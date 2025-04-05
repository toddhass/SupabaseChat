import Foundation

struct Message: Identifiable, Codable, Equatable {
    let id: String
    let userId: String? // User ID for linking to profile
    let username: String
    let content: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case username
        case content
        case createdAt = "created_at"
    }
    
    init(id: String, userId: String? = nil, username: String, content: String, createdAt: Date) {
        self.id = id
        self.userId = userId
        self.username = username
        self.content = content
        self.createdAt = createdAt
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Message {
    // Helper function to create a Message from Supabase response
    static func fromSupabaseRow(_ row: [String: Any]) -> Message? {
        guard 
            let id = row["id"] as? String,
            let username = row["username"] as? String,
            let content = row["content"] as? String,
            let createdAtString = row["created_at"] as? String,
            let createdAt = ISO8601DateFormatter().date(from: createdAtString)
        else {
            return nil
        }
        
        // User ID could be nil in older messages
        let userId = row["user_id"] as? String
        
        return Message(
            id: id,
            userId: userId,
            username: username,
            content: content,
            createdAt: createdAt
        )
    }
}
