-- All Products, paged on the server.
--
-- The marketplace used to download every product and then search, filter and
-- sort them on the phone (lib/modules/shop/models/shop_filters.dart). That
-- cannot page, because "For you" and the price sorts need the whole list. These
-- functions do the same search, filters and sorts in the database so the app
-- can ask for one page at a time. They mirror the Dart rules exactly:
--   * only products of admin-verified shops (profiles.shop_verified);
--   * search over name, shop name, category, subcategory and garment group;
--   * unisex pieces pass any gender filter;
--   * a size counts only while it has stock; "in stock" sums the sizes;
--   * "new" means created in the last 14 days.

-- Layering group of a piece (garmentGroupOf in garment_taxonomy.dart).
create or replace function public.garment_group(category text, subcategory text)
returns text language sql immutable as $$
  select case
    when v like '%dress%' or v like '%jumpsuit%' or v like '%one-piece%'
      then 'dresses'
    when v like '%outerwear%' or v like '%jacket%' or v like '%blazer%'
      or v like '%coat%' or v like '%hoodie%' or v like '%cardigan%'
      then 'outerwear'
    when v like '%bottom%' or v like '%pants%' or v like '%trouser%'
      or v like '%jean%' or v like '%short%' or v like '%skirt%'
      then 'bottoms'
    when v like '%accessor%' or v like '%bag%' or v like '%hat%'
      or v like '%watch%' or v like '%jewel%'
      then 'accessories'
    when v like '%top%' or v like '%shirt%' or v like '%tee%'
      or v like '%tank%' or v like '%blouse%' or v like '%polo%'
      or v like '%sweatshirt%'
      then 'tops'
    else 'other'
  end
  from (
    select lower(coalesce(category, '') || ' ' || coalesce(subcategory, '')) as v
  ) s
$$;

-- Sizes with at least one piece in stock (productSizes in shop_filters.dart),
-- upper-cased; the single `size` field when there is no per-size stock.
create or replace function public.product_sizes(inv jsonb, d jsonb)
returns text[] language sql immutable as $$
  select case
    when inv is not null and inv <> '{}'::jsonb then coalesce((
      select array_agg(distinct upper(btrim(e.key)))
      from jsonb_each(inv) e
      where upper(btrim(e.key)) <> ''
        and jsonb_typeof(e.value) = 'number'
        and (e.value)::text::numeric > 0
    ), '{}'::text[])
    when upper(btrim(coalesce(d ->> 'size', ''))) <> ''
      then array[upper(btrim(d ->> 'size'))]
    else '{}'::text[]
  end
$$;

-- Pieces available, summing per-size stock when present (productStock).
create or replace function public.product_stock(inv jsonb, stock integer)
returns numeric language sql immutable as $$
  select case
    when inv is not null and inv <> '{}'::jsonb then coalesce((
      select sum(trunc((e.value)::text::numeric))
      from jsonb_each(inv) e
      where jsonb_typeof(e.value) = 'number'
    ), 0)
    else coalesce(stock, 0)
  end
$$;

-- The products that pass the search and filters. The list parameters arrive
-- lower-cased (sizes upper-cased) from the app, as the filter chips hold them.
create or replace function public.shop_products_matching(
  p_query text default '',
  p_categories text[] default '{}',
  p_genders text[] default '{}',
  p_styles text[] default '{}',
  p_sizes text[] default '{}',
  p_colours text[] default '{}',
  p_min_price numeric default null,
  p_max_price numeric default null,
  p_in_stock boolean default false,
  p_new_only boolean default false
)
returns setof public.products
language sql stable as $$
  select p.*
  from public.products p
  where exists (
      select 1 from public.profiles s
      where s.id = p.user_id and s.shop_verified
    )
    and (
      btrim(coalesce(p_query, '')) = ''
      or position(
        lower(btrim(p_query)) in lower(concat_ws(' ',
          p.name, p.data ->> 'shopName', p.category, p.subcategory,
          public.garment_group(p.category, p.subcategory)))
      ) > 0
    )
    and (cardinality(p_categories) = 0
      or lower(btrim(p.category)) = any (p_categories))
    and (cardinality(p_genders) = 0
      or lower(btrim(p.gender)) = 'unisex'
      or lower(btrim(p.gender)) = any (p_genders))
    and (cardinality(p_styles) = 0
      or lower(btrim(p.style_tag)) = any (p_styles))
    and (cardinality(p_sizes) = 0
      or public.product_sizes(p.size_inventory, p.data) && p_sizes)
    and (cardinality(p_colours) = 0 or exists (
      select 1 from unnest(p.colours) c
      where lower(btrim(c)) = any (p_colours)))
    and (p_min_price is null or p.price >= p_min_price)
    and (p_max_price is null or p.price <= p_max_price)
    and (not coalesce(p_in_stock, false)
      or public.product_stock(p.size_inventory, p.stock) > 0)
    and (not coalesce(p_new_only, false)
      or now() - p.created_at <= interval '14 days')
$$;

-- One page of matching products, each as the product row plus `_total`, the
-- number of products that match (so the app can say "N products").
-- p_sort is the app's ShopSort name: forYou, newest, priceLowHigh,
-- priceHighLow or nameAZ. p_viewer_gender ('male'/'female') drives forYou.
create or replace function public.shop_products(
  p_query text default '',
  p_categories text[] default '{}',
  p_genders text[] default '{}',
  p_styles text[] default '{}',
  p_sizes text[] default '{}',
  p_colours text[] default '{}',
  p_min_price numeric default null,
  p_max_price numeric default null,
  p_in_stock boolean default false,
  p_new_only boolean default false,
  p_sort text default 'forYou',
  p_viewer_gender text default null,
  p_limit integer default 30,
  p_offset integer default 0
)
returns setof jsonb
language sql stable as $$
  with m as (
    select * from public.shop_products_matching(
      p_query, p_categories, p_genders, p_styles, p_sizes, p_colours,
      p_min_price, p_max_price, p_in_stock, p_new_only)
  )
  select to_jsonb(m) || jsonb_build_object('_total', count(*) over ())
  from m
  order by
    -- Pieces for the viewer's gender first, then unisex, then the rest.
    case when p_sort = 'forYou' then
      case
        when coalesce(p_viewer_gender, '') = '' then 0
        when lower(btrim(m.gender)) = p_viewer_gender then 0
        when lower(btrim(m.gender)) in ('unisex', '') then 1
        else 2
      end
    end,
    case when p_sort in ('forYou', 'newest') then m.created_at end desc,
    case when p_sort = 'priceLowHigh' then m.price end asc,
    case when p_sort = 'priceHighLow' then m.price end desc,
    case when p_sort = 'nameAZ' then lower(m.name) end asc,
    m.created_at desc,
    m.id
  limit greatest(coalesce(p_limit, 30), 1)
  offset greatest(coalesce(p_offset, 0), 0)
$$;

-- How many products match (the filter sheet's live "Show N results").
create or replace function public.shop_products_count(
  p_query text default '',
  p_categories text[] default '{}',
  p_genders text[] default '{}',
  p_styles text[] default '{}',
  p_sizes text[] default '{}',
  p_colours text[] default '{}',
  p_min_price numeric default null,
  p_max_price numeric default null,
  p_in_stock boolean default false,
  p_new_only boolean default false
)
returns integer
language sql stable as $$
  select count(*)::integer from public.shop_products_matching(
    p_query, p_categories, p_genders, p_styles, p_sizes, p_colours,
    p_min_price, p_max_price, p_in_stock, p_new_only)
$$;

-- The values on offer across the whole marketplace, for the filter chips
-- (not narrowed by the search, so options do not vanish while typing).
create or replace function public.shop_facets()
returns jsonb
language sql stable as $$
  with m as (select * from public.shop_products_matching())
  select jsonb_build_object(
    'categories', coalesce((
      select jsonb_agg(distinct lower(btrim(category))) from m
      where btrim(category) <> ''), '[]'::jsonb),
    'genders', coalesce((
      select jsonb_agg(distinct lower(btrim(gender))) from m
      where btrim(gender) <> '' and lower(btrim(gender)) <> 'unisex'),
      '[]'::jsonb),
    'styles', coalesce((
      select jsonb_agg(distinct lower(btrim(style_tag))) from m
      where btrim(style_tag) <> ''), '[]'::jsonb),
    'colours', coalesce((
      select jsonb_agg(distinct lower(btrim(c)))
      from m, unnest(m.colours) c where btrim(c) <> ''), '[]'::jsonb),
    'sizes', coalesce((
      select jsonb_agg(distinct s)
      from m, unnest(public.product_sizes(m.size_inventory, m.data)) s),
      '[]'::jsonb),
    'maxPrice', coalesce((select max(price) from m), 0)
  )
$$;

grant execute on function
  public.shop_products(text, text[], text[], text[], text[], text[], numeric,
    numeric, boolean, boolean, text, text, integer, integer),
  public.shop_products_count(text, text[], text[], text[], text[], text[],
    numeric, numeric, boolean, boolean),
  public.shop_facets()
to anon, authenticated;
