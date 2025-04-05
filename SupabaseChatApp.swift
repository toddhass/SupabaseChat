import SwiftUI
import Supabase

// Note: This App implementation is kept for reference, but on Replit
// we will use the simple HTTP server defined in main.swift instead

struct SupabaseChatApp: App {
    // Initialize the Supabase client
    // Get the Supabase URL and API key from environment variables
    private var supabaseURL: URL {
        if let urlString = ProcessInfo.processInfo.environment["SUPABASE_URL"],
           let url = URL(string: urlString) {
            return url
        } else {
            print("WARNING: SUPABASE_URL environment variable not set. Using placeholder URL.")
            print("To use this app with Supabase, set the SUPABASE_URL environment variable.")
            return URL(string: "https://your-project-url.supabase.co")!
        }
    }
    
    private var supabaseKey: String {
        if let key = ProcessInfo.processInfo.environment["SUPABASE_KEY"] {
            return key
        } else {
            print("WARNING: SUPABASE_KEY environment variable not set. Using placeholder key.")
            print("To use this app with Supabase, set the SUPABASE_KEY environment variable.")
            return "your-supabase-anon-key"
        }
    }
    
    // Create Supabase client
    private lazy var supabaseClient = SupabaseClient(
        supabaseURL: supabaseURL,
        supabaseKey: supabaseKey
    )
    
    // Create our services
    private var supabaseService: SupabaseService
    private var chatService: ChatService
    
    init() {
        print("Initializing SupabaseChatApp...")
        print("Supabase URL: \(self.supabaseURL)")
        
        // Initialize services
        self.supabaseService = SupabaseService(client: supabaseClient)
        self.chatService = ChatService(supabaseService: supabaseService)
        
        print("SupabaseChatApp initialized successfully")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(supabaseService)
                .environmentObject(chatService)
        }
    }
}
