//
//  Color.swift
//  TimeFlow
//
//  Created by Adam Ress on 7/1/25.
//

import SwiftUI

extension Color {
    // Legacy support - keeping this for backwards compatibility but using theme colors
    static let accent = AppTheme.Colors.accent
}

// Legacy color palette function - now uses theme colors
public extension Color {
    static func palette(_ token: String) -> Color {
        return AppTheme.ActivityColors.palette(token)
    }
    
    var paletteToken: String {
        switch self {
        case AppTheme.ActivityColors.red: return "red"
        case AppTheme.ActivityColors.orange: return "orange"
        case AppTheme.ActivityColors.yellow: return "yellow"
        case AppTheme.ActivityColors.green: return "green"
        case AppTheme.ActivityColors.mint: return "mint"
        case AppTheme.ActivityColors.teal: return "teal"
        case AppTheme.ActivityColors.cyan: return "cyan"
        case AppTheme.ActivityColors.blue: return "blue"
        case AppTheme.ActivityColors.indigo: return "indigo"
        case AppTheme.ActivityColors.purple: return "purple"
        case AppTheme.ActivityColors.pink: return "pink"
        default: return "accent"
        }
    }
}

// Legacy support - keeping these for backwards compatibility
public extension Color {
    static let tfAccent = AppTheme.Colors.primary
    static let tfCard = AppTheme.Colors.cardBackground
}

//Written by ChatGPT
public extension Date {

    // ────────── private, shared formatter ──────────
    static let hhmmFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"                 // 24-hour "08:05", "23:45"
        f.locale    = Locale(identifier: "en_US_POSIX")  // stable parsing
        f.calendar  = .current
        f.timeZone  = .current
        return f
    }()

    /// Converts a `Date` to `"HH:mm"` in the user's current calendar/zone.
    var hhmmString: String {
        Date.hhmmFormatter.string(from: self)
    }

    /// Build a `Date` **today** at the given `"HH:mm"` – e.g. *"09:00"* → today 09 00.
    static func at(_ hhmm: String) -> Date {
        guard let t = Date.hhmmFormatter.date(from: hhmm) else { return Date() }

        // stitch the time components onto today's year-month-day
        var today = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let time  = Calendar.current.dateComponents([.hour, .minute], from: t)
        today.hour   = time.hour
        today.minute = time.minute

        return Calendar.current.date(from: today) ?? Date()
    }
}


//public utility function
func dateFromHHMM(_ hhmm: String) -> Date? {
    let parts = hhmm.split(separator: ":")
    guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return nil }
    return Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: Date())
}



// Hides the keyboard regardless of platform.
extension View {

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}


// To see view lines
struct Outline: ViewModifier {
    func body(content: Content) -> some View {
        content
            .border(Color.red.opacity(0.3))
    }
}