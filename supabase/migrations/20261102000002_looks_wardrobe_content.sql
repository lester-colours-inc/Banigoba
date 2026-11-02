-- Banigoba on Supabase, part 2: looks, posts, affirmations, the wardrobe,
-- hair looks, makeovers, and the content engine's tables.

-- ── posts ──────────────────────────────────────────────────────────────────

create table public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles (id) on delete cascade,
  caption text not null default '',
  image_url text not null default '',
  outfit_id text,
  visibility text not null default 'private'
    check (visibility in ('private', 'friends', 'followers', 'public')),
  kind text not null default 'look' check (kind in ('look', 'dressUp')),
  products jsonb not null default '[]'::jsonb,
  product_ids text[] not null default '{}',
  -- Reposts and quotes of another post.
  repost_of_id uuid references public.posts (id) on delete set null,
  repost_of_author_id uuid references public.profiles (id) on delete set null,
  quote_text text not null default '',
  turn_views jsonb not null default '{}'::jsonb,
  comment_count integer not null default 0,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index posts_author on public.posts (author_id, created_at desc);
create index posts_public on public.posts (created_at desc) where visibility = 'public';
create trigger posts_touch before update on public.posts
  for each row execute function public.touch_updated_at();

-- Who may read a post (I-2): its author; anyone when public; followers of the
-- author when shared with followers; mutual follows when shared with friends.
create or replace function public.can_read_post(post public.posts)
returns boolean language sql stable security definer set search_path = public as $$
  select auth.uid() is not null and (
    post.author_id = auth.uid()
    or post.visibility = 'public'
    or (post.visibility = 'followers' and public.follows_user(auth.uid(), post.author_id))
    or (post.visibility = 'friends' and public.are_friends(auth.uid(), post.author_id))
  )
$$;

alter table public.posts enable row level security;
create policy posts_read on public.posts
  for select to authenticated using (public.can_read_post(posts));
create policy posts_create on public.posts
  for insert to authenticated with check (author_id = auth.uid());
create policy posts_update on public.posts
  for update to authenticated using (author_id = auth.uid()) with check (author_id = auth.uid());
create policy posts_delete on public.posts
  for delete to authenticated using (author_id = auth.uid());

-- ── comments (on looks and on hair looks), as private as what they are on ──

create table public.comments (
  id uuid primary key default gen_random_uuid(),
  target_type text not null check (target_type in ('post', 'hairLook')),
  target_id text not null,
  author_id uuid not null references public.profiles (id) on delete cascade,
  author_name text not null default '',
  text text not null,
  created_at timestamptz not null default now()
);
create index comments_target on public.comments (target_type, target_id, created_at);
alter table public.comments enable row level security;

create or replace function public.can_read_comment_target(kind text, target text)
returns boolean language plpgsql stable security definer set search_path = public as $$
declare p public.posts;
begin
  if auth.uid() is null then return false; end if;
  if kind = 'post' then
    select * into p from public.posts where id::text = target;
    return found and public.can_read_post(p);
  end if;
  return true;
end $$;

create policy comments_read on public.comments
  for select to authenticated using (public.can_read_comment_target(target_type, target_id));
create policy comments_create on public.comments
  for insert to authenticated with check (author_id = auth.uid());
create policy comments_update on public.comments
  for update to authenticated using (author_id = auth.uid()) with check (author_id = auth.uid());
create policy comments_delete on public.comments
  for delete to authenticated using (author_id = auth.uid());

-- Keep the number on a post right, without exposing anything else.
create or replace function public.sync_comment_count()
returns trigger language plpgsql security definer set search_path = public as $$
declare tid text; ttype text;
begin
  ttype := coalesce(new.target_type, old.target_type);
  tid := coalesce(new.target_id, old.target_id);
  if ttype = 'post' then
    update public.posts set comment_count = (
      select count(*) from public.comments where target_type = 'post' and target_id = tid
    ) where id::text = tid;
  end if;
  return null;
end $$;
create trigger comments_count after insert or delete on public.comments
  for each row execute function public.sync_comment_count();

-- ── affirmations: qualitative responses, never a popularity count ──────────

create table public.affirmations (
  id text primary key,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  sender_name text not null default '',
  target_type text not null default 'post',
  target_id text not null check (target_id <> ''),
  target_owner_id uuid not null references public.profiles (id) on delete cascade,
  definition_id text not null default '',
  emoji text not null default '',
  short_label text not null default '',
  text text not null default '',
  category text not null default '',
  language text not null default '',
  meaning text not null default '',
  personal_message text not null default '',
  moderation_state text not null default 'clear',
  migrated_from_like boolean not null default false,
  created_at timestamptz not null default now()
);
create index affirmations_target on public.affirmations (target_type, target_id);
create index affirmations_recent on public.affirmations (created_at desc);
alter table public.affirmations enable row level security;
create policy affirmations_read on public.affirmations
  for select to authenticated using (true);
-- In the sender's own name, never on their own look, never a forged migration.
create policy affirmations_create on public.affirmations
  for insert to authenticated with check (
    sender_id = auth.uid() and target_owner_id <> auth.uid() and not migrated_from_like
  );
-- Affirmations are immutable; the sender can withdraw, the owner can remove.
create policy affirmations_delete on public.affirmations
  for delete to authenticated using (sender_id = auth.uid() or target_owner_id = auth.uid());

-- Curator-managed cultural expressions; written by the server only.
create table public.affirmation_library (
  id text primary key,
  data jsonb not null default '{}'::jsonb,
  review_state text not null default 'draft'
);
alter table public.affirmation_library enable row level security;
create policy affirmation_library_read on public.affirmation_library
  for select to authenticated using (true);

-- ── saved looks (outfits) ──────────────────────────────────────────────────

create table public.outfits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  image_url text not null default '',
  products jsonb not null default '[]'::jsonb,
  category text not null default '',
  preview_type text not null default '',
  turn_views jsonb not null default '{}'::jsonb,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index outfits_user on public.outfits (user_id, created_at desc);
create index outfits_image on public.outfits (user_id, image_url);
alter table public.outfits enable row level security;
create policy outfits_read on public.outfits
  for select to authenticated using (true);
create policy outfits_write on public.outfits
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ── the Smart Wardrobe ─────────────────────────────────────────────────────

create table public.user_products (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  name text not null default '',
  category text not null default 'other',
  subcategory text not null default 'none',
  style_tag text not null default 'casual',
  colours text[] not null default '{}',
  gender text not null default 'unisex',
  size text not null default '',
  weather_tags text[] not null default '{}',
  functional_tags text[] not null default '{}',
  image_url text not null default '',
  raw_image_url text not null default '',
  visibility text not null default 'private' check (visibility in ('private', 'public')),
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index user_products_user on public.user_products (user_id, category);
alter table public.user_products enable row level security;
create policy user_products_read on public.user_products
  for select to authenticated using (user_id = auth.uid() or visibility = 'public');
create policy user_products_write on public.user_products
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ── hair looks, the hairstyle catalogue and AI makeovers ───────────────────

create table public.hair_looks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  style_name text not null default '',
  prompt text not null default '',
  source_image_url text not null default '',
  result_image_url text not null default '',
  style_reference_image_url text not null default '',
  is_public boolean not null default false,
  visibility text not null default 'private',
  is_preview boolean not null default false,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  published_at timestamptz
);
alter table public.hair_looks enable row level security;
create policy hair_looks_read on public.hair_looks
  for select to authenticated using (user_id = auth.uid() or is_public);
create policy hair_looks_write on public.hair_looks
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create table public.hairstyles (
  id uuid primary key default gen_random_uuid(),
  name text not null default '',
  image_url text not null default '',
  category text not null default '',
  data jsonb not null default '{}'::jsonb,
  uploader_id uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);
alter table public.hairstyles enable row level security;
create policy hairstyles_read on public.hairstyles
  for select to authenticated using (true);
create policy hairstyles_admin on public.hairstyles
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

create table public.ai_makeovers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  style text not null default '',
  source_image_url text not null default '',
  generated_image_urls text[] not null default '{}',
  status text not null default 'completed',
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
alter table public.ai_makeovers enable row level security;
create policy ai_makeovers_owner on public.ai_makeovers
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Catalogue filter facets; written by admin tooling.
create table public.catalog_metadata (
  id text primary key,
  data jsonb not null default '{}'::jsonb
);
alter table public.catalog_metadata enable row level security;
create policy catalog_metadata_read on public.catalog_metadata
  for select to authenticated using (true);

-- ── the content engine ─────────────────────────────────────────────────────

-- Credited link previews of fashion stories and events, written by the
-- refreshFashionContent job only.
create table public.content_items (
  id text primary key,
  title text not null,
  url text not null,
  image_url text not null default '',
  source_id text not null default '',
  source_name text not null default '',
  region text not null default 'intl',
  kind text not null default 'news' check (kind in ('news', 'event')),
  places text[] not null default '{}',
  topics text[] not null default '{}',
  published_at timestamptz not null,
  starts_at timestamptz,
  expires_at timestamptz not null,
  fetched_at timestamptz not null default now()
);
create index content_items_recent on public.content_items (published_at desc);
create index content_items_expiry on public.content_items (expires_at);
alter table public.content_items enable row level security;
create policy content_items_read on public.content_items
  for select to authenticated using (true);

-- How each feed did on its last run (server only; no client policy).
create table public.content_sources (
  id text primary key,
  name text not null default '',
  url text not null default '',
  ok boolean not null default false,
  item_count integer not null default 0,
  error text,
  last_run_at timestamptz not null default now()
);
alter table public.content_sources enable row level security;
