import Foundation
import Supabase

struct Message: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let username: String?
    let content: String
    let createdAt: Date
    let isEdited: Bool
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case username
        case content
        case createdAt = "created_at"
        case isEdited = "is_edited"
        case updatedAt = "updated_at"
    }
    
    init(id: String, userId: String, username: String? = nil, content: String, createdAt: Date, isEdited: Bool = false, updatedAt: Date) {
        self.id = id
        self.userId = userId
        self.username = username
        self.content = content
        self.createdAt = createdAt
        self.isEdited = isEdited
        self.updatedAt = updatedAt
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func fromSupabaseRow(_ row: [String: Any]) -> Message? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // Base options
        
        guard
            let id = row["id"] as? String,
            let userId = row["user_id"] as? String,
            let content = row["content"] as? String,
            let createdAtString = row["created_at"] as? String,
            let createdAt = isoFormatter.date(from: createdAtString) ?? ISO8601DateFormatter().date(from: createdAtString),
            let updatedAtString = row["updated_at"] as? String,
            let updatedAt = isoFormatter.date(from: updatedAtString) ?? ISO8601DateFormatter().date(from: updatedAtString)
        else {
            return nil
        }
        let isEdited = row["is_edited"] as? Bool ?? false
        let username = row["username"] as? String // Nil for real-time
        return Message(id: id, userId: userId, username: username, content: content, createdAt: createdAt, isEdited: isEdited, updatedAt: updatedAt)
    }
}
