//
//  GoalsView.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/28/25.
//


import SwiftUI

// ----------------------------------------------------------------------
//  GOALS PAGE — matte-black theme
// ----------------------------------------------------------------------

struct GoalsView: View {
    
    var onContinue: () -> Void = {}
    
    @State private var goals: [Goal] = []
    @State private var editingGoal: Goal?
    @State private var showSheet = false
    @State private var editMode: EditMode = .inactive
    
    private let accent = Color(red: 0.30, green: 0.64, blue: 0.97)
    private let card   = Color(red: 0.13, green: 0.13, blue: 0.15)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
                .overlay(
                    Image("Noise").resizable()
                        .scaledToFill()
                        .opacity(0.05)
                        .ignoresSafeArea()
                )
            
            VStack(spacing: 26) {
                header
                goalList
                addButton
                Spacer(minLength: 12)
                continueButton
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { progressToolbar }
        .sheet(isPresented: $showSheet) {
            AddEditGoalSheet(
                existing: $editingGoal,
                onSave: { saveGoal($0) },
                existingTitles: goals.map { $0.title.lowercased() }
            )
        }
        .environment(\.editMode, $editMode)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Header, list, CTA
private extension GoalsView {
    
    var header: some View {
        VStack(spacing: 8) {
            Text("Tell us what you’re working toward.")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            Text("We’ll carve out time for each goal automatically.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(.top, 12)
    }
    
    var goalList: some View {
        Group {
            if goals.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "target")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.6))
                    Text("No goals yet")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(card)
                        .shadow(color: .black.opacity(0.6), radius: 6, y: 3)
                )
            } else {
                List {
                    ForEach(goals) { goal in
                        GoalRow(goal: goal)
                            .swipeActions(edge: .trailing) {
                                Button("Delete", role: .destructive) { deleteGoal(goal) }
                                Button("Edit") { edit(goal) }
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(card)
                    }
                    .onMove(perform: moveGoal)
                }
                .listStyle(.plain)
                .frame(maxHeight: 260)
                .scrollContentBackground(.hidden)
            }
        }
    }
    
    var addButton: some View {
        Button {
            editingGoal = nil
            showSheet = true
        } label: {
            Label("Add goal", systemImage: "plus")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(goals.isEmpty ? accent : Color.clear)
                .foregroundColor(goals.isEmpty ? .white : accent)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(accent, lineWidth: goals.isEmpty ? 0 : 2)
                )
                .cornerRadius(14)
        }
    }
    
    var continueButton: some View {
        Button(action: onContinue) {
            Text("Continue")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(goals.isEmpty ? Color.gray.opacity(0.4) : accent)
                .foregroundColor(.white)
                .cornerRadius(14)
        }
        .disabled(goals.isEmpty)
    }
    
    @ToolbarContentBuilder
    var progressToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Text("Step 4 of 6")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white.opacity(0.7))
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Skip") { onContinue() }
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

// MARK: - Goal row
private struct GoalRow: View {
    let goal: Goal
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(goal.color)
                .frame(width: 36, height: 36)
                .overlay(Image(systemName: goal.symbol).foregroundColor(.white))
            VStack(alignment: .leading, spacing: 2) {
                Text(goal.title).fontWeight(.semibold).foregroundColor(.white)
                Text(goal.activity).font(.caption).foregroundColor(.white.opacity(0.8))
                Text(subtitle).font(.caption2).foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.7))
        }
    }
    private var subtitle: String {
        let freq = goal.cadence == .custom ? "\(goal.customPerWeek ?? 0)×/wk"
                                           : goal.cadence.rawValue
        return "\(freq) • \(goal.durationMinutes) min"
    }
}

// ----------------------------------------------------------------------
//  ADD / EDIT SHEET — inherits dark mode
// ----------------------------------------------------------------------

private struct AddEditGoalSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @Binding var existing: Goal?
    let onSave: (Goal) -> Void
    let existingTitles: [String]
    
    @State private var title          = ""
    @State private var activity       = ""
    @State private var details        = ""
    @State private var cadence: Cadence = .daily
    @State private var customPerWeek  = 3
    @State private var duration       = 30
    @State private var colorName      = "accent"
    
    @State private var showDupeAlert  = false
    
    private let palette = ["red","orange","yellow","green","mint","teal",
                           "cyan","blue","indigo","purple","pink","accent"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("Goal title", text: $title)
                }
                .listRowBackground(Color(red: 0.13, green: 0.13, blue: 0.15))
                
                Section("Activity") {
                    TextField("Primary activity", text: $activity)
                    TextField("Short description", text: $details, axis: .vertical)
                }
                .listRowBackground(Color(red: 0.13, green: 0.13, blue: 0.15))
                
                Section("Cadence") {
                    Picker("", selection: $cadence) {
                        ForEach(Cadence.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    
                    if cadence == .custom {
                        Stepper(value: $customPerWeek, in: 1...7) {
                            Text("\(customPerWeek)× per week")
                        }
                    }
                }
                .listRowBackground(Color(red: 0.13, green: 0.13, blue: 0.15))
                .tint(Color(red: 0.30, green: 0.64, blue: 0.97))
                
                Section("Duration (incl. travel)") {
                    Stepper(value: $duration, in: 5...240, step: 5) {
                        Text("\(duration) min per session")
                    }
                }
                .listRowBackground(Color(red: 0.13, green: 0.13, blue: 0.15))
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 6)) {
                        ForEach(palette, id: \.self) { name in
                            Circle()
                                .fill(Goal(title: "_", colorName: name).color)
                                .overlay(
                                    Circle().stroke(name == colorName ? .white : .clear, lineWidth: 2)
                                )
                                .frame(width: 28, height: 28)
                                .onTapGesture { colorName = name }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color(red: 0.13, green: 0.13, blue: 0.15))
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle(existing == nil ? "New goal" : "Edit goal")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { attemptSave() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Goal title already exists", isPresented: $showDupeAlert) {
                Button("OK", role: .cancel) {}
            }
            .onAppear { if let g = existing { populate(from: g) } }
            .preferredColorScheme(.dark)
        }
    }
    
    private func populate(from g: Goal) {
        title         = g.title
        activity      = g.activity
        details       = g.details
        cadence       = g.cadence
        customPerWeek = g.customPerWeek ?? 3
        duration      = g.durationMinutes
        colorName     = g.colorName
    }
    
    private func attemptSave() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        let dup = existingTitles.contains(trimmed.lowercased()) &&
                  trimmed.lowercased() != existing?.title.lowercased()
        if dup { showDupeAlert = true; return }
        
        let goal = Goal(id: existing?.id ?? UUID(),
                        title: trimmed,
                        activity: activity,
                        details: details,
                        cadence: cadence,
                        customPerWeek: cadence == .custom ? customPerWeek : nil,
                        durationMinutes: duration,
                        colorName: colorName)
        onSave(goal); dismiss()
    }
}

// MARK: CRUD helpers
private extension GoalsView {
    func saveGoal(_ g: Goal) {
        if let i = goals.firstIndex(where: { $0.id == g.id }) { goals[i] = g }
        else { goals.append(g) }
    }
    func deleteGoal(_ g: Goal) { goals.removeAll { $0.id == g.id } }
    func moveGoal(from src: IndexSet, to dest: Int) { goals.move(fromOffsets: src, toOffset: dest) }
    func edit(_ g: Goal) { editingGoal = g; showSheet = true }
}

#Preview {
    NavigationStack { GoalsView() }
}
