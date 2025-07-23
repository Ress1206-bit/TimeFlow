//
//  TimeFlowApp.swift
//  TimeFlow
//
//  Created by Adam Ress on 5/29/25.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn
import UIKit
import BackgroundTasks

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Register background tasks
        BackgroundTaskManager.shared.registerBackgroundTasks()
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Schedule background task if generation is ongoing
        if UserDefaults.standard.bool(forKey: "isGeneratingSchedule") {
            BackgroundTaskManager.shared.scheduleBackgroundTask()
        }
    }
}

@main
struct TimeFlowApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State var contentModel: ContentModel
    
    init() {
        FirebaseApp.configure()
        
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
        
        
        contentModel = ContentModel()
    }
    
    var body: some Scene {
        WindowGroup {
            LaunchView()
                .environment(contentModel)
        }
    }
}
