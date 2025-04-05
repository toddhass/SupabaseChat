import Foundation

// Print environment variables for debugging
print("SupabaseChat App Starting")
print("Environment variables:")
if let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] {
    print("SUPABASE_URL: \(supabaseURL)")
} else {
    print("SUPABASE_URL: Not set")
}

if ProcessInfo.processInfo.environment["SUPABASE_KEY"] != nil {
    print("SUPABASE_KEY: [Set but not displayed for security]")
} else {
    print("SUPABASE_KEY: Not set")
}

print("\nSupabaseChat app is a native SwiftUI application")
print("This demonstrates a real-time chat application with Supabase integration")
print("Features:")
print("- Real-time messaging using Supabase Realtime")
print("- User authentication with Supabase Auth")
print("- Message persistence in Supabase Database")
print("- User profiles and avatars")
print("- Animated message UI")

// Since we can't run a full SwiftUI app in this environment,
// we'll redirect users to the Python demo server
print("\nTo see a demonstration of the app's functionality, please check the Python demo at:")
print("http://0.0.0.0:5000/")

// Keep the process running
print("\nProcess running. Press Ctrl+C to exit.")
dispatchMain()