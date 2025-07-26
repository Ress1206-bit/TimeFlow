//
//  AnalyticsView.swift
//  TimeFlow
//
//  Created by Adam Ress on 5/29/25.
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    @Environment(ContentModel.self) private var contentModel
    @Binding var selectedTab: Int
    
    @State private var selectedTimeframe: TimeframeFilter = .week
    @State private var selectedCategory: AnalyticsCategory = .overview
    @State private var animateContent = false
    
    private var userHistory: UserHistory {
        contentModel.userHistory ?? UserHistory()
    }
    
    private var recentDailyLogs: [DailyInfo] {
        let days = selectedTimeframe.days
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return userHistory.dailyLogs
            .filter { $0.date >= cutoffDate }
            .sorted { $0.date < $1.date }
    }
    
    var body: some View {
        ZStack {
            // Professional dark background
            LinearGradient(
                colors: [
                    AppTheme.Colors.background,
                    AppTheme.Colors.secondary.opacity(0.2),
                    AppTheme.Colors.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            NavigationStack {
                ScrollView {
                    VStack(spacing: 28) {
                        // Header with filters
                        headerSection
                        
                        // Category selector
                        categorySelector
                        
                        // Main content based on selected category
                        switch selectedCategory {
                        case .overview:
                            overviewSection
                        case .goals:
                            goalsSection
                        case .productivity:
                            productivitySection
                        case .schedule:
                            scheduleSection
                        }
                        
                        Spacer(minLength: 100) // Space for tab bar
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
                .opacity(animateContent ? 1.0 : 0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.easeOut(duration: 0.8), value: animateContent)
                .navigationTitle("Analytics")
                .navigationBarTitleDisplayMode(.automatic)
                .preferredColorScheme(.dark)
            }
            // Place tab bar at bottom
            VStack {
                Spacer()
                TabBarView(selectedTab: $selectedTab)
            }
        }
        .onAppear {
            withAnimation {
                animateContent = true
            }
        }
    }
}

// MARK: - Header Section
private extension AnalyticsView {
    
    var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Insights")
                        .font(.title2.weight(.bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text(timeframeSubtitle)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
            }
            
            // Timeframe filter
            timeframeFilter
        }
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateContent)
    }
    
    private var timeframeSubtitle: String {
        let dayCount = recentDailyLogs.count
        return "\(dayCount) days of data"
    }
    
    private var timeframeFilter: some View {
        HStack(spacing: 8) {
            ForEach(TimeframeFilter.allCases) { timeframe in
                Button(action: { selectedTimeframe = timeframe }) {
                    Text(timeframe.rawValue)
                        .font(.caption.weight(.medium))
                        .foregroundColor(selectedTimeframe == timeframe ? .white : AppTheme.Colors.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTimeframe == timeframe ? AppTheme.Colors.primary : Color.clear)
                        )
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Category Selector
private extension AnalyticsView {
    
    var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(AnalyticsCategory.allCases) { category in
                    CategoryTab(
                        category: category,
                        isSelected: selectedCategory == category,
                        onTap: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.horizontal, -24)
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
    }
}

// MARK: - Overview Section
private extension AnalyticsView {
    
    var overviewSection: some View {
        VStack(spacing: 24) {
            // Key metrics
            keyMetricsGrid
            
            // Activity breakdown chart
            if !recentDailyLogs.isEmpty {
                activityBreakdownChart
            }
            
            // Recent trends
            recentTrendsSection
        }
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateContent)
    }
    
    private var keyMetricsGrid: some View {
        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 2), spacing: 16) {
            MetricCard(
                title: "Total Events",
                value: "\(totalEventsCount)",
                subtitle: "across all days",
                icon: "calendar",
                color: AppTheme.Colors.primary
            )
            
            MetricCard(
                title: "Avg Events/Day",
                value: String(format: "%.1f", averageEventsPerDay),
                subtitle: "daily average",
                icon: "chart.line.uptrend.xyaxis",
                color: AppTheme.Colors.secondary
            )
            
            MetricCard(
                title: "Most Productive",
                value: mostProductiveDay,
                subtitle: "day of week",
                icon: "star.fill",
                color: Color.orange
            )
            
            MetricCard(
                title: "Schedule Score",
                value: "\(Int(scheduleScore * 100))%",
                subtitle: "efficiency rating",
                icon: "speedometer",
                color: Color.green
            )
        }
    }
    
    private var activityBreakdownChart: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Activity Breakdown")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Text("Past \(selectedTimeframe.rawValue)")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(activityBreakdownData, id: \.type) { data in
                        SectorMark(
                            angle: .value("Count", data.count),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(data.color)
                        .opacity(0.8)
                    }
                }
                .frame(height: 200)
            } else {
                // Fallback for iOS < 16
                VStack(spacing: 8) {
                    ForEach(activityBreakdownData, id: \.type) { data in
                        HStack {
                            Circle()
                                .fill(data.color)
                                .frame(width: 12, height: 12)
                            
                            Text(data.type.rawValue)
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            Spacer()
                            
                            Text("\(data.count)")
                                .font(.caption.weight(.medium))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.cardBackground.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.Colors.overlay.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
    
    private var recentTrendsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Recent Trends")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                TrendCard(
                    title: "Daily Activity",
                    trend: dailyActivityTrend,
                    description: dailyActivityDescription
                )
                
                TrendCard(
                    title: "Sleep Consistency",
                    trend: sleepConsistencyTrend,
                    description: sleepConsistencyDescription
                )
                
                TrendCard(
                    title: "Goal Progress",
                    trend: goalProgressTrend,
                    description: goalProgressDescription
                )
            }
        }
    }
}

// MARK: - Goals Section
private extension AnalyticsView {
    
    var goalsSection: some View {
        VStack(spacing: 24) {
            if let currentGoals = contentModel.user?.goals, !currentGoals.isEmpty {
                goalPerformanceChart
                goalCompletionStats
                goalTrendsSection
            } else {
                emptyGoalsAnalytics
            }
        }
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateContent)
    }
    
    private var goalPerformanceChart: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Goal Performance")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
            }
            
            if #available(iOS 16.0, *), let goals = contentModel.user?.goals {
                Chart {
                    ForEach(goals.filter { $0.isActive }) { goal in
                        BarMark(
                            x: .value("Goal", goal.title),
                            y: .value("Completions", goal.totalCompletionsAllTime)
                        )
                        .foregroundStyle(goal.color)
                        .opacity(0.8)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }
            } else {
                // Fallback for iOS < 16
                VStack(spacing: 8) {
                    if let goals = contentModel.user?.goals {
                        ForEach(goals.filter { $0.isActive }) { goal in
                            HStack {
                                Circle()
                                    .fill(goal.color)
                                    .frame(width: 12, height: 12)
                                
                                Text(goal.title)
                                    .font(.caption)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                
                                Spacer()
                                
                                Text("\(goal.totalCompletionsAllTime)")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.cardBackground.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.Colors.overlay.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
    
    private var goalCompletionStats: some View {
        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 2), spacing: 16) {
            MetricCard(
                title: "Active Goals",
                value: "\(contentModel.user?.goals.filter { $0.isActive }.count ?? 0)",
                subtitle: "currently tracking",
                icon: "target",
                color: AppTheme.Colors.primary
            )
            
            MetricCard(
                title: "Total Hours",
                value: "\(totalGoalHours)h",
                subtitle: "time invested",
                icon: "clock.fill",
                color: Color.blue
            )
            
            MetricCard(
                title: "Best Streak",
                value: "\(bestGoalStreak) days",
                subtitle: "longest consistency",
                icon: "flame.fill",
                color: Color.orange
            )
            
            MetricCard(
                title: "This Week",
                value: "\(thisWeekGoalProgress)%",
                subtitle: "completion rate",
                icon: "chart.bar.fill",
                color: Color.green
            )
        }
    }
    
    private var goalTrendsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Goal Insights")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                InsightCard(
                    icon: "star.fill",
                    title: "Top Performer",
                    description: topPerformingGoal,
                    color: Color.yellow
                )
                
                InsightCard(
                    icon: "clock.arrow.circlepath",
                    title: "Consistency Pattern",
                    description: consistencyPattern,
                    color: AppTheme.Colors.primary
                )
                
                InsightCard(
                    icon: "lightbulb.fill",
                    title: "Recommendation",
                    description: goalRecommendation,
                    color: Color.purple
                )
            }
        }
    }
    
    private var emptyGoalsAnalytics: some View {
        VStack(spacing: 20) {
            Circle()
                .fill(AppTheme.Colors.primary.opacity(0.15))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "chart.bar")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(AppTheme.Colors.primary)
                )
            
            VStack(spacing: 8) {
                Text("No Goal Data")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("Start tracking goals to see detailed analytics and insights about your progress.")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.Colors.cardBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.Colors.overlay.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Productivity Section
private extension AnalyticsView {
    
    var productivitySection: some View {
        VStack(spacing: 24) {
            if !recentDailyLogs.isEmpty {
                productivityOverTime
                focusTimeAnalysis
                workLifeBalance
            } else {
                emptyProductivityAnalytics
            }
        }
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateContent)
    }
    
    private var productivityOverTime: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Productivity Over Time")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
            }
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(productivityData, id: \.date) { data in
                        LineMark(
                            x: .value("Date", data.date),
                            y: .value("Score", data.score)
                        )
                        .foregroundStyle(AppTheme.Colors.primary)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        AreaMark(
                            x: .value("Date", data.date),
                            y: .value("Score", data.score)
                        )
                        .foregroundStyle(AppTheme.Colors.primary.opacity(0.2))
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.month().day())
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }
            } else {
                Text("Productivity tracking requires iOS 16+")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.cardBackground.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.Colors.overlay.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
    
    private var focusTimeAnalysis: some View {
        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 2), spacing: 16) {
            MetricCard(
                title: "Focus Sessions",
                value: "\(totalFocusSessions)",
                subtitle: "deep work blocks",
                icon: "brain.head.profile",
                color: Color.purple
            )
            
            MetricCard(
                title: "Avg Session",
                value: "\(averageFocusTime)min",
                subtitle: "focus duration",
                icon: "stopwatch",
                color: Color.blue
            )
            
            MetricCard(
                title: "Peak Time",
                value: peakProductivityHour,
                subtitle: "most productive",
                icon: "sun.max.fill",
                color: Color.orange
            )
            
            MetricCard(
                title: "Efficiency",
                value: "\(Int(productivityEfficiency * 100))%",
                subtitle: "time utilization",
                icon: "gauge",
                color: Color.green
            )
        }
    }
    
    private var workLifeBalance: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Work-Life Balance")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                BalanceIndicator(
                    title: "Work",
                    percentage: workTimePercentage,
                    color: Color.blue
                )
                
                BalanceIndicator(
                    title: "Personal",
                    percentage: personalTimePercentage,
                    color: Color.green
                )
                
                BalanceIndicator(
                    title: "Rest",
                    percentage: restTimePercentage,
                    color: Color.purple
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.cardBackground.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.Colors.overlay.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
    
    private var emptyProductivityAnalytics: some View {
        VStack(spacing: 20) {
            Circle()
                .fill(AppTheme.Colors.secondary.opacity(0.15))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(AppTheme.Colors.secondary)
                )
            
            VStack(spacing: 8) {
                Text("No Productivity Data")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("Complete some scheduled activities to see productivity insights and trends.")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.Colors.cardBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.Colors.overlay.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Schedule Section
private extension AnalyticsView {
    
    var scheduleSection: some View {
        VStack(spacing: 24) {
            if !recentDailyLogs.isEmpty {
                scheduleConsistency
                timeDistribution
                scheduleOptimization
            } else {
                emptyScheduleAnalytics
            }
        }
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateContent)
    }
    
    private var scheduleConsistency: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Schedule Consistency")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Text("\(Int(scheduleConsistencyScore * 100))%")
                    .font(.headline.weight(.bold))
                    .foregroundColor(scheduleConsistencyScore > 0.7 ? Color.green : Color.orange)
            }
            
            // Weekly consistency chart
            HStack(spacing: 8) {
                ForEach(Weekday.allCases, id: \.self) { day in
                    VStack(spacing: 4) {
                        Text(String(day.rawValue.prefix(3)))
                            .font(.caption2.weight(.medium))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(consistencyColor(for: day))
                            .frame(width: 24, height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(AppTheme.Colors.primary)
                                    .frame(height: CGFloat(consistencyScore(for: day)) * 40)
                                    .animation(.spring(response: 0.8, dampingFraction: 0.8), value: consistencyScore(for: day)),
                                alignment: .bottom
                            )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.cardBackground.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.Colors.overlay.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
    
    private var timeDistribution: some View {
        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 2), spacing: 16) {
            MetricCard(
                title: "Avg Wake Time",
                value: averageWakeTime,
                subtitle: "daily average",
                icon: "sun.max",
                color: Color.orange
            )
            
            MetricCard(
                title: "Avg Sleep Time",
                value: averageSleepTime,
                subtitle: "daily average",
                icon: "moon",
                color: Color.indigo
            )
            
            MetricCard(
                title: "Schedule Fill",
                value: "\(Int(scheduleFillRate * 100))%",
                subtitle: "time scheduled",
                icon: "calendar",
                color: AppTheme.Colors.primary
            )
            
            MetricCard(
                title: "Free Time",
                value: "\(averageFreeTimeHours)h",
                subtitle: "daily average",
                icon: "leaf",
                color: Color.green
            )
        }
    }
    
    private var scheduleOptimization: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Schedule Insights")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                InsightCard(
                    icon: "clock.arrow.2.circlepath",
                    title: "Schedule Pattern",
                    description: schedulePatternInsight,
                    color: AppTheme.Colors.primary
                )
                
                InsightCard(
                    icon: "exclamationmark.triangle",
                    title: "Optimization Tip",
                    description: scheduleOptimizationTip,
                    color: Color.orange
                )
                
                InsightCard(
                    icon: "checkmark.circle",
                    title: "Best Practice",
                    description: scheduleBestPractice,
                    color: Color.green
                )
            }
        }
    }
    
    private var emptyScheduleAnalytics: some View {
        VStack(spacing: 20) {
            Circle()
                .fill(Color.green.opacity(0.15))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(Color.green)
                )
            
            VStack(spacing: 8) {
                Text("No Schedule Data")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("Use TimeFlow for a few days to see detailed schedule analytics and optimization tips.")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.Colors.cardBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.Colors.overlay.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Supporting Views

private struct CategoryTab: View {
    let category: AnalyticsCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
                
                Text(category.rawValue)
                    .font(.caption.weight(.medium))
                    .foregroundColor(isSelected ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary)
            }
            .frame(width: 80)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppTheme.Colors.primary.opacity(0.15) : Color.clear)
            )
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(color)
                    )
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.cardBackground.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.Colors.overlay.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
}

private struct TrendCard: View {
    let title: String
    let trend: TrendDirection
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(trend.color.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: trend.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(trend.color)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.cardBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.Colors.overlay.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

private struct InsightCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.cardBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.Colors.overlay.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

private struct BalanceIndicator: View {
    let title: String
    let percentage: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: percentage / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.8), value: percentage)
                
                Text("\(Int(percentage))%")
                    .font(.caption.weight(.bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Data Models and Enums

enum TimeframeFilter: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month" 
    case quarter = "3 Months"
    
    var id: String { rawValue }
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        }
    }
}

enum AnalyticsCategory: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case goals = "Goals"
    case productivity = "Productivity"
    case schedule = "Schedule"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .goals: return "target"
        case .productivity: return "brain.head.profile"
        case .schedule: return "calendar"
        }
    }
}

enum TrendDirection {
    case up
    case down
    case stable
    
    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .stable: return .orange
        }
    }
}

struct ActivityBreakdownData {
    let type: EventType
    let count: Int
    let color: Color
}

struct ProductivityDataPoint {
    let date: Date
    let score: Double
}

// MARK: - Computed Properties for Analytics

private extension AnalyticsView {
    
    // Overview analytics
    var totalEventsCount: Int {
        recentDailyLogs.reduce(0) { $0 + $1.events.count }
    }
    
    var averageEventsPerDay: Double {
        guard !recentDailyLogs.isEmpty else { return 0 }
        return Double(totalEventsCount) / Double(recentDailyLogs.count)
    }
    
    var mostProductiveDay: String {
        let dayEventCounts = Dictionary(grouping: recentDailyLogs) { 
            Calendar.current.component(.weekday, from: $0.date)
        }.mapValues { logs in
            logs.reduce(0) { $0 + $1.events.count }
        }
        
        let mostProductiveDayNumber = dayEventCounts.max { $0.value < $1.value }?.key ?? 1
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return dayNames[(mostProductiveDayNumber - 1) % 7]
    }
    
    var scheduleScore: Double {
        guard !recentDailyLogs.isEmpty else { return 0 }
        
        let totalMinutes = recentDailyLogs.reduce(0.0) { total, log in
            let eventDuration = log.events.reduce(0.0) { sum, event in
                sum + event.end.timeIntervalSince(event.start) / 60
            }
            return total + eventDuration
        }
        
        let availableMinutes = Double(recentDailyLogs.count) * (16 * 60) // Assume 16 productive hours per day
        return min(1.0, totalMinutes / availableMinutes)
    }
    
    var activityBreakdownData: [ActivityBreakdownData] {
        let eventCounts = Dictionary(grouping: recentDailyLogs.flatMap { $0.events }) { $0.eventType }
            .mapValues { $0.count }
        
        return eventCounts.map { type, count in
            ActivityBreakdownData(
                type: type,
                count: count,
                color: colorForEventType(type)
            )
        }.sorted { $0.count > $1.count }
    }
    
    var dailyActivityTrend: TrendDirection {
        guard recentDailyLogs.count >= 3 else { return .stable }
        
        let recent = recentDailyLogs.suffix(3).map { $0.events.count }
        let earlier = recentDailyLogs.prefix(max(1, recentDailyLogs.count - 3)).map { $0.events.count }
        
        let recentAvg = Double(recent.reduce(0, +)) / Double(recent.count)
        let earlierAvg = Double(earlier.reduce(0, +)) / Double(max(1, earlier.count))
        
        if recentAvg > earlierAvg * 1.1 {
            return .up
        } else if recentAvg < earlierAvg * 0.9 {
            return .down
        } else {
            return .stable
        }
    }
    
    var dailyActivityDescription: String {
        switch dailyActivityTrend {
        case .up:
            return "Your daily activity is increasing. Keep up the momentum!"
        case .down:
            return "Your activity has decreased recently. Consider reviewing your goals."
        case .stable:
            return "Your activity level is consistent. Great job maintaining balance!"
        }
    }
    
    var sleepConsistencyTrend: TrendDirection {
        guard recentDailyLogs.count >= 7 else { return .stable }
        
        let wakeTimes = recentDailyLogs.map { timeToMinutes($0.awakeHours.wakeTime) }
        let variance = calculateVariance(wakeTimes)
        
        if variance < 30 { // Less than 30 minutes variance
            return .up
        } else if variance > 60 { // More than 1 hour variance
            return .down
        } else {
            return .stable
        }
    }
    
    var sleepConsistencyDescription: String {
        switch sleepConsistencyTrend {
        case .up:
            return "Your sleep schedule is very consistent. Excellent sleep hygiene!"
        case .down:
            return "Your sleep times vary significantly. Try to maintain regular hours."
        case .stable:
            return "Your sleep schedule is moderately consistent. Room for improvement."
        }
    }
    
    var goalProgressTrend: TrendDirection {
        guard let goals = contentModel.user?.goals.filter({ $0.isActive }), !goals.isEmpty else { return .stable }
        
        let completedThisWeek = goals.reduce(0) { $0 + $1.daysCompletedThisWeek.count }
        let targetThisWeek = goals.reduce(0) { $0 + ($1.customPerWeek ?? 1) }
        
        let completionRate = Double(completedThisWeek) / Double(max(1, targetThisWeek))
        
        if completionRate >= 0.8 {
            return .up
        } else if completionRate < 0.5 {
            return .down
        } else {
            return .stable
        }
    }
    
    var goalProgressDescription: String {
        switch goalProgressTrend {
        case .up:
            return "You're crushing your goals this week! Keep it up!"
        case .down:
            return "Goal completion is behind target. Let's get back on track."
        case .stable:
            return "Goal progress is steady. Push a bit more to excel!"
        }
    }
    
    // Goals analytics
    var totalGoalHours: Int {
        contentModel.user?.goals.reduce(0) { $0 + ($1.totalCompletionMinutes / 60) } ?? 0
    }
    
    var bestGoalStreak: Int {
        // This would need to be calculated from historical data
        // For now, return a placeholder
        return 7
    }
    
    var thisWeekGoalProgress: Int {
        guard let goals = contentModel.user?.goals.filter({ $0.isActive }), !goals.isEmpty else { return 0 }
        
        let completed = goals.reduce(0) { $0 + $1.daysCompletedThisWeek.count }
        let target = goals.reduce(0) { $0 + ($1.customPerWeek ?? 1) }
        
        return target > 0 ? Int((Double(completed) / Double(target)) * 100) : 0
    }
    
    var topPerformingGoal: String {
        guard let goals = contentModel.user?.goals.filter({ $0.isActive }), !goals.isEmpty else { 
            return "No active goals to analyze"
        }
        
        let bestGoal = goals.max { $0.totalCompletionsAllTime < $1.totalCompletionsAllTime }
        return bestGoal?.title ?? "No standout performer yet"
    }
    
    var consistencyPattern: String {
        let weekdays = [Weekday.monday, .tuesday, .wednesday, .thursday, .friday]
        let weekendDays = [Weekday.saturday, .sunday]
        
        let weekdayEvents = recentDailyLogs.filter { log in
            let weekday = Calendar.current.component(.weekday, from: log.date)
            return weekdays.contains(Weekday.allCases[weekday - 1])
        }.reduce(0) { $0 + $1.events.count }
        
        let weekendEvents = recentDailyLogs.filter { log in
            let weekday = Calendar.current.component(.weekday, from: log.date)
            return weekendDays.contains(Weekday.allCases[weekday - 1])
        }.reduce(0) { $0 + $1.events.count }
        
        if weekdayEvents > weekendEvents * 2 {
            return "You're most productive on weekdays. Consider lighter weekend goals."
        } else if weekendEvents > weekdayEvents {
            return "You're more active on weekends. Great work-life balance!"
        } else {
            return "You maintain consistent activity throughout the week."
        }
    }
    
    var goalRecommendation: String {
        guard let goals = contentModel.user?.goals else { return "Start tracking goals to get recommendations" }
        
        if goals.isEmpty {
            return "Consider adding 2-3 specific, measurable goals to start building habits."
        } else if goals.count > 5 {
            return "You have many goals. Focus on your top 3 for better success rates."
        } else {
            return "Your goal count looks balanced. Focus on consistency over perfection."
        }
    }
    
    // Productivity analytics
    var productivityData: [ProductivityDataPoint] {
        return recentDailyLogs.map { log in
            let score = Double(log.events.count) / 10.0 // Normalize to 0-1 scale
            return ProductivityDataPoint(date: log.date, score: min(1.0, score))
        }
    }
    
    var totalFocusSessions: Int {
        recentDailyLogs.reduce(0) { total, log in
            total + log.events.filter { 
                $0.eventType == .goal || $0.eventType == .assignment || $0.eventType == .testStudy
            }.count
        }
    }
    
    var averageFocusTime: Int {
        let focusEvents = recentDailyLogs.flatMap { log in
            log.events.filter { 
                $0.eventType == .goal || $0.eventType == .assignment || $0.eventType == .testStudy
            }
        }
        
        guard !focusEvents.isEmpty else { return 0 }
        
        let totalMinutes = focusEvents.reduce(0.0) { total, event in
            total + event.end.timeIntervalSince(event.start) / 60
        }
        
        return Int(totalMinutes / Double(focusEvents.count))
    }
    
    var peakProductivityHour: String {
        let hourEventCounts = Dictionary(grouping: recentDailyLogs.flatMap { $0.events }) { event in
            Calendar.current.component(.hour, from: event.start)
        }.mapValues { $0.count }
        
        let peakHour = hourEventCounts.max { $0.value < $1.value }?.key ?? 9
        
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(bySettingHour: peakHour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date).lowercased()
    }
    
    var productivityEfficiency: Double {
        guard !recentDailyLogs.isEmpty else { return 0 }
        
        let totalScheduledMinutes = recentDailyLogs.reduce(0.0) { total, log in
            let eventDuration = log.events.reduce(0.0) { sum, event in
                sum + event.end.timeIntervalSince(event.start) / 60
            }
            return total + eventDuration
        }
        
        let totalAvailableMinutes = Double(recentDailyLogs.count) * (16 * 60) // 16 productive hours
        return min(1.0, totalScheduledMinutes / totalAvailableMinutes)
    }
    
    var workTimePercentage: Double {
        let workEvents = recentDailyLogs.flatMap { $0.events }.filter { $0.eventType == .work }
        let totalMinutes = recentDailyLogs.flatMap { $0.events }.reduce(0.0) { sum, event in
            sum + event.end.timeIntervalSince(event.start) / 60
        }
        
        let workMinutes = workEvents.reduce(0.0) { sum, event in
            sum + event.end.timeIntervalSince(event.start) / 60
        }
        
        return totalMinutes > 0 ? (workMinutes / totalMinutes) * 100 : 0
    }
    
    var personalTimePercentage: Double {
        let allEvents = recentDailyLogs.flatMap { $0.events }
        let personalEvents = allEvents.filter { event in
            event.eventType == .goal || event.eventType == .meal || event.eventType == .other
        }
        
        let totalMinutes = allEvents.reduce(0.0) { sum, event in
            sum + event.end.timeIntervalSince(event.start) / 60
        }
        
        let personalMinutes = personalEvents.reduce(0.0) { sum, event in
            sum + event.end.timeIntervalSince(event.start) / 60
        }
        
        return totalMinutes > 0 ? (personalMinutes / totalMinutes) * 100 : 0
    }
    
    var restTimePercentage: Double {
        let allEvents = recentDailyLogs.flatMap { $0.events }
        let restEvents = allEvents.filter { $0.eventType == .other }
        
        let totalMinutes = allEvents.reduce(0.0) { sum, event in
            sum + event.end.timeIntervalSince(event.start) / 60
        }
        
        let restMinutes = restEvents.reduce(0.0) { sum, event in
            sum + event.end.timeIntervalSince(event.start) / 60
        }
        
        return totalMinutes > 0 ? (restMinutes / totalMinutes) * 100 : 0
    }
    
    // Schedule analytics
    var scheduleConsistencyScore: Double {
        guard recentDailyLogs.count >= 7 else { return 0 }
        
        let wakeTimes = recentDailyLogs.map { timeToMinutes($0.awakeHours.wakeTime) }
        let sleepTimes = recentDailyLogs.map { timeToMinutes($0.awakeHours.sleepTime) }
        
        let wakeVariance = calculateVariance(wakeTimes)
        let sleepVariance = calculateVariance(sleepTimes)
        
        // Lower variance = higher consistency (inverted)
        let consistency = max(0, 1.0 - (wakeVariance + sleepVariance) / 120.0) // Normalize by 2 hours
        return consistency
    }
    
    func consistencyColor(for day: Weekday) -> Color {
        AppTheme.Colors.primary.opacity(0.2)
    }
    
    func consistencyScore(for day: Weekday) -> Double {
        let dayNumber = Weekday.allCases.firstIndex(of: day) ?? 0
        let dayLogs = recentDailyLogs.filter { log in
            let weekday = Calendar.current.component(.weekday, from: log.date)
            return weekday == dayNumber + 1
        }
        
        guard !dayLogs.isEmpty else { return 0 }
        
        let avgEvents = dayLogs.reduce(0) { $0 + $1.events.count } / dayLogs.count
        return min(1.0, Double(avgEvents) / 8.0) // Normalize by assuming 8 events is "full"
    }
    
    var averageWakeTime: String {
        guard !recentDailyLogs.isEmpty else { return "N/A" }
        
        let totalMinutes = recentDailyLogs.reduce(0) { total, log in
            total + timeToMinutes(log.awakeHours.wakeTime)
        }
        
        let avgMinutes = totalMinutes / recentDailyLogs.count
        return formatMinutesToTime(avgMinutes)
    }
    
    var averageSleepTime: String {
        guard !recentDailyLogs.isEmpty else { return "N/A" }
        
        let totalMinutes = recentDailyLogs.reduce(0) { total, log in
            total + timeToMinutes(log.awakeHours.sleepTime)
        }
        
        let avgMinutes = totalMinutes / recentDailyLogs.count
        return formatMinutesToTime(avgMinutes)
    }
    
    var scheduleFillRate: Double {
        guard !recentDailyLogs.isEmpty else { return 0 }
        
        let totalScheduledMinutes = recentDailyLogs.reduce(0.0) { total, log in
            let eventDuration = log.events.reduce(0.0) { sum, event in
                sum + event.end.timeIntervalSince(event.start) / 60
            }
            return total + eventDuration
        }
        
        let totalAwakeMinutes = recentDailyLogs.reduce(0.0) { total, log in
            let wakeMinutes = timeToMinutes(log.awakeHours.wakeTime)
            let sleepMinutes = timeToMinutes(log.awakeHours.sleepTime)
            let awakeMinutes = sleepMinutes > wakeMinutes ? 
                sleepMinutes - wakeMinutes : 
                (1440 - wakeMinutes) + sleepMinutes
            return total + Double(awakeMinutes)
        }
        
        return totalAwakeMinutes > 0 ? totalScheduledMinutes / totalAwakeMinutes : 0
    }
    
    var averageFreeTimeHours: Int {
        guard !recentDailyLogs.isEmpty else { return 0 }
        
        let totalFreeMinutes = recentDailyLogs.reduce(0.0) { total, log in
            let wakeMinutes = timeToMinutes(log.awakeHours.wakeTime)
            let sleepMinutes = timeToMinutes(log.awakeHours.sleepTime)
            let awakeMinutes = sleepMinutes > wakeMinutes ? 
                sleepMinutes - wakeMinutes : 
                (1440 - wakeMinutes) + sleepMinutes
            
            let scheduledMinutes = log.events.reduce(0.0) { sum, event in
                sum + event.end.timeIntervalSince(event.start) / 60
            }
            
            return total + (Double(awakeMinutes) - scheduledMinutes)
        }
        
        return Int(totalFreeMinutes / Double(recentDailyLogs.count) / 60)
    }
    
    var schedulePatternInsight: String {
        let morningEvents = recentDailyLogs.flatMap { $0.events }.filter { 
            Calendar.current.component(.hour, from: $0.start) < 12 
        }.count
        
        let afternoonEvents = recentDailyLogs.flatMap { $0.events }.filter { 
            let hour = Calendar.current.component(.hour, from: $0.start)
            return hour >= 12 && hour < 17
        }.count
        
        let eveningEvents = recentDailyLogs.flatMap { $0.events }.filter { 
            Calendar.current.component(.hour, from: $0.start) >= 17 
        }.count
        
        if morningEvents > afternoonEvents && morningEvents > eveningEvents {
            return "You're most active in the mornings. Great for productivity!"
        } else if eveningEvents > morningEvents && eveningEvents > afternoonEvents {
            return "You prefer evening activities. Consider morning goals for balance."
        } else {
            return "You maintain balanced activity throughout the day."
        }
    }
    
    var scheduleOptimizationTip: String {
        if scheduleFillRate > 0.8 {
            return "Your schedule is quite packed. Consider adding buffer time between activities."
        } else if scheduleFillRate < 0.4 {
            return "You have plenty of free time. Consider adding more structured activities."
        } else {
            return "Your schedule balance looks healthy. Keep maintaining this rhythm."
        }
    }
    
    var scheduleBestPractice: String {
        if scheduleConsistencyScore > 0.8 {
            return "Excellent schedule consistency! Your routine is well-established."
        } else {
            return "Try to maintain more consistent wake and sleep times for better rhythm."
        }
    }
    
    // Helper functions
    func timeToMinutes(_ time: String) -> Int {
        let components = time.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return 0 }
        return components[0] * 60 + components[1]
    }
    
    func formatMinutesToTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        let date = Calendar.current.date(bySettingHour: hours, minute: mins, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
    
    func calculateVariance(_ values: [Int]) -> Double {
        guard values.count > 1 else { return 0 }
        
        let mean = Double(values.reduce(0, +)) / Double(values.count)
        let squaredDifferences = values.map { pow(Double($0) - mean, 2) }
        return squaredDifferences.reduce(0, +) / Double(values.count - 1)
    }
    
    func colorForEventType(_ type: EventType) -> Color {
        switch type {
        case .school, .collegeClass: return Color.blue
        case .work: return Color.purple
        case .goal: return AppTheme.Colors.primary
        case .recurringCommitment: return Color.green
        case .assignment: return Color.orange
        case .testStudy: return Color.red
        case .meal: return Color.mint
        case .other: return Color.gray
        }
    }
}

#Preview {
    AnalyticsView(selectedTab: .constant(2))
        .environment(ContentModel())
}