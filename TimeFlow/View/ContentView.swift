//
//  ContentView.swift
//  TimeFlow
//
//  Created by Adam Ress on 5/29/25.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(ContentModel.self) private var contentModel
    
    @State private var selectedTab = 0
    
    private var isYoungProfessional: Bool {
        contentModel.user?.ageGroup == .youngProfessional
    }
    
    var body: some View {
        if selectedTab == 0 {
            
            HomeView(selectedTab: $selectedTab)
            
            
        } else if selectedTab == 1 {
            
            GoalsDisplayView(selectedTab: $selectedTab)
            
        } else if selectedTab == 2 {
            
            if isYoungProfessional {
                // Young professionals: tab 2 = commitments
                ExtraCommitmentsView(selectedTab: $selectedTab)
            } else {
                // Students: tab 2 = assignments
                AssignmentsView(selectedTabPage: $selectedTab)
            }
            
        } else if selectedTab == 3 {
            
            if isYoungProfessional {
                // Young professionals: tab 3 = analytics
                AnalyticsView(selectedTab: $selectedTab)
            } else {
                // Students: tab 3 = commitments
                ExtraCommitmentsView(selectedTab: $selectedTab)
            }
            
        } else if selectedTab == 4 {
            
            // Only students have tab 4 (analytics)
            AnalyticsView(selectedTab: $selectedTab)
            
        }
    }
}

#Preview {
    ContentView()
        .environment(ContentModel())
}
