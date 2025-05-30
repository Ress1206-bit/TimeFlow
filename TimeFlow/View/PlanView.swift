//
//  PlanView.swift
//  TimeFlow
//
//  Created by Adam Ress on 5/29/25.
//

import SwiftUI

struct PlanView: View {
    
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack {
            Text("Plan View")
                .padding()
            
            Spacer()
            
            TabView(selectedTab: $selectedTab)
        }
    }
}

#Preview {
    PlanView(selectedTab: .constant(0))
}
