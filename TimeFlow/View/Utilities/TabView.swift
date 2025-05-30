//
//  TabView.swift
//  TimeFlow
//
//  Created by Adam Ress on 5/29/25.
//

import SwiftUI

struct TabView: View {
    
    @Binding var selectedTab: Int
    
    
    var body: some View {
        
        ZStack
        {
            Rectangle()
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .frame(height: 80)
                .padding(.horizontal, 85)
                .foregroundStyle(.white)
                .opacity(0.4)
            
            HStack{
                VStack {
                    Image(systemName: "house")
                        .foregroundColor(selectedTab == 0 ? Color(red: 0.223, green: 0.112, blue: 0.772) : .black)
                        .padding(.bottom, 3)
                    Text("Home")
                        .foregroundColor(selectedTab == 0 ? Color(red: 0.223, green: 0.112, blue: 0.772) : .black)
                        .font(.system(size: 10))
                }
                    .padding(.horizontal, 8)
                    .onTapGesture { selectedTab = 0 }
                
                
                VStack {
                    Image(systemName: "message")
                        .foregroundColor(selectedTab == 1 ? Color(red: 0.223, green: 0.112, blue: 0.772) : .black)
                        .padding(.bottom, 3)
                    Text("Chat")
                        .foregroundColor(selectedTab == 1 ? Color(red: 0.223, green: 0.112, blue: 0.772) : .black)
                        .font(.system(size: 10))
                }
                    .padding(.horizontal, 8)
                    .onTapGesture { selectedTab = 1 }
                
                
                VStack {
                    Image(systemName: "calendar")
                        .foregroundColor(selectedTab == 2 ? Color(red: 0.223, green: 0.112, blue: 0.772) : .black)
                        .padding(.bottom, 3)
                    Text("Plan")
                        .foregroundColor(selectedTab == 2 ? Color(red: 0.223, green: 0.112, blue: 0.772) : .black)
                        .font(.system(size: 10))
                }
                    .padding(.horizontal, 8)
                    .onTapGesture { selectedTab = 2 }
                
                
                VStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(selectedTab == 3 ? Color(red: 0.223, green: 0.112, blue: 0.772) : .black)
                        .padding(.bottom, 3)
                    Text("Analytics")
                        .foregroundColor(selectedTab == 3 ? Color(red: 0.223, green: 0.112, blue: 0.772) : .black)
                        .font(.system(size: 10))
                }
                    .padding(.horizontal, 8)
                    .onTapGesture { selectedTab = 3 }
                
                
                VStack {
                    Image(systemName: "person")
                        .foregroundColor(selectedTab == 4 ? Color(red: 0.223, green: 0.112, blue: 0.772) : .black)
                        .padding(.bottom, 3)
                    Text("Account")
                        .foregroundColor(selectedTab == 4 ? Color(red: 0.223, green: 0.112, blue: 0.772) : .black)
                        .font(.system(size: 10))
                }
                    .padding(.horizontal, 8)
                    .onTapGesture { selectedTab = 4 }
                
                

            }
            .font(.title)
        }
    }
}
