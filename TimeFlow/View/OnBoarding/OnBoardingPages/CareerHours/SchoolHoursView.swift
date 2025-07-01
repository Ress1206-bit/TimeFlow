//
//  SchoolHoursView.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/28/25.
//

import SwiftUI

struct SchoolHoursView: View {
    
    var onContinue: () -> Void = {}
    
    @State private var start = Calendar.current.date(from: .init(hour: 8))!
    @State private var end   = Calendar.current.date(from: .init(hour: 15))!
    
    private var validRange: Bool { end > start }
    
    private let cardFill = Color(red: 0.13, green: 0.13, blue: 0.15)
    private let accent   = Color(red: 0.30, green: 0.64, blue: 0.97)
    
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
            
            VStack {
                
                Spacer()
                
                header
                
                VStack(spacing: 28) {
                    timePicker(title: "School day starts", binding: $start)
                    timePicker(title: "School day ends",   binding: $end)
                }
                
                Spacer()
                
                Button {
                    onContinue()
                } label: {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(validRange ? accent : Color.gray.opacity(0.4))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .disabled(!validRange)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { progressToolbar }
        .preferredColorScheme(.dark)
    }
    
    private func timePicker(title: String, binding: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white.opacity(0.8))
            DatePicker(
                "",
                selection: binding,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardFill)
                    .shadow(color: .black.opacity(0.5), radius: 6, y: 3)
            )
        }
        .padding(.horizontal)
    }
    
    private var header: some View {
        VStack(spacing: 10) {
            Text("When are you in class?")
                .font(.title2.bold())
                .foregroundColor(.white)
            Text("We’ll protect these hours Monday–Friday.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.85))
        }
        .padding()
    }
    
    @ToolbarContentBuilder
    var progressToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Text("Step 2 of 6")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white.opacity(0.7))
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Skip") { onContinue() }
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

#Preview {
    NavigationStack { SchoolHoursView() }
}
