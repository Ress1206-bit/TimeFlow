//
//  SignInLandingView.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/14/25.
//

//  SignInLandingView.swift
import SwiftUI
import AuthenticationServices

struct SignInLandingView: View {
    
    @Environment(ContentModel.self) private var contentModel
    
    @State private var showEmailSheet = false

    var body: some View {
        ZStack {
            // Updated background gradient to match app theme
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
                Spacer()

                // Hero section
                VStack(spacing: 24) {
                    // App icon/logo area
                    RoundedRectangle(cornerRadius: 24)
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
                        .frame(width: 88, height: 88)
                        .overlay(
                            Image(systemName: "calendar.day.timeline.leading")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white)
                        )
                        .shadow(color: AppTheme.Colors.accent.opacity(0.3), radius: 20, y: 8)
                    
                    VStack(spacing: 12) {
                        Text("TimeFlow")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text("AI-powered scheduling for your perfect day")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .padding(.horizontal, 32)
                    }
                }

                Spacer()
                Spacer()

                // Authentication buttons
                VStack(spacing: 16) {
                    // Apple Sign-In
                    Button {
                        Task {
                            // TODO: Implement Apple Sign-In
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "applelogo")
                                .font(.system(size: 20, weight: .medium))
                            Text("Continue with Apple")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.black)
                        )
                        .foregroundColor(.white)
                    }

                    // Google Sign-In
                    GoogleButton()

                    // Email Sign-In
                    Button {
                        showEmailSheet = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope")
                                .font(.system(size: 16, weight: .medium))
                            Text("Continue with Email")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppTheme.Colors.cardBackground)
                                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                        )
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppTheme.Colors.overlay.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    // Divider with "or"
                    HStack {
                        Rectangle()
                            .fill(AppTheme.Colors.overlay.opacity(0.3))
                            .frame(height: 1)
                        
                        Text("or")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .padding(.horizontal, 16)
                        
                        Rectangle()
                            .fill(AppTheme.Colors.overlay.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.vertical, 8)
                    
                    // Guest/Demo mode
                    Button {
                        // TODO: Implement guest mode or demo
                    } label: {
                        Text("Continue as Guest")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
                
                // Terms and privacy
                VStack(spacing: 8) {
                    Text("By continuing, you agree to our")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    
                    HStack(spacing: 4) {
                        Button("Terms of Service") {
                            // TODO: Open terms
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.Colors.accent)
                        
                        Text("and")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                        
                        Button("Privacy Policy") {
                            // TODO: Open privacy policy
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.Colors.accent)
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showEmailSheet) {
            NavigationStack {
                EmailEntryView()
                    .preferredColorScheme(.light) // Ensure consistent appearance
            }
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    SignInLandingView()
        .environment(ContentModel())
}


// Updated Google Button to match theme
struct GoogleButton: View {
    @Environment(\.openURL) private var openURL
    @Environment(ContentModel.self) private var contentModel
    @Environment(\.scenePhase) private var phase
    
    @State private var busy = false
    
    var body: some View {
        Button {
            Task {
                guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
                
                busy = true
                
                do {
                    try await contentModel.googleSignIn(windowScene: scene)
                } catch {
                    print(error.localizedDescription)
                }
                
                busy = false
                
                contentModel.checkLogin()
            }
        } label: {
            HStack(spacing: 12) {
                if busy {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(AppTheme.Colors.textSecondary)
                } else {
                    Image("google_icon")
                        .resizable()
                        .frame(width: 20, height: 20)
                }
                
                Text(busy ? "Signing in..." : "Continue with Google")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            )
            .foregroundColor(.black)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
            )
        }
        .disabled(busy)
    }
}