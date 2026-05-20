-- Migration: Add user preferences to profiles table
-- Run this in Supabase SQL Editor to add missing columns

-- Add columns to profiles table if they don't exist
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS historical_interests jsonb DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS political_leaning text DEFAULT 'neutral',
ADD COLUMN IF NOT EXISTS onboarding_completed boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS daily_quote_date text,
ADD COLUMN IF NOT EXISTS last_synced_at timestamptz DEFAULT now();

-- Update trigger to include new columns
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, historical_interests, political_leaning, onboarding_completed, last_synced_at)
  VALUES (new.id, new.email, '[]'::jsonb, 'neutral', false, now())
  ON CONFLICT (id) DO UPDATE
    SET email = excluded.email,
        updated_at = now();
  RETURN new;
END;
$$;

-- Verify columns exist
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name='profiles' 
ORDER BY ordinal_position;
