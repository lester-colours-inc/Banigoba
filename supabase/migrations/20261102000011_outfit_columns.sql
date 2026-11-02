-- Saved looks carry a name, the avatar they were made on, where they came
-- from (a feed post saves once), and an optional planned date and event.
alter table public.outfits
  add column name text not null default '',
  add column avatar_image_url text not null default '',
  add column source_post_id uuid,
  add column planned_date date,
  add column event_id text,
  add column event_name text,
  add column daily_dress_up_post_id uuid,
  add column updated_at timestamptz not null default now();
create unique index outfits_source_post on public.outfits (user_id, source_post_id)
  where source_post_id is not null;
create trigger outfits_touch before update on public.outfits
  for each row execute function public.touch_updated_at();
alter table public.outfits replica identity full;
