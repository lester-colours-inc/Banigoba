-- Catalogue pieces carry the same style and weather tags as wardrobe pieces,
-- so the Home recommendations can filter on them.
alter table public.products
  add column style_tag text not null default 'casual',
  add column weather_tags text[] not null default '{}',
  add column functional_tags text[] not null default '{}';
create index products_weather on public.products using gin (weather_tags);
alter table public.products replica identity full;
alter table public.user_products replica identity full;
