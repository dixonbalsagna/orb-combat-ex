# The launch marks with no rest (parked, UI, 2026-10-17)

Game Design's thirteenth round (`docs/design/launch-anywhere.md`) and `docs/ui/launch-marks-no-rest.md`, built in scratch behind `features.json` `launch_anywhere` (**off**), ready for Encounter's launcher window. **Not applied.** It also carries Orb's hint C ("He's open! Press B and send him flying!"), so `docs/ui/pending/hint-c/` is superseded by it.

**Apply order for the three parks of this round: `launch-anywhere`, then `run-mode`, then `hud-cache`** (each patch is made against the tree the one before leaves; each is a `patch -p1` from the repo root, and a dry run is clean).

```bash
patch -p1 --dry-run < docs/ui/pending/launch-anywhere/launch-anywhere.patch
patch -p1 < docs/ui/pending/launch-anywhere/launch-anywhere.patch
```

## What it does with the switch on
- **No rest marks, whatever the director sends:** the plate's LAUNCH / RECHARGING chip, its ring, the legend's note and Full touch's triangle are not drawn (`UiStance.rest_marks()` is false), and the rival's run of pips is gone.
- **The lit B carries the marks** for as long as `launcher_open` is on: the word LAUNCH beside it; **a solid ring when the launch is sure, a broken ring (four arcs) when it can be answered**; **pips for the power (1 to 5)** after the word; **a rose of four small arrows** (up, across, down, behind), **filled for a fresh kind of send and hollow for a familiar one** (drawn only when the cue says). Same marks on Full touch's B.
- **The cue's fields (proposed names for Encounter):** on `launcher_open`: `text` or `safe` (`sure`, `hard`, `answerable`), `power` or `k` (1 to 5), `fresh` (a mask: bit 0 up, 1 across, 2 down, 3 behind; a set bit is fresh), `dur` (ticks the window lasts, so a lit B cannot stick if its close never comes). A field that is missing draws a plain lit B: a solid ring, no pips, no rose.
- **The hint** shows once, at the first sure launcher for a human (not at a full gauge).
- **How to play** says "Hit him, then press launch when it lights. Aim with the stick." (the `launch_any` line; the "recharges" line is hidden).

## Files
`ui/core/ui_event_hub.gd`, `ui_fighter_model.gd`, `ui_stance.gd`; `ui/data/features.json`, `howto.json`, `terms.json`; `ui/hud/ui_hud.gd`; `ui/tools/hud_check.gd` (`_launch_anywhere_rules`, 14 checks); `ui/widgets/ui_hints.gd`, `ui_howto.gd`, `ui_plate.gd`, `ui_touch_controls.gd`.

## Gates (scratch of HEAD + this patch, switch off): `hud_check` 4,733 checks, 0 failed; `determinism` plain and `--intro` passed; `hud_words_check` passed. All three parks stacked in order on a scratch HEAD: `hud_check` 4,758 checks, 0 failed; `determinism` plain and `--intro`, `hud_words_check` and `pane_check` passed.
