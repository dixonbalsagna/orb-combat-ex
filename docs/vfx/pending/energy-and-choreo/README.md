# Parked by VFX (2026-10-16): the energy look and the choreography's marks

Built in scratch on HEAD 0ca6f670, measured on Tools' path, not applied. Plans: `docs/vfx/beam-look.md` (the beams, the flavours, the explosions) and `docs/vfx/multi-fight-plan.md` (the cues, the opening's ring, the beam struggle's marks).

Two patches, in this order (the second needs the first's `VfxBeamLook`):

1. `vfx.patch` (20 files, VFX's own): `render/vfx/` (`beam_look.gd`, the three beam shader files, `reach.gd`, `shots_view.gd`, `explode.gd`, `debris.gd`, `shard_view.gd`, `shots.gd`, `react.gd`, `vfx_hub.gd`, the tests in `tools/effects_check.gd`), `data/vfx/energy.json` (keyed by roster id: protagonist, rival, rival_short, reference), `tools/schemas/vfx-energy.schema.json` and its `map.json` entry.
2. `rendering.patch` (4 files, Rendering's, to review and apply): `render/core/beam_view.gd` (the layers' materials and sizes, the rise, 24 rings along each prism, and the beams meeting at `Clash.mid` when there is one), `render/core/sim_host.gd` (the register weighs a beam by its own width), and the two checks that encode the old sizes (`render/tools/flash_reg_check.gd`, `render/tools/depth_check.gd`).

Apply from the repo root with `git apply --ignore-whitespace` (`debris.gd` is CRLF in the working tree). It touches no sim file; the beam struggle's marks read `S.game.clash.mid` when Simulation's one new field exists and use the old glide when it does not.

Gates in the scratch copy: effects_check, hash_check (plain and press styles), determinism (plain and `--intro`), the negative control failing as it must, `node tools/validate.js` (190 files, 0 errors, 0 warnings), `flash_reg_check`, `depth_check`.

Superseded by this: `beam-look/` and `multi-fight/` (their READMEs say so); `chunk-area-cap.patch` is a separate parked idea and stays.
