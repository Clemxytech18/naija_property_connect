-- Fix Properties Table Schema - Comprehensive
-- This script adds ALL potentially missing columns to match the app's requirements.

-- 1. Rename 'media' to 'images' if it exists (legacy support)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'media') THEN
        ALTER TABLE public.properties RENAME COLUMN media TO images;
    END IF;
END $$;

-- 2. Add missing columns
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS images text[];
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS bedrooms numeric;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS bathrooms numeric;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS agent_fee numeric;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS agreement_fee numeric;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS caution_fee numeric;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS legal_fee numeric;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS video text;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS features text[];
