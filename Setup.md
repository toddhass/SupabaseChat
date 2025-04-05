# Supabase Setup Guide for SupabaseChat App

Follow these steps to set up your Supabase project for the chat application:

## 1. Create a Supabase Project

1. Go to [https://app.supabase.io](https://app.supabase.io) and sign in
2. Click "New Project" and fill in the details
3. Wait for your database to start

## 2. Configure Authentication

1. Go to Authentication > Settings
2. Make sure "Enable Email Signup" is turned on
3. Set your site URL and redirect URLs (for production)
4. Set up password recovery if needed

## 3. Set Up Database Structure

Run the following SQL in the Supabase SQL Editor to create the necessary tables:

```sql
-- Create the profiles table to store additional user information
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users,
    username TEXT UNIQUE,
    avatar_url TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Enable Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policies for profile access
CREATE POLICY "Public profiles are viewable by everyone" ON profiles
    FOR SELECT USING (true);
    
CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Create the messages table
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Enable Row Level Security (RLS)
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows all users to read any message
CREATE POLICY "Allow select for all users" ON messages
    FOR SELECT USING (true);

-- Create a policy that allows authenticated users to insert their own messages
CREATE POLICY "Allow insert for authenticated users" ON messages
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Enable realtime for the messages table
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE profiles;
```

## 4. Get your API Keys

1. Go to Project Settings > API
2. Copy your:
   - Project URL (looks like: https://abc123xyz.supabase.co)
   - anon/public key (starts with "eyJh...")

## 5. Set Environment Variables

In your environment, set:
- `SUPABASE_URL`: Your project URL
- `SUPABASE_KEY`: Your anon/public key

## 6. Testing Realtime Functionality

To verify that realtime is working correctly:

1. Go to Supabase Dashboard > Database > Replication
2. Ensure that "Realtime" is enabled
3. Make sure the messages table is included in the publication

## 7. Testing Authentication

To verify that authentication is working correctly:

1. Go to Authentication > Users
2. You should see users appear here when they sign up through your app
3. You can manage users, reset passwords, and verify email addresses from this panel
4. Check Authentication > Policies to ensure your Row Level Security policies are correctly set

## Additional Information

For more details on Supabase features, visit:
- [Supabase Realtime Documentation](https://supabase.com/docs/guides/realtime)
- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)