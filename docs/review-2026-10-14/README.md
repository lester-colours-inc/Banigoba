# Banigoba — App Review Checklist

**Meeting:** App review meeting, 14 October 2026 (full transcript, parts 1–3)  
**Prepared by:** Lester  
**Status:** Splash, turn-around and feed cards built on 26 Oct, not yet seen on a phone. Today: phone check, then the feed server job and content engine.  
**Target:** Next app version by the end of next week (about Friday 23 October 2026)

Tick items off as they ship. Item IDs (e.g. `H-2`) match the Word version (`Banigoba_Review_Checklist.docx`).

Items are ordered easiest and clearest first. The ID prefix shows the app area (H = Home, M = Makeover, W = Wardrobe, …).

_Generated from `tools/checklist.json`; edit that file and run `npm run build` in `tools/`._

## Highlights

### ✅ Done in the 20 October session (52 items, 2 issues fixed)

- **H-1** Tab label reads "My Makeover" / "My Fashion Makeover", not "My Timeline". Page heading: "My Fashion Makeover".
- **H-7** Remove the duplicated name on post cards. Show the name once, with "The look" as the label.
- **M-11** Keep generating one item at a time.
- **P-1** Post audience (Friends / Followers / Public) is chosen every time, with no default.
- **D-1** The feed comes from Smart Wardrobe suggestions. Check what currently fills it.
- **U-6** The profile collects body data: height, measurements, a full-body photo, a hand photo and similar.
- **H-2** Makeover button is large and always shows its label: "Create My Fashion Makeover". Make the font smaller if needed so it fits.
- **H-3** The makeover button has a little movement, like the WhatsApp "Ask Meta AI" button.
- **M-2** Say "your photo", not "your full body photo". People may only want to try a hairstyle or sunglasses.
- **M-3** Use a personal, instructional heading such as "My New Look" or "My New Makeover".
- **M-9** Fix the clashing "Describe style twin…" text.
- **M-12** Add a back button so the user can leave without generating.
- **W-5** Add item: add a back button.
- **G-3** Every sub-page has a visible back button. Do not rely on Android gesture navigation.
- **P-2** "Save to My Smart Wardrobe": the icon changes colour once saved, like a like button.
- **H-6** Tapping anywhere on a post card opens it, like X does. At the moment you have to tap the picture itself.
- **U-1** The profile picture can be changed. Today it cannot be edited and shows a placeholder picture.
- **G-1** Every page has a clear heading at the top. Move the top bar up and put the page title in it.
- **M-4** Make the layout a clear either-or: Option A, describe the look; or Option B, use a look you love (style idol, style twin, community).
- **M-5** Option A: the "Describe the look you want" box sits at the top, with the "What should change" chips (hair, outfit, shoes and so on) below it.
- **M-6** The user must write a description AND pick at least one change chip before Generate is enabled. These chips label our backend data sets.
- **M-7** The chips are generic. They do not try to adapt to what is in the uploaded photo.
- **M-8** Option B also asks the user what should change (outfit only, hair, and so on).
- **D-3** If the Smart Wardrobe is not set up, show "Set up your Smart Wardrobe" with a button that opens the setup.
- **D-2** Friends' shared daily dress-ups also appear here, not only yours.
- **H-5** The feed shows everyone's looks (yours, friends, followers, community and public), not only yours. People want engagement.
- **P-3** After saving, show a sheet that says where the look went and lets the user pick or create a category. Today it just says "Saved", which feels like a dark hole.
- **W-1** The Smart Wardrobe page currently shows the wrong content (friends and community). Give it its own wardrobe interface.
- **W-4** Add item: add size fields (size, shoulders and other key measurements).
- **U-3** Add search for people and friends.
- **C-1** The Community feed includes events.
- **C-2** Add a "Create event" entry point and form (for example to announce a fashion show) that posts into Community.
- **H-4** Remove the "No affirmations yet" text. Show a number instead.
- **U-2** Add a way to follow people. "Following" and "Followers" appear on the profile, but nothing lets you follow anyone.
- **P-4** Make Post and Share clearly different, or merge them. Remove the duplication and settle the wording.
- **P-8** Repost and Quote are always visible in the share sheet. Today they only appear after you share to Community.
- **M-1** Starting a makeover offers two choices: "Hairstyle" and "Other" (outfit, shoes, accessories). People think about their hair and face every morning more than about their full outfit.
- **P-7** New feature: users connect with their own salons, shops and designers. We need a name for this kind of connection.
- **P-6** Share to salon, shop or designer: show a row of the ones you are already connected to above the search box.
- **P-9** Bookmark categories, like Facebook's saved collections (for example "Weddings"). The same categories are used in the "look you love" picker.
- **M-10** "See a look you love" picker: add search plus filters for liked, bookmarked, bookmark categories, trending, style idols and people you follow. Show people you follow first.
- **F-1** The Fashion Twins page currently reuses the makeover page. Rebuild it: find people (search, including the internet), add them, follow them. Their activity then appears in your feed.
- **F-3** "My Hair Stylists" is a setup page, not a makeover page: follow stylists and salons, and keep the hairstyles you like (uploaded, found online, or your own photos).
- **F-4** Do not add new timelines. Hairstyle makeovers and posts go into the existing My Fashion Makeover and My Daily Dress Up feeds.
- **U-4** Give every user a unique @username, separate from their display name (which does not need to be unique).
- **U-5** Stop using email as the public identifier. Use a private ID as the key and the username for display.
- **W-2** The wardrobe holds my clothes, the shops I am connected to and the designers I am connected to.
- **W-7** Track wear: for example "You haven't worn this shirt in 10 months".
- **S-1** Any user can switch between Customer mode and Service-provider mode, like switching between passenger and driver in InDrive. One person can be both.
- **S-2** A provider can be a shop, a designer, a hair stylist or salon, or several of these at once.
- **S-3** Provider mode has its own screens: my shop, my designs, my salon, with forms to enter stock and services.
- **S-4** Shops and designers sign up as normal users, then switch on provider mode. No separate business sign-up.
- **I-1** Smart Wardrobe items are stored in a top-level user_products collection, but firestore.rules only covered users/{uid}/user_products. On the phone, My Clothes fails with PERMISSION_DENIED and new uploads are refused.
- **I-3** People search showed everyone's email address and matched partial emails, and other people's profiles showed their email.

**🔶 Started 20 Oct, not finished:**

- **G-4** Fix text that overlaps or clashes, on every screen. — Fixed where found (makeover method labels, profile photo tiles). Still needs a check on a real phone.
- **B-1** Change the payoff line (tagline) to "g, for "Looking Good!!!"", as in the designer's animation. — 27 Oct: updated to the designer's final video. The line is now exactly for, "Looking Good!!!" in bold, beside the g, sized and spaced as in the video; it types in letter by letter with a soft fade on the newest letters. The sound is now the designer's new sound logo (about 4 s, about 60 KB, made louder so it is easy to hear, with a short fade in and out), lined up so the g appears on its first accent. The splash is held about 3.8 s, instead of the video's 7.8 s. Reduced-motion phones see the finished line at once. Waiting on: a check on a real phone (the phone was not reachable, so I only checked rendered frames against the video), and the designer's font file if you want the text to match the video exactly (the app uses its own bold font, which looks very close)
- **E-2** Fashion-content engine: search the internet and the fashion industry for stories and post them to users' feeds, asking "What do you think about this look?" Examples: what is happening in Paris, what Michelle Obama wore 10 days ago, what local Harare socialites are wearing. This works before we have many users. — Decided 22 Oct: show a credited link preview (title, small image and site name from the source) that opens the source; never copy images to our servers. Not built yet. Planned 25 Oct: see docs/plans/service-provider-mode.md (shopping phases). | Built 28 Oct (first version): a scheduled job (every 3 hours) reads 15 publishers' own RSS/Atom feeds (Vogue, Fashionista, ELLE, Harper's Bazaar, The Guardian, Fashion Week Online, BellaNaija, and Zimbabwean news sites such as The Herald, NewZimbabwe, ZBC, 263Chat), keeps the fashion stories, and stores each as a credited link preview: title, a link to the source's own picture, the source's name and the link. No article text and no picture is copied; every card opens the source. Stories expire after 30 days. Tagged by place (Harare, Lagos, ...) and topic. No scraping. Needs deploying. Limit: Zimbabwean fashion coverage is thin because those feeds are general news; more local sources can be added in one line each.
- **E-3** Fashion events from the content engine also appear in the feeds. — Built 28 Oct (first version): stories that announce an event (a fashion week returning, a show to be hosted, tickets, pop-ups, expos, festivals, galas) appear under \"Fashion events\" with an Event tag, above \"In fashion news\", on the Community tab. They are found from the title only, so dates are not read. Still planned: events with dates in My Daily Dress Up, and curator-added events merged in.
- **F-2** Fashion Idols works the same way: search, follow, and their news comes into your feed. — New "My Fashion Idols" page: keep idols by name; "Style me like …" opens the makeover with the idol filled in. Still to do: idols' news and looks in the feed, which needs the fashion-content engine (E-2). Planned 25 Oct: see docs/plans/service-provider-mode.md (shopping phases). Added 28 Oct: \"In the news\" under your idols lists up to two stories that name each idol (whole name in the title). Not yet: following an idol into your feed, and looks about them.
- **W-3** Add item: take a photo of the piece, and the app detects the colour. Do not ask for colour by hand. — First version built 27 Oct: choosing a photo in Add item pre-selects its colours (up to two), with the note "Picked from your photo. Tap to change." Done on the phone from the pixels, with no AI call, so it is free and instant. The middle of the photo counts more than the edges, so a garment against a plain wall comes out right. Limits: it looks at the photo before the background is removed, so a busy or coloured background can fool it; patterned clothes give their main colours only; not yet tried on real photos or a phone. The shop stock form does not have it yet.
- **W-6** Saved items and looks can be put into categories and are interactive. They should not feel dead. — Partly done: saved looks are filed under categories, grouped in Saved Looks, open full screen and show when last worn. 27 Oct: each saved look now has a "move" button to change its category later, make a new one, or remove it from its category. Still missing: categories for clothes in My Clothes. The move button is tested only as a sheet, not yet on a phone.
- **D-4** Shops and designers you follow add new stock that matches your profile and wardrobe to this feed ("New look from <shop>"). — All 3 steps built (1 and 2 on 26 Oct, 3 on 28 Oct). (1) Matching rules, tested: from a shop or designer you follow, in stock in your size (or the fit-check size), suiting a style you chose or filling a wardrobe gap; best three a day. (2) "New from shops you follow" cards at the top of My Daily Dress Up: picture, shop, price and the reasons ("In your size (M). Suits your Smart style"), tap to open the item, and "Not for me" to hide it for good. Nothing shows when nothing matches. The phone does the matching when the feed opens. Still to build: (3) a server job so the cards are ready before the app opens (needs your OK to deploy). Open: the style-name mapping needs your confirmation, gender is not matched, and no shop has a size chart yet, so most matches will rest on the usual size label. Not yet seen on a phone. (3) Built 28 Oct: a server job (Cloud Function matchNewStock) that runs when a shop adds stock or restocks a sold-out piece, applies the same rules for each follower (a JavaScript copy of the app's rules, tested against the same cases) and writes today's cards, so they are ready when the app opens; the app reads those first and works it out itself only when there are none. Up to 3 a day per person, best kept; \"not for me\" is remembered. Needs the function deployed and the new app build.
- **K-1** Shops, including flea-market traders, upload their stock with photos, sizes, measurements and prices. — Partly built (the listing screen existed): photos with a back photo, sizes with stock per size, an optional size chart per size, prices, colours and style. Added 28 Oct: a proper Shoes category with UK shoe sizes (UK 3 to UK 12), which \"Get this look\" now matches against the buyer's shoe size (the wardrobe has the category too); and a stock overview on Products & Inventory: counts for all, low (2 or fewer left) and sold out, filter chips, and a colour-coded \"Only 2 left\" / \"Sold out\" on each piece. Not yet: a quick-add flow for flea-market traders (photo, price, size only), editing stock counts without opening the full form, and delivery settings (K-3).
- **K-2** Electronic fitting room: try a shop's item on your own body, using your saved measurements. You can turn around and see a fit check (for example "tight around the waist"). The goal is to beat the physical fitting room. — Built 25 Oct (committed a641605) (first version): a "Fit check" card on clothing product pages compares the shop's garment measurements with your saved ones and says where it is tight, snug or loose ("Size M: tight around the waist"), shows the numbers, and suggests the best size in stock. Shops can enter an optional size chart (shoulders, chest, waist, hips, inseam per size) in the stock form; where there is none it compares size labels ("a size bigger than you usually wear"). The fit also goes to the Gemini try-on picture. Not yet: existing shop products have no size charts until shops add them; stretchy fabric is not accounted for.
- **K-4** From look to purchase: after a makeover, check whether the items are already in your wardrobe. If they are not, suggest shops that have them. — Built 28 Oct (first version): after a makeover, "Place Order" opens "Get this look". For each changed piece (top, bottom, clothes, shoes, accessories) it says whether you already own something like it ("You have 2 in your wardrobe" or "None in your wardrobe") and offers up to 3 pieces from verified shops that are in stock in your size, best style match first, each with one-tap "Add to bag". Hair links to hairdressers and "Have it made" to designers. It also opens from friends' looks in My Daily Dress Up (whole look). Not yet: colour matching (the look is a picture, so colour per piece is unknown); shoes are recognised by name because neither the wardrobe nor shops have a shoes category; the shop's own products only, no supplier matching.
- **K-8** Turn-around (3D-style) view in the fitting room: turn the try-on around to see the sides and back. — First version built 26 Oct: "Turn me around" on the try-on makes right side, back and left views with AI (one at a time, shown as they arrive); drag left or right, or use the arrows, to turn like a turntable. Sides and back are estimates and are labelled so. Costs three more AI image calls per try-on.  Later options: a short spin video, optional back photo from shops to improve the back view, and true 3D models once shops can supply them. 27 Oct: the angles are now kept with the saved look (also if you turn around after saving), and a saved look that has angles opens in the turn-around viewer from Saved Looks and My Daily Dress Up. Not tried on a phone yet. 27 Oct: shops can add an optional back photo for each item in the stock form; when there is one, the turn-around uses it for the back view instead of guessing. Needs a shop to add the photo, and has not been seen on a phone.
- **A-6** Match shop and designer stock to user profiles (see the Daily Dress Up section). — All 3 steps built (1 and 2 on 26 Oct, 3 on 28 Oct). (1) Matching rules, tested: from a shop or designer you follow, in stock in your size (or the fit-check size), suiting a style you chose or filling a wardrobe gap; best three a day. (2) "New from shops you follow" cards at the top of My Daily Dress Up: picture, shop, price and the reasons ("In your size (M). Suits your Smart style"), tap to open the item, and "Not for me" to hide it for good. Nothing shows when nothing matches. The phone does the matching when the feed opens. Still to build: (3) a server job so the cards are ready before the app opens (needs your OK to deploy). Open: the style-name mapping needs your confirmation, gender is not matched, and no shop has a size chart yet, so most matches will rest on the usual size label. Not yet seen on a phone. (3) Built 28 Oct: a server job (Cloud Function matchNewStock) that runs when a shop adds stock or restocks a sold-out piece, applies the same rules for each follower (a JavaScript copy of the app's rules, tested against the same cases) and writes today's cards, so they are ready when the app opens; the app reads those first and works it out itself only when there are none. Up to 3 a day per person, best kept; \"not for me\" is remembered. Needs the function deployed and the new app build.
- **A-7** Shops and smart wardrobes talk to each other: a saved look goes into the wardrobe and is matched against shop stock (see K-4). — Built 28 Oct (first version, same work as K-4): a look is checked against the wardrobe and matched to verified-shop stock in your size. Not yet: saving a look into a shop's own view, and shops seeing which wardrobes their pieces would fill.
- **A-8** Fashion-content engine (see E-2) and monetization tracking (see K-7). — Content-engine half built 28 Oct (see E-2). Monetization tracking is not started (K-7).

### 📅 Done on 26 October

- [x] DONE: New white splash with "g for looking good", built from the designer's video (B-1).
- [x] DONE: Turn-around view in the fitting room: drag to see the sides and back (K-8).
- [x] DONE: Daily feed matching, steps 1 and 2: the matching rules, and "New from shops you follow" cards in My Daily Dress Up (D-4, A-6).
- [x] DONE: Checklist refreshed with everything left to do.

### 🚀 To do on Tuesday 27 October

- [ ] Reconnect the phone and install a new build.
- [ ] Check on the phone: the new splash, the fit check, the turn-around, the new feed cards, and any overlapping text (G-4).
- [ ] Send the new splash sound file (B-1).
- [ ] Confirm the style-name mapping for feed matching (Smart = corporate, Traditional = afrochic, Elegant = glamour).
- [ ] Tell me whether the 1.1.0 release steps happened (ship build, deploy rules, run email clean-up).
- [ ] Decide: build the server job for the feed cards (step 3), then the content engine (send the list of 5-10 source sites).

## Contents

- [Highlights](#highlights)
- [Principles (apply to all work)](#principles-apply-to-all-work)
- [Tier 1 — Quick wins](#tier-1-quick-wins) — 17/17 done
- [Tier 2 — Clear, medium work](#tier-2-clear-medium-work) — 15/16 done
- [Tier 3 — Needs a decision first](#tier-3-needs-a-decision-first) — 7/13 done
- [Tier 4 — Bigger features](#tier-4-bigger-features) — 13/24 done
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

- [x] **H-1** ✅ **Done 20 Oct** Tab label reads "My Makeover" / "My Fashion Makeover", not "My Timeline". Page heading: "My Fashion Makeover". — Home — My Fashion Makeover tab _(Already done in the latest build. Check it.)_
  - **Progress:** Checked: the tab reads "My Fashion Makeover".
- [x] **H-7** ✅ **Done 20 Oct** Remove the duplicated name on post cards. Show the name once, with "The look" as the label. — Home — My Fashion Makeover tab _(Already fixed in the developer's latest build. Check it.)_
  - **Progress:** Checked in code: the name shows once in the card header.
- [x] **M-11** ✅ **Done 20 Oct** Keep generating one item at a time. — Makeover generator page _(Already done. Check it.)_
  - **Progress:** Checked: the makeover runs one step per item.
- [x] **P-1** ✅ **Done 20 Oct** Post audience (Friends / Followers / Public) is chosen every time, with no default. — Post, save and share _(Agreed. Keep it as it is.)_
  - **Progress:** Checked: the share sheet asks Friends / Followers / Public each time.
- [x] **D-1** ✅ **Done 20 Oct** The feed comes from Smart Wardrobe suggestions. Check what currently fills it. — My Daily Dress Up
  - **Progress:** Checked: the feed shows looks saved to the Smart Wardrobe. AI suggestions and Twins/Idols looks are not built yet (see D-4, F-1).
- [x] **U-6** ✅ **Done 20 Oct** The profile collects body data: height, measurements, a full-body photo, a hand photo and similar. — Profile, identity and social graph
  - **Progress:** My Profile Details now has face, full-body and hand photos, plus height, weight, shoulders, waist, tummy, chest, hips, inside leg and sizes.
- [x] **H-2** ✅ **Done 20 Oct** Makeover button is large and always shows its label: "Create My Fashion Makeover". Make the font smaller if needed so it fits. — Home — My Fashion Makeover tab _(Reverses the recent change to an icon-only button with a tooltip)_
  - **Progress:** Large labelled button "Create My Fashion Makeover".
- [x] **H-3** ✅ **Done 20 Oct** The makeover button has a little movement, like the WhatsApp "Ask Meta AI" button. — Home — My Fashion Makeover tab
  - **Progress:** The button pulses three times when Home opens; this is skipped when the phone asks for reduced motion.
- [x] **M-2** ✅ **Done 20 Oct** Say "your photo", not "your full body photo". People may only want to try a hairstyle or sunglasses. — Makeover generator page
  - **Progress:** "Add Your Photo" / "Your Photo".
- [x] **M-3** ✅ **Done 20 Oct** Use a personal, instructional heading such as "My New Look" or "My New Makeover". — Makeover generator page _(Exact wording to be confirmed)_
  - **Progress:** Heading is now "My New Look". The wording can still change.
- [x] **M-9** ✅ **Done 20 Oct** Fix the clashing "Describe style twin…" text. — Makeover generator page
  - **Progress:** Method labels wrap onto two lines instead of being cut off.
- [x] **M-12** ✅ **Done 20 Oct** Add a back button so the user can leave without generating. — Makeover generator page
  - **Progress:** Back arrow moved to the top left, where people expect it. It was on the right, next to the cart.
- [x] **W-5** ✅ **Done 20 Oct** Add item: add a back button. — Smart Wardrobe module
  - **Progress:** Back arrow added to the "Upload to Wardrobe" sheet.
- [x] **G-3** ✅ **Done 20 Oct** Every sub-page has a visible back button. Do not rely on Android gesture navigation. — Global UI rules (every screen) _(Missing on the makeover generator and on Add wardrobe item)_
  - **Progress:** Screens that can be a tab or a pushed page (Home, Wardrobe, Search, Notifications, My Hair Style) show a back arrow when opened from somewhere else and the menu otherwise. Makeover and Add item are fixed too.
- [x] **P-2** ✅ **Done 20 Oct** "Save to My Smart Wardrobe": the icon changes colour once saved, like a like button. — Post, save and share
  - **Progress:** The icon fills and turns gold once saved. Tap again to remove it from the wardrobe.
- [x] **H-6** ✅ **Done 20 Oct** Tapping anywhere on a post card opens it, like X does. At the moment you have to tap the picture itself. — Home — My Fashion Makeover tab
  - **Progress:** Tapping the name, words or picture opens the look. The action buttons still do their own thing.
- [x] **U-1** ✅ **Done 20 Oct** The profile picture can be changed. Today it cannot be edited and shows a placeholder picture. — Profile, identity and social graph _(Bug)_
  - **Progress:** Tap your own photo on My Profile to take or choose a new one. Settings uses the same code.

## Tier 2 — Clear, medium work

_The requirement is clear. These need more than a one-line change._

- [x] **G-1** ✅ **Done 20 Oct** Every page has a clear heading at the top. Move the top bar up and put the page title in it. — Global UI rules (every screen)
  - **Progress:** Wardrobe heading is "My Smart Wardrobe"; the Discover tab heading now matches the bottom bar; Home's tabs name each feed.
- [ ] **G-4** 🔶 **Started 20 Oct** Fix text that overlaps or clashes, on every screen. — Global UI rules (every screen)
  - **Progress:** Fixed where found (makeover method labels, profile photo tiles). Still needs a check on a real phone.
- [x] **M-4** ✅ **Done 20 Oct** Make the layout a clear either-or: Option A, describe the look; or Option B, use a look you love (style idol, style twin, community). — Makeover generator page _(The current screen is cluttered)_
  - **Progress:** Two large choices: "Describe it" or "Use a look you love". The second shows Style twin, Style idol, Trending and Weather.
- [x] **M-5** ✅ **Done 20 Oct** Option A: the "Describe the look you want" box sits at the top, with the "What should change" chips (hair, outfit, shoes and so on) below it. — Makeover generator page _(Reverses the current order)_
  - **Progress:** The description box sits under "How do you want to create your look?", with "What should change?" below it.
- [x] **M-6** ✅ **Done 20 Oct** The user must write a description AND pick at least one change chip before Generate is enabled. These chips label our backend data sets. — Makeover generator page
  - **Progress:** Nothing is pre-selected. Generate stays off until there is a description (or a chosen look) and a "What should change" choice.
- [x] **M-7** ✅ **Done 20 Oct** The chips are generic. They do not try to adapt to what is in the uploaded photo. — Makeover generator page
  - **Progress:** The chips are the same for every photo: Full look, Outfit only, Hair only, Top only, Bottom only.
- [x] **M-8** ✅ **Done 20 Oct** Option B also asks the user what should change (outfit only, hair, and so on). — Makeover generator page
  - **Progress:** The same "What should change?" chips apply to a look you love.
- [x] **D-3** ✅ **Done 20 Oct** If the Smart Wardrobe is not set up, show "Set up your Smart Wardrobe" with a button that opens the setup. — My Daily Dress Up
  - **Progress:** An empty feed shows "Set up my Smart Wardrobe" and "Add my measurements" buttons.
- [x] **D-2** ✅ **Done 20 Oct** Friends' shared daily dress-ups also appear here, not only yours. — My Daily Dress Up
  - **Progress:** Forward a dress-up to Friends or Community to share it as today's look. Friends' shared dress-ups from the last 36 hours show at the top of the feed.
- [x] **H-5** ✅ **Done 20 Oct** The feed shows everyone's looks (yours, friends, followers, community and public), not only yours. People want engagement. — Home — My Fashion Makeover tab
  - **Progress:** My Fashion Makeover shows your looks plus everyone else's you are allowed to see. Community shows only other people's.
- [x] **P-3** ✅ **Done 20 Oct** After saving, show a sheet that says where the look went and lets the user pick or create a category. Today it just says "Saved", which feels like a dark hole. — Post, save and share
  - **Progress:** After saving, a sheet says "Saved to My Smart Wardrobe", offers categories (or a new one) and a "View in wardrobe" button.
- [x] **W-1** ✅ **Done 20 Oct** The Smart Wardrobe page currently shows the wrong content (friends and community). Give it its own wardrobe interface. — Smart Wardrobe module _(Bug)_
  - **Progress:** Tabs are now My Clothes, Saved Looks (grouped by category) and Shops & Designers. The Friends and Community tabs are gone. My Clothes stays empty until the user_products rule (issue I-1) is deployed.
- [x] **W-4** ✅ **Done 20 Oct** Add item: add size fields (size, shoulders and other key measurements). — Smart Wardrobe module _(Missing today)_
  - **Progress:** Add item asks for size (XXS–XXXL), shoulders and length. These are stored in the same fields shops use. Uploading only works once the user_products rule (issue I-1) is deployed.
- [x] **U-3** ✅ **Done 20 Oct** Add search for people and friends. — Profile, identity and social graph
  - **Progress:** Search was on Discover; there is now a search icon on Home and a "Find people to follow" button on your profile. Search no longer shows emails and matches an email only when the full address is typed. Your email is shown only to you.
- [x] **C-1** ✅ **Done 20 Oct** The Community feed includes events. — Community
  - **Progress:** An "Upcoming events" strip sits at the top of the Community feed.
- [x] **C-2** ✅ **Done 20 Oct** Add a "Create event" entry point and form (for example to announce a fashion show) that posts into Community. — Community _(Not built yet)_
  - **Progress:** There is an "Add event" button on the Community feed. It uses the existing event form, which goes to curators for approval.

## Tier 3 — Needs a decision first

_Blocked on an open question at the end of this document. Quick to build once decided._

- [ ] **B-1** 🔶 **Started 20 Oct** Change the payoff line (tagline) to "g, for "Looking Good!!!"", as in the designer's animation. — Branding _(Confirm exact wording)_
  - **Progress:** 27 Oct: updated to the designer's final video. The line is now exactly for, "Looking Good!!!" in bold, beside the g, sized and spaced as in the video; it types in letter by letter with a soft fade on the newest letters. The sound is now the designer's new sound logo (about 4 s, about 60 KB, made louder so it is easy to hear, with a short fade in and out), lined up so the g appears on its first accent. The splash is held about 3.8 s, instead of the video's 7.8 s. Reduced-motion phones see the finished line at once. Waiting on: a check on a real phone (the phone was not reachable, so I only checked rendered frames against the video), and the designer's font file if you want the text to match the video exactly (the app uses its own bold font, which looks very close)
- [x] **H-4** ✅ **Done 20 Oct** Remove the "No affirmations yet" text. Show a number instead. — Home — My Fashion Makeover tab _(Open question 1: this clashes with the work plan's "no counters" rule)_
  - **Progress:** Decided: owner-only count. "No affirmations yet" is gone. The look's owner sees the total; everyone else sees which affirmations were given, never a number (fits BNG SRS 001).
- [x] **U-2** ✅ **Done 20 Oct** Add a way to follow people. "Following" and "Followers" appear on the profile, but nothing lets you follow anyone. — Profile, identity and social graph _(Open question 1 (counts))_
  - **Progress:** Follow already existed on other people's profiles and is now reachable through people search. Follower and following numbers show only to the profile owner; others see the lists without totals.
- [x] **P-4** ✅ **Done 20 Oct** Make Post and Share clearly different, or merge them. Remove the duplication and settle the wording. — Post, save and share
  - **Progress:** Decided: keep both, renamed. "Post" (in the ⋮ menu) decides who sees the look in the feeds; "Send to" (share icon) sends it to a salon, shop, designer, WhatsApp or other apps. Community and Friends are no longer in Send to. Daily Dress Up has its own "Post as today's dress-up" action.
- [x] **P-8** ✅ **Done 20 Oct** Repost and Quote are always visible in the share sheet. Today they only appear after you share to Community. — Post, save and share _(Today quoting is only possible on public looks. Open question 3.)_
  - **Progress:** Decided: always shown. On a private look, Repost or Quote first asks "Share this look first?", then carries on.
- [x] **M-1** ✅ **Done 20 Oct** Starting a makeover offers two choices: "Hairstyle" and "Other" (outfit, shoes, accessories). People think about their hair and face every morning more than about their full outfit. — Makeover generator page _(Open question 6: two buttons or one button that asks)_
  - **Progress:** Decided: one button, then a choice. "Create My Fashion Makeover" (and the menu item) asks Hairstyle or Outfit & more first.
- [x] **P-7** ✅ **Done 20 Oct** New feature: users connect with their own salons, shops and designers. We need a name for this kind of connection. — Post, save and share _(Open question 2)_
  - **Progress:** Decided: "My Circle". Add or remove any salon, shop or designer from the Send to list; kept privately per user.
- [x] **P-6** ✅ **Done 20 Oct** Share to salon, shop or designer: show a row of the ones you are already connected to above the search box. — Post, save and share
  - **Progress:** Send to shows your Circle as a one-tap row above the search, then everyone else.
- [ ] **K-5** 🗳️ **Decided 22 Oct** Platform commission on every sale, like InDrive (for example $1.00 item + $0.20). — Marketplace, e-fitting room and monetization _(Open question 7 (rates))_
  - **Progress:** Decided 22 Oct: 20% added on top of the seller's price (a $1.00 item costs the buyer $1.20); the seller gets their full price. Not built yet.
- [ ] **K-6** 🗳️ **Decided 22 Oct** Influencers share in the revenue from sales they bring in. — Marketplace, e-fitting room and monetization
  - **Progress:** Decided 22 Oct: the influencer whose post or link brought the sale gets 25% of the commission (5c on a $1.00 item). Not built yet.
- [ ] **K-3** 🗳️ **Decided 22 Oct** Buy online with delivery, so people do not have to queue or walk around a crowded flea market. — Marketplace, e-fitting room and monetization _(Open question 8 (delivery))_
  - **Progress:** Decided 22 Oct: shops deliver themselves (they set whether they deliver, the fee and the areas) or the buyer collects; the app tracks the status. Not built yet.
- [ ] **E-2** 🔶 **Started 20 Oct** Fashion-content engine: search the internet and the fashion industry for stories and post them to users' feeds, asking "What do you think about this look?" Examples: what is happening in Paris, what Michelle Obama wore 10 days ago, what local Harare socialites are wearing. This works before we have many users. — Engagement and go-to-market _(Backend. Open question 9 (image rights))_
  - **Progress:** Decided 22 Oct: show a credited link preview (title, small image and site name from the source) that opens the source; never copy images to our servers. Not built yet. Planned 25 Oct: see docs/plans/service-provider-mode.md (shopping phases). | Built 28 Oct (first version): a scheduled job (every 3 hours) reads 15 publishers' own RSS/Atom feeds (Vogue, Fashionista, ELLE, Harper's Bazaar, The Guardian, Fashion Week Online, BellaNaija, and Zimbabwean news sites such as The Herald, NewZimbabwe, ZBC, 263Chat), keeps the fashion stories, and stores each as a credited link preview: title, a link to the source's own picture, the source's name and the link. No article text and no picture is copied; every card opens the source. Stories expire after 30 days. Tagged by place (Harare, Lagos, ...) and topic. No scraping. Needs deploying. Limit: Zimbabwean fashion coverage is thin because those feeds are general news; more local sources can be added in one line each.
- [ ] **E-3** 🔶 **Started 20 Oct** Fashion events from the content engine also appear in the feeds. — Engagement and go-to-market _(Links to C-1)_
  - **Progress:** Built 28 Oct (first version): stories that announce an event (a fashion week returning, a show to be hosted, tickets, pop-ups, expos, festivals, galas) appear under \"Fashion events\" with an Event tag, above \"In fashion news\", on the Community tab. They are found from the title only, so dates are not read. Still planned: events with dates in My Daily Dress Up, and curator-added events merged in.

## Tier 4 — Bigger features

_Clear, but large: new screens, new data, or migrations._

- [x] **P-9** ✅ **Done 20 Oct** Bookmark categories, like Facebook's saved collections (for example "Weddings"). The same categories are used in the "look you love" picker. — Post, save and share
  - **Progress:** Saved looks already carry the category chosen when saving (P-3); they can now be browsed by category in Smart Wardrobe › Saved Looks and in the look picker.
- [x] **M-10** ✅ **Done 20 Oct** "See a look you love" picker: add search plus filters for liked, bookmarked, bookmark categories, trending, style idols and people you follow. Show people you follow first. — Makeover generator page
  - **Progress:** "Find a look you love" picker: Following (first), Fashion Twins, Saved (by category), Affirmed and Community, with search by words, category, name or @username. Still to do: Trending and Style idols sources, which need the content engine (E-2).
- [x] **F-1** ✅ **Done 20 Oct** The Fashion Twins page currently reuses the makeover page. Rebuild it: find people (search, including the internet), add them, follow them. Their activity then appears in your feed. — Fashion Twins, Fashion Idols and Hair Stylists _(Same page reused several times today)_
  - **Progress:** New "My Fashion Twins" page: find people by name or @username, add them (this also asks to follow them, so their looks reach your feeds), open their profiles, remove them.
- [ ] **F-2** 🔶 **Started 20 Oct** Fashion Idols works the same way: search, follow, and their news comes into your feed. — Fashion Twins, Fashion Idols and Hair Stylists
  - **Progress:** New "My Fashion Idols" page: keep idols by name; "Style me like …" opens the makeover with the idol filled in. Still to do: idols' news and looks in the feed, which needs the fashion-content engine (E-2). Planned 25 Oct: see docs/plans/service-provider-mode.md (shopping phases). Added 28 Oct: \"In the news\" under your idols lists up to two stories that name each idol (whole name in the title). Not yet: following an idol into your feed, and looks about them.
- [x] **F-3** ✅ **Done 20 Oct** "My Hair Stylists" is a setup page, not a makeover page: follow stylists and salons, and keep the hairstyles you like (uploaded, found online, or your own photos). — Fashion Twins, Fashion Idols and Hair Stylists
  - **Progress:** New "My Hair Stylists" setup page: your salons (My Circle, with "Find a salon"), "Hairstyles I like" from your photos or camera, "Try this on me" (hair makeover copying that style) and "Try a new hairstyle".
- [x] **F-4** ✅ **Done 20 Oct** Do not add new timelines. Hairstyle makeovers and posts go into the existing My Fashion Makeover and My Daily Dress Up feeds. — Fashion Twins, Fashion Idols and Hair Stylists _(Keep the number of feeds small)_
  - **Progress:** The menu no longer opens the old hair flow. Its code (and the unreachable My Fashion Style page) has been deleted, about 5,400 lines; the curators' hairstyle catalogue upload moved to the admin area. Hair makeovers go through the main makeover and appear in the normal feeds. Hair looks saved in the old flow are still in the database but no longer shown.
- [x] **U-4** ✅ **Done 20 Oct** Give every user a unique @username, separate from their display name (which does not need to be unique). — Profile, identity and social graph
  - **Progress:** Built: unique @username (3–20 characters; letters, numbers, dots, underscores), held in a usernames lookup so no two people can have the same one. Anyone without one is asked once, with a suggestion from their name. It shows on profiles and in search, and can be changed in Settings. Database rules deployed 20 October 2026.
- [x] **U-5** ✅ **Done 20 Oct** Stop using email as the public identifier. Use a private ID as the key and the username for display. — Profile, identity and social graph _(Backend migration, privacy)_
  - **Progress:** Built and tested: emails now live in a private record (owner only) and are no longer on public profiles; a full email can still be searched via a one-way hashed lookup. Every sign-in moves the email; functions/scripts/migrate_private_emails.js moves the rest. Goes live with the Friday rules deploy.
- [x] **W-2** ✅ **Done 20 Oct** The wardrobe holds my clothes, the shops I am connected to and the designers I am connected to. — Smart Wardrobe module
  - **Progress:** The wardrobe's Shops & Designers tab now opens with My Circle (your salons, shops and designers, removable), then the directories.
- [ ] **W-3** 🔶 **Started 20 Oct** Add item: take a photo of the piece, and the app detects the colour. Do not ask for colour by hand. — Smart Wardrobe module
  - **Progress:** First version built 27 Oct: choosing a photo in Add item pre-selects its colours (up to two), with the note "Picked from your photo. Tap to change." Done on the phone from the pixels, with no AI call, so it is free and instant. The middle of the photo counts more than the edges, so a garment against a plain wall comes out right. Limits: it looks at the photo before the background is removed, so a busy or coloured background can fool it; patterned clothes give their main colours only; not yet tried on real photos or a phone. The shop stock form does not have it yet.
- [ ] **W-6** 🔶 **Started 20 Oct** Saved items and looks can be put into categories and are interactive. They should not feel dead. — Smart Wardrobe module
  - **Progress:** Partly done: saved looks are filed under categories, grouped in Saved Looks, open full screen and show when last worn. 27 Oct: each saved look now has a "move" button to change its category later, make a new one, or remove it from its category. Still missing: categories for clothes in My Clothes. The move button is tested only as a sheet, not yet on a phone.
- [x] **W-7** ✅ **Done 20 Oct** Track wear: for example "You haven't worn this shirt in 10 months". — Smart Wardrobe module
  - **Progress:** Clothes in My Clothes have "I wore this today" and show "Worn 3 weeks ago" / "Not worn in 10 months" (highlighted after 6 months, or when never worn after a month). Saved Looks show when each was last worn, from "Wear today".
- [ ] **D-4** 🔶 **Started 20 Oct** Shops and designers you follow add new stock that matches your profile and wardrobe to this feed ("New look from <shop>"). — My Daily Dress Up _(Backend matching engine)_
  - **Progress:** All 3 steps built (1 and 2 on 26 Oct, 3 on 28 Oct). (1) Matching rules, tested: from a shop or designer you follow, in stock in your size (or the fit-check size), suiting a style you chose or filling a wardrobe gap; best three a day. (2) "New from shops you follow" cards at the top of My Daily Dress Up: picture, shop, price and the reasons ("In your size (M). Suits your Smart style"), tap to open the item, and "Not for me" to hide it for good. Nothing shows when nothing matches. The phone does the matching when the feed opens. Still to build: (3) a server job so the cards are ready before the app opens (needs your OK to deploy). Open: the style-name mapping needs your confirmation, gender is not matched, and no shop has a size chart yet, so most matches will rest on the usual size label. Not yet seen on a phone. (3) Built 28 Oct: a server job (Cloud Function matchNewStock) that runs when a shop adds stock or restocks a sold-out piece, applies the same rules for each follower (a JavaScript copy of the app's rules, tested against the same cases) and writes today's cards, so they are ready when the app opens; the app reads those first and works it out itself only when there are none. Up to 3 a day per person, best kept; \"not for me\" is remembered. Needs the function deployed and the new app build.
- [x] **S-1** ✅ **Done 20 Oct** Any user can switch between Customer mode and Service-provider mode, like switching between passenger and driver in InDrive. One person can be both. — Service-provider mode
  - **Progress:** Built 28 Oct: a Customer / Provider switch at the top of the menu and a "Provider mode" row in Settings. Switching never signs you out. The old Seller Mode switch (which turned the whole app into the shop screen) is gone.
- [x] **S-2** ✅ **Done 20 Oct** A provider can be a shop, a designer, a hair stylist or salon, or several of these at once. — Service-provider mode
  - **Progress:** Built 28 Oct: one person can hold shop, designer and salon together; roles set up before are carried over automatically.
- [x] **S-3** ✅ **Done 20 Oct** Provider mode has its own screens: my shop, my designs, my salon, with forms to enter stock and services. — Service-provider mode
  - **Progress:** Built 28 Oct: a provider home with a card per role (My Shop, My Designs, My Salon), "Orders & requests" (orders, design requests and hair requests together, with Accept / Decline / Completed and a notification to the customer) and Messages. Needs the new database rules deployed for design and hair requests.
- [x] **S-4** ✅ **Done 20 Oct** Shops and designers sign up as normal users, then switch on provider mode. No separate business sign-up. — Service-provider mode
  - **Progress:** Built 28 Oct: one "Become a provider" form (tick what you offer, business name, location) for any user; every old "Create profile" button now opens it. Listings still appear only after a curator verifies them.
- [ ] **K-1** 🔶 **Started 20 Oct** Shops, including flea-market traders, upload their stock with photos, sizes, measurements and prices. — Marketplace, e-fitting room and monetization _(Provider mode (S) is built, so shops now reach this from My Shop.)_
  - **Progress:** Partly built (the listing screen existed): photos with a back photo, sizes with stock per size, an optional size chart per size, prices, colours and style. Added 28 Oct: a proper Shoes category with UK shoe sizes (UK 3 to UK 12), which \"Get this look\" now matches against the buyer's shoe size (the wardrobe has the category too); and a stock overview on Products & Inventory: counts for all, low (2 or fewer left) and sold out, filter chips, and a colour-coded \"Only 2 left\" / \"Sold out\" on each piece. Not yet: a quick-add flow for flea-market traders (photo, price, size only), editing stock counts without opening the full form, and delivery settings (K-3).
- [ ] **K-2** 🔶 **Started 20 Oct** Electronic fitting room: try a shop's item on your own body, using your saved measurements. You can turn around and see a fit check (for example "tight around the waist"). The goal is to beat the physical fitting room. — Marketplace, e-fitting room and monetization _(Core value. Depends on U-6 measurements.)_
  - **Progress:** Built 25 Oct (committed a641605) (first version): a "Fit check" card on clothing product pages compares the shop's garment measurements with your saved ones and says where it is tight, snug or loose ("Size M: tight around the waist"), shows the numbers, and suggests the best size in stock. Shops can enter an optional size chart (shoulders, chest, waist, hips, inseam per size) in the stock form; where there is none it compares size labels ("a size bigger than you usually wear"). The fit also goes to the Gemini try-on picture. Not yet: existing shop products have no size charts until shops add them; stretchy fabric is not accounted for.
- [ ] **K-4** 🔶 **Started 20 Oct** From look to purchase: after a makeover, check whether the items are already in your wardrobe. If they are not, suggest shops that have them. — Marketplace, e-fitting room and monetization _(Backend matching)_
  - **Progress:** Built 28 Oct (first version): after a makeover, "Place Order" opens "Get this look". For each changed piece (top, bottom, clothes, shoes, accessories) it says whether you already own something like it ("You have 2 in your wardrobe" or "None in your wardrobe") and offers up to 3 pieces from verified shops that are in stock in your size, best style match first, each with one-tap "Add to bag". Hair links to hairdressers and "Have it made" to designers. It also opens from friends' looks in My Daily Dress Up (whole look). Not yet: colour matching (the look is a picture, so colour per piece is unknown); shoes are recognised by name because neither the wardrobe nor shops have a shoes category; the shop's own products only, no supplier matching.
- [ ] **K-7** 🗳️ **Decided 22 Oct** Design the monetization module: track users, transactions, who sold what, commission and payouts. — Marketplace, e-fitting room and monetization _(Not designed yet)_
  - **Progress:** 22 Oct: when this starts, decide whether money records (orders, commission, influencer share, payouts) live in a Postgres database (Supabase or Cloud SQL) next to Firebase.
- [ ] **E-4** 📅 **Deploys 23 Oct** Push notifications for trending looks and styles, once there are enough users to create trends. — Engagement and go-to-market
  - **Progress:** Planned 25 Oct: see docs/plans/service-provider-mode.md (shopping phases).
- [ ] **E-5** Opt-in access to the photo gallery: suggest "Check out this look" makeovers made from the user's own photos, as Google Photos does. — Engagement and go-to-market _(Needs clear consent)_
- [ ] **K-8** 🔶 **Started 20 Oct** Turn-around (3D-style) view in the fitting room: turn the try-on around to see the sides and back. — Marketplace, e-fitting room and monetization _(Added 26 Oct)_
  - **Progress:** First version built 26 Oct: "Turn me around" on the try-on makes right side, back and left views with AI (one at a time, shown as they arrive); drag left or right, or use the arrows, to turn like a turntable. Sides and back are estimates and are labelled so. Costs three more AI image calls per try-on.  Later options: a short spin video, optional back photo from shops to improve the back view, and true 3D models once shops can supply them. 27 Oct: the angles are now kept with the saved look (also if you turn around after saving), and a saved look that has angles opens in the turn-around viewer from Saved Looks and My Daily Dress Up. Not tried on a phone yet. 27 Oct: shops can add an optional back photo for each item in the stock form; when there is one, the turn-around uses it for the back view instead of guessing. Needs a shop to add the photo, and has not been seen on a phone.

## Tier 5 — Backend, research and go-to-market

_Open-ended. Needs design or research before building._

- [ ] **A-1** Get the original AI and system architecture specification. Ask Da, who built the first version from it; it may also be in a ChatGPT conversation. Read it in detail. — Backend, algorithms and research _(Action: Speaker 2)_
- [ ] **A-3** Build the algorithms in that specification on the backend. — Backend, algorithms and research _(Depends on the item above)_
- [ ] **A-4** Community engine based on location (see the Post, save and share section). — Backend, algorithms and research
- [ ] **A-5** Feed ranking: people you follow first, then wider. — Backend, algorithms and research
- [ ] **A-6** 🔶 **Started 20 Oct** Match shop and designer stock to user profiles (see the Daily Dress Up section). — Backend, algorithms and research
  - **Progress:** All 3 steps built (1 and 2 on 26 Oct, 3 on 28 Oct). (1) Matching rules, tested: from a shop or designer you follow, in stock in your size (or the fit-check size), suiting a style you chose or filling a wardrobe gap; best three a day. (2) "New from shops you follow" cards at the top of My Daily Dress Up: picture, shop, price and the reasons ("In your size (M). Suits your Smart style"), tap to open the item, and "Not for me" to hide it for good. Nothing shows when nothing matches. The phone does the matching when the feed opens. Still to build: (3) a server job so the cards are ready before the app opens (needs your OK to deploy). Open: the style-name mapping needs your confirmation, gender is not matched, and no shop has a size chart yet, so most matches will rest on the usual size label. Not yet seen on a phone. (3) Built 28 Oct: a server job (Cloud Function matchNewStock) that runs when a shop adds stock or restocks a sold-out piece, applies the same rules for each follower (a JavaScript copy of the app's rules, tested against the same cases) and writes today's cards, so they are ready when the app opens; the app reads those first and works it out itself only when there are none. Up to 3 a day per person, best kept; \"not for me\" is remembered. Needs the function deployed and the new app build.
- [ ] **A-7** 🔶 **Started 20 Oct** Shops and smart wardrobes talk to each other: a saved look goes into the wardrobe and is matched against shop stock (see K-4). — Backend, algorithms and research
  - **Progress:** Built 28 Oct (first version, same work as K-4): a look is checked against the wardrobe and matched to verified-shop stock in your size. Not yet: saving a look into a shop's own view, and shops seeing which wardrobes their pieces would fill.
- [ ] **A-8** 🔶 **Started 20 Oct** Fashion-content engine (see E-2) and monetization tracking (see K-7). — Backend, algorithms and research
  - **Progress:** Content-engine half built 28 Oct (see E-2). Monetization tracking is not started (K-7).
- [ ] **P-5** Define "Community" (people near your location) and "Public" (anyone), and build the backend logic that decides who is in each. — Post, save and share _(Backend)_
- [ ] **W-8** Research: physical clothing tags (AirTag-style button tags, RFID) to show what is in or out of the wardrobe, what is at the wash, and to alert when an item leaves the yard (geofence). Include a way to switch a tag off while the owner wears it, and cost per tag. — Smart Wardrobe module _(Long term, hardware. Privacy concerns.)_
- [ ] **E-6** Brand ambassadors: recruit influencers and pay them monthly to use the app, do makeovers, post looks and vlog about it. — Engagement and go-to-market _(Go-to-market)_

## Issues found while working

_Not raised in the meeting; found while building._

- [x] **I-1** ✅ **Done 20 Oct** Smart Wardrobe items are stored in a top-level user_products collection, but firestore.rules only covered users/{uid}/user_products. On the phone, My Clothes fails with PERMISSION_DENIED and new uploads are refused. _(Fixed and deployed (20 October 2026))_
  - **Action:** A user_products rule was added and deployed: owners read all their items, others only public ones, and only the owner can write.
- [x] **I-2** 📅 **Deploys 23 Oct** Any signed-in user can read every post, including private and friends-only ones. The app only hides them on the phone. _(Fixed and tested; deploy with Friday's release)_
  - **Action:** Posts are readable only by their author, by followers or friends as chosen, or by anyone when public; comments follow their post. Feeds now ask only for posts the user may see. 26 rules tests pass in the local emulator (npm --prefix test_rules test). Deploying blocks the old app's feed, so it goes out with the new build.
- [x] **I-3** ✅ **Done 20 Oct** People search showed everyone's email address and matched partial emails, and other people's profiles showed their email. _(Fixed)_
  - **Action:** Emails are no longer shown, only a full email address matches, and your email appears on your own profile only (see U-3).
- [x] **I-4** 📅 **Deploys 23 Oct** Any user could make themselves an admin (isAdmin / role) or mark their own shop, designer or salon profile as verified, because a catch-all rule also matched the profile record itself. _(Fixed and tested; deploy with Friday's release)_
  - **Action:** The catch-all now only covers subcollections; users cannot set admin or verified flags on themselves. Covered by the rules tests.
- [x] **I-5** 📅 **Deploys 23 Oct** The curators' "verify shop / designer / salon" buttons wrote to other users' records, which the rules never allowed, so verification could not work from the app. _(Fixed and tested; deploy with Friday's release)_
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
5. DECIDED 26 Oct: "g for looking good", from the designer's animation.
6. DECIDED 20 Oct: one large "Create My Fashion Makeover" button that then asks Hairstyle or Outfit & more.
7. DECIDED 22 Oct: commission 20% added on top of the seller's price; the influencer who brought the sale gets 25% of it.
8. DECIDED 22 Oct: shops deliver themselves (fee and areas set per shop) or the buyer collects; the app tracks the status.
9. DECIDED 22 Oct: credited link previews that open the source; no copying of images.
