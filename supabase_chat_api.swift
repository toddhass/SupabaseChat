import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Models

struct Profile: Codable {
    let id: String
    let username: String
    let displayName: String?
    let avatarUrl: String?
    let status: String
    let lastSeen: Date
    
    enum CodingKeys: String, CodingKey {
        case id, username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case status
        case lastSeen = "last_seen"
    }
}

struct Message: Codable {
    let id: String
    let userId: String
    let content: String
    let isEdited: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case content
        case isEdited = "is_edited"
        case createdAt = "created_at"
    }
}

struct Channel: Codable {
    let id: String
    let name: String
    let description: String?
    let isPrivate: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case isPrivate = "is_private"
    }
}

// MARK: - SupabaseChatService

class SupabaseChatService {
    private let baseUrl: String
    private let apiKey: String
    private var authToken: String?
    
    init() {
        // Get credentials from environment variables
        self.baseUrl = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
        self.apiKey = ProcessInfo.processInfo.environment["SUPABASE_KEY"] ?? ""
        
        if baseUrl.isEmpty || apiKey.isEmpty {
            print("⚠️ Error: SUPABASE_URL or SUPABASE_KEY environment variables are not set")
        }
    }
    
    // MARK: - Authentication
    
    func signUp(email: String, password: String, username: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(baseUrl)/auth/v1/signup") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "data": [
                "username": username
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -2, userInfo: nil)))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                completion(.failure(NSError(domain: "Error \(httpResponse.statusCode)", code: httpResponse.statusCode, userInfo: nil)))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let user = json["user"] as? [String: Any],
                   let id = user["id"] as? String {
                    completion(.success(id))
                } else {
                    completion(.failure(NSError(domain: "Invalid response format", code: -3, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func signIn(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(baseUrl)/auth/v1/token?grant_type=password") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -2, userInfo: nil)))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                completion(.failure(NSError(domain: "Error \(httpResponse.statusCode)", code: httpResponse.statusCode, userInfo: nil)))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let accessToken = json["access_token"] as? String,
                   let user = json["user"] as? [String: Any],
                   let id = user["id"] as? String {
                    self.authToken = accessToken
                    completion(.success(id))
                } else {
                    completion(.failure(NSError(domain: "Invalid response format", code: -3, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // MARK: - Profile Management
    
    func getProfile(userId: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        guard let url = URL(string: "\(baseUrl)/rest/v1/profiles?id=eq.\(userId)&select=*") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        
        if let token = authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -2, userInfo: nil)))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                completion(.failure(NSError(domain: "Error \(httpResponse.statusCode)", code: httpResponse.statusCode, userInfo: nil)))
                return
            }
            
            do {
                // The response is an array, so we need to get the first item
                let decoder = JSONDecoder()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                
                let profiles = try decoder.decode([Profile].self, from: data)
                if let profile = profiles.first {
                    completion(.success(profile))
                } else {
                    completion(.failure(NSError(domain: "Profile not found", code: -4, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func updateProfile(userId: String, displayName: String?, avatarUrl: String?, completion: @escaping (Bool, Error?) -> Void) {
        guard let url = URL(string: "\(baseUrl)/rest/v1/profiles?id=eq.\(userId)") else {
            completion(false, NSError(domain: "Invalid URL", code: -1, userInfo: nil))
            return
        }
        
        guard let token = authToken else {
            completion(false, NSError(domain: "Not authenticated", code: -3, userInfo: nil))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("return=minimal", forHTTPHeaderField: "Prefer")
        
        var body: [String: Any] = [:]
        if let displayName = displayName {
            body["display_name"] = displayName
        }
        if let avatarUrl = avatarUrl {
            body["avatar_url"] = avatarUrl
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(false, error)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                completion(true, nil)
            } else {
                completion(false, NSError(domain: "Update failed", code: -4, userInfo: nil))
            }
        }
        
        task.resume()
    }
    
    // MARK: - Messaging
    
    func sendMessage(channelId: String, content: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let token = authToken else {
            completion(.failure(NSError(domain: "Not authenticated", code: -3, userInfo: nil)))
            return
        }
        
        // First create the message
        guard let messagesUrl = URL(string: "\(baseUrl)/rest/v1/messages") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var messageRequest = URLRequest(url: messagesUrl)
        messageRequest.httpMethod = "POST"
        messageRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        messageRequest.addValue(apiKey, forHTTPHeaderField: "apikey")
        messageRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        messageRequest.addValue("return=representation", forHTTPHeaderField: "Prefer")
        
        let messageBody: [String: Any] = [
            "content": content
        ]
        
        do {
            messageRequest.httpBody = try JSONSerialization.data(withJSONObject: messageBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        let messageTask = URLSession.shared.dataTask(with: messageRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -2, userInfo: nil)))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                completion(.failure(NSError(domain: "Error \(httpResponse.statusCode)", code: httpResponse.statusCode, userInfo: nil)))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   let messageData = json.first,
                   let messageId = messageData["id"] as? String {
                    
                    // Now link the message to the channel
                    guard let channelMessageUrl = URL(string: "\(self.baseUrl)/rest/v1/channel_messages") else {
                        completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
                        return
                    }
                    
                    var channelMessageRequest = URLRequest(url: channelMessageUrl)
                    channelMessageRequest.httpMethod = "POST"
                    channelMessageRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    channelMessageRequest.addValue(self.apiKey, forHTTPHeaderField: "apikey")
                    channelMessageRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    
                    let channelMessageBody: [String: Any] = [
                        "channel_id": channelId,
                        "message_id": messageId
                    ]
                    
                    do {
                        channelMessageRequest.httpBody = try JSONSerialization.data(withJSONObject: channelMessageBody)
                    } catch {
                        completion(.failure(error))
                        return
                    }
                    
                    let channelMessageTask = URLSession.shared.dataTask(with: channelMessageRequest) { data, response, error in
                        if let error = error {
                            completion(.failure(error))
                            return
                        }
                        
                        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                            completion(.success(messageId))
                        } else {
                            completion(.failure(NSError(domain: "Failed to link message to channel", code: -5, userInfo: nil)))
                        }
                    }
                    
                    channelMessageTask.resume()
                } else {
                    completion(.failure(NSError(domain: "Invalid response format", code: -3, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        messageTask.resume()
    }
    
    func getChannelMessages(channelId: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        guard let url = URL(string: "\(baseUrl)/rest/v1/channel_messages?channel_id=eq.\(channelId)&select=messages(*)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        
        if let token = authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -2, userInfo: nil)))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                completion(.failure(NSError(domain: "Error \(httpResponse.statusCode)", code: httpResponse.statusCode, userInfo: nil)))
                return
            }
            
            do {
                struct ChannelMessageResponse: Codable {
                    let messages: Message
                }
                
                let decoder = JSONDecoder()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                
                let channelMessages = try decoder.decode([ChannelMessageResponse].self, from: data)
                let messages = channelMessages.map { $0.messages }
                completion(.success(messages))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // MARK: - Channels
    
    func getChannels(completion: @escaping (Result<[Channel], Error>) -> Void) {
        guard let url = URL(string: "\(baseUrl)/rest/v1/channels?select=*") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        
        if let token = authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -2, userInfo: nil)))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                completion(.failure(NSError(domain: "Error \(httpResponse.statusCode)", code: httpResponse.statusCode, userInfo: nil)))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let channels = try decoder.decode([Channel].self, from: data)
                completion(.success(channels))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func createChannel(name: String, description: String?, isPrivate: Bool, completion: @escaping (Result<String, Error>) -> Void) {
        guard let token = authToken else {
            completion(.failure(NSError(domain: "Not authenticated", code: -3, userInfo: nil)))
            return
        }
        
        guard let url = URL(string: "\(baseUrl)/rest/v1/channels") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("return=representation", forHTTPHeaderField: "Prefer")
        
        var body: [String: Any] = [
            "name": name,
            "is_private": isPrivate
        ]
        
        if let description = description {
            body["description"] = description
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -2, userInfo: nil)))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                completion(.failure(NSError(domain: "Error \(httpResponse.statusCode)", code: httpResponse.statusCode, userInfo: nil)))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   let channelData = json.first,
                   let channelId = channelData["id"] as? String {
                    completion(.success(channelId))
                } else {
                    completion(.failure(NSError(domain: "Invalid response format", code: -3, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // MARK: - User Status
    
    func updateUserStatus(isOnline: Bool, completion: @escaping (Bool, Error?) -> Void) {
        guard let token = authToken else {
            completion(false, NSError(domain: "Not authenticated", code: -3, userInfo: nil))
            return
        }
        
        guard let url = URL(string: "\(baseUrl)/rest/v1/user_status?id=eq.CURRENT_USER") else {
            completion(false, NSError(domain: "Invalid URL", code: -1, userInfo: nil))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("return=minimal", forHTTPHeaderField: "Prefer")
        
        let body: [String: Any] = [
            "is_online": isOnline,
            "last_status_change": ISO8601DateFormatter().string(from: Date())
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(false, error)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                completion(true, nil)
            } else {
                completion(false, NSError(domain: "Update failed", code: -4, userInfo: nil))
            }
        }
        
        task.resume()
    }
}

// MARK: - Example usage

func runChatServiceDemo() {
    let chatService = SupabaseChatService()
    let semaphore = DispatchSemaphore(value: 0)
    
    print("=== SupabaseChat API Demo ===")
    
    // Sign up a new user
    let randomInt = Int.random(in: 1000...9999)
    let testEmail = "user\(randomInt)@example.com"
    let testPassword = "Test123!"
    let testUsername = "testuser\(randomInt)"
    
    print("1. Creating a new user: \(testUsername)")
    chatService.signUp(email: testEmail, password: testPassword, username: testUsername) { result in
        switch result {
        case .success(let userId):
            print("✅ User created with ID: \(userId)")
            
            // Sign in with the new user
            print("\n2. Signing in with the new user")
            chatService.signIn(email: testEmail, password: testPassword) { result in
                switch result {
                case .success(let userId):
                    print("✅ Signed in as user ID: \(userId)")
                    
                    // Get user profile
                    print("\n3. Fetching user profile")
                    chatService.getProfile(userId: userId) { result in
                        switch result {
                        case .success(let profile):
                            print("✅ Profile fetched:")
                            print("  Username: \(profile.username)")
                            print("  Status: \(profile.status)")
                            
                            // Update profile
                            print("\n4. Updating user profile with a display name")
                            chatService.updateProfile(userId: userId, displayName: "Test User \(randomInt)", avatarUrl: nil) { success, error in
                                if success {
                                    print("✅ Profile updated successfully")
                                    
                                    // Create a channel
                                    print("\n5. Creating a new chat channel")
                                    chatService.createChannel(name: "test-channel-\(randomInt)", description: "Test channel created by demo", isPrivate: false) { result in
                                        switch result {
                                        case .success(let channelId):
                                            print("✅ Channel created with ID: \(channelId)")
                                            
                                            // Send a message to the channel
                                            print("\n6. Sending a message to the channel")
                                            chatService.sendMessage(channelId: channelId, content: "Hello from the Swift API demo!") { result in
                                                switch result {
                                                case .success(let messageId):
                                                    print("✅ Message sent with ID: \(messageId)")
                                                    
                                                    // Get all channels
                                                    print("\n7. Fetching all channels")
                                                    chatService.getChannels { result in
                                                        switch result {
                                                        case .success(let channels):
                                                            print("✅ Fetched \(channels.count) channels:")
                                                            for channel in channels {
                                                                print("  - \(channel.name): \(channel.description ?? "No description")")
                                                            }
                                                            
                                                            // Update user status
                                                            print("\n8. Updating user status to online")
                                                            chatService.updateUserStatus(isOnline: true) { success, error in
                                                                if success {
                                                                    print("✅ User status updated to online")
                                                                } else if let error = error {
                                                                    print("❌ Failed to update status: \(error.localizedDescription)")
                                                                }
                                                                
                                                                print("\nDemo completed successfully!")
                                                                semaphore.signal()
                                                            }
                                                            
                                                        case .failure(let error):
                                                            print("❌ Failed to fetch channels: \(error.localizedDescription)")
                                                            semaphore.signal()
                                                        }
                                                    }
                                                    
                                                case .failure(let error):
                                                    print("❌ Failed to send message: \(error.localizedDescription)")
                                                    semaphore.signal()
                                                }
                                            }
                                            
                                        case .failure(let error):
                                            print("❌ Failed to create channel: \(error.localizedDescription)")
                                            semaphore.signal()
                                        }
                                    }
                                    
                                } else if let error = error {
                                    print("❌ Failed to update profile: \(error.localizedDescription)")
                                    semaphore.signal()
                                }
                            }
                            
                        case .failure(let error):
                            print("❌ Failed to fetch profile: \(error.localizedDescription)")
                            semaphore.signal()
                        }
                    }
                    
                case .failure(let error):
                    print("❌ Failed to sign in: \(error.localizedDescription)")
                    semaphore.signal()
                }
            }
            
        case .failure(let error):
            print("❌ Failed to create user: \(error.localizedDescription)")
            
            // Try signing in instead
            print("\nAttempting to sign in with existing credentials")
            chatService.signIn(email: testEmail, password: testPassword) { result in
                switch result {
                case .success(let userId):
                    print("✅ Signed in as existing user: \(userId)")
                case .failure(let error):
                    print("❌ Sign-in also failed: \(error.localizedDescription)")
                }
                semaphore.signal()
            }
        }
    }
    
    // Wait for all operations to complete
    semaphore.wait()
}

// Run the demo
runChatServiceDemo()