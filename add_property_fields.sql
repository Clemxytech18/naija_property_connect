-- Add new columns for Property features and fees
-- Run this in your Supabase SQL Editor

ALTER TABLE public.properties
ADD COLUMN IF NOT EXISTS bedrooms numeric,
ADD COLUMN IF NOT EXISTS bathrooms numeric,
ADD COLUMN IF NOT EXISTS sqft numeric,
ADD COLUMN IF NOT EXISTS parking_spaces numeric,
ADD COLUMN IF NOT EXISTS agent_fee numeric,
ADD COLUMN IF NOT EXISTS legal_fee numeric,
ADD COLUMN IF NOT EXISTS agreement_fee numeric,
ADD COLUMN IF NOT EXISTS caution_fee numeric,
ADD COLUMN IF NOT EXISTS service_fee numeric;
