//
//  ChatPlaygroundView.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/25/25.
//

import SwiftUI
import OpenAI

private let client = OpenAI(apiToken: "")


//private func chatWithAI(prompt: String, model: String = "gpt-4o") async throws -> String {
//
//    let tuples: [(ChatQuery.ChatCompletionMessageParam.Role, String)] = [
//        (.system, "You are TimeFlow, an AI day-planner."),
//        (.user,   prompt)
//    ]
//
//    let messages: [ChatQuery.ChatCompletionMessageParam] = try tuples.map { role, content in
//        guard let msg = ChatQuery.ChatCompletionMessageParam(role: role, content: content) else {
//            throw OpenAIHelperError.messageInitFailed(content)
//        }
//        return msg
//    }
//
//    let query  = ChatQuery(messages: messages, model: model)
//    let result = try await client.chats(query: query)
//    
//    if let usage = result.usage {
//        
//        let inputTokensAmount = Double(usage.promptTokens)
//        let outputTokensAmount = Double(usage.completionTokens)
//        
//        print("Input tokens: \(inputTokensAmount)")
//        print("Output tokens: \(outputTokensAmount)")
//        
//        let priceInputPerTokens: Double = 1.1 / 1000000
//        let priceOutputPerTokens: Double = 4.4 / 1000000
//        
//        let totalCost = inputTokensAmount * priceInputPerTokens + outputTokensAmount * priceOutputPerTokens
//        
//        print("Estimated Cost of Request:", totalCost)
//        
//        
//    }
//
//    return result.choices.first?.message.content ?? ""
//}

private func chatWithAI(prompt: String, model: String = "gpt-4o") async throws -> String {
    
    let tuples: [(ChatQuery.ChatCompletionMessageParam.Role, String)] = [
        (.system, "You are TimeFlow, an AI day-planner."),
        (.user,   prompt)
    ]

    
    let messages: [ChatQuery.ChatCompletionMessageParam] = try tuples.map { role, content in
        guard let msg = ChatQuery.ChatCompletionMessageParam(role: role, content: content) else {
            print("Failed to initialize message with role: \(role) and content: \(content)")
            throw NSError(domain: "ChatPlaygroundView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize message with content: \(content)"])
        }
        return msg
    }
    
    let query = ChatQuery(messages: messages, model: model)
    
    do {
        let result = try await client.chats(query: query)
        
        // Handle usage if present
        if let usage = result.usage {
            let inputTokensAmount = Double(usage.promptTokens)
            let outputTokensAmount = Double(usage.completionTokens)
            
            let priceInputPerTokens: Double = 1.1 / 1000000
            let priceOutputPerTokens: Double = 4.4 / 1000000
            
            let totalCost = inputTokensAmount * priceInputPerTokens + outputTokensAmount * priceOutputPerTokens
            
            print("Cost of Request: $\(totalCost)")
        } else {
            print("No usage information in result")
        }
        
        // Get content from the structured result
        let content = result.choices.first?.message.content ?? ""
        return content
        
    } catch {
        print("Error during API call: \(error.localizedDescription)")
        throw error
    }
}

// MARK: - Public helper
func userInfoToSchedule(
    user: User,
    history: UserHistory,
    note: String,
    now: Date = Date()
) async throws -> [Event] {

    // ----- 1. Build prompt --------------------------------------------------
    let prompt: String
    switch user.ageGroup {
    case .highSchool, .middleSchool:
        prompt = generateSchoolStudentSchedulePrompt(
                    user: user, history: history, note: note, now: now)
    case .college:
        prompt = generateCollegeStudentSchedulePrompt(
                    user: user, history: history, note: note, now: now)
    case .youngProfessional:
        prompt = generateYoungProSchedulePrompt(
                    user: user, history: history, note: note, now: now)
    }
    
//    print("---------------- PROMPT ----------------------")
//    print(prompt)
//    print("--------------------------------------")

    // ----- 2. Query AI ------------------------------------------------------
    let raw = try await chatWithAI(prompt: prompt, model: "o4-mini")

    // ----- 3. Clean JSON ----------------------------------------------------
    let cleaned = raw
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "“", with: "\"")
        .replacingOccurrences(of: "”", with: "\"")
        .replacingOccurrences(of: "```json", with: "")
        .replacingOccurrences(of: "```", with: "")

    // Grab first '[' … last ']' to be safe
    guard
        let firstBracket = cleaned.firstIndex(of: "["),
        let lastBracket  = cleaned.lastIndex(of: "]")
    else { throw ScheduleError.invalidJSON }

    let jsonString = String(cleaned[firstBracket...lastBracket])
    print("Cleaned JSON:", jsonString)

    guard let data = jsonString.data(using: .utf8) else {
        throw ScheduleError.invalidJSON
    }

    // ----- 4. Parse into [Event] -------------------------------------------
    // Using JSONSerialization so we can keep Event as‑is
    guard
        let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    else { throw ScheduleError.invalidJSON }

    let events: [Event] = array.compactMap { dict in
        guard
            let title  = dict["title"] as? String,
            let startS = dict["start"] as? String,
            let endS   = dict["end"]   as? String,
            let start  = dateFromHHMM(startS),
            let end    = dateFromHHMM(endS)
        else { return nil }

        let idStr = dict["id"] as? String
        let uuid  = idStr.flatMap(UUID.init(uuidString:)) ?? UUID()

        return Event(id: uuid,
                     start: start,
                     end: end,
                     title: title,
                     eventType: .other)   // you’ll map this later
    }
    
    return events
}

// MARK: - Errors
private enum ScheduleError: Error { case invalidJSON }




func generateSchoolStudentSchedulePrompt(
    user: User,
    history: UserHistory,
    note: String = "",
    now: Date = Date(),
    lookbackDays: Int = 3
) -> String {

    let cal = Calendar.current
    
    let wakeTime = user.todaysAwakeHours?.wakeTime ?? user.awakeHours.wakeTime
    let hardBedtime = user.todaysAwakeHours?.sleepTime ?? user.awakeHours.sleepTime
    let softBedtime = { () -> String in
        let comps = hardBedtime.split(separator: ":").compactMap { Int($0) }
        guard comps.count == 2 else { return hardBedtime }
        let mins = comps[0] * 60 + comps[1] + 20       // +20 min cap
        return String(format: "%02d:%02d", (mins / 60) % 24, mins % 60)
    }()

    // MARK: — Summaries (same as before)
    let weekdayIdx = cal.component(.weekday, from: now)
    let weekday = Weekday.allCases[(weekdayIdx + 5) % 7]
    let isSchoolDay = weekday != .saturday && weekday != .sunday
    
    var goalsSummary: String {
        func effectivePerWeek(for goal: Goal) -> Int {
            switch goal.cadence {
            case .daily: return 7
            case .thriceWeekly: return 3
            case .weekly: return 1
            case .custom: return goal.customPerWeek ?? 0
            }
        }
        
        let activeGoals = user.goals.filter { $0.isActive }
        
        let sortedGoals = activeGoals.sorted { goal1, goal2 in
            let rem1 = effectivePerWeek(for: goal1) - goal1.daysCompletedThisWeek.count
            let rem2 = effectivePerWeek(for: goal2) - goal2.daysCompletedThisWeek.count
            return rem1 > rem2
        }
        
        let summaries = sortedGoals.map { goal in
            let activityTitle: String
            if goal.activity.lowercased() == goal.title.lowercased() {
                activityTitle = goal.activity
            } else {
                activityTitle = "\(goal.activity)-\(goal.title)"
            }
            
            let effectiveCount = effectivePerWeek(for: goal)
            let completedCount = goal.daysCompletedThisWeek.count
            let daysStr = goal.daysCompletedThisWeek.isEmpty ? "none" : goal.daysCompletedThisWeek.map { $0.rawValue }.joined(separator: ", ")
            let extraStr = goal.extraPreferenceInfo.isEmpty ? "" : " Extra preferences: \(goal.extraPreferenceInfo)."

            return "\(activityTitle) - The user wants to complete this activity \(effectiveCount) times per week and has already completed it \(completedCount) times this week on \(daysStr). The activity's duration is \(goal.durationMinutes) minutes. \(extraStr) ID: \(goal.id.uuidString)."
        }
        
        return summaries.joined(separator: "\n")
    }
    
    var assignmentsSummary: String {
        let incompleteAssignments = user.assignments.filter { !$0.completed }
        
        let sortedAssignments = incompleteAssignments.sorted { $0.dueDate < $1.dueDate }
        
        let summaries = sortedAssignments.map { assignment in
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            let dueDateStr = dateFormatter.string(from: assignment.dueDate)
            
            let extraStr = assignment.extraPreferenceInfo.isEmpty ? "" : " Extra preferences: \(assignment.extraPreferenceInfo)."
            
            return "Assignment Title: \(assignment.assignmentTitle) - \(assignment.classTitle). Due on \(dueDateStr). Estimated time left to complete: \(assignment.estimatedMinutesLeftToComplete) minutes. \(extraStr). ID: \(assignment.id.uuidString)."
        }
        
        return summaries.joined(separator: "\n")
    }
    
    var testsSummary: String {
        let unpreparedTests = user.tests.filter { !$0.prepared }
        
        let sortedTests = unpreparedTests.sorted { $0.date < $1.date }
        
        let summaries = sortedTests.map { test in
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            let testDateStr = dateFormatter.string(from: test.date)
            
            let extraStr = test.extraPreferenceInfo.isEmpty ? "" : test.extraPreferenceInfo
            
            return "Test: \(test.testTitle) - \(test.classTitle). Scheduled on \(testDateStr). Estimated study time left: \(test.studyMinutesLeft) minutes. \(extraStr). ID: \(test.id.uuidString)."
        }
        
        return summaries.joined(separator: "\n")
    }
    
    var recurringCommitmentsSummary: String {
        let now = Date()
        let weekdayComponent = cal.component(.weekday, from: now)
        
        let weekdayMap: [Int: Weekday] = [
            1: .sunday, 2: .monday, 3: .tuesday, 4: .wednesday,
            5: .thursday, 6: .friday, 7: .saturday
        ]
        
        guard let todayWeekday = weekdayMap[weekdayComponent] else {
            return "Error determining current weekday."
        }
        
        let todaysCommitments = user.recurringCommitments.filter {
            $0.cadence == .daily ||
            ($0.cadence == .weekdays && [.monday, .tuesday, .wednesday, .thursday, .friday].contains(todayWeekday)) ||
            ($0.cadence == .custom && $0.customDays.contains(todayWeekday))
        }
        
        if todaysCommitments.isEmpty {
            return "No commitments today."
        }
    
        let summaryLines = todaysCommitments
            .sorted { $0.startTime < $1.startTime }
            .map { commitment in
                let daysStr = commitment.cadence == .custom && !commitment.customDays.isEmpty
                    ? " on " + commitment.customDays.map { $0.rawValue }.joined(separator: ", ")
                    : ""
                return "Recurring Commitment: \(commitment.title). Cadence: \(commitment.cadence.rawValue)\(daysStr). Time: \(commitment.startTime) - \(commitment.endTime). ID: \(commitment.id.uuidString)."
            }

        return summaryLines.joined(separator: "\n")
    }
    
    var ngTimeSummary: String {
        // helper to turn "HH:mm" into a Date on `now`’s day
        func dateToday(from time: String) -> Date? {
            let comps = time.split(separator: ":").compactMap { Int($0) }
            guard comps.count == 2 else { return nil }
            var dc = cal.dateComponents([.year, .month, .day], from: now)
            dc.hour   = comps[0]
            dc.minute = comps[1]
            return cal.date(from: dc)
        }

        guard
            let wakeDate = dateToday(from: wakeTime),
            wakeDate < now            // nothing to do if we generated before wake‑up
        else { return "" }

        // ---- Collect TODAY’s fixed intervals that ended (or started) before `now` ----
        var intervals: [(start: Date, end: Date)] = []

        // school hours
        if isSchoolDay,
           let s = dateToday(from: user.schoolHours.startTime),
           let e = dateToday(from: user.schoolHours.endTime) {
            intervals.append((start: s, end: min(e, now)))
        }

        // today’s recurring commitments
        for c in user.recurringCommitments {
            let isToday =
                c.cadence == .daily ||
                (c.cadence == .weekdays && [.monday,.tuesday,.wednesday,.thursday,.friday].contains(weekday)) ||
                (c.cadence == .custom && c.customDays.contains(weekday))
            guard isToday,
                  let s = dateToday(from: c.startTime),
                  let e = dateToday(from: c.endTime),
                  s < now                         // ignore ones entirely in the future
            else { continue }
            intervals.append((start: s, end: min(e, now)))
        }

        // merge overlaps & sort
        intervals.sort { $0.start < $1.start }
        var merged: [(start: Date, end: Date)] = []
        for iv in intervals {
            if let last = merged.last, iv.start <= last.end {
                merged[merged.count - 1].end = max(last.end, iv.end)
            } else {
                merged.append(iv)
            }
        }

        // ---- Build NGTime gaps (5‑minute buffers)  ----
        var ng: [(Date,Date)] = []
        var cursor = wakeDate
        for iv in merged {
            let gapEnd   = iv.start.addingTimeInterval(-5*60)     // leave 5 min before
            if gapEnd > cursor { ng.append((cursor, gapEnd)) }
            cursor = iv.end.addingTimeInterval( 5*60)             // leave 5 min after
        }
        if cursor < now.addingTimeInterval(-5*60) {
            ng.append((cursor, now.addingTimeInterval(-5*60)))
        }
        guard !ng.isEmpty else { return "" }

        // stringify
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return ng.enumerated().map { idx, block in
            "Recurring Commitment: NGTime. Cadence: one‑off. Time: \(fmt.string(from:block.0)) - \(fmt.string(from:block.1)). ID: NGTime-\(idx)."
        }.joined(separator: "\n")
    }

    // MARK: — Prompt
    let prompt = """
    You are an elite scheduling assistant.

    ## TODAY
    • Schedule window: **\(wakeTime)** → soft bedtime **\(hardBedtime)** (may extend to **\(softBedtime)** if needed)

    ## USER DATA
    • School hours: \(user.schoolHours.startTime)-\(user.schoolHours.endTime) \(isSchoolDay ? "(school day)" : "(Weekend, user has NO school)")

    • Today's commitments:
    \(recurringCommitmentsSummary)
    \(ngTimeSummary)
    
    
    • Active goals:
    \(goalsSummary)
    
    
    • Pending assignments:
    \(assignmentsSummary)
    
    
    • Pending tests:
    \(testsSummary)
    

    ## USER NOTE
    “\(note)”

    ## OBJECTIVE
    Build the most productive, balanced and thought out schedule from the current time until bedtime.

    ## RULES
    1. **Priority** Prioritize Closely Due Assignments and Tests First, then Goals, then assignments that are less urgent.
    2. **Gaps** Leave at least a 5 min gaps or more time if you see necessary between each activity; **no explicit Break/Leisure events**.
    3. **Meals** Breakfast 30 min (if ahead), Dinner 30 min 18:00‑20:00; \(isSchoolDay ? "Lunch in school – don't add." : "Add Lunch 30 min ±1:15.")
    4. **Titles** must be specific; no “Study”/“Work” fillers.
    5. **Bedtime** Aim to finish by \(hardBedtime), **but** if need more time for assignments extend bedtime up to **\(softBedtime)**.  
       Always preserve ≥ 6 h sleep (i.e., do not schedule past 00:30 if wake is 07:00). 
    6. *Need more time** *You may extend the user’s bedtime by up to 20 minutes (e.g., 23:20 instead of 23:00) when doing so lets you fit a beneficial, non‑urgent activity—such as a goal session or an optional assignment—that would otherwise be left out.
    7. **Do not schedule the same goal twice in one day.**
    8. No overlaps; free blocks may remain unscheduled.

    ## OUTPUT (STRICT)
    Return **only** a JSON array, e.g.:
    [
      { "title": "School", "start": "8:30", "end": "15:00", "id": "School" }, ← used Event Title
      { "title": "Soccer Practive", "start": "15:30", "end": "17:15", "id": "71778cfa-4120-41e5-a7c4-0366b57463f4" }, ← used given UUID
      { "title": "Math Worksheet - AP Calculus", "start": "17:45", "end": "18:30", "id": "71778cfa-4120-41e5-a7c4-0366b57463f4" } ← used given UUID
    ]

    • "id" — if the event already has a UUID in the data above, use it; otherwise set "id" to the event’s title.
    """

    return prompt
}

func generateCollegeStudentSchedulePrompt(
    user: User,
    history: UserHistory,
    note: String = "",
    now: Date = Date(),
    lookbackDays: Int = 3
) -> String {

    let cal = Calendar.current
    
    let wakeTime = user.todaysAwakeHours?.wakeTime ?? user.awakeHours.wakeTime
    let hardBedtime = user.todaysAwakeHours?.sleepTime ?? user.awakeHours.sleepTime
    let softBedtime = { () -> String in
        let comps = hardBedtime.split(separator: ":").compactMap { Int($0) }
        guard comps.count == 2 else { return hardBedtime }
        let mins = comps[0] * 60 + comps[1] + 20       // +20 min cap
        return String(format: "%02d:%02d", (mins / 60) % 24, mins % 60)
    }()

    // Weekday helpers
    let weekdayIdx = cal.component(.weekday, from: now)
    let weekdayEnum = Weekday.allCases[(weekdayIdx + 5) % 7]

    // ---------- College course commitments today ----------
    let todaysCourses = user.collegeCourses
        .filter { $0.day == weekdayEnum }
        .sorted { $0.startTime < $1.startTime }

    let coursesSummary = todaysCourses.isEmpty
        ? "None"
        : todaysCourses.map {
            "– \($0.name) \($0.startTime)-\($0.endTime) (ID: \($0.id.uuidString))"
          }.joined(separator: "\n")

    // ---------- Goals summary (same logic as before) ----------
    func effectivePerWeek(for g: Goal) -> Int {
        switch g.cadence {
        case .daily: 7
        case .thriceWeekly: 3
        case .weekly: 1
        case .custom: g.customPerWeek ?? 0
        }
    }
    let goalsSummary = user.goals
        .filter { $0.isActive }
        .sorted {
            effectivePerWeek(for: $0) - $0.daysCompletedThisWeek.count >
            effectivePerWeek(for: $1) - $1.daysCompletedThisWeek.count
        }
        .map { g -> String in
            let remaining = effectivePerWeek(for: g) - g.daysCompletedThisWeek.count
            let actTitle = g.activity.lowercased() == g.title.lowercased()
                ? g.activity : "\(g.activity)-\(g.title)"
            let prefs = g.extraPreferenceInfo.isEmpty ? "" : "User prefers: \(g.extraPreferenceInfo)."
            return "\(actTitle) – \(g.durationMinutes) min, needs \(max(0,remaining)) this week.\(prefs) ID: \(g.id.uuidString)."
        }.joined(separator: "\n").ifEmpty("None")

    // ---------- Assignments / tests summaries (same pattern) ----------
    func daysLeft(to d: Date) -> String {
        "\(max(0, Int(d.timeIntervalSince(now)/86_400))) d"
    }
    let assignmentsSummary = user.assignments.filter { !$0.completed }
        .sorted { $0.dueDate < $1.dueDate }
        .map {
            let prefs = $0.extraPreferenceInfo.isEmpty ? "" : " Prefers: \($0.extraPreferenceInfo)."
            return "– \($0.assignmentTitle) (\($0.classTitle)), due \(daysLeft(to:$0.dueDate)), ~\($0.estimatedMinutesLeftToComplete) min left,\(prefs) ID: \($0.id.uuidString)"
        }.joined(separator: "\n").ifEmpty("None")

    let testsSummary = user.tests.filter { !$0.prepared }
        .sorted { $0.date < $1.date }
        .map {
            let prefs = $0.extraPreferenceInfo.isEmpty ? "" : " Prefers: \($0.extraPreferenceInfo)."
            return "– \($0.testTitle) (\($0.classTitle)) on \(daysLeft(to:$0.date)), ~\($0.studyMinutesLeft) min study left.\(prefs) ID: \($0.id.uuidString)"
        }.joined(separator: "\n").ifEmpty("None")

    // ---------- Recurring commitments (clubs, work, etc.) ----------
    let todaysCommitments = user.recurringCommitments
        .filter {
            switch $0.cadence {
            case .daily: true
            case .weekdays: weekdayEnum != .saturday && weekdayEnum != .sunday
            case .custom: $0.customDays.contains(weekdayEnum)
            }
        }.map {
            "– \($0.title) \($0.startTime)-\($0.endTime) (ID: \($0.id.uuidString))"
        }.sorted().joined(separator: "\n").ifEmpty("None")

    let ngTimeSummary: String = {
        // helper: "HH:mm" -> Date today
        func dateToday(from time: String) -> Date? {
            let comps = time.split(separator: ":").compactMap { Int($0) }
            guard comps.count == 2 else { return nil }
            var dc = cal.dateComponents([.year, .month, .day], from: now)
            dc.hour = comps[0]; dc.minute = comps[1]
            return cal.date(from: dc)
        }

        guard
            let wakeDate = dateToday(from: wakeTime),
            wakeDate < now                                // nothing to do if prompt before wake‑up
        else { return "" }

        // collect fixed intervals (TODAY’s courses + recurring commitments)
        var intervals: [(start: Date, end: Date)] = []

        // today’s courses
        for c in todaysCourses {
            if let s = dateToday(from: c.startTime),
               let e = dateToday(from: c.endTime),
               s < now {
                intervals.append((start: s, end: min(e, now)))
            }
        }

        // today’s recurring commitments
        for rc in user.recurringCommitments {
            let happensToday: Bool = {
                switch rc.cadence {
                case .daily: return true
                case .weekdays: return weekdayEnum != .saturday && weekdayEnum != .sunday
                case .custom: return rc.customDays.contains(weekdayEnum)
                }
            }()
            guard happensToday,
                  let s = dateToday(from: rc.startTime),
                  let e = dateToday(from: rc.endTime),
                  s < now
            else { continue }
            intervals.append((start: s, end: min(e, now)))
        }

        // merge overlaps
        intervals.sort { $0.start < $1.start }
        var merged: [(Date,Date)] = []
        for iv in intervals {
            if let last = merged.last, iv.start <= last.1 {
                merged[merged.count-1].1 = max(last.1, iv.1)
            } else {
                merged.append(iv)
            }
        }

        // build NGTime gaps (5‑minute buffers)
        var ng: [(Date,Date)] = []
        var cursor = wakeDate
        for iv in merged {
            let gapEnd = iv.0.addingTimeInterval(-5*60)
            if gapEnd > cursor { ng.append((cursor, gapEnd)) }
            cursor = iv.1.addingTimeInterval(5*60)
        }
        if cursor < now.addingTimeInterval(-5*60) {
            ng.append((cursor, now.addingTimeInterval(-5*60)))
        }
        guard !ng.isEmpty else { return "" }

        let fmt = DateFormatter(); fmt.dateFormat = "HH:mm"
        return ng.enumerated().map { idx, block in
            "– NGTime \(fmt.string(from:block.0))-\(fmt.string(from:block.1)) (ID: NGTime-\(idx))"
        }.joined(separator: "\n")
    }()
    
    // MARK: — Prompt
    let prompt = """
    You are an elite scheduling assistant for college students.

    ## TODAY
    • Schedule window: **\(wakeTime)** → bedtime **\(hardBedtime)** (may extend to **\(softBedtime)** if rules allow)

    ## USER DATA
    • Wake/Sleep: \(wakeTime)‑\(hardBedtime) (≥ 6 h sleep must remain)
    • College courses today:
    \(coursesSummary)

    • Today's commitments (clubs, part‑time work, etc.):
    \(todaysCommitments)
    \(ngTimeSummary)

    • Active goals:
    \(goalsSummary)

    • Pending assignments:
    \(assignmentsSummary)

    • Pending tests:
    \(testsSummary)

    ## USER NOTE
    “\(note)”

    ## OBJECTIVE
    Build the most productive, balanced and thought out schedule from the current time until bedtime.

    ## RULES
    1. Prioritize Closely Due Assignments and Tests First, then Goals, then assignments that are less urgent.
    2. Leave at least a 5 min gaps or more time if you see necessary between each activity; **no explicit Break/Leisure events**.
    3. **Meals**  
       • Breakfast 30 min if before first task.  
       • **Lunch** 40 min if a ≥ 60 min gap appears 11:30‑15:00.  
       • Dinner 30 min 18:00‑20:00.
    4. Titles must be specific; no “Study”/“Work” fillers.
    5. Aim to finish by \(hardBedtime), **but** if need more time for assignments extend bedtime up to **\(softBedtime)**.  
       Always preserve ≥ 7 h sleep (i.e., do not schedule past 00:00 if wake is 07:00). 
    6. You may extend the user’s bedtime by up to 20 minutes (e.g., 23:20 instead of 23:00) when doing so lets you fit a beneficial, non‑urgent activity—such as a goal session or an optional assignment—that would otherwise be left out.
    7. **Do not schedule the same goal twice in one day.**
    8. No overlaps; free blocks may remain unscheduled.

    ## OUTPUT (STRICT)
    Return **only** a JSON array, e.g.:
    [
      { "title": "Linear Algebra Worksheet", "start": "16:10", "end": "17:00", "id": "71778cfa-4120-41e5-a7c4-0366b57463f4" } ← used given UUID
    ]

    • "id" — if the event already has a UUID in the data above, use it; otherwise set "id" to the event’s title.
    """

    return prompt
}

func generateYoungProSchedulePrompt(
    user: User,
    history: UserHistory,
    note: String = "",
    now: Date = Date(),
    lookbackDays: Int = 3
) -> String {

    guard user.ageGroup == .youngProfessional else {
        return "ERROR: user.ageGroup must be .youngProfessional"
    }

    // ---- Time helpers ------------------------------------------------------
    let cal = Calendar.current
    let bump = (5 - (cal.component(.minute, from: now) % 5)) % 5
    let startDate = cal.date(byAdding: .minute, value: bump, to: now)!
    let hhmm: DateFormatter = { let f = DateFormatter(); f.dateFormat = "HH:mm"; return f }()
    let startHHMM = hhmm.string(from: startDate)

    
    let hardBedtime = user.todaysAwakeHours?.sleepTime ?? user.awakeHours.sleepTime
    let softBedtime = { () -> String in
        let comps = hardBedtime.split(separator: ":").compactMap { Int($0) }
        guard comps.count == 2 else { return hardBedtime }
        let mins = comps[0] * 60 + comps[1] + 20       // +20 min cap
        return String(format: "%02d:%02d", (mins / 60) % 24, mins % 60)
    }()

    // ---- Work block today --------------------------------------------------
    let weekdayIdx = cal.component(.weekday, from: now)
    let weekday    = Weekday.allCases[(weekdayIdx + 5) % 7]

    let todaysWork = user.workHours.first { $0.day == weekday && $0.enabled }
    let workSummary = todaysWork == nil
        ? "None (day off)"
        : "\(todaysWork!.startTime)-\(todaysWork!.endTime)"

    let hasWorkToday = todaysWork != nil

    // ---- Goals summary (same as before) ------------------------------------
    func effectivePerWeek(_ g:Goal)->Int{
        switch g.cadence{case .daily:7;case .thriceWeekly:3;case .weekly:1;case .custom:g.customPerWeek ?? 0}
    }
    let goalsSummary = user.goals.filter{$0.isActive}
        .sorted{
            effectivePerWeek($0)-$0.daysCompletedThisWeek.count >
            effectivePerWeek($1)-$1.daysCompletedThisWeek.count
        }
        .map{ g in
            let remain = effectivePerWeek(g)-g.daysCompletedThisWeek.count
            let prefs  = g.extraPreferenceInfo.isEmpty ? "" : " Prefers: \(g.extraPreferenceInfo)."
            let name   = g.activity.lowercased()==g.title.lowercased() ? g.activity : "\(g.activity)-\(g.title)"
            return "\(name) – \(g.durationMinutes) min, needs \(max(0,remain)) this week.\(prefs) ID: \(g.id.uuidString)"
        }.joined(separator:"\n").ifEmpty("None")

    // ---- Recurring commitments --------------------------------------------
    let todaysCommitments = user.recurringCommitments.filter{
        switch $0.cadence{
        case .daily: true
        case .weekdays: [.monday,.tuesday,.wednesday,.thursday,.friday].contains(weekday)
        case .custom: $0.customDays.contains(weekday)
        }
    }.sorted{$0.startTime<$1.startTime}
     .map{ "– \($0.title) \($0.startTime)-\($0.endTime) (ID:\($0.id.uuidString))" }
     .joined(separator:"\n").ifEmpty("None")
    
    let ngTimeSummary: String = {
        // Wake‑up time (string like "07:00")
        let wakeTime = user.todaysAwakeHours?.wakeTime ?? user.awakeHours.wakeTime

        // convert "HH:mm" -> Date (today)
        func dateToday(_ time: String) -> Date? {
            let comps = time.split(separator: ":").compactMap { Int($0) }
            guard comps.count == 2 else { return nil }
            var dc = cal.dateComponents([.year,.month,.day], from: now)
            dc.hour = comps[0]; dc.minute = comps[1]
            return cal.date(from: dc)
        }

        guard
            let wakeDate = dateToday(wakeTime),
            wakeDate < now                                        // skip if before wake‑up
        else { return "" }

        // fixed intervals before `now`
        var intervals:[(Date,Date)] = []

        // today’s work block
        if let w = todaysWork,
           let s = dateToday(w.startTime),
           let e = dateToday(w.endTime),
           s < now {
            intervals.append((s, min(e,now)))
        }

        // today’s recurring commitments
        for rc in user.recurringCommitments {
            let happensToday: Bool = {
                switch rc.cadence{
                case .daily: true
                case .weekdays: [.monday,.tuesday,.wednesday,.thursday,.friday].contains(weekday)
                case .custom: rc.customDays.contains(weekday)
                }
            }()
            guard happensToday,
                  let s = dateToday(rc.startTime),
                  let e = dateToday(rc.endTime),
                  s < now else { continue }
            intervals.append((s, min(e,now)))
        }

        // merge overlapping intervals
        intervals.sort{ $0.0 < $1.0 }
        var merged:[(Date,Date)]=[]
        for iv in intervals{
            if let last = merged.last, iv.0 <= last.1 {
                merged[merged.count-1].1 = max(last.1, iv.1)
            } else {
                merged.append(iv)
            }
        }

        // build NGTime gaps (leave 5‑minute buffers)
        var ng:[(Date,Date)]=[]
        var cursor = wakeDate
        for iv in merged{
            let gapEnd = iv.0.addingTimeInterval(-5*60)
            if gapEnd > cursor { ng.append((cursor,gapEnd)) }
            cursor = iv.1.addingTimeInterval(5*60)
        }
        if cursor < now.addingTimeInterval(-5*60) {
            ng.append((cursor, now.addingTimeInterval(-5*60)))
        }
        guard !ng.isEmpty else { return "" }

        let fmt = DateFormatter(); fmt.dateFormat = "HH:mm"
        return ng.enumerated().map { idx, block in
            "– NGTime \(fmt.string(from:block.0))-\(fmt.string(from:block.1)) (ID: NGTime-\(idx))"
        }.joined(separator:"\n")
    }()

    // ---- Prompt ------------------------------------------------------------
    let prompt = """
    You are an elite scheduling assistant for young professionals.

    ## TODAY
    • Current time: \(ISO8601DateFormatter().string(from: now))
    • Schedule window: **\(startHHMM)** → bedtime **\(hardBedtime)** (may extend to **\(softBedtime)** if allowed)

    ## USER DATA
    • Now/Sleep: \(startHHMM)‑\(hardBedtime) (≥ 6 h sleep required)
    • Work hours today: \(workSummary)
    • Recurring commitments:
    \(todaysCommitments)
    \(ngTimeSummary)
    
    • Active goals:
    \(goalsSummary)

    ## USER NOTE
    “\(note)”

    ## OBJECTIVE
    Build the most productive, balanced and thought out schedule from the current time until bedtime.

    ## RULES
    1. **Fixed commitments first** – schedule the work block (if any) and recurring commitments at their exact times.
    2. **Gaps** Leave at least a 5 min gaps or more time if you see necessary between each activity; **no explicit Break/Leisure events**.
    3. **Meals**  
           - Breakfast 30 min if before first task.  
           - \(hasWorkToday ? "*No scheduled Lunch – user manages lunch during work.*" : "Lunch 30 min around 1:00 (only on non‑workdays).")  
           - Dinner 30 min between 18:00‑20:00.
    4. **Titles** must be specific; no “Study”/“Work” fillers.
    5. **Bedtime** Aim to finish by \(hardBedtime), **but** if need more time for assignments extend bedtime up to **\(softBedtime)**.  
       Always preserve ≥ 6 h sleep (i.e., do not schedule past 00:30 if wake is 07:00). 
    6. *Need more time** *You may extend the user’s bedtime by up to 20 minutes (e.g., 23:20 instead of 23:00) when doing so lets you fit a beneficial, non‑urgent activity—such as a goal session or an optional assignment—that would otherwise be left out.
    7. **Do not schedule the same goal twice in one day.**
    8. No overlaps; free blocks may remain unscheduled.

    ## OUTPUT (STRICT)
    Return **only** a JSON array, e.g.:
    [
      { "title": "Evening Run", "start": "18:20", "end": "18:50", "id": "71778cfa-4120-41e5-a7c4-0366b57463f4" } ← used given UUID
    ]

    • "id" — if the event already has a UUID in the data above, use it; otherwise set "id" to the event’s title.
    """

    return prompt
}



// MARK: — Tiny helper
private extension String {
    func ifEmpty(_ alt: String) -> String { isEmpty ? alt : self }
}
