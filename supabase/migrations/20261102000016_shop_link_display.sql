alter table public.shop_links
  add column shop_name text not null default '',
  add column cover_image_url text not null default '';
