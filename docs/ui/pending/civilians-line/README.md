# The overlay HUD's CIVILIANS LOST line (parked, not committed; Legal RL-257 and lint row c11; the EP's brief of 2026-11-09)

World found that `render/core/hud.gd:66` (`HudView`, the overlay the game draws from `render/core/main.gd`) still drew **CIVILIANS LOST n / total**, reading `S.world.casualties` and `pop0`. UI's damage-chip park cleaned `ui/` only, so this one was missed: the file is Rendering's, not UI's.

**Two patches, one commit (the row guards the fix, so the UI one fails without the grant):**
- `civilians-line-grant.patch` (sha1 39da43104829; **a grant**: `render/core/hud.gd`): the line is removed, and the STRUCTURES LOST and CRATERS line moves up (y 40 to 24) into its place. Nothing else in the file changes.
- `civilians-line-ui.patch` (sha1 e298d0475537; `ui/tools/hud_check.gd`): one new row in `_retired_words_rules` that scans `res://render/core/hud.gd` for the retired words (civilians lost, casualties, toll, kill count, death count, body count) so the line cannot come back.

Cut on HEAD d6e28824; both apply clean. Apply: `git -c core.autocrlf=false apply` each, from the repo root.

**What was run (and what was not):** the new row alone **fails without the grant** (it names "CIVILIANS LOST" and "casualt") and **passes with it** (48 checks, 0 failed); Rendering's `render/tools/hud_words_check.gd` (the overlay's words check) passes on the fixed file. Logs in `docs/ui/runs/d6e28824/`. I did **not** run the full hud_check or the render gates for this one-line change (the EP's pace rule); the row is the only hud_check change.

**Other places that still carry the word, not mine and not changed (listed for World, Simulation and Rendering):**
- `sim/core/damage.gd:150` (and its JS oracle `sim/core/damage.js:33`): the KO feed line's detail reads "Casualties <n>, structures lost <n>". It goes to the sim's feed (a debug feed on the web demo, and anything that shows feed text); RL-257 (2) says no people-lost counter in the sim's outputs.
- `render/core/sky_drive.gd:454` reads `S.world.casualties` for the sky's mood (presentation, not words; it falls away when the sim's scalar is removed: Game Design, World and Simulation).
