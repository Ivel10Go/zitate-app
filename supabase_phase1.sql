-- Marx App / Supabase Phase 1
-- Run this in the Supabase SQL Editor.

-- Enable UUID generation if not already present.
create extension if not exists pgcrypto;

-- Profiles table
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz,
  -- User preferences for personalization
  historical_interests jsonb default '[]'::jsonb,
  political_leaning text default 'neutral',
  onboarding_completed boolean default false,
  -- Optional: Track today's quote for consistency across devices
  daily_quote_date text,
  last_synced_at timestamptz default now()
);

-- Auto-create profile row when a new auth user is created.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.profiles (id, email, historical_interests, political_leaning, onboarding_completed, last_synced_at)
  values (new.id, new.email, '[]'::jsonb, 'neutral', false, now())
  on conflict (id) do update
    set email = excluded.email,
        updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Favorites table
create table if not exists public.user_favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  -- quote_id is text to support string IDs from the app (e.g. 'ho_chi_minh_001')
  quote_id text not null,
  created_at timestamptz default now(),
  unique(user_id, quote_id)
);

create index if not exists idx_user_favorites_user_id on public.user_favorites(user_id);
create index if not exists idx_user_favorites_quote_id on public.user_favorites(quote_id);

-- Community submissions table for bug reports and quote proposals.
create table if not exists public.community_submissions (
  id uuid primary key default gen_random_uuid(),
  submission_type text not null check (submission_type in ('bug_report', 'quote_submission')),
  title text,
  message text,
  quote_text text,
  author text,
  source text,
  details jsonb not null default '{}'::jsonb,
  submitted_by uuid references auth.users(id) on delete set null,
  submitter_email text,
  platform text,
  app_version text,
  app_locale text,
  status text not null default 'pending' check (status in ('pending', 'reviewing', 'accepted', 'rejected', 'closed')),
  created_at timestamptz default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references auth.users(id) on delete set null,
  review_notes text
);

create index if not exists idx_community_submissions_type_status_created_at
  on public.community_submissions(submission_type, status, created_at desc);

-- Enable Row Level Security
alter table public.profiles enable row level security;
alter table public.user_favorites enable row level security;
alter table public.community_submissions enable row level security;

-- Profiles policies
drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile"
  on public.profiles
  for select
  using (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
  on public.profiles
  for update
  using (auth.uid() = id);

-- Favorites policies
drop policy if exists "Users can view own favorites" on public.user_favorites;
create policy "Users can view own favorites"
  on public.user_favorites
  for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own favorites" on public.user_favorites;
create policy "Users can insert own favorites"
  on public.user_favorites
  for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own favorites" on public.user_favorites;
create policy "Users can delete own favorites"
  on public.user_favorites
  for delete
  using (auth.uid() = user_id);

-- Community submissions policies
drop policy if exists "Anyone can insert community submissions" on public.community_submissions;
create policy "Anyone can insert community submissions"
  on public.community_submissions
  for insert
  with check (true);
