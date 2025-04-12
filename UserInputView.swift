import SwiftUI

struct UserInputView: View {
    @Binding var messageText: String
    @FocusState var isInputFocused: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack(alignment: .bottom) {
            TextEditor(text: $messageText)
                .focused($isInputFocused)
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .keyboardType(.default)
                .frame(minHeight: 34, maxHeight: 100)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .onTapGesture {
                    isInputFocused = true
                }
                .onChange(of: messageText) { newValue in
                    if newValue.contains("\n") {
                        messageText = newValue.replacingOccurrences(of: "\n", with: "")
                        isInputFocused = false
                        onSend()
                    }
                }
            
            Button(action: {
                isInputFocused = false
                onSend()
            }) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.blue)
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }
}
