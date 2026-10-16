# The beam struggle's legend (parked, UI, 2026-10-16)

Controls' paper `docs/controls/struggle-input.md`: the let-go is **A** on Arena, the keyboards and Full touch, and **Guard** on Simple (pad and touch); X, Y and B surge alike on the beat; a hold, a second press or a press off the beat is a stray; on touch teach a **tap**, not a swipe. Built and gated in a scratch copy of HEAD plus the tree; **not applied**, because it reads the tug, which waits for Encounter's cues.

```bash
cd <repo root>
patch -p1 --dry-run < docs/ui/pending/tug-legend/tug-legend.patch   # reads every file, writes nothing
patch -p1 < docs/ui/pending/tug-legend/tug-legend.patch
```

| File | Change |
| :-- | :-- |
| `ui/core/ui_fighter_model.gd` | `in_struggle`: a human in a beam struggle (derived from the tug each frame; the HUD writes nothing in the sim) |
| `ui/widgets/ui_hints.gd` | while it is set the legend's rows say: A "LET GO" (it is greyed "not yet" otherwise, so the let-go overrides it), X, Y and B "on the beat"; on Simple, Guard "LET GO" and Attack "on the beat". Redraws on the change |
| `ui/widgets/ui_tug.gd` | two caption lines under the meeting point for a touch screen (it has no legend): Simple "Tap Attack on the beat" and "Tap Guard to let go"; Full touch "Tap on the beat" and "Tap Action to let go". Never the word swipe |
| `ui/hud/ui_hud.gd` | sets `in_struggle`, builds the captions |
| `ui/data/terms.json` | six lines (placeholder wording for Narrative) |
| `ui/tools/hud_check.gd` | `_tug_legend_rules` (14 checks): arena and the three keyboard layouts, Simple, the touch captions, no swipe, none off a touch screen, cleared at the end |

Gates on the scratch copy (patch on top): `hud_check` 4730 checks, 0 failed.
