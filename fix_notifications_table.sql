-- Clean up existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can see their own notifications." ON public.notifications;
DROP POLICY IF EXISTS "Users can update their own notifications (mark as read)." ON public.notifications;
DROP POLICY IF EXISTS "Authenticated users can create notifications." ON public.notifications;

-- Ensure table exists
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id uuid REFERENCES public.users(id) NOT NULL,
  title text NOT NULL,
  body text NOT NULL,
  category text NOT NULL, -- 'bookings', 'messages', 'updates'
  is_read boolean DEFAULT false,
  related_entity_id uuid, -- booking_id, chat_id, property_id, etc.
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Re-create policies
CREATE POLICY "Users can see their own notifications." ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update their own notifications (mark as read)." ON public.notifications FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Authenticated users can create notifications." ON public.notifications FOR INSERT WITH CHECK (auth.role() = 'authenticated');
