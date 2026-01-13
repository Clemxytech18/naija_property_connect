-- Create Wishlists Table
create table if not exists public.wishlists (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users(id) not null,
  property_id uuid references public.properties(id) on delete cascade not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, property_id)
);

-- Enable RLS
alter table public.wishlists enable row level security;

-- Policies
create policy "Users can view their own wishlist." on public.wishlists for select using (auth.uid() = user_id);
create policy "Users can add to their wishlist." on public.wishlists for insert with check (auth.uid() = user_id);
create policy "Users can remove from their wishlist." on public.wishlists for delete using (auth.uid() = user_id);
