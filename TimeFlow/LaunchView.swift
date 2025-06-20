//
//  LaunchView.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/11/25.
//

import SwiftUI
import FirebaseAuth

struct LaunchView: View {
    
    @Environment(ContentModel.self) var contentModel
        

    var body: some View {
        
        NavigationStack {
            if !contentModel.loggedIn {
                
                SignInLandingView()
                
            } else {
                
                ContentView()
                
            }
        }
        .task {
            contentModel.checkLogin()
        }
    }
}

#Preview {
    LaunchView()
        .environment(ContentModel())
}
