//
//  AnalyticsView.swift
//  TimeFlow
//
//  Created by Adam Ress on 5/29/25.
//

import SwiftUI

struct AnalyticsView: View {
    
    @Binding var selectedTab: Int
    
    var body: some View {
        
        VStack {
            
            Text("Analystics View")
                .padding()
            
            Spacer()
            
            TabView(selectedTab: $selectedTab)
        }
    }
}

#Preview {
    AnalyticsView(selectedTab: .constant(0))
}
