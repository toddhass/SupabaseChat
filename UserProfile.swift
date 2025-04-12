//
//  UserProfile.swift
//  SupabaseChat
//
//  Created by Todd Hassinger on 4/5/25.
//


struct UserProfile: Codable {
    let id: String
    let username: String
    let email: String
    let avatarUrl: String?
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, username, email
        case avatarUrl = "avatar_url"
        case updatedAt = "updated_at"
    }
}