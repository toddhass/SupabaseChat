import Foundation
import Supabase
import Combine
import OSLog

enum AuthError: Error {
    case signUpFailed(String)
    case signInFailed(String)
    case signOutFailed(String)
    case notAuthenticated
    case sessionExpired
    case refreshFailed(String)
}

class AuthenticationService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var authError: String?
    
    private let client: SupabaseClient
    private let logger = Logger(subsystem: "com.supachat.app", category: "AuthenticationService")
    
    // Access to user info
    private(set) var session: Session?
    
    init(client: SupabaseClient) {
        self.client = client
        
        // Try to restore session on init
        Task {
            await refreshSession()
        }
    }
    
    // MARK: - Authentication Methods
    
    @MainActor
    func signUp(email: String, password: String, username: String) async throws {
        isLoading = true
        authError = nil
        
        do {
            // Create the user in Auth
            let result = try await client.auth.signUp(
                email: email,
                password: password,
                data: ["username": username]
            )
            
            if let session = result {
                self.session = Session(
                    accessToken: session.accessToken,
                    refreshToken: session.refreshToken,
                    user: AuthUser(from: session.user),
                    expiresAt: session.expiresAt
                )
                
                if let newUser = User.fromSession(self.session!) {
                    self.currentUser = newUser
                    self.isAuthenticated = true
                }
            }
        } catch {
            logger.error("Sign up failed: \(error.localizedDescription)")
            authError = "Sign up failed: \(error.localizedDescription)"
            isLoading = false;
            throw AuthError.signUpFailed(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    @MainActor
    func signIn(email: String, password: String) async throws {
        isLoading = true
        authError = nil
        
        do {
            // Sign in with email and password
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            
            self.session = Session(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                user: AuthUser(from: session.user),
                expiresAt: session.expiresAt
            )
            
            if let user = User.fromSession(self.session!) {
                self.currentUser = user
                self.isAuthenticated = true
            }
        } catch {
            logger.error("Sign in failed: \(error.localizedDescription)")
            authError = "Sign in failed: \(error.localizedDescription)"
            isLoading = false;
            throw AuthError.signInFailed(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    @MainActor
    func signOut() async throws {
        isLoading = true
        
        do {
            try await client.auth.signOut()
            self.session = nil
            self.currentUser = nil
            self.isAuthenticated = false
        } catch {
            logger.error("Sign out failed: \(error.localizedDescription)")
            authError = "Sign out failed: \(error.localizedDescription)"
            isLoading = false;
            throw AuthError.signOutFailed(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    @MainActor
    func refreshSession() async {
        do {
            let session = try await client.auth.session
            
            self.session = Session(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                user: AuthUser(from: session.user),
                expiresAt: session.expiresAt
            )
            
            if let user = User.fromSession(self.session!) {
                self.currentUser = user
                self.isAuthenticated = true
            }
        } catch {
            logger.notice("No active session or session refresh failed")
            self.session = nil
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
    
    @MainActor
    func updateUserProfile(username: String, avatarUrl: String? = nil) async throws {
        guard isAuthenticated, let user = currentUser else {
            throw AuthError.notAuthenticated
        }
        
        isLoading = true
        
        do {
            var userData: [String: Any] = ["username": username]
            if let avatarUrl = avatarUrl {
                userData["avatar_url"] = avatarUrl
            }
            
            _ = try await client.auth.update(user: userData)
            
            // Refresh the session to get updated user data
            await refreshSession()
        } catch {
            logger.error("Profile update failed: \(error.localizedDescription)")
            authError = "Profile update failed: \(error.localizedDescription)"
            isLoading = false;
            throw error
        }
        
        isLoading = false
    }
}

// Helper extension to convert Supabase Auth User to our AuthUser model
private extension AuthUser {
    init(from authUser: User) {
        self.id = authUser.id
        self.email = authUser.email
        
        var metadata: [String: Any] = [:]
        if let username = authUser.userMetadata?["username"] as? String {
            metadata["username"] = username
        }
        if let avatarUrl = authUser.userMetadata?["avatar_url"] as? String {
            metadata["avatar_url"] = avatarUrl
        }
        self.userMetadata = metadata
        
        self.createdAt = authUser.createdAt
        self.lastSignInAt = authUser.lastSignInAt
    }
}