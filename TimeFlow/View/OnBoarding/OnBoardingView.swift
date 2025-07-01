//
//  OnBoardingView.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/25/25.


import SwiftUI

// MARK: – On-boarding route map
enum OnboardingScreen: Hashable {
    case schoolLevel
    case schoolHours
    case collegeSchedule
    case workHours
    case scheduleTimes
    case goals
    case recurringTimes
    case notifications
    case pageSix
    case subscription
}

struct OnBoardingView: View {
    
    @Environment(ContentModel.self) private var contentModel
    @State private var path: [OnboardingScreen] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            
            // ── First page ─────────────────────────────────────────────
            WelcomeView { push(.schoolLevel) }
                .navigationBarBackButtonHidden(true)
            
            // ── Destinations ───────────────────────────────────────────
            .navigationDestination(for: OnboardingScreen.self) { screen in
                switch screen {
                    
                case .schoolLevel:
                    // SchoolLevel passes back the chosen AgeGroup
                    SchoolLevelView { group in
                        switch group {
                        case .middleSchool, .highSchool:
                            push(.schoolHours)
                        case .college:
                            push(.collegeSchedule)
                        case .youngPro:
                            push(.workHours)
                        }
                    }
                    .navigationBarBackButtonHidden(true)
                    
                case .schoolHours:
                    SchoolHoursView { push(.scheduleTimes) }
                        .navigationBarBackButtonHidden(true)
                    
                case .collegeSchedule:
                    CollegeScheduleView { push(.scheduleTimes) }
                        .navigationBarBackButtonHidden(true)
                     
                case .workHours:
                    WorkHoursView { push(.scheduleTimes) }
                        .navigationBarBackButtonHidden(true)
                    
                case .scheduleTimes:
                    ScheduleTimes { push(.goals) }
                        .navigationBarBackButtonHidden(true)
                    
                case .goals:
                    GoalsView { push(.recurringTimes) }
                        .navigationBarBackButtonHidden(true)
                
                case .recurringTimes:
                    RecurringActivitiesView { push (.notifications) }
                        .navigationBarBackButtonHidden(true)
                    
                case .notifications:
                    NotificationsWidgetsView { push(.subscription) }
                        .navigationBarBackButtonHidden(true)
                    
                case .pageSix:
                    PageSix { push(.subscription) }
                        .navigationBarBackButtonHidden(true)
                    
                case .subscription:
                    SubscriptionView { finishOnboarding() }
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: – Helpers
    private func push(_ next: OnboardingScreen) {
        withAnimation(.easeInOut) { path.append(next) }
    }
    
    private func finishOnboarding() {
        // Persist flag, swap app root, etc.
    }
}

// MARK: – Preview
#Preview {
    OnBoardingView()
        .environment(ContentModel())
}

//OnBoarding Pages

//----------------------------------------------------------------

struct PageSix: View { // preview schedule before use app cool right
    
    var onContinue: () -> Void
    
    var body: some View {
        Button(action: onContinue) {
            Text("Continue")
        }
    }
}

