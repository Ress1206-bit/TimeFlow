//
//  AccountView.swift
//  TimeFlow
//
//  Created by Adam Ress on 5/29/25.
//

import SwiftUI

struct AccountView: View {
    
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack {
            
            Text("Account View")
                .padding()
            
            Spacer()
            
            TabView(selectedTab: $selectedTab)
        }
    }
}

#Preview {
    AccountView(selectedTab: .constant(0))
}
