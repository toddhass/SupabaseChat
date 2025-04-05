import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: String
    let username: String
    let email: String?
    let avatarUrl: String?
    let createdAt: Date?
    let lastSignInAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case lastSignInAt = "last_sign_in_at"
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(id: String, username: String, email: String? = nil, avatarUrl: String? = nil, createdAt: Date? = nil, lastSignInAt: Date? = nil) {
        self.id = id
        self.username = username
        self.email = email
        self.avatarUrl = avatarUrl
        self.createdAt = createdAt
        self.lastSignInAt = lastSignInAt
    }
    
    // Helper function to create a User from Supabase Auth Session data
    static func fromSession(_ session: Session) -> User? {
        guard let user = session.user else { return nil }
        
        // Try to get the username from metadata or use email as fallback
        let username = user.userMetadata?["username"] as? String ?? user.email?.components(separatedBy: "@").first ?? "Unknown User"
        
        return User(
            id: user.id.uuidString,
            username: username,
            email: user.email,
            avatarUrl: user.userMetadata?["avatar_url"] as? String,
            createdAt: user.createdAt,
            lastSignInAt: user.lastSignInAt
        )
    }
}

// Session model to match Supabase Auth Session
struct Session: Codable {
    let accessToken: String
    let refreshToken: String
    let user: AuthUser?
    let expiresAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
        case expiresAt = "expires_at"
    }
}

// AuthUser model to match Supabase Auth User
struct AuthUser: Codable {
    let id: UUID
    let email: String?
    let userMetadata: [String: Any]?
    let createdAt: Date?
    let lastSignInAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case userMetadata = "user_metadata"
        case createdAt = "created_at"
        case lastSignInAt = "last_sign_in_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        lastSignInAt = try container.decodeIfPresent(Date.self, forKey: .lastSignInAt)
        
        // Decode userMetadata dictionary
        if let metadataData = try container.decodeIfPresent(Data.self, forKey: .userMetadata) {
            userMetadata = try JSONSerialization.jsonObject(with: metadataData) as? [String: Any]
        } else {
            userMetadata = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(lastSignInAt, forKey: .lastSignInAt)
        
        // Encode userMetadata dictionary if it exists
        if let metadata = userMetadata, 
           let metadataData = try? JSONSerialization.data(withJSONObject: metadata) {
            try container.encode(metadataData, forKey: .userMetadata)
        }
    }
}
