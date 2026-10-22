# No pointer chip during a beam struggle, and none over a body (parked)

Apply from the repo root after `minimal-hud-hints`: `patch -p1 < docs/ui/pending/chips-off-bodies/chips-off-bodies.patch` (a dry run is clean).

1. **Pointer, incoming and off-screen chips are down during a beam struggle and for 0.3 s after it** (Camera's brink framing holds both fighters).
2. **With `minimal_hud` on, no chip is drawn over a body**: `UiSplit.chips_off_bodies` drops any chip whose rectangle meets a fighter's body box (the anchor's torso, one drawn height by about one wide), whatever the anchor's `visible` flag says (it reads false beside him in the one view) and including a launched body. UI draws no trail line; the one line-like thing on a chip is the dashed edge of an estimated arrival.
3. **The heavy's full-charge hint is keyed on the charge's two states**: launcher resting, "Full! Let go to knock him back." (Orb's); launcher ready, `prompt.hint_full_launch`, which shows once Game Design and Narrative's line exists in `ui/data/terms.json`.

Files: `ui/hud/ui_hud.gd`, `ui/widgets/ui_split.gd`, `ui/tools/hud_check.gd` (2 checks). Gates on main with minimal-hud-on and minimal-hud-hints and this: `hud_check` 4,773 checks, 0 failed; determinism plain and `--intro`, `hud_words_check` and `pane_check` passed.
