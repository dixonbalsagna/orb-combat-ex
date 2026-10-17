# The boons screen and the lives line (parked, UI, 2026-10-17)

Game Design's reshaped run (`docs/design/run-mode.md` sections 1.4 and 4.1, rulings of 2026-10-17): one boon of three after each won fight, **a temptation's offer with a Walk on choice that gains a life**, lives instead of chances. Built in scratch behind `features.json` `run_mode` (off). **Not applied.** Apply after `launch-anywhere`, `run-mode` and `hud-cache`:

```bash
patch -p1 --dry-run < docs/ui/pending/run-boons/run-boons.patch
patch -p1 < docs/ui/pending/run-boons/run-boons.patch
```

- **`ui/widgets/ui_run.gd`:** `boons_plan`, `boons_hit`, `boons_sig`, `boons_draw`; a shape for each kind of boon; the temptation's card shows its record's `line` and never `gives`; Take this, and Walk on only when the record says `walk_on`; full, compact (the Walk on button says "Walk on, gain a life") and row layouts; the results' "Lives used: n" (`lives_used` in the record; `chances` still works).
- **`ui/hud/ui_hud.gd`:** `show_run_boons(rec)`, signals `run_boon_chosen(index)` and `run_boon_walked_on()`; keyboard, pad and touch as for the offers (left from Take this reaches Walk on).
- **`ui/data/terms.json`:** 13 strings; the Proving ground's reward reads "Two boons, one after the other", the Crossing's "A rest: every part of you is healed".
- **`ui/tools/hud_check.gd`:** `_run_boon_rules` (10 checks).
- **The record:** `boons {pick, of, lives, tier, walk_on, boons: [{kind: form|ability|lifeline|rest|temptation, name, gives, line}]}`.

Gates (scratch of HEAD with the four run and cache parks stacked): see the report; `hud_check` 27 partial checks and the full run are green.
