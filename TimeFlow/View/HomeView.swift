//
//  HomeView.swift
//  TimeFlow
//
//  Created by Adam Ress on 7/21/25.
//

import SwiftUI

struct HomeView: View {
    @Environment(ContentModel.self) var contentModel
    @Binding var selectedTab: Int
    
    @State var events: [Event] = []
    @State private var userNote: String = ""
    @State private var showingNoteSheet = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                
                if visibleEvents.isEmpty {
                    emptyStateView
                } else {
                    scheduleView
                }
            }
            .toolbar(content: {
                leadingToolbarContent
                trailingToolbarContent
            })
        }
        .sheet(isPresented: $showingNoteSheet) {
            noteInputSheet
        }
        .sheet(isPresented: $showingSettings) {
            AccountView()
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadScheduleData()
            
            // Check for background generation when view appears
            contentModel.checkForBackgroundGenerationOnStartup()
            
            // Always refresh from Firebase when view appears
            if contentModel.loggedIn && contentModel.user == nil {
                Task {
                    do {
                        try await contentModel.fetchUser()
                        await MainActor.run {
                            loadScheduleData() // Reload after user fetch
                        }
                    } catch {
                        print("❌ Failed to fetch user on appear: \(error)")
                    }
                }
            } else if contentModel.loggedIn {
                // Force refresh user data from Firebase when view appears
                Task {
                    do {
                        try await contentModel.refreshUserData()
                        await MainActor.run {
                            loadScheduleData()
                        }
                    } catch {
                        print("❌ Failed to refresh user data: \(error)")
                    }
                }
            }
        }
        .onChange(of: contentModel.user?.currentSchedule) { oldSchedule, newSchedule in
            // Handle the new schedule - explicitly check for empty or nil
            if let newSchedule = newSchedule {
                if newSchedule.isEmpty {
                    events = []
                } else {
                    events = newSchedule
                }
            } else {
                events = []
            }
        }
    }
    
    private var leadingToolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Schedule")
                    .font(AppTheme.Typography.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(Date().formatted(date: .abbreviated, time: .omitted))
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding(.top, 20)
            .padding(.bottom, 20)
        }
    }
    
    private var trailingToolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding(10)
                    .background(AppTheme.Colors.cardBackground)
                    .clipShape(Circle())
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 40) {
                VStack(spacing: 20) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 72, weight: .ultraLight))
                        .foregroundColor(AppTheme.Colors.accent)
                    
                    VStack(spacing: 12) {
                        Text("Ready to optimize your day?")
                            .font(AppTheme.Typography.title)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text("AI will create a personalized schedule based on your goals, assignments, and commitments")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                    }
                }
                
                VStack(spacing: 16) {
                    if !userNote.isEmpty {
                        HStack(spacing: 12) {
                            Image(systemName: "note.text.badge.plus")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.Colors.accent)
                            
                            Text(userNote)
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .lineLimit(2)
                            
                            Spacer()
                            
                            Button("Edit") {
                                showingNoteSheet = true
                            }
                            .font(AppTheme.Typography.caption)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.Colors.accent)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(AppTheme.Colors.cardBackground)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppTheme.Colors.accent.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    HStack(spacing: 12) {
                        Button {
                            showingNoteSheet = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Add Note")
                                    .font(AppTheme.Typography.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(AppTheme.Colors.cardBackground)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.Colors.overlay, lineWidth: 1)
                            )
                        }

                        
                        Button {
                            generateSchedule()
                        } label: {
                            HStack(spacing: 12) {
                                if contentModel.isGeneratingSchedule {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                
                                Text(contentModel.isGeneratingSchedule ? "Generating..." : "Generate Schedule")
                                    .font(AppTheme.Typography.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [AppTheme.Colors.accent, AppTheme.Colors.accent.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: AppTheme.Colors.accent.opacity(0.3), radius: 8, y: 4)
                        }
                        .disabled(contentModel.isGeneratingSchedule)
                        .scaleEffect(contentModel.isGeneratingSchedule ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: contentModel.isGeneratingSchedule)
                    }
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            TabBarView(selectedTab: $selectedTab)
        }
    }
    
    // MARK: - Schedule View
    private var scheduleView: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 20) {
                    currentTimelineSection
                    todayTimelineSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            
            TabBarView(selectedTab: $selectedTab)
        }
    }
    
    // MARK: - Today Timeline Section
    private var todayTimelineSection: some View {
        TimelineView(.periodic(from: Date(), by: 30.0)) { context in
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Remaining Today")
                        .font(AppTheme.Typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(visibleEvents.count) events left")
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                
                timelineView(at: context.date)
            }
            .padding(24)
            .themeCard()
        }
    }
    
    private func timelineView(at currentTime: Date) -> some View {
        let remainingEvents = visibleEvents.sorted { $0.start < $1.start }
        
        return Group {
            if remainingEvents.isEmpty {
                emptyTimelineView
            } else {
                eventsList(remainingEvents, at: currentTime)
            }
        }
    }
    
    private var emptyTimelineView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(AppTheme.Colors.textTertiary.opacity(0.6))
            
            VStack(spacing: 4) {
                Text("All done for today!")
                    .font(AppTheme.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("No more events scheduled")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private func eventsList(_ remainingEvents: [Event], at currentTime: Date) -> some View {
        VStack(spacing: 16) {
            ForEach(remainingEvents, id: \.id) { event in
                timelineEventBlock(event, at: currentTime)
            }
        }
    }
    
    // MARK: - Current Timeline Section
    private var currentTimelineSection: some View {
        TimelineView(.periodic(from: Date(), by: 1.0)) { context in
            if let currentEvent = getCurrentEvent(at: context.date) {
                VStack(spacing: 16) {
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(AppTheme.Colors.accent)
                                .frame(width: 8, height: 8)
                            Text("In Progress")
                                .font(AppTheme.Typography.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.Colors.accent)
                        }
                        
                        Spacer()
                        
                        Text(timeRemainingText(for: currentEvent, at: context.date))
                            .font(AppTheme.Typography.caption)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    
                    currentEventBlock(currentEvent, at: context.date)
                        .transition(.scale.combined(with: .opacity))
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentEvent.id)
                .padding(.top, 25)
            }
        }
    }
    
    private func currentEventBlock(_ event: Event, at currentTime: Date) -> some View {
        VStack(spacing: 0) {
            // Event content
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(event.title)
                            .font(AppTheme.Typography.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        Text("\(event.start.formatted(date: .omitted, time: .shortened)) - \(event.end.formatted(date: .omitted, time: .shortened))")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(progressForEvent(event, at: currentTime) * 100))%")
                            .font(AppTheme.Typography.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Complete")
                            .font(AppTheme.Typography.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding(24)
            .background(
                LinearGradient(
                    colors: [AppTheme.Colors.accent, AppTheme.Colors.accent.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            // Progress bar
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(.white)
                        .frame(width: geometry.size.width * progressForEvent(event, at: currentTime))
                    
                    Rectangle()
                        .fill(.white.opacity(0.3))
                }
            }
            .frame(height: 4)
        }
        .cornerRadius(20)
        .shadow(color: AppTheme.Colors.accent.opacity(0.3), radius: 12, y: 6)
    }
    
    // MARK: - Timeline Event Block
    
    private func timelineEventBlock(_ event: Event, at currentTime: Date) -> some View {
        let isActive = currentTime >= event.start && currentTime <= event.end
        let isPast = currentTime > event.end
        let duration = event.end.timeIntervalSince(event.start) / 60 // in minutes
        let blockHeight = max(60, duration * 0.8) // Minimum 60pt, scale by duration
        let remainingEvents = visibleEvents.sorted { $0.start < $1.start }
        
        return HStack(spacing: 16) {
            // Time indicator
            VStack(spacing: 4) {
                Text(event.start.formatted(date: .omitted, time: .shortened))
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isActive ? AppTheme.Colors.accent : AppTheme.Colors.textTertiary)
                
                Circle()
                    .fill(isActive ? AppTheme.Colors.accent : (isPast ? AppTheme.Colors.textTertiary.opacity(0.3) : AppTheme.Colors.textTertiary.opacity(0.6)))
                    .frame(width: 8, height: 8)
                
                if event != remainingEvents.last {
                    Rectangle()
                        .fill(AppTheme.Colors.overlay)
                        .frame(width: 2, height: max(20, blockHeight - 40))
                }
            }
            .frame(width: 50)
            
            // Event block
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(AppTheme.Typography.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(isActive ? .white : (isPast ? AppTheme.Colors.textSecondary : AppTheme.Colors.textPrimary))
                        
                        Text(durationText(for: event))
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(isActive ? .white.opacity(0.8) : AppTheme.Colors.textTertiary)
                    }
                    
                    Spacer()
                    
                    if isActive {
                        VStack(spacing: 2) {
                            Circle()
                                .fill(.white)
                                .frame(width: 6, height: 6)
                            Text("LIVE")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.white)
                        }
                    } else if isPast {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.Colors.textTertiary.opacity(0.6))
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(minHeight: blockHeight)
            .background(
                Group {
                    if isActive {
                        LinearGradient(
                            colors: [AppTheme.Colors.accent, AppTheme.Colors.accent.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else if isPast {
                        AppTheme.Colors.cardBackground.opacity(0.5)
                    } else {
                        AppTheme.Colors.cardBackground
                    }
                }
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isActive ? AppTheme.Colors.accent.opacity(0.3) : AppTheme.Colors.overlay,
                        lineWidth: isActive ? 2 : 1
                    )
            )
            .scaleEffect(isActive ? 1.02 : (isPast ? 0.98 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isActive)
        }
    }
    
    // MARK: - Note Input Sheet
    private var noteInputSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add context for the AI")
                        .font(AppTheme.Typography.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("Share any preferences, constraints, or special considerations for today's schedule.")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                TextEditor(text: $userNote)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .background(AppTheme.Colors.cardBackground)
                    .cornerRadius(16)
                    .frame(minHeight: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.Colors.overlay, lineWidth: 1)
                    )
                
                Spacer()
            }
            .padding(24)
            .background(AppTheme.Colors.background)
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingNoteSheet = false
                    }
                    .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        showingNoteSheet = false
                    }
                    .foregroundColor(AppTheme.Colors.accent)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private var visibleEvents: [Event] {
        let now = Date()
        return events.filter { event in
            event.start > now && !event.title.contains("NGTime")
        }
    }
    
    private func getCurrentEvent(at time: Date = Date()) -> Event? {
        return events.first { event in
            time >= event.start && time <= event.end && !event.title.contains("NGTime")
        }
    }
    
    private func timeRemainingText(for event: Event, at currentTime: Date = Date()) -> String {
        let remaining = event.end.timeIntervalSince(currentTime)
        let totalMinutes = Int(ceil(remaining / 60))
        
        if totalMinutes <= 0 {
            return "Ending soon"
        } else if totalMinutes < 60 {
            return "\(totalMinutes)m remaining"
        } else {
            let hours = totalMinutes / 60
            let remainingMinutes = totalMinutes % 60
            return "\(hours)h \(remainingMinutes)m remaining"
        }
    }
    
    private func progressForEvent(_ event: Event, at currentTime: Date = Date()) -> Double {
        let total = event.end.timeIntervalSince(event.start)
        let elapsed = currentTime.timeIntervalSince(event.start)
        let progress = elapsed / total
        
        return max(0, min(progress, 1))
    }
    
    private func durationText(for event: Event) -> String {
        let duration = event.end.timeIntervalSince(event.start)
        let minutes = Int(duration / 60)
        
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return remainingMinutes > 0 ? "\(hours)h \(remainingMinutes)m" : "\(hours)h"
        }
    }
    
    private func loadScheduleData() {
        if let user = contentModel.user {
            events = user.currentSchedule
            return
        }
        
        if let completedEvents = contentModel.checkForCompletedSchedule(), !completedEvents.isEmpty {
            events = completedEvents
            return
        }
        
        events = []
    }
    
    private func generateSchedule() {
        guard contentModel.user != nil else {
            if contentModel.loggedIn {
                Task {
                    do {
                        try await contentModel.fetchUser()
                        await MainActor.run {
                            if contentModel.user != nil {
                                generateSchedule()
                            }
                        }
                    } catch {
                        print("❌ Failed to fetch user: \(error)")
                    }
                }
            }
            return
        }
        
        Task {
            do {
                let responseEvents = try await contentModel.generateScheduleWithBackgroundSupport(userNote: userNote)
                
                await MainActor.run {
                    events = responseEvents
                    contentModel.user?.currentSchedule = responseEvents
                    Task {
                        do {
                            try await contentModel.saveUserInfo()
                        } catch {
                            print("❌ Failed to save to Firebase: \(error)")
                        }
                    }
                }
            
            } catch {
                await MainActor.run {
                    print("❌ Schedule generation failed: \(error)")
                }
            }
        }
    }
}