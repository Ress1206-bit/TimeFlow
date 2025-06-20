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
            LinearGradient(colors: [.blue.opacity(0.6),
                                    .purple.opacity(0.6)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
                .blur(radius: 40)

            VStack(spacing: 32) {
                Spacer()

                Text("TimeFlow")
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(radius: 10)

                Text("Plan smarter, live happier")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))

                Spacer()

                VStack(spacing: 16) {
                    // Apple Sign-In
                    Button {
                        Task {

                        }
                    } label: {
                        HStack {
                            Image(systemName: "applelogo")
                                //.resizable()
                                .frame(width: 24, height: 24)
                                .font(.system(size: 23))
                            Text("Sign in with Apple")
                                .fontWeight(.medium)
                                .font(.system(size: 18))
                        }
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Color.black)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Google Sign-In
                    Button {
                        Task {

                        }
                    } label: {
                        HStack {
                            Image("google_icon")
                                .resizable()
                                .frame(width: 24, height: 24)
                            Text("Sign in with Google")
                                .fontWeight(.medium)
                                .font(.system(size: 18))
                        }
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Color.white)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Email Sign-In
                    Button {
                        showEmailSheet = true
                    } label: {
                        Text("Continue with Email")
                            .fontWeight(.medium)
                            .font(.system(size: 18))
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(.white.opacity(0.2))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(.white.opacity(0.5), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
                Spacer(minLength: 40)
                
                Text("By continuing you agree to our Terms and Conditions and Privacy Policy.")
                    .foregroundStyle(.white)
                    .font(.system(size: 12))
                    .padding()
            }
        }
        .sheet(isPresented: $showEmailSheet) {
            NavigationStack {
                EmailEntryView()
            }
        }
    }
}

#Preview {
    SignInLandingView()
        .environment(ContentModel())
}
