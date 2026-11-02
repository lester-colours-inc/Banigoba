-- Saving the same feed look twice keeps one copy. The uniqueness must be a
-- plain unique index for upsert to find it; NULLs never clash, so looks that
-- came from a makeover (no source post) are unaffected.
drop index if exists public.outfits_source_post;
create unique index outfits_source_post on public.outfits (user_id, source_post_id);
