//
//  ChatView.swift
//  TimeFlow
//
//  Created by Adam Ress on 5/29/25.
//

import SwiftUI
import Combine

struct ChatView: View {
    @Binding var selectedTab: Int
    @State private var messageText = ""
    @FocusState private var isTyping: Bool
    @EnvironmentObject var chatVM: ChatViewModel
    @State private var animateContent = false
    
    @State private var keyboardVisible = false
    private var bottomPadding: CGFloat { keyboardVisible ? 0 : 70 }

    var body: some View {
        ZStack {
            // Background gradient matching app theme
            AppTheme.Gradients.backgroundGradient(for: Calendar.current.component(.hour, from: Date()))
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                // Main content area
                if chatVM.messages.isEmpty {
                    emptyStateView
                } else {
                    messageListView
                }
                
                // Input section
                inputSection
                
                Spacer(minLength: 0) 
            }
            
            // Fixed tab bar
            VStack {
                Spacer()
                TabBarView(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(.keyboard)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateContent = true
            }
        }
        .onTapGesture {
            isTyping = false
        }
        .onReceive(
            Publishers.Merge(
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
                    .map { _ in true },
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                    .map { _ in false }
            )
        ) { visible in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardVisible = visible
            }
        }
    }
}

// MARK: - Empty State View
private extension ChatView {
    
    var emptyStateView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Top spacing
                Spacer()
                    .frame(height: 60)
                
                // Main content
                VStack(spacing: 32) {
                    // Welcome section
                    welcomeSection
                    
                    // Input section moved here
                    inputSectionForEmpty
                    
                    // Contextual suggestions
                    suggestionsSection
                }
                .padding(.horizontal, 24)
                
                Spacer()
                    .frame(height: 120) // Space for tab bar
            }
        }
    }
    
    private var welcomeSection: some View {
        VStack(spacing: 16) {
            // Icon
            Circle()
                .fill(AppTheme.Colors.primary.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(AppTheme.Colors.primary)
                )
            
            // Text
            VStack(spacing: 8) {
                Text("Schedule Assistant")
                    .font(.title.weight(.bold))
                    .foregroundColor(.white)
                
                Text("Ask me anything about your schedule")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .opacity(animateContent ? 1.0 : 0)
        .scaleEffect(animateContent ? 1.0 : 0.9)
        .animation(.easeOut(duration: 0.8).delay(0.1), value: animateContent)
    }
    
    private var suggestionsSection: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text(suggestionSectionTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Suggestions
            VStack(spacing: 12) {
                ForEach(Array(contextualSuggestions.enumerated()), id: \.offset) { index, suggestion in
                    SuggestionChip(text: suggestion) {
                        messageText = suggestion
                        isTyping = true
                    }
                    .opacity(animateContent ? 1.0 : 0)
                    .offset(x: animateContent ? 0 : -20)
                    .animation(.easeOut(duration: 0.6).delay(0.2 + Double(index) * 0.1), value: animateContent)
                }
            }
        }
    }
    
    // Contextual suggestions based on time of day
    private var contextualSuggestions: [String] {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 6...11: // Morning
            return [
                "What do I have scheduled for today?",
                "Add morning workout to my schedule",
                "Block time for breakfast",
                "Schedule my commute to work"
            ]
        case 12...17: // Afternoon
            return [
                "What's coming up this afternoon?",
                "Schedule a lunch break",
                "Add a meeting for 3 PM",
                "Move my 2 PM appointment to tomorrow"
            ]
        case 18...22: // Evening
            return [
                "What's on my schedule tomorrow?",
                "Add dinner plans for tonight",
                "Schedule time to review my day",
                "Plan my evening routine"
            ]
        default: // Night/Late
            return [
                "What do I have planned for tomorrow?",
                "Set a bedtime reminder",
                "Schedule morning preparation time",
                "Review this week's commitments"
            ]
        }
    }
    
    private var suggestionSectionTitle: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 6...11:
            return "Good morning! Try asking..."
        case 12...17:
            return "Good afternoon! Try asking..."
        case 18...22:
            return "Good evening! Try asking..."
        default:
            return "Try asking..."
        }
    }
    
    // New input section for empty state
    private var inputSectionForEmpty: some View {
        HStack(spacing: 12) {
            // Text input field - larger size
            HStack(spacing: 12) {
                TextField("Ask about your schedule...", text: $messageText, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.title3) // Larger font
                    .foregroundColor(.white)
                    .focused($isTyping)
                    .submitLabel(.send)
                    .lineLimit(1...4)
                    .onSubmit {
                        sendMessage()
                    }
                
                if !messageText.isEmpty {
                    Button(action: { messageText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 24) // More padding
            .padding(.vertical, 20) // Taller field
            .background(
                RoundedRectangle(cornerRadius: 28) // Larger corner radius
                    .fill(.ultraThinMaterial.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
            )
            
            // Send button - larger
            Button(action: sendMessage) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52) // Larger button
                    .background(
                        Circle()
                            .fill(messageText.isEmpty ? .white.opacity(0.15) : AppTheme.Colors.primary)
                    )
            }
            .disabled(messageText.isEmpty)
            .scaleEffect(messageText.isEmpty ? 0.9 : 1.0)
            .animation(.spring(response: 0.3), value: messageText.isEmpty)
        }
        .opacity(animateContent ? 1.0 : 0)
        .offset(y: animateContent ? 0 : 30)
        .animation(.easeOut(duration: 0.8).delay(0.2), value: animateContent)
    }
}

// MARK: - Message List View
private extension ChatView {
    
    var messageListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    // Top padding
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 20)
                    
                    // Messages
                    LazyVStack(spacing: 16) {
                        ForEach(Array(chatVM.messages.enumerated()), id: \.offset) { index, message in
                            MessageBubble(
                                message: message,
                                isUser: message.role == .user
                            )
                            .id(index)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .offset(y: 20)),
                                removal: .opacity
                            ))
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Bottom padding
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 120)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: chatVM.messages.count)
            .onChange(of: chatVM.messages.count) { oldValue, newValue in
                if newValue > oldValue {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(newValue - 1, anchor: .bottom)
                    }
                }
            }
        }
    }
}

// MARK: - Input Section
private extension ChatView {
    
    var inputSection: some View {
        VStack(spacing: 0) {
            // Subtle separator
            Rectangle()
                .fill(.white.opacity(0.06))
                .frame(height: 1)
            
            // Input area - only shown when there are messages
            if !chatVM.messages.isEmpty {
                HStack(spacing: 12) {
                    // Text input field
                    HStack(spacing: 12) {
                        TextField("Ask about your schedule...", text: $messageText, axis: .vertical)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.body)
                            .foregroundColor(.white)
                            .focused($isTyping)
                            .submitLabel(.send)
                            .lineLimit(1...4)
                            .onSubmit {
                                sendMessage()
                            }
                        
                        if !messageText.isEmpty {
                            Button(action: { messageText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(.white.opacity(0.15), lineWidth: 1)
                            )
                    )
                    
                    // Send button
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(messageText.isEmpty ? .white.opacity(0.15) : AppTheme.Colors.primary)
                            )
                    }
                    .disabled(messageText.isEmpty)
                    .scaleEffect(messageText.isEmpty ? 0.9 : 1.0)
                    .animation(.spring(response: 0.3), value: messageText.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(Material.ultraThinMaterial)
            }
        }
        .padding(.bottom, bottomPadding)
        .opacity(animateContent ? 1.0 : 0)
        .offset(y: animateContent ? 0 : 30)
        .animation(.easeOut(duration: 0.8).delay(0.3), value: animateContent)
    }
}

// MARK: - Helper Functions
private extension ChatView {
    
    func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        isTyping = false
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        chatVM.send(message, from: "userID")
        messageText = ""
    }
}

// MARK: - Supporting Views

private struct SuggestionChip: View {
    let text: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(text)
                    .font(.body)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(SuggestionButtonStyle())
    }
}

private struct SuggestionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

private struct MessageBubble: View {
    let message: Message
    let isUser: Bool
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if isUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                // Message content
                Text(message.text)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isUser ? AppTheme.Colors.primary : .white.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(.white.opacity(isUser ? 0.1 : 0.08), lineWidth: 1)
                            )
                    )
                
                // Timestamp
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 6)
            }
            
            if !isUser {
                Spacer(minLength: 60)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ChatView(selectedTab: .constant(3))
        .environmentObject(ChatViewModel())
}