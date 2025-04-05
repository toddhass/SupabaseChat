import Foundation
import Combine
import OSLog

@MainActor
class ChatService: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoadingMessages = false
    @Published var error: Error?
    
    private let supabaseService: SupabaseService
    private let logger = Logger(subsystem: "com.supachat.app", category: "ChatService")
    
    init(supabaseService: SupabaseService) {
        self.supabaseService = supabaseService
        setupRealtimeSubscription()
    }
    
    // Fetch all messages
    func fetchMessages() async throws {
        isLoadingMessages = true
        error = nil
        
        do {
            let fetchedMessages = try await supabaseService.fetchMessages()
            self.messages = fetchedMessages
            self.isLoadingMessages = false
        } catch {
            self.error = error
            self.isLoadingMessages = false
            logger.error("Error fetching messages: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Send a new message
    func sendMessage(_ message: Message) async throws {
        do {
            try await supabaseService.sendMessage(message)
            // The message will be received through the realtime subscription
        } catch {
            logger.error("Error sending message: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Set up realtime subscription
    private func setupRealtimeSubscription() {
        Task {
            do {
                try await supabaseService.subscribeToMessages { [weak self] message in
                    Task { @MainActor in
                        guard let self = self else { return }
                        // Only add the message if it's not already in the list
                        if !self.messages.contains(where: { $0.id == message.id }) {
                            self.messages.append(message)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    logger.error("Error setting up realtime subscription: \(error.localizedDescription)")
                }
            }
        }
    }
}
