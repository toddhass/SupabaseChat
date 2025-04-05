import SwiftUI
import Combine

struct ChatView: View {
    @EnvironmentObject private var chatService: ChatService
    @AppStorage("username") private var username: String = ""
    
    @State private var messageText = ""
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var pendingMessages: [Message] = []
    @State private var appearAnimation = false
    
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom local navigation bar (not used anymore, controlled by ContentView)
            /*HStack {
                Text("SupaChat")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding()
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.gray.opacity(0.3)),
                alignment: .bottom
            )*/
            
            // Messages list
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if isLoading && chatService.messages.isEmpty && pendingMessages.isEmpty {
                            VStack {
                                ProgressView()
                                    .padding(.bottom, 8)
                                Text("Loading messages...")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                        } else if chatService.messages.isEmpty && pendingMessages.isEmpty {
                            EmptyMessagesView()
                                .transition(.opacity)
                                .animation(.easeIn, value: appearAnimation)
                                .onAppear {
                                    // Trigger animation when view appears
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        appearAnimation = true
                                    }
                                }
                        } else {
                            // Display actual messages
                            ForEach(chatService.messages) { message in
                                MessageRow(message: message, isCurrentUser: message.username == username)
                                    .id(message.id)
                                    .transition(.asymmetric(insertion: .scale(scale: 0.9).combined(with: .opacity), removal: .opacity))
                            }
                            
                            // Display messages that are still sending
                            ForEach(pendingMessages) { message in
                                MessageRow(message: message, isCurrentUser: true, isLoading: true)
                                    .id("pending-\(message.id)")
                                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: chatService.messages.count)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pendingMessages.count)
                }
                .onChange(of: chatService.messages) { _ in
                    // Scroll to the bottom when new messages arrive
                    if let lastMessage = chatService.messages.last {
                        withAnimation {
                            scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: pendingMessages) { _ in
                    // Scroll to the bottom when pending messages change
                    if let lastPending = pendingMessages.last {
                        withAnimation {
                            scrollView.scrollTo("pending-\(lastPending.id)", anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input area
            UserInputView(
                messageText: $messageText,
                isInputFocused: _isInputFocused,
                onSend: sendMessage
            )
        }
        .onAppear {
            loadMessages()
        }
    }
    
    private func loadMessages() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await chatService.fetchMessages()
                await MainActor.run {
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Failed to load messages: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        // Clear input field immediately
        messageText = ""
        
        let messageId = UUID().uuidString
        let newMessage = Message(
            id: messageId,
            username: username,
            content: trimmedMessage,
            createdAt: Date()
        )
        
        // Add to pending messages with loading animation
        withAnimation {
            pendingMessages.append(newMessage)
        }
        
        Task {
            do {
                try await chatService.sendMessage(newMessage)
                
                // Remove from pending after successful send
                await MainActor.run {
                    withAnimation {
                        pendingMessages.removeAll { $0.id == messageId }
                    }
                }
            } catch {
                await MainActor.run {
                    // Show error and keep the message in pending state
                    self.errorMessage = "Failed to send message: \(error.localizedDescription)"
                    
                    // Remove from pending after some time
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            pendingMessages.removeAll { $0.id == messageId }
                        }
                    }
                }
            }
        }
    }
}

// Empty state view with animation
struct EmptyMessagesView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.7))
                .padding()
                .background(Circle().fill(Color.blue.opacity(0.1)))
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            Text("No messages yet")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Be the first to send a message!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .opacity(isAnimating ? 1.0 : 0.7)
                .animation(
                    Animation.easeInOut(duration: 2)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
        }
        .padding(.vertical, 30)
        .onAppear {
            isAnimating = true
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        let supabaseService = SupabaseService(client: .init(
            supabaseURL: URL(string: "https://example.com")!,
            supabaseKey: "dummy-key"
        ))
        let chatService = ChatService(supabaseService: supabaseService)
        
        return ChatView()
            .environmentObject(chatService)
    }
}
