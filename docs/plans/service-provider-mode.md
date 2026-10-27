# Service-provider mode: plan for approval

Covers checklist items S-1 to S-4. Nothing is built yet.

## What the meeting asked for

Any user can switch between **Customer** and **Service provider**, like
passenger and driver in InDrive. One person can be a customer *and* a shop, a
designer or a salon. Shops sign up as normal users; there is no separate
business sign-up.

## What exists today

| Role | How you become one today | What you get |
|---|---|---|
| Shop | Settings › "Seller Mode" switch | The **whole app turns into** the boutique dashboard (products, orders). Admin-verified. |
| Salon / hair agent | Agents page › register | Profile, verification, chat. No "mode". |
| Designer | Designers page › portfolio | Portfolio, verification, chat. No "mode". |

Problems: three different doors; Seller Mode *replaces* the customer app
instead of switching beside it; one person can't comfortably be both; nothing
tells a customer which providers exist as "my" shop.

## Proposal

1. **One door.** Settings gets **"Switch to provider mode"**. First time, a
   short form asks what you offer (tick any of: Shop, Designer, Hair salon),
   a business name, and a location. Pre-existing shops, designers and agents
   are carried over automatically; nobody re-registers.
2. **A visible switch, not a different app.** A "Customer ⇄ Provider" toggle
   at the top of the menu. Provider mode shows a provider home with a card per
   role you hold (My Shop, My Designs, My Salon), each opening the screen that
   already exists, plus **Orders** and **Messages** across all roles. The
   customer app stays one tap away; no sign-out.
3. **Verification stays.** Curators still verify each role; unverified
   providers can set up but don't appear in Send to or the directories.
4. **Data.** Keep the current `shop`, `designerProfile`, `agentProfile`
   sections on the user record (rules already protect their `verified`
   flags). Add one field, `providerRoles: ['shop','designer','salon']`, and
   `providerMode: true/false` for which side the user last used.

## Build steps (each shippable on its own)

1. Provider home screen + the Customer/Provider toggle; keep Seller Mode
   working underneath. (~1 day)
2. Unified "Become a provider" form that creates any of the three profiles
   and migrates existing ones. (~1 day)
3. Provider-wide Orders and Messages views. (~1 day)
4. Retire the old Seller Mode switch and the separate registration entry
   points. (~half day)

Tests: role-combination logic (unit), the toggle and provider home (widget),
rule tests for the new fields.

## Decisions I need from you

1. **Seller Mode today replaces the app.** Is the new "toggle that keeps the
   customer app available" what you want? (Recommended: yes.)
2. **Can unverified providers be seen at all?** Recommended: set up yes,
   listed publicly only after a curator verifies.
3. **Naming:** "Provider mode" vs "Business mode" vs "Seller mode" for
   shops, designers and salons together.
4. **Marketplace dependency:** build only steps 1-2 now (the switch and
   sign-up), leaving Orders for the marketplace work? (Recommended: yes.)

---

# What comes after: the shopping phases

Added 25 Oct. These need provider mode (shops listing stock) first, so they
are phases 2 to 5 of one roadmap. Nothing here is built yet.

## Phase 2: Virtual fitting room (K-2)

*Try a shop's item on your own body, with a fit check like "tight around the
waist".*

- **Already there:** the avatar try-on screen, your saved measurements and
  sizes (`BodyProfile`), per-size stock on shop products, and a plain-words fit
  summary (`tryOnFitNote`).
- **To build:** compare the item's measurements (shoulders, length, size chart)
  with yours and say where it is tight, loose or short, per body part; show it
  on the try-on picture with that note. Shops need to enter a size chart (part
  of provider mode's stock form).
- **Risk:** the fit check is only as good as the shop's measurements, so it
  says "estimated" and shows the numbers it used.

## Phase 3: From look to purchase (K-4, A-7)

*After a makeover, check what you already own; suggest shops for the rest.*

- **Already there:** the "Find pieces" sheet links each changed item to shops,
  salons or designers, and saved looks and wardrobe items exist.
- **To build:** match each piece of the finished look against your wardrobe
  (category, colour, style tag); show "You have this" or "Buy this" per piece;
  for the rest, list verified shops whose stock matches and fits your size,
  with a one-tap "Add to cart".
- **Depends on:** shop stock with categories, colours and sizes (phase 1).

## Phase 4: Shop matching in the daily feed (D-4, A-6)

*New stock from shops and designers you follow shows in My Daily Dress Up.*

- **To build:** when a followed shop adds a piece, a server function checks it
  against each follower's size, style and wardrobe gaps and adds a card
  ("New from Glow Boutique, in your size"); capped to a few a day so it
  doesn't spam.
- **Depends on:** phase 1 (stock) and the server-side feed work we already
  noted as the fix for feed scale.

## Phase 5: Fashion-content engine (E-2, E-3, F-2, E-4)

*Find fashion stories and events online; post them as credited link previews.*

- **Decided:** show title, small image and site name from the source and send
  taps to the source; never copy images.
- **To build:** a scheduled server job that reads chosen sources (fashion news
  feeds, event listings), tags stories by place and by people, stores the
  link preview, and feeds it to users by location and interests. Idols you
  keep (My Fashion Idols) get their name matched against stories (F-2).
  Push notifications for a trending look or story follow once there is
  enough activity (E-4).
- **Needs from you:** the list of sources to start with (for example 5 to 10
  fashion sites and event pages in Harare and internationally).
- **Risk:** scraping sites can break their terms; prefer their RSS feeds or
  official APIs.

## Suggested order

1. Provider mode (switch and sign-up), then shop stock listing with size
   charts.
2. Look to purchase (phase 3): the most direct "makeover to sale" step.
3. Fitting room (phase 2).
4. Daily feed matching (phase 4).
5. Content engine (phase 5), which can run in parallel by anyone since it
   doesn't depend on shops.
