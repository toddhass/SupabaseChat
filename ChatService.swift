import Foundation
import Combine
import OSLog
import Supabase

@MainActor
class ChatService: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoadingMessages = false
    @Published var error: Error?
    
    let supabaseService: SupabaseService
    private let logger = Logger(subsystem: "com.supachat.app", category: "ChatService")
    private var cancellables = Set<AnyCancellable>()
    
    init(supabaseService: SupabaseService) {
        self.supabaseService = supabaseService
        setupAuthObserver()
        Task {
            try await fetchMessages() // Initial load
        }
    }
    
    func fetchMessages() async throws {
        isLoadingMessages = true
        error = nil
        
        do {
            let fetchedMessages = try await supabaseService.fetchMessages()
            self.messages = fetchedMessages
            self.isLoadingMessages = false
            logger.info("Fetched \(fetchedMessages.count) messages")
        } catch {
            self.error = error
            self.isLoadingMessages = false
            logger.error("Error fetching messages: \(error.localizedDescription)")
            throw error
        }
    }
    
    func sendMessage(_ message: Message) async throws {
        do {
            try await supabaseService.sendMessage(message)
            logger.info("Sent message: \(message.content)")
        } catch {
            logger.error("Error sending message: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func setupAuthObserver() {
        supabaseService.authService.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                guard let self = self else { return }
                logger.info("Authentication state changed to: \(isAuthenticated)")
                if isAuthenticated {
                    self.setupRealtimeSubscription()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupRealtimeSubscription() {
        logger.info("Setting up Realtime subscription...")
        Task {
            do {
                try await supabaseService.subscribeToMessages { [weak self] message in
                    Task { @MainActor in
                        guard let self = self else { return }
                        if !self.messages.contains(where: { $0.id == message.id }) {
                            self.messages.append(message)
                            self.logger.info("Received realtime message: \(message.id) - \(message.content), username: \(message.username ?? "nil")")
                        } else {
                            self.logger.debug("Duplicate message ignored: \(message.id)")
                        }
                    }
                }
                logger.info("Realtime subscription established")
            } catch {
                await MainActor.run {
                    self.error = error
                    logger.error("Error setting up realtime subscription: \(error.localizedDescription)")
                }
            }
        }
    }
}
