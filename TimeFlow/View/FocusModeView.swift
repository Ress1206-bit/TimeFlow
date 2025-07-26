//
//  FocusModeView.swift
//  TimeFlow
//
//  Created by Adam Ress on 7/21/25.
//

import SwiftUI

struct FocusModeView: View {
    let event: Event
    @Binding var isPresented: Bool
    let animationNamespace: Namespace.ID
    
    @State private var currentTime = Date()
    @State private var showContent = false
    @State private var isDismissing = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with matched geometry
                LinearGradient(
                    colors: [event.color.opacity(0.9), event.color.opacity(0.7), event.color.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .matchedGeometryEffect(id: "eventBackground", in: animationNamespace, isSource: isDismissing)
                
                // Content overlay
                if showContent && !isDismissing {
                    VStack(spacing: 0) {
                        // Header with close button
                        HStack {
                            Spacer()
                            
                            Button {
                                dismissView()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .background(
                                        Circle()
                                            .fill(.white.opacity(0.1))
                                            .frame(width: 44, height: 44)
                                    )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        Spacer()
                        
                        // Main content
                        VStack(spacing: 40) {
                            // Event icon
                            Image(systemName: event.icon)
                                .font(.system(size: 80, weight: .light))
                                .foregroundColor(.white)
                                .frame(width: 120, height: 120)
                                .background(
                                    Circle()
                                        .fill(.white.opacity(0.15))
                                        .overlay(
                                            Circle()
                                                .stroke(.white.opacity(0.3), lineWidth: 2)
                                        )
                                )
                                .matchedGeometryEffect(id: "eventIcon", in: animationNamespace, isSource: isDismissing)
                            
                            // Event title
                            Text(event.title)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .matchedGeometryEffect(id: "eventTitle", in: animationNamespace, isSource: isDismissing)
                            
                            // Time remaining display
                            timeRemainingDisplay
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer()
                        
                        // Bottom info
                        bottomInfo
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onAppear {
            // Delay content appearance for smooth animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showContent = true
                }
            }
        }
        .statusBarHidden()
    }
    
    private func dismissView() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showContent = false
            isDismissing = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isPresented = false
            }
        }
    }
    
    // MARK: - Time Remaining Display
    private var timeRemainingDisplay: some View {
        VStack(spacing: 12) {
            Text("Time Remaining")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Text(timeRemainingText)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .matchedGeometryEffect(id: "eventTime", in: animationNamespace, isSource: isDismissing)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Bottom Info
    private var bottomInfo: some View {
        VStack(spacing: 16) {
            HStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("Started")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(event.start.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Rectangle()
                    .fill(.white.opacity(0.3))
                    .frame(width: 1, height: 40)
                
                VStack(spacing: 8) {
                    Text("Ends")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(event.end.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.1))
            )
            
            // Focus tip
            Text("Stay focused and make the most of this time!")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.bottom, 32)
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Computed Properties
    private var timeRemainingText: String {
        let remaining = event.end.timeIntervalSince(currentTime)
        let totalMinutes = Int(ceil(remaining / 60))
        
        if totalMinutes <= 0 {
            return "00:00"
        }
        
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d", hours, minutes)
        } else {
            return String(format: "00:%02d", minutes)
        }
    }
    
    private var progressPercentage: Double {
        let total = event.end.timeIntervalSince(event.start)
        let elapsed = currentTime.timeIntervalSince(event.start)
        let progress = elapsed / total
        
        return max(0, min(progress, 1))
    }
}

#Preview {
    FocusModeView(
        event: Event(
            id: UUID(),
            start: Date(),
            end: Date().addingTimeInterval(3600),
            title: "Important Meeting",
            icon: "person.3.fill",
            eventType: .work,
            colorName: "blue"
        ),
        isPresented: .constant(true),
        animationNamespace: Namespace().wrappedValue
    )
}
