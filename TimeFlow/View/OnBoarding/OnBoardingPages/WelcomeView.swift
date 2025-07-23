//
//  WelcomeView.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/28/25.
//

import SwiftUI

struct WelcomeView: View {
    
    let themeColor: Color
    var onContinue: () -> Void = {}
    
    @State private var animateContent = false
    @State private var animateIcon = false
    @State private var showFeatures = false
    @State private var expandedFeature: String? = nil
    
    var body: some View {
        ZStack {
            // Clean gradient background
            LinearGradient(
                colors: [
                    AppTheme.Colors.background,
                    AppTheme.Colors.secondary.opacity(0.3),
                    AppTheme.Colors.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Main content
                VStack(spacing: 40) {
                    // Hero section
                    heroSection
                        .opacity(expandedFeature != nil ? 0.3 : 1.0)
                        .scaleEffect(expandedFeature != nil ? 0.95 : 1.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: expandedFeature)
                    
                    // Features section
                    featuresSection
                        .opacity(showFeatures ? 1 : 0)
                        .offset(y: showFeatures ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.6), value: showFeatures)
                }
                .scaleEffect(animateContent ? 1.0 : 0.9)
                .opacity(animateContent ? 1.0 : 0)
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: animateContent)
                
                Spacer()
                Spacer() // Extra spacer for more space above button
                
                // Get started button
                getStartedButton
                    .opacity(animateContent && expandedFeature == nil ? 1 : 0)
                    .offset(y: expandedFeature != nil ? 20 : 0)
                    .animation(.easeOut(duration: 0.6).delay(expandedFeature == nil ? 1.0 : 0), value: animateContent)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: expandedFeature)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
            
            // Expanded feature overlay
            if let expandedFeature = expandedFeature {
                expandedFeatureView(expandedFeature)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                    ))
            }
        }
        .onAppear {
            withAnimation {
                animateContent = true
                animateIcon = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation {
                    showFeatures = true
                }
            }
        }
    }
}

// MARK: - Components
private extension WelcomeView {
    
    var heroSection: some View {
        VStack(spacing: 32) {
            // App icon with subtle animation
            VStack(spacing: 20) {
                ZStack {
                    // Background glow
                    Circle()
                        .fill(themeColor.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .scaleEffect(animateIcon ? 1.0 : 0.8)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateIcon)
                    
                    // Main icon
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(themeColor)
                        .rotationEffect(.degrees(animateIcon ? 360 : 0))
                        .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: animateIcon)
                }
                
                // App title and tagline
                VStack(spacing: 12) {
                    Text("TimeFlow")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("Transform your schedule into a seamless flow")
                        .font(.title3.weight(.regular))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    var featuresSection: some View {
        VStack(spacing: 24) {
            // Features grid
            VStack(spacing: 20) {
                featureRow(
                    leading: FeatureItem(
                        id: "smart-planning",
                        icon: "brain.head.profile",
                        title: "Smart Planning",
                        description: "AI optimizes your schedule automatically",
                        detailedDescription: "Our advanced AI analyzes your preferences, deadlines, and energy levels to create the perfect schedule. It learns from your habits and continuously optimizes to maximize your productivity while maintaining work-life balance."
                    ),
                    trailing: FeatureItem(
                        id: "full-control",
                        icon: "slider.horizontal.3",
                        title: "Full Control",
                        description: "Drag, drop, and customize with ease",
                        detailedDescription: "Don't like where something is scheduled? Simply drag and drop to rearrange. Add custom time blocks, set buffer times, and fine-tune your schedule until it's perfect. Your preferences are always respected."
                    )
                )
                
                featureRow(
                    leading: FeatureItem(
                        id: "goal-tracking",
                        icon: "target",
                        title: "Goal Tracking",
                        description: "Stay focused on what matters most",
                        detailedDescription: "Set meaningful goals and let TimeFlow automatically carve out dedicated time for them. Track your progress with beautiful visualizations and celebrate your achievements as you build lasting habits."
                    ),
                    trailing: FeatureItem(
                        id: "smart-alerts",
                        icon: "bell.badge",
                        title: "Smart Alerts",
                        description: "Gentle reminders at the right time",
                        detailedDescription: "Receive thoughtful notifications that help you transition between tasks smoothly. Our smart system knows when to remind you and when to let you focus, creating a mindful approach to time management."
                    )
                )
            }
        }
    }
    
    func featureRow(leading: FeatureItem, trailing: FeatureItem) -> some View {
        HStack(spacing: 16) {
            featureCard(leading)
            featureCard(trailing)
        }
    }
    
    func featureCard(_ feature: FeatureItem) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                expandedFeature = expandedFeature == feature.id ? nil : feature.id
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon
                Image(systemName: feature.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(themeColor)
                    .frame(width: 40, height: 40, alignment: .topLeading)
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(feature.title)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Tap indicator
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .scaleEffect(0.8)
                    }
                    
                    Text(feature.description)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.Colors.textPrimary.opacity(expandedFeature == feature.id ? 0.08 : 0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(expandedFeature == feature.id ? themeColor.opacity(0.3) : AppTheme.Colors.overlay.opacity(0.5), lineWidth: expandedFeature == feature.id ? 1 : 0.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(expandedFeature != nil && expandedFeature != feature.id ? 0.4 : 1.0)
        .scaleEffect(expandedFeature != nil && expandedFeature != feature.id ? 0.95 : 1.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: expandedFeature)
    }
    
    func expandedFeatureView(_ featureId: String) -> some View {
        let feature = allFeatures.first { $0.id == featureId }!
        
        return VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: feature.icon)
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(themeColor)
                            
                            Text(feature.title)
                                .font(.title2.weight(.bold))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                        }
                        
                        Text(feature.description)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            expandedFeature = nil
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
                
                // Detailed description
                ScrollView {
                    Text(feature.detailedDescription)
                        .font(.body)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppTheme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(themeColor.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            )
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    var getStartedButton: some View {
        Button(action: onContinue) {
            HStack(spacing: 8) {
                Text("Get Started")
                    .font(.headline.weight(.semibold))
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [themeColor, themeColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: themeColor.opacity(0.3), radius: 8, y: 4)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }
    
    var allFeatures: [FeatureItem] {
        [
            FeatureItem(
                id: "smart-planning",
                icon: "brain.head.profile",
                title: "Smart Planning",
                description: "AI optimizes your schedule automatically",
                detailedDescription: "Our advanced AI analyzes your preferences, deadlines, and energy levels to create the perfect schedule. It learns from your habits and continuously optimizes to maximize your productivity while maintaining work-life balance."
            ),
            FeatureItem(
                id: "full-control",
                icon: "slider.horizontal.3",
                title: "Full Control",
                description: "Drag, drop, and customize with ease",
                detailedDescription: "Don't like where something is scheduled? Simply drag and drop to rearrange. Add custom time blocks, set buffer times, and fine-tune your schedule until it's perfect. Your preferences are always respected."
            ),
            FeatureItem(
                id: "goal-tracking",
                icon: "target",
                title: "Goal Tracking",
                description: "Stay focused on what matters most",
                detailedDescription: "Set meaningful goals and let TimeFlow automatically carve out dedicated time for them. Track your progress with beautiful visualizations and celebrate your achievements as you build lasting habits."
            ),
            FeatureItem(
                id: "smart-alerts",
                icon: "bell.badge",
                title: "Smart Alerts",
                description: "Gentle reminders at the right time",
                detailedDescription: "Receive thoughtful notifications that help you transition between tasks smoothly. Our smart system knows when to remind you and when to let you focus, creating a mindful approach to time management."
            )
        ]
    }
}

// MARK: - Supporting Types
private struct FeatureItem: Identifiable {
    let id: String
    let icon: String
    let title: String
    let description: String
    let detailedDescription: String
}

// MARK: - Custom Button Style
private struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    WelcomeView(themeColor: AppTheme.Colors.accent)
        .preferredColorScheme(.dark)
}
