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
- **The cue's fields (Encounter's, from docs/director/pending/launch-anywhere/README.md):** on `launcher_open` and `launcher_link`: `source` (`sure`, `hard`, `answerable`), `k` the power in pips (1 to 5), `amount` the fresh kinds as a mask (1 up, 2 across, 4 down, 8 behind; a set bit is fresh), `dur` how long B stays lit (an opening's stagger; a link's 24 ticks, so a lit B cannot stick if its close never comes). `n`, the tick the window ends, is not read: the HUD has no tick, so `dur` and `launcher_close` end it. The names UI first proposed (`safe` or `text`, `power`, `fresh`) still read when the new ones are missing. A field that is missing draws a plain lit B: a solid ring, no pips, no rose. `amount` joined the hub's list of event fields (`_FIELDS`), which is what hands the sim's event object its mask.
- **`launcher_link` (2026-10-17):** a clean landing of his, with the ki, lights B for the link. It carries the same marks. It does **not** pulse the pad (an opening does; a link would pulse at every landing of a string), and **it does not take over an opening that is already lit**: the opening's own marks stay. `launcher_close` ends either.
- **The hint** shows once, at the first sure launcher for a human (not at a full gauge).
- **How to play** says "Hit him, then press launch when it lights. Aim with the stick." (the `launch_any` line; the "recharges" line is hidden).

## Files
`ui/core/ui_event_hub.gd`, `ui_fighter_model.gd`, `ui_stance.gd`; `ui/data/features.json`, `howto.json`, `terms.json`; `ui/hud/ui_hud.gd`; `ui/tools/hud_check.gd` (`_launch_anywhere_rules`, 21 checks); `ui/widgets/ui_hints.gd`, `ui_howto.gd`, `ui_plate.gd`, `ui_touch_controls.gd`.

## Gates (re-run 2026-10-17 with Encounter's fields and launcher_link: all five parks stacked, `hud_check` 4,789 checks, 0 failed, determinism plain and `--intro`, `hud_words_check`, `pane_check` passed; the original run follows) (scratch of HEAD + this patch, switch off): `hud_check` 4,733 checks, 0 failed; `determinism` plain and `--intro` passed; `hud_words_check` passed. All three parks stacked in order on a scratch HEAD: `hud_check` 4,758 checks, 0 failed; `determinism` plain and `--intro`, `hud_words_check` and `pane_check` passed.
