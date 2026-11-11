-- Likes on looks.
--
-- Who liked a look is private: rows are readable by the person who liked
-- only, and you can only like a look you can see. The total shown on a look
-- is added in 20261111000003_post_like_count.sql.

create table public.post_likes (
  user_id uuid not null references public.profiles (id) on delete cascade,
  post_id uuid not null references public.posts (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, post_id)
);
create index post_likes_post on public.post_likes (post_id);
alter table public.post_likes enable row level security;

create policy post_likes_owner_read on public.post_likes
  for select to authenticated using (user_id = auth.uid());
create policy post_likes_owner_create on public.post_likes
  for insert to authenticated with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.posts p
      where p.id = post_id and public.can_read_post(p)
    )
  );
create policy post_likes_owner_delete on public.post_likes
  for delete to authenticated using (user_id = auth.uid());
