//
//  AssignmentsView.swift
//  TimeFlow
//
//  Created by Adam Ress on 7/25/25.
//

import SwiftUI

struct AssignmentsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ContentModel.self) var contentModel
    
    @Binding var selectedTabPage: Int
    
    @State private var selectedTab: AssignmentTab = .assignments
    @State private var showingAssignmentEditor = false
    @State private var showingTestEditor = false
    @State private var selectedAssignment: Assignment?
    @State private var selectedTest: Test?
    @State private var showingDeleteConfirmation = false
    @State private var itemToDelete: DeleteableItem?
    @State private var showingCloseButton = false
    @State private var filterCompleted: CompletionFilter = .all
    @State private var sortOption: SortOption = .dueDate
    
    // Animation namespace
    @Namespace private var tabAnimation
    
    enum AssignmentTab: String, CaseIterable {
        case assignments = "Assignments"
        case tests = "Tests"
        
        var icon: String {
            switch self {
            case .assignments: return "doc.text.fill"
            case .tests: return "graduationcap.fill"
            }
        }
    }
    
    enum CompletionFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case completed = "Completed"
    }
    
    enum SortOption: String, CaseIterable {
        case dueDate = "Due Date"
        case alphabetical = "Alphabetical"
        case timeLeft = "Time Left"
        
        var icon: String {
            switch self {
            case .dueDate: return "calendar"
            case .alphabetical: return "textformat.abc"
            case .timeLeft: return "clock"
            }
        }
    }
    
    enum DeleteableItem {
        case assignment(Assignment)
        case test(Test)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
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
                    
                    if (selectedTab == .assignments ? filteredAssignments.isEmpty : filteredTests.isEmpty) &&
                       (contentModel.user?.assignments.isEmpty == true && contentModel.user?.tests.isEmpty == true) {
                        emptyStateView
                    } else {
                        contentView
                    }
                    
                    Spacer()
                    
                    TabBarView(selectedTab: $selectedTabPage)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAssignmentEditor) {
            AssignmentEditorView(
                assignment: selectedAssignment ?? createNewAssignment(),
                onSave: { assignment in
                    saveAssignment(assignment)
                },
                onDelete: selectedAssignment != nil ? { assignment in
                    deleteAssignment(assignment)
                } : nil
            )
        }
        .sheet(isPresented: $showingTestEditor) {
            TestEditorView(
                test: selectedTest ?? createNewTest(),
                onSave: { test in
                    saveTest(test)
                },
                onDelete: selectedTest != nil ? { test in
                    deleteTest(test)
                } : nil
            )
        }
        .alert("Delete Item", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let item = itemToDelete {
                    switch item {
                    case .assignment(let assignment):
                        deleteAssignment(assignment)
                    case .test(let test):
                        deleteTest(test)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this item? This action cannot be undone.")
        }
        .onAppear {
            loadData()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 0) {
            // Top header with title
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Assignments & Tests")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text(statusText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)
            
            // Tab selector
            HStack(spacing: 0) {
                ForEach(AssignmentTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 14, weight: .semibold))
                            
                            Text(tab.rawValue)
                                .font(.system(size: 15, weight: .semibold))
                            
                            // Count badge
                            Text("\(tab == .assignments ? (contentModel.user?.assignments.count ?? 0) : (contentModel.user?.tests.count ?? 0))")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(selectedTab == tab ? .white : AppTheme.Colors.textTertiary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(selectedTab == tab ? AppTheme.Colors.accent.opacity(0.3) : AppTheme.Colors.overlay.opacity(0.2))
                                )
                        }
                        .foregroundColor(selectedTab == tab ? AppTheme.Colors.accent : AppTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedTab == tab ? AppTheme.Colors.accent.opacity(0.1) : Color.clear)
                                .matchedGeometryEffect(id: "selectedTab", in: tabAnimation)
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            // Add button
            Button {
                if selectedTab == .assignments {
                    selectedAssignment = nil
                    showingAssignmentEditor = true
                } else {
                    selectedTest = nil
                    showingTestEditor = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Add \(selectedTab.rawValue.dropLast())")
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
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            // Filters section
            filtersSection
            
            // Divider
            Rectangle()
                .fill(AppTheme.Colors.overlay.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, 24)
        }
        .background(AppTheme.Colors.background)
    }
    
    // MARK: - Filters Section
    private var filtersSection: some View {
        VStack(spacing: 16) {
            // Completion filter
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Status")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Spacer()
                }
                
                HStack(spacing: 8) {
                    ForEach(CompletionFilter.allCases, id: \.self) { filter in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                filterCompleted = filter
                            }
                        } label: {
                            Text(filter.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(filterCompleted == filter ? .white : AppTheme.Colors.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(filterCompleted == filter ? AppTheme.Colors.accent : AppTheme.Colors.cardBackground)
                                        .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
                                )
                        }
                    }
                    
                    Spacer()
                }
            }
            
            // Sort options
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Sort By")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Spacer()
                }
                
                HStack(spacing: 8) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                sortOption = option
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: option.icon)
                                    .font(.system(size: 10, weight: .medium))
                                Text(option.rawValue)
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(sortOption == option ? .white : AppTheme.Colors.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(sortOption == option ? AppTheme.Colors.accent : AppTheme.Colors.cardBackground)
                                    .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
                            )
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.cardBackground.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.Colors.overlay.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
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
                        Image(systemName: selectedTab.icon)
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(AppTheme.Colors.accent)
                    )
                
                VStack(spacing: 12) {
                    Text("No \(selectedTab.rawValue)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("Start by adding your \(selectedTab.rawValue.lowercased()) to keep track of deadlines and study time")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal, 32)
                }
                
                Button {
                    if selectedTab == .assignments {
                        selectedAssignment = nil
                        showingAssignmentEditor = true
                    } else {
                        selectedTest = nil
                        showingTestEditor = true
                    }
                } label: {
                    Text("Add \(selectedTab.rawValue.dropLast())")
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
    
    // MARK: - Content View
    private var contentView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                if selectedTab == .assignments {
                    ForEach(filteredAssignments, id: \.id) { assignment in
                        assignmentRow(assignment)
                    }
                } else {
                    ForEach(filteredTests, id: \.id) { test in
                        testRow(test)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Assignment Row
    private func assignmentRow(_ assignment: Assignment) -> some View {
        HStack(spacing: 16) {
            // Completion indicator
            Button {
                toggleAssignmentCompletion(assignment)
            } label: {
                Image(systemName: assignment.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(assignment.completed ? .green : AppTheme.Colors.textTertiary)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(assignment.assignmentTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(assignment.completed ? AppTheme.Colors.textSecondary : AppTheme.Colors.textPrimary)
                            .strikethrough(assignment.completed)
                        
                        Text(assignment.classTitle)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(assignment.dueDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(dueDateColor(assignment.dueDate))
                        
                        Text(timeUntilDue(assignment.dueDate))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
                
                HStack(spacing: 12) {
                    // Time remaining indicator
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text("\(assignment.estimatedMinutesLeftToComplete)m left")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(AppTheme.Colors.overlay.opacity(0.1))
                    )
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 8) {
                        if assignment.completed {
                            Button {
                                itemToDelete = .assignment(assignment)
                                showingDeleteConfirmation = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 10, weight: .semibold))
                                    Text("Remove")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundColor(.red)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.red.opacity(0.1))
                                )
                            }
                        } else {
                            Button {
                                selectedAssignment = assignment
                                showingAssignmentEditor = true
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppTheme.Colors.accent)
                                    .frame(width: 28, height: 28)
                                    .background(
                                        Circle()
                                            .fill(AppTheme.Colors.accent.opacity(0.1))
                                    )
                            }
                            
                            Button {
                                itemToDelete = .assignment(assignment)
                                showingDeleteConfirmation = true
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.red)
                                    .frame(width: 28, height: 28)
                                    .background(
                                        Circle()
                                            .fill(Color.red.opacity(0.1))
                                    )
                            }
                        }
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
                .stroke(assignment.completed ? Color.green.opacity(0.3) : AppTheme.Colors.overlay.opacity(0.2), lineWidth: 1)
        )
        .opacity(assignment.completed ? 0.7 : 1.0)
    }
    
    // MARK: - Test Row
    private func testRow(_ test: Test) -> some View {
        HStack(spacing: 16) {
            // Completion indicator
            Button {
                toggleTestPreparation(test)
            } label: {
                Image(systemName: test.prepared ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(test.prepared ? .blue : AppTheme.Colors.textTertiary)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(test.testTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(test.prepared ? AppTheme.Colors.textSecondary : AppTheme.Colors.textPrimary)
                            .strikethrough(test.prepared)
                        
                        Text(test.classTitle)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(test.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(dueDateColor(test.date))
                        
                        Text(timeUntilDue(test.date))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
                
                HStack(spacing: 12) {
                    // Study time remaining indicator
                    HStack(spacing: 4) {
                        Image(systemName: "book")
                            .font(.system(size: 10))
                        Text("\(test.studyMinutesLeft)m study left")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(AppTheme.Colors.overlay.opacity(0.1))
                    )
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 8) {
                        if test.prepared {
                            Button {
                                itemToDelete = .test(test)
                                showingDeleteConfirmation = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 10, weight: .semibold))
                                    Text("Remove")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundColor(.red)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.red.opacity(0.1))
                                )
                            }
                        } else {
                            Button {
                                selectedTest = test
                                showingTestEditor = true
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppTheme.Colors.accent)
                                    .frame(width: 28, height: 28)
                                    .background(
                                        Circle()
                                            .fill(AppTheme.Colors.accent.opacity(0.1))
                                    )
                            }
                            
                            Button {
                                itemToDelete = .test(test)
                                showingDeleteConfirmation = true
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.red)
                                    .frame(width: 28, height: 28)
                                    .background(
                                        Circle()
                                            .fill(Color.red.opacity(0.1))
                                    )
                            }
                        }
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
                .stroke(test.prepared ? Color.blue.opacity(0.3) : AppTheme.Colors.overlay.opacity(0.2), lineWidth: 1)
        )
        .opacity(test.prepared ? 0.7 : 1.0)
    }
    
    // MARK: - Computed Properties
    private var statusText: String {
        if selectedTab == .assignments {
            let total = contentModel.user?.assignments.count ?? 0
            let completed = contentModel.user?.assignments.filter { $0.completed }.count ?? 0
            return "\(completed)/\(total) completed"
        } else {
            let total = contentModel.user?.tests.count ?? 0
            let prepared = contentModel.user?.tests.filter { $0.prepared }.count ?? 0
            return "\(prepared)/\(total) prepared"
        }
    }
    
    private var filteredAssignments: [Assignment] {
        var assignments = contentModel.user?.assignments ?? []
        
        // Apply completion filter
        switch filterCompleted {
        case .all:
            break
        case .pending:
            assignments = assignments.filter { !$0.completed }
        case .completed:
            assignments = assignments.filter { $0.completed }
        }
        
        // Apply sorting
        switch sortOption {
        case .dueDate:
            assignments.sort { $0.dueDate < $1.dueDate }
        case .alphabetical:
            assignments.sort { $0.assignmentTitle < $1.assignmentTitle }
        case .timeLeft:
            assignments.sort { $0.estimatedMinutesLeftToComplete < $1.estimatedMinutesLeftToComplete }
        }
        
        return assignments
    }
    
    private var filteredTests: [Test] {
        var tests = contentModel.user?.tests ?? []
        
        // Apply completion filter
        switch filterCompleted {
        case .all:
            break
        case .pending:
            tests = tests.filter { !$0.prepared }
        case .completed:
            tests = tests.filter { $0.prepared }
        }
        
        // Apply sorting
        switch sortOption {
        case .dueDate:
            tests.sort { $0.date < $1.date }
        case .alphabetical:
            tests.sort { $0.testTitle < $1.testTitle }
        case .timeLeft:
            tests.sort { $0.studyMinutesLeft < $1.studyMinutesLeft }
        }
        
        return tests
    }
    
    // MARK: - Helper Functions
    private func loadData() {
        // Data is loaded from contentModel automatically
    }
    
    private func saveData() {
        Task {
            do {
                try await contentModel.saveUserInfo()
            } catch {
                print("❌ Failed to save assignments/tests: \(error)")
            }
        }
    }
    
    private func saveAssignment(_ assignment: Assignment) {
        if let index = contentModel.user?.assignments.firstIndex(where: { $0.id == assignment.id }) {
            contentModel.user?.assignments[index] = assignment
        } else {
            contentModel.user?.assignments.append(assignment)
        }
        saveData()
    }
    
    private func saveTest(_ test: Test) {
        if let index = contentModel.user?.tests.firstIndex(where: { $0.id == test.id }) {
            contentModel.user?.tests[index] = test
        } else {
            contentModel.user?.tests.append(test)
        }
        saveData()
    }
    
    private func deleteAssignment(_ assignment: Assignment) {
        contentModel.user?.assignments.removeAll { $0.id == assignment.id }
        saveData()
    }
    
    private func deleteTest(_ test: Test) {
        contentModel.user?.tests.removeAll { $0.id == test.id }
        saveData()
    }
    
    private func toggleAssignmentCompletion(_ assignment: Assignment) {
        if let index = contentModel.user?.assignments.firstIndex(where: { $0.id == assignment.id }) {
            contentModel.user?.assignments[index].completed.toggle()
            saveData()
        }
    }
    
    private func toggleTestPreparation(_ test: Test) {
        if let index = contentModel.user?.tests.firstIndex(where: { $0.id == test.id }) {
            contentModel.user?.tests[index].prepared.toggle()
            saveData()
        }
    }
    
    private func createNewAssignment() -> Assignment {
        Assignment(
            assignmentTitle: "",
            classTitle: "",
            dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        )
    }
    
    private func createNewTest() -> Test {
        Test(
            testTitle: "",
            classTitle: "",
            date: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        )
    }
    
    private func dueDateColor(_ date: Date) -> Color {
        let now = Date()
        let timeInterval = date.timeIntervalSince(now)
        let daysUntilDue = timeInterval / (24 * 60 * 60)
        
        if daysUntilDue < 0 {
            return .red // Overdue
        } else if daysUntilDue < 1 {
            return .orange // Due today
        } else if daysUntilDue < 3 {
            return .yellow // Due soon
        } else {
            return AppTheme.Colors.textSecondary // Normal
        }
    }
    
    private func timeUntilDue(_ date: Date) -> String {
        let now = Date()
        let timeInterval = date.timeIntervalSince(now)
        let daysUntilDue = Int(timeInterval / (24 * 60 * 60))
        
        if timeInterval < 0 {
            let daysOverdue = abs(daysUntilDue)
            return daysOverdue == 0 ? "Overdue" : "\(daysOverdue)d overdue"
        } else if daysUntilDue == 0 {
            return "Due today"
        } else if daysUntilDue == 1 {
            return "Due tomorrow"
        } else {
            return "Due in \(daysUntilDue)d"
        }
    }
}

// MARK: - Assignment Editor View
struct AssignmentEditorView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var assignment: Assignment
    @State private var dueDate: Date
    
    let onSave: (Assignment) -> Void
    let onDelete: ((Assignment) -> Void)?
    
    private let isNewAssignment: Bool
    
    init(assignment: Assignment, onSave: @escaping (Assignment) -> Void, onDelete: ((Assignment) -> Void)? = nil) {
        self._assignment = State(initialValue: assignment)
        self._dueDate = State(initialValue: assignment.dueDate)
        self.onSave = onSave
        self.onDelete = onDelete
        self.isNewAssignment = assignment.assignmentTitle.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Assignment Details") {
                    TextField("Assignment Title", text: $assignment.assignmentTitle)
                        .font(.system(size: 16, weight: .medium))
                    
                    TextField("Class/Subject", text: $assignment.classTitle)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Section("Due Date") {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Time Estimation") {
                    HStack {
                        Text("Estimated Time Left")
                        Spacer()
                        HStack(spacing: 4) {
                            TextField("60", value: $assignment.estimatedMinutesLeftToComplete, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            Text("minutes")
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                }
                
                Section("Additional Information") {
                    TextField("Extra preferences or notes...", text: $assignment.extraPreferenceInfo, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                if !isNewAssignment, let onDelete = onDelete {
                    Section {
                        Button("Delete Assignment") {
                            onDelete(assignment)
                            dismiss()
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle(isNewAssignment ? "New Assignment" : "Edit Assignment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAssignment()
                    }
                    .fontWeight(.semibold)
                    .disabled(assignment.assignmentTitle.isEmpty || assignment.classTitle.isEmpty)
                }
            }
        }
    }
    
    private func saveAssignment() {
        assignment.dueDate = dueDate
        onSave(assignment)
        dismiss()
    }
}

// MARK: - Test Editor View
struct TestEditorView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var test: Test
    @State private var testDate: Date
    
    let onSave: (Test) -> Void
    let onDelete: ((Test) -> Void)?
    
    private let isNewTest: Bool
    
    init(test: Test, onSave: @escaping (Test) -> Void, onDelete: ((Test) -> Void)? = nil) {
        self._test = State(initialValue: test)
        self._testDate = State(initialValue: test.date)
        self.onSave = onSave
        self.onDelete = onDelete
        self.isNewTest = test.testTitle.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Test Details") {
                    TextField("Test Title", text: $test.testTitle)
                        .font(.system(size: 16, weight: .medium))
                    
                    TextField("Class/Subject", text: $test.classTitle)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Section("Test Date") {
                    DatePicker("Test Date", selection: $testDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Study Time") {
                    HStack {
                        Text("Study Time Left")
                        Spacer()
                        HStack(spacing: 4) {
                            TextField("120", value: $test.studyMinutesLeft, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            Text("minutes")
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                }
                
                Section("Additional Information") {
                    TextField("Extra preferences or notes...", text: $test.extraPreferenceInfo, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                if !isNewTest, let onDelete = onDelete {
                    Section {
                        Button("Delete Test") {
                            onDelete(test)
                            dismiss()
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle(isNewTest ? "New Test" : "Edit Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTest()
                    }
                    .fontWeight(.semibold)
                    .disabled(test.testTitle.isEmpty || test.classTitle.isEmpty)
                }
            }
        }
    }
    
    private func saveTest() {
        test.date = testDate
        onSave(test)
        dismiss()
    }
}