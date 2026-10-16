# The civilian bar: no running count in the fight (UI, 2026-10-16)

Owner: UI & UX. Orb's homework 5 left the civilian count to us; the EP's decision: **no running number during the fight, a small steady bar for the share of the city's civilians lost, and the exact count on the results screen.** **Applied to the tree on 2026-10-16 with `civilian_bar` ON** (the EP's go; the card only for menu sessions and "Buildings" accepted). The park is kept in `docs/ui/pending/civilian-bar/` as the record. Stills with a toll above zero (134 of 425, 9 buildings, 14 craters): `img/civilian-bar-1280.png`, `img/civilian-bar-844.png`.

## What the player sees

- **During the fight:** the top chip says CIVILIANS LOST and, beside the words, a thin outlined bar filled to the share lost, with marks at a quarter, a half and three quarters. No number. The bar is a shape and the fill is ink, never a hue (colour-vision presets change nothing). The second line (STRUCTURES LOST, CRATERS) stays as it is.
- **Steady:** the bar steps in whole percents (at most a hundred steps in a match, never a creep) and **keeps one opacity**: it does not dim at rest or brighten when it grows, so nothing flashes or blinks when the toll rises. The structures and craters line stops brightening too. A change inside the same percent redraws nothing.
- **One view and a split:** the chip keeps its rectangle (`UiLayout.toll`, top centre on a landscape screen, a full row in portrait), so the divider, the ring map and the strip sit where they did. On a phone the words and the bar share the one line the chip has; the bar is at least 50 px at every size tested.
- **The results screen** (the match-over card, three seconds after the KO, for a session that came through the menu): under MATCH OVER, three plain lines: "Civilians lost: 123 of 425", "Buildings lost: 12", "Craters: 40". The card widens or wraps for them and every button stays a 48 dp target inside it.
- **The link to anguish and menace is untouched:** the HUD only reads the world's counts (it never writes the sim) and the meters are the sim's; the test shows the toll events change no fighter's meter with the switch on or off.

## What it costs and what it leaves

- Files: `ui/widgets/ui_center.gd` (the chip), `ui/widgets/ui_pause.gd` (the facts), `ui/hud/ui_hud.gd` (the chip's signature, `over_facts`), `ui/data/terms.json` (three lines), `ui/data/features.json` (the switch), `ui/tools/hud_check.gd` (`_civilian_bar_rules`, 14 checks).
- **Public pictures:** the demo's `--public` pin keeps the toll at zero, so the bar is empty there too. The match-over card shows real counts in a live match; the rule is about pictures and clips.
- **Sessions that did not come through the menu** get no match-over card (as today), so no counts: if Orb wants the counts there too, the card can open for every session (one condition in the HUD).
- The word "Civilians" stays (it is the word Orb used). "Structures" became "Buildings" on the card.
- Stills: from a scratch export of the HUD demo with `?toll=134:425:9:14` (a flag added to `ui/demo/hud_demo.gd`).

## To apply

`patch -p1 < docs/ui/pending/civilian-bar/civilian-bar.patch` from the repo root (a dry run is clean), then set `civilian_bar` to true in `ui/data/features.json`. Gates on the scratch copy of HEAD with the switch off: `hud_check` 4715 checks, 0 failed; determinism plain and `--intro --seeds=2 --ticks=900`, `hud_words_check` and `pane_check` pass.
