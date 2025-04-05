import Foundation
import Supabase
import Combine
import OSLog

// Define custom errors
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
        case .fetchFailed(let reason):
            return "Failed to fetch data: \(reason)"
        case .insertFailed(let reason):
            return "Failed to insert data: \(reason)"
        case .updateFailed(let reason):
            return "Failed to update data: \(reason)"
        case .deleteFailed(let reason):
            return "Failed to delete data: \(reason)"
        case .invalidData(let reason):
            return "Invalid data: \(reason)"
        case .realtimeSubscriptionFailed(let reason):
            return "Failed to subscribe to real-time updates: \(reason)"
        case .unauthorizedAccess(let reason):
            return "Unauthorized access: \(reason)"
        case .storageFailed(let reason):
            return "Storage operation failed: \(reason)"
        case .fileUploadFailed(let reason):
            return "Failed to upload file: \(reason)"
        case .fileDownloadFailed(let reason):
            return "Failed to download file: \(reason)"
        }
    }
}

class SupabaseService {
    private let client: SupabaseClient
    private let logger = Logger(subsystem: "com.supachat.app", category: "SupabaseService")
    
    // Table names
    private let messagesTable = "messages"
    private let usersTable = "profiles"
    
    // Storage bucket names
    private let avatarsBucket = "avatars"
    
    // Auth service
    private(set) var authService: AuthenticationService
    
    init(client: SupabaseClient) {
        self.client = client
        self.authService = AuthenticationService(client: client)
        
        // Initialize storage buckets if needed
        Task {
            do {
                try await setupStorageBuckets()
            } catch {
                logger.error("Failed to setup storage buckets: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Storage Setup
    
    private func setupStorageBuckets() async throws {
        do {
            // Check if the avatars bucket exists, if not create it
            do {
                _ = try await client.storage.getBucket(id: avatarsBucket)
                logger.info("Avatars bucket exists")
            } catch {
                // Bucket doesn't exist, create it
                logger.info("Creating avatars bucket")
                try await client.storage.createBucket(
                    id: avatarsBucket,
                    options: .init(public: true) // Public bucket for avatar access
                )
            }
        } catch {
            logger.error("Storage setup failed: \(error.localizedDescription)")
            throw SupabaseError.storageFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Messages
    
    // Fetch all messages
    func fetchMessages() async throws -> [Message] {
        do {
            let response = try await client
                .database
                .from(messagesTable)
                .select()
                .order("created_at", ascending: true)
                .execute()
            
            guard let data = response.data else {
                throw SupabaseError.fetchFailed("No data returned")
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let messages = try decoder.decode([Message].self, from: data)
            return messages
        } catch {
            logger.error("Failed to fetch messages: \(error.localizedDescription)")
            throw SupabaseError.fetchFailed(error.localizedDescription)
        }
    }
    
    // Send a new message
    func sendMessage(_ message: Message) async throws {
        // Ensure the user is authenticated
        guard let currentUser = authService.currentUser else {
            throw SupabaseError.unauthorizedAccess("Must be logged in to send messages")
        }
        
        // Create a message with the current user's ID
        var updatedMessage = message
        if updatedMessage.userId == nil {
            // Create a new message with the user ID included
            updatedMessage = Message(
                id: message.id,
                userId: currentUser.id, // Include the user ID
                username: message.username,
                content: message.content,
                createdAt: message.createdAt
            )
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        guard let encodedMessage = try? encoder.encode(updatedMessage) else {
            throw SupabaseError.invalidData("Failed to encode message")
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: encodedMessage) as? [String: Any] else {
            throw SupabaseError.invalidData("Failed to convert message to JSON")
        }
        
        do {
            _ = try await client
                .database
                .from(messagesTable)
                .insert(values: json)
                .execute()
        } catch {
            logger.error("Failed to send message: \(error.localizedDescription)")
            throw SupabaseError.insertFailed(error.localizedDescription)
        }
    }
    
    // Delete a message (only your own messages)
    func deleteMessage(id: String) async throws {
        // Ensure the user is authenticated
        guard let currentUser = authService.currentUser else {
            throw SupabaseError.unauthorizedAccess("Must be logged in to delete messages")
        }
        
        do {
            _ = try await client
                .database
                .from(messagesTable)
                .delete()
                .eq("id", value: id)
                .eq("user_id", value: currentUser.id) // Ensure only deleting own messages
                .execute()
        } catch {
            logger.error("Failed to delete message: \(error.localizedDescription)")
            throw SupabaseError.deleteFailed(error.localizedDescription)
        }
    }
    
    // Subscribe to realtime updates
    func subscribeToMessages(onReceive: @escaping (Message) -> Void) async throws {
        do {
            try await client.realtime.channel("public:\(messagesTable)")
                .on(.all, tableName: messagesTable) { payload in
                    switch payload.eventType {
                    case .insert:
                        if let record = payload.newRecord,
                           let message = Message.fromSupabaseRow(record) {
                            onReceive(message)
                        }
                    // Can handle update and delete events here as well
                    default:
                        break
                    }
                }
                .subscribe()
        } catch {
            logger.error("Failed to subscribe to realtime updates: \(error.localizedDescription)")
            throw SupabaseError.realtimeSubscriptionFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Storage Operations
    
    /// Upload an avatar image for the current user
    /// - Parameters:
    ///   - imageData: The image data to upload
    ///   - fileExtension: The file extension (jpg, png, etc.)
    /// - Returns: The URL of the uploaded avatar
    func uploadAvatar(imageData: Data, fileExtension: String = "jpg") async throws -> String {
        // Ensure the user is authenticated
        guard let currentUser = authService.currentUser else {
            throw SupabaseError.unauthorizedAccess("Not authenticated")
        }
        
        // Create a unique filename for the avatar
        let filename = "\(currentUser.id)_\(Date().timeIntervalSince1970).\(fileExtension)"
        
        do {
            // Upload the file to the avatars bucket
            let uploadResult = try await client.storage
                .from(avatarsBucket)
                .upload(
                    path: filename,
                    file: imageData,
                    options: .init(contentType: "image/\(fileExtension)")
                )
            
            // Get the public URL for the uploaded file
            let publicURL = try await client.storage
                .from(avatarsBucket)
                .getPublicURL(path: filename)
            
            logger.info("Avatar uploaded: \(publicURL)")
            
            // Update the user's avatar URL in the database
            try await updateUserAvatarUrl(userId: currentUser.id, avatarUrl: publicURL)
            
            return publicURL
        } catch {
            logger.error("Failed to upload avatar: \(error.localizedDescription)")
            throw SupabaseError.fileUploadFailed(error.localizedDescription)
        }
    }
    
    /// Get the public URL for an avatar by filename
    /// - Parameter filename: The filename of the avatar
    /// - Returns: The public URL of the avatar
    func getAvatarUrl(filename: String) async throws -> String {
        do {
            let publicURL = try await client.storage
                .from(avatarsBucket)
                .getPublicURL(path: filename)
            
            return publicURL
        } catch {
            logger.error("Failed to get avatar URL: \(error.localizedDescription)")
            throw SupabaseError.fileDownloadFailed(error.localizedDescription)
        }
    }
    
    /// Download an avatar image by filename
    /// - Parameter filename: The filename of the avatar
    /// - Returns: The image data
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
    
    /// Delete a user's previous avatar if it exists
    /// - Parameter userId: The user ID
    private func deletePreviousAvatar(userId: String) async {
        do {
            // List files in the avatars bucket that start with the user's ID
            let fileList = try await client.storage
                .from(avatarsBucket)
                .list(path: "", searchOptions: .init(prefix: "\(userId)_"))
            
            // Delete any found files (old avatars)
            for file in fileList {
                try? await client.storage
                    .from(avatarsBucket)
                    .remove(paths: [file.name])
                
                logger.info("Deleted old avatar: \(file.name)")
            }
        } catch {
            logger.warning("Failed to delete previous avatars: \(error.localizedDescription)")
            // Non-critical error, so we just log it
        }
    }
    
    /// Extract filename from a storage URL
    /// - Parameter url: The full storage URL
    /// - Returns: The filename
    private func extractFilenameFromUrl(_ url: String) -> String? {
        return url.components(separatedBy: "/").last
    }
    
    // MARK: - User Profile Management
    
    /// Create/update user profile after authentication
    func syncUserProfile() async throws {
        guard let currentUser = authService.currentUser else {
            throw SupabaseError.unauthorizedAccess("Not authenticated")
        }
        
        let userProfile: [String: Any] = [
            "id": currentUser.id,
            "username": currentUser.username,
            "email": currentUser.email ?? "",
            "avatar_url": currentUser.avatarUrl ?? "",
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        do {
            _ = try await client
                .database
                .from(usersTable)
                .upsert(values: userProfile)
                .execute()
        } catch {
            logger.error("Failed to sync user profile: \(error.localizedDescription)")
            throw SupabaseError.updateFailed(error.localizedDescription)
        }
    }
    
    /// Update just the avatar URL for a user
    /// - Parameters:
    ///   - userId: The user ID
    ///   - avatarUrl: The new avatar URL
    private func updateUserAvatarUrl(userId: String, avatarUrl: String) async throws {
        do {
            _ = try await client
                .database
                .from(usersTable)
                .update(values: ["avatar_url": avatarUrl, "updated_at": ISO8601DateFormatter().string(from: Date())])
                .eq("id", value: userId)
                .execute()
            
            logger.info("Updated user avatar URL")
        } catch {
            logger.error("Failed to update avatar URL: \(error.localizedDescription)")
            throw SupabaseError.updateFailed(error.localizedDescription)
        }
    }
    
    /// Get user profile by ID
    /// - Parameter userId: The user ID
    /// - Returns: The user profile
    func getUserProfile(userId: String) async throws -> User {
        do {
            let response = try await client
                .database
                .from(usersTable)
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
            
            guard let data = response.data else {
                throw SupabaseError.fetchFailed("No user profile found")
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let user = try decoder.decode(User.self, from: data)
            return user
        } catch {
            logger.error("Failed to fetch user profile: \(error.localizedDescription)")
            throw SupabaseError.fetchFailed(error.localizedDescription)
        }
    }
    
    /// Update user profile with a new avatar image
    /// - Parameters:
    ///   - imageData: The new avatar image data
    ///   - fileExtension: The file extension (jpg, png, etc.)
    /// - Returns: The updated user profile
    func updateUserWithNewAvatar(imageData: Data, fileExtension: String = "jpg") async throws -> User {
        guard let currentUser = authService.currentUser else {
            throw SupabaseError.unauthorizedAccess("Not authenticated")
        }
        
        // Delete previous avatar if any
        await deletePreviousAvatar(userId: currentUser.id)
        
        // Upload new avatar
        let newAvatarUrl = try await uploadAvatar(imageData: imageData, fileExtension: fileExtension)
        
        // Get updated user profile
        return try await getUserProfile(userId: currentUser.id)
    }
}
