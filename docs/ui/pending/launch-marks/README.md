# Launch marks and the beam struggle's tug of war (parked, UI, 2026-10-16)

Owner: UI & UX. **APPLIED to the tree on 2026-10-16 (the EP's go, Game Design's ruling 8c8368b3) with `launch_marks` ON; kept here as the record.** Built and gated first in a scratch copy of main 0ca6f670. One patch, all inside `ui/` (my own paths), so the EP may apply it at any time:

```bash
cd <repo root>
patch -p1 --dry-run < docs/ui/pending/launch-marks/launch-marks.patch   # reads every file, writes nothing
patch -p1 < docs/ui/pending/launch-marks/launch-marks.patch
```

Base: the patch expects `ui/` as in the tree with the camera_launch_follow "hold" change (options.json, settings.json, hud_check.gd) already in it, which is applied directly.

## What is in it

| File | Change |
| :-- | :-- |
| `ui/data/features.json` | `launch_marks` (**false**): the flag, ready to flip |
| `ui/core/ui_stance.gd` | `launch_marks()`: the flag, or `three_strengths` (which includes them) |
| `ui/core/ui_fighter_model.gd` | `gauge_full` (derived by the hub; the HUD never writes the sim) |
| `ui/core/ui_event_hub.gd` | the gauge derivation; `beam_struggle`, `beam_pulse`, `beam_surge`, `beam_stray`, `beam_end` into `tug`; `set_clash_mid`; the once-only hint |
| `ui/core/ui_sim_bridge.gd` | `clash_mid(S)`: reads `Clash.mid` (-1 until Encounter's park is applied), read only |
| `ui/widgets/ui_plate.gd` | the run, the launcher chip and OPEN under `launch_marks()`; a full gauge is a heavier steady edge and a filled caret; the rest's ring (30 s, one step a second, no number) |
| `ui/widgets/ui_hints.gd` | B is lit and its row says LAUNCH when the rival's gauge is full and the launcher is ready (`lit_b`) |
| `ui/widgets/ui_tug.gd` (+ `.uid`) | the tug of war: track, comeback quarters in each ring colour, the meeting point, the beat ring, surge and stray marks |
| `ui/hud/ui_hud.gd` | the gates, `haptic_requested(slot, kind)` ("launch_open"), the hint's trigger, the tug layer |
| `ui/data/terms.json` | `prompt.launch_hint`: "Keep hitting, then press the lit button to launch him." (a placeholder for Narrative to word) |
| `ui/tools/hud_check.gd` | `_launch_marks_rules` (flag off and on, the gauge, B, the word, the hint once, the pad's pulse, the rest's step, Control hints off) and `_tug_rules` (the five cues, the point, the plan at five sizes, the beat's steps, the layer in the HUD) |

## What the flag does today, and when to flip it

- **Flag off (as shipped):** nothing changes. `hud_check` 4694 checks, 0 failed with the patch and the flag off; determinism plain and `--intro`, `hud_words_check`, `pane_check` pass.
- **Flag on, with today's cues:** the plate's LAUNCH or RESTING chip with the rest's ring, OPEN after a miss, the lit B (already lit by `launcher_open`), the pad's pulse when a launch opens for a human. **No gauge and no hint yet:** they need the `blow` cue's `run` and `run_to` (Encounter's).
- **Flag on, with Encounter's cues:** the four pips fill on the rival, at four B lights with LAUNCH, and the hint shows once.
- **The tug of war needs no flag:** it draws only while `beam_struggle` is on (Encounter's park). Until that park is applied there are no such cues and nothing draws. `Clash.mid` is read as -1 until it exists; with the cues but no field the point stays in the middle.

## For the host

`UiHud.haptic_requested(slot, kind)`: play a short pulse on that player's pad for `"launch_open"`. Controls' or main.gd's one line, as for `form_prompt_shown`.
