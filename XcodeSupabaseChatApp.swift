import SwiftUI
import Supabase

// Initialize Supabase client
let supabaseUrl = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
let supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_KEY"] ?? ""
let supabase = SupabaseClient(supabaseURL: URL(string: supabaseUrl)!, supabaseKey: supabaseKey)

// Authentication state management
class AuthState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User? = nil
    @Published var profile: Profile? = nil
    @Published var error: Error? = nil
    
    func signIn(email: String, password: String) async {
        do {
            let session = try await supabase.auth.signIn(email: email, password: password)
            DispatchQueue.main.async {
                self.currentUser = session.user
                self.isAuthenticated = true
                self.error = nil
            }
            await self.fetchProfile()
        } catch {
            DispatchQueue.main.async {
                self.error = error
            }
        }
    }
    
    func signUp(email: String, password: String, username: String) async {
        do {
            let session = try await supabase.auth.signUp(email: email, password: password, data: ["username": username])
            DispatchQueue.main.async {
                self.currentUser = session.user
                self.isAuthenticated = true
                self.error = nil
            }
            await self.fetchProfile()
        } catch {
            DispatchQueue.main.async {
                self.error = error
            }
        }
    }
    
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            DispatchQueue.main.async {
                self.currentUser = nil
                self.isAuthenticated = false
                self.profile = nil
                self.error = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error
            }
        }
    }
    
    func fetchProfile() async {
        guard let userId = currentUser?.id else { return }
        
        do {
            let response = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
            
            let profile = try response.decoded(to: Profile.self)
            
            DispatchQueue.main.async {
                self.profile = profile
                self.error = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error
            }
        }
    }
}

// Data models
struct User: Codable, Identifiable {
    let id: String
    let email: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
    }
}

struct Profile: Codable, Identifiable {
    let id: String
    let username: String
    let displayName: String?
    let avatarUrl: String?
    let status: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case status
    }
}

struct Message: Codable, Identifiable {
    let id: String
    let userId: String
    let content: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case content
        case createdAt = "created_at"
    }
}

// Main app
@main
struct SupabaseChatApp: App {
    @StateObject private var authState = AuthState()
    
    var body: some Scene {
        WindowGroup {
            if authState.isAuthenticated {
                ContentView()
                    .environmentObject(authState)
            } else {
                AuthView()
                    .environmentObject(authState)
            }
        }
    }
}

// Authentication view
struct AuthView: View {
    @EnvironmentObject var authState: AuthState
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var isSignUp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("SupabaseChat")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Spacer()
                
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if isSignUp {
                        TextField("Username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                }
                
                if let error = authState.error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
                
                Button(action: {
                    Task {
                        if isSignUp {
                            await authState.signUp(email: email, password: password, username: username)
                        } else {
                            await authState.signIn(email: email, password: password)
                        }
                    }
                }) {
                    Text(isSignUp ? "Sign Up" : "Sign In")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    isSignUp.toggle()
                }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle(isSignUp ? "Create Account" : "Welcome Back")
        }
    }
}

// Main content view
struct ContentView: View {
    @EnvironmentObject var authState: AuthState
    @State private var messages: [Message] = []
    @State private var newMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if let profile = authState.profile {
                    Text("Welcome, \(profile.displayName ?? profile.username)!")
                        .font(.headline)
                }
                
                // Messages list would go here
                List {
                    ForEach(messages) { message in
                        MessageRow(message: message)
                    }
                }
                
                // Message input bar
                HStack {
                    TextField("Type a message", text: $newMessage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        sendMessage()
                    }) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                    }
                }
                .padding()
            }
            .navigationTitle("Chat")
            .toolbar {
                Button("Sign Out") {
                    Task {
                        await authState.signOut()
                    }
                }
            }
            .onAppear {
                fetchMessages()
            }
        }
    }
    
    func fetchMessages() {
        // In a real app, this would fetch messages from Supabase
        // Example:
        // Task {
        //     do {
        //         let response = try await supabase
        //             .from("messages")
        //             .select()
        //             .order("created_at", ascending: false)
        //             .limit(50)
        //             .execute()
        //         
        //         let fetchedMessages = try response.decoded(to: [Message].self)
        //         DispatchQueue.main.async {
        //             self.messages = fetchedMessages.reversed()
        //         }
        //     } catch {
        //         print("Error fetching messages: \(error)")
        //     }
        // }
    }
    
    func sendMessage() {
        guard !newMessage.isEmpty, let userId = authState.currentUser?.id else { return }
        
        // In a real app, this would send the message to Supabase
        // Example:
        // Task {
        //     do {
        //         let response = try await supabase
        //             .from("messages")
        //             .insert([
        //                 "user_id": userId,
        //                 "content": newMessage
        //             ])
        //             .execute()
        //         
        //         newMessage = ""
        //         fetchMessages()
        //     } catch {
        //         print("Error sending message: \(error)")
        //     }
        // }
    }
}

// Message row component
struct MessageRow: View {
    let message: Message
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(message.content)
                    .padding(10)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                
                Text(message.createdAt, style: .time)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let authState = AuthState()
        ContentView()
            .environmentObject(authState)
    }
}