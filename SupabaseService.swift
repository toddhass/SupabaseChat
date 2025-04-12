import Foundation
import Supabase
import Combine
import OSLog

enum SupabaseError: Error, LocalizedError {
    case fetchFailed(String)
    case insertFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case realtimeSubscriptionFailed(String)
    case invalidData(String)
    case unauthorizedAccess(String)
    case storageFailed(String)
    case fileUploadFailed(String)
    case fileDownloadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let reason): return "Failed to fetch data: \(reason)"
        case .insertFailed(let reason): return "Failed to insert data: \(reason)"
        case .updateFailed(let reason): return "Failed to update data: \(reason)"
        case .deleteFailed(let reason): return "Failed to delete data: \(reason)"
        case .invalidData(let reason): return "Invalid data: \(reason)"
        case .realtimeSubscriptionFailed(let reason): return "Failed to subscribe to real-time updates: \(reason)"
        case .unauthorizedAccess(let reason): return "Unauthorized access: \(reason)"
        case .storageFailed(let reason): return "Storage operation failed: \(reason)"
        case .fileUploadFailed(let reason): return "Failed to upload file: \(reason)"
        case .fileDownloadFailed(let reason): return "Failed to download file: \(reason)"
        }
    }
}

class SupabaseService: ObservableObject {
    private let client: SupabaseClient
    private let logger = Logger(subsystem: "com.supachat.app", category: "SupabaseService")
    private var messagesChannel: RealtimeChannelV2?
    
    private let messagesTable = "messages"
    private let usersTable = "profiles"
    private let avatarsBucket = "avatars"
    
    private(set) var authService: AuthenticationService
    
    init(client: SupabaseClient) {
        self.client = client
        self.authService = AuthenticationService(client: client)
        
        Task {
            do {
                try await setupStorageBuckets()
            } catch {
                logger.error("Failed to setup storage buckets: \(error.localizedDescription)")
            }
        }
        
        Task {
            await reconnectRealtime()
        }
    }
    
    // MARK: - Real-Time Connection Management
    
    private func reconnectRealtime() async {
        while true {
            if client.realtimeV2.status != .connected {
                await client.realtimeV2.connect()
                logger.info("Realtime client connected or reconnected")
            }
            try? await Task.sleep(for: .seconds(5))
        }
    }
    
    // MARK: - Storage Setup
    
    struct MessageInsert: Encodable {
        let id: String
        let userId: String
        let content: String
        let isEdited: Bool
        let createdAt: Date
        let updatedAt: Date
        
        enum CodingKeys: String, CodingKey {
            case id
            case userId = "user_id"
            case content
            case isEdited = "is_edited"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }
    
    private func setupStorageBuckets() async throws {
        do {
            _ = try await client.storage.getBucket(avatarsBucket)
            logger.info("Avatars bucket exists")
        } catch {
            if (error as NSError).code == 409 {
                logger.info("Avatars bucket already exists, no action needed")
            } else {
                logger.info("Creating avatars bucket")
                try await client.storage.createBucket(avatarsBucket, options: .init(public: true))
                logger.info("Avatars bucket created")
            }
        }
    }
    
    // MARK: - Messages
    
    func fetchMessages() async throws -> [Message] {
        do {
            let response = try await client
                .database
                .from(messagesTable)
                .select("*, profiles!messages_user_id_fkey(username)")
                .order("created_at", ascending: true)
                .execute()
            
            let rawString = String(data: response.data, encoding: .utf8) ?? "Invalid UTF-8"
            logger.info("Raw response from Supabase: \(rawString)")
            
            let data = response.data
            
            guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                logger.error("Failed to parse JSON as array: \(String(data: data, encoding: .utf8) ?? "Invalid UTF-8")")
                throw SupabaseError.fetchFailed("Invalid JSON array")
            }
            
            if jsonArray.isEmpty {
                logger.info("No messages found in the database")
                return []
            }
            
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            let messages = jsonArray.compactMap { (dict: [String: Any]) -> Message? in
                guard let id = dict["id"] as? String else { logger.error("Invalid or missing 'id' in: \(dict)"); return nil }
                guard let userId = dict["user_id"] as? String else { logger.error("Invalid or missing 'user_id' in: \(dict)"); return nil }
                guard let content = dict["content"] as? String else { logger.error("Invalid or missing 'content' in: \(dict)"); return nil }
                guard let createdAtString = dict["created_at"] as? String else { logger.error("Invalid or missing 'created_at' in: \(dict)"); return nil }
                guard let createdAt = isoFormatter.date(from: createdAtString) ?? ISO8601DateFormatter().date(from: createdAtString) else {
                    logger.error("Failed to parse 'created_at': \(createdAtString) in: \(dict)")
                    return nil
                }
                guard let updatedAtString = dict["updated_at"] as? String else { logger.error("Invalid or missing 'updated_at' in: \(dict)"); return nil }
                guard let updatedAt = isoFormatter.date(from: updatedAtString) ?? ISO8601DateFormatter().date(from: updatedAtString) else {
                    logger.error("Failed to parse 'updated_at': \(updatedAtString) in: \(dict)")
                    return nil
                }
                
                let isEdited = dict["is_edited"] as? Bool ?? false
                let profiles = dict["profiles"] as? [String: Any]
                let username = profiles?["username"] as? String
                logger.debug("Decoded message: id=\(id), userId=\(userId), username=\(username ?? "nil"), content=\(content), createdAt=\(createdAt), updatedAt=\(updatedAt)")
                return Message(id: id, userId: userId, username: username, content: content, createdAt: createdAt, isEdited: isEdited, updatedAt: updatedAt)
            }
            
            logger.info("Successfully decoded \(messages.count) messages from \(jsonArray.count) entries")
            return messages
        } catch {
            logger.error("Fetch error: \(error.localizedDescription)")
            throw SupabaseError.fetchFailed(error.localizedDescription)
        }
    }
    
    func sendMessage(_ message: Message) async throws {
        guard let currentUser = authService.currentUser else {
            throw SupabaseError.unauthorizedAccess("Must be logged in to send messages")
        }
        
        let currentDate = Date()
        let newMessage = MessageInsert(
            id: UUID().uuidString,
            userId: currentUser.id,
            content: message.content,
            isEdited: false,
            createdAt: currentDate,
            updatedAt: currentDate
        )
        
        do {
            _ = try await client
                .database
                .from(messagesTable)
                .insert(newMessage)
                .execute()
            logger.info("Message sent successfully: \(newMessage.content)")
        } catch {
            logger.error("Failed to send message: \(error.localizedDescription)")
            throw SupabaseError.insertFailed(error.localizedDescription)
        }
    }
    
    func deleteMessage(id: String) async throws {
        guard let currentUser = authService.currentUser else {
            throw SupabaseError.unauthorizedAccess("Must be logged in to delete messages")
        }
        
        do {
            _ = try await client
                .database
                .from(messagesTable)
                .delete()
                .eq("id", value: id)
                .eq("user_id", value: currentUser.id)
                .execute()
        } catch {
            logger.error("Failed to delete message: \(error.localizedDescription)")
            throw SupabaseError.deleteFailed(error.localizedDescription)
        }
    }
    
    func subscribeToMessages(onReceive: @escaping @Sendable (Message) -> Void) async throws {
        do {
            let channel = client.realtimeV2.channel("realtime:public:messages")
            
            channel.onStatusChange { (status: RealtimeChannelStatus) in // Fixed: Added type annotation
                self.logger.info("Channel status changed to: \(status)")
            }
            
            channel.onPostgresChange(
                InsertAction.self,
                schema: "public",
                table: messagesTable
            ) { action in
                let record = action.record
                self.logger.debug("Raw realtime payload: \(record)")
                if let newMessage = Message.fromSupabaseRow(record) {
                    self.logger.debug("Realtime insert detected: \(newMessage.id) - \(newMessage.content)")
                    onReceive(newMessage)
                } else {
                    self.logger.error("Failed to parse realtime record: \(record)")
                }
            }
            
            channel.onSystem { message in
                self.logger.info("Realtime system message: \(message.payload)")
            }
            
            self.messagesChannel = channel
            try await channel.subscribe()
            logger.info("Subscribed to realtime channel for \(self.messagesTable)")
        } catch {
            logger.error("Failed to subscribe to realtime updates: \(error.localizedDescription)")
            throw SupabaseError.realtimeSubscriptionFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Storage Operations
    
    func uploadAvatar(imageData: Data, fileExtension: String = "jpg") async throws -> String {
        guard let currentUser = authService.currentUser else {
            throw SupabaseError.unauthorizedAccess("Not authenticated")
        }
        
        let filename = "\(currentUser.id)_\(Date().timeIntervalSince1970).\(fileExtension)"
        
        do {
            let uploadResult = try await client.storage
                .from(avatarsBucket)
                .upload(
                    path: filename,
                    file: imageData,
                    options: .init(contentType: "image/\(fileExtension)")
                )
            
            let publicURL = try await client.storage
                .from(avatarsBucket)
                .getPublicURL(path: filename)
            
            logger.info("Avatar uploaded: \(publicURL)")
            
            try await updateUserAvatarUrl(userId: currentUser.id, avatarUrl: publicURL.absoluteString)
            
            return publicURL.absoluteString
        } catch {
            logger.error("Failed to upload avatar: \(error.localizedDescription)")
            throw SupabaseError.fileUploadFailed(error.localizedDescription)
        }
    }
    
    func getAvatarUrl(filename: String) async throws -> String {
        do {
            let publicURL = try await client.storage
                .from(avatarsBucket)
                .getPublicURL(path: filename)
            
            return publicURL.absoluteString
        } catch {
            logger.error("Failed to get avatar URL: \(error.localizedDescription)")
            throw SupabaseError.fileDownloadFailed(error.localizedDescription)
        }
    }
    
    func downloadAvatar(filename: String) async throws -> Data {
        do {
            let data = try await client.storage
                .from(avatarsBucket)
                .download(path: filename)
            
            return data
        } catch {
            logger.error("Failed to download avatar: \(error.localizedDescription)")
            throw SupabaseError.fileDownloadFailed(error.localizedDescription)
        }
    }
    
    private func deletePreviousAvatar(userId: String) async {
        do {
            let searchOptions = SearchOptions(
                limit: 100,
                offset: 0,
                sortBy: SortBy(column: "name", order: "asc")
            )
            
            let fileList = try await client.storage
                .from(avatarsBucket)
                .list(path: "", options: searchOptions)
            
            for file in fileList where file.name.hasPrefix("\(userId)_") {
                try? await client.storage
                    .from(avatarsBucket)
                    .remove(paths: [file.name])
                
                logger.info("Deleted old avatar: \(file.name)")
            }
        } catch {
            logger.warning("Failed to delete previous avatars: \(error.localizedDescription)")
        }
    }
    
    private func extractFilenameFromUrl(_ url: String) -> String? {
        return url.components(separatedBy: "/").last
    }
    
    // MARK: - User Profile Management
    
    func syncUserProfile() async throws {
        guard let currentUser = authService.currentUser else {
            throw SupabaseError.unauthorizedAccess("Not authenticated")
        }
        
        let userProfile = UserProfile(
            id: currentUser.id,
            username: currentUser.username,
            email: currentUser.email ?? "",
            avatarUrl: currentUser.avatarUrl,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        do {
            _ = try await client
                .database
                .from(usersTable)
                .upsert(userProfile)
                .execute()
        } catch {
            logger.error("Failed to sync user profile: \(error.localizedDescription)")
            throw SupabaseError.updateFailed(error.localizedDescription)
        }
    }
    
    private func updateUserAvatarUrl(userId: String, avatarUrl: String) async throws {
        do {
            _ = try await client
                .database
                .from(usersTable)
                .update(["avatar_url": avatarUrl, "updated_at": ISO8601DateFormatter().string(from: Date())])
                .eq("id", value: userId)
                .execute()
            
            logger.info("Updated user avatar URL")
        } catch {
            logger.error("Failed to update avatar URL: \(error.localizedDescription)")
            throw SupabaseError.updateFailed(error.localizedDescription)
        }
    }
    
    func getUserProfile(userId: String) async throws -> User {
        do {
            let response = try await client
                .database
                .from(usersTable)
                .select()
                .eq("id", value: userId)
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let user = try decoder.decode(User.self, from: response.data)
            return user
        } catch {
            logger.error("Failed to fetch user profile: \(error.localizedDescription)")
            throw SupabaseError.fetchFailed(error.localizedDescription)
        }
    }
    
    func updateUserWithNewAvatar(imageData: Data, fileExtension: String = "jpg") async throws -> User {
        guard let currentUser = authService.currentUser else {
            throw SupabaseError.unauthorizedAccess("Not authenticated")
        }
        
        await deletePreviousAvatar(userId: currentUser.id)
        
        let newAvatarUrl = try await uploadAvatar(imageData: imageData, fileExtension: fileExtension)
        
        return try await getUserProfile(userId: currentUser.id)
    }
}
