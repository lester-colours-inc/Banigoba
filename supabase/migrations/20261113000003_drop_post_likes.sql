-- Likes are removed from the app entirely. Undoes
-- 20261111000001_post_likes.sql and 20261111000003_post_like_count.sql.

drop trigger if exists posts_guard_like_count on public.posts;
drop function if exists private.guard_like_count();

drop trigger if exists post_likes_count on public.post_likes;
drop function if exists public.sync_like_count();

drop table if exists public.post_likes;

alter table public.posts drop column if exists like_count;

-- Any old like notifications have nothing left to point at.
delete from public.notifications where type = 'like';
