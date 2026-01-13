-- Enable Realtime for relevant tables
-- Supabase requires explicit enabling of replication for tables to support Realtime subscriptions.

-- Enable replication for 'chats' table
alter publication supabase_realtime add table public.chats;

-- Enable replication for 'users' table (useful for profile updates in UI)
alter publication supabase_realtime add table public.users;

-- Enable replication for 'properties' table (if we want live updates on properties)
alter publication supabase_realtime add table public.properties;
