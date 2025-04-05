import SwiftUI

// This extension provides easier access to environment values
// that might be useful throughout the application
extension EnvironmentValues {
    // Add any custom environment values here if needed
}

#if canImport(UIKit)
// Extension for UIApplication to help with keyboard dismissal (iOS only)
import UIKit
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
