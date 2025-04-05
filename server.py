#!/usr/bin/env python3
import os
import http.server
import socketserver
from http import HTTPStatus
import json

# Get Supabase environment variables
supabase_url = os.environ.get('SUPABASE_URL', 'Not set')
supabase_key_status = 'Set' if os.environ.get('SUPABASE_KEY') else 'Not set'

# Session status variable (would be managed by cookies in a real app)
session_active = False

# Print environment variables for debugging
print("Environment variables:")
print(f"SUPABASE_URL: {supabase_url}")
if os.environ.get('SUPABASE_KEY'):
    print("SUPABASE_KEY: [Set but not displayed for security]")
else:
    print("SUPABASE_KEY: Not set")

print("\nSupabaseChat app information:")
print("This is a server displaying information about the Swift Supabase chat project")
print("See README.md for more information about this project")

# Mock data to simulate the app functionality
def get_mock_data():
    return {
        "users": [
            {"id": "user1", "username": "sarah_dev", "avatar_url": "https://ui-avatars.com/api/?name=Sarah&background=0D8ABC&color=fff"},
            {"id": "user2", "username": "alex_swift", "avatar_url": "https://ui-avatars.com/api/?name=Alex&background=FF5722&color=fff"},
            {"id": "user3", "username": "taylor_code", "avatar_url": "https://ui-avatars.com/api/?name=Taylor&background=4CAF50&color=fff"}
        ],
        "messages": [
            {"id": "msg1", "user_id": "user2", "content": "Hi everyone! Just joined this chat app.", "created_at": "2025-04-01T14:22:00Z"},
            {"id": "msg2", "user_id": "user1", "content": "Welcome to SupabaseChat! Let me know if you have any questions about the features.", "created_at": "2025-04-01T14:24:00Z"},
            {"id": "msg3", "user_id": "user3", "content": "The real-time functionality is really smooth!", "created_at": "2025-04-01T14:25:30Z"},
            {"id": "msg4", "user_id": "user2", "content": "I like how the messages animate in. Nice touch!", "created_at": "2025-04-01T14:26:45Z"},
            {"id": "msg5", "user_id": "user1", "content": "Thanks! We also added full authentication with Supabase Auth and user profiles.", "created_at": "2025-04-01T14:28:10Z"},
            {"id": "msg6", "user_id": "user3", "content": "The profile management is great. I just updated my avatar!", "created_at": "2025-04-01T14:30:22Z"}
        ]
    }

class SupabaseChatHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        global session_active
        
        if self.path == "/api/data":
            self.send_response(HTTPStatus.OK)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            data = get_mock_data()
            self.wfile.write(json.dumps(data).encode())
            return
        
        elif self.path == "/api/login":
            # Toggle login status
            session_active = True
            self.send_response(HTTPStatus.OK)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "success", "logged_in": True}).encode())
            return
            
        elif self.path == "/api/logout":
            # Toggle login status
            session_active = False
            self.send_response(HTTPStatus.OK)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "success", "logged_in": False}).encode())
            return
            
        elif self.path == "/api/status":
            # Return current login status
            self.send_response(HTTPStatus.OK)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"logged_in": session_active}).encode())
            return
        
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        
        # Create status classes for the HTML
        supabase_url_status_class = "status-success" if supabase_url != "Not set" else "status-warning"
        supabase_key_status_class = "status-success" if supabase_key_status == "Set" else "status-warning"
        
        # Create HTML content
        html = f"""
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>SupabaseChat - SwiftUI App</title>
            <style>
                :root {{
                    --primary-color: #007AFF;
                    --secondary-color: #5AC8FA;
                    --success-color: #34C759;
                    --warning-color: #FF9500;
                    --error-color: #FF3B30;
                    --background-color: #F2F2F7;
                    --card-background: #FFFFFF;
                    --text-primary: #1C1C1E;
                    --text-secondary: #8E8E93;
                    --border-radius: 10px;
                    --spacing: 20px;
                    --header-height: 60px;
                }}
                
                * {{
                    box-sizing: border-box;
                    margin: 0;
                    padding: 0;
                }}
                
                body {{
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    line-height: 1.6;
                    color: var(--text-primary);
                    background-color: var(--background-color);
                    padding: 0;
                    margin: 0;
                    overflow-x: hidden;
                }}
                
                .container {{
                    max-width: 1200px;
                    margin: 0 auto;
                    padding: 0 var(--spacing);
                    width: 100%;
                    box-sizing: border-box;
                }}
                
                header {{
                    background-color: var(--primary-color);
                    color: white;
                    padding: var(--spacing);
                    position: sticky;
                    top: 0;
                    z-index: 100;
                    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                }}
                
                header h1 {{
                    margin: 0;
                    font-size: 1.8rem;
                }}
                
                .header-content {{
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                }}
                
                .user-status {{
                    display: flex;
                    align-items: center;
                    font-size: 0.9rem;
                }}
                
                #logged-out-state, #logged-in-state {{
                    display: flex;
                    align-items: center;
                    gap: 8px;
                }}
                
                .status-indicator {{
                    width: 10px;
                    height: 10px;
                    border-radius: 50%;
                    display: inline-block;
                }}
                
                .status-indicator.online {{
                    background-color: #4CAF50;
                    box-shadow: 0 0 5px #4CAF50;
                }}
                
                .status-indicator.offline {{
                    background-color: #f44336;
                }}
                
                .username {{
                    font-weight: bold;
                    color: #fff;
                }}
                
                .avatar-small {{
                    width: 24px;
                    height: 24px;
                    border-radius: 50%;
                    overflow: hidden;
                    margin-left: 5px;
                }}
                
                .avatar-small img {{
                    width: 100%;
                    height: 100%;
                    object-fit: cover;
                }}
                
                .login-button, .logout-button {{
                    background-color: rgba(255, 255, 255, 0.2);
                    color: white;
                    border: none;
                    padding: 5px 10px;
                    border-radius: 4px;
                    cursor: pointer;
                    font-size: 0.8rem;
                    transition: background-color 0.2s;
                    margin-left: 8px;
                }}
                
                .login-button:hover, .logout-button:hover {{
                    background-color: rgba(255, 255, 255, 0.3);
                }}
                
                .main-content {{
                    display: grid;
                    grid-template-columns: 1fr 2fr;
                    gap: var(--spacing);
                    padding: var(--spacing) 0;
                    width: 100%;
                    box-sizing: border-box;
                    overflow: hidden;
                }}
                
                @media (max-width: 768px) {{
                    .main-content {{
                        grid-template-columns: 1fr;
                    }}
                }}
                
                .sidebar {{
                    position: sticky;
                    top: calc(var(--header-height) + var(--spacing));
                    height: min-content;
                    max-width: 100%;
                    box-sizing: border-box;
                }}
                
                .content {{
                    width: 100%;
                    box-sizing: border-box;
                    overflow: hidden;
                }}
                
                .card {{
                    background-color: var(--card-background);
                    border-radius: var(--border-radius);
                    padding: var(--spacing);
                    margin-bottom: var(--spacing);
                    box-shadow: 0 2px 10px rgba(0,0,0,0.05);
                }}
                
                .card h2 {{
                    color: var(--primary-color);
                    margin-bottom: 15px;
                    font-size: 1.3rem;
                    display: flex;
                    align-items: center;
                }}
                
                .card h2 i {{
                    margin-right: 10px;
                }}
                
                ul, ol {{
                    padding-left: 25px;
                    margin: 10px 0;
                }}
                
                li {{
                    margin-bottom: 8px;
                }}
                
                a {{
                    color: var(--primary-color);
                    text-decoration: none;
                }}
                
                a:hover {{
                    text-decoration: underline;
                }}
                
                code {{
                    background-color: #eaeaea;
                    padding: 2px 4px;
                    border-radius: 4px;
                    font-family: Menlo, Monaco, "Courier New", monospace;
                }}
                
                .button {{
                    background-color: var(--primary-color);
                    color: white;
                    border: none;
                    padding: 10px 20px;
                    border-radius: 6px;
                    font-weight: bold;
                    text-decoration: none;
                    display: inline-block;
                    margin-top: 10px;
                    cursor: pointer;
                    transition: background-color 0.2s;
                }}
                
                .button:hover {{
                    background-color: #005ecb;
                }}
                
                .status {{
                    display: inline-block;
                    padding: 5px 10px;
                    border-radius: 4px;
                    font-weight: bold;
                }}
                
                .status-success {{
                    background-color: var(--success-color);
                    color: white;
                }}
                
                .status-warning {{
                    background-color: var(--warning-color);
                    color: white;
                }}
                
                /* Chat Demo UI */
                .chat-demo {{
                    display: flex;
                    flex-direction: column;
                    height: 550px;
                    border-radius: var(--border-radius);
                    overflow: hidden;
                    border: 1px solid #E5E5EA;
                }}
                
                .chat-header {{
                    background-color: var(--primary-color);
                    color: white;
                    padding: 15px;
                    display: flex;
                    align-items: center;
                }}
                
                .chat-header h3 {{
                    margin: 0;
                }}
                
                .chat-messages {{
                    flex: 1;
                    padding: 15px;
                    overflow-y: auto;
                    background-color: #F7F7FC;
                    display: flex;
                    flex-direction: column;
                }}
                
                .message {{
                    max-width: 80%;
                    margin-bottom: 15px;
                    position: relative;
                    animation: fadeIn 0.3s ease-out, scaleIn 0.2s ease-out;
                    display: flex;
                    flex-direction: row;
                    align-items: flex-start;
                }}
                
                .message-avatar {{
                    width: 36px;
                    height: 36px;
                    border-radius: 50%;
                    margin-right: 8px;
                    background-color: #E5E5EA;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-weight: bold;
                    color: white;
                    font-size: 14px;
                    flex-shrink: 0;
                    overflow: hidden;
                }}
                
                .message-avatar img {{
                    width: 100%;
                    height: 100%;
                    object-fit: cover;
                }}
                
                .message-content-wrapper {{
                    display: flex;
                    flex-direction: column;
                }}
                
                .message-bubble {{
                    padding: 10px 15px;
                    border-radius: 18px;
                    word-break: break-word;
                    max-width: 100%;
                }}
                
                @keyframes fadeIn {{
                    from {{ opacity: 0; }}
                    to {{ opacity: 1; }}
                }}
                
                @keyframes scaleIn {{
                    from {{ transform: scale(0.9); }}
                    to {{ transform: scale(1); }}
                }}
                
                @keyframes bounce {{
                    0%, 100% {{ transform: translateY(0); }}
                    50% {{ transform: translateY(-10px); }}
                }}
                
                .message.sent {{
                    align-self: flex-end;
                    flex-direction: row-reverse;
                }}

                .message.sent .message-avatar {{
                    margin-right: 0;
                    margin-left: 8px;
                }}
                
                .message.sent .message-bubble {{
                    background-color: var(--primary-color);
                    color: white;
                    border-bottom-right-radius: 5px;
                }}
                
                .message.received .message-bubble {{
                    background-color: #E5E5EA;
                    color: black;
                    border-bottom-left-radius: 5px;
                }}
                
                .message-info {{
                    font-size: 0.75rem;
                    margin-bottom: 5px;
                    display: flex;
                    align-items: center;
                }}
                
                .message-info img {{
                    width: 24px;
                    height: 24px;
                    border-radius: 50%;
                    margin-right: 5px;
                }}
                
                .message-time {{
                    font-size: 0.7rem;
                    color: rgba(0,0,0,0.5);
                    margin-top: 5px;
                    text-align: right;
                }}
                
                .sent .message-time {{
                    color: rgba(255,255,255,0.7);
                }}
                
                .chat-input {{
                    display: flex;
                    padding: 10px;
                    background-color: white;
                    border-top: 1px solid #E5E5EA;
                }}
                
                .chat-input input {{
                    flex: 1;
                    border: 1px solid #E5E5EA;
                    border-radius: 20px;
                    padding: 8px 15px;
                    margin-right: 10px;
                    outline: none;
                }}
                
                .chat-input button {{
                    background-color: var(--primary-color);
                    color: white;
                    border: none;
                    border-radius: 50%;
                    width: 40px;
                    height: 40px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    cursor: pointer;
                    transition: transform 0.2s;
                }}
                
                .chat-input button:hover {{
                    transform: scale(1.1);
                }}
                
                .chat-input button i {{
                    font-size: 1.2rem;
                }}
                
                /* Auth Form Demo */
                .auth-forms {{
                    display: flex;
                    gap: var(--spacing);
                    margin-top: 30px;
                }}
                
                .auth-form {{
                    flex: 1;
                    background: white;
                    border-radius: var(--border-radius);
                    padding: var(--spacing);
                    box-shadow: 0 2px 10px rgba(0,0,0,0.05);
                }}
                
                .auth-form h3 {{
                    margin-bottom: 15px;
                    color: var(--primary-color);
                    text-align: center;
                }}
                
                .form-group {{
                    margin-bottom: 15px;
                }}
                
                .form-group label {{
                    display: block;
                    margin-bottom: 5px;
                    font-weight: 500;
                }}
                
                .form-group input {{
                    width: 100%;
                    padding: 10px;
                    border: 1px solid #E5E5EA;
                    border-radius: 6px;
                    outline: none;
                }}
                
                .form-group input:focus {{
                    border-color: var(--primary-color);
                }}
                
                .auth-form button {{
                    width: 100%;
                    padding: 12px;
                    background-color: var(--primary-color);
                    color: white;
                    border: none;
                    border-radius: 6px;
                    font-weight: 600;
                    cursor: pointer;
                    transition: background-color 0.2s;
                }}
                
                .auth-form button:hover {{
                    background-color: #005ecb;
                }}
                
                @media (max-width: 768px) {{
                    .auth-forms {{
                        flex-direction: column;
                    }}
                }}
                
                /* Animation demos */
                .animation-demo {{
                    display: flex;
                    flex-wrap: wrap;
                    gap: 20px;
                    margin-top: 20px;
                }}
                
                .animation-card {{
                    background-color: white;
                    border-radius: var(--border-radius);
                    padding: 15px;
                    width: calc(50% - 10px);
                    box-shadow: 0 2px 5px rgba(0,0,0,0.05);
                    text-align: center;
                }}
                
                @media (max-width: 600px) {{
                    .animation-card {{
                        width: 100%;
                    }}
                }}
                
                .animation-card h4 {{
                    margin-bottom: 10px;
                    color: var(--primary-color);
                }}
                
                .animation-example {{
                    height: 100px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }}
                
                .bounce-animation {{
                    animation: bounce 2s infinite;
                }}
                
                .pulse-animation {{
                    animation: pulse 2s infinite;
                }}
                
                @keyframes pulse {{
                    0% {{ transform: scale(1); }};
                    50% {{ transform: scale(1.1); }}
                    100% {{ transform: scale(1); }}
                }}
                
                .scale-animation {{
                    animation: scale 2s infinite;
                }}
                
                @keyframes scale {{
                    0% {{ transform: scale(1); opacity: 1; }};
                    50% {{ transform: scale(0.8); opacity: 0.8; }}
                    100% {{ transform: scale(1); opacity: 1; }}
                }}
                
                .loading-spinner {{
                    width: 40px;
                    height: 40px;
                    border: 3px solid rgba(0, 122, 255, 0.2);
                    border-radius: 50%;
                    border-top-color: var(--primary-color);
                    animation: spin 1s ease-in-out infinite;
                }}
                
                @keyframes spin {{
                    to {{ transform: rotate(360deg); }}
                }}
                
                /* Tab system */
                .tab-container {{
                    margin-bottom: 20px;
                }}
                
                .tab-buttons {{
                    display: flex;
                    border-bottom: 1px solid #E5E5EA;
                }}
                
                .tab-button {{
                    padding: 10px 20px;
                    background: none;
                    border: none;
                    cursor: pointer;
                    font-weight: 500;
                    color: var(--text-secondary);
                    border-bottom: 2px solid transparent;
                }}
                
                .tab-button.active {{
                    color: var(--primary-color);
                    border-bottom-color: var(--primary-color);
                }}
                
                .tab-content {{
                    display: none;
                    padding: 20px 0;
                }}
                
                .tab-content.active {{
                    display: block;
                }}
                
                footer {{
                    background-color: var(--primary-color);
                    color: white;
                    text-align: center;
                    padding: 20px;
                    margin-top: 40px;
                }}
            </style>
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">
            <script>
                document.addEventListener("DOMContentLoaded", function() {{
                    // Set up login status functionality
                    const loginButton = document.getElementById('login-button');
                    const logoutButton = document.getElementById('logout-button');
                    const loggedOutState = document.getElementById('logged-out-state');
                    const loggedInState = document.getElementById('logged-in-state');
                    
                    // Check current server login status
                    checkLoginStatus();
                    
                    // Add event listeners for login/logout
                    loginButton.addEventListener('click', function() {{
                        // Call the login API
                        fetch('/api/login')
                            .then(response => response.json())
                            .then(data => {{
                                if (data.status === 'success') {{
                                    // Update UI
                                    loggedOutState.style.display = 'none';
                                    loggedInState.style.display = 'flex';
                                    // Store in localStorage as well
                                    localStorage.setItem('supabaseChat_loggedIn', 'true');
                                }}
                            }})
                            .catch(error => console.error('Login error:', error));
                    }});
                    
                    logoutButton.addEventListener('click', function() {{
                        // Call the logout API
                        fetch('/api/logout')
                            .then(response => response.json())
                            .then(data => {{
                                if (data.status === 'success') {{
                                    // Update UI
                                    loggedInState.style.display = 'none';
                                    loggedOutState.style.display = 'flex';
                                    // Store in localStorage as well
                                    localStorage.setItem('supabaseChat_loggedIn', 'false');
                                }}
                            }})
                            .catch(error => console.error('Logout error:', error));
                    }});
                    
                    function checkLoginStatus() {{
                        // Check server status first, then use localStorage as fallback
                        fetch('/api/status')
                            .then(response => response.json())
                            .then(data => {{
                                const isLoggedIn = data.logged_in;
                                
                                if (isLoggedIn) {{
                                    loggedOutState.style.display = 'none';
                                    loggedInState.style.display = 'flex';
                                    localStorage.setItem('supabaseChat_loggedIn', 'true');
                                }} else {{
                                    // If not logged in on server, check localStorage
                                    const localLoggedIn = localStorage.getItem('supabaseChat_loggedIn') === 'true';
                                    if (localLoggedIn) {{
                                        // Local state says logged in, sync with server
                                        fetch('/api/login').catch(e => console.error(e));
                                        loggedOutState.style.display = 'none';
                                        loggedInState.style.display = 'flex';
                                    }} else {{
                                        loggedInState.style.display = 'none';
                                        loggedOutState.style.display = 'flex';
                                    }}
                                }}
                            }})
                            .catch(error => {{
                                console.error('Status check error:', error);
                                // Fallback to localStorage
                                const isLoggedIn = localStorage.getItem('supabaseChat_loggedIn') === 'true';
                                if (isLoggedIn) {{
                                    loggedOutState.style.display = 'none';
                                    loggedInState.style.display = 'flex';
                                }}
                            }});
                    }}
                    
                    // Load chat data
                    fetch('/api/data')
                        .then(response => response.json())
                        .then(data => populateChat(data))
                        .catch(error => console.error('Error loading data:', error));
                    
                    // Tab functionality
                    const tabButtons = document.querySelectorAll('.tab-button');
                    const tabContents = document.querySelectorAll('.tab-content');
                    
                    tabButtons.forEach(button => {{
                        button.addEventListener('click', () => {{
                            // Remove active class from all buttons and contents
                            tabButtons.forEach(btn => btn.classList.remove('active'));
                            tabContents.forEach(content => content.classList.remove('active'));
                            
                            // Add active class to current button
                            button.classList.add('active');
                            
                            // Show corresponding content
                            const tabId = button.getAttribute('data-tab');
                            document.getElementById(tabId).classList.add('active');
                        }});
                    }});
                    
                    // Set up send button for the chat demo
                    const sendButton = document.getElementById('send-button');
                    const messageInput = document.getElementById('message-input');
                    
                    sendButton.addEventListener('click', function() {{
                        sendMessage();
                    }});
                    
                    messageInput.addEventListener('keypress', function(e) {{
                        if (e.key === 'Enter') {{
                            sendMessage();
                        }}
                    }});
                    
                    function sendMessage() {{
                        const messageText = messageInput.value.trim();
                        if (messageText) {{
                            // Add message to UI
                            const messagesContainer = document.querySelector('.chat-messages');
                            const messageEl = document.createElement('div');
                            messageEl.className = 'message sent';
                            messageEl.innerHTML = `
                                <div class="message-avatar">
                                    <img src="https://ui-avatars.com/api/?name=Y&background=007BFF&color=fff" alt="You">
                                </div>
                                <div class="message-content-wrapper">
                                    <div class="message-bubble">${{messageText}}</div>
                                    <div class="message-time">Just now</div>
                                </div>
                            `;
                            messagesContainer.appendChild(messageEl);
                            
                            // Clear input
                            messageInput.value = '';
                            
                            // Scroll to bottom
                            messagesContainer.scrollTop = messagesContainer.scrollHeight;
                            
                            // Simulate response after a delay
                            setTimeout(() => {{
                                const responseEl = document.createElement('div');
                                responseEl.className = 'message received';
                                responseEl.innerHTML = `
                                    <div class="message-avatar">
                                        <img src="https://ui-avatars.com/api/?name=S&background=0D8ABC&color=fff" alt="Sarah">
                                    </div>
                                    <div class="message-content-wrapper">
                                        <div class="message-info">
                                            sarah_dev
                                        </div>
                                        <div class="message-bubble">Thanks for trying the SupabaseChat demo! This is a simulated response.</div>
                                        <div class="message-time">Just now</div>
                                    </div>
                                `;
                                messagesContainer.appendChild(responseEl);
                                messagesContainer.scrollTop = messagesContainer.scrollHeight;
                            }}, 1000);
                        }}
                    }}
                }});
                
                function populateChat(data) {{
                    const messagesContainer = document.querySelector('.chat-messages');
                    const users = data.users.reduce((acc, user) => {{
                        acc[user.id] = user;
                        return acc;
                    }}, {{}});
                    
                    // Empty the container first
                    messagesContainer.innerHTML = '';
                    
                    // Add messages in chronological order
                    data.messages.forEach(message => {{
                        const user = users[message.user_id];
                        const messageEl = document.createElement('div');
                        const isCurrentUser = message.user_id === 'user1'; // Just for demo
                        messageEl.className = `message ${{isCurrentUser ? 'sent' : 'received'}}`;
                        
                        // Format date
                        const date = new Date(message.created_at);
                        const timeString = date.toLocaleTimeString([], {{hour: '2-digit', minute:'2-digit'}});
                        
                        // Create message with new avatar structure
                        let html = `
                            <div class="message-avatar">
                                <img src="${{user.avatar_url}}" alt="${{user.username}}">
                            </div>
                            <div class="message-content-wrapper">
                        `;
                        
                        if (!isCurrentUser) {{
                            html += `
                                <div class="message-info">
                                    ${{user.username}}
                                </div>
                            `;
                        }}
                        
                        html += `
                                <div class="message-bubble">${{message.content}}</div>
                                <div class="message-time">${{timeString}}</div>
                            </div>
                        `;
                        
                        messageEl.innerHTML = html;
                        messagesContainer.appendChild(messageEl);
                    }});
                    
                    // Scroll to bottom
                    messagesContainer.scrollTop = messagesContainer.scrollHeight;
                }}
            </script>
        </head>
        <body>
            <header>
                <div class="container">
                    <div class="header-content">
                        <h1><i class="fas fa-comment-dots"></i> SupabaseChat - SwiftUI App</h1>
                        <div class="user-status">
                            <div id="logged-out-state">
                                <span class="status-indicator offline"></span>
                                <span>Not logged in</span>
                                <button id="login-button" class="login-button">Login</button>
                            </div>
                            <div id="logged-in-state" style="display: none;">
                                <span class="status-indicator online"></span>
                                <span>Logged in as</span>
                                <span class="username">sarah_dev</span>
                                <div class="avatar-small">
                                    <img src="https://ui-avatars.com/api/?name=S&background=0D8ABC&color=fff" alt="User">
                                </div>
                                <button id="logout-button" class="logout-button">Logout</button>
                            </div>
                        </div>
                    </div>
                </div>
            </header>
            
            <div class="container">
                <div class="main-content">
                    <div class="sidebar">
                        <div class="card">
                            <h2><i class="fas fa-info-circle"></i> About</h2>
                            <p>SupabaseChat is a real-time chat application built with SwiftUI and powered by Supabase's real-time features and authentication services.</p>
                            <p>As a SwiftUI app, it's designed to run natively on Apple platforms (iOS, macOS) and cannot be viewed directly in a web browser. This page provides a demonstration of its features.</p>
                        </div>
                        
                        <div class="card">
                            <h2><i class="fas fa-cogs"></i> Configuration</h2>
                            <p>Status of your Supabase environment variables:</p>
                            
                            <p style="margin-top: 10px;">
                                <strong>SUPABASE_URL:</strong> 
                                <span class="status {supabase_url_status_class}">
                                    {("Set" if supabase_url != "Not set" else "Not set")}
                                </span>
                            </p>
                            
                            <p style="margin-top: 10px;">
                                <strong>SUPABASE_KEY:</strong> 
                                <span class="status {supabase_key_status_class}">
                                    {supabase_key_status}
                                </span>
                            </p>
                        </div>
                        
                        <div class="card">
                            <h2><i class="fas fa-folder-open"></i> Project Structure</h2>
                            <ul>
                                <li><strong>Models:</strong> Message, User</li>
                                <li><strong>Services:</strong> 
                                    <ul>
                                        <li>SupabaseService</li>
                                        <li>AuthenticationService</li>
                                        <li>ChatService</li>
                                    </ul>
                                </li>
                                <li><strong>Views:</strong>
                                    <ul>
                                        <li>ContentView</li>
                                        <li>ChatView</li>
                                        <li>MessageRow</li>
                                        <li>AuthenticationView</li>
                                        <li>SignInView</li>
                                        <li>SignUpView</li>
                                        <li>ProfileView</li>
                                    </ul>
                                </li>
                            </ul>
                        </div>
                        
                        <div class="card">
                            <h2><i class="fas fa-user-shield"></i> Authentication</h2>
                            <p>The app implements comprehensive user authentication with:</p>
                            <ul>
                                <li>Email/password sign-up & sign-in</li>
                                <li>Session management</li>
                                <li>User profile data storage</li>
                                <li>Secure token handling</li>
                            </ul>
                        </div>
                    </div>
                    
                    <div class="content">
                        <div class="card">
                            <h2><i class="fas fa-comment-alt"></i> Chat Interface Demo</h2>
                            <p>This is a demonstration of how the SupabaseChat interface looks and functions:</p>
                            
                            <div class="chat-demo">
                                <div class="chat-header">
                                    <h3>SupabaseChat Room</h3>
                                </div>
                                <div class="chat-messages">
                                    <div class="message received">
                                        <div class="message-avatar">
                                            <img src="https://ui-avatars.com/api/?name=S&background=0D8ABC&color=fff" alt="Sarah">
                                        </div>
                                        <div class="message-content-wrapper">
                                            <div class="message-info">
                                                sarah_dev
                                            </div>
                                            <div class="message-bubble">Loading messages...</div>
                                            <div class="message-time">Just now</div>
                                        </div>
                                    </div>
                                </div>
                                <div class="chat-input">
                                    <input type="text" id="message-input" placeholder="Type a message...">
                                    <button id="send-button"><i class="fas fa-paper-plane"></i></button>
                                </div>
                            </div>
                            
                            <p style="margin-top: 15px;"><strong>Try it:</strong> Type a message and click send to simulate the chat experience!</p>
                        </div>
                        
                        <div class="card">
                            <h2><i class="fas fa-magic"></i> Playful Animations</h2>
                            <p>The app features various playful animations to enhance the user experience:</p>
                            
                            <div class="animation-demo">
                                <div class="animation-card">
                                    <h4>Message Bounce</h4>
                                    <div class="animation-example">
                                        <div class="message bounce-animation" style="margin: 0;">
                                            <div class="message-avatar">
                                                <img src="https://ui-avatars.com/api/?name=Y&background=007BFF&color=fff" alt="You">
                                            </div>
                                            <div class="message-content-wrapper">
                                                <div class="message-bubble" style="background: var(--primary-color); color: white;">Hello there!</div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                
                                <div class="animation-card">
                                    <h4>Pulsing Button</h4>
                                    <div class="animation-example">
                                        <button class="button pulse-animation" style="margin: 0;">
                                            <i class="fas fa-paper-plane"></i> Send
                                        </button>
                                    </div>
                                </div>
                                
                                <div class="animation-card">
                                    <h4>Loading Indicator</h4>
                                    <div class="animation-example">
                                        <div class="loading-spinner"></div>
                                    </div>
                                </div>
                                
                                <div class="animation-card">
                                    <h4>Scale Transition</h4>
                                    <div class="animation-example">
                                        <div class="scale-animation" style="background: var(--primary-color); color: white; padding: 15px; border-radius: 10px;">
                                            New Message!
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <div class="card">
                            <h2><i class="fas fa-user-lock"></i> Authentication Demo</h2>
                            <p>The app provides a complete authentication system with sign-up, sign-in, and profile management:</p>
                            
                            <div class="tab-container">
                                <div class="tab-buttons">
                                    <button class="tab-button active" data-tab="sign-in-tab">Sign In</button>
                                    <button class="tab-button" data-tab="sign-up-tab">Sign Up</button>
                                    <button class="tab-button" data-tab="profile-tab">Profile</button>
                                </div>
                                
                                <div class="tab-content active" id="sign-in-tab">
                                    <div class="auth-form">
                                        <h3>Sign In</h3>
                                        <div class="form-group">
                                            <label for="email">Email Address</label>
                                            <input type="email" id="email" placeholder="your@email.com">
                                        </div>
                                        <div class="form-group">
                                            <label for="password">Password</label>
                                            <input type="password" id="password" placeholder="••••••••">
                                        </div>
                                        <button>Sign In</button>
                                    </div>
                                </div>
                                
                                <div class="tab-content" id="sign-up-tab">
                                    <div class="auth-form">
                                        <h3>Create Account</h3>
                                        <div class="form-group">
                                            <label for="username">Username</label>
                                            <input type="text" id="username" placeholder="Choose a username">
                                        </div>
                                        <div class="form-group">
                                            <label for="email-signup">Email Address</label>
                                            <input type="email" id="email-signup" placeholder="your@email.com">
                                        </div>
                                        <div class="form-group">
                                            <label for="password-signup">Password</label>
                                            <input type="password" id="password-signup" placeholder="Choose a password">
                                        </div>
                                        <div class="form-group">
                                            <label for="password-confirm">Confirm Password</label>
                                            <input type="password" id="password-confirm" placeholder="Confirm your password">
                                        </div>
                                        <button>Create Account</button>
                                    </div>
                                </div>
                                
                                <div class="tab-content" id="profile-tab">
                                    <div class="auth-form">
                                        <h3>Edit Profile</h3>
                                        <div class="form-group">
                                            <label for="profile-username">Username</label>
                                            <input type="text" id="profile-username" value="sarah_dev">
                                        </div>
                                        <div class="form-group">
                                            <label for="profile-email">Email Address</label>
                                            <input type="email" id="profile-email" value="sarah@example.com">
                                        </div>
                                        <div class="form-group">
                                            <label for="profile-avatar">Avatar URL</label>
                                            <input type="text" id="profile-avatar" value="https://ui-avatars.com/api/?name=Sarah&background=0D8ABC&color=fff">
                                        </div>
                                        <button>Update Profile</button>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <div class="card">
                            <h2><i class="fas fa-star"></i> Key Features</h2>
                            <p>SupabaseChat combines powerful back-end capabilities with an elegant, animated user interface:</p>
                            
                            <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px; margin-top: 20px;">
                                <div style="background-color: white; border-radius: 10px; padding: 15px; box-shadow: 0 2px 5px rgba(0,0,0,0.05);">
                                    <div style="width: 30px; height: 30px; background-color: #007AFF; color: white; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin-bottom: 10px;">
                                        <i class="fas fa-bolt"></i>
                                    </div>
                                    <h4 style="margin: 0 0 5px 0; color: #007AFF;">Real-time Messaging</h4>
                                    <p style="margin: 0;">Instant message delivery using Supabase Realtime.</p>
                                </div>
                                
                                <div style="background-color: white; border-radius: 10px; padding: 15px; box-shadow: 0 2px 5px rgba(0,0,0,0.05);">
                                    <div style="width: 30px; height: 30px; background-color: #007AFF; color: white; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin-bottom: 10px;">
                                        <i class="fas fa-user-shield"></i>
                                    </div>
                                    <h4 style="margin: 0 0 5px 0; color: #007AFF;">Secure Authentication</h4>
                                    <p style="margin: 0;">Full user authentication with Supabase Auth.</p>
                                </div>
                                
                                <div style="background-color: white; border-radius: 10px; padding: 15px; box-shadow: 0 2px 5px rgba(0,0,0,0.05);">
                                    <div style="width: 30px; height: 30px; background-color: #007AFF; color: white; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin-bottom: 10px;">
                                        <i class="fas fa-magic"></i>
                                    </div>
                                    <h4 style="margin: 0 0 5px 0; color: #007AFF;">Playful Animations</h4>
                                    <p style="margin: 0;">Delightful animations throughout the interface.</p>
                                </div>
                                
                                <div style="background-color: white; border-radius: 10px; padding: 15px; box-shadow: 0 2px 5px rgba(0,0,0,0.05);">
                                    <div style="width: 30px; height: 30px; background-color: #007AFF; color: white; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin-bottom: 10px;">
                                        <i class="fas fa-database"></i>
                                    </div>
                                    <h4 style="margin: 0 0 5px 0; color: #007AFF;">Message Persistence</h4>
                                    <p style="margin: 0;">Messages stored securely in Supabase database.</p>
                                </div>
                            </div>
                        </div>
                        
                        <div class="card">
                            <h2><i class="fas fa-book"></i> Documentation</h2>
                            <p>For more information about this project:</p>
                            <ul>
                                <li>See the <strong>README.md</strong> for project overview</li>
                                <li>Follow <strong>Setup.md</strong> for Supabase configuration steps</li>
                                <li>Explore the code in the <strong>SupabaseChat</strong> directory</li>
                            </ul>
                            <p>The app uses these key technologies:</p>
                            <ul>
                                <li>SwiftUI - Apple's declarative UI framework</li>
                                <li>Supabase Swift SDK - for backend communication</li>
                                <li>Supabase Auth - for user authentication</li>
                                <li>Supabase Realtime - for real-time messaging</li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
            
            <footer>
                <div class="container">
                    <p>SupabaseChat - A real-time chat application built with SwiftUI and Supabase</p>
                </div>
            </footer>
        </body>
        </html>
        """
        
        self.wfile.write(html.encode())
        
    def log_message(self, format, *args):
        # Disable logging
        return

# Set up the server
PORT = 5000
handler = SupabaseChatHTTPRequestHandler
socketserver.TCPServer.allow_reuse_address = True

with socketserver.TCPServer(("", PORT), handler) as httpd:
    print(f"\nServer started at http://0.0.0.0:{PORT}")
    print("Press Ctrl+C to stop the server")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")