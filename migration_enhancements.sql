-- Migration for App Enhancements
-- Run this in your Supabase SQL Editor

-- 1. Update Properties Table
alter table public.properties rename column media to images;
alter table public.properties add column video text;

-- 2. Create Wishlists Table
create table if not exists public.wishlists (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users(id) not null,
  property_id uuid references public.properties(id) not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, property_id) -- Prevent duplicate likes
);

-- RLS for Wishlists
alter table public.wishlists enable row level security;

create policy "Users can view their own wishlist." 
  on public.wishlists for select 
  using (auth.uid() = user_id);

create policy "Users can add to their wishlist." 
  on public.wishlists for insert 
  with check (auth.uid() = user_id);

create policy "Users can remove from their wishlist." 
  on public.wishlists for delete 
  using (auth.uid() = user_id);

-- 3. Create Saved Searches Table
create table if not exists public.saved_searches (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users(id) not null,
  title text not null, -- e.g. "Lagos Apartments < 500k"
  criteria_json jsonb not null, -- Stores the filter parameters
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS for Saved Searches
alter table public.saved_searches enable row level security;

create policy "Users can view their saved searches." 
  on public.saved_searches for select 
  using (auth.uid() = user_id);

create policy "Users can create saved searches." 
  on public.saved_searches for insert 
  with check (auth.uid() = user_id);

create policy "Users can delete saved searches." 
  on public.saved_searches for delete 
  using (auth.uid() = user_id);
