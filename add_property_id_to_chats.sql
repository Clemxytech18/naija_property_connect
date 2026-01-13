-- Migration to add property_id to chats table

ALTER TABLE public.chats ADD COLUMN IF NOT EXISTS property_id uuid references public.properties(id) ON DELETE SET NULL;
