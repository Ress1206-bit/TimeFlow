//
//  Notifications&Widgets.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/28/25.
//

import SwiftUI
import UserNotifications

// ----------------------------------------------------------------------
//  NOTIFICATIONS & WIDGETS SCREEN — dark palette
// ----------------------------------------------------------------------

struct NotificationsWidgetsView: View {
    
    var onContinue: () -> Void = {}
    
    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined
    @State private var isRequesting = false
    
    private let bg     = Color.black
    private let card   = Color(red: 0.13, green: 0.13, blue: 0.15)
    private let accent = Color(red: 0.30, green: 0.64, blue: 0.97)
    
    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
                .overlay(
                    Image("Noise")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.05)
                        .ignoresSafeArea()
                )
            
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
    }
    
    var previewCard: some View {
        VStack(spacing: 24) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 60, weight: .semibold))
                .foregroundColor(accent)
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
        .background(accent)
        .foregroundColor(.white)
        .cornerRadius(16)
        .padding(.horizontal)
        .disabled(permissionStatus == .authorized || isRequesting)
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

// MARK: – Preview
#Preview {
    NavigationStack { NotificationsWidgetsView() }
}
