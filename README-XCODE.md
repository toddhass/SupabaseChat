# SupabaseChat Xcode Project

## Overview

SupabaseChat is a Swift-based real-time chat application built with SwiftUI for the frontend and Supabase for the backend services. The application uses the Supabase-Swift SDK to interact with Supabase services for authentication, database, storage, and real-time messaging.

## Project Structure

The project is organized as follows:

```
SupabaseChat/
├── Models/               # Data models
│   ├── Message.swift     # Message data model
│   └── User.swift        # User and profile data models
├── Services/             # Communication with Supabase
│   ├── AuthenticationService.swift  # Authentication logic
│   ├── ChatService.swift            # Messaging and channel logic
│   └── SupabaseService.swift        # Core Supabase integration
├── Utilities/            # Helper functions
│   ├── DateFormatter+Extensions.swift
│   └── EnvironmentValues+Extensions.swift
├── Views/                # SwiftUI views
│   ├── AuthenticationView.swift  # Login/signup screen
│   ├── ChatView.swift            # Main chat interface
│   ├── MessageRow.swift          # Individual message component
│   ├── ProfileImageView.swift    # User avatar component
│   ├── ProfileView.swift         # User profile screen
│   ├── SignInView.swift          # Sign in form
│   ├── SignUpView.swift          # Sign up form
│   ├── UserInputView.swift       # Message input component
│   └── UserStatusView.swift      # Online status indicator
├── ContentView.swift     # Root view
└── SupabaseChatApp.swift # App entry point
```

## Features

- 🔐 **Authentication**: Full user signup/login flow with Supabase Auth
- 💬 **Real-time Messaging**: Instant message delivery using Supabase Realtime
- 👤 **User Profiles**: User profiles with customizable avatars stored in Supabase Storage
- 🟢 **Online Status**: Track and display user online/offline status
- 🎨 **Animated UI**: Smooth animations for message delivery and status changes

## Setup Instructions

### Prerequisites

- Xcode 14.0 or later
- Swift 5.6 or later
- iOS 15.0+ / macOS 12.0+
- A Supabase account and project

### Installation

1. Clone this repository or create a new Xcode project and add the files from this repository
2. Set up your Supabase project using the instructions in `SUPABASE_SETUP.md`
3. Configure your Supabase credentials in Xcode following the instructions in `XcodeSetup.md`
4. Install the Supabase-Swift SDK via Swift Package Manager:
   - Add the package dependency: `https://github.com/supabase-community/supabase-swift`

### Configuration

1. Set your Supabase URL and API Key in environment variables (see `XcodeSetup.md`)
2. Run the database setup script from `create.sql` in your Supabase SQL Editor

## Usage

### Authentication

```swift
// Sign up a new user
await authState.signUp(email: "user@example.com", password: "securePassword", username: "newuser")

// Sign in an existing user
await authState.signIn(email: "user@example.com", password: "securePassword")

// Sign out
await authState.signOut()
```

### Messaging

```swift
// Send a message
await chatService.sendMessage(channelId: "general", content: "Hello world!")

// Fetch channel messages
let messages = await chatService.getChannelMessages(channelId: "general")
```

### User Status

```swift
// Update user status
await userService.updateStatus(isOnline: true)

// Listen for status changes
let subscription = supabase
    .from("user_status")
    .on(.update) { payload in
        // Handle status update
    }
    .subscribe()
```

## Troubleshooting

If you encounter any issues:

1. Verify your Supabase URL and API key are correct
2. Ensure the Supabase database is set up with the correct tables and RLS policies
3. Check that you've enabled the appropriate Supabase services (Auth, Storage, Realtime)
4. Look for specific error messages in the Xcode debug console

## Additional Resources

- [Supabase-Swift SDK Documentation](https://github.com/supabase-community/supabase-swift)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Supabase Documentation](https://supabase.com/docs)