//
//  WorkHoursView.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/29/25.
//

import SwiftUI

struct WorkHoursView: View {
    
    var onContinue: () -> Void = {}
    
    @State private var rows: [DayHours] = Weekday.allCases.map { wd in
        let c = Calendar.current
        return DayHours(day: wd,
                        enabled: [.mon,.tue,.wed,.thu,.fri].contains(wd),
                        start: c.date(from: .init(hour: 9))!,
                        end:   c.date(from: .init(hour: 17))!)
    }
    @State private var copyAlert = false
    
    // ------------------------------------------------------------------
    private let bg      = Color.black
    private let card    = Color(red: 0.13, green: 0.13, blue: 0.15)
    private let accent  = Color(red: 0.30, green: 0.64, blue: 0.97)
    
    private var valid: Bool {
        rows.filter(\.enabled).allSatisfy { $0.end > $0.start }
    }
    
    // ------------------------------------------------------------------
    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
                .overlay(
                    Image("Noise")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.05)
                        .ignoresSafeArea()
                )
            
            VStack(spacing: 28) {
                header
                
                ScrollView {
                    VStack(spacing: 18) {
                        ForEach($rows) { $row in
                            rowCard($row)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Button("Copy Monday to Tue–Fri") { copyAlert = true }
                    .font(.subheadline.weight(.semibold))
                    .disabled(!rows.first!.enabled)
                    .tint(accent)
                
                continueButton
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { progressToolbar }
        .alert("Copy Monday’s hours to Tue–Fri?",
               isPresented: $copyAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Copy", role: .destructive) { copyMonday() }
        }
        .preferredColorScheme(.dark)
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

// MARK: sub-views
private extension WorkHoursView {
    
    var header: some View {
        VStack(spacing: 8) {
            Text("Set your core work hours")
                .font(.title2.bold())
                .foregroundColor(.white)
            Text("We’ll avoid scheduling personal tasks inside this window.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal)
        }
    }
    
    func rowCard(_ binding: Binding<DayHours>) -> some View {
        let row = binding.wrappedValue
        return VStack(alignment: .leading, spacing: 14) {
            Toggle(row.day.rawValue, isOn: binding.enabled)
                .toggleStyle(.switch)
                .font(.headline)
                .tint(accent)
                .foregroundColor(.white)
            
            if row.enabled {
                HStack {
                    DatePicker("", selection: binding.start,
                               displayedComponents: .hourAndMinute)
                        .labelsHidden()
                    Spacer()
                    Image(systemName: "arrow.right")
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    DatePicker("", selection: binding.end,
                               displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(card)
                .shadow(color: .black.opacity(0.6), radius: 6, y: 3)
        )
    }
    
    var continueButton: some View {
        Button(action: onContinue) {
            Text("Continue")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(valid ? accent : Color.gray.opacity(0.4))
                .foregroundColor(.white)
                .cornerRadius(16)
        }
        .disabled(!valid)
        .padding(.horizontal)
        .padding(.bottom, 26)
    }
    
    func copyMonday() {
        guard let mon = rows.first else { return }
        for i in 1...4 {
            rows[i].enabled = mon.enabled
            rows[i].start   = mon.start
            rows[i].end     = mon.end
        }
    }
}

// MARK: preview
#Preview {
    NavigationStack { WorkHoursView() }
}
