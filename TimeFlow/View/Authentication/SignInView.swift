//
//  SignInView.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/20/25.
//

import SwiftUI

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
                Text("Sign Into Your\nAccount")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)

                // E-mail label
                Text(email)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.85))

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
                }

                // Action button
                Button {
                    contentModel.signIn(email: email, password: password)
                } label: {
                    Text("Sign In")
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


#Preview {
    SignInView(email: "alex@example.com")
        .environment(ContentModel())
}
