# Steam readiness: the store-page and marketing half

Owner: Community and Marketing. 2026-10-27. Private draft. Legal writes the legal half separately (`docs/legal/`). Plan context: `go-to-market-plan.md` (stages), `store-copy-draft.md` (copy, art plan, claims).
Valve facts were read from Steamworks docs on 2026-10-27 and are cited by page name. **Unconfirmed** means I could not confirm it from a Valve page today; check Steamworks before acting. No dates or figures here beyond what those pages state.

Status: **have** (exists today), **need** (not made yet), **Orb's call**.

## 1. What the store page needs

| Item | Status | Owner | Source / note |
|---|---|---|---|
| Header capsule 920x430, small capsule 462x174, main capsule 1232x706, vertical capsule 748x896 (all required) | need | Art, with Marketing | Valve "Graphical assets" page. Made from one real capture plus a plain wordmark in a licensed font (`store-copy-draft.md` C) |
| Wordmark font | Orb's call | Orb | Licensed font, one row in `licence-register.md` (Legal) |
| Page background 1438x810 | optional | Art | Valve page marks it optional |
| Screenshots: at least 5, at least 1920x1080, 16:9, gameplay only (no concept art, no marketing text) | need | Marketing, from real captures | Valve page. At least 4 must be marked suitable for all ages: Legal's call, since the game shows violence |
| Trailer: .mp4/.mov/.wmv, H.264 preferred, up to 1920x1080, 30 or 60 fps, 5,000+ Kbps, 16:9. Valve recommends the first trailer be mostly gameplay | need | Marketing, Audio for the track | Valve "Trailers" page. A trailer is required for release; whether one is required for Coming Soon is **unconfirmed**. Real captures only (`store-copy-draft.md` C) |
| Short and long description | have (skeleton) | Marketing | `store-copy-draft.md` A2. Written to be true of the build on the day; Legal reviews |
| Tags | have (draft list) | Marketing | `store-copy-draft.md` B. Tags follow the game as it is at the time, not the plan |
| Library assets (hero, logo) | need | Art | Sizes **unconfirmed**; Valve lists them on a separate page |

**Orb's rule on character art.** Every screenshot, capsule and trailer frame shows the build as it ships on the day. No in-progress character art, no concept art as a screenshot (Valve forbids it too), and no frame with the placeholder names or the working title. Until the fighters are final, the page waits (see section 5).

## 2. Coming Soon, wishlists and when to open

| Item | Status | Owner | Source / note |
|---|---|---|---|
| Title cleared (OrbCombat clash) before any store page | Orb's call, Legal | Orb, Legal | CLAUDE.md; Legal's go-to-market |
| Fee: $100 per product | Orb's call | Orb | Valve "Onboarding" page. Paying starts the wait below |
| Identity, tax and bank details | need | Orb | Onboarding page: tax verification can take up to 30 days. Free to start early. Legal's half covers the rules |
| Page review: 1-5 days (Onboarding) or 3-5 business days (Releasing); submit 7+ days before you want it live | fact | Marketing | Valve "Releasing" page |
| Coming Soon visible at least 2 weeks before release | fact | Marketing | Valve "Releasing" page |
| 21 days between paying the fee and release | fact | Marketing | Valve "Onboarding" page. **This corrects my plan, which said 30; fixed in `go-to-market-plan.md`.** Legal's text says 30: Legal to reconcile |
| When to open the page | Orb's call | Orb | My recommendation: open it as soon as the title is cleared and the real assets exist, because wishlists only start counting once it is public. Not before: a thin page with two fighters teaches people to ignore it. The plan's Stage 2 gate (four fighters, music, controller) stands unless Orb overrides it |

## 3. Demo, Next Fest and the browser build

- **The browser build cannot be the Steam demo.** Valve treats a demo as its own app with its own build, depots and checklist (Valve "Demos" page). It needs a Windows and Linux build first (Performance).
- **The browser build can be the funnel.** Plan: a "Wishlist on Steam" button on the site once the Steam page is public, and a "Play free in your browser" line on the Steam page. Whether Valve limits pointing to play outside Steam is **unconfirmed**; Legal reads it with the store text. Owner: Marketing for the words, Tools for the site button, Legal for review.
- **Wishlist notification:** a demo release may notify wishlisters once, within 14 days of its first release (Demos page).
- **Next Fest:** entry rules are **unconfirmed today** (the Demos page does not cover them). My earlier read, from the Next Fest page on 2026-10-05, was: public store page and a live demo. The next two dates in the plan are Orb's call after the stage gates; the plan lists them in Stage 3.

## 4. Remote Play Together, Steam Deck, AI disclosure

| Item | Status | Owner | Source / note |
|---|---|---|---|
| Remote Play Together as a selling point | Orb's call | Orb, Legal | One checkbox on the store page. Games listed as local multiplayer get it automatically; only the host owns the game (Valve "Remote Play"). It needs the Steam build; the browser build has no Remote Play. **We have not tried it**, and fighting games are latency-sensitive. Claim only "play with a friend through Steam Remote Play Together" after someone has played it, never "online multiplayer" |
| Steam Deck | need | Performance, Controls | Valve sets Verified, Playable or Unsupported after its own review; developers cannot choose a tag (Valve "Steam Deck compatibility"). Criteria include Deck controls with full content in the default layout, controller-friendly text entry, smallest text at least 9 px at 1280x800, and 30 fps at 800p. We claim nothing until Valve awards a badge (C22). Reviews need a build review first |
| AI disclosure in the store copy | have (wording) | Marketing, Legal | Orb's rule: the statement goes in the long description in full and in the content survey, covering the capsule art and trailer as well as the game (`go-to-market-plan.md` section 4, `store-copy-draft.md` A2). Steam's survey exempts coding aids, and we disclose them anyway. Whether Steam's survey wording changed again since January 2026 is **unconfirmed** |

## 5. A realistic order of steps

1. Orb: title, licence shape, who sells, fee (the open questions in `go-to-market-plan.md` section 14).
2. Legal: title clear; store-copy screen; asset-origin rows ready.
3. Orb starts identity, tax and bank setup (free, slow, and can run alongside the rest).
4. Performance and Controls: Windows and Linux build, controller play, a Steam Deck check.
5. Game side: the fighters, music and look the page will show.
6. Marketing and Art: real captures, screenshots, capsules, trailer. Legal reviews each asset.
7. Orb pays the fee (the 21 days start), Marketing fills the store page, Legal reads it, submit for review at least 7 days ahead.
8. Coming Soon goes public. Site gets "Wishlist on Steam". Devlog posts begin.
9. Demo (separate app) and, later, a Next Fest.
10. Mostly final build to review, then Orb clicks Release.
