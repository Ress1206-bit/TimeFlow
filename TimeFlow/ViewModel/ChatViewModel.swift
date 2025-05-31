//
//  ChatViewModel.swift
//  TimeFlow
//
//  Created by Adam Ress on 5/30/25.
//

import Foundation
import FirebaseFunctions

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    
    private lazy var functions = Functions.functions()

    func send(_ text: String, from userID: String) {

        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }

        messages.append(
            Message(
                id: UUID().uuidString,
                role: .user,             // mark this as a “user” message
                text: body,
                timestamp: .now
            )
        )
        
        // Get A.I. Response
        Task {
                do {
                    // a) Create a JSON‐serializable payload of your full chat history
                    let payload: [String: Any] = [
                        "messages": messages.map { ["role": $0.role.rawValue, "content": $0.text] }
                    ]

                    // b) Invoke the Cloud Function by name
                    let result = try await functions
                        .httpsCallable("chatBot")
                        .call(payload)

                    // c) Parse the returned JSON { "text": "AI’s reply" }
                    if let data = result.data as? [String: Any],
                       let replyText = data["text"] as? String
                    {
                        // Append the AI’s reply to messages
                        messages.append(
                            Message(
                                id: UUID().uuidString,
                                role: .assistant,
                                text: replyText,
                                timestamp: .now
                            )
                        )
                    }
                } catch {
                    // If there’s an error, show it as a message
                    messages.append(
                        Message(
                            id: UUID().uuidString,
                            role: .assistant,
                            text: "Error: \(error.localizedDescription)",
                            timestamp: .now
                        )
                    )
                }
            }
        
        // todo: Firestore write later
        
        
    }

    // todo: loadMessages() that streams changes from Firestore
}
