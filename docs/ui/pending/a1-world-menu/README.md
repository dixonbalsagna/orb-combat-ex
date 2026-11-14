# a1-world-menu: the first match across sessions, the planet in the seed line, the planet size row (UI & UX, 2026-11-14; park, not landed)

The EP's three items from World's parks (GW1b, GW1b, GW1c). Design: `docs/ui/menus-a1.md` sections 9 to 11 (in the patch).

- `world-menu.patch` (`patch -p1` / `git apply`; **apply after `a1-rail-default`, the end of the stack**; dry-run clean on the stack, and the whole stack equals the tree the gate ran on): `ui/core/ui_modes.gd`, `ui/widgets/ui_menu.gd`, `ui_pause.gd`, `ui_feedback.gd`, `ui/hud/ui_hud.gd`, `ui/data/terms.json`, `ui/data/feedback.json`, the regenerated pseudo-locale and `docs/ui/strings.md`, `ui/tools/hud_check.gd` (`_menus_world_rules`), `docs/ui/menus-a1.md`.
- `grant/main-gd-first-match-size-world.patch` (**Rendering's `render/core/main.gd`; needs a grant**; 8 changed lines): a delta on top of **World's `grant-rendering-main.patch` as Rendering merges it onto Tools' code-03, report-hook and my quit-and-fighters grant** (World's patch as it stands does not apply after those: its `_on_menu_started` hunk anchors on `var sd: int = fresh_seed()`; I merged its three hunks by hand to cut this delta, so the delta anchors on lines that World's grant adds). It drops `_played_one` (the HUD keeps the flag), reads `ui_hud.first_match_played()` in `planet_part`, sets the setup key `planetSize` from the menu's `planet_size`, and adds `"world": WorldDefault.describe(host.S)` to the report context. Needs World's grants first (it names `WorldDefault`).

## 1. The first match across sessions (GW1b)
`UiHud.first_match_played()` reads the settings store (`UiPrefs`, key `played_match`); the HUD sets it right after the host is told of a match (Start and Play again), so the host still reads "no match yet" while it makes the first one. A second session with the same store knows. The first match ever is the fixed planet and later quick matches draw.

## 2. The seed line (GW1b)
The report context's `world` (World's `describe(S)`) shows as "Planet 7" in the pause menu's and the match-over card's detail card, in the saved match record (`world`) and in the report ("World: Planet 7, generator 3, 4800 columns around"; "The hand-made arena"; "unknown" where the host gave none). Nothing is drawn on the fighting HUD.

## 3. The planet size row (GW1c)
A "Planet size" cycle row after the fighters in "Set up the match", from World's `data/biomes/sizes.json` (the offered ones in its order: Tiny, Small, Medium, Big, Huge), Medium the default, kept with the menu choices and shown in the "This match" card. No sizes file means no row. The setup page now has ten rows; its header sits higher so it still fits 1280 by 720.

## Words for Orb to see (all in the patch)
"Planet size", "Tiny", "Small", "Medium", "Big", "Huge"; "Planet {planet}", "The hand-made arena", "Planet {planet}, generator {gen}, {cols} columns around"; and the report label "World".

## Tests
`_menus_world_rules`: the world line (short, full, arena, none) and the report line; no size row without sizes, with five it follows the computer's fighter, default medium, an unknown size becomes medium, the steps wrap, the words; the setup with the size row and the version line fits at 1280x720, 1280x800, 1920x1080 and 1366x768 for one and two players; in the HUD Right on the size row goes medium to big and changes nothing else, Start sends the size, the host sees no match played while it reads the flag and the flag is set after, a second HUD with the same store knows, the saved size comes back, the pause card and the match-over card say which planet, the saved record carries it, and a host that gives none shows no line.
