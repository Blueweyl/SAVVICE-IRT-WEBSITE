-- ============================================================
-- SAVVICE IRT — SUPABASE DATABASE SETUP
-- Run this in Supabase SQL Editor (Dashboard → SQL Editor → New Query)
-- ============================================================

-- 1. Helper functions (bypass RLS for role checks)
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from profiles
    where id = auth.uid()
    and system_role = 'admin'
    and status = 'approved'
  );
$$;

create or replace function public.is_approved()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from profiles
    where id = auth.uid()
    and status = 'approved'
  );
$$;

-- 2. Profiles table
create table public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  email text not null,
  display_name text not null,
  team text,
  position text,
  system_role text default 'supervisor' check (system_role in ('admin', 'supervisor', 'client')),
  status text default 'pending' check (status in ('pending', 'approved', 'rejected')),
  registered_at timestamptz default now(),
  approved_by uuid,
  approved_at timestamptz,
  last_login timestamptz
);

alter table public.profiles enable row level security;

create policy "Users can read own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Admins can read all profiles"
  on public.profiles for select
  using (public.is_admin());

create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Admins can update any profile"
  on public.profiles for update
  using (public.is_admin());

-- 3. Reports table
create table public.reports (
  id bigint generated always as identity primary key,
  date text,
  expressway text default 'NLEX',
  shift text,
  weather text,
  team text,
  leadman text,
  control_no text,
  direction text,
  km_post text,
  loc_notice text,
  lanes text,
  traffic_flow text,
  vehicle text,
  category text,
  plate text,
  main_activity text,
  sub_activity text,
  traffic_mgmt text,
  action_taken text,
  remarks text,
  time_notif text,
  odo_notif text,
  time_arrival text,
  odo_arrival text,
  time_cleared text,
  time_site_cleared text,
  time_departure text,
  response_time text,
  clearing_time text,
  recovery_time text,
  distance text,
  submitted_by uuid references auth.users(id),
  submitted_by_name text,
  submitted_at timestamptz default now()
);

alter table public.reports enable row level security;

create policy "Approved users can read reports"
  on public.reports for select
  using (public.is_approved());

create policy "Approved users can insert reports"
  on public.reports for insert
  with check (public.is_approved());

-- 4. Attendance table
create table public.attendance (
  date text primary key,
  saved_by uuid references auth.users(id),
  saved_at timestamptz default now(),
  records jsonb not null default '[]'::jsonb
);

alter table public.attendance enable row level security;

create policy "Approved users can read attendance"
  on public.attendance for select
  using (public.is_approved());

create policy "Approved users can insert attendance"
  on public.attendance for insert
  with check (public.is_approved());

create policy "Approved users can update attendance"
  on public.attendance for update
  using (public.is_approved());

-- 5. Enable realtime for reports table
alter publication supabase_realtime add table public.reports;

-- 6. Fire truck turnover checklists
create table public.firetruck_checklists (
  id bigint generated always as identity primary key,
  date text not null,
  truck text not null,
  plate_no text,
  items jsonb not null default '{}'::jsonb,
  turnover_1to2_by text,
  turnover_1to2_notes text,
  turnover_1to2_received_by text,
  turnover_2to1_by text,
  turnover_2to1_notes text,
  turnover_2to1_received_by text,
  validated_by text,
  submitted_by uuid references auth.users(id),
  submitted_by_name text,
  submitted_at timestamptz default now(),
  unique (date, truck)
);

alter table public.firetruck_checklists enable row level security;

create policy "Approved users can read firetruck checklists"
  on public.firetruck_checklists for select
  using (public.is_approved());

create policy "Approved users can insert firetruck checklists"
  on public.firetruck_checklists for insert
  with check (public.is_approved());

create policy "Approved users can update firetruck checklists"
  on public.firetruck_checklists for update
  using (public.is_approved());
