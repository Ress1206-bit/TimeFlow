//
//  ContentView.swift
//  TimeFlow
//
//  Created by Adam Ress on 5/29/25.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var chatVM = ChatViewModel()
    
    
    @State private var selectedTab = 0
    
    
    var body: some View {
        if selectedTab == 0 {
            
            HomeView(selectedTab: $selectedTab)
            
        } else if selectedTab == 1 {
            
            ChatView(selectedTab: $selectedTab)
                .environmentObject(chatVM)
            
        } else if selectedTab == 2 {
            
            PlanView(selectedTab: $selectedTab)
            
        } else if selectedTab == 3 {
            
            AnalyticsView(selectedTab: $selectedTab)
            
        } else if selectedTab == 4 {
            
            AccountView(selectedTab: $selectedTab)
            
        }
    }
}

#Preview {
    ContentView()
}
