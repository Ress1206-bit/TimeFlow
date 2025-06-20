//
//  AccountView.swift
//  TimeFlow
//
//  Created by Adam Ress on 5/29/25.
//

import SwiftUI

struct AccountView: View {
    
    @Environment(ContentModel.self) private var contentModel
    
    
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack {
            
            Text("Account View")
                .padding()
            
            Spacer()
            
            Button {
                contentModel.signOut()
                contentModel.checkLogin()
            } label: {
                ZStack {
                    Rectangle()
                        .frame(width: 250, height: 150)
                        .foregroundStyle(.red)
                    Text("Sign Out")
                        .foregroundStyle(.white)
                }
            }

            
            TabView(selectedTab: $selectedTab)
        }
    }
}

#Preview {
    AccountView(selectedTab: .constant(0))
}
