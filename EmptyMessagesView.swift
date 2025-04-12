import SwiftUI

struct EmptyMessagesView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.7))
                .padding()
                .background(Circle().fill(Color.blue.opacity(0.1)))
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            Text("No messages yet")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Be the first to send a message!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 30)
        .onAppear {
            isAnimating = true
        }
    }
}
