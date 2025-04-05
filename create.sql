-- create.sql
-- SQL setup for Supabase SupabaseChat application

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create profiles table that extends the auth.users table
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  status TEXT DEFAULT 'offline',
  last_seen TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create messages table for chat messages
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  is_edited BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create channel table for chat channels
CREATE TABLE IF NOT EXISTS public.channels (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  is_private BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create channel_messages to link messages to channels
CREATE TABLE IF NOT EXISTS public.channel_messages (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  channel_id UUID REFERENCES public.channels(id) ON DELETE CASCADE NOT NULL,
  message_id UUID REFERENCES public.messages(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(channel_id, message_id)
);

-- Create channel_members to track channel members
CREATE TABLE IF NOT EXISTS public.channel_members (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  channel_id UUID REFERENCES public.channels(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(channel_id, user_id)
);

-- Create user_status table to track online/offline status
CREATE TABLE IF NOT EXISTS public.user_status (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  is_online BOOLEAN DEFAULT FALSE,
  last_status_change TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create read receipts table
CREATE TABLE IF NOT EXISTS public.read_receipts (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  channel_id UUID REFERENCES public.channels(id) ON DELETE CASCADE NOT NULL,
  last_read_message_id UUID REFERENCES public.messages(id) ON DELETE CASCADE,
  read_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(user_id, channel_id)
);

-- Create message reactions table
CREATE TABLE IF NOT EXISTS public.message_reactions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  message_id UUID REFERENCES public.messages(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  reaction TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(message_id, user_id, reaction)
);

-- Create a trigger to keep user status updated
CREATE OR REPLACE FUNCTION public.handle_user_status_change()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.profiles
  SET 
    status = CASE WHEN NEW.is_online THEN 'online' ELSE 'offline' END,
    last_seen = CASE WHEN NEW.is_online THEN now() ELSE now() END,
    updated_at = now()
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_user_status_change
  AFTER INSERT OR UPDATE ON public.user_status
  FOR EACH ROW
  EXECUTE PROCEDURE public.handle_user_status_change();

-- Create a function to update timestamps
CREATE OR REPLACE FUNCTION update_timestamps()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply timestamp triggers
CREATE TRIGGER update_profiles_timestamp
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE PROCEDURE update_timestamps();

CREATE TRIGGER update_messages_timestamp
  BEFORE UPDATE ON public.messages
  FOR EACH ROW
  EXECUTE PROCEDURE update_timestamps();

CREATE TRIGGER update_channels_timestamp
  BEFORE UPDATE ON public.channels
  FOR EACH ROW
  EXECUTE PROCEDURE update_timestamps();

-- Create default channel
INSERT INTO public.channels (name, description, is_private)
VALUES ('general', 'General chat for everyone', false)
ON CONFLICT (name) DO NOTHING;

-- Setup Row-Level Security (RLS) policies

-- Profiles table RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by everyone" 
ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile" 
ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Messages table RLS
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Messages are viewable by everyone" 
ON public.messages FOR SELECT USING (true);

CREATE POLICY "Users can insert their own messages" 
ON public.messages FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own messages" 
ON public.messages FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own messages" 
ON public.messages FOR DELETE USING (auth.uid() = user_id);

-- Channels table RLS
ALTER TABLE public.channels ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public channels are viewable by everyone" 
ON public.channels FOR SELECT USING (NOT is_private OR EXISTS (
  SELECT 1 FROM public.channel_members 
  WHERE channel_members.channel_id = channels.id AND channel_members.user_id = auth.uid()
));

CREATE POLICY "Anyone can create a channel" 
ON public.channels FOR INSERT WITH CHECK (true);

-- Channel messages RLS
ALTER TABLE public.channel_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Channel messages are viewable through channel access" 
ON public.channel_messages FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.channels
    WHERE channels.id = channel_messages.channel_id 
    AND (NOT channels.is_private OR EXISTS (
      SELECT 1 FROM public.channel_members 
      WHERE channel_members.channel_id = channels.id AND channel_members.user_id = auth.uid()
    ))
  )
);

-- User status RLS
ALTER TABLE public.user_status ENABLE ROW LEVEL SECURITY;

CREATE POLICY "User status is viewable by everyone" 
ON public.user_status FOR SELECT USING (true);

CREATE POLICY "Users can update their own status" 
ON public.user_status FOR UPDATE USING (auth.uid() = id);

-- Enable realtime for tables that need it
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_status;
ALTER PUBLICATION supabase_realtime ADD TABLE public.channel_messages;

-- Create function to handle new user registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, avatar_url)
  VALUES (
    NEW.id, 
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8)),
    'https://ui-avatars.com/api/?name=' || COALESCE(NEW.raw_user_meta_data->>'username', 'User') || '&background=random'
  );
  
  INSERT INTO public.user_status (id, is_online)
  VALUES (NEW.id, true);
  
  -- Add the user to the general channel
  INSERT INTO public.channel_members (channel_id, user_id)
  SELECT id, NEW.id FROM public.channels WHERE name = 'general';
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile and status entries for new users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE PROCEDURE public.handle_new_user();