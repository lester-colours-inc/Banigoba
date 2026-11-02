-- Server-side work: pushes, feed cards, trending, fashion content, and the
-- announcement of shared stock links.
--
-- Edge Functions are called from the database through pg_net. The project URL
-- and service-role key live in Vault (names `edge_base_url` and
-- `edge_service_key`) and are set per environment, never in a migration. With
-- no secrets set the calls quietly do nothing, so a fresh database still runs.

create extension if not exists pg_net with schema extensions;
create extension if not exists pg_cron;
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create or replace function private.call_edge_function(fn text, payload jsonb)
returns void language plpgsql security definer set search_path = public as $$
declare base text; key text;
begin
  select decrypted_secret into base from vault.decrypted_secrets where name = 'edge_base_url';
  select decrypted_secret into key from vault.decrypted_secrets where name = 'edge_service_key';
  if base is null or key is null then
    return;
  end if;
  perform net.http_post(
    url := base || '/functions/v1/' || fn,
    body := payload,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || key),
    timeout_milliseconds := 30000);
exception when others then
  -- A failed call must never undo the change that triggered it.
  raise warning 'could not call edge function %: %', fn, sqlerrm;
end $$;
revoke all on function private.call_edge_function(text, jsonb) from public, anon, authenticated;

-- A push for every new notification.
create or replace function private.push_on_notification()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform private.call_edge_function('send-push', jsonb_build_object('record', to_jsonb(new)));
  return new;
end $$;
create trigger notifications_push after insert on public.notifications
  for each row execute function private.push_on_notification();

-- A piece that is new, or back in stock, may suit followers' daily feeds.
create or replace function private.match_on_stock()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    if new.stock > 0 then
      perform private.call_edge_function('match-new-stock', jsonb_build_object('record', to_jsonb(new)));
    end if;
  elsif old.stock <= 0 and new.stock > 0 then
    perform private.call_edge_function('match-new-stock',
      jsonb_build_object('record', to_jsonb(new), 'old_record', to_jsonb(old)));
  end if;
  return new;
end $$;
create trigger products_match after insert or update of stock on public.products
  for each row execute function private.match_on_stock();

-- When a shop shares its stock to friends, followers or the public, tell
-- those people (a just-the-link share tells nobody; the shop sends it).
create or replace function private.announce_shop_link()
returns trigger language plpgsql security definer set search_path = public as $$
declare shop text := coalesce(nullif(new.shop_name, ''), 'A shop');
begin
  if not new.active or new.audience not in ('friends', 'followers', 'public') then
    return new;
  end if;
  insert into public.notifications (user_id, sender_id, type, title, body, extra_data)
  select f.follower_id, new.owner_id, 'shop_link', shop,
         'shared ' || coalesce(nullif(new.title, ''), 'their stock') || '. Try them on and buy.',
         jsonb_build_object('linkId', new.id, 'fromName', shop)
  from public.follows f
  where f.followee_id = new.owner_id
    and f.follower_id <> new.owner_id
    and (new.audience <> 'friends' or public.follows_user(new.owner_id, f.follower_id))
  limit 1000;
  return new;
end $$;
create trigger shop_links_announce after insert on public.shop_links
  for each row execute function private.announce_shop_link();

-- Schedules (UTC). Trending runs at 16:00, which is 18:00 in Harare.
select cron.schedule('refresh-content', '0 */3 * * *',
  $$select private.call_edge_function('refresh-content', '{}'::jsonb)$$);
select cron.schedule('notify-trending', '0 16 * * *',
  $$select private.call_edge_function('notify-trending', '{}'::jsonb)$$);
