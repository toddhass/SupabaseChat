import SwiftUI

/// A view that displays the user's profile image
struct ProfileImageView: View {
    let user: User
    let size: CGFloat
    let supabaseService: SupabaseService
    
    @State private var avatarImage: UIImage? = nil
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    init(user: User, size: CGFloat = 40, supabaseService: SupabaseService) {
        self.user = user
        self.size = size
        self.supabaseService = supabaseService
    }
    
    var body: some View {
        ZStack {
            if let image = avatarImage {
                // Display the loaded image
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .transition(.opacity)
            } else if isLoading {
                // Show loading indicator
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: size, height: size)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.7)
                    )
            } else if let error = errorMessage {
                // Show error state with user initials
                Circle()
                    .fill(generateColor(from: user.id))
                    .frame(width: size, height: size)
                    .overlay(
                        Text(initials)
                            .font(.system(size: size * 0.4, weight: .medium))
                            .foregroundColor(.white)
                    )
            } else {
                // Show user initials as fallback
                Circle()
                    .fill(generateColor(from: user.id))
                    .frame(width: size, height: size)
                    .overlay(
                        Text(initials)
                            .font(.system(size: size * 0.4, weight: .medium))
                            .foregroundColor(.white)
                    )
            }
        }
        .onAppear {
            loadAvatar()
        }
        .onChange(of: user.avatarUrl) { _ in
            // Reload avatar if the URL changes
            loadAvatar()
        }
    }
    
    /// The user's initials
    private var initials: String {
        let components = user.username.components(separatedBy: .whitespacesAndNewlines)
        if components.count > 1, let first = components.first?.first, let last = components.last?.first {
            return "\(first)\(last)".uppercased()
        } else if let first = user.username.first {
            return String(first).uppercased()
        } else {
            return "?"
        }
    }
    
    /// Generate a consistent color based on the user ID
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
    
    /// Load the avatar image
    private func loadAvatar() {
        guard let avatarUrl = user.avatarUrl, !avatarUrl.isEmpty else {
            // No avatar URL, use initials instead
            return
        }
        
        // Check if it's a Supabase Storage URL
        let isSupabaseUrl = avatarUrl.contains("storage.googleapis.com") || 
                            avatarUrl.contains("supabase.co/storage/")
        
        isLoading = true
        errorMessage = nil
        
        if isSupabaseUrl {
            // If it's a Supabase URL, extract the filename and use the download method
            if let filename = extractFilenameFromUrl(avatarUrl) {
                Task {
                    do {
                        // Download the image data from Supabase Storage
                        let imageData = try await supabaseService.downloadAvatar(filename: filename)
                        if let image = UIImage(data: imageData) {
                            DispatchQueue.main.async {
                                withAnimation {
                                    self.avatarImage = image
                                    self.isLoading = false
                                }
                            }
                        } else {
                            handleError("Invalid image data")
                        }
                    } catch {
                        handleError(error.localizedDescription)
                    }
                }
            } else {
                handleError("Invalid avatar URL")
            }
        } else {
            // For other URLs, load directly
            loadExternalImage(from: avatarUrl)
        }
    }
    
    /// Load an image from an external URL
    private func loadExternalImage(from urlString: String) {
        guard let url = URL(string: urlString) else {
            handleError("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                handleError(error.localizedDescription)
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                handleError("Invalid image data")
                return
            }
            
            DispatchQueue.main.async {
                withAnimation {
                    self.avatarImage = image
                    self.isLoading = false
                }
            }
        }.resume()
    }
    
    /// Handle error states
    private func handleError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.isLoading = false
        }
    }
    
    /// Extract filename from a storage URL
    private func extractFilenameFromUrl(_ url: String) -> String? {
        return url.components(separatedBy: "/").last
    }
}

#if DEBUG
struct ProfileImageView_Previews: PreviewProvider {
    static var previews: some View {
        let mockUser = User(
            id: "user1",
            username: "Sarah Dev",
            email: "sarah@example.com", 
            avatarUrl: "https://ui-avatars.com/api/?name=Sarah&background=0D8ABC&color=fff"
        )
        
        return ProfileImageView(
            user: mockUser,
            supabaseService: SupabaseService(client: SupabaseClient(supabaseURL: "", supabaseKey: ""))
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
#endif