-- Leads from the portfolio's onboarding (onboarding.html).
-- Run this once in the Supabase SQL editor of the project whose URL and anon key go in onboarding.html.
-- The site can only INSERT. Nobody can read, change or delete rows with the public key;
-- you read leads in the Supabase dashboard (Table editor) or with the service key.

create table if not exists public.leads (
  id          uuid primary key,
  created_at  timestamptz not null default now(),
  name        text not null check (char_length(name) between 1 and 120),
  email       text not null check (char_length(email) between 3 and 200),
  phone       text not null check (char_length(phone) between 7 and 40),
  handle      text check (char_length(handle) <= 80),
  role        text check (char_length(role) <= 60),
  revenue     text check (char_length(revenue) <= 60),
  blocker     text check (char_length(blocker) <= 4000),
  hours       text check (char_length(hours) <= 60),
  ready       text check (char_length(ready) <= 60),
  score       int  check (score between 0 and 8),
  tier        text check (tier in ('hot', 'warm', 'cold')),
  page        text check (char_length(page) <= 300)
);

-- Which package a hot lead picked on the last screen ($500 advisor or $250 coaching).
create table if not exists public.lead_packages (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  lead_id     uuid not null,
  package     text not null check (package in ('$500 advisor', '$250 coaching'))
);

alter table public.leads enable row level security;
alter table public.lead_packages enable row level security;

drop policy if exists "site can add leads" on public.leads;
create policy "site can add leads" on public.leads for insert to anon with check (true);

drop policy if exists "site can add package picks" on public.lead_packages;
create policy "site can add package picks" on public.lead_packages for insert to anon with check (true);

-- One view to read everything, hottest and newest first (dashboard / service key only).
create or replace view public.leads_overview with (security_invoker = true) as
select l.created_at, l.tier, l.score, l.name, l.email, l.phone, l.handle, l.role, l.revenue, l.hours, l.ready,
       (select p.package from public.lead_packages p where p.lead_id = l.id order by p.created_at desc limit 1) as package,
       l.blocker
from public.leads l
order by (l.tier = 'hot') desc, l.created_at desc;
