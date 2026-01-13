-- Add status and closed_reason to properties table
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS status text DEFAULT 'available';
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS closed_reason text;

-- Add total_revenue to users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS total_revenue numeric DEFAULT 0;
