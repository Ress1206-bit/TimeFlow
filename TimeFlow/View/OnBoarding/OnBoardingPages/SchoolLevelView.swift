//
//  SchoolLevel.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/27/25.
//

import SwiftUI

import SwiftUI

struct SchoolLevelView: View {
    
    @State private var selection: AgeGroup?
    var onContinue: (AgeGroup) -> Void = { _ in }
    
    private let grid = [GridItem(.adaptive(minimum: 150), spacing: 16)]
    
    private let cardFill   = Color(red: 0.13, green: 0.13, blue: 0.15)
    private let cardStroke = Color(red: 0.30, green: 0.64, blue: 0.97)
    private let accent     = Color(red: 0.30, green: 0.64, blue: 0.97)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
                .overlay(
                    Image("Noise")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.05)
                        .ignoresSafeArea()
                )
            
            VStack(spacing: 36) {
                header
                LazyVGrid(columns: grid, spacing: 18) {
                    ForEach(AgeGroup.allCases) { card(for: $0) }
                }
                .padding(.horizontal)
                Spacer()
                continueButton
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { progressToolbar }
        .preferredColorScheme(.dark)
    }
    
    @ToolbarContentBuilder
    var progressToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Text("Step 1 of 6")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
}

private extension SchoolLevelView {
    
    var header: some View {
        VStack(spacing: 10) {
            Text("Tell us where you are")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            Text("We’ll tailor the planner around your day-to-day reality.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal)
        }
        .padding(.top, 60)
    }
    
    func card(for group: AgeGroup) -> some View {
        let picked = selection == group
        return VStack(spacing: 14) {
            Image(systemName: group.icon)
                .font(.system(size: 42, weight: .semibold))
                .foregroundColor(picked ? accent : .white)
            Text(group.rawValue)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(picked ? accent : Color.clear, lineWidth: 3)
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
        .onTapGesture { withAnimation(.easeInOut) { selection = group } }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(picked ? .isSelected : [])
    }
    
    var continueButton: some View {
        Button {
            if let s = selection { onContinue(s) }
        } label: {
            Text("Continue")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selection == nil ? Color.white.opacity(0.15) : Color.white)
                .foregroundColor(selection == nil ? .white.opacity(0.5) : accent)
                .cornerRadius(16)
        }
        .disabled(selection == nil)
        .padding(.horizontal)
        .padding(.bottom, 22)
    }
}

#Preview {
    NavigationStack { SchoolLevelView() }
}
