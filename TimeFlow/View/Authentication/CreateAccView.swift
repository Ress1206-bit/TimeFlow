//
//  CreateAccountView.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/19/25.
//

import SwiftUI

struct CreateAccView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(ContentModel.self) private var contentModel
    
    let email: String

    // Local UI state
    @State private var fullName = ""
    @State private var password = ""
    @State private var isBusy = false
    
    @State private var age = 18
    @State private var showAgeSel = false
    
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
                Text("Create Your\nAccount")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                // E-mail label
                Text(email)
                    .font(.headline)
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                // Name field
                TextField("", text: $fullName, prompt: Text("Full name").foregroundStyle(AppTheme.Colors.textPrimary))
                    .fieldStyle()
                
                //Birthday
                VStack(alignment: .leading, spacing: 6) {

                    // Compact row (tap to expand)
                    Button {
                        withAnimation(.easeInOut) { showAgeSel.toggle() }
                    } label: {
                        HStack {
                            Text("\(age) years old")
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Image(systemName: "chevron.down")
                                .rotationEffect(.degrees(showAgeSel ? 180 : 0))
                                .foregroundStyle(AppTheme.Colors.textTertiary)
                                .animation(.easeInOut(duration: 0.25), value: showAgeSel)
                        }
                        .padding(.horizontal, 18)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.Colors.textPrimary.opacity(0.05))
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.Colors.overlay, lineWidth: 1))
                        )
                    }
                    .buttonStyle(.plain)

                    // Wheel picker appears only when needed
                    if showAgeSel {
                        Picker("", selection: $age) {
                            ForEach(5...100, id: \.self) { Text("\($0)").foregroundStyle(AppTheme.Colors.textPrimary) }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity, maxHeight: 120)
                        .clipped()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.Colors.textPrimary.opacity(0.08))
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                // Password field
                ZStack {
                    if showPassword {
                        TextField("", text: $password,
                                  prompt: Text("Password").foregroundStyle(AppTheme.Colors.textPrimary))
                            .fieldStyle()
                    } else {
                        SecureField("", text: $password,
                                    prompt: Text("Password").foregroundStyle(AppTheme.Colors.textPrimary))
                            .fieldStyle()
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
                        .padding(.trailing, 18)
                    }
                    .allowsHitTesting(!isBusy)
                }

                // Action button
                Button {
                    Task {
                        guard !isBusy else { return }
                        isBusy = true
                        
                        do {
                            try await contentModel.createAccount(
                                email: email,
                                name: fullName,
                                password: password)
                            
                            print("before: \(contentModel.loggedIn)")
                            contentModel.checkLogin()
                            print(contentModel.loggedIn)
                            
                            isBusy = false
                        } catch {
                            let errorMessage = error.localizedDescription
                            print(errorMessage)
                        }
                    }
                } label: {
                    Text(isBusy ? "Creating…" : "Create Account")
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
                .disabled(isBusy)

                // Fine-print
                Text("By continuing you agree to our\nTerms & Privacy Policy.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.Colors.textTertiary)
                    .padding(.top, 12)

            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(AppTheme.Colors.overlay, lineWidth: 1)
            )
            .shadow(color: AppTheme.Shadows.button, radius: 18, y: 10)
            .padding(.horizontal, 36)
        }
    }
}

// MARK: - TextField style helper
extension View {
    func fieldStyle() -> some View {
        self
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
}

// PREVIEW ------------------------------------------------------------
#Preview {
    CreateAccView(email: "alex@example.com")
        .environment(ContentModel())
}