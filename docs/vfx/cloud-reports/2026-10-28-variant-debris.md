# VFX cloud report: the ten variant debris looks (2026-10-28)

Branch `cloud/vfx/variant-debris`. Brief: docs/ep/cloud-briefs/vfx-variant-debris.md.

## SUMMARY
Each of the ten gen 2 variant names (ICEFIELD THAW, FLOE SPLIT, VINE SHEAR, GRASSLAND BLAZE, FROST HEAVE, PINE BREAK, MIRE BOIL, SHORE SCOUR, SCREE RUN, CRUST SEAR) now has its own debris. It's built from its sigvariants.json row's fx kinds, in Art's plume and scar colours for that row's biome, with the row's own fx.dust for its dust puffs. The look sits behind `VfxHub.variant_debris_enabled`, which is off by default. The seven built names have no entry, so gen 1 draws byte-identically with the switch on or off. **Look evidence pending (local).**

## CHANGES
- `render/vfx/biome.gd`: `variant()`, `has_variant()`, `sig_row()`. Reads sigvariants.json read-only to get each name's biome and fx. Four new emitter kinds in `_one`: shard, plate, spray and cinder.
- `render/vfx/debris.gd`: `fleck` takes an optional `flat` (a chunk's width over its length). The default is 0.8, the same as before.
- `render/vfx/vfx_hub.gd`: on a scorch event with the switch on and a name in the table, `biomefx.variant` draws instead of `debris.embers`. Otherwise the path is unchanged. Adds `variant_debris_enabled`.
- `render/vfx/vfx_look.gd`: `VARIANT_DEBRIS_DEFAULT = false`.
- `data/vfx/biome.json`: new `variants` block (`per_tick_cap` 8, ten rows, emitters by fx kind).
- `tools/schemas/vfx-biome.schema.json`: `variants` (fx-kind names enforced), new emitter kinds, and the `dust` and `steam` colour tokens. I checked that a bad kind or a bad fx name fails validate.
- `render/vfx/tools/effects_check.gd`: new `_variant_debris` section, 22 lines.
- `docs/vfx/biome-fx.md`: window 5 (the table of looks, hook, switch, budget, checks).

## DECISIONS
- **The table is keyed by the row's name**, as the brief asks. The biome and the dust colour come from the sigvariants row itself, so they can't drift from it. effects_check fails if a new row, or any of a row's fx kinds, has no emitters here, or if a built name gets an entry.
- **It replaces the scorch embers for those names; it doesn't add to them.** The budget stays at about the embers' level: up to 8 bits a tick, roughly 3 a tick in a long beam.
- **CRUST SEAR uses steady orange chips, not the pulsing ember bit** (the same as window 1 and Art's rule). Only GRASSLAND BLAZE uses ember needles, through `ember_bit`, which stays under the register's ember area, cap and per-tick budget. Nothing asks the flash register.
- **The switch is off by default** (cloud-workflow rule 6), separate from `embers_enabled`, which is also off in the live build. Turning on only `variant_debris_enabled` shows the new looks.

## Gates (this tree)
| Gate | Exit | Last line |
| :-- | :-- | :-- |
| validate | 0 | 278 files checked, 0 errors, 0 warnings |
| validate --self-test | 0 | parser 283 files + 7 text cases; engine 46 cases + 6 unsupported; schemas 170; data cases 8153 |
| lint-determinism | 0 | determinism lint ok |
| npm test --prefix sim | 0 | all 4 stages passed (golden byte-identical) |
| effects_check | 0 | effects check passed (variant debris: 22 ok) |
| hash_check | 0 | hash check passed |
| anim_check | 0 | anim check passed (9537 checks) |
| all 40 sim/world/tools/*_check.gd | 0 | 0 failed each. step_check's 25 ms timing line failed once (29.0 ms) while the machine was saturated with 3 parallel runs, which makes that reading invalid. Rerun alone: 0 failed (13.9 ms) |
| split_sweep | 0 | split sweep passed |
| campaign_episode | 0 | the two plays are the same to the bit |
| parity | 0 | golden check passed |
| sigvariants_check | 0 | sigvariants check passed |
| flash_worst (via gate.mjs) + check-log | 0, 0 | no SCRIPT ERROR lines; flash count passed in 82 runs. The switch is off in the scene, so this is the unchanged build's count; the variant debris asks the register nothing (effects_check) |

**Seen in real play.** A scratch run of 72 gen 2 AI matches with fineOn forced on fed the hub with the switch on. Nine of the ten names reached VFX and drew their debris. FLOE SPLIT never came up in those matches; effects_check covers it with forced scorch events.

## Look evidence pending (local): scenes for the side-by-side
For each scene: gen 2, `planetGen 2`, `arena.cols 2400`, `DirData.sigFine = 1` (or fineOn), `hub.variant_debris_enabled` on against off, at the first scorch tick of that name. Each row gives the match seed, the planet seed, the touch value and the tick:
- ICEFIELD THAW: 111, planet 4, touch 2, tick 869
- GRASSLAND BLAZE: 301, planet 11, touch 1, tick 449
- SCREE RUN: 302, planet 11, touch 2, tick 416
- VINE SHEAR: 307, planet 17, touch 1, tick 428
- MIRE BOIL: 112, planet 5, touch 0, tick 959
- PINE BREAK: 313, planet 23, touch 1, tick 555
- CRUST SEAR: 334, planet 9, touch 1, tick 2322
- FROST HEAVE: 100, planet 1, touch 0, tick 2602
- SHORE SCOUR: 343, planet 14, touch 1, tick 529
- FLOE SPLIT: none found in play. Use sigvariants_check's beam setup on a sea_ice column instead (DirBeam.fireBeam with the row's name).

## NEEDS FROM EP
- The local side-by-sides above, and a flash clip with the switch on, before it is turned on.
- Rendering: the main.gd debug word or flag to turn on `variant_debris_enabled` for the captures. That is Rendering's file, so I didn't touch it.

## RISKS
- The sizes and counts were tuned by number, not by eye. The colours are Art's exactly.
- If a row is renamed (TIDE CLEAVE, LANE SWEEP), the table's key must change with it. effects_check catches the mismatch.
- FLOE SPLIT is unproven in real play. Sea ice may rarely sit under a defender.

## NEXT
Run the local side-by-sides. If Orb likes them, turn the switch on (one line in vfx_look.gd).
