-- One follow notification per person, not one per tap.
--
-- The app adds a `follow_request` / `follow_accepted` notification each time
-- someone taps Follow / Accept, so a double tap (or follow, cancel, follow)
-- gave the other person the same notification, and push, several times.
-- A repeat of an unanswered one from the same sender within a day is now
-- dropped before it is stored, so no push goes out for it either (the push
-- trigger runs after insert).

create or replace function private.skip_repeat_follow_notification()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.type not in ('follow_request', 'follow_accepted') or new.sender_id is null then
    return new;
  end if;
  -- Two taps landing at once must not both get through.
  perform pg_advisory_xact_lock(
    hashtextextended(new.user_id::text || new.sender_id::text || new.type, 0));
  if exists (
    select 1 from public.notifications
     where user_id = new.user_id
       and sender_id = new.sender_id
       and type = new.type
       and extra_data->>'response' is null
       and created_at > now() - interval '1 day'
  ) then
    return null;
  end if;
  return new;
end $$;
revoke all on function private.skip_repeat_follow_notification() from public, anon, authenticated;

create trigger notifications_skip_repeat_follow before insert on public.notifications
  for each row execute function private.skip_repeat_follow_notification();

-- Clear the repeats already sent: keep the newest of each run.
delete from public.notifications older
 using public.notifications newer
 where older.type in ('follow_request', 'follow_accepted')
   and newer.type = older.type
   and newer.user_id = older.user_id
   and newer.sender_id = older.sender_id
   and older.extra_data->>'response' is null
   and newer.created_at > older.created_at
   and newer.created_at - older.created_at < interval '1 day';
