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

## Decisions (answered 28 Oct)

1. **Customer ⇄ Provider toggle that keeps the customer app available:** yes.
2. **Unverified providers:** can set up, listed publicly only after a curator
   verifies them: yes.
3. **Name:** "Provider mode".
4. **Scope now:** build steps 1 and 2 (the switch and the sign-up) only;
   Orders across all roles waits for the marketplace work: yes.

## Status

All four steps are built (28 Oct).

1. **Switch and provider home:** `lib/data/models/provider_roles.dart`,
   `lib/data/services/provider_service.dart`, `lib/ui/screens/provider/`, the
   switch in the menu and the Provider mode row in Settings. Existing shops,
   designers and hair salons are recognised from their old fields.
2. **One sign-up:** "Become a provider" creates any of the three profiles.
3. **Orders and requests across roles:** "Orders & requests" on the provider
   home merges shop orders, design requests and hair requests, new ones first,
   with Accept / Decline / Mark completed for requests (customers are
   notified). Messages already covered shops and designers (their chats store
   the provider as `sellerId`); salons work through requests only.
4. **Old doors retired:** the Seller Mode switch is gone, and every old
   "Create profile" button (Agents page, Designers page) now opens the one
   sign-up with that role ticked, or the editor if the role is already held.

**Bug found and fixed on the way:** the rules for `design_requests` and
`agent_requests` only recognised `userId`, `sellerId` and similar fields, so
nobody could create or read a request (customers sending one, designers or
salons reading one). They now allow the customer and the provider, and a
request can never be reassigned. Six rules tests cover this. **The rules need
deploying for design and hair requests to work.**

Not built: provider-wide earnings or payouts (marketplace work), and a chat
with salons.

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

**Status (28 Oct): first version built.** "Get this look" matches by kind,
size and chosen style, not by colour, and shows pieces from verified shops
only. See `lib/data/models/look_purchase.dart` and
`lib/ui/widgets/get_this_look_sheet.dart`.

## Phase 4: Shop matching in the daily feed (D-4, A-6)

*New stock from shops and designers you follow shows in My Daily Dress Up.*

- **To build:** when a followed shop adds a piece, a server function checks it
  against each follower's size, style and wardrobe gaps and adds a card
  ("New from Glow Boutique, in your size"); capped to a few a day so it
  doesn't spam.
- **Depends on:** phase 1 (stock) and the server-side feed work we already
  noted as the fix for feed scale.

**Status (28 Oct): built.** `functions/feedMatching.js` (rules, tested) and
`functions/matchNewStock.js` (the trigger on `products/{id}`), writing cards to
`users/{uid}/feedCards`; the app reads them in `FeedMatchesService`. Limits:
at most 1000 followers handled per stock event; a deleted product's card
expires after a day instead of being removed.

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

**Status (28 Oct): first version built.** `functions/content/` (feed reader,
classifier, ingest, source list) and the `refreshFashionContent` schedule
write credited link previews to `content_items`; the app shows them on the
Community tab (`FashionNewsSection`) and under My Fashion Idols
(`IdolNewsSection`). Only publishers' own feeds are read; no article text or
picture is copied. To add a source, add one line in `functions/content/sources.js`.
To deploy: `firebase deploy --only functions:refreshFashionContent,firestore:rules`.

## Suggested order

1. Provider mode (switch and sign-up), then shop stock listing with size
   charts.
2. Look to purchase (phase 3): the most direct "makeover to sale" step.
3. Fitting room (phase 2).
4. Daily feed matching (phase 4).
5. Content engine (phase 5), which can run in parallel by anyone since it
   doesn't depend on shops.

---

# Share my stock (K-9), added 30 Oct

*A shop sends a link or QR code to its stock, a category or chosen pieces, to
WhatsApp groups and to friends, followers or the public in Banigoba. Anyone
opening it can try the pieces on and buy them.*

**Built (first version, 30 Oct):** `lib/data/models/shop_link.dart`,
`lib/data/services/shop_link_service.dart`, `lib/ui/screens/shop/shop_link*`,
`shared_stock_*`, `share_shop_link_panel.dart`, the Community strip
(`lib/ui/widgets/shop_drops_strip.dart`) and the `announceShopLink` function.

**Decisions taken:**
- WhatsApp has no way for an app to post to groups; "Send on WhatsApp" opens
  WhatsApp with the message ready and the shop picks the groups there.
- Links live on the Firebase web address, `https://appdemo-b9e3e.web.app/s?id=…`
  (change `kShareHost` for a custom domain). On Android with the app installed
  they open the app (verified App Link via `web/.well-known/assetlinks.json`).
- Shop products are readable by anyone so links work without an account.
  Only public links can be listed; just-the-link shares cannot be browsed.
- The hosted web app is built **without** the Gemini key, so try-on there says
  to use the app. Moving image generation behind a Cloud Function would make
  web try-on safe.

**To deploy (in this order):**
1. `firebase deploy --only firestore:rules --project appdemo-b9e3e`
2. `firebase deploy --only functions:announceShopLink --project appdemo-b9e3e`
3. `flutter build web --release` (no `--dart-define-from-file`, so no keys
   are compiled in), then `firebase deploy --only hosting --project appdemo-b9e3e`
4. Ship the new app build so links open in the app.

If the release APK is signed with a key other than the local debug key, add
its SHA-256 fingerprint to `web/.well-known/assetlinks.json`.
