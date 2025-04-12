import SwiftUI

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
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        appearAnimation = true
                                    }
                                }
                        } else {
                            ForEach(chatService.messages) { message in
                                MessageRow(
                                    message: message,
                                    isCurrentUser: message.userId == chatService.supabaseService.authService.currentUser?.id
                                )
                                    .id(message.id)
                                    .transition(.asymmetric(insertion: .scale(scale: 0.9).combined(with: .opacity), removal: .opacity))
                            }
                            
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
                    if let lastMessage = chatService.messages.last {
                        withAnimation {
                            scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: pendingMessages) { _ in
                    if let lastPending = pendingMessages.last {
                        withAnimation {
                            scrollView.scrollTo("pending-\(lastPending.id)", anchor: .bottom)
                        }
                    }
                }
            }
            
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
        
        messageText = ""
        
        let messageId = UUID().uuidString
        let currentDate = Date()
        guard let currentUser = chatService.supabaseService.authService.currentUser else {
            self.errorMessage = "You must be logged in to send messages"
            return
        }
        
        let newMessage = Message(
            id: messageId,
            userId: currentUser.id,
            username: username,
            content: trimmedMessage,
            createdAt: currentDate,
            isEdited: false,
            updatedAt: currentDate
        )
        
        withAnimation {
            pendingMessages.append(newMessage)
        }
        
        Task {
            do {
                try await chatService.sendMessage(newMessage)
                await MainActor.run {
                    withAnimation {
                        pendingMessages.removeAll { $0.id == messageId }
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to send message: \(error.localizedDescription)"
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

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        let supabaseService = SupabaseService(client: .init(
            supabaseURL: URL(string: "https://hdzmbngzplkgkchmxfwu.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhkem1ibmd6cGxrZ2tjaG14Znd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE2NzgyNzc3NjQsImV4cCI6MTk5Mzg1Mzc2NH0.ogb5FZ_nfUdIcobdas9EFm7u8vOs8-_RB2CB4MxLMAU"
        ))
        let chatService = ChatService(supabaseService: supabaseService)
        
        return ChatView()
            .environmentObject(chatService)
    }
}
