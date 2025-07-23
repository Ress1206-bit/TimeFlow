//
//  Utilities.swift
//  TimeFlow
//
//  Created by Adam Ress on 7/12/25.
//

import SwiftUI


@ToolbarContentBuilder
func progressToolbar(currentStep: Int, onSkip: @escaping () -> Void) -> some ToolbarContent {
    ToolbarItem(placement: .navigationBarLeading) {
        Text("Step \(currentStep) of 8")
            .font(.subheadline.weight(.semibold))
            .foregroundColor(AppTheme.Colors.textTertiary)
    }
    ToolbarItem(placement: .navigationBarTrailing) {
        Button("Skip") { onSkip() }
            .foregroundColor(AppTheme.Colors.textTertiary)
    }
}

//Icons


//Icon picker sheet
struct IconPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedIcon: String
    private let icons = [
        "target",              // set/track a goal
        "figure.walk",         // daily walking
        "figure.run",          // running/jogging
        "bicycle",             // cycling
        "dumbbell",            // strength training
        "heart.fill",          // general health
        "leaf.fill",           // sustainability / eat green
        "book.fill",           // reading / study
        "pencil",              // writing / journaling
        "globe",               // learn a language / travel
        "laptopcomputer",      // learn programming / tech skills
        "keyboard",            // typing practice
        "music.note",          // play an instrument
        "mic.fill",            // singing / public speaking
        "paintbrush.fill",     // painting / visual art
        "camera.fill",         // photography
        "video.fill",          // film‑making / vlogging
        "gamecontroller.fill", // game development / play time
        "sun.max.fill",        // wake up early / daylight goals
        "moon.stars.fill",     // sleep hygiene
        "drop.fill",           // hydrate
        "flame.fill",          // burn calories
        "bolt.fill",           // boost energy / productivity
        "brain.head.profile",  // mindfulness / cognitive skills
        "lightbulb.fill",      // creative ideas / innovation
        "medal.fill",          // compete / earn certification
        "calendar",            // scheduling / planning
        "clock",               // time management / pomodoro
        "chart.bar.fill",      // track metrics / analytics
        "wallet.pass",         // budgeting / finance
        "house.fill",          // home improvement
        "hammer.fill",         // DIY projects
        "scissors",            // crafting / sewing
        "guitars",             // practice guitar
        "theatermasks.fill",   // acting / drama
        "fork.knife",          // cooking / meal prep
        "figure.yoga",         // yoga / flexibility
        "figure.dance",        // dance practice
        "figure.hiking",       // hiking / outdoors
        "figure.pool.swim",    // swimming
        "soccerball",          // play soccer
        "basketball",          // play basketball
        "baseball",            // play baseball
        "american.football",   // football training
        "tennis.racket",       // tennis
        "volleyball",          // volleyball
        "graduationcap.fill",  // earn a degree / certificate
        "doc.text.fill",       // write a paper / blog
        "bell.fill",           // habit reminders / alerts
        "sparkles"             // celebrate milestones
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: 16) {
                        ForEach(icons, id: \.self) { icon in
                            Button(action: {
                                selectedIcon = icon
                                dismiss()
                            }) {
                                Image(systemName: icon)
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(selectedIcon == icon ? AppTheme.Colors.textPrimary : AppTheme.Colors.textTertiary)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Circle()
                                            .fill(selectedIcon == icon ? AppTheme.Colors.accent : AppTheme.Colors.textPrimary.opacity(0.1))
                                            .overlay(
                                                Circle()
                                                    .stroke(AppTheme.Colors.overlay, lineWidth: 1)
                                            )
                                    )
                                    .scaleEffect(selectedIcon == icon ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedIcon == icon)
                            }
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
            }
        }
    }
}


//VERY NICE BUTTON DESIGN BUT NOT NEEDED ATM
//                Spacer()
//
//                Button {
//                    showingClassManager = true
//                } label: {
//                    HStack(spacing: 4) {
//                        Image(systemName: "gear")
//                            .font(.system(size: 12, weight: .medium))
//                        Text("Manage")
//                            .font(.system(size: 12, weight: .medium))
//                    }
//                    .foregroundColor(themeColor)
//                    .padding(.horizontal, 8)
//                    .padding(.vertical, 4)
//                    .background(
//                        RoundedRectangle(cornerRadius: 6)
//                            .fill(themeColor.opacity(0.15))
//                    )
//                }