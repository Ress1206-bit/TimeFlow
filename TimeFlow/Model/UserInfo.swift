//
//  UserInfo.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/27/25.
//

import Foundation


struct UserInfo: Identifiable, Codable, Hashable {
    let id: String = UUID().uuidString
    var background: String
    var name: String
    var age: Int
    var ageGroup: AgeGroup
    var goals: [String]
    var activities: [String]
    var wakeMinutes: Int
    var bedMinutes: Int
    var workHours: WorkHours?
}
