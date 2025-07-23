//
//  Onboarding.swift
//  TimeFlow
//
//  Created by Adam Ress on 7/10/25.
//

enum OnboardingStep: String, Codable {
    case welcome
    case ageGroup
    case awakeHours
    case schoolWorkHours  // Conditional based on ageGroup
    case collegeCourses   // Only for .college
    case goals
    case recurringCommitments
    case assignmentsTests
    case notifications  // Assuming this exists
    case subscription
    case complete
}
