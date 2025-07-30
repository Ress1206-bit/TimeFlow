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
    @State private var showingEditSchedule = false
    @State private var showCalendarView = false
    @State private var showAllUpcomingEvents = false
    @State private var showingFocusMode = false
    @State private var focusEvent: Event? = nil
    @State private var selectedPieSlice: PieChartSlice? = nil
    @Namespace private var eventCardAnimation
    
    // AI Thinking feature
    @State private var showingThinkingOverlay = false
    @State private var currentThinkingStep = ""
    @State private var thinkingStepIndex = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Subtle background gradient
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
                    
                    if visibleEvents.isEmpty {
                        emptyStateView
                    } else {
                        if showCalendarView {
                            calendarView
                        } else {
                            timelineScheduleView
                        }
                    }
                }
                
                // AI Thinking Overlay
                if showingThinkingOverlay {
                    aiThinkingOverlay
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingNoteSheet) {
            noteInputSheet
        }
        .sheet(isPresented: $showingSettings) {
            AccountView()
        }
        .sheet(isPresented: $showingEditSchedule) {
            EditScheduleView()
        }
        .onAppear {
            loadScheduleData()
            contentModel.checkForBackgroundGenerationOnStartup()
            
            print(events)
            
            if contentModel.loggedIn && contentModel.user == nil {
                Task {
                    do {
                        try await contentModel.fetchUser()
                        await MainActor.run {
                            loadScheduleData()
                        }
                    } catch {
                        print("❌ Failed to fetch user on appear: \(error)")
                    }
                }
            } else if contentModel.loggedIn {
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
            if let newSchedule = newSchedule {
                events = newSchedule.isEmpty ? [] : newSchedule
            } else {
                events = []
            }
        }
    }
    
    // MARK: - AI Thinking Overlay
    private var aiThinkingOverlay: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    // Prevent dismissing while thinking
                }
            
            VStack(spacing: 24) {
                // AI Brain animation
                VStack(spacing: 16) {
                    ZStack {
                        // Pulsing circles
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .stroke(AppTheme.Colors.accent.opacity(0.3), lineWidth: 2)
                                .frame(width: 60 + CGFloat(index * 20), height: 60 + CGFloat(index * 20))
                                .scaleEffect(1.0 + CGFloat(index) * 0.1)
                                .opacity(0.7 - Double(index) * 0.2)
                                .animation(
                                    .easeInOut(duration: 1.5 + Double(index) * 0.3)
                                    .repeatForever(autoreverses: true),
                                    value: showingThinkingOverlay
                                )
                        }
                        
                        // Central brain icon
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppTheme.Colors.accent,
                                        AppTheme.Colors.accent.opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: AppTheme.Colors.accent.opacity(0.3), radius: 12, y: 4)
                    }
                    
                    Text("TimeFlow AI")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                
                // Thinking steps
                VStack(spacing: 16) {
                    Text("Generating your perfect schedule...")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    // Current thinking step
                    HStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(AppTheme.Colors.accent)
                        
                        Text(currentThinkingStep)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.Colors.cardBackground)
                            .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.Colors.accent.opacity(0.2), lineWidth: 1)
                    )
                }
                
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { index in
                        Circle()
                            .fill(index <= thinkingStepIndex ? AppTheme.Colors.accent : AppTheme.Colors.overlay.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: thinkingStepIndex)
                    }
                }
            }
            .padding(.horizontal, 32)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Schedule")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text(Date().formatted(.dateTime.weekday(.wide).day().month(.abbreviated)))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if !visibleEvents.isEmpty {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showCalendarView.toggle()
                            }
                        } label: {
                            Image(systemName: showCalendarView ? "list.bullet" : "calendar")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(AppTheme.Colors.cardBackground)
                                        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                                )
                        }
                        
                        Button {
                            showingEditSchedule = true
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(AppTheme.Colors.cardBackground)
                                        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                                )
                        }
                    }
                    
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textSecondary)
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
            
            // Subtle divider
            Rectangle()
                .fill(AppTheme.Colors.overlay.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, 24)
        }
        .background(AppTheme.Colors.background)
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 40) {
                VStack(spacing: 20) {
                    // More subtle icon presentation
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
                            Image(systemName: "calendar.day.timeline.leading")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(AppTheme.Colors.accent)
                        )
                    
                    VStack(spacing: 12) {
                        Text("No schedule for today")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text("Create an AI-generated schedule based on your goals and commitments")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .padding(.horizontal, 16)
                    }
                }
                
                VStack(spacing: 16) {
                    if !userNote.isEmpty {
                        notePreviewCard
                    }
                    
                    actionButtonsRow
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            TabBarView(selectedTab: $selectedTab)
        }
    }
    
    private var notePreviewCard: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(AppTheme.Colors.accent.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "note.text")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.Colors.accent)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Context Note")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(userNote)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button("Edit") {
                showingNoteSheet = true
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(AppTheme.Colors.accent)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.cardBackground)
                .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.Colors.accent.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var actionButtonsRow: some View {
        HStack(spacing: 12) {
            Button {
                showingNoteSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Add Context")
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
            
            Button {
                generateSchedule()
            } label: {
                HStack(spacing: 8) {
                    if contentModel.isGeneratingSchedule || showingThinkingOverlay {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    
                    Text((contentModel.isGeneratingSchedule || showingThinkingOverlay) ? "Generating..." : "Generate Schedule")
                        .font(.system(size: 15, weight: .semibold))
                }
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
            .disabled(contentModel.isGeneratingSchedule || showingThinkingOverlay)
            .scaleEffect((contentModel.isGeneratingSchedule || showingThinkingOverlay) ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: contentModel.isGeneratingSchedule || showingThinkingOverlay)
        }
    }

    // MARK: - Timeline Schedule View
    private var timelineScheduleView: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 20) {
                    currentEventSection
                    upcomingEventsSection
                    dayOverviewSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
            
            TabBarView(selectedTab: $selectedTab)
        }
    }
    
    // MARK: - Current Event Section
    private var currentEventSection: some View {
        TimelineView(.periodic(from: Date(), by: 1.0)) { context in
            if let currentEvent = getCurrentEvent(at: context.date) {
                VStack(spacing: 12) {
                    HStack {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(currentEvent.color)
                                .frame(width: 6, height: 6)
                            Text("In Progress")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(currentEvent.color)
                        }
                        
                        Spacer()
                        
                        Text(timeRemainingText(for: currentEvent, at: context.date))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(AppTheme.Colors.cardBackground)
                                    .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
                            )
                    }
                    
                    currentEventCard(currentEvent, at: context.date)
                        .transition(.scale.combined(with: .opacity))
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentEvent.id)
            }
        }
    }
    
    private func currentEventCard(_ event: Event, at currentTime: Date) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Icon with refined styling
                RoundedRectangle(cornerRadius: 6)
                    .fill(.white.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: event.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                    )
                    .matchedGeometryEffect(id: "eventIcon", in: eventCardAnimation, isSource: !showingFocusMode)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("\(event.start.formatted(date: .omitted, time: .shortened)) – \(event.end.formatted(date: .omitted, time: .shortened))")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .matchedGeometryEffect(id: "eventTime", in: eventCardAnimation, isSource: !showingFocusMode)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(progressForEvent(event, at: currentTime) * 100))%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .matchedGeometryEffect(id: "eventProgress", in: eventCardAnimation, isSource: !showingFocusMode)
                    
                    Text("Complete")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(event.color.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(event.color.opacity(0.4), lineWidth: 0.5)
                    )
                    .matchedGeometryEffect(id: "eventBackground", in: eventCardAnimation, isSource: !showingFocusMode)
            )
            .onTapGesture {
                focusEvent = event
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showingFocusMode = true
                }
            }
            
            // Progress bar with refined styling
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(.white.opacity(0.9))
                        .frame(width: geometry.size.width * progressForEvent(event, at: currentTime))
                    
                    Rectangle()
                        .fill(.white.opacity(0.2))
                }
            }
            .frame(height: 3)
            .matchedGeometryEffect(id: "eventProgressBar", in: eventCardAnimation, isSource: !showingFocusMode)
        }
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .shadow(color: event.color.opacity(0.3), radius: 12, y: 6)
        .fullScreenCover(isPresented: $showingFocusMode) {
            if let focusEvent = focusEvent {
                FocusModeView(
                    event: focusEvent,
                    isPresented: $showingFocusMode,
                    animationNamespace: eventCardAnimation
                )
                .onDisappear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.focusEvent = nil
                    }
                }
            }
        }
        .onChange(of: getCurrentEvent(at: Date())) { (oldEvent: Event?, newEvent: Event?) in
            if showingFocusMode && focusEvent?.id != newEvent?.id {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showingFocusMode = false
                }
            }
        }
    }

    // MARK: - Upcoming Events Section
    private var upcomingEventsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Upcoming")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                if visibleEvents.count > 3 {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showAllUpcomingEvents.toggle()
                        }
                    } label: {
                        Text(showAllUpcomingEvents ? "Show Less" : "View All (\(visibleEvents.count))")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(AppTheme.Colors.accent.opacity(0.1))
                            )
                    }
                }
            }
            
            LazyVStack(spacing: 8) {
                let eventsToShow = showAllUpcomingEvents ? visibleEvents : Array(visibleEvents.prefix(3))
                ForEach(eventsToShow, id: \.id) { event in
                    upcomingEventCard(event)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.cardBackground)
                .shadow(color: .black.opacity(0.03), radius: 8, y: 4)
        )
    }

    private func upcomingEventCard(_ event: Event) -> some View {
        HStack(spacing: 12) {
            VStack(spacing: 1) {
                Text(event.start.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(event.end.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .frame(width: 60)
            
            Rectangle()
                .fill(event.color)
                .frame(width: 3)
                .frame(maxHeight: .infinity)
            
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(event.color.opacity(0.1))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: event.icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(event.color)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(1)
                    
                    Text(durationText(for: event))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(event.color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(event.color.opacity(0.4), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Day Overview Section
    private var dayOverviewSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Day Overview")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chart.pie")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            
            VStack(spacing: 16) {
                ZStack {
                    pieChartView
                        .frame(width: 160, height: 160)
                    
                    if let selectedSlice = selectedPieSlice {
                        pieSlicePopup(slice: selectedSlice)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                
                pieChartLegendGrid
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.cardBackground)
                .shadow(color: .black.opacity(0.03), radius: 8, y: 4)
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedPieSlice = nil
            }
        }
    }

    // MARK: - Pie Chart View
    private var pieChartView: some View {
        ZStack {
            ForEach(Array(pieChartData.enumerated()), id: \.element.id) { index, slice in
                pieSlice(
                    startAngle: slice.startAngle,
                    endAngle: slice.endAngle,
                    color: slice.color,
                    slice: slice
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPieSlice = selectedPieSlice?.id == slice.id ? nil : slice
                    }
                }
            }
            
            Circle()
                .fill(AppTheme.Colors.cardBackground)
                .frame(width: 70, height: 70)
            
            VStack(spacing: 1) {
                Text(totalTimeText)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("Total")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }

    // MARK: - Pie Slice Popup
    private func pieSlicePopup(slice: PieChartSlice) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Circle()
                    .fill(slice.color)
                    .frame(width: 8, height: 8)
                
                Text(slice.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPieSlice = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
            
            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text(slice.timeText)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("Duration")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                VStack(spacing: 2) {
                    Text("\(Int(slice.percentage))%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(slice.color)
                    
                    Text("of Day")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                VStack(spacing: 2) {
                    Text("\(slice.count)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("Events")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            if !slice.events.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Events:")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    ForEach(slice.events.prefix(3), id: \.id) { event in
                        HStack(spacing: 6) {
                            Image(systemName: event.icon)
                                .font(.system(size: 9))
                                .foregroundColor(slice.color)
                                .frame(width: 12)
                            
                            Text(event.title)
                                .font(.system(size: 10))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text(durationText(for: event))
                                .font(.system(size: 9))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }
                    
                    if slice.events.count > 3 {
                        Text("+ \(slice.events.count - 3) more")
                            .font(.system(size: 9))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .padding(.leading, 18)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.Colors.background)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(slice.color.opacity(0.2), lineWidth: 1)
        )
        .frame(width: 240)
        .offset(y: -35)
    }

    // MARK: - Pie Chart Legend Grid
    private var pieChartLegendGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 2)
        
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(pieChartData.prefix(6), id: \.id) { slice in
                HStack(spacing: 6) {
                    Circle()
                        .fill(slice.color)
                        .frame(width: 8, height: 8)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(slice.label)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .lineLimit(1)
                        
                        Text(slice.timeText)
                            .font(.system(size: 9))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppTheme.Colors.background.opacity(0.5))
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPieSlice = selectedPieSlice?.id == slice.id ? nil : slice
                    }
                }
            }
        }
    }

    // MARK: - Pie Slice Helper Function
    private func pieSlice(startAngle: Angle, endAngle: Angle, color: Color, slice: PieChartSlice) -> some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2
            let isSelected = selectedPieSlice?.id == slice.id
            
            Path { path in
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: startAngle - Angle(degrees: 90),
                    endAngle: endAngle - Angle(degrees: 90),
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(isSelected ? color.opacity(0.8) : color)
            .scaleEffect(isSelected ? 1.03 : 1.0)
            .overlay(
                Path { path in
                    path.move(to: center)
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: startAngle - Angle(degrees: 90),
                        endAngle: endAngle - Angle(degrees: 90),
                        clockwise: false
                    )
                    path.closeSubpath()
                }
                .stroke(Color.white.opacity(0.5), lineWidth: isSelected ? 2 : 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }

    // MARK: - Calendar View (Simplified for brevity - same structure as original)
    private var calendarView: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    currentEventSection
                    simpleCalendarTimelineView
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
            
            TabBarView(selectedTab: $selectedTab)
        }
    }

    private var simpleCalendarTimelineView: some View {
        TimelineView(.periodic(from: Date(), by: 60.0)) { context in
            let currentTime = context.date
            
            VStack(spacing: 16) {
                HStack {
                    Text("Timeline")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    Text(currentTime.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.Colors.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(AppTheme.Colors.accent.opacity(0.1))
                        )
                }
                
                calendarTimelineContent(currentTime: currentTime)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.Colors.cardBackground)
                    .shadow(color: .black.opacity(0.03), radius: 8, y: 4)
            )
        }
    }

    // MARK: - Note Input Sheet
    private var noteInputSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add Context")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("Provide additional context or preferences for your schedule generation.")
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineSpacing(2)
                }
                
                TextEditor(text: $userNote)
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.Colors.cardBackground)
                            .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
                    )
                    .frame(minHeight: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.Colors.overlay.opacity(0.2), lineWidth: 1)
                    )
                
                Spacer()
            }
            .padding(24)
            .background(AppTheme.Colors.background)
            .navigationTitle("Context Note")
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
    
    // MARK: - All remaining functions stay the same
    private var visibleEvents: [Event] {
        let now = Date()
        return events.filter { event in
            event.start > now && !event.title.contains("NGTime")
        }.sorted { $0.start < $1.start }
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
            return "\(totalMinutes)m left"
        } else {
            let hours = totalMinutes / 60
            let remainingMinutes = totalMinutes % 60
            return "\(hours)h \(remainingMinutes)m left"
        }
    }
    
    private func durationText(for event: Event) -> String {
        let roundedMinutes = roundedMinutesForEvent(event)
        return formatMinutesToTimeText(roundedMinutes)
    }
    
    private func progressForEvent(_ event: Event, at currentTime: Date = Date()) -> Double {
        let total = event.end.timeIntervalSince(event.start)
        let elapsed = currentTime.timeIntervalSince(event.start)
        let progress = elapsed / total
        
        return max(0, min(progress, 1))
    }
    
    private func roundedMinutesForEvent(_ event: Event) -> Int {
        let eventMinutes = Int(round(event.end.timeIntervalSince(event.start) / 60))
        // Round to nearest 5 minutes, minimum 5 minutes
        let roundedMinutes = max(5, ((eventMinutes + 2) / 5) * 5)
        return roundedMinutes
    }
    
    private func formatMinutesToTimeText(_ minutes: Int) -> String {
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
    
    // Helper function to calculate total awake minutes
    private func calculateTotalAwakeMinutes() -> Int {
        guard let user = contentModel.user else { return 960 } // Default to 16 hours
        
        let awakeHours = user.todaysAwakeHours ?? user.awakeHours
        let wakeTimeString = awakeHours.wakeTime
        let sleepTimeString = awakeHours.sleepTime
        
        // Parse wake time
        let wakeComponents = wakeTimeString.split(separator: ":").compactMap { Int($0) }
        guard wakeComponents.count == 2 else { return 960 }
        let wakeMinutes = wakeComponents[0] * 60 + wakeComponents[1]
        
        // Parse sleep time
        let sleepComponents = sleepTimeString.split(separator: ":").compactMap { Int($0) }
        guard sleepComponents.count == 2 else { return 960 }
        let sleepMinutes = sleepComponents[0] * 60 + sleepComponents[1]
        
        // Calculate total awake minutes
        if sleepMinutes > wakeMinutes {
            // Same day (e.g., wake at 7:00, sleep at 23:00)
            return sleepMinutes - wakeMinutes
        } else {
            // Sleep time is next day (e.g., wake at 7:00, sleep at 1:00)
            return (24 * 60) - wakeMinutes + sleepMinutes
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
    
    // MARK: - AI Thinking Functions
    private func generateThinkingStepsForScheduleGeneration() -> [String] {
        guard let user = contentModel.user else {
            return [
                "🤔 Preparing to create your schedule...",
                "📋 Setting up the planning framework...",
                "⏰ Analyzing your time preferences...",
                "✨ Finalizing your schedule..."
            ]
        }
        
        let hasGoals = !user.goals.filter { $0.isActive }.isEmpty
        let hasAssignments = !user.assignments.filter { !$0.completed }.isEmpty
        let hasTests = !user.tests.filter { !$0.prepared }.isEmpty
        let hasCommitments = !user.recurringCommitments.isEmpty
        
        var steps: [String] = []
        
        // Step 1: Always analyze user data
        steps.append("🤔 Analyzing your goals, commitments, and preferences...")
        
        // Step 2: Time analysis
        if hasCommitments {
            steps.append("📅 Reviewing your recurring commitments and time blocks...")
        } else {
            steps.append("⏰ Analyzing your available time windows...")
        }
        
        // Step 3: Priority setting
        if hasAssignments || hasTests {
            steps.append("📚 Prioritizing assignments and test preparation...")
        } else if hasGoals {
            steps.append("🎯 Planning your goal activities and personal time...")
        } else {
            steps.append("⚖️ Balancing your schedule for optimal productivity...")
        }
        
        // Step 4: Schedule building
        steps.append("🏗️ Building your personalized schedule structure...")
        
        // Step 5: Final optimization
        steps.append("✨ Finalizing and optimizing your perfect day...")
        
        return steps
    }
    
    private func simulateThinkingProcess() async {
        let thinkingSteps = generateThinkingStepsForScheduleGeneration()
        
        await MainActor.run {
            showingThinkingOverlay = true
            thinkingStepIndex = 0
            currentThinkingStep = thinkingSteps.first ?? "Preparing your schedule..."
        }
        
        for (index, step) in thinkingSteps.enumerated() {
            await MainActor.run {
                currentThinkingStep = step
                thinkingStepIndex = index
            }
            
            // Add random delay between thinking steps (1.0 to 5.0 seconds)
            let randomDelay = Double.random(in: 1.0...5.0)
            let nanoseconds = UInt64(randomDelay * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
        }
    }

    // MARK: - Pie Chart Data Structure
    private struct PieChartSlice: Identifiable {
        let id = UUID()
        let label: String
        let count: Int
        let totalMinutes: Int
        let timeText: String
        let percentage: Double
        let color: Color
        let startAngle: Angle
        let endAngle: Angle
        let events: [Event]
    }

    // MARK: - Pie Chart Data Computation
    private var pieChartData: [PieChartSlice] {
        let eventsByType = Dictionary(grouping: allDayEvents) { $0.eventType }
        let scheduledMinutes = allDayEvents.reduce(0) { total, event in
            return total + roundedMinutesForEvent(event)
        }
        
        // Calculate total awake minutes and unscheduled time
        let totalAwakeMinutes = calculateTotalAwakeMinutes()
        let unscheduledMinutes = max(0, totalAwakeMinutes - scheduledMinutes)
        let totalMinutes = scheduledMinutes + unscheduledMinutes
        
        guard totalMinutes > 0 else { return [] }
        
        var currentAngle: Double = 0
        var slices: [PieChartSlice] = []
        
        let sortedTypes = eventsByType.sorted { 
            let time1 = $0.value.reduce(0) { total, event in
                return total + roundedMinutesForEvent(event)
            }
            let time2 = $1.value.reduce(0) { total, event in
                return total + roundedMinutesForEvent(event)
            }
            return time1 > time2
        }
        
        // Add slices for scheduled events
        for (eventType, events) in sortedTypes {
            let typeMinutes = events.reduce(0) { total, event in
                return total + roundedMinutesForEvent(event)
            }
            
            let percentage = (Double(typeMinutes) / Double(totalMinutes)) * 100
            let angleSize = (Double(typeMinutes) / Double(totalMinutes)) * 360
            
            let timeText = formatMinutesToTimeText(typeMinutes)
            let cleanLabel = eventType == .recurringCommitment ? "Commitment" : eventType.rawValue
            
            let slice = PieChartSlice(
                label: cleanLabel,
                count: events.count,
                totalMinutes: typeMinutes,
                timeText: timeText,
                percentage: percentage,
                color: eventTypeColor(eventType),
                startAngle: Angle(degrees: currentAngle),
                endAngle: Angle(degrees: currentAngle + angleSize),
                events: events
            )
            
            slices.append(slice)
            currentAngle += angleSize
        }
        
        // Add unscheduled time slice if there's any
        if unscheduledMinutes > 0 {
            let percentage = (Double(unscheduledMinutes) / Double(totalMinutes)) * 100
            let angleSize = (Double(unscheduledMinutes) / Double(totalMinutes)) * 360
            
            let timeText = formatMinutesToTimeText(unscheduledMinutes)
            
            let unscheduledSlice = PieChartSlice(
                label: "Unscheduled",
                count: 0,
                totalMinutes: unscheduledMinutes,
                timeText: timeText,
                percentage: percentage,
                color: AppTheme.Colors.textTertiary.opacity(0.6),
                startAngle: Angle(degrees: currentAngle),
                endAngle: Angle(degrees: currentAngle + angleSize),
                events: []
            )
            
            slices.append(unscheduledSlice)
        }
        
        return slices
    }

    private var totalTimeText: String {
        let totalMinutes = calculateTotalAwakeMinutes()
        return formatMinutesToTimeText(totalMinutes)
    }
    
    private var allDayEvents: [Event] {
        return events.filter { !$0.title.contains("NGTime") }
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
    
    // MARK: - Calendar Timeline Content (Same structure, simplified for brevity)
    private func calendarTimelineContent(currentTime: Date) -> some View {
        let timeColumnWidth: CGFloat = 70
        let hourHeight: CGFloat = 80
        
        let userScheduleBounds = getUserScheduleBounds()
        let startHour = userScheduleBounds.startHour
        let endHour = userScheduleBounds.endHour
        let totalHours = endHour - startHour
        
        return GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let eventAreaWidth = totalWidth - timeColumnWidth - 16
            
            ScrollView(showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    VStack(spacing: 0) {
                        ForEach(startHour..<endHour, id: \.self) { hour in
                            calendarHourRow(
                                hour: hour,
                                currentTime: currentTime,
                                timeColumnWidth: timeColumnWidth,
                                eventAreaWidth: eventAreaWidth,
                                hourHeight: hourHeight
                            )
                        }
                    }
                    
                    ForEach(allCalendarEvents, id: \.id) { event in
                        calendarEventBlock(
                            event: event,
                            currentTime: currentTime,
                            timeColumnWidth: timeColumnWidth,
                            eventAreaWidth: eventAreaWidth,
                            hourHeight: hourHeight,
                            startHour: startHour
                        )
                    }
                }
            }
        }
        .frame(height: CGFloat(totalHours) * hourHeight)
    }

    private func getUserScheduleBounds() -> (startHour: Int, endHour: Int) {
        guard let user = contentModel.user else {
            return (startHour: 6, endHour: 24)
        }
        
        let awakeHours = user.todaysAwakeHours ?? user.awakeHours
        let wakeTimeString = awakeHours.wakeTime
        let components = wakeTimeString.split(separator: ":").compactMap { Int($0) }
        let wakeHour = components.first ?? 7
        
        let sleepTimeString = awakeHours.sleepTime
        let sleepComponents = sleepTimeString.split(separator: ":").compactMap { Int($0) }
        let sleepHour = sleepComponents.first ?? 23
        
        let startHour = max(0, wakeHour - 1)
        let endHour = sleepHour < 12 ? sleepHour + 25 : sleepHour + 2
        
        return (startHour: startHour, endHour: endHour)
    }

    private func calendarHourRow(
        hour: Int,
        currentTime: Date,
        timeColumnWidth: CGFloat,
        eventAreaWidth: CGFloat,
        hourHeight: CGFloat
    ) -> some View {
        let displayHour = hour >= 24 ? hour - 24 : hour
        let hourDate = Calendar.current.date(bySettingHour: displayHour, minute: 0, second: 0, of: currentTime) ?? currentTime
        
        return HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(hourDate.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            .frame(width: timeColumnWidth, alignment: .leading)
            
            VStack(spacing: 0) {
                Rectangle()
                    .fill(AppTheme.Colors.overlay.opacity(0.2))
                    .frame(height: 1)
                
                Spacer()
                    .frame(height: hourHeight / 2 - 1)
                
                Rectangle()
                    .fill(AppTheme.Colors.overlay.opacity(0.1))
                    .frame(height: 1)
                
                Spacer()
                    .frame(height: hourHeight / 2 - 1)
            }
            .frame(width: eventAreaWidth, height: hourHeight)
        }
        .frame(height: hourHeight)
    }

    private func calendarEventBlock(
        event: Event,
        currentTime: Date,
        timeColumnWidth: CGFloat,
        eventAreaWidth: CGFloat,
        hourHeight: CGFloat,
        startHour: Int
    ) -> some View {
        let position = calculateEventPosition(
            event: event,
            hourHeight: hourHeight,
            startHour: startHour
        )
        
        let isActive = currentTime >= event.start && currentTime <= event.end
        let isPast = currentTime > event.end
        let isSpecialEvent = event.title == "Wake Up" || event.title == "Bedtime"
        
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(event.color.opacity(0.1))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: event.icon)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(event.color)
                    )
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(event.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(2)
                    
                    Text("\(event.start.formatted(date: .omitted, time: .shortened)) – \(event.end.formatted(date: .omitted, time: .shortened))")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                
                Spacer()
            }
            
            if position.height > 50 {
                Spacer()
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(width: eventAreaWidth - 8, height: position.height)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(event.color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(
                            event.color.opacity(isActive ? 0.8 : 0.4),
                            style: isSpecialEvent ? StrokeStyle(lineWidth: isActive ? 2 : 1, dash: [3, 2]) : StrokeStyle(lineWidth: isActive ? 2 : 1)
                        )
                )
        )
        .opacity(isPast ? 0.6 : 1.0)
        .offset(
            x: timeColumnWidth + 16,
            y: position.yOffset
        )
    }

    private func calculateEventPosition(
        event: Event,
        hourHeight: CGFloat,
        startHour: Int
    ) -> (yOffset: CGFloat, height: CGFloat) {
        let calendar = Calendar.current
        
        let startHour24 = calendar.component(.hour, from: event.start)
        let startMinute = calendar.component(.minute, from: event.start)
        let endHour24 = calendar.component(.hour, from: event.end)
        let endMinute = calendar.component(.minute, from: event.end)
        
        let startHourPosition = startHour24 >= startHour ? startHour24 - startHour : (24 - startHour) + startHour24
        let endHourPosition = endHour24 >= startHour ? endHour24 - startHour : (24 - startHour) + endHour24
        
        let startTotalMinutes = startHourPosition * 60 + startMinute
        let endTotalMinutes = endHourPosition * 60 + endMinute
        
        let minutesPerPixel = hourHeight / 60.0
        let yOffset = CGFloat(startTotalMinutes) * minutesPerPixel
        let height = max(CGFloat(endTotalMinutes - startTotalMinutes) * minutesPerPixel, 36.0)
        
        return (yOffset: yOffset, height: height)
    }

    private var allCalendarEvents: [Event] {
        var allEvents = events.filter { !$0.title.contains("NGTime") }
        
        if let user = contentModel.user {
            if let wakeUpEvent = createWakeUpEvent(for: user) {
                allEvents.append(wakeUpEvent)
            }
            
            if let bedsideEvent = createBedtimeEvent(for: user) {
                allEvents.append(bedsideEvent)
            }
        }
        
        return allEvents.sorted { $0.start < $1.start }
    }

    private func createWakeUpEvent(for user: User) -> Event? {
        let calendar = Calendar.current
        let today = Date()
        
        let awakeHours = user.todaysAwakeHours ?? user.awakeHours
        let wakeTimeString = awakeHours.wakeTime
        
        let components = wakeTimeString.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return nil }
        
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: today)
        dateComponents.hour = components[0]
        dateComponents.minute = components[1]
        
        guard let wakeTime = calendar.date(from: dateComponents) else { return nil }
        let wakeEndTime = calendar.date(byAdding: .minute, value: 15, to: wakeTime) ?? wakeTime
        
        return Event(
            id: UUID(),
            start: wakeTime,
            end: wakeEndTime,
            title: "Wake Up",
            icon: "sun.max.fill",
            eventType: .other,
            colorName: "yellow"
        )
    }
    
    private func createBedtimeEvent(for user: User) -> Event? {
        let calendar = Calendar.current
        let today = Date()
        
        let awakeHours = user.todaysAwakeHours ?? user.awakeHours
        let sleepTimeString = awakeHours.sleepTime
        
        let components = sleepTimeString.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return nil }
        
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: today)
        dateComponents.hour = components[0]
        dateComponents.minute = components[1]
        
        guard let bedTime = calendar.date(from: dateComponents) else { return nil }
        let bedStartTime = calendar.date(byAdding: .minute, value: -5, to: bedTime) ?? bedTime
        let bedEndTime = calendar.date(byAdding: .minute, value: 10, to: bedTime) ?? bedTime
        
        return Event(
            id: UUID(),
            start: bedStartTime,
            end: bedEndTime,
            title: "Bedtime",
            icon: "moon.fill",
            eventType: .other,
            colorName: "purple"
        )
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
            // Start thinking process
            await simulateThinkingProcess()
            
            do {
                let responseEvents = try await contentModel.generateScheduleWithBackgroundSupport(userNote: userNote)
                
                await MainActor.run {
                    showingThinkingOverlay = false
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
                    showingThinkingOverlay = false
                    print("❌ Schedule generation failed: \(error)")
                }
            }
        }
    }
}