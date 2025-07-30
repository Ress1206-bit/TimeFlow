//
//  EditScheduleView.swift
//  TimeFlow
//
//  Created by Adam Ress on 12/31/24.
//

import SwiftUI

struct EditScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ContentModel.self) var contentModel
    
    @State private var events: [Event] = []
    @State private var selectedEvent: Event?
    @State private var showingEventEditor = false
    @State private var showingAIChat = false
    @State private var showingDeleteConfirmation = false
    @State private var eventToDelete: Event?
    @State private var editMode = false
    @State private var filterType: EventType? = nil
    @State private var showingFilters = false
    @State private var showingCreditAlert = false
    
    // Animation namespace for smooth transitions
    @Namespace private var editAnimation
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient matching HomeView
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
                
                VStack(spacing: 0) {
                    headerView
                    
                    if filteredEvents.isEmpty && events.isEmpty {
                        emptyStateView
                    } else {
                        scheduleContentView
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingEventEditor) {
            if let selectedEvent = selectedEvent {
                EventEditorView(
                    event: selectedEvent,
                    onSave: { updatedEvent in
                        updateEvent(updatedEvent)
                    },
                    onDelete: { eventToDelete in
                        deleteEvent(eventToDelete)
                    }
                )
            } else {
                EventEditorView(
                    event: createNewEvent(),
                    onSave: { newEvent in
                        addEvent(newEvent)
                    }
                )
            }
        }
        .sheet(isPresented: $showingAIChat) {
            AIScheduleUpdateView(
                currentEvents: events,
                contentModel: contentModel,
                onScheduleUpdate: { updatedEvents in
                    events = updatedEvents
                    saveScheduleChanges()
                }
            )
        }
        .alert("Delete Event", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let event = eventToDelete {
                    deleteEvent(event)
                }
            }
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone.")
        }
        .alert("No Credits Remaining", isPresented: $showingCreditAlert) {
            Button("OK") { }
        } message: {
            Text("You've used all 3 AI schedule updates for today. Credits reset daily.")
        }
        .onAppear {
            loadEvents()
            contentModel.checkAndResetCreditsIfNeeded()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Edit Schedule")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text(Date().formatted(.dateTime.weekday(.wide).day().month(.abbreviated)))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    // AI Credits indicator
                    Button {
                        if contentModel.hasCreditsRemaining() {
                            showingAIChat = true
                        } else {
                            showingCreditAlert = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 12, weight: .semibold))
                            Text("\(contentModel.dailyCredits)")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(contentModel.hasCreditsRemaining() ? AppTheme.Colors.accent : AppTheme.Colors.textTertiary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(AppTheme.Colors.cardBackground)
                                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                        )
                    }
                    
                    // Filter toggle
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showingFilters.toggle()
                        }
                    } label: {
                        Image(systemName: showingFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(AppTheme.Colors.cardBackground)
                                    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                            )
                    }
                    
                    // Edit mode toggle
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            editMode.toggle()
                        }
                    } label: {
                        Image(systemName: editMode ? "checkmark.circle.fill" : "pencil.circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(editMode ? AppTheme.Colors.accent : AppTheme.Colors.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(AppTheme.Colors.cardBackground)
                                    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)
            
            // Action buttons row
            HStack(spacing: 12) {
                Button {
                    if contentModel.hasCreditsRemaining() {
                        showingAIChat = true
                    } else {
                        showingCreditAlert = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 14, weight: .semibold))
                        Text("AI Update (\(contentModel.dailyCredits) left)")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: contentModel.hasCreditsRemaining() ?
                                        [AppTheme.Colors.accent, AppTheme.Colors.accent.opacity(0.8)] :
                                        [AppTheme.Colors.textTertiary, AppTheme.Colors.textTertiary.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: AppTheme.Colors.accent.opacity(contentModel.hasCreditsRemaining() ? 0.3 : 0.1), radius: 8, y: 4)
                    )
                }
                .disabled(!contentModel.hasCreditsRemaining())
                
                Button {
                    selectedEvent = nil
                    showingEventEditor = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Add Event")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.Colors.cardBackground)
                            .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.Colors.overlay.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            // Filters section
            if showingFilters {
                filterSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Divider
            Rectangle()
                .fill(AppTheme.Colors.overlay.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, 24)
        }
        .background(AppTheme.Colors.background)
    }
    
    // MARK: - Filter Section
    private var filterSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Filter by Type")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Button("Clear") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        filterType = nil
                    }
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.Colors.accent)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(EventType.allCases, id: \.self) { type in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                filterType = filterType == type ? nil : type
                            }
                        } label: {
                            Text(type.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(filterType == type ? .white : AppTheme.Colors.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(filterType == type ? eventTypeColor(type) : AppTheme.Colors.cardBackground)
                                        .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 24) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.accent.opacity(0.1),
                                AppTheme.Colors.accent.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(AppTheme.Colors.accent)
                    )
                
                VStack(spacing: 12) {
                    Text("No Events to Edit")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("Start by generating a schedule or adding events manually")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal, 32)
                }
                
                Button {
                    dismiss()
                } label: {
                    Text("Go Back to Schedule")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.Colors.accent, AppTheme.Colors.accent.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: AppTheme.Colors.accent.opacity(0.3), radius: 8, y: 4)
                        )
                }
                .padding(.horizontal, 32)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Schedule Content View
    private var scheduleContentView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                ForEach(filteredEvents, id: \.id) { event in
                    eventRow(event)
                        .matchedGeometryEffect(id: event.id, in: editAnimation)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Event Row
    private func eventRow(_ event: Event) -> some View {
        HStack(spacing: 16) {
            // Time column
            VStack(alignment: .leading, spacing: 2) {
                Text(event.start.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(event.end.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .frame(width: 60, alignment: .leading)
            
            // Event content
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(event.color.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: event.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(event.color)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Text(event.eventType.rawValue)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(event.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(event.color.opacity(0.1))
                            )
                        
                        Text(durationText(for: event))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
                
                Spacer()
                
                if editMode {
                    HStack(spacing: 8) {
                        Button {
                            selectedEvent = event
                            showingEventEditor = true
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.accent)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(AppTheme.Colors.accent.opacity(0.1))
                                )
                        }
                        
                        Button {
                            eventToDelete = event
                            showingDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.red)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(Color.red.opacity(0.1))
                                )
                        }
                    }
                } else {
                    Button {
                        selectedEvent = event
                        showingEventEditor = true
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.cardBackground)
                .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(event.color.opacity(0.2), lineWidth: 1)
        )
        .scaleEffect(editMode && selectedEvent?.id == event.id ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: editMode)
        .onTapGesture {
            if !editMode {
                selectedEvent = event
                showingEventEditor = true
            }
        }
    }
    
    // MARK: - Computed Properties
    private var filteredEvents: [Event] {
        var filtered = events
        
        // Apply type filter
        if let filterType = filterType {
            filtered = filtered.filter { $0.eventType == filterType }
        }
        
        // Apply search filter
        if false {
            filtered = filtered.filter { event in
                event.title.localizedCaseInsensitiveContains("") ||
                event.eventType.rawValue.localizedCaseInsensitiveContains("")
            }
        }
        
        return filtered.sorted { $0.start < $1.start }
    }
    
    // MARK: - Helper Functions
    private func loadEvents() {
        if let user = contentModel.user {
            let now = Date()
            events = user.currentSchedule.filter { event in
                !event.title.contains("NGTime") && event.end > now
            }
        }
    }
    
    private func saveScheduleChanges() {
        contentModel.user?.currentSchedule = events
        Task {
            do {
                try await contentModel.saveUserInfo()
            } catch {
                print("❌ Failed to save schedule changes: \(error)")
            }
        }
    }
    
    private func addEvent(_ event: Event) {
        events.append(event)
        events.sort { $0.start < $1.start }
        saveScheduleChanges()
    }
    
    private func updateEvent(_ updatedEvent: Event) {
        if let index = events.firstIndex(where: { $0.id == updatedEvent.id }) {
            events[index] = updatedEvent
            events.sort { $0.start < $1.start }
            saveScheduleChanges()
        }
    }
    
    private func deleteEvent(_ event: Event) {
        events.removeAll { $0.id == event.id }
        saveScheduleChanges()
    }
    
    private func createNewEvent() -> Event {
        let now = Date()
        let calendar = Calendar.current
        let startTime = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
        let endTime = calendar.date(byAdding: .minute, value: 60, to: startTime) ?? startTime
        
        return Event(
            start: startTime,
            end: endTime,
            title: "New Event",
            icon: "calendar",
            eventType: .other,
            colorName: "accent"
        )
    }
    
    private func durationText(for event: Event) -> String {
        let minutes = Int(event.end.timeIntervalSince(event.start) / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 && remainingMinutes > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func eventTypeColor(_ type: EventType) -> Color {
        switch type {
        case .school, .collegeClass:
            return .blue
        case .work:
            return .indigo
        case .goal:
            return .purple
        case .assignment, .testStudy:
            return .orange
        case .meal:
            return .green
        case .recurringCommitment:
            return .pink
        case .other:
            return .gray
        }
    }
}

// MARK: - Event Editor View
struct EventEditorView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var event: Event
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var selectedIcon = "calendar"
    @State private var selectedColor = "accent"
    @State private var showingIconPicker = false
    @State private var showingColorPicker = false
    
    let onSave: (Event) -> Void
    let onDelete: ((Event) -> Void)?
    
    private let isNewEvent: Bool
    
    private let availableIcons = [
        "calendar", "clock", "book.fill", "laptopcomputer", "dumbbell.fill",
        "fork.knife", "car.fill", "house.fill", "briefcase.fill", "graduationcap.fill",
        "heart.fill", "star.fill", "bell.fill", "phone.fill", "envelope.fill"
    ]
    
    private let availableColors = [
        "accent", "red", "blue", "green", "orange", "purple", "pink", "yellow", "gray"
    ]
    
    init(event: Event, onSave: @escaping (Event) -> Void, onDelete: ((Event) -> Void)? = nil) {
        self._event = State(initialValue: event)
        self._startDate = State(initialValue: event.start)
        self._endDate = State(initialValue: event.end)
        self._selectedIcon = State(initialValue: event.icon)
        self._selectedColor = State(initialValue: event.colorName ?? "accent")
        self.onSave = onSave
        self.onDelete = onDelete
        self.isNewEvent = event.title == "New Event"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Event Title", text: $event.title)
                        .font(.system(size: 16, weight: .medium))
                    
                    Picker("Event Type", selection: $event.eventType) {
                        ForEach(EventType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
                
                Section("Timing") {
                    DatePicker("Start Time", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("End Time", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Appearance") {
                    HStack {
                        Text("Icon")
                        Spacer()
                        Button {
                            showingIconPicker = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: selectedIcon)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color.activityColor(selectedColor))
                                Text("Choose")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Color")
                        Spacer()
                        Button {
                            showingColorPicker = true
                        } label: {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.activityColor(selectedColor))
                                    .frame(width: 20, height: 20)
                                Text("Choose")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                            }
                        }
                    }
                }
                
                if !isNewEvent, let onDelete = onDelete {
                    Section {
                        Button("Delete Event") {
                            onDelete(event)
                            dismiss()
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle(isNewEvent ? "New Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEvent()
                    }
                    .fontWeight(.semibold)
                    .disabled(event.title.isEmpty || endDate <= startDate)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                iconPickerView
            }
            .sheet(isPresented: $showingColorPicker) {
                colorPickerView
            }
        }
    }
    
    private var iconPickerView: some View {
        NavigationStack {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                ForEach(availableIcons, id: \.self) { icon in
                    Button {
                        selectedIcon = icon
                        showingIconPicker = false
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: icon)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(selectedIcon == icon ? Color.activityColor(selectedColor) : AppTheme.Colors.textSecondary)
                                .frame(width: 50, height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedIcon == icon ? Color.activityColor(selectedColor).opacity(0.1) : AppTheme.Colors.cardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedIcon == icon ? Color.activityColor(selectedColor) : Color.clear, lineWidth: 2)
                                        )
                                )
                        }
                    }
                }
            }
            .padding(24)
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingIconPicker = false
                    }
                }
            }
        }
    }
    
    private var colorPickerView: some View {
        NavigationStack {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                ForEach(availableColors, id: \.self) { color in
                    Button {
                        selectedColor = color
                        showingColorPicker = false
                    } label: {
                        VStack(spacing: 8) {
                            Circle()
                                .fill(Color.activityColor(color))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? AppTheme.Colors.textPrimary : Color.clear, lineWidth: 3)
                                        .frame(width: 60, height: 60)
                                )
                            
                            Text(color.capitalized)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                }
            }
            .padding(24)
            .navigationTitle("Choose Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingColorPicker = false
                    }
                }
            }
        }
    }
    
    private func saveEvent() {
        event.start = startDate
        event.end = endDate
        event.icon = selectedIcon
        event.colorName = selectedColor
        onSave(event)
        dismiss()
    }
}

// MARK: - AI Schedule Update View
struct AIScheduleUpdateView: View {
    @Environment(\.dismiss) private var dismiss
    
    let currentEvents: [Event]
    let contentModel: ContentModel
    let onScheduleUpdate: ([Event]) -> Void
    
    @State private var messages: [Message] = []
    @State private var message = ""
    @State private var isProcessing = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with credits
                headerSection
                
                // Chat history
                if messages.isEmpty {
                    emptyConversationView
                } else {
                    chatHistoryView
                }
                
                // Input section
                inputSection
            }
            .background(AppTheme.Colors.background)
            .navigationBarHidden(true)
            .keyboardAdaptive()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("AI Schedule Assistant")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 12, weight: .medium))
                        Text("\(contentModel.dailyCredits) credits remaining")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(AppTheme.Colors.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(AppTheme.Colors.accent.opacity(0.1))
                    )
                }
                
                Spacer()
                
                // Spacer to balance the close button
                Color.clear
                    .frame(width: 24, height: 24)
            }
            
            // Current schedule summary
            currentScheduleSummary
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .background(
            Rectangle()
                .fill(AppTheme.Colors.background)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }
    
    private var currentScheduleSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Schedule (\(currentEvents.count) events)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            if currentEvents.isEmpty {
                Text("No events scheduled")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .italic()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(currentEvents.prefix(5), id: \.id) { event in
                            HStack(spacing: 6) {
                                Image(systemName: event.icon)
                                    .font(.system(size: 10))
                                    .foregroundColor(event.color)
                                
                                Text(event.title)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                    .lineLimit(1)
                                
                                Text(event.start.formatted(date: .omitted, time: .shortened))
                                    .font(.system(size: 9))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(event.color.opacity(0.1))
                            )
                        }
                        
                        if currentEvents.count > 5 {
                            Text("+\(currentEvents.count - 5) more")
                                .font(.system(size: 10))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(AppTheme.Colors.cardBackground)
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.cardBackground)
                .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
        )
    }
    
    private var emptyConversationView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.accent.opacity(0.1),
                                AppTheme.Colors.accent.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(AppTheme.Colors.accent)
                    )
                
                VStack(spacing: 10) {
                    Text("AI Schedule Assistant")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("Tell me how you'd like to update your schedule. I can help you add, remove, move, or modify events.")
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal, 16)
                }
            }
            
            VStack(spacing: 8) {
                Text("Example requests:")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                VStack(spacing: 6) {
                    exampleRequestCard("Add a 30-minute workout at 7 AM")
                    exampleRequestCard("Move my lunch break to 1 PM")
                    exampleRequestCard("Remove the meeting at 3 PM")
                    exampleRequestCard("Add more time for studying")
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    private func exampleRequestCard(_ text: String) -> some View {
        Button {
            message = text
        } label: {
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.Colors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppTheme.Colors.overlay.opacity(0.2), lineWidth: 1)
                        )
                )
        }
    }
    
    private var chatHistoryView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(messages) { message in
                    chatBubble(message)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
    
    private func chatBubble(_ message: Message) -> some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.system(size: 15))
                    .foregroundColor(message.role == .user ? .white : AppTheme.Colors.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(message.role == .user ? AppTheme.Colors.accent : AppTheme.Colors.cardBackground)
                            .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
                    )
                
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.role == .user ? .trailing : .leading)
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }
    
    private var inputSection: some View {
        VStack(spacing: 16) {
            Rectangle()
                .fill(AppTheme.Colors.overlay.opacity(0.1))
                .frame(height: 1)
            
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    TextField("Describe your schedule changes...", text: $message, axis: .vertical)
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(1...4)
                        .disabled(isProcessing || !contentModel.hasCreditsRemaining())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(AppTheme.Colors.cardBackground)
                        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.Colors.overlay.opacity(0.2), lineWidth: 1)
                )
                
                Button {
                    sendMessage()
                } label: {
                    Group {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(
                                message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !contentModel.hasCreditsRemaining() ?
                                AppTheme.Colors.textTertiary : AppTheme.Colors.accent
                            )
                    )
                }
                .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing || !contentModel.hasCreditsRemaining())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(AppTheme.Colors.background)
    }
    
    private func sendMessage() {
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              contentModel.hasCreditsRemaining(),
              !isProcessing else { return }
        
        let userMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add user message to chat
        messages.append(
            Message(
                id: UUID().uuidString,
                role: .user,
                text: userMessage,
                timestamp: Date()
            )
        )
        
        // Clear input
        message = ""
        
        // Start processing
        isProcessing = true
        
        let thinkingMessageId = UUID().uuidString
        messages.append(
            Message(
                id: thinkingMessageId,
                role: .assistant,
                text: "Let me think about this...",
                timestamp: Date(),
                isThinking: true
            )
        )
        
        Task {
            await simulateThinkingProcess(messageId: thinkingMessageId, userRequest: userMessage)
            
            do {
                // Update schedule using ContentModel's AI function
                let updatedEvents = try await contentModel.updateScheduleWithAI(
                    userMessage: userMessage,
                    currentEvents: currentEvents
                )
                
                await MainActor.run {
                    // Remove thinking message
                    messages.removeAll { $0.id == thinkingMessageId }
                    
                    // Update the schedule
                    onScheduleUpdate(updatedEvents)
                    
                    // Add success message to chat
                    messages.append(
                        Message(
                            id: UUID().uuidString,
                            role: .assistant,
                            text: "Perfect! I've updated your schedule based on your request. The changes include \(updatedEvents.count) events. Check your updated schedule above!",
                            timestamp: Date()
                        )
                    )
                    
                    isProcessing = false
                }
                
            } catch {
                await MainActor.run {
                    // Remove thinking message
                    messages.removeAll { $0.id == thinkingMessageId }
                    
                    print("❌ Failed to update schedule: \(error)")
                    isProcessing = false
                    
                    // Add error message to chat
                    let errorMessage = if error.localizedDescription.contains("No credits remaining") {
                        "You've used all your daily AI credits. Credits reset every day at midnight."
                    } else {
                        "Sorry, I encountered an error updating your schedule: \(error.localizedDescription)"
                    }
                    
                    messages.append(
                        Message(
                            id: UUID().uuidString,
                            role: .assistant,
                            text: errorMessage,
                            timestamp: Date()
                        )
                    )
                }
            }
        }
    }
    
    private func simulateThinkingProcess(messageId: String, userRequest: String) async {
        let thinkingSteps = generateThinkingSteps(for: userRequest)
        
        for (index, step) in thinkingSteps.enumerated() {
            await MainActor.run {
                if let messageIndex = messages.firstIndex(where: { $0.id == messageId }) {
                    messages[messageIndex] = Message(
                        id: messageId,
                        role: .assistant,
                        text: step,
                        timestamp: messages[messageIndex].timestamp,
                        isThinking: true
                    )
                }
            }
            
            // Add delay between thinking steps
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
        }
    }
    
    private func generateThinkingSteps(for request: String) -> [String] {
        let lowercaseRequest = request.lowercased()
        
        if lowercaseRequest.contains("move") || lowercaseRequest.contains("push back") || lowercaseRequest.contains("reschedule") {
            return [
                "🤔 Analyzing your current schedule...",
                "🔍 Looking for the event you want to move...",
                "⏰ Calculating the new time slot...",
                "🔄 Checking for any conflicts with other events...",
                "✨ Updating your schedule..."
            ]
        } else if lowercaseRequest.contains("add") || lowercaseRequest.contains("include") {
            return [
                "🤔 Understanding what you want to add...",
                "📅 Finding the best time slot for this activity...",
                "⚖️ Making sure it fits with your existing events...",
                "✨ Adding it to your schedule..."
            ]
        } else if lowercaseRequest.contains("remove") || lowercaseRequest.contains("delete") || lowercaseRequest.contains("cancel") {
            return [
                "🤔 Identifying which event to remove...",
                "🔍 Locating it in your current schedule...",
                "🗑️ Removing the event safely...",
                "✨ Updating your schedule..."
            ]
        } else if lowercaseRequest.contains("extend") || lowercaseRequest.contains("longer") {
            return [
                "🤔 Finding the event you want to extend...",
                "⏰ Calculating the new end time...",
                "🔄 Checking if this affects other events...",
                "✨ Adjusting your schedule..."
            ]
        } else {
            return [
                "🤔 Analyzing your request...",
                "📅 Reviewing your current schedule...",
                "🔄 Planning the changes...",
                "✨ Updating your schedule..."
            ]
        }
    }
}

// MARK: - DateFormatter Extensions
private extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

extension View {
    func keyboardAdaptive() -> some View {
        self.modifier(KeyboardAdaptive())
    }
}

struct KeyboardAdaptive: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                    let keyboardRectangle = keyboardFrame.cgRectValue
                    let keyboardHeight = keyboardRectangle.height
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        // This will cover the example requests but leave header visible
                        self.keyboardHeight = min(keyboardHeight, 200)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.keyboardHeight = 0
                }
            }
            .offset(y: -keyboardHeight)
    }
}
