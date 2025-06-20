//
//  ChatViewModel.swift
//  TimeFlow
//
//  Created by Adam Ress on 5/30/25.
//

import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []

    // 1) Change this URL to match your deployed function
    private let chatURL = URL(string: "https://us-central1-timeflow-31890.cloudfunctions.net/chatBot")!

    func send(_ text: String, from userID: String) {
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }

        // Append the user’s message immediately:
        messages.append(
            Message(
                id: UUID().uuidString,
                role: .user,
                text: body,
                timestamp: .now
            )
        )

        // Build the payload array
        let msgArray: [[String: String]] = messages.map {
            ["role":    $0.role.rawValue,
             "content": $0.text]
        }
        let requestBody: [String: Any] = ["messages": msgArray]

        // Debug‐print
        print("DEBUG HTTP payload =", requestBody)

        Task {
            do {
                // Serialize to JSON
                let data = try JSONSerialization.data(withJSONObject: requestBody)

                // Create a POST request
                var req = URLRequest(url: chatURL)
                req.httpMethod = "POST"
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                req.httpBody = data

                // Fire it off
                let (responseData, response) = try await URLSession.shared.data(for: req)

                // Check for HTTP errors
                if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                    let msg = String(data: responseData, encoding: .utf8) ?? "Unknown error"
                    throw NSError(domain: "", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
                }

                // Parse JSON { "text": "…" }
                guard
                    let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                    let replyText = json["text"] as? String
                else {
                    throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Malformed response"])
                }

                // Append the assistant’s reply
                messages.append(
                    Message(
                        id: UUID().uuidString,
                        role: .assistant,
                        text: replyText,
                        timestamp: .now
                    )
                )
            } catch {
                // On any error, append that error message
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
    }
}
