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
                //.foregroundStyle(.white)
                .foregroundStyle(Color(red: 0.664, green: 0.695, blue: 0.996))
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .frame(height: 80)
                .padding(.horizontal, 30)
                .foregroundStyle(.white)
                //.opacity(0.4)
            
            HStack{
                VStack {
                    Image(systemName: "house")
                        .foregroundColor(selectedTab == 0 ? Color(red: 0.223, green: 0.112, blue: 0.772) : .black)
                        .font(.system(size: 25))
                        .padding(.bottom, 0.1)
                    Text("Home")
                        .foregroundColor(selectedTab == 0 ? Color(red: 0.223, green: 0.112, blue: 0.772) : .black)
                        .font(.system(size: 10))
                }
                    .padding(.horizontal, 8)
                    .onTapGesture { selectedTab = 0 }
                
                
                VStack {
                    Image(systemName: "message")
                        .foregroundColor(selectedTab == 1 ? Color(red: 0.223, green: 0.112, blue: 0.772) : .black)
                        .font(.system(size: 25))
                        .padding(.bottom, 0.1)
                    Text("Chat")
                        .foregroundColor(selectedTab == 1 ? Color(red: 0.223, green: 0.112, blue: 0.772) : .black)
                        .font(.system(size: 10))
                }
                    .padding(.horizontal, 8)
                    .onTapGesture { selectedTab = 1 }
                
                
                VStack {
                    Image(systemName: "calendar")
                        .foregroundColor(selectedTab == 2 ? Color(red: 0.223, green: 0.112, blue: 0.772) : .black)
                        .font(.system(size: 25))
                        .padding(.bottom, 0.1)
                    Text("Plan")
                        .foregroundColor(selectedTab == 2 ? Color(red: 0.223, green: 0.112, blue: 0.772) : .black)
                        .font(.system(size: 10))
                }
                    .padding(.horizontal, 8)
                    .onTapGesture { selectedTab = 2 }
                
                
                VStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(selectedTab == 3 ? Color(red: 0.223, green: 0.112, blue: 0.772) : .black)
                        .font(.system(size: 25))
                        .padding(.bottom, 0.1)
                    Text("Analytics")
                        .foregroundColor(selectedTab == 3 ? Color(red: 0.223, green: 0.112, blue: 0.772) : .black)
                        .font(.system(size: 10))
                }
                    .padding(.horizontal, 8)
                    .onTapGesture { selectedTab = 3 }
                
                
                VStack {
                    Image(systemName: "person")
                        .foregroundColor(selectedTab == 4 ? Color(red: 0.223, green: 0.112, blue: 0.772) : .black)
                        .font(.system(size: 25))
                        .padding(.bottom, 0.1)
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
