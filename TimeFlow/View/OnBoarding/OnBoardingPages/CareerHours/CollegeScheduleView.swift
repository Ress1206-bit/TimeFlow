//
//  CollegeScheduleView.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/28/25.
//

import SwiftUI

struct CollegeScheduleView: View {
    
    var onContinue: () -> Void = {}
    
    init(onContinue: @escaping () -> Void = {}) {
        self.onContinue = onContinue
        UIScrollView.appearance().bounces = false
    }
    
    @State private var courses: [Course] = []
    @State private var editing: Course? = nil
    @State private var showSheet = false
    
    private let hourHeight: CGFloat = 38               // 30-min row
    private let bg        = Color.black
    private let card      = Color(red: 0.13, green: 0.13, blue: 0.15)
    private let accent    = Color(red: 0.30, green: 0.64, blue: 0.97)
    

    private let weekdays: [Weekday] = Array(Weekday.allCases.prefix(5)) // Mon-Fri
    
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
            
            VStack(spacing: 24) {
                header
                
                calendarPanel
                    .padding(.horizontal, 8)
                
                addButton
                
                Button(action: onContinue) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(courses.isEmpty ? Color.gray.opacity(0.4) : accent)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .disabled(courses.isEmpty)
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { progressToolbar }
        .sheet(isPresented: $showSheet) {
            ClassSheet(existing: $editing) { save($0) }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: Calendar
private extension CollegeScheduleView {
    
    var calendarPanel: some View {
        VStack(spacing: 0) {
            weekdayHeader
            ScrollView(showsIndicators: true) {
                calendarGrid
                    .frame(height: hourHeight * 18)   // 6 AM→12 AM
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(card)
                .shadow(color: .black.opacity(0.6), radius: 8, y: 4)
        )
    }
    
    var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdays) { day in
                Text(day.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 6)
        .background(card.opacity(0.9))
    }
    
    var calendarGrid: some View {
        ZStack(alignment: .topLeading) {
            gridLines
            classBlocks
        }
    }
    
    var gridLines: some View {
        VStack(spacing: 0) {
            ForEach(0..<18) { _ in
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 1)
                Spacer().frame(height: hourHeight - 1)
            }
        }
        .overlay(
            HStack(spacing: 0) {
                ForEach(weekdays) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 1)
                    Spacer()
                }
            }
        )
    }
    
    var classBlocks: some View {
        GeometryReader { geo in
            ForEach(courses) { cls in
                let colW = geo.size.width / 5
                let colX = CGFloat(weekdays.firstIndex(of: cls.day) ?? 0)
                let (top, height) = rect(for: cls)
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(cls.color.opacity(0.9))
                    .overlay(
                        VStack(alignment: .leading, spacing: 2) {
                            Text(cls.name).font(.caption).bold()
                            Text(time(cls.start)+" – "+time(cls.end))
                                .font(.caption2)
                        }
                        .foregroundColor(.white)
                        .padding(4),
                        alignment: .topLeading
                    )
                    .frame(width: colW - 4, height: height - 2)
                    .position(x: colW * colX + colW/2,
                              y: top + height/2)
                    .onTapGesture { editing = cls; showSheet = true }
            }
        }
        .clipped()
    }
    
    func rect(for cls: Course) -> (CGFloat, CGFloat) {
        let s = fractionalHours(cls.start)
        let e = fractionalHours(cls.end)
        let top = CGFloat(s - 6) * hourHeight
        let h   = CGFloat(e - s) * hourHeight
        return (top, h)
    }
    
    func fractionalHours(_ d: Date) -> Double {
        let c = Calendar.current.dateComponents([.hour,.minute], from: d)
        return Double(c.hour!) + Double(c.minute!) / 60
    }
    
    func time(_ d: Date) -> String {
        DateFormatter.localizedString(from: d, dateStyle: .none, timeStyle: .short)
    }
}

// MARK: Fixed UI
private extension CollegeScheduleView {
    
    var header: some View {
        VStack(spacing: 6) {
            Text("Add your classes")
                .font(.title2.bold())
                .foregroundColor(.white)
            Text("Tap + to insert · tap block to edit")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal)
    }
    
    var addButton: some View {
        Button {
            editing = nil
            showSheet = true
        } label: {
            Label("Add class", systemImage: "plus")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(accent)
                .foregroundColor(.white)
                .cornerRadius(14)
                .padding(.horizontal)
        }
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

private struct ClassSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var existing: Course?
    let onSave: (Course) -> Void
    
    @State private var name  = ""
    @State private var day   : Weekday  = .mon
    @State private var start = Calendar.current.date(from: .init(hour: 9))!
    @State private var end   = Calendar.current.date(from: .init(hour: 10))!
    @State private var picked: Color    = .blue
    @State private var showDelete = false
    
    private let accent  = Color(red: 0.30, green: 0.64, blue: 0.97)
    private let card    = Color(red: 0.13, green: 0.13, blue: 0.15)
    private let palette: [Color] = [.red,.orange,.yellow,.green,.mint,.teal,
                                    .cyan,.blue,.indigo,.purple,.pink]
    
    private let weekdays: [Weekday] = Array(Weekday.allCases.prefix(5)) // Mon-Fri
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Course name", text: $name)
                        .foregroundColor(.white)
                }
                .listRowBackground(card)
                
                Section {
                    Picker("Day", selection: $day) {
                        ForEach(weekdays) { Text($0.rawValue).tag($0) }
                    }
                    DatePicker("Starts", selection: $start,
                               in: timeRange, displayedComponents: .hourAndMinute)
                    DatePicker("Ends",   selection: $end,
                               in: timeRange, displayedComponents: .hourAndMinute)
                }
                .listRowBackground(card)
                .tint(accent)
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 6)) {
                        ForEach(palette, id: \.self) { col in
                            Circle()
                                .fill(col)
                                .overlay(
                                    Circle()
                                        .stroke(col == picked ? Color.white : .clear, lineWidth: 2)
                                )
                                .frame(width: 28, height: 28)
                                .onTapGesture { picked = col }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(card)
                
                if existing != nil {
                    Section {
                        Button("Delete class", role: .destructive) { showDelete = true }
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .listRowBackground(card)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)                     // matte backdrop
            .navigationTitle(existing == nil ? "New class" : "Edit class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || end <= start)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { if let c = existing { load(c) } }
            .alert("Delete this class?", isPresented: $showDelete) {
                Button("Delete", role: .destructive) {
                    onSave(Course(id: existing!.id,
                                  name: "", day: .mon,
                                  start: Date(), end: Date(),
                                  color: .clear))
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            }
        }
        .preferredColorScheme(.dark)                     // force dark mode
    }
    
    private var timeRange: ClosedRange<Date> {
        let c = Calendar.current
        return c.date(from: .init(hour: 6))!
             ...
        c.date(from: .init(hour: 23, minute: 30))!
    }
    
    private func load(_ c: Course) {
        name   = c.name
        day    = c.day
        start  = c.start
        end    = c.end
        picked = c.color
    }
    
    private func save() {
        let new = Course(id: existing?.id ?? UUID(),
                         name: name,
                         day: day,
                         start: start,
                         end: end,
                         color: picked)
        onSave(new)
        dismiss()
    }
}

private extension CollegeScheduleView {
    func save(_ c: Course) {
        if let i = courses.firstIndex(where: { $0.id == c.id }) {
            if c.name.isEmpty { courses.remove(at: i) }
            else              { courses[i] = c }
        } else { courses.append(c) }
    }
}

#Preview {
    NavigationStack { CollegeScheduleView() }
}
