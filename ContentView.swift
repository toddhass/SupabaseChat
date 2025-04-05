import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var supabaseService: SupabaseService
    @State private var showProfileSheet: Bool = false
    
    var body: some View {
        NavigationView {
            if supabaseService.authService.isAuthenticated {
                // User is authenticated, show the chat interface
                ChatView()
                    .navigationTitle("SupaChat")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            UserStatusView()
                                .environmentObject(supabaseService.authService)
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                showProfileSheet = true
                            }) {
                                Image(systemName: "person.circle")
                                    .imageScale(.large)
                            }
                        }
                    }
                    .sheet(isPresented: $showProfileSheet) {
                        ProfileView()
                    }
            } else {
                // User is not authenticated, show the authentication view
                VStack {
                    HStack {
                        UserStatusView()
                            .environmentObject(supabaseService.authService)
                            .padding()
                        Spacer()
                    }
                    
                    Spacer()
                    
                    AuthenticationView()
                    
                    Spacer()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .animation(.easeInOut, value: supabaseService.authService.isAuthenticated)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
