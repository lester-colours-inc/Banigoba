alter table public.comments add column author_image_url text not null default '';

-- Tables the app watches live. Row-level security still decides who hears
-- about which row.
alter publication supabase_realtime add table
  public.profiles, public.posts, public.comments, public.affirmations,
  public.follows, public.follow_requests, public.notifications,
  public.outfits, public.user_products, public.hair_looks, public.ai_makeovers,
  public.cart_items, public.orders, public.shop_chats, public.shop_chat_messages,
  public.design_requests, public.agent_requests, public.events,
  public.content_items, public.shop_links, public.feed_cards, public.products;
