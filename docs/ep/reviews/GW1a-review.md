# GW1a landing review (2026-11-14)

An independent, read-only review of the whole GW1a stack. It was run by an Opus reviewer for the EP, because the stand-in was paused for the Fable reset. It read the s422 tree (b09d705) and every park's README. The full gate ran separately.

## Blocker

**1. World's checks-gw1a pins hide real failures without classing them.**
- `WorldPin.shipped()` turns the energy model and the dash off in 33 checks.
- Nine of those checks fail only with the model on, which is Orb's real path: repeat, wrecks, meteor_crater, interior, wall_hold, brunt, deepen, bystanders, struggle_dir.
- Each must be classed:
  - a real fault becomes a ceiling, or a row that runs under the model, with the owed fix named;
  - only rows that test a path Orb's game doesn't take may stay pinned.

## Major

2. **Encounter pinned two faults it calls real.** arc_check's meteor bowl and beam_ai_check's lost beam hold are pinned off, when they should be ceilings. The meteor bowl has two competing fixes; the EP picks Encounter's gw1b-riders.
3. **Camera's launch_shots fight 2.** A quarter-width jump with no cut ships on main until GW1b. It is correctly capped as a ceiling, and the fix is `gw1b-scape-side`.
4. **A-CAMERA-01 has no side-by-side against the 9 Nov build** (ADR 0010). Camera makes one in its next capture window.
5. **Controls' t1_latency_test.** The join press is a real fault for a mid-match join. It was traced by Rendering, and the fix is `join-press` (GW1b).
6. **The gated tree predates two late parks** (camera gw1a-pins-2, tools ci-gw1a-checks). The final tree must be re-verified with them.

## Minor

- Some visible changes have no side-by-side:
  - the ghost-limb cap (VFX made stills: no visible change);
  - the planet-view fixes;
  - the start-flow menus (Orb has seen the pictures);
  - slam_hint;
  - the stick push default.
- Gaps on the globe ground:
  - props_check has no globe version;
  - no check stands a fighter on water on the globe ground.
  - Both are owed after GW1a.
- Numbers in code:
  - `sim/core/hitstop.gd:32` writes the never-cut list in code; it should come from data;
  - `render/vfx/meteor.gd:317` copies the sim's flight-speed formula into render code.

## Clean

- **Determinism:** no clock or unseeded random number reaches the sim, and there are no float32 types in the sim diffs.
- **The field-cache fix** is sound.
- **Orb's rules:** none are broken in the added lines.
- **Order:** no duplicated JSON keys, and no patch undoes another.
