# howto-licence (UI & UX, 2026-11-25): RL-265's licence line on How to play

Parked, not landed. The line replaces "License: not chosen yet. All rights reserved for now." on the "License and privacy" page.

## The words (Legal's, verbatim; Orb sees them before they go in, docs/legal/permission-page.md)

> License: all rights are reserved during the Alpha. See "What you may do with Orb Combat EX". Whether the code is made public is decided at Beta.

Orb's yes is on record ("GO", `docs/ep/vision.md`, decision 5), which is what RL-265 waits for.

## The layout change the longer line needs

The line is about two lines longer, and the page stopped fitting its card at 1560x720 (density 2) and 360x640. Both fit again with:

- the sentence "The full license texts, and the licenses of the other parts built into the engine, are on the next page." moved to the top of the right-hand column (it was the last item on the left);
- on a one-column card laid out tight (today 360x640 only), that sentence is left out. It points to the next page and is not a notice; the notices and the licence texts are all still there.

## Files

`howto-licence.patch` (sha1 79bb451cf2df, 6 files): `ui/data/howto.json`, `ui/widgets/ui_howto.gd`, `ui/tools/hud_check.gd`, the pseudo-locale `howto.json`, `docs/ui/strings.md`, `docs/ui/hud-spec.md`. No grant.

## Order

Applies after the GW1c stack (`docs/ep/reviews/GW1c-stack.txt`) and `pad-recommended`. On main alone, every file applies except `docs/ui/strings.md`, which is generated (`python ui/tools/strings_inventory.py`); hud_check was not run that way.

## Proof (data folder pointed away from Orb's)

- Full hud_check on the stack, pad-recommended and this patch: 8665 checks, 0 failed (`runs/hud-check-full.txt`).
- About rules alone: 62 checks, 0 failed. With the old line left in the data, the two word-for-word rows fail.
- `node tools/validate.js` 0 errors; `node tools/content-screen.mjs` 0 failing hits.
- No still taken (a words-and-layout change on a text page; the web export was left out to keep cost low).

## Not in this patch

- **The page the line names is not in the build.** "What you may do with Orb Combat EX" is `docs/legal/permission-page.md`; neither the game nor the desktop package (`README.txt`, `NOTICES.txt`, `build_info.json`) carries it. It needs to be in the testers' folder, or on a How to play page, before the line is true.
- The old words are also in `tools/build-site.mjs` line 303 (Tools) and `README.md` line 7 (EP).
