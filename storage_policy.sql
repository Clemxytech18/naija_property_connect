-- Storage Policies for Property Images and Videos
-- Run this in your Supabase SQL Editor

-- 1. Create the bucket if it doesn't exist
insert into storage.buckets (id, name, public)
values ('property_images', 'property_images', true)
on conflict (id) do nothing;

-- 2. Enable RLS on storage.objects (if not already enabled)
-- Skipping this as it causes permission errors and is usually enabled by default
-- alter table storage.objects enable row level security;

-- 3. Drop existing policies to prevent conflicts
drop policy if exists "Public Access" on storage.objects;
drop policy if exists "Auth Upload" on storage.objects;
drop policy if exists "Owner Update" on storage.objects;
drop policy if exists "Owner Delete" on storage.objects;

-- 4. Create new policies

-- Allow everyone to view images/videos
create policy "Public Access"
on storage.objects for select
using ( bucket_id = 'property_images' );

-- Allow authenticated users (Landlords/Agents) to upload
create policy "Auth Upload"
on storage.objects for insert
with check (
  bucket_id = 'property_images' 
  and auth.role() = 'authenticated'
);

-- Allow owners to update their own files
create policy "Owner Update"
on storage.objects for update
using (
  bucket_id = 'property_images' 
  and auth.uid() = owner
);

-- Allow owners to delete their own files
create policy "Owner Delete"
on storage.objects for delete
using (
  bucket_id = 'property_images' 
  and auth.uid() = owner
);
