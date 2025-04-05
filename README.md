# SupabaseChat - Real-time SwiftUI Chat App

A real-time chat application built with SwiftUI and powered by Supabase and the Supabase Swift SDK.

## Features

- Real-time messaging with Supabase Realtime
- SwiftUI interface for a native Apple platform experience
- Full user authentication with Supabase Auth:
  - Email and password sign-up and sign-in
  - User profile management
  - Secure session handling
  - Profile editing capabilities
- Persistent message storage in Supabase database
- Playful animations throughout the user experience:
  - Animated loading indicators for messages being sent
  - Bounce and scale effects when messages appear
  - Pulsing send button animation
  - Animated empty state with bouncing chat icon
  - Spring animations in authentication views
  - Interactive validation feedback
  - Smooth transitions between screens

## Requirements

- macOS 12.0+ or iOS 15.0+
- Swift 5.7+
- Supabase project

## Setup Instructions

1. Create a new Supabase project at [https://app.supabase.io](https://app.supabase.io)
2. Run the SQL setup script from the `Setup.md` file to create the required tables and enable real-time functionality
3. Set the following environment variables:
   - `SUPABASE_URL`: Your Supabase project URL
   - `SUPABASE_KEY`: Your Supabase anon/public key

## Run the Project

```bash
swift run
```

## Project Structure

- **Models**: Data models including Message and User
- **Services**: Supabase and Chat services for data handling
- **Views**: SwiftUI views for the user interface
- **Utilities**: Helper extensions and utilities

## Deployment Notes

This is a native SwiftUI application designed to run on Apple platforms. When run in Replit, it will start a simple HTTP server that displays information about the project instead of the actual SwiftUI interface.