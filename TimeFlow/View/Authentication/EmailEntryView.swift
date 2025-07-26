//
//  EmailEntrySheet.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/16/25.
//

import SwiftUI
import FirebaseAuth

struct EmailEntryView: View {
    
    @Environment(ContentModel.self) private var contentModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var goCreateAccount = false
    @State private var goSignIn = false
    
    @State private var email = ""
    @State private var busy = false
    @State private var errorMsg: String?

    private var emailIsValid: Bool {
        email.range(of: #"^\S+@\S+\.\S+$"#, options: .regularExpression) != nil
    }

    var body: some View {
        ZStack {
            // Modern background gradient
            LinearGradient(
                colors: [
                    AppTheme.Colors.background,
                    AppTheme.Colors.accent.opacity(0.1),
                    AppTheme.Colors.secondary.opacity(0.2),
                    AppTheme.Colors.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    // Handle bar
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppTheme.Colors.overlay.opacity(0.3))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)
                    
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 32)
                
                // Main content
                VStack(spacing: 32) {
                    // Header section
                    VStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppTheme.Colors.accent,
                                        AppTheme.Colors.accent.opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                            .overlay(
                                Image(systemName: "envelope")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: AppTheme.Colors.accent.opacity(0.3), radius: 12, y: 4)
                        
                        VStack(spacing: 8) {
                            Text("Enter Your Email")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            
                            Text("We'll check if you have an account or help you create one")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                        }
                    }
                    
                    // Email input
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("your@email.com", text: $email)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .frame(height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppTheme.Colors.cardBackground)
                                        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            emailIsValid ? AppTheme.Colors.accent.opacity(0.5) : 
                                            AppTheme.Colors.overlay.opacity(0.2),
                                            lineWidth: 1
                                        )
                                )
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            
                            if let errorMsg = errorMsg {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red)
                                    
                                    Text(errorMsg)
                                        .font(.system(size: 12))
                                        .foregroundColor(.red)
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        
                        // Continue button
                        Button {
                            guard emailIsValid else {
                                errorMsg = "Please enter a valid email address"
                                return
                            }
                            
                            errorMsg = nil
                            busy = true
                            
                            contentModel.checkIfEmailExists(email: email) { exists, error in
                                DispatchQueue.main.async {
                                    busy = false
                                    
                                    if let error = error {
                                        errorMsg = "Something went wrong. Please try again."
                                        return
                                    }
                                    
                                    if exists {
                                        goSignIn = true
                                    } else {
                                        goCreateAccount = true
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if busy {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Text("Continue")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        emailIsValid && !busy ? 
                                        LinearGradient(
                                            colors: [AppTheme.Colors.accent, AppTheme.Colors.accent.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            colors: [AppTheme.Colors.textTertiary.opacity(0.5), AppTheme.Colors.textTertiary.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(
                                        color: emailIsValid && !busy ? AppTheme.Colors.accent.opacity(0.3) : .clear,
                                        radius: 8,
                                        y: 4
                                    )
                            )
                            .foregroundColor(.white)
                        }
                        .disabled(!emailIsValid || busy)
                        .animation(.easeInOut(duration: 0.2), value: emailIsValid)
                        .animation(.easeInOut(duration: 0.2), value: busy)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
        }
        .navigationDestination(isPresented: $goCreateAccount) {
            CreateAccView(email: email)
        }
        .navigationDestination(isPresented: $goSignIn) {
            SignInView(email: email)
        }
        .interactiveDismissDisabled(busy)
    }
}

#Preview {
    NavigationStack {
        EmailEntryView()
            .environment(ContentModel())
    }
}