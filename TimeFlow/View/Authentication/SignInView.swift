//
//  SignInView.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/20/25.
//

import SwiftUI

struct SignInView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(ContentModel.self) private var contentModel
    
    let email: String
    
    @State private var password = ""

    
    @State private var showPassword = false

    // MARK: - UI
    var body: some View {
        ZStack {
        
            LinearGradient(
                colors: [
                    AppTheme.Colors.secondary,                    // deep navy
                    AppTheme.Colors.accent.opacity(0.8),          // accent lavender
                    AppTheme.Colors.primary                       // primary blue
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // 2. GLASS CARD ----------------------------------------------------
            VStack(spacing: 28) {

                // Title
                Text("Sign Into Your\nAccount")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                // E-mail label
                Text(email)
                    .font(.headline)
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                // Password field
                ZStack {
                    if showPassword {
                        TextField("", text: $password,
                                  prompt: Text("Password").foregroundStyle(AppTheme.Colors.textPrimary))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(.horizontal, 18)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.Colors.textPrimary.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.Colors.overlay, lineWidth: 1)
                                )
                        )
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    } else {
                        SecureField("", text: $password,
                                    prompt: Text("Password").foregroundStyle(AppTheme.Colors.textPrimary))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(.horizontal, 18)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.Colors.textPrimary.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.Colors.overlay, lineWidth: 1)
                                )
                        )
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    }

                    // Eye icon, aligned to the trailing edge
                    HStack {
                        Spacer()
                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye" : "eye.slash")
                                .foregroundStyle(AppTheme.Colors.textTertiary)
                        }
                        .padding(.trailing, 18)          // same horizontal padding as field
                    }
                }

                // Action button
                Button {
                    Task {
                        do {
                            try await contentModel.signIn(email: email, password: password)
                        } catch {
                            print("Sign in failed: \(error.localizedDescription)")
                        }
                    }
                } label: {
                    Text("Sign In")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.Colors.primary)
                                .shadow(color: AppTheme.Shadows.icon,
                                        radius: 18, y: 10)
                        )
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                }
                .buttonStyle(.plain)

            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.55))      // glass blur + tint
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(AppTheme.Colors.overlay, lineWidth: 1)   // subtle border
            )
            .shadow(color: AppTheme.Shadows.button, radius: 18, y: 10)
            .padding(.horizontal, 36)
        }
    }
}


#Preview {
    SignInView(email: "alex@example.com")
        .environment(ContentModel())
}
