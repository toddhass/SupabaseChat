import Foundation

// Print environment variables for debugging
let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "Not set"
print("Environment variables:")
print("SUPABASE_URL: \(supabaseURL)")
if ProcessInfo.processInfo.environment["SUPABASE_KEY"] != nil {
    print("SUPABASE_KEY: [Set but not displayed for security]")
} else {
    print("SUPABASE_KEY: Not set")
}

print("\nSupabaseChat app information:")
print("This is a Swift server for the SupabaseChat application")
print("This application demonstrates:")
print("- Real-time chat functionality using Supabase Realtime")
print("- User authentication with Supabase Auth")
print("- Persistent chat history using Supabase Database")
print("- Animated message UI and interactive elements")
print("\nTo see the application in action, visit the Python demo at:")
print("http://0.0.0.0:5000")

// Keep process running for a while
print("\nServer running (press Ctrl+C to stop)...")
sleep(600) // Run for 10 minutes