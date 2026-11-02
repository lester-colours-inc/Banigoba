-- A feed card is one per person per piece: the same piece is a card for many
-- followers, so the key includes the person.
alter table public.feed_cards drop constraint feed_cards_pkey;
alter table public.feed_cards add primary key (user_id, id);
