import SwiftUI

struct MessageRow: View {
    let message: Message
    let isCurrentUser: Bool
    let isLoading: Bool
    @EnvironmentObject private var supabaseService: SupabaseService
    
    // User profile for avatar display
    @State private var userProfile: User?
    @State private var isLoadingProfile = false
    
    // Initialize with default isLoading = false for backward compatibility
    init(message: Message, isCurrentUser: Bool, isLoading: Bool = false) {
        self.message = message
        self.isCurrentUser = isCurrentUser
        self.isLoading = isLoading
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Show avatar for other users (not current user)
            if !isCurrentUser {
                // User avatar
                if let user = userProfile {
                    ProfileImageView(user: user, size: 36, supabaseService: supabaseService)
                } else if isLoadingProfile {
                    // Loading avatar
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 36, height: 36)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.6)
                        )
                } else {
                    // Default avatar with auto-generated color based on user ID
                    Circle()
                        .fill(generateColor(from: message.userId ?? "unknown"))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(getInitials(from: message.username))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        )
                }
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                HStack(alignment: .bottom, spacing: 4) {
                    if !isCurrentUser {
                        Text(message.username)
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    
                    if isLoading {
                        LoadingBubble(isCurrentUser: isCurrentUser)
                    } else {
                        Text(message.content)
                            .padding(10)
                            .background(isCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(isCurrentUser ? .white : .primary)
                            .cornerRadius(16)
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: message.id)
                    }
                }
                
                Text(isLoading ? "Sending..." : message.createdAt.formatted())
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .opacity(isLoading ? 0.7 : 1.0)
            }
            
            // Add avatar for current user at the end
            if isCurrentUser {
                if let currentUser = supabaseService.authService.currentUser {
                    ProfileImageView(user: currentUser, size: 36, supabaseService: supabaseService)
                } else {
                    // Default avatar for current user
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(getInitials(from: message.username))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        )
                }
            }
        }
        .padding(.vertical, 4)
        .id(message.id)
        .onAppear {
            loadUserProfile()
        }
    }
    
    // Load the user profile for avatar display
    private func loadUserProfile() {
        // Skip for current user as we already have their profile
        if isCurrentUser || message.userId == nil {
            return
        }
        
        isLoadingProfile = true
        
        Task {
            do {
                let profile = try await supabaseService.getUserProfile(userId: message.userId!)
                await MainActor.run {
                    userProfile = profile
                    isLoadingProfile = false
                }
            } catch {
                print("Failed to load user profile: \(error.localizedDescription)")
                await MainActor.run {
                    isLoadingProfile = false
                }
            }
        }
    }
    
    // Get initials from username
    private func getInitials(from name: String) -> String {
        let components = name.components(separatedBy: .whitespacesAndNewlines)
        if components.count > 1, let first = components.first?.first, let last = components.last?.first {
            return "\(first)\(last)".uppercased()
        } else if let first = name.first {
            return String(first).uppercased()
        } else {
            return "?"
        }
    }
    
    // Generate a consistent color based on user ID
    private func generateColor(from string: String) -> Color {
        let colors: [Color] = [
            .blue, .purple, .pink, .orange, .green, .teal, .indigo
        ]
        
        // Generate a consistent index based on the string hash
        var hash = 0
        for char in string {
            hash = (hash &* 31) &+ Int(char.asciiValue ?? 0)
        }
        let index = abs(hash) % colors.count
        
        return colors[index]
    }
}

// Animated loading bubble for messages being sent
struct LoadingBubble: View {
    let isCurrentUser: Bool
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(isCurrentUser ? Color.blue.opacity(0.8) : Color.gray.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? (index == 1 ? 1.2 : (index == 0 ? 0.8 : 0.8)) : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isCurrentUser ? Color.blue.opacity(0.3) : Color.gray.opacity(0.15))
        .cornerRadius(16)
        .onAppear {
            isAnimating = true
        }
    }
}

// Bounce animation effect
struct BounceEffect: GeometryEffect {
    var time: Double
    var bounceHeight: Double
    
    var animatableData: Double {
        get { time }
        set { time = newValue }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        let bounce = sin(time * .pi * 2) * bounceHeight
        return ProjectionTransform(CGAffineTransform(translationX: 0, y: bounce))
    }
}

struct MessageRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MessageRow(
                message: Message(
                    id: "1",
                    username: "John",
                    content: "Hello, how are you?",
                    createdAt: Date()
                ),
                isCurrentUser: false
            )
            
            MessageRow(
                message: Message(
                    id: "2",
                    username: "Me",
                    content: "I'm good, thanks for asking!",
                    createdAt: Date()
                ),
                isCurrentUser: true
            )
            
            MessageRow(
                message: Message(
                    id: "3",
                    username: "Me",
                    content: "Sending a new message...",
                    createdAt: Date()
                ),
                isCurrentUser: true,
                isLoading: true
            )
        }
        .padding()
    }
}
