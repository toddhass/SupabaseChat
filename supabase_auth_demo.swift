import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Models for authentication

// User model
struct SupabaseUser: Codable {
    let id: String
    let email: String?
    let username: String?
    let createdAt: String
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, email, username
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// Authentication response model
struct AuthResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String?
    let user: SupabaseUser
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case user
    }
}

// Error response model
struct ErrorResponse: Codable {
    let error: String
    let errorDescription: String?
    
    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
    }
}

// MARK: - Supabase Auth Service

class SupabaseAuthService {
    // Get environment variables
    let supabaseUrl: String
    let supabaseKey: String
    private var authToken: String?
    
    init() {
        // Retrieve from environment variables
        let processInfo = ProcessInfo.processInfo
        self.supabaseUrl = processInfo.environment["SUPABASE_URL"] ?? ""
        self.supabaseKey = processInfo.environment["SUPABASE_KEY"] ?? ""
        
        if supabaseUrl.isEmpty || supabaseKey.isEmpty {
            print("⚠️ Warning: SUPABASE_URL or SUPABASE_KEY environment variables are not set")
        } else {
            print("✅ Supabase environment variables loaded")
        }
    }
    
    // Sign up a new user
    func signUp(email: String, password: String, completion: @escaping (Result<SupabaseUser, Error>) -> Void) {
        guard let url = URL(string: "\(supabaseUrl)/auth/v1/signup") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.addValue(supabaseKey, forHTTPHeaderField: "apikey")
        
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -2, userInfo: nil)))
                return
            }
            
            // Check if we got an error response
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                do {
                    let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                    let errorMessage = errorResponse.errorDescription ?? errorResponse.error
                    completion(.failure(NSError(domain: errorMessage, code: httpResponse.statusCode, userInfo: nil)))
                } catch {
                    completion(.failure(NSError(domain: "Failed to parse error", code: httpResponse.statusCode, userInfo: nil)))
                }
                return
            }
            
            // Parse successful response
            do {
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                self.authToken = authResponse.accessToken
                completion(.success(authResponse.user))
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // Sign in an existing user
    func signIn(email: String, password: String, completion: @escaping (Result<SupabaseUser, Error>) -> Void) {
        guard let url = URL(string: "\(supabaseUrl)/auth/v1/token?grant_type=password") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.addValue(supabaseKey, forHTTPHeaderField: "apikey")
        
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -2, userInfo: nil)))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                do {
                    let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                    let errorMessage = errorResponse.errorDescription ?? errorResponse.error
                    completion(.failure(NSError(domain: errorMessage, code: httpResponse.statusCode, userInfo: nil)))
                } catch {
                    completion(.failure(NSError(domain: "Failed to parse error", code: httpResponse.statusCode, userInfo: nil)))
                }
                return
            }
            
            do {
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                self.authToken = authResponse.accessToken
                completion(.success(authResponse.user))
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // Sign out the current user
    func signOut(completion: @escaping (Bool, Error?) -> Void) {
        guard let token = authToken else {
            completion(false, NSError(domain: "Not authenticated", code: -3, userInfo: nil))
            return
        }
        
        guard let url = URL(string: "\(supabaseUrl)/auth/v1/logout") else {
            completion(false, NSError(domain: "Invalid URL", code: -1, userInfo: nil))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue(supabaseKey, forHTTPHeaderField: "apikey")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error)
                return
            }
            
            // Check response code
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                self.authToken = nil
                completion(true, nil)
            } else {
                completion(false, NSError(domain: "Logout failed", code: -4, userInfo: nil))
            }
        }
        
        task.resume()
    }
    
    // Display auth information
    func showAuthInfo() {
        print("Supabase URL: \(supabaseUrl)")
        print("Auth Status: \(authToken != nil ? "Authenticated" : "Not authenticated")")
    }
}

// MARK: - Main Demo

func runAuthDemo() {
    let authService = SupabaseAuthService()
    let semaphore = DispatchSemaphore(value: 0)
    
    print("==================================================")
    print("  Supabase Authentication Demo")
    print("==================================================")
    
    authService.showAuthInfo()
    
    // Prevent real API calls if environment variables aren't set
    guard !authService.supabaseUrl.isEmpty && !authService.supabaseKey.isEmpty else {
        print("\n⚠️ Cannot run demo: Missing Supabase environment variables")
        return
    }
    
    print("\n1. Testing sign-up...")
    // Use a random email to avoid conflicts
    let randomInt = Int.random(in: 1000...9999)
    let testEmail = "test\(randomInt)@example.com"
    let testPassword = "Password123!"
    
    authService.signUp(email: testEmail, password: testPassword) { result in
        switch result {
        case .success(let user):
            print("✅ Sign-up successful!")
            print("User ID: \(user.id)")
            print("Email: \(user.email ?? "none")")
            
            print("\n2. Testing sign-in with new account...")
            authService.signIn(email: testEmail, password: testPassword) { result in
                switch result {
                case .success(let user):
                    print("✅ Sign-in successful!")
                    print("User ID: \(user.id)")
                    
                    print("\n3. Testing sign-out...")
                    authService.signOut { success, error in
                        if success {
                            print("✅ Sign-out successful!")
                        } else if let error = error {
                            print("❌ Sign-out failed: \(error.localizedDescription)")
                        }
                        semaphore.signal()
                    }
                    
                case .failure(let error):
                    print("❌ Sign-in failed: \(error.localizedDescription)")
                    semaphore.signal()
                }
            }
            
        case .failure(let error):
            print("❌ Sign-up failed: \(error.localizedDescription)")
            
            // If sign-up failed, try signing in with test credentials
            print("\nTrying sign-in instead...")
            authService.signIn(email: testEmail, password: testPassword) { result in
                switch result {
                case .success(let user):
                    print("✅ Sign-in successful!")
                    print("User ID: \(user.id)")
                    
                    print("\nTesting sign-out...")
                    authService.signOut { success, error in
                        if success {
                            print("✅ Sign-out successful!")
                        } else if let error = error {
                            print("❌ Sign-out failed: \(error.localizedDescription)")
                        }
                        semaphore.signal()
                    }
                    
                case .failure(let error):
                    print("❌ Sign-in also failed: \(error.localizedDescription)")
                    print("Demo complete with errors.")
                    semaphore.signal()
                }
            }
        }
    }
    
    // Wait for async operations to complete
    semaphore.wait()
    print("\nAuth demo complete!")
}

// Run the demo
runAuthDemo()