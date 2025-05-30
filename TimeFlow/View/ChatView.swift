//
//  ChatView.swift
//  TimeFlow
//
//  Created by Adam Ress on 5/29/25.
//

import SwiftUI

struct ChatView: View {
    
    @Binding var selectedTab: Int
    
    var body: some View {
        
        VStack {
            Text("Chat View")
                .padding()
            
            Spacer()
            
            TabView(selectedTab: $selectedTab)
            
        }
    }
}

#Preview {
    ChatView(selectedTab: .constant(0))
}
