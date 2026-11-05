-- App Store safety (guidelines 1.2, 5.1.1 and 5.1.2), the server's half.
--
-- * Blocking: a person can block someone. Neither then sees the other's looks
--   or comments, and any follow between them is removed.
-- * Reporting looks and profiles, alongside comment reports (C-3). Three
--   different people reporting a look hides it from everyone but its author
--   and curators until a curator looks.
-- * Consent: when someone agreed to the Terms, and whether they allowed their
--   photos to be sent to the AI services. Kept owner-only in private_account.
--
-- Deleting an account needs nothing here: every table that holds a person's
-- data references auth.users or profiles with "on delete cascade", so the
-- delete-account function only removes the auth user and their stored files.

-- ── blocking ────────────────────────────────────────────────────────────────

create table public.user_blocks (
  blocker_id uuid not null references public.profiles (id) on delete cascade,
  blocked_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);
alter table public.user_blocks enable row level security;
create policy user_blocks_owner_read on public.user_blocks
  for select to authenticated using (blocker_id = auth.uid());
create policy user_blocks_owner_create on public.user_blocks
  for insert to authenticated with check (blocker_id = auth.uid());
create policy user_blocks_owner_delete on public.user_blocks
  for delete to authenticated using (blocker_id = auth.uid());

-- Either way round: you blocked them, or they blocked you.
create or replace function public.is_blocked_between(a uuid, b uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.user_blocks
    where (blocker_id = a and blocked_id = b) or (blocker_id = b and blocked_id = a)
  )
$$;
revoke execute on function public.is_blocked_between(uuid, uuid) from public, anon;

-- Blocking someone ends any follow or pending follow request between you.
create or replace function private.end_follows_on_block()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  delete from public.follows
  where (follower_id = new.blocker_id and followee_id = new.blocked_id)
     or (follower_id = new.blocked_id and followee_id = new.blocker_id);
  delete from public.follow_requests
  where (requester_id = new.blocker_id and target_id = new.blocked_id)
     or (requester_id = new.blocked_id and target_id = new.blocker_id);
  return new;
end $$;
create trigger user_blocks_end_follows after insert on public.user_blocks
  for each row execute function private.end_follows_on_block();

-- ── looks: hidden after reports, never shown across a block ─────────────────

alter table public.posts add column hidden boolean not null default false;

create or replace function public.can_read_post(post public.posts)
returns boolean language sql stable security definer set search_path = public as $$
  select auth.uid() is not null and (
    post.author_id = auth.uid()
    or public.is_admin()
    or (
      not post.hidden
      and not public.is_blocked_between(auth.uid(), post.author_id)
      and (
        post.visibility = 'public'
        or (post.visibility = 'followers' and public.follows_user(auth.uid(), post.author_id))
        or (post.visibility = 'friends' and public.are_friends(auth.uid(), post.author_id))
      )
    )
  )
$$;
revoke execute on function public.can_read_post(public.posts) from public, anon;

-- Comments: as before (C-3), and never from someone across a block.
drop policy comments_read on public.comments;
create policy comments_read on public.comments for select to authenticated using (
  public.can_read_comment_target(target_type, target_id)
  and not public.is_blocked_between(auth.uid(), author_id)
  and (
    not hidden
    or author_id = auth.uid()
    or public.comment_target_owner(target_type, target_id) = auth.uid()
    or public.is_admin()
  )
);

-- A curator can clear or remove a reported look.
create policy posts_admin_update on public.posts
  for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy posts_admin_delete on public.posts
  for delete to authenticated using (public.is_admin());

-- ── reports on looks and profiles ───────────────────────────────────────────

create table public.post_reports (
  post_id uuid not null references public.posts (id) on delete cascade,
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  reason text not null default '' check (char_length(reason) <= 200),
  created_at timestamptz not null default now(),
  primary key (post_id, reporter_id)
);
alter table public.post_reports enable row level security;
create policy post_reports_create on public.post_reports
  for insert to authenticated with check (reporter_id = auth.uid());
create policy post_reports_read on public.post_reports
  for select to authenticated using (reporter_id = auth.uid() or public.is_admin());
create policy post_reports_admin_delete on public.post_reports
  for delete to authenticated using (public.is_admin());

create or replace function private.hide_reported_post()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if (select count(*) from public.post_reports where post_id = new.post_id) >= 3 then
    update public.posts set hidden = true where id = new.post_id;
  end if;
  return new;
end $$;
create trigger post_reports_hide after insert on public.post_reports
  for each row execute function private.hide_reported_post();

create table public.profile_reports (
  profile_id uuid not null references public.profiles (id) on delete cascade,
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  reason text not null default '' check (char_length(reason) <= 200),
  created_at timestamptz not null default now(),
  primary key (profile_id, reporter_id),
  check (profile_id <> reporter_id)
);
alter table public.profile_reports enable row level security;
create policy profile_reports_create on public.profile_reports
  for insert to authenticated with check (reporter_id = auth.uid());
create policy profile_reports_read on public.profile_reports
  for select to authenticated using (reporter_id = auth.uid() or public.is_admin());
create policy profile_reports_admin_delete on public.profile_reports
  for delete to authenticated using (public.is_admin());

-- ── consent ─────────────────────────────────────────────────────────────────

alter table public.private_account
  add column terms_accepted_at timestamptz,
  add column terms_version text not null default '',
  add column ai_photo_consent_at timestamptz;
