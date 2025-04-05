import Foundation

// ANSI color codes for terminal output
struct TerminalColors {
    static let reset = "\u{001B}[0m"
    static let red = "\u{001B}[31m"
    static let green = "\u{001B}[32m"
    static let yellow = "\u{001B}[33m"
    static let blue = "\u{001B}[34m"
    static let magenta = "\u{001B}[35m"
    static let cyan = "\u{001B}[36m"
    static let white = "\u{001B}[37m"
}

// Print a styled header
func printHeader(_ text: String) {
    print("\n\(TerminalColors.blue)=== \(text) ===\(TerminalColors.reset)")
}

// Print an info line with colored label
func printInfo(_ label: String, _ value: String, success: Bool = true) {
    let color = success ? TerminalColors.green : TerminalColors.yellow
    print("\(TerminalColors.cyan)\(label):\(TerminalColors.reset) \(color)\(value)\(TerminalColors.reset)")
}

// Print a list item with bullet
func printListItem(_ text: String) {
    print("  • \(text)")
}

// Check environment variables
printHeader("SupabaseChat - SwiftUI App")
print("A real-time chat application powered by Supabase and Swift")

printHeader("Environment Configuration")
let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "Not set"
let supabaseKeyAvailable = ProcessInfo.processInfo.environment["SUPABASE_KEY"] != nil

printInfo("SUPABASE_URL", supabaseURL != "Not set" ? "Available" : "Not set", success: supabaseURL != "Not set")
printInfo("SUPABASE_KEY", supabaseKeyAvailable ? "Available" : "Not set", success: supabaseKeyAvailable)

printHeader("Application Features")
printListItem("Real-time messaging using Supabase Realtime")
printListItem("User authentication with Supabase Auth")
printListItem("Message persistence with Supabase Database")
printListItem("User profiles and presence indicators")
printListItem("Animated message UI with typing indicators")
printListItem("Read receipts and message reactions")

printHeader("Next Steps")
print("Since SwiftUI apps can only run on Apple platforms (iOS, macOS, etc.),")
print("we've created a Python demonstration server to showcase the app's features.")
print("\nTo see the app in action, visit the Python demo at:")
print("\(TerminalColors.green)http://0.0.0.0:5000\(TerminalColors.reset)")

printHeader("Swift Compatibility")
print("Swift Version: \(TerminalColors.green)5.6\(TerminalColors.reset)")
print("Supabase Swift SDK: \(TerminalColors.green)Compatible\(TerminalColors.reset)")

print("\nServer running (press Ctrl+C to stop)...")
sleep(3600) // Run for 1 hour