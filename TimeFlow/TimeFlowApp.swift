//
//  TimeFlowApp.swift
//  TimeFlow
//
//  Created by Adam Ress on 5/29/25.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct TimeFlowApp: App {
    
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
