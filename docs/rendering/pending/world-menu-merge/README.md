# World's menu planet and UI's delta, merged onto the A1 stack (for GW1b)

Rendering, 2026-11-14, at the EP's word. `world_menu_merged.diff` (sha1 78abe08e, 50 lines, `render/core/main.gd` only) is the merge of:
- **World's `docs/world/pending/a-world-01/grant-rendering-main.patch`** (sha1 e152543e816c): the menu seed and the round planet in `planet_part`, A-WORLD-01;
- **UI's delta `docs/ui/pending/a1-world-menu/grant/main-gd-first-match-size-world.patch`** (sha1 a96d8a402dc8): no `_played_one`; the first match ever read from the HUD (`ui_hud.first_match_played()`, kept across sessions); the size row's `planetSize`; the world in the report's context (`WorldDefault.describe`).

## Why a merge

World's patch as filed doesn't apply on the stack. Its `_on_menu_started` hunk anchors on the lines that UI's quit-and-fighters grant separates with its `_slots` line. I applied World's three hunks by hand with World's own text, then UI's delta. Nothing else is changed.

## The stack it's cut on

`render/core/main.gd` of main 42c38d8b with, in order:
1. Camera's `a-camera-01.patch`;
2. Tools' A-CODE-03 (`planet-entry-and-probe.patch`, `report-hook.patch`);
3. my `look-recut/` diffs (globe ground and crater look defaults);
4. UI's `pause-clock.patch` and `rail-default.patch`;
5. UI's `a1-start-flow/grant/main-gd-quit-and-fighters.patch` (sha1 b233392bf1f5).

## It needs, in the same landing

- World's `a-world-01.diff` (`WorldDefault`) and Simulation's grant for it (`grant-simulation-sim.patch`);
- UI's `a1-world-menu/world-menu.patch` (`UiHud.first_match_played`);
- UI's `a1-start-flow/start-flow.patch` (the `quit_requested` signal the quit grant connects).

## Review

- **The globe ground's setup (`RenderTileGround.setup_of`)** adds planet 7, touch 3, gen 3 when a setup names no planet. World's default is the same planet (`data/biomes/world.json` fixed: 7, 3, 3), and `WorldDefault.apply` leaves a setup that names a planet as it is, so the two agree today. If the data's fixed planet ever changes, `setup_of` should take it from `WorldDefault`: mine, a small change, noted for GW1b.
- **The quick-match draw** (planets 7, 12, 3, 13 and 17): the tile ground has only been looked at on planet 7. A still of each of the other four is owed before GW1b lands (the look gate).
- **`planetSize`** goes into the setup only when the menu has a size row, and UI shows the row only with World's `sizes.json` (GW1c), so it's inert in GW1b.

## Proof

- It applies on the stack above (`git apply`).
- **On the full GW1b stack** (`docs/rendering/runs/4f06e7a3/world-menu-merge.txt`):
  - the stack is main 4f06e7a3 + Camera + A-CODE-03 + `look-recut/` + UI's pause-clock, start-flow and its grant, replay-words, menu-fixes, screen-sweep, rail-default and world-menu + World's A-WORLD-01 new files and Simulation's grant for it + this merge;
  - it imports clean, and `golden.json` is byte-identical (the data's world mode is still the arena until GW1a's switches flip it);
  - the five ground checks pass, World's `world_default_check` fails 0, UI's `hud_check` passes 8,546 checks with 0 failed, and the render gates pass 20 of 20.
  - The run was stopped once for the GW1a foot-slice gate and finished on the same tree; the record says which parts came from which.
