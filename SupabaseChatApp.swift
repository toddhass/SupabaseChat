import SwiftUI
import Supabase

@main
struct SupabaseChatApp: App {
    private let supabaseClient: SupabaseClient
    private let supabaseService: SupabaseService
    private let chatService: ChatService
    
    init() {
        print("Initializing SupabaseChatApp...")
        
        let url = URL(string: "https://hdzmbngzplkgkchmxfwu.supabase.co")!
        let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhkem1ibmd6cGxrZ2tjaG14Znd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE2NzgyNzc3NjQsImV4cCI6MTk5Mzg1Mzc2NH0.ogb5FZ_nfUdIcobdas9EFm7u8vOs8-_RB2CB4MxLMAU"
        
        print("Supabase URL: \(url)")
        print("Supabase Key: \(key.prefix(20))... [truncated]")
        
        let client = SupabaseClient(supabaseURL: url, supabaseKey: key)
        let service = SupabaseService(client: client)
        let chat = ChatService(supabaseService: service)
        
        self.supabaseClient = client
        self.supabaseService = service
        self.chatService = chat
        
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
