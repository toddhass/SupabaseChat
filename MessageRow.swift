import SwiftUI
import Supabase

struct MessageRow: View {
    let message: Message
    let isCurrentUser: Bool
    let isLoading: Bool
    @EnvironmentObject private var supabaseService: SupabaseService
    
    @State private var userProfile: User?
    @State private var isLoadingProfile = false
    
    init(message: Message, isCurrentUser: Bool, isLoading: Bool = false) {
        self.message = message
        self.isCurrentUser = isCurrentUser
        self.isLoading = isLoading
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if !isCurrentUser {
                if let user = userProfile {
                    ProfileImageView(user: user, size: 36, supabaseService: supabaseService)
                } else if isLoadingProfile {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 36, height: 36)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.6)
                        )
                } else {
                    Circle()
                        .fill(generateColor(from: message.userId)) // userId is non-optional
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(getInitials(from: message.username ?? "Unknown"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        )
                }
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                HStack(alignment: .bottom, spacing: 4) {
                    if !isCurrentUser {
                        Text(message.username ?? "Unknown")
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
                
                Text(isLoading ? "Sending..." : message.createdAt.formatted()) // Line 65: Removed ?.
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .opacity(isLoading ? 0.7 : 1.0)
            }
            
            if isCurrentUser {
                if let currentUser = supabaseService.authService.currentUser {
                    ProfileImageView(user: currentUser, size: 36, supabaseService: supabaseService)
                } else {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(getInitials(from: message.username ?? "Unknown")) // Line 102: Replaced ! with ??
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
    
    private func loadUserProfile() {
        if isCurrentUser || message.userId.isEmpty { // userId is String, not optional
            return
        }
        
        isLoadingProfile = true
        
        Task {
            do {
                let profile = try await supabaseService.getUserProfile(userId: message.userId)
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
    
    private func generateColor(from string: String) -> Color {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .teal, .indigo]
        var hash = 0
        for char in string {
            hash = (hash &* 31) &+ Int(char.asciiValue ?? 0)
        }
        let index = abs(hash) % colors.count
        return colors[index]
    }
}

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
                    userId: "user1",
                    username: "John",
                    content: "Hello, how are you?",
                    createdAt: Date(),
                    isEdited: false,
                    updatedAt: Date()
                ),
                isCurrentUser: false
            )
            
            MessageRow(
                message: Message(
                    id: "2",
                    userId: "user2",
                    username: "Me",
                    content: "I'm good, thanks for asking!",
                    createdAt: Date(),
                    isEdited: false,
                    updatedAt: Date()
                ),
                isCurrentUser: true
            )
            
            MessageRow(
                message: Message(
                    id: "3",
                    userId: "user2",
                    username: "Me",
                    content: "Sending a new message...",
                    createdAt: Date(),
                    isEdited: false,
                    updatedAt: Date()
                ),
                isCurrentUser: true,
                isLoading: true
            )
        }
        .padding()
        .environmentObject(SupabaseService(client: SupabaseClient(supabaseURL: URL(string: "your-url")!, supabaseKey: "your-key")))
    }
}
