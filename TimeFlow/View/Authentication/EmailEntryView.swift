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
    
    @State private var goCreateAccount = false
    @State private var goSignIn = false
    

    @State private var email     = ""
    @State private var busy      = false
    @State private var nextMsg   = ""
    @State private var errorMsg  : String?

    private var emailIsValid: Bool {
        // ultra-basic regex
        email.range(of: #"^\S+@\S+\.\S+$"#, options: .regularExpression) != nil
    }

    var body: some View {
        ZStack {
            // full-screen backdrop
            LinearGradient(
                    colors: [Color(#colorLiteral(red: 0.3971439004, green: 0.1718953252, blue: 1, alpha: 1)),   // deep indigo
                             Color(#colorLiteral(red: 0.8545649648, green: 0.5632926822, blue: 1, alpha: 1)),
                             Color(#colorLiteral(red: 0.3432879448, green: 0.35139364, blue: 1, alpha: 1))],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            // glass card
            VStack(spacing: 28) {
                Text("Enter Your Email")
                    .font(.system(size: 30))
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .center)

                TextField("", text: $email, prompt: Text("Email").foregroundStyle(.white))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal, 18)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.05))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.45), lineWidth: 1))
                    )
                    .foregroundStyle(.white)

                Button {
                    Task {
                        contentModel.checkIfEmailExists(email: email) { exists, error in
                                if let error = error {
                                    print("Error checking email: \(error.localizedDescription)")
                                    return
                                }
                                if exists {
                                    goSignIn = true
                                    print("Email is already registered.")
                                    // Show error to user (e.g., "This email is already in use.")
                                } else {
                                    goCreateAccount = true
                                    print("Email is available for registration.")
                                    // Proceed with sign-up
                                }
                            }
                    }
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(#colorLiteral(red: 0.4427401125, green: 0.4285973907, blue: 0.9061256051, alpha: 1)))
                                .shadow(color: .white.opacity(0.2), radius: 18, y: 10)
                        )
                }
                .foregroundStyle(.white)
                .buttonStyle(.plain)
                //.disabled(!emailIsValid)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.55)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.42), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.30), radius: 18, y: 10)
            .padding(.horizontal, 36)
        }
        .presentationBackground(.ultraThinMaterial)
        .interactiveDismissDisabled(busy)
        .navigationDestination(isPresented: $goCreateAccount) {
            CreateAccView(email: email)
        }
        .navigationDestination(isPresented: $goSignIn) {
            SignInView(email: email)
        }
    }
}

#Preview {
    EmailEntryView()
        .environment(ContentModel())
}
