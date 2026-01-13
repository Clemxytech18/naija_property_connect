-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- USERS Table
-- Note: Supabase handles auth separately in auth.users. 
-- This table is for public profiles linked to auth.users.
create table if not exists public.users (
  id uuid references auth.users on delete cascade not null primary key,
  email text,
  full_name text,
  phone text,
  role text check (role in ('tenant', 'landlord', 'agent')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS for Users
alter table public.users enable row level security;
create policy "Public profiles are viewable by everyone." on public.users for select using (true);
create policy "Users can insert their own profile." on public.users for insert with check (auth.uid() = id);
create policy "Users can update their own profile." on public.users for update using (auth.uid() = id);

-- PROPERTIES Table
create table if not exists public.properties (
  id uuid default uuid_generate_v4() primary key,
  owner_id uuid references public.users(id) not null,
  title text not null,
  description text,
  type text, -- 'Apartment', 'House', etc.
  location text,
  price numeric,
  images text[], -- Array of image URLs (renamed from media)
  bedrooms numeric,
  bathrooms numeric,
  video text, -- Video URL
  features text[], -- Array of features
  agent_fee numeric,
  legal_fee numeric,
  agreement_fee numeric,
  caution_fee numeric,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS for Properties
alter table public.properties enable row level security;
create policy "Properties are viewable by everyone." on public.properties for select using (true);
create policy "Landlords/Agents can insert properties." on public.properties for insert with check (
  auth.uid() = owner_id and exists (
    select 1 from public.users where id = auth.uid() and role in ('landlord', 'agent')
  )
);
create policy "Owners can update their properties." on public.properties for update using (auth.uid() = owner_id);

-- WISHLISTS Table
create table if not exists public.wishlists (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users(id) not null,
  property_id uuid references public.properties(id) not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, property_id)
);

-- RLS for Wishlists
alter table public.wishlists enable row level security;
create policy "Users can view their own wishlist." on public.wishlists for select using (auth.uid() = user_id);
create policy "Users can add to their wishlist." on public.wishlists for insert with check (auth.uid() = user_id);
create policy "Users can remove from their wishlist." on public.wishlists for delete using (auth.uid() = user_id);

-- SAVED SEARCHES Table
create table if not exists public.saved_searches (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users(id) not null,
  title text not null,
  criteria_json jsonb not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS for Saved Searches
alter table public.saved_searches enable row level security;
create policy "Users can view their saved searches." on public.saved_searches for select using (auth.uid() = user_id);
create policy "Users can create saved searches." on public.saved_searches for insert with check (auth.uid() = user_id);
create policy "Users can delete saved searches." on public.saved_searches for delete using (auth.uid() = user_id);

-- BOOKINGS Table
create table if not exists public.bookings (
  id uuid default uuid_generate_v4() primary key,
  property_id uuid references public.properties(id) not null,
  user_id uuid references public.users(id) not null,
  date timestamp with time zone not null,
  status text default 'pending', -- 'pending', 'confirmed', 'cancelled'
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS for Bookings
alter table public.bookings enable row level security;
create policy "Users can see their own bookings." on public.bookings for select using (auth.uid() = user_id);
create policy "Landlords can see bookings for their properties." on public.bookings for select using (
  exists (
    select 1 from public.properties where id = property_id and owner_id = auth.uid()
  )
);
create policy "Users can insert bookings." on public.bookings for insert with check (auth.uid() = user_id);

-- CHATS Table
create table if not exists public.chats (
  id uuid default uuid_generate_v4() primary key,
  sender_id uuid references public.users(id) not null,
  receiver_id uuid references public.users(id) not null,
  message text not null,
  property_id uuid references public.properties(id) on delete set null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS for Chats
alter table public.chats enable row level security;
create policy "Users can see their own chats." on public.chats for select using (auth.uid() = sender_id or auth.uid() = receiver_id);
create policy "Users can send chats." on public.chats for insert with check (auth.uid() = sender_id);
