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
                    Color(red: 0.18, green: 0.16, blue: 0.47),      // deep indigo
                    Color(red: 0.46, green: 0.30, blue: 0.89),      // lavender
                    Color(red: 0.40, green: 0.40, blue: 0.95)       // periwinkle
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
                    .foregroundStyle(.white)

                // E-mail label
                Text(email)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.85))

                // Name field
                TextField("", text: $fullName, prompt: Text("Full name").foregroundStyle(.white))
                    .fieldStyle()
                
                //Birthday
                VStack(alignment: .leading, spacing: 6) {

                    // Compact row (tap to expand)
                    Button {
                        withAnimation(.easeInOut) { showAgeSel.toggle() }
                    } label: {
                        HStack {
                            Text("\(age) years old")
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Image(systemName: "chevron.down")
                                .rotationEffect(.degrees(showAgeSel ? 180 : 0))
                                .foregroundStyle(.white.opacity(0.8))
                                .animation(.easeInOut(duration: 0.25), value: showAgeSel)
                        }
                        .padding(.horizontal, 18)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white.opacity(0.05))
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.45), lineWidth: 1))
                        )
                    }
                    .buttonStyle(.plain)

                    // Wheel picker appears only when needed
                    if showAgeSel {
                        Picker("", selection: $age) {
                            ForEach(5...100, id: \.self) { Text("\($0)").foregroundStyle(.white) }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity, maxHeight: 120)
                        .clipped()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white.opacity(0.08))
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                // Password field
                ZStack {
                    if showPassword {
                        TextField("", text: $password,
                                  prompt: Text("Password").foregroundStyle(.white))
                            .fieldStyle()
                    } else {
                        SecureField("", text: $password,
                                    prompt: Text("Password").foregroundStyle(.white))
                            .fieldStyle()
                    }

                    // Eye icon, aligned to the trailing edge
                    HStack {
                        Spacer()
                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye" : "eye.slash")
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(.trailing, 18)          // same horizontal padding as field
                    }
                    .allowsHitTesting(!isBusy)           // optional: disable while loading
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
                                .fill(Color(red: 0.41, green: 0.42, blue: 0.94))
                                .shadow(color: .white.opacity(0.18),
                                        radius: 18, y: 10)
                        )
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(isBusy)

                // Fine-print
                Text("By continuing you agree to our\nTerms & Privacy Policy.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.top, 12)

            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.55))      // glass blur + tint
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.42), lineWidth: 1)   // subtle border
            )
            .shadow(color: .black.opacity(0.30), radius: 18, y: 10)
            .padding(.horizontal, 36)
        }
    }
}

// MARK: - TextField style helper
private extension View {
    func fieldStyle() -> some View {
        self
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .padding(.horizontal, 18)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.45), lineWidth: 1)
                    )
            )
            .foregroundStyle(.white)
    }
}

// PREVIEW ------------------------------------------------------------
#Preview {
    CreateAccView(email: "alex@example.com")
        .environment(ContentModel())
}
