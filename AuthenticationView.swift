import SwiftUI

enum AuthenticationScreen {
    case signIn
    case signUp
}

struct AuthenticationView: View {
    @EnvironmentObject private var supabaseService: SupabaseService
    @State private var currentScreen: AuthenticationScreen = .signIn
    
    // Animation properties
    @State private var slideOffset: CGFloat = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        ZStack {
            // Background with animation
            Color.blue.opacity(0.05)
                .ignoresSafeArea()
            
            VStack {
                // Logo or app name
                HStack {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .foregroundColor(.blue)
                    
                    Text("SupaChat")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .padding(.top, 30)
                .padding(.bottom, 20)
                
                // Authentication screens
                if currentScreen == .signIn {
                    SignInView()
                        .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                        .offset(x: slideOffset)
                        .opacity(opacity)
                } else {
                    SignUpView()
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        .offset(x: slideOffset)
                        .opacity(opacity)
                }
                
                // Switch between authentication screens
                HStack {
                    Button(action: {
                        switchScreen(to: .signIn)
                    }) {
                        Text("Sign In")
                            .fontWeight(currentScreen == .signIn ? .bold : .regular)
                            .foregroundColor(currentScreen == .signIn ? .blue : .gray)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(currentScreen == .signIn ? Color.blue.opacity(0.2) : Color.clear)
                            )
                    }
                    
                    Button(action: {
                        switchScreen(to: .signUp)
                    }) {
                        Text("Sign Up")
                            .fontWeight(currentScreen == .signUp ? .bold : .regular)
                            .foregroundColor(currentScreen == .signUp ? .blue : .gray)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(currentScreen == .signUp ? Color.blue.opacity(0.2) : Color.clear)
                            )
                    }
                }
                .padding(.bottom, 20)
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func switchScreen(to screen: AuthenticationScreen) {
        guard screen != currentScreen else { return }
        
        // Slide out current screen
        withAnimation(.easeInOut(duration: 0.3)) {
            slideOffset = screen == .signIn ? 100 : -100
            opacity = 0
        }
        
        // Change screen and slide in new screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentScreen = screen
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                slideOffset = 0
                opacity = 1
            }
        }
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}