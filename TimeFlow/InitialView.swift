//
//  InitialView.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/27/25.
//

import SwiftUI

struct InitialView: View {
    var body: some View {
        ZStack {
            // Brand gradient background
            LinearGradient(colors: [.blue.opacity(0.6),
                                    .purple.opacity(0.6)],
                           startPoint: .topLeading,
                           endPoint:   .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer(minLength: 120)

                // App name
                Text("TimeFlow")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(radius: 4)

                Spacer()

                // Primary CTA
                Button {
                    //showOnboarding = true
                } label: {
                    Text("Get Started")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.95))
                        .foregroundColor(.black)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 36)

                // Secondary CTA
                Button {
                    //showSignIn = true
                } label: {
                    Text("Already have an account?")
                        .underline()
                        .foregroundColor(.white)
                }
                .padding(.top, 6)

                Spacer(minLength: 100)
            }
        }
    }
}

#Preview {
    InitialView()
}
