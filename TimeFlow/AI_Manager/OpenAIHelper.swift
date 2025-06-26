//
//  OpenAIHelper.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/25/25.
//

import Foundation
import OpenAI

// Errors we might throw instead of force-unwrapping
enum OpenAIHelperError: LocalizedError {
    case messageInitFailed(String)
    var errorDescription: String? {
        switch self {
        case .messageInitFailed(let txt): return "Failed to create chat message: “\(txt)”"
        }
    }
}

@MainActor
final class OpenAIHelper {

    private let client = OpenAI(apiToken: "")

    // MARK: – Python chatWithAI
    func chatWithAI(_ userMessage: String) async throws -> String {
        let systemPrompt = """
        You are a productivity assistant for a scheduling app, \
        providing concise, practical advice to help users organize tasks, \
        prioritize goals, and stay motivated.
        """

        let messages = try makeMessages([
            (.system, systemPrompt),
            (.user,   userMessage)
        ])

        return try await send(messages: messages, model: "gpt-4o")
    }

    // MARK: – Python chatWithManager
    func chatWithManager(_ systemMessage: String) async throws -> String {
        let messages = try makeMessages([
            (.system, "You are helping this app organize and manage information from the user."),
            (.system, systemMessage)
        ])

        return try await send(messages: messages, model: "gpt-4o")
    }

    // MARK: – Helpers --------------------------------------------------------

    /// Builds `[ChatCompletionMessageParam]` safely
    private func makeMessages(_ tuples: [(ChatQuery.ChatCompletionMessageParam.Role, String)])
        throws -> [ChatQuery.ChatCompletionMessageParam] {

        try tuples.map { role, content in
            guard let msg = ChatQuery.ChatCompletionMessageParam(role: role, content: content)
            else { throw OpenAIHelperError.messageInitFailed(content) }
            return msg
        }
    }

    /// Shared sender
    private func send(messages: [ChatQuery.ChatCompletionMessageParam],
                      model: String) async throws -> String {

        let query  = ChatQuery(messages: messages, model: model)
        let result = try await client.chats(query: query)
        return result.choices.first?.message.content ?? ""
    }
}
