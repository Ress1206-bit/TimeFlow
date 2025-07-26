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
            
            GoalsDisplayView(selectedTab: $selectedTab)
            
        } else if selectedTab == 2 {
            
            AssignmentsView(selectedTabPage: $selectedTab)
            
        } else if selectedTab == 3 {
            
            ExtraCommitmentsView(selectedTab: $selectedTab)
            
        } else if selectedTab == 4 {
            
            AnalyticsView(selectedTab: $selectedTab)
            
        }
    }
}

#Preview {
    ContentView()
}
