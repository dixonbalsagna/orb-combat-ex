# The rewritten holding page: screen

Owner: Legal and IP Compliance. 2026-10-06. Screens the EP's draft (`site-preview/index.html`, its `img/` files) against the promotion hold, `go-to-market.md` section 7, `never-use-words.md`, `photosensitivity-note.md`. Orb's request is in `docs/ep/vision.md` (last section). A screen, not legal advice.

## 1. The hold
**It is promotion in substance** (ad copy and polished images), so it is under my hold, **but it is Orb's call as owner, and with the limits you name it is acceptable:** `noindex`, no social cards, no description or tags, linked from nowhere by us (no posts, no communities, no creator messages, no Steam or itch.io page), the working title shown as "(working title)". What I would tell Orb: **yes to this one page; no to anything wider until the title is decided.** The real risk is the title: the OrbCombat project is live, and every public asset that carries "Orb Combat EX" attaches the name to our visual identity. On one unindexed page that added risk is small and bounded; it grows with every post or link. The working title as shown now is acceptable. Orb should decide the title soon (write to the OrbCombat author, or change it), because this page and the README now carry marketing words with the working title.

## 2. The words
| Line | Verdict |
| :-- | :-- |
| Title, "(working title)", tagline "A real-time anime brawler where the whole planet is the arena." | **Pass.** "Anime brawler" names the genre; no franchise word |
| The status box | **Pass.** Keep it first. After the recount, "found scenes at or near the recommended limit of three flashes a second" if nothing is over 3 (addendum 4) |
| **"Fights that write themselves"** | **Change.** Next to an AI statement it reads as AI writing the fight live, which is untrue. Use "Combos that build as you fight" or "No combo lists to memorise", and add: **"The fight director is ordinary game code, not an AI model."** |
| "...a procedural fight director threads your lights, mediums and heavies into combos on the fly, shaped by where you are, what you chose and how the fight is going." | **Soften to design:** "is designed to thread ... " The three-strength combat is not in a live build. "No two exchanges are meant to play the same way twice" is fine ("are meant to") |
| "Planned: flurries you can steer across the sky, charged heavies that shrug off jabs, launchers you aim with the stick, point-blank energy blasts, and zips that carry you through a rival's guard..." | **Pass with one change:** "through a rival's guard" to **"past a rival's guard"**. A zip passes beside or over a body, never through it (m04). Every item is marked Planned: good |
| "The planet is the arena ... city, desert, ocean, mountains. Planned: a sky that turns from noon to night" | **Pass** (true; the sky is marked Planned) |
| "Power has weight. Beams carve trenches. Towers crack, shed their glass and come down a stage at a time. The world keeps every scar until the match ends." | **Pass** (cleared claims C5 and C6, true of the build when it returns) |
| Captions | **Pass**, except "Every building here can be broken" becomes **"Buildings here break in stages."** "Heavy flurry, animation study ... Work in progress, on a test stage" and "Concept art for the dynamic sky" are honest |
| Small print: work in progress, Planned may change | **Pass** |
| **The AI statement** | **Move it up.** It sits in the small print; Orb's rule is the first lines. Add a visible line under the tagline: **"A one-person project: Orb directs it and builds it with AI tools."** and keep the full statement and the privacy line at the foot. No claim reads as human-made |
| No comparison, no endorsement, no franchise word | **None found** |

## 3. The assets
| Asset | Verdict |
| :-- | :-- |
| `er-blast-land.jpg` (a point-blank blast: hollow ring, crossed lines, spill) | **Pass.** No title, no placeholder name (a "P1" bubble and the red markers are UI). Alt text: describe it |
| `br-double.jpg` (the double hit) | **Pass** (the contact marks cleared under k04) |
| `bstage-towers.png` (downtown, a cracked and a collapsed tower, civilians) | **Pass.** No text, no names; the civilians are small stylised figures (the rating question stays with Orb) |
| The sky strip (`sky.png`, from `sky-stills.svg`) | **Pass after a crop.** The image still carries the sheet's header ("The dynamic sky: the two fighters over each key ... Working labels", "the aura ring is an assumption") and a scroll bar: crop to the three panels only. The caption already says concept art, which is right: these are concept designs, not the game's current bodies |
| `bmash.gif` (heavy flurry, two figures on a flat dark stage, no effects) | **Pass on content** (no title, no names, no effects). **Not as an inline GIF:** see 4 |
| `zip.jpg` (in `img/`, not used by the page) | **Not reviewed.** Send it if you want to use it |
All stand under the originality marks I screened (no aura-with-scream, no flame, no franchise pose). The captions say what each is.

## 4. The clip and flashing
- **No autoplay and no loop.** A GIF cannot be paused, so **do not inline the GIF.** Use a `<video controls preload="none" poster="...">` (an MP4 or WebM encoded from the clip) with **no autoplay and no loop**, which also needs no script. It plays once, on a click, and the viewer can pause.
- Show the **poster still only when the visitor's setting is reduced motion** (CSS `prefers-reduced-motion`): no play control.
- **The encoded file as served** (its size and frame rate, not the source) goes through Tools' analyser under the combined rule (primary at most 2.5, no sensitivity run above 3, whole-screen dips capped) and **passes** before it ships. Record the result with the hashes.
- **The page itself has no animation** apart from the clip: no CSS transitions, carousels or pulsing elements.
- A caption that does not say "no flashing" or "safe" (the same wording rules as the notice).
- **Nothing else changes** until these are met; I will look at the revised page and the clip's analyser result before it goes live.
