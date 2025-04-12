import SwiftUI
import Supabase

struct ContentView: View {
    @EnvironmentObject private var supabaseService: SupabaseService
    @State private var showProfileSheet: Bool = false
    
    var body: some View {
        NavigationView {
            if supabaseService.authService.isAuthenticated {
                ChatView()
                    .navigationTitle("SupaChat")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            UserStatusView()
                                .environmentObject(supabaseService.authService)
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { showProfileSheet = true }) {
                                Image(systemName: "person.circle")
                                    .imageScale(.large)
                            }
                        }
                    }
                    .sheet(isPresented: $showProfileSheet) {
                        ProfileView()
                    }
            } else {
                VStack {
                    HStack {
                        UserStatusView()
                            .environmentObject(supabaseService.authService)
                            .padding()
                        Spacer()
                    }
                    Spacer()
                    AuthenticationView()
                        .environmentObject(supabaseService)
                    Spacer()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .animation(.easeInOut, value: supabaseService.authService.isAuthenticated)
        .onAppear {
            print("ContentView appeared - SupabaseService instance: \(Unmanaged.passUnretained(supabaseService).toOpaque())")
            print("ContentView appeared - isAuthenticated: \(supabaseService.authService.isAuthenticated)")
        }
        .onChange(of: supabaseService.authService.isAuthenticated) { newValue in
            print("isAuthenticated changed to: \(newValue)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(SupabaseService(client: SupabaseClient(
                supabaseURL: URL(string: "https://hdzmbngzplkgkchmxfwu.supabase.co")!,
                supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhkem1ibmd6cGxrZ2tjaG14Znd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE2NzgyNzc3NjQsImV4cCI6MTk5Mzg1Mzc2NH0.ogb5FZ_nfUdIcobdas9EFm7u8vOs8-_RB2CB4MxLMAU"
            )))
    }
}
