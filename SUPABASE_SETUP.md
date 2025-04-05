# Supabase Setup for SupabaseChat

This guide explains how to set up the database structure for the SupabaseChat application using Supabase.

## Prerequisites

- A Supabase account (you can create one at [https://supabase.com](https://supabase.com))
- A Supabase project created in your account

## Setup Instructions

1. **Log in to your Supabase project dashboard**

2. **Navigate to the SQL Editor**
   - In the left sidebar, click on "SQL Editor"
   - Click "New Query" to open a new SQL editor window

3. **Run the SQL Script**
   - Copy the entire content of the `create.sql` file
   - Paste it into the SQL editor window
   - Click "Run" to execute the SQL script

4. **Verify the Setup**
   - Navigate to "Table Editor" in the left sidebar
   - You should see the following tables created:
     - `profiles`
     - `messages`
     - `channels` 
     - `channel_messages`
     - `channel_members`
     - `user_status`
     - `read_receipts`
     - `message_reactions`

5. **Set up Authentication**
   - Go to "Authentication" in the left sidebar
   - Under "Settings", make sure Email authentication is enabled
   - Optionally, you can configure additional providers like Google, GitHub, etc.

6. **Configure Storage**
   - Go to "Storage" in the left sidebar
   - Create a new bucket called "avatars" for storing user profile images
   - Configure the following bucket policy for "avatars":
     ```sql
     CREATE POLICY "Avatar images are publicly accessible."
     ON storage.objects FOR SELECT
     USING (bucket_id = 'avatars');
     
     CREATE POLICY "Users can upload avatars."
     ON storage.objects FOR INSERT
     WITH CHECK (bucket_id = 'avatars' AND auth.uid() IS NOT NULL);
     
     CREATE POLICY "Users can update their own avatars."
     ON storage.objects FOR UPDATE
     USING (bucket_id = 'avatars' AND auth.uid() = owner);
     ```

7. **Enable Realtime**
   - Go to "Database" → "Replication"
   - Enable realtime for the following tables:
     - `messages`
     - `user_status`
     - `channel_messages`

## Accessing from Swift

Use the following environment variables in your Swift application to connect to Supabase:

```swift
let supabaseUrl = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
let supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_KEY"] ?? ""
```

## Schema Overview

### Profiles Table
Extends Supabase Auth users with additional profile information:
- `id`: UUID (linked to auth.users)
- `username`: Text (unique)
- `display_name`: Text
- `avatar_url`: Text
- `status`: Text (online/offline)
- `last_seen`: Timestamp
- `created_at`: Timestamp
- `updated_at`: Timestamp

### Messages Table
Stores all chat messages:
- `id`: UUID
- `user_id`: UUID (linked to profiles)
- `content`: Text
- `is_edited`: Boolean
- `created_at`: Timestamp
- `updated_at`: Timestamp

### Channels Table
Represents chat channels:
- `id`: UUID
- `name`: Text (unique)
- `description`: Text
- `is_private`: Boolean
- `created_at`: Timestamp
- `updated_at`: Timestamp

### User Status Table
Tracks user online/offline status:
- `id`: UUID (linked to profiles)
- `is_online`: Boolean
- `last_status_change`: Timestamp

### Security
The SQL script sets up Row Level Security (RLS) policies to ensure:
- Users can only update their own profiles
- Public channels are visible to everyone
- Private channels are only visible to members
- Users can only create/update/delete their own messages

### Triggers
Automatic triggers handle:
- User profile creation on registration
- Status updates
- Timestamp maintenance
- Default channel membership

## Next Steps

After setting up the database structure, use the Supabase-Swift SDK to interact with your data from the Swift application.

```swift
// Example: Fetch user profile
let userProfile = await supabase
    .from("profiles")
    .select()
    .eq("id", userId)
    .single()
    .execute()
```