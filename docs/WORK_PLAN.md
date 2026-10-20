# Banigoba — Work Plan

**Prepared by:** Lester
**Date:** 24 September 2026
**Status:** Draft for review

---

## 1. Purpose

This plan follows our app review meeting. It sets out what we are building, in what order, and how we will know each piece is done. Every page is listed so you can comment on any of them before work starts.

**Guiding direction from the meeting:**

1. **Simple first.** The app is too busy. Every screen should do one clear job.
2. **The makeover is the hook.** The first experience must be nice, simple and interactive with friends.
3. **Selling is the goal.** Wardrobe, boutiques, salons and designers come after the user accepts a look.
4. **Affirmation, not validation.** No likes, no view counts, no follower counts. Comments are preset only.

---

## 2. Target user journey

```
Logo / splash
   ↓
Marketing slides (what Banigoba does — shown once, before login)
   ↓
Create account / Log in
   ↓
Preferences (style, sizes, location — skippable, can finish later in Settings)
   ↓
HOME (X-style feed)  ──►  [Makeover] floating button
                              ↓
                          Upload photo
                              ↓
                          Choose how: Describe · Fashion idol/twin · Weather · Trending
                          Choose scope: Full body · Hair only · Top only …
                              ↓
                          Generate (one look at a time) → try variations
                              ↓
                          Ask friends ("What do you think?")
                              ↓
                          Accept the look
                              ↓
                          Post to Friends / Community  (and/or)
                              ↓
                          "Get this look": your wardrobe → boutiques / salons / retail
                              ↓
                          Message a boutique or hairdresser ("Can you do this for me?")
```

A diagram version of this flow will be shared with the plan.

---

## 3. Phases at a glance

| Phase | Focus | Proposed duration | Depends on |
|---|---|---|---|
| **0** | Alignment: read the spec, confirm open questions, share the flow diagram | 1 day | — |
| **1** | **Home page:** X-style feed and Makeover button | 3–4 days | Phase 0 |
| **2** | Onboarding: marketing slides, sign-up, preferences | 2 days | Phase 0 |
| **3** | Makeover flow: new input options, scope, faster generation | 4–5 days | Phase 1 |
| **4** | Sharing and affirmation rules: post, share, preset comments, moderation | 2–3 days | Phase 1 |
| **5** | "Get this look": wardrobe match, then boutiques, salons, retail | 5–7 days | Phase 3 |
| **6** | Wardrobe upload (photo + measurements, cleaned-up image) | 3–4 days | Phase 5 |
| **7** | Supplier side: boutique/salon onboarding, fitting room, designer alerts | Scoped separately | Phase 5 |
| **8** | Later: fashion idol portals, physical wardrobe tracking (QR tags) | Scoped separately | — |

Durations are estimates for review. Phases 1 and 2 can run side by side. Each phase ends with a demo to you before the next one starts.

---

## 4. Phase details

### Phase 0: Alignment (1 day)

- Read the specification document you forwarded, and note anything in this plan that conflicts with it.
- Share the user-journey diagram (Section 2).
- Get answers to the open questions in Section 6.

**Done when:** you have approved this plan and the diagram.

---

### Phase 1: Home page (3–4 days) ⭐ first priority

**Goal:** You open the app and land on a simple feed. You can find your own looks instantly.

| Item | Detail |
|---|---|
| Rename | "Daily Dress Up" / "Mine" becomes **Home**. Daily Dress Up stays as its own feature. |
| Layout | Copy X: tabs at the top (**My timeline · Friends · Community**), posts as tweet-style cards |
| Feed design | Switch to the **simple** timeline variant from the UI kit, replacing the busy one |
| Post card | Picture of the look, user name, and **Try On · Comment · Share** under each post |
| Floating button | **Makeover** button on Home. It replaces the misplaced "Create" button and can also appear on Daily Dress Up. |
| Declutter | Move **Style by Occasion, Plan Ahead, Shopping Intelligence** off Home. The code is kept, not deleted. |
| Shopping Intelligence | Add an "order / get this look" action on the side of each post picture (design to agree during this phase) |
| Bug fix | Feed tabs are currently hidden behind the navigation buttons |
| Findability | After you post or save a makeover, it appears at the top of **My timeline** |

**Done when:**
- A new user lands on Home.
- A makeover they post shows on My timeline straight away.
- Nothing on Home is unrelated to the feed or the makeover.

---

### Phase 2: Onboarding (2 days)

| Item | Detail |
|---|---|
| Marketing slides | 3–4 slides that sell the app (makeover, share with friends, find it near you). Shown once, before login. |
| Copy example | "See trends based on your location" |
| Sign-up / login | Kept as is, with minor tidy-up |
| Preferences | Moved **after** account creation. Every question is skippable and can be finished later in Settings. |
| Notifications | Keep the existing permission screen |
| Logout | Show the intro again after logout (to confirm, see Section 6) |

**Done when:** the order matches Section 2, and a first-time user reaches Home in under a minute.

---

### Phase 3: Makeover flow (4–5 days)

**Goal:** Creating a makeover feels as easy as writing a tweet.

| Item | Detail |
|---|---|
| Entry | Makeover button → upload or take a photo |
| **Option 1: Describe** | Free text, e.g. "I want a low haircut" → Generate |
| **Option 2: Fashion idol / twin** | Pick an icon or a "fashion twin" to base the look on |
| **Option 3: Weather** | A look suited to today's weather at the user's location |
| **Option 4: Trending** | What's popular in the user's community or area |
| Scope | Full body · Hair only · Top only · Bottom only · Outfit + hair |
| Remove catalogue-first | Products are **not** the starting point. People see themselves first and buy afterwards. |
| Speed | Generate **one look at a time** and show it straight away, rather than queueing many. Target a clearly shorter wait than today (to measure in this phase). |
| Provider | The AI provider never appears in the UI; it lives only in the backend |
| Iterate | "Try another" keeps the photo and settings |

**Done when:**
- All four options produce a look.
- The first result shows faster than today (numbers to be reported).
- No provider names appear anywhere in the app.

---

### Phase 4: Sharing and affirmation rules (2–3 days)

| Item | Detail |
|---|---|
| Post | Post an accepted look to **Friends** or **Community** |
| Share / forward | Send a look to a friend and ask "What do you think?" |
| Comments | **Preset only:** affirmations and emojis, no free text. Partly built already. |
| Remove counters | No like counts, view counts or follower counts anywhere |
| Moderation | Report and remove, as required by the App Store |

**Done when:** a full review of every screen finds no counters and no free-text input on social surfaces, and a report flow exists.

---

### Phase 5: "Get this look" (5–7 days)

**Goal:** Turn an accepted look into a sale.

| Step | Detail |
|---|---|
| 1. Wardrobe check | "You already have X and Y. You're missing a beige Z." |
| 2. Match suppliers | Show which boutique, salon or retailer has each missing piece |
| 3. Demand alerts | If nobody stocks it, notify designers and boutiques: "Someone in your community wants this" |
| 4. New stock alerts | Tell users when a boutique adds an item that fits a look they accepted |
| 5. Messaging | Message a boutique, shop or hairdresser with the look attached: "Can you do this for me?" |

**Done when:** an accepted look shows at least one of: a wardrobe match, a supplier match, or a sent demand alert.

---

### Phase 6: Wardrobe upload (3–4 days)

| Item | Detail |
|---|---|
| Add item | Take a photo and describe it with the usual measurements (waist, shoulders, length, size) |
| Clean-up | The system straightens and tidies the photo so it looks presentable |
| Use | Wardrobe items feed the Phase 5 wardrobe check |

---

### Phase 7: Supplier side (to be scoped separately)

- **Boutiques, designers, flea markets:** upload items with photos, sizes and lengths. Items display on a hanger.
- **Virtual fitting room:** customers try items on, with fit shown by width, length and cut.
- **Salons and hairdressers:** use the app with clients to try several styles until the client picks one.

### Phase 8: Later (to be scoped separately)

- **Fashion idol / influencer portals:** idols join the platform and earn when people buy their looks.
- **Physical wardrobe tracking:** QR codes or tags on clothes, so the app knows what's in and what's out ("gone for washing").

---

## 4a. Backlog (October 2026 review)

These came out of the 12 October 2026 review. Each needs its own design and
scoping before building. Smaller items from the same review are already done
(see section 7).

### Feeds

| Item | Detail |
|---|---|
| Location trending timeline | An algorithm that picks out affirmation lingo, praise songs, *mitupo* and other cultural expressions trending in the user's location, and builds a trending timeline from them. It can include local events. |
| Extra locations | Users add other places (e.g. New York) whose trending fashion feeds into their trending timeline and their Community feed. |
| Community: events and location | Community already shows friends, followers and public looks. Still to add: events, people around the user's location, and the far-away places they choose. Needs a location on each post. |
| Daily Dress Up sources | Daily Dress Up currently shows Smart Wardrobe looks. Still to add: Smart Wardrobe AI suggestions, and looks from the Fashion Twins and Fashion Idols the user picks (there is no way to pick them yet). |
| eFitting Room | A virtual fitting room inside the Daily Dress Up feed. |

### Shops and demand

| Item | Detail |
|---|---|
| Smart Wardrobe ↔ shop stock (AI) | Match the user's wardrobe against shop and boutique stock, so the Smart Wardrobe can suggest pieces that work with what they own. |
| Makeover ↔ shops (AI) | Suggest shops whose pieces fit a makeover. If nothing is in stock, the user can pre-order or queue the request with their preferred shops, or any shop. |
| Demand from fantasies | Makeovers stay based on what the user imagines (colours, descriptions), not on what is in stock. Each makeover becomes product demand that is queued with shops. When stock appears, Banigoba links the user and the shop with notifications. |
| Smart Wardrobe input window | A proper screen for adding items to the Smart Wardrobe. |
| Shop stock input window | A screen for shops and boutiques to enter their stock. |
| Financial management | Bookkeeping for shops, boutiques and flea-market sellers, simple enough for the informal market. Part of the value proposition for them. |

### Hardware

| Item | Detail |
|---|---|
| Shop stock sensors | Tags on shop pieces so shops can track stock. Removed when a customer buys. |
| Wardrobe sensors | User-owned tags so the Smart Wardrobe knows whether each piece is in the wardrobe, out for washing, or lost (outside a geofence). Extends "Physical wardrobe tracking" in Phase 8. |

---

## 5. How we'll work

- **Demo at the end of every phase.** You approve before the next phase starts.
- **Page-by-page review.** For each page, I'll share a screenshot or mock-up before building so you can shape it.
- **Nothing gets deleted.** Features removed from a screen stay in the code until we decide where they belong.
- **Daily or every-other-day progress update**, in a format you choose.

---

## 6. Open questions for you

1. **Bottom navigation.** The spec defines five tabs (Home, Discover, Create, Wardrobe, Profile), with Create in the middle. In the meeting we agreed on a floating **Makeover** button on Home. Should the Create tab be **removed**, or **kept alongside** the button?
2. **Gemini.** In the meeting someone said the provider was "just for the demo." Do you want to keep Gemini for generation, or is a different provider planned?
3. **Intro after logout.** Should the marketing slides show again after a user logs out, or only on first install?
4. **Fashion idols.** Can we use real public figures (e.g. Winky D) in the idol list, or only idols who have joined the platform?
5. **Shopping Intelligence button.** Where on each post should it sit, and what should it say ("Order", "Get this look", "Forward")?
6. **Daily Dress Up.** What is its role now that Home is the feed?

---

## 7. Already done (current branch)

- The "Mine" timeline renamed to Home
- Tweet-style post card with user name and verified mark
- Preset quick-reply comments instead of free-text comments
- Gemini added for faster generation
- Home feeds renamed: **My Fashion Makeover** (was My Timeline), **My Daily Dress Up** (replaces Friends; fed from the Smart Wardrobe), **Community** (now includes friends, followers and public looks)
- Affirming and commenting merged into one action; the comment travels with the affirmation
- Followers: posts can be shared with Only me, Friends, Followers or Public
- Repost and Quote on shared looks
- Post actions spaced evenly under each look
- Every saved makeover is also saved to the Smart Wardrobe
