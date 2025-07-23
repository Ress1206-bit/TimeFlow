//
//  BackgroundTaskManager.swift
//  TimeFlow
//
//  Created by Adam Ress on 7/22/25.
//

import Foundation
import BackgroundTasks
import UserNotifications
import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

class BackgroundTaskManager: ObservableObject {
    static let shared = BackgroundTaskManager()
    
    private let backgroundTaskIdentifier = "com.timeflow.schedulegeneration"
    private let wakeUpScheduleIdentifier = "com.timeflow.wakeupschedule"
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    private init() {}
    
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            self.handleBackgroundScheduleGeneration(task: task as! BGProcessingTask)
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: wakeUpScheduleIdentifier, using: nil) { task in
            self.handleWakeUpScheduleGeneration(task: task as! BGProcessingTask)
        }
    }
    
    func scheduleBackgroundTask() {
        let request = BGProcessingTaskRequest(identifier: backgroundTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 1)
        
        try? BGTaskScheduler.shared.submit(request)
    }
    
    func scheduleWakeUpGeneration(wakeUpTime: String) {
        // Cancel any existing scheduled task
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: wakeUpScheduleIdentifier)
        
        guard let wakeUpDate = nextWakeUpDate(from: wakeUpTime) else { return }
        
        let request = BGProcessingTaskRequest(identifier: wakeUpScheduleIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = wakeUpDate
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Scheduled wake-up generation for: \(wakeUpDate)")
        } catch {
            print("❌ Failed to schedule wake-up task: \(error)")
        }
    }
    
    private func nextWakeUpDate(from timeString: String) -> Date? {
        let components = timeString.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
        dateComponents.hour = components[0]
        dateComponents.minute = components[1]
        dateComponents.second = 0
        
        guard let wakeUpToday = calendar.date(from: dateComponents) else { return nil }
        
        // If wake-up time has already passed today, schedule for tomorrow
        if wakeUpToday <= now {
            return calendar.date(byAdding: .day, value: 1, to: wakeUpToday)
        } else {
            return wakeUpToday
        }
    }
    
    private func handleWakeUpScheduleGeneration(task: BGProcessingTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        Task {
            do {
                await performWakeUpScheduleGeneration()
                
                // Schedule next day's wake-up generation
                if let userData = UserDefaults.standard.data(forKey: "cachedUserData"),
                   let user = try? JSONDecoder().decode(User.self, from: userData) {
                    let wakeTime = user.todaysAwakeHours?.wakeTime ?? user.awakeHours.wakeTime
                    scheduleWakeUpGeneration(wakeUpTime: wakeTime)
                }
                
                task.setTaskCompleted(success: true)
            } catch {
                print("Wake-up schedule generation failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    @MainActor
    private func performWakeUpScheduleGeneration() async {
        // Check if auto-scheduling is enabled
        guard UserDefaults.standard.bool(forKey: "autoScheduleEnabled") else {
            print("🚫 Auto-scheduling disabled, skipping wake-up generation")
            return
        }
        
        // Get stored user data and generate schedule
        guard let userData = UserDefaults.standard.data(forKey: "cachedUserData"),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            return
        }
        
        let userNote = UserDefaults.standard.string(forKey: "savedUserNote") ?? ""
        
        do {
            let events = try await userInfoToSchedule(
                user: user,
                history: UserHistory(),
                note: userNote
            )
            
            // Save generated schedule locally
            if let eventsData = try? JSONEncoder().encode(events) {
                UserDefaults.standard.set(eventsData, forKey: "generatedSchedule")
                UserDefaults.standard.set(Date(), forKey: "scheduleGeneratedAt")
                UserDefaults.standard.set(false, forKey: "isGeneratingSchedule")
            }
            
            // Try to save to Firebase if possible
            do {
                try await saveScheduleToFirebase(events: events)
            } catch {
                print("⚠️ Failed to save wake-up schedule to Firebase: \(error)")
            }
            
            // Send wake-up notification using NotificationManager
            await NotificationManager.shared.sendWakeUpScheduleNotification(eventCount: events.count)
            
            // Schedule event reminders for today's events
            await NotificationManager.shared.scheduleAllEventReminders(for: events)
            
        } catch {
            print("Failed to generate wake-up schedule: \(error)")
        }
    }
    
    private func handleBackgroundScheduleGeneration(task: BGProcessingTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        Task {
            do {
                try await performBackgroundScheduleGeneration()
                task.setTaskCompleted(success: true)
            } catch {
                print("Background schedule generation failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    @MainActor
    private func performBackgroundScheduleGeneration() async throws {
        // Get stored user data and generate schedule
        guard let userData = UserDefaults.standard.data(forKey: "cachedUserData"),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            throw NSError(domain: "BackgroundTaskManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "No cached user data"])
        }
        
        let userNote = UserDefaults.standard.string(forKey: "pendingUserNote") ?? ""
        
        let events = try await userInfoToSchedule(
            user: user,
            history: UserHistory(),
            note: userNote
        )
        
        // Save generated schedule locally
        if let eventsData = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(eventsData, forKey: "generatedSchedule")
            UserDefaults.standard.set(Date(), forKey: "scheduleGeneratedAt")
            UserDefaults.standard.set(false, forKey: "isGeneratingSchedule")
        }
        
        // Try to save to Firebase if possible
        do {
            try await saveScheduleToFirebase(events: events)
        } catch {
            print("⚠️ Failed to save background schedule to Firebase: \(error)")
        }
        
        // Send manual generation notification using NotificationManager
        await NotificationManager.shared.sendManualGenerationNotification(eventCount: events.count)
    }
    
    private func saveScheduleToFirebase(events: [Event]) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "BackgroundTaskManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
        }
        
        // Convert events to Firestore-compatible format
        let eventsData = events.map { event in
            return [
                "id": event.id.uuidString,
                "start": Timestamp(date: event.start),
                "end": Timestamp(date: event.end),
                "title": event.title,
                "eventType": event.eventType.rawValue
            ]
        }
        
        let db = Firestore.firestore()
        try await db
            .collection("users")
            .document(uid)
            .updateData([
                "currentSchedule": eventsData,
                "scheduleGeneratedAt": Timestamp(date: Date())
            ])
    }
    
    func beginBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "ScheduleGeneration") {
            self.endBackgroundTask()
        }
    }
    
    func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}