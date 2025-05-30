//
//  ChatView.swift
//  TimeFlow
//
//  Created by Adam Ress on 5/29/25.
//

import SwiftUI

struct ChatView: View {
    
    @Binding var selectedTab: Int
    
    @State private var messageText = ""
    @FocusState private var isTyping: Bool
    
    var body: some View {
        
        ZStack {
            
            Image("blurbackground")
                .resizable()
                .ignoresSafeArea()
                .contrast(0.4)
                .brightness(-0.4)
            
            VStack {
                VStack {
                    
                    Text("Assistant")
                        .font(.system(size: 33))
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 25)
                        .padding(.top, 5)
                        .ignoresSafeArea(.keyboard)
                    
                }
                
                Spacer()
                .safeAreaInset(edge: .bottom) {
                    ZStack(alignment: .leading) {
                        
                        RoundedRectangle(cornerRadius: 30)
                            .foregroundStyle(Color(red: 0.115, green: 0.081, blue: 0.253))
                            .frame(height: 60)
                            .padding(.horizontal, 20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color(red: 0.214, green: 0.175, blue: 0.361), lineWidth: 1)
                                    .padding(.horizontal, 20)
                            )
                        
                        HStack {
                            
                            TextEditor(text: $messageText)
                                .foregroundColor(Color(red: 0.542, green: 0.517, blue: 0.75))
                                .font(.body)
                                .frame(height: 30)
                                .scrollContentBackground(.hidden)
                                .focused($isTyping)
                                .padding(.bottom, 6)
                            
                            Image(systemName: "triangleshape")
                                .foregroundColor(Color(red: 0.235, green: 0.243, blue: 0.848))
                                .rotationEffect(.degrees(90))
                                .font(.system(size: 20))
                                .bold().bold()
                                .onTapGesture {
                                    isTyping = false
                                }
            
                        }
                        .padding(.horizontal, 30)
                        
                        if messageText.isEmpty {
                            
                            Text("Type a message…")
                                .foregroundColor(Color(red: 0.542, green: 0.517, blue: 0.75))
                                .padding(.leading, 35)
                                .padding(.bottom, 2)
                                .allowsHitTesting(false)
                        }
                        
                    }
                    .padding(.bottom, 25)      // your bar component
                }
                
                if !isTyping {
                    TabView(selectedTab: $selectedTab)
                }
            }
        }
    }
}

#Preview {
    ChatView(selectedTab: .constant(0))
}
