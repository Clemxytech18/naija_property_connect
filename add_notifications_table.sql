-- NOTIFICATIONS Table
create table if not exists public.notifications (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.users(id) not null,
  title text not null,
  body text not null,
  category text not null, -- 'bookings', 'messages', 'updates'
  is_read boolean default false,
  related_entity_id uuid, -- booking_id, chat_id, property_id, etc.
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS for Notifications
alter table public.notifications enable row level security;
create policy "Users can see their own notifications." on public.notifications for select using (auth.uid() = user_id);
create policy "Users can update their own notifications (mark as read)." on public.notifications for update using (auth.uid() = user_id);

-- Only system/triggers/functions usually insert notifications, but for client-side simplicity in this MVP:
-- We might allow users to insert notifications if they are 'sending' a notification to another user (like a message alert)
-- However, strict security would use a Postgres Trigger.
-- For now, we will allow authenticated users to insert notifications for ANYONE (for simplicity of 'Agent notifying Tenant' or vice-versa),
-- but in production this should be restricted via Edge Functions.
create policy "Authenticated users can create notifications." on public.notifications for insert with check (auth.role() = 'authenticated');
