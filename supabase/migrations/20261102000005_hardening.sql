-- Security hardening from the Supabase advisors: pin search paths, keep
-- internal and trigger functions off the public API, keep pg_trgm out of
-- the exposed schema.

alter function public.touch_updated_at() set search_path = public;
alter function public.is_server() set search_path = public;
alter function public.reserved_usernames() set search_path = public;
alter function public.is_admin() set search_path = public;
alter function public.is_chat_participant(public.shop_chats) set search_path = public;
alter function public.guard_order_update() set search_path = public;
alter function public.guard_request_update() set search_path = public;

-- Trigger functions are never called through the API.
revoke execute on function public.guard_profile_privileges() from public, anon, authenticated;
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.sync_comment_count() from public, anon, authenticated;

-- Policy helpers are evaluated for signed-in users only.
revoke execute on function public.are_friends(uuid, uuid) from public, anon;
revoke execute on function public.follows_user(uuid, uuid) from public, anon;
revoke execute on function public.profile_is_admin(uuid) from public, anon;
revoke execute on function public.can_read_post(public.posts) from public, anon;
revoke execute on function public.can_read_comment_target(text, text) from public, anon;
revoke execute on function public.in_chat(uuid) from public, anon;
revoke execute on function public.ensure_chat(text, uuid, text) from public, anon;
revoke execute on function public.accept_follow_request(uuid) from public, anon;
revoke execute on function public.find_user_by_email_hash(text) from public, anon;

create schema if not exists extensions;
alter extension pg_trgm set schema extensions;
