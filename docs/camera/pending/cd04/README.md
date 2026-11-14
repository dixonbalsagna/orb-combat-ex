# Parked: the audit's CD-04, camera half (cd04)

Camera, 2026-11-07. CD-04 asks for two things:
1. SCROLL_MAX_REDUCED back at 0.03, or a higher value justified with a saved reading.
2. The hard cuts that change most of the screen asking the flash register.

This park does both. **Paused at the EP's word (pacing) before the cut-step table and the reduced-mode analyser reading.** Those come after Sunday's play-test, so CD-04's "Done when" (3), the next pin reading 3 or less in reduced mode, isn't shown yet.

**Apply on main** (cut on d41ce393; `git apply --check --cached` passes on e9216c1a): `git -c core.autocrlf=false apply cd04.patch` (sha1 cb4d7363).
- Files: `render/camera/split_rig.gd`, `render/camera/split_view.gd`, `render/camera/camera_params.gd` and a new `render/camera/tests/cut_register_check.gd`, all mine.
- The two-fighter ratchet is unchanged (365).
- It works with or without VFX's shared-register park (`docs/vfx/pending/shared-register`). It uses `flashes.ask_cut` when the register has it, else the register's plain `ask`, weighed the same way. Either can land first.

Saved outputs (CD-22): `docs/camera/runs/d41ce393/cd-04/`.

## What it does

- **SCROLL_MAX_REDUCED is 0.03 again.** It had been 0.045 since 2026-10-22, "while the flash work is paused". Under reduced flashing and the motion setting, the scroll governor holds the scenery's crossing to 0.03 of the width a tick.
- **Every hard cut asks first** (`_cut_gate`).
  - The area is the share of the screen the cut changes: the whole screen in one view or a full pane, else the pane's share.
  - The step comes from `CamParams.CUT_STEP`, empty for now, so each cut is weighed by its area alone: a whole flash, as VFX's `ask_cut` intends.
  - A refused cut doesn't ask again before the register's wait (at least 6 ticks).
- **What each cut does when refused.** No dissolve, no fade, no marker anywhere.

| Cut | Refused |
| :--- | :--- |
| far_catch_up | A whip to him (the motion setting has none: it holds until there's room) |
| solo_cut_in | The launch's eased take-over when one view is up. A hand-over from the other pane, or a shot of its own (a finisher): no shot |
| hold_to_victim | The hold ends and the layout eases back to his pane |
| insert | No insert. Its cut back holds the insert until there's room |
| transform | The calm break (the same beats, the zoom eased, no cut), as reduced flashing already has |
| angle | The tilt eases, at just under the cut's size a tick |
| side_swap, rush_pin, travel_safety, relocate (and the ring's turn) | Held until there's room. The register's 60-tick window guarantees it within a second (the relocation's snap waits and the follow catches up meanwhile) |
| intro | The shot eases in, or isn't made |
| motion_setting (the motion setting's cuts in place of moves) | Held until there's room: the setting has no eased form |

- **Found on main and fixed: an unflagged cut.** Under the motion setting, a launch shot holds the frame through the flight and then snapped to where he landed (`split_rig.gd`, the launch solo's "land" phase). That moved the picture up to 5.6 widths with no cut named, so it asked nothing. It's now a `motion_setting` cut through the gate.

## Proof (`docs/camera/runs/d41ce393/cd-04/`)

| Run | Result |
| :--- | :--- |
| `cut_register_check` (new), main + this park, the fallback ask | **73 of 73** |
| `cut_register_check` with VFX's shared-register park too (`ask_cut`) | **73 of 73** |
| `cut_register_check` on main (negative control) | **43 of 73 fail**: no cut asks, every cut is made with the register full, and the motion setting's landing jumps 5.6 widths |
| The camera suite on main + this park | split_sweep, launch_shots 635, cross_ko 21, peak_shot 24, peak_retry 1, split_vision 11, split_share 26, swing_shot 164, swing_places 33, swing_real 48 and swing_read 14,420 pass. chase_rush (3) and flight_shots (1) fail as on main until vkeep and land-release land. intro_shots needs a window and wasn't run |
| `clip_digest`, 1v1 | **Changes**, as expected: reduced mode in every clip (the governor at 0.03, and cuts that wait), and normal mode where a cut met a busy register (ai:5 most). By clip in `digest-diff.txt` |

**The check reads:**
- Real AI matches (six seeds) in normal, reduced flashing and the motion setting (two seeds), with a real `VfxFlashRegistry` wired as SplitView wires it.
  - Every cut has the register's granted row on its tick, and no cut skips the gate.
  - Off a named cut, a whip or the slam, the shown picture's step changes by no more than 0.5 of the width.
- The same matches with the register kept full: no cut at all, and no step change larger than with room. Over 7,000 refusals.
- All 12 reasons in `CamParams.CUT_REASONS`: granted with a row on an empty register, refused on a full one.

## What's owed (after Sunday)

- **The cut-step table.** Measuring each reason's luminance step on recorded cuts would fill `CUT_STEP`. Then a cut that barely changes the screen (a swap between two framings of the same sky) costs less than a whole flash. Scratch tools for it are written: a hook that lists the cuts, a two-pass capture, a step reader.
- **The reduced-mode analyser reading** (rushcity and collapse, main against the park), and the next pin's full set in reduced mode for CD-04 (3).
- **The look gate:** the digest changes normal-mode frames where cuts now wait or ease.

## RISKS

- **Under a busy register, shots are lost or late.** An insert, a cut-in or a finisher close-up can be skipped. That's the point of the rule, but it's visible in a heavy exchange.
- **`SplitRig.cut(S)`** (the public re-seat, used only by `swing_real_check`) doesn't ask. No shipped code calls it.
