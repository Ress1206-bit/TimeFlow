//
//  NotificationManager.swift
//  TimeFlow
//
//  Created by Adam Ress on 7/22/25.
//
// Heavily assisted by Claude Sonnet 4

import Foundation
import UserNotifications
import UIKit

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    // Notification Types
    enum NotificationType: String, CaseIterable {
        case wakeUpSchedule = "wake_up_schedule"
        case manualGeneration = "manual_generation"
        case eventReminders = "event_reminders"
        case dayComplete = "day_complete"
        case goalReminders = "goal_reminders"
        case assignmentDeadlines = "assignment_deadlines"
        
        var displayName: String {
            switch self {
            case .wakeUpSchedule: return "Morning Schedule"
            case .manualGeneration: return "Schedule Updates"
            case .eventReminders: return "Event Reminders"
            case .dayComplete: return "Day Complete"
            case .goalReminders: return "Goal Reminders"
            case .assignmentDeadlines: return "Assignment Deadlines"
            }
        }
        
        var description: String {
            switch self {
            case .wakeUpSchedule: return "Get notified when your daily schedule is ready"
            case .manualGeneration: return "Updates when you manually generate a schedule"
            case .eventReminders: return "Reminders before events start"
            case .dayComplete: return "Celebrate when you complete your daily schedule"
            case .goalReminders: return "Motivational reminders for your goals"
            case .assignmentDeadlines: return "Alerts for upcoming assignment due dates"
            }
        }
        
        var icon: String {
            switch self {
            case .wakeUpSchedule: return "sun.max.fill"
            case .manualGeneration: return "arrow.clockwise"
            case .eventReminders: return "bell.fill"
            case .dayComplete: return "checkmark.circle.fill"
            case .goalReminders: return "target"
            case .assignmentDeadlines: return "exclamationmark.triangle.fill"
            }
        }
        
        var defaultEnabled: Bool {
            switch self {
            case .wakeUpSchedule: return true
            case .manualGeneration: return true
            case .eventReminders: return true
            case .dayComplete: return true
            case .goalReminders: return false // Opt-in
            case .assignmentDeadlines: return true
            }
        }
    }
    
    private init() {
        setupDefaultPreferences()
    }
    
    // MARK: - Permission Management
    
    func requestPermissions() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            print("❌ Failed to request notification permissions: \(error)")
            return false
        }
    }
    
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Preference Management
    
    private func setupDefaultPreferences() {
        let hasSetupDefaults = UserDefaults.standard.bool(forKey: "hasSetupNotificationDefaults")
        
        if !hasSetupDefaults {
            for notificationType in NotificationType.allCases {
                UserDefaults.standard.set(notificationType.defaultEnabled, forKey: preferenceKey(for: notificationType))
            }
            UserDefaults.standard.set(true, forKey: "hasSetupNotificationDefaults")
        }
    }
    
    private func preferenceKey(for type: NotificationType) -> String {
        return "notification_\(type.rawValue)_enabled"
    }
    
    func isEnabled(_ type: NotificationType) -> Bool {
        return UserDefaults.standard.bool(forKey: preferenceKey(for: type))
    }
    
    func setEnabled(_ type: NotificationType, enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: preferenceKey(for: type))
        objectWillChange.send()
    }
    
    // MARK: - Notification Sending
    
    func sendWakeUpScheduleNotification(eventCount: Int) async {
        guard isEnabled(.wakeUpSchedule) else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Good Morning! 🌅"
        content.body = eventCount > 0
            ? "Your schedule is ready with \(eventCount) activities planned for today."
            : "Your schedule is ready! Looks like you have a free day ahead. Let's get started by adding some activities."
        content.sound = .default
        content.categoryIdentifier = "SCHEDULE_READY"
        
        await sendNotification(content: content, identifier: "wake_up_schedule_\(Date().timeIntervalSince1970)")
    }
    
    func sendManualGenerationNotification(eventCount: Int) async {
        guard isEnabled(.manualGeneration) else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Schedule Updated"
        content.body = "Your schedule has been updated with \(eventCount) activities."
        content.sound = .default
        
        await sendNotification(content: content, identifier: "manual_generation_\(Date().timeIntervalSince1970)")
    }
    
    func scheduleEventReminder(for event: Event, minutesBefore: Int = 10) async {
        guard isEnabled(.eventReminders) else { return }
        
        let reminderTime = event.start.addingTimeInterval(-TimeInterval(minutesBefore * 60))
        
        // Don't schedule if reminder time is in the past
        guard reminderTime > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Event"
        content.body = "\(event.title) starts in \(minutesBefore) minutes"
        content.sound = .default
        content.categoryIdentifier = "EVENT_REMINDER"
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: reminderTime.timeIntervalSinceNow,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "event_reminder_\(event.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("📅 Scheduled reminder for: \(event.title)")
        } catch {
            print("❌ Failed to schedule event reminder: \(error)")
        }
    }
    
    func sendDayCompleteNotification() async {
        guard isEnabled(.dayComplete) else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Day Complete! 🎉"
        content.body = "Congratulations! You've finished all your scheduled activities for today."
        content.sound = .default
        content.categoryIdentifier = "DAY_COMPLETE"
        
        await sendNotification(content: content, identifier: "day_complete_\(Date().timeIntervalSince1970)")
    }
    
    func scheduleGoalReminder(goalTitle: String, at time: Date) async {
        guard isEnabled(.goalReminders) else { return }
        guard time > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Goal Reminder 🎯"
        content.body = "Don't forget about your goal: \(goalTitle)"
        content.sound = .default
        content.categoryIdentifier = "GOAL_REMINDER"
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: time.timeIntervalSinceNow,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "goal_reminder_\(goalTitle.lowercased().replacingOccurrences(of: " ", with: "_"))",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("🎯 Scheduled goal reminder: \(goalTitle)")
        } catch {
            print("❌ Failed to schedule goal reminder: \(error)")
        }
    }
    
    func scheduleAssignmentDeadlineReminder(assignment: Assignment, hoursBefore: Int = 24) async {
        guard isEnabled(.assignmentDeadlines) else { return }
        
        let reminderTime = assignment.dueDate.addingTimeInterval(-TimeInterval(hoursBefore * 3600))
        guard reminderTime > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Assignment Due Soon ⚠️"
        content.body = "\(assignment.assignmentTitle) is due in \(hoursBefore) hours"
        content.sound = .default
        content.categoryIdentifier = "ASSIGNMENT_DEADLINE"
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: reminderTime.timeIntervalSinceNow,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "assignment_deadline_\(assignment.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("📝 Scheduled assignment reminder: \(assignment.assignmentTitle)")
        } catch {
            print("❌ Failed to schedule assignment reminder: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func sendNotification(content: UNMutableNotificationContent, identifier: String) async {
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("❌ Failed to send notification: \(error)")
        }
    }
    
    func cancelEventReminders(for event: Event) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["event_reminder_\(event.id.uuidString)"]
        )
    }
    
    func cancelAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func cancelNotifications(of type: NotificationType) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToCancel = requests
                .filter { $0.identifier.contains(type.rawValue) }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
        }
    }
    
    // MARK: - Bulk Operations
    
    func scheduleAllEventReminders(for events: [Event]) async {
        for event in events {
            await scheduleEventReminder(for: event)
        }
    }
    
    func scheduleAllAssignmentReminders(for assignments: [Assignment]) async {
        for assignment in assignments.filter({ !$0.completed }) {
            await scheduleAssignmentDeadlineReminder(assignment: assignment)
        }
    }
}

// MARK: - Notification Categories Setup
extension NotificationManager {
    func setupNotificationCategories() {
        let scheduleReadyActions = [
            UNNotificationAction(
                identifier: "VIEW_SCHEDULE",
                title: "View Schedule",
                options: [.foreground]
            )
        ]
        
        let eventReminderActions = [
            UNNotificationAction(
                identifier: "SNOOZE_5",
                title: "Remind in 5 min",
                options: []
            ),
            UNNotificationAction(
                identifier: "MARK_STARTED",
                title: "I'm ready",
                options: []
            )
        ]
        
        let categories = [
            UNNotificationCategory(
                identifier: "SCHEDULE_READY",
                actions: scheduleReadyActions,
                intentIdentifiers: [],
                options: []
            ),
            UNNotificationCategory(
                identifier: "EVENT_REMINDER",
                actions: eventReminderActions,
                intentIdentifiers: [],
                options: []
            ),
            UNNotificationCategory(
                identifier: "DAY_COMPLETE",
                actions: [],
                intentIdentifiers: [],
                options: []
            ),
            UNNotificationCategory(
                identifier: "GOAL_REMINDER",
                actions: [],
                intentIdentifiers: [],
                options: []
            ),
            UNNotificationCategory(
                identifier: "ASSIGNMENT_DEADLINE",
                actions: [],
                intentIdentifiers: [],
                options: []
            )
        ]
        
        UNUserNotificationCenter.current().setNotificationCategories(Set(categories))
    }
}
