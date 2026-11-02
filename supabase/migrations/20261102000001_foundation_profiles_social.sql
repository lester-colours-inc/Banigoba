-- Banigoba on Supabase, part 1: profiles, who follows whom, notifications.
--
-- Replaces Firestore's users/{uid} document and its subcollections. The
-- private details that used to sit on the public user document (email,
-- address, measurements) get their own owner-only tables, which also fixes
-- the street address being readable by every signed-in user.

create extension if not exists pgcrypto;
create extension if not exists pg_trgm;

-- ── helpers ────────────────────────────────────────────────────────────────

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

-- True when the caller is the server (service role) or the database owner.
create or replace function public.is_server()
returns boolean language sql stable as $$
  select coalesce(auth.role(), '') = 'service_role' or current_user in ('postgres', 'supabase_admin')
$$;

-- ── profiles (the public side of a user) ───────────────────────────────────

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text,
  display_name text not null default '',
  profile_image_url text not null default '',
  city text not null default '',
  city_key text not null default '',
  -- "Near me": only a coarse cell about 22 km wide, never coordinates.
  area_enabled boolean not null default false,
  area_cell text,
  area_updated_at timestamptz,
  style_preferences text[] not null default '{}',
  notify_trending boolean not null default true,
  -- Provider mode (shops, designers, hair salons).
  provider_roles text[] not null default '{}',
  provider_mode boolean not null default false,
  shop jsonb not null default '{}'::jsonb,
  designer_profile jsonb not null default '{}'::jsonb,
  agent_profile jsonb not null default '{}'::jsonb,
  -- Privileged: only the server or an admin may change these.
  is_admin boolean not null default false,
  role text not null default 'user',
  shop_verified boolean not null default false,
  designer_verified boolean not null default false,
  agent_verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint username_format check (
    username is null or (username ~ '^[a-z0-9._]+$' and char_length(username) between 3 and 20)
  ),
  constraint role_known check (role in ('user', 'admin'))
);

create unique index profiles_username_key on public.profiles (lower(username));
create index profiles_city_key on public.profiles (city_key) where city_key <> '';
create index profiles_area_cell on public.profiles (area_cell) where area_cell is not null;

create trigger profiles_touch before update on public.profiles
  for each row execute function public.touch_updated_at();

-- Reserved handles can never be claimed.
create or replace function public.reserved_usernames()
returns text[] language sql immutable as $$
  select array['admin','administrator','banigoba','support','help','moderator','official','staff','root','system']
$$;

create or replace function public.profile_is_admin(uid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select is_admin or role = 'admin' from public.profiles where id = uid), false)
$$;

create or replace function public.is_admin()
returns boolean language sql stable as $$
  select auth.uid() is not null and public.profile_is_admin(auth.uid())
$$;

-- Admin rights and verified badges are set by the server or an admin only.
create or replace function public.guard_profile_privileges()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if public.is_server() then
    return new;
  end if;
  if tg_op = 'INSERT' then
    if new.is_admin or new.role <> 'user' or new.shop_verified or new.designer_verified or new.agent_verified then
      raise exception 'privileges cannot be granted at sign-up' using errcode = '42501';
    end if;
  else
    if new.is_admin is distinct from old.is_admin or new.role is distinct from old.role then
      raise exception 'admin rights can only be changed by the server' using errcode = '42501';
    end if;
    if (new.shop_verified is distinct from old.shop_verified
        or new.designer_verified is distinct from old.designer_verified
        or new.agent_verified is distinct from old.agent_verified)
       and not public.is_admin() then
      raise exception 'only a curator can verify a shop, designer or salon' using errcode = '42501';
    end if;
    if new.username is distinct from old.username
       and new.username is not null
       and new.username = any (public.reserved_usernames()) then
      raise exception 'that username is reserved' using errcode = '23514';
    end if;
  end if;
  return new;
end $$;

create trigger profiles_guard before insert or update on public.profiles
  for each row execute function public.guard_profile_privileges();

alter table public.profiles enable row level security;

-- Anyone signed in can read profiles (feeds, follower lists and shop pages
-- all resolve names from here); no private data lives in this table.
create policy profiles_read on public.profiles
  for select to authenticated using (true);
create policy profiles_update_self on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
-- Curators verify shops, designers and salons.
create policy profiles_update_admin on public.profiles
  for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy profiles_delete_self on public.profiles
  for delete to authenticated using (id = auth.uid());

-- A profile is created with the account.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', ''))
  on conflict (id) do nothing;
  insert into public.private_account (id, email)
  values (new.id, coalesce(new.email, ''))
  on conflict (id) do nothing;
  return new;
end $$;

-- ── private account details (owner only) ───────────────────────────────────

create table public.private_account (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null default '',
  address jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.private_account enable row level security;
create policy private_account_owner on public.private_account
  for all to authenticated using (id = auth.uid()) with check (id = auth.uid());

create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

create table public.body_profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.body_profiles enable row level security;
create policy body_profiles_owner on public.body_profiles
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Consent for gallery suggestions (E-5), versioned.
create table public.gallery_consent (
  user_id uuid primary key references auth.users (id) on delete cascade,
  granted boolean not null default false,
  version integer not null default 0,
  changed_at timestamptz not null default now()
);
alter table public.gallery_consent enable row level security;
create policy gallery_consent_owner on public.gallery_consent
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Push tokens: kept here so the server can send through Firebase Cloud
-- Messaging, which stays only for notifications.
create table public.fcm_tokens (
  user_id uuid not null references auth.users (id) on delete cascade,
  token text not null,
  platform text not null default '',
  updated_at timestamptz not null default now(),
  primary key (user_id, token)
);
alter table public.fcm_tokens enable row level security;
create policy fcm_tokens_owner on public.fcm_tokens
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- The last trending push each person had (server only).
create table public.trending_notices (
  user_id uuid primary key references auth.users (id) on delete cascade,
  day date,
  post_ids text[] not null default '{}'
);
alter table public.trending_notices enable row level security;

-- Find someone by their full email without ever listing emails (U-5): the
-- caller supplies the SHA-256 of the lower-cased address.
create table public.email_lookup (
  hash text primary key,
  user_id uuid not null references auth.users (id) on delete cascade
);
alter table public.email_lookup enable row level security;
create policy email_lookup_owner_write on public.email_lookup
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create or replace function public.find_user_by_email_hash(email_hash text)
returns uuid language sql stable security definer set search_path = public as $$
  select user_id from public.email_lookup where hash = email_hash
$$;
revoke all on function public.find_user_by_email_hash(text) from public, anon;
grant execute on function public.find_user_by_email_hash(text) to authenticated;

-- ── the social graph ───────────────────────────────────────────────────────

create table public.follows (
  follower_id uuid not null references public.profiles (id) on delete cascade,
  followee_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, followee_id),
  constraint not_self check (follower_id <> followee_id)
);
create index follows_followee on public.follows (followee_id);
alter table public.follows enable row level security;
create policy follows_read on public.follows
  for select to authenticated using (true);
create policy follows_insert on public.follows
  for insert to authenticated with check (follower_id = auth.uid());
create policy follows_delete on public.follows
  for delete to authenticated using (follower_id = auth.uid() or followee_id = auth.uid());

create table public.follow_requests (
  requester_id uuid not null references public.profiles (id) on delete cascade,
  target_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (requester_id, target_id)
);
alter table public.follow_requests enable row level security;
create policy follow_requests_parties on public.follow_requests
  for all to authenticated
  using (requester_id = auth.uid() or target_id = auth.uid())
  with check (requester_id = auth.uid() or target_id = auth.uid());

-- The person asked accepts: the requester starts following them.
create or replace function public.accept_follow_request(requester uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from public.follow_requests where requester_id = requester and target_id = auth.uid()) then
    raise exception 'there is no such request' using errcode = 'P0002';
  end if;
  insert into public.follows (follower_id, followee_id) values (requester, auth.uid()) on conflict do nothing;
  delete from public.follow_requests where requester_id = requester and target_id = auth.uid();
end $$;
grant execute on function public.accept_follow_request(uuid) to authenticated;

create or replace function public.follows_user(follower uuid, followee uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.follows where follower_id = follower and followee_id = followee)
$$;

-- Friends are mutual follows.
create or replace function public.are_friends(a uuid, b uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select public.follows_user(a, b) and public.follows_user(b, a)
$$;

-- ── notifications ──────────────────────────────────────────────────────────

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  sender_id uuid references public.profiles (id) on delete set null,
  type text not null default 'general',
  title text not null default '',
  body text not null default '',
  extra_data jsonb not null default '{}'::jsonb,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);
create index notifications_user on public.notifications (user_id, created_at desc);
alter table public.notifications enable row level security;
-- Whoever triggered a notification creates it, in their own name.
create policy notifications_create on public.notifications
  for insert to authenticated with check (sender_id = auth.uid());
create policy notifications_recipient on public.notifications
  for select to authenticated using (user_id = auth.uid());
create policy notifications_recipient_update on public.notifications
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy notifications_recipient_delete on public.notifications
  for delete to authenticated using (user_id = auth.uid());

-- ── small owner-only lists ─────────────────────────────────────────────────

-- Fashion twins, fashion idols and hairstyles I like.
create table public.style_list_entries (
  user_id uuid not null references auth.users (id) on delete cascade,
  list text not null check (list in ('fashionTwins', 'fashionIdols', 'hairInspiration')),
  id text not null,
  name text not null default '',
  image_url text not null default '',
  username text not null default '',
  added_at timestamptz not null default now(),
  primary key (user_id, list, id)
);
alter table public.style_list_entries enable row level security;
create policy style_list_owner on public.style_list_entries
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- My Circle: my own salons, shops and designers.
create table public.circle_entries (
  user_id uuid not null references auth.users (id) on delete cascade,
  kind text not null check (kind in ('salon', 'shop', 'designer')),
  target_id uuid not null references public.profiles (id) on delete cascade,
  added_at timestamptz not null default now(),
  primary key (user_id, kind, target_id)
);
alter table public.circle_entries enable row level security;
create policy circle_owner on public.circle_entries
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Everything else a person keeps privately and rarely queries across:
-- event plans, packing lists, daily plans, wear history, makeover jobs.
create table public.user_documents (
  user_id uuid not null references auth.users (id) on delete cascade,
  kind text not null,
  id text not null,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, kind, id)
);
alter table public.user_documents enable row level security;
create policy user_documents_owner on public.user_documents
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create trigger user_documents_touch before update on public.user_documents
  for each row execute function public.touch_updated_at();
