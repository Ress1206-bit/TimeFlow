//
//  ChatPlaygroundView.swift
//  TimeFlow
//
//  Created by Adam Ress on 6/25/25.
//

import SwiftUI

struct ChatPlaygroundView: View {
    @StateObject private var vm = ViewModel()
    @State private var draft = ""
    @State private var target: Target = .ai      // which function to call

    var body: some View {
        VStack(spacing: 16) {

            // Scrollback -----------------------------------------------------
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(vm.log.indices, id: \.self) { idx in
                        Text(vm.log[idx])
                            .frame(maxWidth: .infinity,
                                   alignment: vm.log[idx].hasPrefix("→") ? .trailing : .leading)
                            .padding(8)
                    }
                }
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: vm.log.count) { _ in
                    proxy.scrollTo(vm.log.indices.last, anchor: .bottom)
                }
            }
            .frame(maxHeight: 300)

            // Input field ----------------------------------------------------
            TextField("Type your message", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.roundedBorder)

            // Segmented control to pick helper ------------------------------
            Picker("Target", selection: $target) {
                Text("chatWithAI").tag(Target.ai)
                Text("chatWithManager").tag(Target.manager)
            }
            .pickerStyle(.segmented)

            // Send button ----------------------------------------------------
            Button("Send") {
                let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return }
                draft = ""
                Task { await vm.send(text, to: target) }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Nova Playground")
    }
}

// MARK: – ViewModel ----------------------------------------------------------
extension ChatPlaygroundView {
    enum Target { case ai, manager }

    @MainActor
    final class ViewModel: ObservableObject {
        @Published var log: [String] = []
        private let helper = OpenAIHelper()

        func send(_ text: String, to target: Target) async {
            log.append("← " + text)
            do {
                let reply: String
                switch target {
                case .ai:      reply = try await helper.chatWithAI(text)
                case .manager: reply = try await helper.chatWithManager(text)
                }
                log.append("→ " + reply)
            } catch {
                log.append("⚠️  " + error.localizedDescription)
            }
        }
    }
}

#Preview {
    ChatPlaygroundView()
}
