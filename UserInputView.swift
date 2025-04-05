import SwiftUI

struct UserInputView: View {
    @Binding var messageText: String
    @FocusState var isInputFocused: Bool
    var onSend: () -> Void
    
    @State private var isSending = false
    @State private var animateSend = false
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Message input field
                TextField("Type a message...", text: $messageText)
                    .padding(10)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(20)
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        sendMessageWithAnimation()
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: messageText)
                
                // Send button with animation
                Button(action: sendMessageWithAnimation) {
                    ZStack {
                        // Pulse animation on send
                        if animateSend {
                            Circle()
                                .foregroundColor(.blue.opacity(0.3))
                                .frame(width: 36, height: 36)
                                .scaleEffect(animateSend ? 1.4 : 1.0)
                                .opacity(animateSend ? 0 : 0.3)
                                .animation(
                                    Animation.easeOut(duration: 0.6)
                                        .repeatCount(1, autoreverses: false),
                                    value: animateSend
                                )
                        }
                        
                        // Button icon
                        Image(systemName: isSending ? "arrow.up.circle" : "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .blue.opacity(0.5) : .blue)
                            .rotationEffect(Angle(degrees: animateSend ? 8 : 0))
                            .scaleEffect(animateSend ? 0.8 : 1.0)
                            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: animateSend)
                    }
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.white)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSending)
            .padding(.bottom, 8)
        }
    }
    
    private func sendMessageWithAnimation() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // Start animation
        animateSend = true
        isSending = true
        
        // Reset animation state after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animateSend = false
            
            // Call actual send function
            onSend()
            
            // Reset sending state after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isSending = false
            }
        }
    }
}

struct UserInputView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            UserInputView(
                messageText: .constant("Hello, world!"),
                onSend: {}
            )
            
            UserInputView(
                messageText: .constant(""),
                onSend: {}
            )
        }
    }
}
