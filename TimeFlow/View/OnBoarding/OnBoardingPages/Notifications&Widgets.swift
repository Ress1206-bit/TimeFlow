//
//  Notifications&Widgets.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/28/25.
//

import SwiftUI
import UserNotifications


struct NotificationsWidgetsView: View {
    
    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined
    @State private var isRequesting = false
    
    let themeColor: Color

    private let card = Color(red: 0.13, green: 0.13, blue: 0.15)
    
    var onContinue: () -> Void = {}
    
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            //background
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
            
            VStack(spacing: 36) {
                header
                previewCard
                Spacer(minLength: 24)
                allowButton
                skipButton
            }
            .padding(.horizontal)
            .task { permissionStatus = await currentStatus() }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation {
                animateContent = true
            }
        }
    }
}

// MARK: – Sub-views
private extension NotificationsWidgetsView {
    
    var header: some View {
        VStack(spacing: 8) {
            Text("Stay on track")
                .font(.title2.bold())
                .foregroundColor(.white)
            Text("Smart reminders keep you ahead of every task.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(.top, 64)
        .opacity(animateContent ? 1.0 : 0)
        .offset(y: animateContent ? 0 : -20)
        .animation(.easeOut(duration: 0.8), value: animateContent)
    }
    
    var previewCard: some View {
        VStack(spacing: 24) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 60, weight: .semibold))
                .foregroundColor(themeColor)
                .padding(.top, 28)
            
            Text("Timely alerts")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("We’ll nudge you a few minutes before each event and suggest breaks when you’re overloaded.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal)
                .padding(.bottom, 28)
            
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(card)
                .shadow(color: .black.opacity(0.6), radius: 8, y: 4)
        )
        .padding(.horizontal)
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateContent)
    }
    
    var allowButton: some View {
        Button {
            requestPermission()
        } label: {
            Group {
                if isRequesting {
                    ProgressView().progressViewStyle(.circular)
                } else {
                    Text(buttonTitle).fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .background(themeColor)
        .foregroundColor(.white)
        .cornerRadius(16)
        .padding(.horizontal)
        .disabled(permissionStatus == .authorized || isRequesting)
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateContent)
    }
    
    var skipButton: some View {
        Button(action: onContinue) {
            Text("Skip for now")
                .underline()
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(.bottom, 32)
    }
    
    private var buttonTitle: String {
        permissionStatus == .denied ? "Open Settings" : "Allow Notifications"
    }
}


// MARK: – Permission helpers
private extension NotificationsWidgetsView {
    
    func currentStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    func requestPermission() {
        guard permissionStatus != .authorized else { return }
        
        if permissionStatus == .denied {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
            return
        }
        isRequesting = true
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                Task { @MainActor in
                    permissionStatus = granted ? .authorized : .denied
                    isRequesting = false
                }
            }
    }
}
