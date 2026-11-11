-- Like counts on looks. Who liked a look stays private (post_likes rows are
-- readable only by the person who liked); how many people did is now shown on
-- the look, kept on the post the same way as comment_count.

alter table public.posts add column like_count integer not null default 0;

update public.posts p set like_count = (
  select count(*) from public.post_likes l where l.post_id = p.id
);

create or replace function public.sync_like_count()
returns trigger language plpgsql security definer set search_path = public as $$
declare pid uuid;
begin
  pid := coalesce(new.post_id, old.post_id);
  update public.posts set like_count = (
    select count(*) from public.post_likes where post_id = pid
  ) where id = pid;
  return null;
end $$;
revoke execute on function public.sync_like_count() from public, anon, authenticated;

create trigger post_likes_count after insert or delete on public.post_likes
  for each row execute function public.sync_like_count();

-- Authors may edit their own posts, but never the count: a client's insert
-- starts at zero and a client's update keeps the stored number. Only
-- sync_like_count (running as the table owner) changes it.
create or replace function private.guard_like_count()
returns trigger language plpgsql set search_path = public as $$
begin
  if current_user not in ('authenticated', 'anon') then
    return new;
  end if;
  if tg_op = 'INSERT' then
    new.like_count := 0;
  else
    new.like_count := old.like_count;
  end if;
  return new;
end $$;
create trigger posts_guard_like_count before insert or update on public.posts
  for each row execute function private.guard_like_count();
