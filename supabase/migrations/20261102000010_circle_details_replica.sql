-- My Circle keeps a snapshot of how each member looked when added.
alter table public.circle_entries
  add column name text not null default '',
  add column avatar_url text not null default '',
  add column detail text not null default '';

-- Live lists must hear about deletes, which needs the full old row.
alter table public.follows replica identity full;
alter table public.follow_requests replica identity full;
alter table public.comments replica identity full;
alter table public.affirmations replica identity full;
alter table public.notifications replica identity full;
alter table public.posts replica identity full;
alter table public.circle_entries replica identity full;
