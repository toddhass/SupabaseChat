import SwiftUI
import Supabase

struct UserStatusView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var supabaseService: SupabaseService // Add this
    @State private var showProfileSheet: Bool = false
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(authService.isAuthenticated ? Color.green : Color.red)
                .frame(width: 8, height: 8)
                .shadow(color: authService.isAuthenticated ? Color.green.opacity(0.5) : Color.red.opacity(0.5),
                        radius: 2, x: 0, y: 0)
            
            if authService.isAuthenticated, let user = authService.currentUser {
                HStack(spacing: 6) {
                    Text(user.username)
                        .font(.footnote)
                        .fontWeight(.medium)
                    
                    ProfileImageView(user: user, size: 24, supabaseService: supabaseService) // Fix call
                        .onTapGesture {
                            showProfileSheet = true
                        }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            } else {
                Text("Not logged in")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.secondary.opacity(0.1))
        )
        .sheet(isPresented: $showProfileSheet) {
            ProfileView()
        }
        .animation(.spring(response: 0.3), value: authService.isAuthenticated)
    }
}

//struct UserStatusView_Previews: PreviewProvider {
//    static var previews: some View {
//        UserStatusView()
//            .environmentObject(AuthenticationService(client: SupabaseClient(
//                supabaseURL: URL(string: "https://example.supabase.co")!,
//                supabaseKey: "example-key"
//            )))
//            .environmentObject(SupabaseService(client: SupabaseClient(
//                supabaseURL: URL(string: "https://example.supabase.co")!,
//                supabaseKey: "example-key"
//            )))
//    }
//}
