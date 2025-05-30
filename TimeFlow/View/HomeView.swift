//
//  HomeView.swift
//  TimeFlow
//
//  Created by Adam Ress on 5/29/25.
//

import SwiftUI

struct HomeView: View {
    
    @Binding var selectedTab: Int
    
    var body: some View {
        ZStack
        {
            Image("blurbackground")
                .resizable()
                .ignoresSafeArea()
            
            VStack{
                Text("Today's Schedule")
                    .font(.system(size: 40))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Rectangle()
                    .foregroundStyle(.white)
                    .opacity(0.9)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                
                TabView(selectedTab: $selectedTab)
            }
        }
    }
}

#Preview {
    HomeView(selectedTab: .constant(0))
}
