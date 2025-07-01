//
//  SubscriptionView.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/30/25.
//

import SwiftUI


struct SubscriptionView: View {
    
    var onContinue: () -> Void = {}
    
    
    enum Plan: String, CaseIterable, Identifiable { case monthly, yearly
        var id: String { rawValue }
    }
    @State private var selected: Plan = .yearly
    @State private var isPurchasing = false
    
    
    private let bg     = Color.black
    private let card   = Color(red: 0.13, green: 0.13, blue: 0.15)
    private let accent = Color(red: 0.30, green: 0.64, blue: 0.97)
    
    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
                .overlay(Image("Noise")
                            .resizable()
                            .scaledToFill()
                            .opacity(0.05)
                            .ignoresSafeArea())
            
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
    }
    
    var pricingCards: some View {
        VStack(spacing: 20) {
            
            ForEach(Plan.allCases) { plan in
                planCard(for: plan)
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
                        .stroke(picked ? accent : .clear, lineWidth: 3)
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
                .background(accent)
                .foregroundColor(.white)
                .cornerRadius(16)
            }
            .disabled(isPurchasing)
            
            Button(action: onContinue) {
                Text("Maybe Later")
                    .underline()
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.bottom, 8)
        }
    }
    

    var footer: some View {
        Text("Payment is charged to your Apple ID at the end of the trial. "
             + "Subscription renews automatically unless canceled at least 24 hours before the period ends.")
            .font(.footnote)
            .foregroundColor(.white.opacity(0.75))
            .multilineTextAlignment(.center)
            .padding(.bottom, 40)
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


#Preview {
    NavigationStack { SubscriptionView() }
}
