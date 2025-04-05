#!/usr/bin/env python3
import os
import json
import http.server
import socketserver
from http import HTTPStatus
from urllib.parse import urlparse, parse_qs

# Get Supabase environment variables - needed for Swift app integration
supabase_url = os.environ.get('SUPABASE_URL', 'Not set')
supabase_key_status = 'Set' if os.environ.get('SUPABASE_KEY') else 'Not set'

# User status tracking (would be in a database in a real app)
users = {
    "user1": {"id": "user1", "username": "sarah_dev", "is_online": False},
    "user2": {"id": "user2", "username": "alex_swift", "is_online": False},
    "user3": {"id": "user3", "username": "taylor_code", "is_online": False}
}

# Helper function to get all user statuses
def get_user_statuses():
    return {"users": list(users.values())}

# API Request Handler
class UserStatusHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # Parse URL and extract path and query parameters
        parsed_url = urlparse(self.path)
        path = parsed_url.path
        query_params = parse_qs(parsed_url.query)

        # Handle API endpoints
        if path == "/api/users":
            # Return all users and their statuses
            self.send_response(HTTPStatus.OK)
            self.send_header("Content-type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")  # CORS for testing
            self.end_headers()
            self.wfile.write(json.dumps(get_user_statuses()).encode())
            return

        elif path.startswith("/api/users/"):
            # Get user by ID
            user_id = path.split("/")[-1]
            if user_id in users:
                self.send_response(HTTPStatus.OK)
                self.send_header("Content-type", "application/json")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(json.dumps(users[user_id]).encode())
            else:
                self.send_response(HTTPStatus.NOT_FOUND)
                self.send_header("Content-type", "application/json")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(json.dumps({"error": "User not found"}).encode())
            return

        elif path == "/api/toggle-status":
            # Toggle user online status
            user_id = query_params.get("user_id", [""])[0]
            if user_id in users:
                users[user_id]["is_online"] = not users[user_id]["is_online"]
                self.send_response(HTTPStatus.OK)
                self.send_header("Content-type", "application/json")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(json.dumps(users[user_id]).encode())
            else:
                self.send_response(HTTPStatus.NOT_FOUND)
                self.send_header("Content-type", "application/json")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(json.dumps({"error": "User not found"}).encode())
            return

        # If not an API endpoint, serve an HTML page with instructions
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        
        html = f"""
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>User Status API</title>
            <style>
                body {{
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    max-width: 800px;
                    margin: 0 auto;
                    padding: 20px;
                    line-height: 1.6;
                }}
                h1 {{
                    color: #007AFF;
                }}
                .endpoint {{
                    background-color: #f5f5f7;
                    padding: 15px;
                    border-radius: 8px;
                    margin-bottom: 20px;
                }}
                .method {{
                    font-weight: bold;
                    color: #ff9500;
                }}
                code {{
                    background-color: #eee;
                    padding: 2px 4px;
                    border-radius: 3px;
                }}
                .user-list {{
                    list-style-type: none;
                    padding: 0;
                }}
                .user-item {{
                    display: flex;
                    align-items: center;
                    padding: 10px;
                    border-bottom: 1px solid #eee;
                }}
                .user-avatar {{
                    width: 40px;
                    height: 40px;
                    border-radius: 50%;
                    background-color: #007AFF;
                    color: white;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    margin-right: 10px;
                    font-weight: bold;
                }}
                .user-info {{
                    flex: 1;
                }}
                .user-status {{
                    font-size: 12px;
                    padding: 3px 8px;
                    border-radius: 10px;
                    color: white;
                }}
                .status-online {{
                    background-color: #34C759;
                }}
                .status-offline {{
                    background-color: #FF3B30;
                }}
                .toggle-button {{
                    background-color: #007AFF;
                    color: white;
                    border: none;
                    padding: 5px 10px;
                    border-radius: 4px;
                    cursor: pointer;
                }}
                .toggle-button:hover {{
                    background-color: #005ecb;
                }}
            </style>
        </head>
        <body>
            <h1>User Status API</h1>
            <p>This API provides endpoints to check and update user online status. Integration with the Swift app will allow real-time user status updates.</p>
            
            <h2>API Endpoints</h2>
            
            <div class="endpoint">
                <h3><span class="method">GET</span> /api/users</h3>
                <p>Get status information for all users.</p>
                <p>Example response:</p>
                <pre><code>{json.dumps(get_user_statuses(), indent=2)}</code></pre>
            </div>
            
            <div class="endpoint">
                <h3><span class="method">GET</span> /api/users/:id</h3>
                <p>Get status information for a specific user by ID.</p>
                <p>Example: <code>/api/users/user1</code></p>
                <p>Example response:</p>
                <pre><code>{json.dumps(users["user1"], indent=2)}</code></pre>
            </div>
            
            <div class="endpoint">
                <h3><span class="method">GET</span> /api/toggle-status?user_id=:id</h3>
                <p>Toggle the online status of a user.</p>
                <p>Example: <code>/api/toggle-status?user_id=user1</code></p>
            </div>
            
            <h2>Current Users</h2>
            <ul class="user-list">
            """
        
        # Add each user with toggle button
        for user_id, user in users.items():
            status_class = "status-online" if user["is_online"] else "status-offline"
            status_text = "Online" if user["is_online"] else "Offline"
            avatar_text = user["username"][0].upper()
            
            html += f"""
                <li class="user-item">
                    <div class="user-avatar">{avatar_text}</div>
                    <div class="user-info">
                        <div><strong>{user["username"]}</strong></div>
                        <div>ID: {user["id"]}</div>
                    </div>
                    <span class="user-status {status_class}">{status_text}</span>
                    <button class="toggle-button" onclick="toggleStatus('{user_id}')">Toggle Status</button>
                </li>
            """
        
        html += """
            </ul>
            
            <script>
                function toggleStatus(userId) {
                    fetch(`/api/toggle-status?user_id=${userId}`)
                        .then(response => response.json())
                        .then(data => {
                            // Reload page to show updated status
                            window.location.reload();
                        })
                        .catch(error => console.error('Error toggling status:', error));
                }
            </script>
        </body>
        </html>
        """
        
        self.wfile.write(html.encode())

def run_server(port=5002):
    handler = UserStatusHandler
    with socketserver.TCPServer(("0.0.0.0", port), handler) as httpd:
        print(f"User Status API server started at http://0.0.0.0:{port}")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass
        finally:
            httpd.server_close()
            print("Server stopped.")

if __name__ == "__main__":
    run_server()