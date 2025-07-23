//
//  ContentModel.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/11/25.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import SwiftUI
import BackgroundTasks

@MainActor @Observable
class ContentModel {
    var user: User? = nil
    var userHistory: UserHistory? = nil
    
    var madeTodaySchedule = false
    
    var newUser: Bool? = nil
    
    var loggedIn = false
    var agreedToEULA = true //give them the benefit of the doubt haha :)
    
    // Add UI loading state that persists across views
    var isGeneratingSchedule = false
    
    private var showAlert: Bool = false
    
    private var email: String = ""
    private var password: String = ""
    private var isSecured: Bool = true
    
    // Add listener for real-time updates
    private var userListener: ListenerRegistration?
    
    let db = Firestore.firestore()
    
    func currentUID() -> String? {
        Auth.auth().currentUser?.uid
    }
    
    func debugUserState() {
        print("🔍 ContentModel Debug:")
        print("  • Auth user exists: \(Auth.auth().currentUser != nil)")
        print("  • Auth user UID: \(Auth.auth().currentUser?.uid ?? "nil")")
        print("  • Auth user email: \(Auth.auth().currentUser?.email ?? "nil")")
        print("  • loggedIn flag: \(loggedIn)")
        print("  • user model exists: \(user != nil)")
        print("  • user model name: \(user?.name ?? "nil")")
        print("  • user model email: \(user?.email ?? "nil")")
    }
    
    func checkLogin() {
        let wasLoggedIn = loggedIn
        loggedIn = Auth.auth().currentUser != nil
        
        print("🔍 CheckLogin called:")
        print("  • Was logged in: \(wasLoggedIn)")
        print("  • Now logged in: \(loggedIn)")
        
        // If newly logged in and no user data, try to fetch
        if loggedIn && user == nil {
            print("🔄 Logged in but no user data, fetching...")
            Task {
                do {
                    try await fetchUser()
                    print("✅ User data fetched successfully")
                } catch {
                    print("❌ Failed to fetch user data: \(error)")
                }
            }
        }
    }
    
    func onboardingComplete() async throws {
        guard let uid = currentUID() else { return }

        try await db
            .collection("users")
            .document(uid)
            .updateData(["new_user": false])
            
        self.newUser = false
    }
    
    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
        checkLogin()
        try await fetchUser()
        setupUserListener()
        await setupAutoScheduling()
    }
    
    // get user!!
    func fetchUser() async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "ContentModel", code: 401,
                          userInfo: [NSLocalizedDescriptionKey : "Not signed in"])
        }

        let snapshot = try await db
            .collection("users")
            .document(uid)
            .getDocument()

        guard snapshot.exists else { return }

        // Decode user using Codable
        user = try snapshot.data(as: User.self)
        
        // Ensure name and email are properly populated from the database
        if let name = snapshot.get("name") as? String {
            user?.name = name
        }
        if let email = snapshot.get("email") as? String {
            user?.email = email
        }
        
        // Handle currentSchedule separately as it might need special decoding from Firestore
        if let scheduleData = snapshot.get("currentSchedule") as? [[String: Any]] {
            let events = scheduleData.compactMap { eventDict -> Event? in
                guard let idString = eventDict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let startTimestamp = eventDict["start"] as? Timestamp,
                      let endTimestamp = eventDict["end"] as? Timestamp,
                      let title = eventDict["title"] as? String,
                      let eventTypeString = eventDict["eventType"] as? String,
                      let eventType = EventType(rawValue: eventTypeString) else {
                    return nil
                }
                
                return Event(
                    id: id,
                    start: startTimestamp.dateValue(),
                    end: endTimestamp.dateValue(),
                    title: title,
                    eventType: eventType
                )
            }
            user?.currentSchedule = events
            saveScheduleBackup(events: events)
            
        } else {
            // Save empty backup if no schedule
            saveScheduleBackup(events: [])
        }
        
        // Set up listener if not already done
        if userListener == nil {
            setupUserListener()
        }
    }
    
    func saveUserInfo() async throws {
        user?.email = Auth.auth().currentUser?.email ?? ""
        user?.name = Auth.auth().currentUser?.displayName ?? ""
        
        guard let uid = currentUID(), let userData = user else { return }
        try db.collection("users").document(uid).setData(from: userData, merge: true)
    }
    
    func googleSignIn(windowScene: UIWindowScene?) async throws {
        guard let rootVC = windowScene?.windows.first?.rootViewController else {
            throw URLError(.badServerResponse)
        }
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        
        let accessToken = result.user.accessToken.tokenString
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        let authResult = try await Auth.auth().signIn(with: credential)
        let authUser = authResult.user
        
        if authResult.additionalUserInfo?.isNewUser == true {
            let doc = db.collection("users").document(authUser.uid)
            
            try await doc.setData([
                "email": authUser.email ?? "",
                "name": authUser.displayName ?? "",
                "new_user": true,
                "accountCreated": Timestamp(date: Date()),
                "agreedToEULA": false
            ])
        }
        checkLogin()
        try await fetchUser()
        setupUserListener()
        await setupAutoScheduling()
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        loggedIn = false
        user = nil
        checkLogin()
    }
    
    func createAccount(email: String, name: String, password: String) async throws {
        
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        
        try await db
            .collection("users")
            .document(result.user.uid)
            .setData([
                "email": email,
                "name": name,
                "new_user": true,
                "accountCreated": Timestamp(date: Date()),
                "agreedToEULA": false
            ])
        checkLogin()
        try await fetchUser()
        setupUserListener()
        await setupAutoScheduling()
    }
    
    
    func checkIfEmailExists(email: String, completion: @escaping (Bool, Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: "TemporaryPassword123") { authResult, error in
            if let error = error as NSError? {
                // Check if the error indicates the email is already in use
                if error.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                    completion(true, nil) // Email exists
                } else {
                    completion(false, error) // Other error (e.g., invalid email, network issue)
                }
            } else {
                // User was created successfully, but we don't want a new user
                // Delete the temporary user to avoid cluttering Firebase
                if let user = authResult?.user {
                    user.delete { deletionError in
                        if let deletionError = deletionError {
                            print("Failed to delete temporary user: \(deletionError.localizedDescription)")
                        }
                        completion(false, nil) // Email does not exist
                    }
                } else {
                    completion(false, nil) // Email does not exist
                }
            }
        }
    }
    
    func checkNewUser() async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw URLError(.userAuthenticationRequired)
        }

        // Firestore fetch runs on a background thread
        let snapshot = try await db
            .collection("users")
            .document(uid)
            .getDocument()

        let flag = snapshot.get("new_user") as? Bool ?? false
        self.newUser = flag                              // safe: already on MainActor
    }
    
    
    
    //Schedule made for today?-related functions
    
    ////"HH:mm" (24-hour) → Date *today* at that time.
    /// Returns `nil` if the string is malformed (e.g. "25:90").
    private func today(at hhmm: String) -> Date? {
        let parts = hhmm.split(separator: ":")
        guard parts.count == 2,
              let h = Int(parts[0]), (0...23).contains(h),
              let m = Int(parts[1]), (0...59).contains(m)
        else { return nil }

        var dc = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        dc.hour = h
        dc.minute = m
        return Calendar.current.date(from: dc)
    }
    
    func hasMadeSchedule(wakeHHMM: String, markDone: Bool = false) -> Bool {

        let key = "lastScheduleMade"
        let now = Date()
        guard let wakeToday = today(at: wakeHHMM) else { return false }

        let windowStart = Calendar.current.date(byAdding: .hour, value: -3, to: wakeToday)!
       
        let windowEnd = windowStart > now
            ? wakeToday
            : Calendar.current.date(byAdding: .day, value: 1, to: windowStart)!

        if markDone { UserDefaults.standard.set(now, forKey: key) }

        if let saved = UserDefaults.standard.object(forKey: key) as? Date {
            return saved >= windowStart && saved < windowEnd
        }
        return false
    }
    
    //------------------------------ Generate Schedule In Background -------------------------------------
    
    func generateScheduleWithBackgroundSupport(userNote: String = "") async throws -> [Event] {
        // Set UI loading state
        isGeneratingSchedule = true
        
        // Start background task
        BackgroundTaskManager.shared.beginBackgroundTask()
        
        // Cache user data for background access
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "cachedUserData")
        }
        
        // Store generation state
        UserDefaults.standard.set(true, forKey: "isGeneratingSchedule")
        UserDefaults.standard.set(userNote, forKey: "pendingUserNote")
        UserDefaults.standard.set(Date(), forKey: "generationStartTime")
        
        // Schedule background continuation
        BackgroundTaskManager.shared.scheduleBackgroundTask()
        
        defer {
            BackgroundTaskManager.shared.endBackgroundTask()
            UserDefaults.standard.set(false, forKey: "isGeneratingSchedule")
            UserDefaults.standard.removeObject(forKey: "pendingUserNote")
            // Reset UI loading state
            isGeneratingSchedule = false
        }
        
        guard let user = self.user else {
            throw NSError(domain: "ContentModel", code: 400, userInfo: [NSLocalizedDescriptionKey: "No user found"])
        }
        
        do {
            let events = try await userInfoToSchedule(
                user: user,
                history: self.userHistory ?? UserHistory(),
                note: userNote
            )
            
            // Save as backup
            if let eventsData = try? JSONEncoder().encode(events) {
                UserDefaults.standard.set(eventsData, forKey: "generatedSchedule")
                UserDefaults.standard.set(Date(), forKey: "scheduleGeneratedAt")
                UserDefaults.standard.set(false, forKey: "backupFromFirebase")
            }
            
            // Save to user's currentSchedule and Firebase
            await MainActor.run {
                self.user?.currentSchedule = events
            }
            
            // Save to Firebase
            do {
                try await saveCurrentScheduleToFirebase(events: events)
            } catch {
                print("⚠️ Failed to save schedule to Firebase: \(error)")
                // Continue anyway, as we have it locally
            }
            
            return events
            
        } catch {
            print("Schedule generation failed: \(error)")
            throw error
        }
    }
    
    private func saveCurrentScheduleToFirebase(events: [Event]) async throws {
        guard let uid = currentUID() else {
            throw NSError(domain: "ContentModel", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
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
        
        do {
            try await db
                .collection("users")
                .document(uid)
                .updateData([
                    "currentSchedule": eventsData,
                    "scheduleGeneratedAt": Timestamp(date: Date())
                ])
            print("✅ Successfully saved schedule to Firebase")
        } catch {
            print("❌ Firebase save failed: \(error)")
            throw error
        }
    }
    
    func checkForCompletedSchedule() -> [Event]? {
        // Don't return backup if user explicitly has an empty currentSchedule
        if let user = self.user {
            // User has explicitly set currentSchedule (even if empty) - don't use backup
            return user.currentSchedule.isEmpty ? nil : user.currentSchedule
        }
        
        // Only use backup if user has no currentSchedule field at all
        guard let eventsData = UserDefaults.standard.data(forKey: "generatedSchedule"),
              let events = try? JSONDecoder().decode([Event].self, from: eventsData),
              !events.isEmpty,
              let generatedAt = UserDefaults.standard.object(forKey: "scheduleGeneratedAt") as? Date else {
            return nil
        }
        
        // Consider valid if generated within last 12 hours
        let isRecent = Date().timeIntervalSince(generatedAt) < 12 * 60 * 60
        return isRecent ? events : nil
    }
    
    func isGeneratingInBackground() -> Bool {
        return UserDefaults.standard.bool(forKey: "isGeneratingSchedule")
    }
    
    func clearAllScheduleData() {
        // Clear local user model
        user?.currentSchedule = []
        
        // Clear UserDefaults backup
        UserDefaults.standard.removeObject(forKey: "generatedSchedule")
        UserDefaults.standard.removeObject(forKey: "scheduleGeneratedAt")
        UserDefaults.standard.removeObject(forKey: "cachedUserData")
        UserDefaults.standard.removeObject(forKey: "backupFromFirebase")
        UserDefaults.standard.set(false, forKey: "isGeneratingSchedule")
        
        print("🧹 Cleared all local schedule data")
    }
    
    func logScheduleDataSources() {
        print("📊 Schedule Data Sources:")
        print("• User.currentSchedule: \(user?.currentSchedule.count ?? 0) events")
        
        if UserDefaults.standard.data(forKey: "generatedSchedule") != nil {
            print("• UserDefaults backup: EXISTS")
        } else {
            print("• UserDefaults backup: NONE")
        }
        
        print("• Background generating: \(isGeneratingInBackground())")
    }
    
    func debugScheduleState() {
        print("🔍 Schedule Debug State:")
        if let schedule = user?.currentSchedule {
            print("  • User.currentSchedule: \(schedule.count) events")
            if schedule.isEmpty {
                print("    ↳ Schedule exists but is EMPTY")
            } else {
                print("    ↳ Events: \(schedule.map { $0.title }.joined(separator: ", "))")
            }
        } else {
            print("  • User.currentSchedule: nil")
        }
        
        if let eventsData = UserDefaults.standard.data(forKey: "generatedSchedule"),
           let events = try? JSONDecoder().decode([Event].self, from: eventsData) {
            print("  • UserDefaults backup: \(events.count) events")
        } else {
            print("  • UserDefaults backup: none")
        }
        
        print("  • Background generating: \(isGeneratingInBackground())")
    }
    
    func refreshUserData() async throws {
        guard let uid = currentUID() else {
            throw NSError(domain: "ContentModel", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
        }

        let snapshot = try await db
            .collection("users")
            .document(uid)
            .getDocument()

        guard snapshot.exists else { return }

        // Decode user using Codable
        let freshUser = try snapshot.data(as: User.self)
        
        // Handle currentSchedule separately as it might need special decoding from Firestore
        if let scheduleData = snapshot.get("currentSchedule") as? [[String: Any]] {
            let events = scheduleData.compactMap { eventDict -> Event? in
                guard let idString = eventDict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let startTimestamp = eventDict["start"] as? Timestamp,
                      let endTimestamp = eventDict["end"] as? Timestamp,
                      let title = eventDict["title"] as? String,
                      let eventTypeString = eventDict["eventType"] as? String,
                      let eventType = EventType(rawValue: eventTypeString) else {
                    return nil
                }
                
                return Event(
                    id: id,
                    start: startTimestamp.dateValue(),
                    end: endTimestamp.dateValue(),
                    title: title,
                    eventType: eventType
                )
            }
            
            var updatedUser = freshUser
            updatedUser.name = snapshot.get("name") as? String ?? freshUser.name
            updatedUser.email = snapshot.get("email") as? String ?? freshUser.email
            updatedUser.currentSchedule = events
        
            self.user = updatedUser
            saveScheduleBackup(events: events)
        
        } else {
            // No schedule data field exists - treat as empty
            var updatedUser = freshUser
            updatedUser.name = snapshot.get("name") as? String ?? freshUser.name
            updatedUser.email = snapshot.get("email") as? String ?? freshUser.email
            updatedUser.currentSchedule = []
        
            self.user = updatedUser
            saveScheduleBackup(events: [])
        }
    }
    
    private func saveScheduleBackup(events: [Event], isFromFirebase: Bool = false) {
        if let eventsData = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(eventsData, forKey: "generatedSchedule")
            UserDefaults.standard.set(Date(), forKey: "scheduleGeneratedAt")
            UserDefaults.standard.set(isFromFirebase, forKey: "backupFromFirebase")
        }
    }
    
    func setupUserListener() {
        guard let uid = currentUID() else { return }
        
        // Remove existing listener if any
        userListener?.remove()
        
        // Set up new listener for user document changes
        userListener = db.collection("users").document(uid).addSnapshotListener { [weak self] snapshot, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ User listener error: \(error)")
                    return
                }
                
                guard let snapshot = snapshot, snapshot.exists else { return }
                
                do {
                    // Decode the updated user data
                    let updatedUser = try snapshot.data(as: User.self)
                    
                    // Handle currentSchedule separately for proper decoding
                    if let scheduleData = snapshot.get("currentSchedule") as? [[String: Any]] {
                        let events = scheduleData.compactMap { eventDict -> Event? in
                            guard let idString = eventDict["id"] as? String,
                                  let id = UUID(uuidString: idString),
                                  let startTimestamp = eventDict["start"] as? Timestamp,
                                  let endTimestamp = eventDict["end"] as? Timestamp,
                                  let title = eventDict["title"] as? String,
                                  let eventTypeString = eventDict["eventType"] as? String,
                                  let eventType = EventType(rawValue: eventTypeString) else {
                                return nil
                            }
                            
                            return Event(
                                id: id,
                                start: startTimestamp.dateValue(),
                                end: endTimestamp.dateValue(),
                                title: title,
                                eventType: eventType
                            )
                        }
                        
                        var finalUser = updatedUser
                        finalUser.name = snapshot.get("name") as? String ?? updatedUser.name
                        finalUser.email = snapshot.get("email") as? String ?? updatedUser.email
                        finalUser.currentSchedule = events
                        
                        // Always update to match Firebase exactly
                        self.user = finalUser
                        
                        // Save backup AFTER updating user, and mark as Firebase-sourced
                        self.saveScheduleBackup(events: events, isFromFirebase: true)
                        
                    } else {
                        // No schedule data field exists - treat as empty
                        var finalUser = updatedUser
                        finalUser.name = snapshot.get("name") as? String ?? updatedUser.name
                        finalUser.email = snapshot.get("email") as? String ?? updatedUser.email
                        finalUser.currentSchedule = []
                        
                        self.user = finalUser
                        self.saveScheduleBackup(events: [], isFromFirebase: true)
                    }
                    
                } catch {
                    print("❌ Error decoding user update: \(error)")
                }
            }
        }
    }
    
    func setupAutoScheduling() async {
        guard let user = self.user else { return }
        
        // Set default auto-schedule to enabled
        if !UserDefaults.standard.bool(forKey: "hasSetAutoSchedule") {
            UserDefaults.standard.set(true, forKey: "autoScheduleEnabled")
            UserDefaults.standard.set(true, forKey: "hasSetAutoSchedule")
        }
        
        // Schedule wake-up generation if auto-scheduling is enabled
        if UserDefaults.standard.bool(forKey: "autoScheduleEnabled") {
            let wakeTime = user.todaysAwakeHours?.wakeTime ?? user.awakeHours.wakeTime
            BackgroundTaskManager.shared.scheduleWakeUpGeneration(wakeUpTime: wakeTime)
            
            // Cache user data for background generation
            if let userData = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(userData, forKey: "cachedUserData")
            }
        }
        
        // Set up notifications
        await setupNotifications()
    }

    func setupNotifications() async {
        // Request permissions
        let granted = await NotificationManager.shared.requestPermissions()
        if granted {
            NotificationManager.shared.setupNotificationCategories()
        }
    }

    func checkForDayCompletion() async {
        guard let user = self.user else { return }
        
        let now = Date()
        let remainingEvents = user.currentSchedule.filter { event in
            event.start > now && !event.title.contains("NGTime")
        }
        
        if remainingEvents.isEmpty && !user.currentSchedule.isEmpty {
            await NotificationManager.shared.sendDayCompleteNotification()
        }
    }
    
    func toggleAutoScheduling(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "autoScheduleEnabled")
        
        if enabled {
            // Enable auto-scheduling
            if let user = self.user {
                let wakeTime = user.todaysAwakeHours?.wakeTime ?? user.awakeHours.wakeTime
                BackgroundTaskManager.shared.scheduleWakeUpGeneration(wakeUpTime: wakeTime)
                
                // Cache user data
                if let userData = try? JSONEncoder().encode(user) {
                    UserDefaults.standard.set(userData, forKey: "cachedUserData")
                }
            }
        } else {
            // Disable auto-scheduling
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: "com.timeflow.wakeupschedule")
        }
    }

    func isAutoSchedulingEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "autoScheduleEnabled")
    }
    
    func checkForBackgroundGenerationOnStartup() {
        // Check if generation was happening when app went to background
        if UserDefaults.standard.bool(forKey: "isGeneratingSchedule") {
            isGeneratingSchedule = true
            
            // Start monitoring for completion
            monitorBackgroundGeneration()
        }
    }
    
    private func monitorBackgroundGeneration() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            Task { @MainActor in
                if !self.isGeneratingInBackground() {
                    timer.invalidate()
                    self.isGeneratingSchedule = false
                    
                    // Try to load completed schedule
                    if let completedEvents = self.checkForCompletedSchedule() {
                        self.user?.currentSchedule = completedEvents
                        
                        Task {
                            try? await self.saveUserInfo()
                        }
                    }
                }
            }
        }
    }
}