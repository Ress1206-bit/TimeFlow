//
//  TimeFlowApp.swift
//  TimeFlow
//
//  Created by Adam Ress on 5/29/25.
//

import SwiftUI
import FirebaseCore

@main
struct TimeFlowApp: App {
    
    @State var contentModel: ContentModel
    
    init() {
        FirebaseApp.configure()
        contentModel = ContentModel()
    }
    
    var body: some Scene {
        WindowGroup {
            LaunchView()
                .environment(contentModel)
        }
    }
}
