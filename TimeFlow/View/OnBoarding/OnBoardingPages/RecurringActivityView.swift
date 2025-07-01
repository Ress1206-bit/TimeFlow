//
//  RecurringActivityView.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/29/25.
//

import SwiftUI

struct RecurringActivitiesView: View {
    
    var onContinue: () -> Void = {}
    
    @State private var activities: [RecurringActivity] = []
    @State private var editing: RecurringActivity?
    @State private var showingSheet = false
    @State private var editMode: EditMode = .inactive
    
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
            
            VStack(spacing: 26) {
                header
                listCard
                addButton
                Spacer(minLength: 12)
                continueButton
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { progressToolbar }
        .sheet(isPresented: $showingSheet) {
            AddEditActivitySheet(existing: $editing) { save($0) }
        }
        .environment(\.editMode, $editMode)
        .preferredColorScheme(.dark)
    }
}

private extension RecurringActivitiesView {
    var header: some View {
        VStack(spacing: 8) {
            Text("Log your recurring activities")
                .font(.title2.bold())
                .foregroundColor(.white)
            Text("These happen at the same time every week—never double-booked.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal)
        }
    }
    
    var listCard: some View {
        Group {
            if activities.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.6))
                    Text("Nothing added yet")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(activities) { act in
                        ActivityRow(activity: act)
                            .swipeActions(edge: .trailing) {
                                Button("Delete", role: .destructive) { delete(act) }
                                Button("Edit") { edit(act) }
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(card)
                    }
                    .onMove(perform: move)
                }
                .listStyle(.plain)
                .frame(maxHeight: 300)
                .scrollContentBackground(.hidden)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(card)
                .shadow(color: .black.opacity(0.6), radius: 6, y: 3)
        )
    }
    
    var addButton: some View {
        Button {
            editing = nil
            showingSheet = true
        } label: {
            Label("Add activity", systemImage: "plus")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(activities.isEmpty ? accent : Color.clear)
                .foregroundColor(activities.isEmpty ? .white : accent)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(accent, lineWidth: activities.isEmpty ? 0 : 2)
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
                .background(activities.isEmpty ? Color.gray.opacity(0.4) : accent)
                .foregroundColor(.white)
                .cornerRadius(14)
        }
        .disabled(activities.isEmpty)
    }
    
    @ToolbarContentBuilder
    var progressToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Text("Step 5 of 6")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white.opacity(0.7))
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Skip") { onContinue() }
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

private struct ActivityRow: View {
    let activity: RecurringActivity
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(activity.color)
                .frame(width: 36, height: 36)
                .overlay(Image(systemName: activity.icon).foregroundColor(.white))
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.name).fontWeight(.semibold).foregroundColor(.white)
                Text(subtitle).font(.caption).foregroundColor(.white.opacity(0.8))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.7))
        }
        .contentShape(Rectangle())
    }
    private var subtitle: String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"
        let time = f.string(from: activity.start)
        let dur  = "\(activity.duration) min"
        let cadence: String = {
            switch activity.cadence {
            case .daily: return "Daily"
            case .weekdays: return "Weekdays"
            case .custom: return activity.customDays.map(\.rawValue).joined(separator: " ")
            }
        }()
        return "\(cadence) • \(dur) • \(time)"
    }
}

private struct AddEditActivitySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var existing: RecurringActivity?
    let onSave: (RecurringActivity) -> Void
    
    @State private var name = ""
    @State private var icon = "figure.walk"
    @State private var color = "blue"
    @State private var cadence: RecurringCadence = .daily
    @State private var days: Set<Weekday> = [.mon,.wed]
    @State private var start = Calendar.current.date(from: .init(hour: 18))!
    @State private var duration = 30
    
    private let icons  = ["figure.walk","dumbbell","book","pawprint","guitars","leaf","paintbrush","fork.knife"]
    private let colors = ["red","orange","yellow","green","mint","teal","cyan","blue","indigo","purple","pink"]
    private let card   = Color(red: 0.13, green: 0.13, blue: 0.15)
    private let accent = Color(red: 0.30, green: 0.64, blue: 0.97)
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Name") { TextField("Activity", text: $name) }
                    .listRowBackground(card)
                
                Section("Icon & colour") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(icons, id: \.self) { ic in
                                Image(systemName: ic)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(ic == icon ? accent : .clear,
                                                    lineWidth: 2)
                                    )
                                    .onTapGesture { icon = ic }
                            }
                        }
                    }
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 6)) {
                        ForEach(colors, id: \.self) { c in
                            Circle()
                                .fill(RecurringActivity(
                                    name:"",icon:"",colorName:c,
                                    cadence:.daily,customDays:[],
                                    start:.now,duration:1).color)
                                .overlay(
                                    Circle().stroke(c == color ? .white : .clear, lineWidth: 2)
                                )
                                .frame(width: 26, height: 26)
                                .onTapGesture { color = c }
                        }
                    }.padding(.vertical,4)
                }.listRowBackground(card)
                
                Section("Cadence") {
                    Picker("Frequency", selection: $cadence) {
                        ForEach(RecurringCadence.allCases) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented).tint(accent)
                    
                    if cadence == .custom {
                        DayChipsView(selection: $days)
                            .padding(.vertical, 4)
                    }
                }.listRowBackground(card)
                
                Section("Time & duration") {
                    DatePicker("Start", selection: $start,
                               displayedComponents: .hourAndMinute)
                    Stepper(value: $duration, in: 5...240, step: 5) {
                        Text("\(duration) min")
                    }
                }.listRowBackground(card)
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle(existing == nil ? "New activity" : "Edit activity")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty
                                  || (cadence == .custom && days.isEmpty))
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { if let ex = existing { load(ex) } }
            .preferredColorScheme(.dark)
        }
    }
    
    private func load(_ a: RecurringActivity) {
        name = a.name; icon = a.icon; color = a.colorName
        cadence = a.cadence; days = Set(a.customDays)
        start = a.start; duration = a.duration
    }
    
    private func save() {
        let act = RecurringActivity(
            name: name, icon: icon, colorName: color,
            cadence: cadence, customDays: cadence == .custom ? Array(days) : [],
            start: start, duration: duration
        )
        onSave(act); dismiss()
    }
    
    private struct DayChipsView: View {
        @Binding var selection: Set<Weekday>
        private let cols = [GridItem(.adaptive(minimum: 46), spacing: 8)]
        var body: some View {
            LazyVGrid(columns: cols, alignment: .leading, spacing: 8) {
                ForEach(Weekday.allCases, id: \.self) { d in
                    let sel = selection.contains(d)
                    Text(d.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .padding(.vertical,6)
                        .frame(minWidth: 44)
                        .background(
                            Capsule()
                                .fill(sel ? Color(red: 0.30, green: 0.64, blue: 0.97)
                                          : Color.gray.opacity(0.25))
                        )
                        .foregroundColor(sel ? .white : .primary)
                        .onTapGesture {
                            if sel { selection.remove(d) } else { selection.insert(d) }
                        }
                }
            }
        }
    }
}

private extension RecurringActivitiesView {
    func save(_ a: RecurringActivity) {
        if let i = activities.firstIndex(where: { $0.id == a.id }) { activities[i] = a }
        else { activities.append(a) }
    }
    func delete(_ a: RecurringActivity) { activities.removeAll { $0.id == a.id } }
    func move(from s: IndexSet, to d: Int) { activities.move(fromOffsets: s, toOffset: d) }
    func edit(_ a: RecurringActivity) { editing = a; showingSheet = true }
}

#Preview {
    NavigationStack { RecurringActivitiesView() }
}
