import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var supabaseService: SupabaseService
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String = ""
    @State private var isSigningIn: Bool = false
    @State private var emailFieldOffset: CGFloat = 30
    @State private var passwordFieldOffset: CGFloat = 60
    @State private var buttonOffset: CGFloat = 90
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack(spacing: 25) {
            VStack(spacing: 10) {
                Text("Welcome back")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Sign in to continue chatting")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 30)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.red.opacity(0.1)))
                    .transition(.scale.combined(with: .opacity))
            }
            
            VStack(spacing: 20) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .offset(x: emailFieldOffset)
                    .opacity(opacity)
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .offset(x: passwordFieldOffset)
                    .opacity(opacity)
            }
            .padding(.horizontal)
            
            Button(action: signIn) {
                HStack {
                    if isSigningIn {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, 5)
                    }
                    Text(isSigningIn ? "Signing In..." : "Sign In")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
                .disabled(isSigningIn || email.isEmpty || password.isEmpty)
                .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)
            }
            .disabled(isSigningIn || email.isEmpty || password.isEmpty)
            .padding(.horizontal)
            .offset(x: buttonOffset)
            .opacity(opacity)
            
            Spacer()
        }
        .padding()
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                emailFieldOffset = 0
                opacity = 1
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                passwordFieldOffset = 0
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                buttonOffset = 0
            }
        }
    }
    
    private func signIn() {
        guard !email.isEmpty, !password.isEmpty else { return }
        errorMessage = ""
        isSigningIn = true
        
        Task {
            do {
                print("SupabaseService instance in SignInView: \(Unmanaged.passUnretained(supabaseService).toOpaque())")
                print("Attempting sign-in with email: \(email)")
                try await supabaseService.authService.signIn(email: email, password: password)
                print("Sign-in successful")
                print("Session: \(String(describing: supabaseService.authService.session))")
                print("CurrentUser: \(String(describing: supabaseService.authService.currentUser))")
                print("isAuthenticated: \(supabaseService.authService.isAuthenticated)")
                try await supabaseService.syncUserProfile()
                print("User profile synced")
                supabaseService.objectWillChange.send()
                supabaseService.authService.objectWillChange.send()
                email = ""
                password = ""
            } catch {
                print("Sign-in failed: \(error)")
                if let authError = supabaseService.authService.authError {
                    errorMessage = authError
                } else {
                    errorMessage = "Failed to sign in: \(error.localizedDescription)"
                }
            }
            await MainActor.run {
                isSigningIn = false
            }
        }
    }
}

//struct SignInView_Previews: PreviewProvider {
//    static var previews: some View {
//        SignInView()
//            .environmentObject(SupabaseService(client: SupabaseClient(
//                supabaseURL: URL(string: "https://hdzmbngzplkgkchmxfwu.supabase.co")!,
//                supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhkem1ibmd6cGxrZ2tjaG14Znd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE2NzgyNzc3NjQsImV4cCI6MTk5Mzg1Mzc2NH0.ogb5FZ_nfUdIcobdas9EFm7u8vOs8-_RB2CB4MxLMAU"
//            )))
//    }
//}
