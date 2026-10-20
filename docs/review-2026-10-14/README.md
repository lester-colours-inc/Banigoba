# Banigoba — App Review Checklist

**Meeting:** App review meeting, 14 October 2026 (full transcript, parts 1–3)  
**Prepared by:** Lester  
**Status:** In progress: Tiers 1 and 2 done except G-4. Tier 3: 7 of 13. Privacy and admin fixes built and tested; their rules deploy with Friday's release.  
**Target:** Next app version by the end of next week (about Friday 23 October 2026)

Tick items off as they ship. Item IDs (e.g. `H-2`) match the Word version (`Banigoba_Review_Checklist.docx`).

Items are ordered easiest and clearest first. The ID prefix shows the app area (H = Home, M = Makeover, W = Wardrobe, …).

_Generated from `tools/checklist.json`; edit that file and run `npm run build` in `tools/`._

## Contents

- [Principles (apply to all work)](#principles-apply-to-all-work)
- [Tier 1 — Quick wins](#tier-1-quick-wins) — 17/17 done
- [Tier 2 — Clear, medium work](#tier-2-clear-medium-work) — 15/16 done
- [Tier 3 — Needs a decision first](#tier-3-needs-a-decision-first) — 7/13 done
- [Tier 4 — Bigger features](#tier-4-bigger-features) — 3/23 done
- [Tier 5 — Backend, research and go-to-market](#tier-5-backend-research-and-go-to-market) — 0/10 done
- [Issues found while working](#issues-found-while-working)
- [Release day (Friday)](#release-day-friday)
- [Open questions](#open-questions)

## Principles (apply to all work)

_Not tasks. Keep these in mind on every change._

- [ ] **G-2** Copy the basics from WhatsApp, X and Instagram. Do not reinvent standard patterns; add our own ideas on top later. — Global UI rules (every screen) _(Guiding principle)_
- [ ] **E-1** Make the app habit-forming: people should want to check it every 15 minutes. User numbers will grow slowly, so engagement matters. — Engagement and go-to-market _(Strategy)_
- [ ] **A-2** The backend engine and its algorithms are the top priority. That is where the app's power comes from. — Backend, algorithms and research _(Priority)_

## Tier 1 — Quick wins

_Small, clear UI changes, or checks of work that is already done. Start here._

- [x] **H-1** Tab label reads "My Makeover" / "My Fashion Makeover", not "My Timeline". Page heading: "My Fashion Makeover". — Home — My Fashion Makeover tab _(Already done in the latest build. Check it.)_
  - **Progress:** Checked: the tab reads "My Fashion Makeover".
- [x] **H-7** Remove the duplicated name on post cards. Show the name once, with "The look" as the label. — Home — My Fashion Makeover tab _(Already fixed in the developer's latest build. Check it.)_
  - **Progress:** Checked in code: the name shows once in the card header.
- [x] **M-11** Keep generating one item at a time. — Makeover generator page _(Already done. Check it.)_
  - **Progress:** Checked: the makeover runs one step per item.
- [x] **P-1** Post audience (Friends / Followers / Public) is chosen every time, with no default. — Post, save and share _(Agreed. Keep it as it is.)_
  - **Progress:** Checked: the share sheet asks Friends / Followers / Public each time.
- [x] **D-1** The feed comes from Smart Wardrobe suggestions. Check what currently fills it. — My Daily Dress Up
  - **Progress:** Checked: the feed shows looks saved to the Smart Wardrobe. AI suggestions and Twins/Idols looks are not built yet (see D-4, F-1).
- [x] **U-6** The profile collects body data: height, measurements, a full-body photo, a hand photo and similar. — Profile, identity and social graph
  - **Progress:** My Profile Details now has face, full-body and hand photos, plus height, weight, shoulders, waist, tummy, chest, hips, inside leg and sizes.
- [x] **H-2** Makeover button is large and always shows its label: "Create My Fashion Makeover". Make the font smaller if needed so it fits. — Home — My Fashion Makeover tab _(Reverses the recent change to an icon-only button with a tooltip)_
  - **Progress:** Large labelled button "Create My Fashion Makeover".
- [x] **H-3** The makeover button has a little movement, like the WhatsApp "Ask Meta AI" button. — Home — My Fashion Makeover tab
  - **Progress:** The button pulses three times when Home opens; this is skipped when the phone asks for reduced motion.
- [x] **M-2** Say "your photo", not "your full body photo". People may only want to try a hairstyle or sunglasses. — Makeover generator page
  - **Progress:** "Add Your Photo" / "Your Photo".
- [x] **M-3** Use a personal, instructional heading such as "My New Look" or "My New Makeover". — Makeover generator page _(Exact wording to be confirmed)_
  - **Progress:** Heading is now "My New Look". The wording can still change.
- [x] **M-9** Fix the clashing "Describe style twin…" text. — Makeover generator page
  - **Progress:** Method labels wrap onto two lines instead of being cut off.
- [x] **M-12** Add a back button so the user can leave without generating. — Makeover generator page
  - **Progress:** Back arrow moved to the top left, where people expect it. It was on the right, next to the cart.
- [x] **W-5** Add item: add a back button. — Smart Wardrobe module
  - **Progress:** Back arrow added to the "Upload to Wardrobe" sheet.
- [x] **G-3** Every sub-page has a visible back button. Do not rely on Android gesture navigation. — Global UI rules (every screen) _(Missing on the makeover generator and on Add wardrobe item)_
  - **Progress:** Screens that can be a tab or a pushed page (Home, Wardrobe, Search, Notifications, My Hair Style) show a back arrow when opened from somewhere else and the menu otherwise. Makeover and Add item are fixed too.
- [x] **P-2** "Save to My Smart Wardrobe": the icon changes colour once saved, like a like button. — Post, save and share
  - **Progress:** The icon fills and turns gold once saved. Tap again to remove it from the wardrobe.
- [x] **H-6** Tapping anywhere on a post card opens it, like X does. At the moment you have to tap the picture itself. — Home — My Fashion Makeover tab
  - **Progress:** Tapping the name, words or picture opens the look. The action buttons still do their own thing.
- [x] **U-1** The profile picture can be changed. Today it cannot be edited and shows a placeholder picture. — Profile, identity and social graph _(Bug)_
  - **Progress:** Tap your own photo on My Profile to take or choose a new one. Settings uses the same code.

## Tier 2 — Clear, medium work

_The requirement is clear. These need more than a one-line change._

- [x] **G-1** Every page has a clear heading at the top. Move the top bar up and put the page title in it. — Global UI rules (every screen)
  - **Progress:** Wardrobe heading is "My Smart Wardrobe"; the Discover tab heading now matches the bottom bar; Home's tabs name each feed.
- [ ] **G-4** Fix text that overlaps or clashes, on every screen. — Global UI rules (every screen)
  - **Progress:** Fixed where found (makeover method labels, profile photo tiles). Still needs a check on a real phone.
- [x] **M-4** Make the layout a clear either-or: Option A, describe the look; or Option B, use a look you love (style idol, style twin, community). — Makeover generator page _(The current screen is cluttered)_
  - **Progress:** Two large choices: "Describe it" or "Use a look you love". The second shows Style twin, Style idol, Trending and Weather.
- [x] **M-5** Option A: the "Describe the look you want" box sits at the top, with the "What should change" chips (hair, outfit, shoes and so on) below it. — Makeover generator page _(Reverses the current order)_
  - **Progress:** The description box sits under "How do you want to create your look?", with "What should change?" below it.
- [x] **M-6** The user must write a description AND pick at least one change chip before Generate is enabled. These chips label our backend data sets. — Makeover generator page
  - **Progress:** Nothing is pre-selected. Generate stays off until there is a description (or a chosen look) and a "What should change" choice.
- [x] **M-7** The chips are generic. They do not try to adapt to what is in the uploaded photo. — Makeover generator page
  - **Progress:** The chips are the same for every photo: Full look, Outfit only, Hair only, Top only, Bottom only.
- [x] **M-8** Option B also asks the user what should change (outfit only, hair, and so on). — Makeover generator page
  - **Progress:** The same "What should change?" chips apply to a look you love.
- [x] **D-3** If the Smart Wardrobe is not set up, show "Set up your Smart Wardrobe" with a button that opens the setup. — My Daily Dress Up
  - **Progress:** An empty feed shows "Set up my Smart Wardrobe" and "Add my measurements" buttons.
- [x] **D-2** Friends' shared daily dress-ups also appear here, not only yours. — My Daily Dress Up
  - **Progress:** Forward a dress-up to Friends or Community to share it as today's look. Friends' shared dress-ups from the last 36 hours show at the top of the feed.
- [x] **H-5** The feed shows everyone's looks (yours, friends, followers, community and public), not only yours. People want engagement. — Home — My Fashion Makeover tab
  - **Progress:** My Fashion Makeover shows your looks plus everyone else's you are allowed to see. Community shows only other people's.
- [x] **P-3** After saving, show a sheet that says where the look went and lets the user pick or create a category. Today it just says "Saved", which feels like a dark hole. — Post, save and share
  - **Progress:** After saving, a sheet says "Saved to My Smart Wardrobe", offers categories (or a new one) and a "View in wardrobe" button.
- [x] **W-1** The Smart Wardrobe page currently shows the wrong content (friends and community). Give it its own wardrobe interface. — Smart Wardrobe module _(Bug)_
  - **Progress:** Tabs are now My Clothes, Saved Looks (grouped by category) and Shops & Designers. The Friends and Community tabs are gone. My Clothes stays empty until the user_products rule (issue I-1) is deployed.
- [x] **W-4** Add item: add size fields (size, shoulders and other key measurements). — Smart Wardrobe module _(Missing today)_
  - **Progress:** Add item asks for size (XXS–XXXL), shoulders and length. These are stored in the same fields shops use. Uploading only works once the user_products rule (issue I-1) is deployed.
- [x] **U-3** Add search for people and friends. — Profile, identity and social graph
  - **Progress:** Search was on Discover; there is now a search icon on Home and a "Find people to follow" button on your profile. Search no longer shows emails and matches an email only when the full address is typed. Your email is shown only to you.
- [x] **C-1** The Community feed includes events. — Community
  - **Progress:** An "Upcoming events" strip sits at the top of the Community feed.
- [x] **C-2** Add a "Create event" entry point and form (for example to announce a fashion show) that posts into Community. — Community _(Not built yet)_
  - **Progress:** There is an "Add event" button on the Community feed. It uses the existing event form, which goes to curators for approval.

## Tier 3 — Needs a decision first

_Blocked on an open question at the end of this document. Quick to build once decided._

- [ ] **B-1** Change the payoff line (tagline) to "G for God", tied to the G in the logo. — Branding _(Confirm exact wording)_
  - **Progress:** Decided: "G for Good" (not God). Waiting for the designer's new logo file with the line; then swap it in and regenerate the splash screens (dart run flutter_native_splash:create).
- [x] **H-4** Remove the "No affirmations yet" text. Show a number instead. — Home — My Fashion Makeover tab _(Open question 1: this clashes with the work plan's "no counters" rule)_
  - **Progress:** Decided: owner-only count. "No affirmations yet" is gone. The look's owner sees the total; everyone else sees which affirmations were given, never a number (fits BNG SRS 001).
- [x] **U-2** Add a way to follow people. "Following" and "Followers" appear on the profile, but nothing lets you follow anyone. — Profile, identity and social graph _(Open question 1 (counts))_
  - **Progress:** Follow already existed on other people's profiles and is now reachable through people search. Follower and following numbers show only to the profile owner; others see the lists without totals.
- [x] **P-4** Make Post and Share clearly different, or merge them. Remove the duplication and settle the wording. — Post, save and share
  - **Progress:** Decided: keep both, renamed. "Post" (in the ⋮ menu) decides who sees the look in the feeds; "Send to" (share icon) sends it to a salon, shop, designer, WhatsApp or other apps. Community and Friends are no longer in Send to. Daily Dress Up has its own "Post as today's dress-up" action.
- [x] **P-8** Repost and Quote are always visible in the share sheet. Today they only appear after you share to Community. — Post, save and share _(Today quoting is only possible on public looks. Open question 3.)_
  - **Progress:** Decided: always shown. On a private look, Repost or Quote first asks "Share this look first?", then carries on.
- [x] **M-1** Starting a makeover offers two choices: "Hairstyle" and "Other" (outfit, shoes, accessories). People think about their hair and face every morning more than about their full outfit. — Makeover generator page _(Open question 6: two buttons or one button that asks)_
  - **Progress:** Decided: one button, then a choice. "Create My Fashion Makeover" (and the menu item) asks Hairstyle or Outfit & more first.
- [x] **P-7** New feature: users connect with their own salons, shops and designers. We need a name for this kind of connection. — Post, save and share _(Open question 2)_
  - **Progress:** Decided: "My Circle". Add or remove any salon, shop or designer from the Send to list; kept privately per user.
- [x] **P-6** Share to salon, shop or designer: show a row of the ones you are already connected to above the search box. — Post, save and share
  - **Progress:** Send to shows your Circle as a one-tap row above the search, then everyone else.
- [ ] **K-5** Platform commission on every sale, like InDrive (for example $1.00 item + $0.20). — Marketplace, e-fitting room and monetization _(Open question 7 (rates))_
- [ ] **K-6** Influencers share in the revenue from sales they bring in. — Marketplace, e-fitting room and monetization
- [ ] **K-3** Buy online with delivery, so people do not have to queue or walk around a crowded flea market. — Marketplace, e-fitting room and monetization _(Open question 8 (delivery))_
- [ ] **E-2** Fashion-content engine: search the internet and the fashion industry for stories and post them to users' feeds, asking "What do you think about this look?" Examples: what is happening in Paris, what Michelle Obama wore 10 days ago, what local Harare socialites are wearing. This works before we have many users. — Engagement and go-to-market _(Backend. Open question 9 (image rights))_
- [ ] **E-3** Fashion events from the content engine also appear in the feeds. — Engagement and go-to-market _(Links to C-1)_

## Tier 4 — Bigger features

_Clear, but large: new screens, new data, or migrations._

- [ ] **P-9** Bookmark categories, like Facebook's saved collections (for example "Weddings"). The same categories are used in the "look you love" picker. — Post, save and share
- [ ] **M-10** "See a look you love" picker: add search plus filters for liked, bookmarked, bookmark categories, trending, style idols and people you follow. Show people you follow first. — Makeover generator page
- [ ] **F-1** The Fashion Twins page currently reuses the makeover page. Rebuild it: find people (search, including the internet), add them, follow them. Their activity then appears in your feed. — Fashion Twins, Fashion Idols and Hair Stylists _(Same page reused several times today)_
- [ ] **F-2** Fashion Idols works the same way: search, follow, and their news comes into your feed. — Fashion Twins, Fashion Idols and Hair Stylists
- [ ] **F-3** "My Hair Stylists" is a setup page, not a makeover page: follow stylists and salons, and keep the hairstyles you like (uploaded, found online, or your own photos). — Fashion Twins, Fashion Idols and Hair Stylists
- [ ] **F-4** Do not add new timelines. Hairstyle makeovers and posts go into the existing My Fashion Makeover and My Daily Dress Up feeds. — Fashion Twins, Fashion Idols and Hair Stylists _(Keep the number of feeds small)_
- [x] **U-4** Give every user a unique @username, separate from their display name (which does not need to be unique). — Profile, identity and social graph
  - **Progress:** Built: unique @username (3–20 characters; letters, numbers, dots, underscores), held in a usernames lookup so no two people can have the same one. Anyone without one is asked once, with a suggestion from their name. It shows on profiles and in search, and can be changed in Settings. Database rules deployed 20 October 2026.
- [x] **U-5** Stop using email as the public identifier. Use a private ID as the key and the username for display. — Profile, identity and social graph _(Backend migration, privacy)_
  - **Progress:** Built and tested: emails now live in a private record (owner only) and are no longer on public profiles; a full email can still be searched via a one-way hashed lookup. Every sign-in moves the email; functions/scripts/migrate_private_emails.js moves the rest. Goes live with the Friday rules deploy.
- [x] **W-2** The wardrobe holds my clothes, the shops I am connected to and the designers I am connected to. — Smart Wardrobe module
  - **Progress:** The wardrobe's Shops & Designers tab now opens with My Circle (your salons, shops and designers, removable), then the directories.
- [ ] **W-3** Add item: take a photo of the piece, and the app detects the colour. Do not ask for colour by hand. — Smart Wardrobe module
- [ ] **W-6** Saved items and looks can be put into categories and are interactive. They should not feel dead. — Smart Wardrobe module
- [ ] **W-7** Track wear: for example "You haven't worn this shirt in 10 months". — Smart Wardrobe module
- [ ] **D-4** Shops and designers you follow add new stock that matches your profile and wardrobe to this feed ("New look from <shop>"). — My Daily Dress Up _(Backend matching engine)_
- [ ] **S-1** Any user can switch between Customer mode and Service-provider mode, like switching between passenger and driver in InDrive. One person can be both. — Service-provider mode
- [ ] **S-2** A provider can be a shop, a designer, a hair stylist or salon, or several of these at once. — Service-provider mode
- [ ] **S-3** Provider mode has its own screens: my shop, my designs, my salon, with forms to enter stock and services. — Service-provider mode _(Not built yet)_
- [ ] **S-4** Shops and designers sign up as normal users, then switch on provider mode. No separate business sign-up. — Service-provider mode
- [ ] **K-1** Shops, including flea-market traders, upload their stock with photos, sizes, measurements and prices. — Marketplace, e-fitting room and monetization _(Uses provider mode (S))_
- [ ] **K-2** Electronic fitting room: try a shop's item on your own body, using your saved measurements. You can turn around and see a fit check (for example "tight around the waist"). The goal is to beat the physical fitting room. — Marketplace, e-fitting room and monetization _(Core value. Depends on U-6 measurements.)_
- [ ] **K-4** From look to purchase: after a makeover, check whether the items are already in your wardrobe. If they are not, suggest shops that have them. — Marketplace, e-fitting room and monetization _(Backend matching)_
- [ ] **K-7** Design the monetization module: track users, transactions, who sold what, commission and payouts. — Marketplace, e-fitting room and monetization _(Not designed yet)_
- [ ] **E-4** Push notifications for trending looks and styles, once there are enough users to create trends. — Engagement and go-to-market
- [ ] **E-5** Opt-in access to the photo gallery: suggest "Check out this look" makeovers made from the user's own photos, as Google Photos does. — Engagement and go-to-market _(Needs clear consent)_

## Tier 5 — Backend, research and go-to-market

_Open-ended. Needs design or research before building._

- [ ] **A-1** Get the original AI and system architecture specification. Ask Da, who built the first version from it; it may also be in a ChatGPT conversation. Read it in detail. — Backend, algorithms and research _(Action: Speaker 2)_
- [ ] **A-3** Build the algorithms in that specification on the backend. — Backend, algorithms and research _(Depends on the item above)_
- [ ] **A-4** Community engine based on location (see the Post, save and share section). — Backend, algorithms and research
- [ ] **A-5** Feed ranking: people you follow first, then wider. — Backend, algorithms and research
- [ ] **A-6** Match shop and designer stock to user profiles (see the Daily Dress Up section). — Backend, algorithms and research
- [ ] **A-7** Shops and smart wardrobes talk to each other: a saved look goes into the wardrobe and is matched against shop stock (see K-4). — Backend, algorithms and research
- [ ] **A-8** Fashion-content engine (see E-2) and monetization tracking (see K-7). — Backend, algorithms and research
- [ ] **P-5** Define "Community" (people near your location) and "Public" (anyone), and build the backend logic that decides who is in each. — Post, save and share _(Backend)_
- [ ] **W-8** Research: physical clothing tags (AirTag-style button tags, RFID) to show what is in or out of the wardrobe, what is at the wash, and to alert when an item leaves the yard (geofence). Include a way to switch a tag off while the owner wears it, and cost per tag. — Smart Wardrobe module _(Long term, hardware. Privacy concerns.)_
- [ ] **E-6** Brand ambassadors: recruit influencers and pay them monthly to use the app, do makeovers, post looks and vlog about it. — Engagement and go-to-market _(Go-to-market)_

## Issues found while working

_Not raised in the meeting; found while building._

- [x] **I-1** Smart Wardrobe items are stored in a top-level user_products collection, but firestore.rules only covered users/{uid}/user_products. On the phone, My Clothes fails with PERMISSION_DENIED and new uploads are refused. _(Fixed and deployed (20 October 2026))_
  - **Action:** A user_products rule was added and deployed: owners read all their items, others only public ones, and only the owner can write.
- [x] **I-2** Any signed-in user can read every post, including private and friends-only ones. The app only hides them on the phone. _(Fixed and tested; deploy with Friday's release)_
  - **Action:** Posts are readable only by their author, by followers or friends as chosen, or by anyone when public; comments follow their post. Feeds now ask only for posts the user may see. 26 rules tests pass in the local emulator (npm --prefix test_rules test). Deploying blocks the old app's feed, so it goes out with the new build.
- [x] **I-3** People search showed everyone's email address and matched partial emails, and other people's profiles showed their email. _(Fixed)_
  - **Action:** Emails are no longer shown, only a full email address matches, and your email appears on your own profile only (see U-3).
- [x] **I-4** Any user could make themselves an admin (isAdmin / role) or mark their own shop, designer or salon profile as verified, because a catch-all rule also matched the profile record itself. _(Fixed and tested; deploy with Friday's release)_
  - **Action:** The catch-all now only covers subcollections; users cannot set admin or verified flags on themselves. Covered by the rules tests.
- [x] **I-5** The curators' "verify shop / designer / salon" buttons wrote to other users' records, which the rules never allowed, so verification could not work from the app. _(Fixed and tested; deploy with Friday's release)_
  - **Action:** Admins may now update only the shop, designer and agent profile sections of other users.

## Release day (Friday)

1. Ship the new app build to testers.
2. Deploy the rules: firebase deploy --only firestore:rules
3. Check on a phone that Home, Community and Daily Dress Up load.
4. Run the email cleanup once, with a service-account key: node functions/scripts/migrate_private_emails.js --dry-run, then without --dry-run.

## Open questions

1. DECIDED 20 Oct: counts are visible to the owner only, on looks and on profiles (fits BNG SRS 001).
2. DECIDED 20 Oct: "My Circle".
3. DECIDED 20 Oct: Repost and Quote always shown; a private look asks to be shared first.
4. DECIDED 20 Oct: keep both, renamed: "Post" (who sees it in the feeds) and "Send to" (salon, shop, designer, WhatsApp, other apps).
5. DECIDED 20 Oct: "G for Good". Needs new logo artwork with the line.
6. DECIDED 20 Oct: one large "Create My Fashion Makeover" button that then asks Hairstyle or Outfit & more.
7. Monetization: what commission rate, and what share goes to influencers?
8. Delivery: do shops deliver themselves, or does the platform provide or partner for delivery?
9. Content engine: what are the copyright and licensing rules for reposting fashion photos found online? We may need to link to the source, or use only licensed content.
