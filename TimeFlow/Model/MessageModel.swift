//
//  MessageModel.swift
//  TimeFlow
//
//  Created by Adam Ress on 5/30/25.
//

import Foundation

enum Role: String, Codable {
    case user
    case assistant
}

struct Message: Identifiable, Codable, Hashable {
    let id: String
    let role: Role
    let text: String
    let timestamp: Date
    let isThinking: Bool
    
    init(id: String, role: Role, text: String, timestamp: Date, isThinking: Bool = false) {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
        self.isThinking = isThinking
    }
}