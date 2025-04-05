import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var supabaseService: SupabaseService
    
    @State private var email: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String = ""
    @State private var isSigningUp: Bool = false
    
    // Animation properties
    @State private var fieldsOffset: [CGFloat] = [30, 60, 90, 120]
    @State private var buttonOffset: CGFloat = 150
    @State private var opacity: Double = 0
    
    private var passwordsMatch: Bool {
        return password == confirmPassword
    }
    
    private var formIsValid: Bool {
        return !email.isEmpty && email.contains("@") &&
               !username.isEmpty && username.count >= 3 &&
               !password.isEmpty && password.count >= 6 &&
               passwordsMatch
    }
    
    var body: some View {
        VStack(spacing: 25) {
            // Header
            VStack(spacing: 10) {
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Join our chat community")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            
            // Error message if any
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                    )
                    .transition(.scale.combined(with: .opacity))
            }
            
            // Input fields
            VStack(spacing: 15) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .offset(x: fieldsOffset[0])
                    .opacity(opacity)
                
                TextField("Username", text: $username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .offset(x: fieldsOffset[1])
                    .opacity(opacity)
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .offset(x: fieldsOffset[2])
                    .opacity(opacity)
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .offset(x: fieldsOffset[3])
                    .opacity(opacity)
                
                if !password.isEmpty && !confirmPassword.isEmpty && !passwordsMatch {
                    Text("Passwords do not match")
                        .foregroundColor(.red)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 5)
                }
            }
            .padding(.horizontal)
            
            // Sign up button
            Button(action: signUp) {
                HStack {
                    if isSigningUp {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, 5)
                    }
                    
                    Text(isSigningUp ? "Creating Account..." : "Create Account")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
                .opacity(formIsValid ? 1.0 : 0.6)
            }
            .disabled(isSigningUp || !formIsValid)
            .padding(.horizontal)
            .offset(x: buttonOffset)
            .opacity(opacity)
            
            // Navigation to sign in is now handled by AuthenticationView
            
            Spacer()
        }
        .padding()
        .onAppear {
            animateViews()
        }
    }
    
    private func animateViews() {
        // Animate input fields one by one
        for i in 0..<fieldsOffset.count {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1 * Double(i + 1))) {
                fieldsOffset[i] = 0
                opacity = 1
            }
        }
        
        // Animate button
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6)) {
            buttonOffset = 0
        }
    }
    
    private func signUp() {
        guard formIsValid else { return }
        
        errorMessage = ""
        isSigningUp = true
        
        Task {
            do {
                try await supabaseService.authService.signUp(
                    email: email,
                    password: password,
                    username: username
                )
                
                // Sync profile with Supabase
                try await supabaseService.syncUserProfile()
                
                // Reset fields
                email = ""
                username = ""
                password = ""
                confirmPassword = ""
            } catch {
                if let authError = supabaseService.authService.authError {
                    errorMessage = authError
                } else {
                    errorMessage = "Failed to create account: \(error.localizedDescription)"
                }
            }
            
            await MainActor.run {
                isSigningUp = false
            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}