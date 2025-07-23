//
//  SubscriptionView.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/30/25.
//

import SwiftUI
import UserNotifications


struct SubscriptionView: View {
    
    @Environment(ContentModel.self) private var contentModel
    @Environment(\.dismiss) private var dismiss
    
    let themeColor: Color
    
    var onContinue: () -> Void = {}
    
    
    enum Plan: String, CaseIterable, Identifiable { case monthly, yearly
        var id: String { rawValue }
    }
    @State private var selected: Plan = .yearly
    @State private var isPurchasing = false
    
    
    private let card = Color(red: 0.13, green: 0.13, blue: 0.15)
    
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            //background
            LinearGradient(
                colors: [
                    AppTheme.Colors.background,
                    AppTheme.Colors.secondary.opacity(0.3),
                    AppTheme.Colors.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 36) {
                    
                    header
                    
                    pricingCards
                    
                    ctaButtons
                    
                    footer
                }
                .padding(.horizontal)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation {
                animateContent = true
            }
        }
    }
}


private extension SubscriptionView {
    
    var header: some View {
        VStack(spacing: 12) {
            Text("Start your 3-day free trial")
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            
            Text("Unlimited schedules, smart adjustments, and priority support.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(.top, 40)
        .opacity(animateContent ? 1.0 : 0)
        .offset(y: animateContent ? 0 : -20)
        .animation(.easeOut(duration: 0.8), value: animateContent)
    }
    
    var pricingCards: some View {
        VStack(spacing: 20) {
            
            ForEach(Array(Plan.allCases.enumerated()), id: \.offset) { index, plan in
                planCard(for: plan)
                    .scaleEffect(animateContent ? 1.0 : 0.8)
                    .opacity(animateContent ? 1.0 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1 + Double(index) * 0.15), value: animateContent)
            }
        }
    }
    
    @ViewBuilder
    func planCard(for plan: Plan) -> some View {
        let picked = selected == plan
        VStack(spacing: 8) {
            Text(plan == .monthly ? "Monthly Plan" : "Annual Plan")
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(plan == .monthly ? "$4.99" : "$49.99")
                    .font(.largeTitle.weight(.bold))
                Text(plan == .monthly ? "/mo" : "/yr")
                    .foregroundColor(.white.opacity(0.75))
            }
            
            Text(plan == .monthly
                 ? "Billed monthly · Cancel anytime"
                 : "2 months free · Best value")
            .font(.footnote)
            .foregroundColor(.white.opacity(0.75))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(card)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(picked ? themeColor : .clear, lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.6), radius: 8, y: 4)
        )
        .onTapGesture { withAnimation(.easeInOut) { selected = plan } }
    }
    
    var ctaButtons: some View {
        VStack(spacing: 14) {
            Button {
                purchase()
            } label: {
                Group {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Text("Start Free Trial")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .background(themeColor)
            .foregroundColor(.white)
            .cornerRadius(16)
            .disabled(isPurchasing)
            
            Button {
                contentModel.newUser = false
                dismiss()
            } label: {
                Text("Maybe Later")
                    .underline()
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.bottom, 8)
        }
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateContent)
    }
    

    var footer: some View {
        Text("Payment is charged to your Apple ID at the end of the trial. "
             + "Subscription renews automatically unless canceled at least 24 hours before the period ends.")
            .font(.footnote)
            .foregroundColor(.white.opacity(0.75))
            .multilineTextAlignment(.center)
            .padding(.bottom, 40)
            .opacity(animateContent ? 1.0 : 0)
            .animation(.easeInOut(duration: 0.8).delay(0.5), value: animateContent)
    }
    
    // ─────────────────────────── MOCK PURCHASE
    func purchase() {
        guard !isPurchasing else { return }
        isPurchasing = true
        // Simulate network call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isPurchasing = false
            onContinue()
        }
    }
}
