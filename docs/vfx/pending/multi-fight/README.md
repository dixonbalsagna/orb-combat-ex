# Parked by VFX (2026-10-15): multi-fight and choreography

Built in scratch on HEAD 69a46841, measured on Tools' path, not applied. Plan and numbers: `docs/vfx/multi-fight-plan.md`.

- `multi-fight.patch`: `render/vfx/reach.gd` (nine new cue arms and the `multi` defaults group), `render/vfx/shots_view.gd` (twelve new drawn styles), `render/vfx/react.gd` (`on_wave`: the duel's glass), `render/vfx/vfx_hub.gd` (`_duel_wave`: the glass and the ground's crack web), `render/vfx/tools/effects_check.gd` (`_multi`, the checks of this set). `git apply docs/vfx/pending/multi-fight/multi-fight.patch` from the repo root. Inert until Encounter sends the cues (none exists today): no 1v1 reading moves.
- `scratch-multi-scenario.patch`: a measuring scenario `multi` for `render/tools/flash_capture.gd` (an AI match with the cues injected on a 300-tick cycle). It also needs eight lines in `vfx_hub.gd` that are not part of the tree: `var scratch_events: Array = []` and, at the top of `_consume`, `if not scratch_events.is_empty(): events = events + scratch_events; scratch_events = []`. Scratch only: never apply it to the tree.
