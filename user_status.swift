import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// Define model for user data
struct UserStatus: Codable {
    let id: String
    let username: String
    var isOnline: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id, username
        case isOnline = "is_online"
    }
}

// Define model for users response
struct UsersResponse: Codable {
    let users: [UserStatus]
}

// Simple network manager for User Status API
class UserStatusManager {
    private let baseURL = "http://0.0.0.0:5002/api"
    
    // Fetch all users
    func fetchAllUsers(completion: @escaping ([UserStatus]?, Error?) -> Void) {
        guard let url = URL(string: "\(baseURL)/users") else {
            print("Invalid URL")
            completion(nil, NSError(domain: "URLError", code: -1, userInfo: nil))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion(nil, NSError(domain: "DataError", code: -2, userInfo: nil))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let usersResponse = try decoder.decode(UsersResponse.self, from: data)
                completion(usersResponse.users, nil)
            } catch {
                print("Decoding error: \(error)")
                completion(nil, error)
            }
        }
        
        task.resume()
    }
    
    // Fetch a specific user by ID
    func fetchUser(id: String, completion: @escaping (UserStatus?, Error?) -> Void) {
        guard let url = URL(string: "\(baseURL)/users/\(id)") else {
            print("Invalid URL")
            completion(nil, NSError(domain: "URLError", code: -1, userInfo: nil))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion(nil, NSError(domain: "DataError", code: -2, userInfo: nil))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let user = try decoder.decode(UserStatus.self, from: data)
                completion(user, nil)
            } catch {
                print("Decoding error: \(error)")
                completion(nil, error)
            }
        }
        
        task.resume()
    }
    
    // Toggle user status
    func toggleUserStatus(id: String, completion: @escaping (UserStatus?, Error?) -> Void) {
        guard let url = URL(string: "\(baseURL)/toggle-status?user_id=\(id)") else {
            print("Invalid URL")
            completion(nil, NSError(domain: "URLError", code: -1, userInfo: nil))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion(nil, NSError(domain: "DataError", code: -2, userInfo: nil))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let user = try decoder.decode(UserStatus.self, from: data)
                completion(user, nil)
            } catch {
                print("Decoding error: \(error)")
                completion(nil, error)
            }
        }
        
        task.resume()
    }
}

// Main function to demonstrate user status API usage
func main() {
    print("Swift User Status API Demo")
    print("==========================")
    
    let statusManager = UserStatusManager()
    let semaphore = DispatchSemaphore(value: 0)
    
    // 1. Fetch all users first
    print("\nFetching all users...")
    statusManager.fetchAllUsers { users, error in
        if let error = error {
            print("Error fetching users: \(error)")
            semaphore.signal()
            return
        }
        
        guard let users = users else {
            print("No users found")
            semaphore.signal()
            return
        }
        
        print("\nUsers found:")
        for user in users {
            let statusSymbol = user.isOnline ? "🟢" : "🔴"
            print("\(statusSymbol) \(user.username) (ID: \(user.id))")
        }
        
        // 2. Toggle status for first user
        if let firstUser = users.first {
            print("\nToggling status for \(firstUser.username)...")
            
            statusManager.toggleUserStatus(id: firstUser.id) { updatedUser, error in
                if let error = error {
                    print("Error toggling status: \(error)")
                    semaphore.signal()
                    return
                }
                
                guard let updatedUser = updatedUser else {
                    print("Failed to update user")
                    semaphore.signal()
                    return
                }
                
                let newStatusText = updatedUser.isOnline ? "online" : "offline"
                print("\(updatedUser.username) is now \(newStatusText)")
                
                // 3. Fetch the updated user
                statusManager.fetchUser(id: firstUser.id) { user, error in
                    if let error = error {
                        print("Error fetching updated user: \(error)")
                        semaphore.signal()
                        return
                    }
                    
                    guard let user = user else {
                        print("User not found")
                        semaphore.signal()
                        return
                    }
                    
                    let statusSymbol = user.isOnline ? "🟢" : "🔴"
                    print("\nVerified updated user:")
                    print("\(statusSymbol) \(user.username) (ID: \(user.id))")
                    
                    // 4. Fetch all users again to see the change
                    statusManager.fetchAllUsers { allUsers, error in
                        if let error = error {
                            print("Error fetching all users again: \(error)")
                            semaphore.signal()
                            return
                        }
                        
                        guard let allUsers = allUsers else {
                            print("No users found")
                            semaphore.signal()
                            return
                        }
                        
                        print("\nAll users after update:")
                        for user in allUsers {
                            let statusSymbol = user.isOnline ? "🟢" : "🔴"
                            print("\(statusSymbol) \(user.username) (ID: \(user.id))")
                        }
                        
                        print("\nDemo complete!")
                        semaphore.signal()
                    }
                }
            }
        } else {
            print("No users to update")
            semaphore.signal()
        }
    }
    
    // Wait for all async operations to complete
    semaphore.wait()
}

// Run the demo
main()