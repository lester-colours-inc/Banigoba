-- Fields the profile screens and onboarding use that the first cut left out.
alter table public.profiles
  add column bio text not null default '',
  add column cover_image_url text not null default '',
  add column makeover_focus text,
  add column preferences_prompted boolean not null default false,
  add column last_seen timestamptz;
