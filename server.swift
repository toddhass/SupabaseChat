import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

// Simple HTTP server using standard library
class SimpleHTTPServer {
    let port: UInt16
    var serverSocket: Int32 = -1
    
    init(port: UInt16) {
        self.port = port
    }
    
    func start() {
        print("Starting HTTP server on port \(port)...")
        
        // Create socket
        serverSocket = socket(AF_INET, Int32(SOCK_STREAM.rawValue), 0)
        if serverSocket == -1 {
            perror("Failed to create socket")
            exit(1)
        }
        
        // Set socket options
        var on: Int32 = 1
        if setsockopt(serverSocket, SOL_SOCKET, SO_REUSEADDR, &on, socklen_t(MemoryLayout<Int32>.size)) == -1 {
            perror("setsockopt() failed")
            exit(1)
        }
        
        // Bind to port
        var serverAddr = sockaddr_in()
        serverAddr.sin_family = sa_family_t(AF_INET)
        serverAddr.sin_port = htons(port)
        serverAddr.sin_addr.s_addr = INADDR_ANY
        
        let serverAddrPtr = withUnsafePointer(to: &serverAddr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { $0 }
        }
        
        if bind(serverSocket, serverAddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size)) == -1 {
            perror("bind() failed")
            exit(1)
        }
        
        // Listen for connections
        if listen(serverSocket, 10) == -1 {
            perror("listen() failed")
            exit(1)
        }
        
        print("HTTP server is running on http://0.0.0.0:\(port)")
        
        // Accept and handle connections
        acceptConnections()
    }
    
    func acceptConnections() {
        var clientAddr = sockaddr_in()
        var clientAddrLen = socklen_t(MemoryLayout<sockaddr_in>.size)
        
        // Accept loop
        while true {
            let clientAddrPtr = withUnsafeMutablePointer(to: &clientAddr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { $0 }
            }
            
            let clientSocket = accept(serverSocket, clientAddrPtr, &clientAddrLen)
            if clientSocket == -1 {
                perror("accept() failed")
                continue
            }
            
            // Handle the connection
            handleConnection(clientSocket: clientSocket)
        }
    }
    
    func handleConnection(clientSocket: Int32) {
        // Get environment variables
        let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "Not set"
        let supabaseKeyStatus = ProcessInfo.processInfo.environment["SUPABASE_KEY"] != nil ? "Set" : "Not set"
        
        // Buffer for request
        var buffer = [UInt8](repeating: 0, count: 1024)
        let bytesRead = recv(clientSocket, &buffer, buffer.count, 0)
        
        if bytesRead <= 0 {
            close(clientSocket)
            return
        }
        
        // Create response HTML
        let html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>SupabaseChat - SwiftUI App</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    line-height: 1.6;
                    color: #333;
                    max-width: 650px;
                    margin: 0 auto;
                    padding: 20px;
                }
                h1 {
                    color: #007aff;
                }
                .card {
                    background-color: #f5f5f7;
                    border-radius: 10px;
                    padding: 20px;
                    margin: 20px 0;
                }
                code {
                    background-color: #eaeaea;
                    padding: 2px 4px;
                    border-radius: 4px;
                    font-family: Menlo, Monaco, "Courier New", monospace;
                }
                .button {
                    background-color: #007aff;
                    color: white;
                    border: none;
                    padding: 10px 20px;
                    border-radius: 6px;
                    font-weight: bold;
                    text-decoration: none;
                    display: inline-block;
                    margin-top: 10px;
                }
                .status {
                    display: inline-block;
                    padding: 5px 10px;
                    border-radius: 4px;
                    font-weight: bold;
                }
                .status-success {
                    background-color: #34c759;
                    color: white;
                }
                .status-warning {
                    background-color: #ff9500;
                    color: white;
                }
            </style>
        </head>
        <body>
            <h1>SupabaseChat - SwiftUI App</h1>
            
            <div class="card">
                <h2>About This Project</h2>
                <p>This is a native SwiftUI chat application with real-time functionality powered by Supabase.</p>
                <p>As a SwiftUI app, it is designed to run on Apple platforms (iOS, macOS) and cannot be viewed directly in a web browser.</p>
            </div>
            
            <div class="card">
                <h2>Project Status</h2>
                <p>✅ Server is running</p>
                <p>✅ Swift environment is working</p>
            </div>
            
            <div class="card">
                <h2>Supabase Configuration</h2>
                <p>Status of your Supabase environment variables:</p>
                
                <p>
                    <strong>SUPABASE_URL:</strong> 
                    <span class="status \(supabaseURL != "Not set" ? "status-success" : "status-warning")">
                        \(supabaseURL != "Not set" ? "Set" : "Not set")
                    </span>
                </p>
                
                <p>
                    <strong>SUPABASE_KEY:</strong> 
                    <span class="status \(supabaseKeyStatus == "Set" ? "status-success" : "status-warning")">
                        \(supabaseKeyStatus)
                    </span>
                </p>
                
                <p>To modify these environment variables, you can set them in your project settings.</p>
            </div>
            
            <div class="card">
                <h2>Next Steps</h2>
                <ol>
                    <li>Check the README.md for project overview and setup</li>
                    <li>Follow Setup.md for Supabase project configuration</li>
                    <li>View code examples in the SupabaseChat directory</li>
                </ol>
            </div>
        </body>
        </html>
        """
        
        // Create HTTP response
        let response = """
        HTTP/1.1 200 OK
        Content-Type: text/html
        Content-Length: \(html.utf8.count)
        Connection: close
        
        \(html)
        """
        
        // Send response
        let responseData = Array(response.utf8)
        _ = responseData.withUnsafeBufferPointer { ptr in
            send(clientSocket, ptr.baseAddress, ptr.count, 0)
        }
        
        // Close connection
        close(clientSocket)
    }
    
    func stop() {
        if serverSocket != -1 {
            close(serverSocket)
            print("HTTP server stopped")
        }
    }
}

// Print environment variables for debugging
let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "Not set"
print("Environment variables:")
print("SUPABASE_URL: \(supabaseURL)")
if ProcessInfo.processInfo.environment["SUPABASE_KEY"] != nil {
    print("SUPABASE_KEY: [Set but not displayed for security]")
} else {
    print("SUPABASE_KEY: Not set")
}

print()
print("SupabaseChat app information:")
print("This is a mock server since Swift apps need to run on Apple platforms")
print("See README.md for more information about this project")

// Start the server
let server = SimpleHTTPServer(port: 5000)
server.start()