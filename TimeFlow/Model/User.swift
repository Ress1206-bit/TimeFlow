//
//  User.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/27/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore

// ----------------------------------------- User Information -----------------------------------------
struct User: Codable, Hashable {
    
    // base info
    var name: String = ""
    var email: String = ""
    var accountCreated: Timestamp = Timestamp(date: Date())
    
    // initial info
    var ageGroup: AgeGroup = .youngProfessional
    var awakeHours: AwakeHours = AwakeHours(wakeTime: "07:00", sleepTime: "23:00")
    
    // Student
    var schoolHours: SchoolHours = SchoolHours(startTime: "08:00", endTime: "15:00")
    var classes: [String] = []
    
    // College
    var collegeCourses: [CollegeCourse] = []
    
    // Young Pro
    var workHours: [DayHours] = Weekday.allCases.map {
        DayHours(day: $0, enabled: [.monday, .tuesday, .wednesday, .thursday, .friday].contains($0), startTime: "09:00", endTime: "17:00")
    }
    
    // Changing Info --- Schedule Critical
    var goals: [Goal] = []

    var recurringCommitments: [RecurringCommitment] = []
    
    // College & Student
    var assignments: [Assignment] = []
    var tests: [Test] = []
    
    
    // Daily Specifics
    var todaysAwakeHours: AwakeHours?
    var currentSchedule: [Event] = []
    
    //Subscription
    var subscribed: Bool = false
    
    init() {
        // All properties already have default values above
    }
    
    enum CodingKeys: String, CodingKey {
        case name, email, accountCreated, ageGroup, awakeHours, schoolHours
        case classes, collegeCourses, workHours, goals, recurringCommitments
        case assignments, tests, todaysAwakeHours, currentSchedule, subscribed
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        accountCreated = try container.decodeIfPresent(Timestamp.self, forKey: .accountCreated) ?? Timestamp(date: Date())
        ageGroup = try container.decodeIfPresent(AgeGroup.self, forKey: .ageGroup) ?? .youngProfessional
        awakeHours = try container.decodeIfPresent(AwakeHours.self, forKey: .awakeHours) ?? AwakeHours(wakeTime: "07:00", sleepTime: "23:00")
        schoolHours = try container.decodeIfPresent(SchoolHours.self, forKey: .schoolHours) ?? SchoolHours(startTime: "08:00", endTime: "15:00")
        classes = try container.decodeIfPresent([String].self, forKey: .classes) ?? []
        collegeCourses = try container.decodeIfPresent([CollegeCourse].self, forKey: .collegeCourses) ?? []
        workHours = try container.decodeIfPresent([DayHours].self, forKey: .workHours) ?? Weekday.allCases.map {
            DayHours(day: $0, enabled: [.monday, .tuesday, .wednesday, .thursday, .friday].contains($0), startTime: "09:00", endTime: "17:00")
        }
        goals = try container.decodeIfPresent([Goal].self, forKey: .goals) ?? []
        recurringCommitments = try container.decodeIfPresent([RecurringCommitment].self, forKey: .recurringCommitments) ?? []
        assignments = try container.decodeIfPresent([Assignment].self, forKey: .assignments) ?? []
        tests = try container.decodeIfPresent([Test].self, forKey: .tests) ?? []
        todaysAwakeHours = try container.decodeIfPresent(AwakeHours.self, forKey: .todaysAwakeHours)
        subscribed = try container.decodeIfPresent(Bool.self, forKey: .subscribed) ?? false
        
        // Handle currentSchedule with safe decoding - provide default empty array
        currentSchedule = []
        if container.contains(.currentSchedule) {
            do {
                currentSchedule = try container.decode([Event].self, forKey: .currentSchedule)
            } catch {
                print("⚠️ Failed to decode currentSchedule, using empty array: \(error)")
                currentSchedule = []
            }
        }
    }
}


// ----------------------------------------- User Info Structures -----------------------------------------

enum AgeGroup: String, Codable, Hashable, CaseIterable, Identifiable {
    case middleSchool = "Middle School"
    case highSchool = "High School"
    case college = "College"
    case youngProfessional = "Young Professional"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .middleSchool: return "backpack.fill"
        case .highSchool: return "books.vertical.fill"
        case .college: return "graduationcap.fill"
        case .youngProfessional: return "briefcase.fill"
        }
    }
    
    var themeColor: Color {
        return Color.ageGroupColor(for: self)
    }
    
    var colorToken: String {
        switch self {
        case .middleSchool: return "middleschool"
        case .highSchool: return "highschool"
        case .college: return "college"
        case .youngProfessional: return "youngpro"
        }
    }
}

enum Weekday: String, CaseIterable, Identifiable, Codable {
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    case sunday = "Sunday"
    var id: String { rawValue }
}

enum Cadence: String, CaseIterable, Identifiable, Codable {
    case daily = "Daily"
    case thriceWeekly = "3× Weekly"
    case weekly = "Weekly"
    case custom = "Custom"
    var id: String { rawValue }
}

enum RecurringCadence: String, CaseIterable, Identifiable, Codable {
    case daily = "Daily"
    case weekdays = "Weekdays"
    case custom = "Custom"
    var id: String { rawValue }
}

struct SchoolHours: Codable, Hashable {
    var startTime: String // "HH:mm"
    var endTime: String   // "HH:mm"
}

struct AwakeHours: Codable, Hashable {
    var wakeTime: String  // "HH:mm"
    var sleepTime: String // "HH:mm"
}

struct CollegeCourse: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var day: Weekday
    var startTime: String // "HH:mm"
    var endTime: String   // "HH:mm"
    var colorName: String = "accent"
    var color: Color { 
        return Color.activityColor(colorName)
    }
}

struct DayHours: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var day: Weekday
    var enabled: Bool
    var startTime: String // "HH:mm"
    var endTime: String   // "HH:mm"
}

struct Goal: Identifiable, Codable, Hashable {
    
    var isActive: Bool = true
    
    var id: UUID = UUID()
    
    //initial info
    var title: String
    var activity: String = ""
    var extraPreferenceInfo: String = "" //Any preferences the A.I. should know
    
    var cadence: Cadence = .daily
    var customPerWeek: Int?
    var durationMinutes: Int = 30
    
    var colorName: String = "accent"
    var icon: String = "target"
    var color: Color { 
        return Color.activityColor(colorName) 
    } // Computed for UI
    
    var daysCompletedThisWeek: [Weekday]
    
    //Analytics
    var totalCompletionsAllTime: Int = 0
    var totalCompletionMinutes: Int = 0
    var weeksActive: Int = 0
}

struct RecurringCommitment: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    
    //initial info
    var title: String
    var icon: String = "calendar"
    var colorName: String = "gray"
    var cadence: RecurringCadence
    var customDays: [Weekday] = []
    var startTime: String // "HH:mm"
    var endTime: String
    var color: Color { 
        return Color.activityColor(colorName) 
    } // Computed
    
}

struct Assignment: Identifiable, Codable, Hashable {
    
    var id: UUID = UUID()
    
    //initial info
    var assignmentTitle: String
    var classTitle: String
    var dueDate: Date
    
    var extraPreferenceInfo: String = ""
    
    var estimatedMinutesLeftToComplete: Int = 60
    
    
    
    var completed: Bool = false
}

struct Test: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    
    var testTitle: String
    var classTitle: String
    
    var date: Date
    var extraPreferenceInfo: String = ""
    var studyMinutesLeft: Int = 120
    
    var prepared: Bool = false
}


// ----------------------------------------- User History ----------------------------------------- For Analytics


struct UserHistory: Codable, Hashable {
    var dailyLogs: [DailyInfo] = [] // Historical daily summaries
    var goalStats: [Goal] = [] //Includes analytics
}

// ----------------------------------------- User History Structures -----------------------------------------

struct DailyInfo: Codable, Hashable {
    var date: Date
    
    var events: [Event]
    
    var awakeHours: AwakeHours
}


// ----------------------------------------- Schedule Event Item -----------------------------------------

struct Event: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var start: Date
    var end: Date
    var title: String
    var icon: String = "calendar"
    var eventType: EventType
    var colorName: String?
    
    var color: Color {
        return Color.activityColor(colorName ?? "red")
    }
    
    // Keep the existing init for manual creation
    init(id: UUID = UUID(), start: Date, end: Date, title: String, icon: String = "calendar", eventType: EventType, colorName: String? = nil) {
        self.id = id
        self.start = start
        self.end = end
        self.title = title
        self.icon = icon
        self.eventType = eventType
        self.colorName = colorName
    }
}


enum EventType: String, Codable, CaseIterable {
    case school = "School"
    case collegeClass = "College Class"
    case work = "Work"
    case goal = "Goal"
    case recurringCommitment = "Recurring Commitment"
    case assignment = "Assignment"
    case testStudy = "Test Study"
    case meal = "Meal"
    case other = "Other"
}