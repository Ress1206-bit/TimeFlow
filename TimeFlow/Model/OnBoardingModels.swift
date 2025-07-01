//
//  OnBoardingModels.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/29/25.
//

import SwiftUI

enum Weekday: String, CaseIterable, Identifiable {
    case mon = "Mon", tue = "Tue", wed = "Wed", thu = "Thu", fri = "Fri", sat = "Sat", sun = "Sun"
    var id: String { rawValue }
}

struct Course: Identifiable, Hashable {
    let id: UUID
    var name: String
    var day: Weekday
    var start: Date
    var end: Date
    var color: Color
    
    init(id: UUID = UUID(),
         name: String,
         day: Weekday,
         start: Date,
         end: Date,
         color: Color) {
        self.id = id; self.name = name; self.day = day
        self.start = start; self.end = end; self.color = color
    }
}


enum RecurringCadence: String, CaseIterable, Identifiable, Codable {
    case daily = "Daily"
    case weekdays = "Weekdays"
    case custom = "Custom"
    var id: String { rawValue }
}

struct RecurringActivity: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var icon: String
    var colorName: String
    var cadence: RecurringCadence
    var customDays: [Weekday]        // filled only when cadence = .custom
    var start: Date
    var duration: Int                // minutes
    
    var color: Color {
        switch colorName {
        case "red":    return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green":  return .green
        case "mint":   return .mint
        case "teal":   return .teal
        case "cyan":   return .cyan
        case "blue":   return .blue
        case "indigo": return .indigo
        case "purple": return .purple
        case "pink":   return .pink
        default:       return .accentColor
        }
    }
}

struct DayHours: Identifiable {
    let id = UUID()
    var day: Weekday
    var enabled: Bool
    var start: Date
    var end: Date
}

enum Cadence: String, CaseIterable, Identifiable, Codable {
    case daily        = "Daily"
    case thriceWeek   = "3× week"
    case weekly       = "Weekly"
    case custom       = "Custom"
    var id: String { rawValue }
}

struct Goal: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var activity: String
    var details: String
    var cadence: Cadence
    var customPerWeek: Int?
    var durationMinutes: Int
    var colorName: String
    var symbol: String

    var color: Color {
        switch colorName {
        case "red":    return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green":  return .green
        case "mint":   return .mint
        case "teal":   return .teal
        case "cyan":   return .cyan
        case "blue":   return .blue
        case "indigo": return .indigo
        case "purple": return .purple
        case "pink":   return .pink
        default:       return .accentColor
        }
    }

    init(id: UUID = UUID(),
         title: String,
         activity: String = "",
         details: String = "",
         cadence: Cadence = .daily,
         customPerWeek: Int? = nil,
         durationMinutes: Int = 30,
         colorName: String = "accent",
         symbol: String = "target") {
        self.id = id
        self.title = title
        self.activity = activity
        self.details = details
        self.cadence = cadence
        self.customPerWeek = customPerWeek
        self.durationMinutes = durationMinutes
        self.colorName = colorName
        self.symbol = symbol
    }
}

struct WorkHours: Codable, Hashable {
    var startMinutes: Int
    var endMinutes: Int
}

enum AgeGroup: String, Codable, Hashable, CaseIterable, Identifiable {
    case middleSchool = "Middle School"
    case highSchool   = "High School"
    case college      = "College"
    case youngPro     = "Young Professional"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .middleSchool: return "backpack.fill"
        case .highSchool:   return "books.vertical.fill"
        case .college:      return "graduationcap.fill"
        case .youngPro:     return "briefcase.fill"
        }
    }
}
