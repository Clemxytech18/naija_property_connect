-- Migration to add detailed profile fields to users table

ALTER TABLE public.users ADD COLUMN IF NOT EXISTS avatar_url text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS bio text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS employment_status text; -- 'Self-Employed', 'Employed', 'Student', 'Not-Employed'
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS gender text; -- 'Male', 'Female'
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS marital_status text; -- 'Married', 'Single', 'Divorced'
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS state text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS city text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS business_name text; -- For Agents/Landlords

-- Update RLS to ensure these fields are accessible (policies usually cover all columns, but good to double check if column security is used. Default policies I saw covered the whole row 'using (true)' or 'auth.uid() = id').
-- The existing policies SELECT using(true) and UPDATE using(auth.uid() = id) should cover these new columns automatically.
