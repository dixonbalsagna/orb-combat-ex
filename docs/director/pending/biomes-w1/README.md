# Biomes W1: the signature's variant by biome (parked 2026-10-27)

Owner: Encounter Systems Director. This is the first of Encounter's windows in `docs/combat/biomes.md` section 6. It is built on e1521ef5, which has Combat's `data/combat/sigvariants.json` (2b6d6757, `fineOn` false) and Tools' `combat.sigvariants/1` schema. The director now reads the file in place of the three old tables, so VFX's ten variant looks can appear in play once `fineOn` is on. As the file ships (`fineOn` false), play is bit-identical to main and the golden is byte-identical; only the replay header's data hash moves.

## What it does

- **The pick.** `DirData.planBeam` picks the row by the biome under the defender, once, for the whole beam:
  - with `fineOn` off, by `WorldBiomes.biomeAt` (the seven names, today's play);
  - with `fineOn` on, by `fineNameAt`, so a gen 2 planet reads its fine biome's row (`city` and `village` over a settlement).
  
  Gen 1 and the hand-made world read the same seven rows either way, because `fineNameAt` is `biomeAt` there. A name the file has no row for reads `biomeAt`'s row.
- **What the beam reads from its row**, found by the name it carries (`b.variant`, unchanged, so `debris.gd` and the `scorch` event keep the name):
  - `scorch`: passed to `WorldCrater.scorch` as the groove's [depth, width] factors;
  - `structMul`: times the structure bite `b.sf` at fire time, so forks and the impact blast carry it too;
  - `areaMul`: times the radius of `sampleBeam`'s `damageArea` (1 when missing);
  - `fx.dust`, `fx.sparks` and `fx.fire`: in place of the GLASS TRENCH and FIRESTORM branches, at the same places and in the same order.
- **What it reads but doesn't build yet.** `trees` is read as `area` (today's `damageArea`) whatever the row says, until World builds `burn`, `fell`, `snap` and `none`. The other `fx` flags (spray, steam, shards, plates, powder, embers, ash) are VFX's, keyed by the variant's name.
- **What it retires.** `templates.json` `beam.variants` goes, along with the templates schema's requirement and its property; a `_variants` note points to the new file. `crater.gd`'s `SCORCH_VARIANT` and `beam.gd`'s unused `VARIANT` go too.
- **The data hash.** The file's text is folded into `DirData.dataHash` (the replay header), after `enders.json`.
- **Not read in W1** (W2's): `aftermathOn`, `aftermath`, `byPersonality`, `waterRule`, `adoptProposed` with `proposed`, and `outcomes`. The landed file has `aftermathOn` and `byPersonality.enabled` true. W1 reads neither, so both play as off until W2 wires them.
- **A loader rule.** Rows that share a name must play the same (the city and the village share BOULEVARD RAZE until LANE SWEEP is adopted). A second row of the same name that plays differently is a `push_error`, and the first row is kept.

## To build it

On e1521ef5 or later, run `node w1.cjs <root>` from this folder. `--check` reads every anchor and writes nothing. Godot's import then writes `sim/director/tools/sigvariants_check.gd.uid`, which goes in the same commit.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/data.gd` | Encounter | Loads `sigvariants.json` and indexes it by name; adds `sigKeyAt`, `sigRow` and `sigByName`; `planBeam` picks the row; adds the hash fold; adds `sigFine` (tools only: force `fineOn`) |
| `sim/director/beam.gd` | Encounter | `VARIANT` deleted; `fireBeam` times `b.sf` by `structMul`; `sampleBeam` reads `scorch`, `areaMul` and `fx` from the row |
| `sim/director/tools/sigvariants_check.gd` | Encounter | New: the proof below |
| `sim/world/crater.gd` | World (grant) | `SCORCH_VARIANT` deleted; `scorch` takes a last parameter `vk: Array = [1.0, 1.0]` and passes it to `_scorch` |
| `sim/world/tools/probe.gd` | World (grant) | Line 235's GLASS TRENCH call passes `NAN, [0.8, 1.3]` (its other calls are FIELD SCAR and HORIZON CLEAVE, which are [1, 1]) |
| `data/combat/templates.json` | Combat (grant) | `beam.variants` replaced by a `_variants` note |
| `tools/schemas/combat-templates.schema.json` | Tools (grant) | `variants` dropped from `beam.required` and from `beam.properties` |

Other callers of `WorldCrater.scorch` pass the plain groove, as they did before: `render/tools/shots.gd` (FIELD SCAR), `probe.gd`'s other three calls, and World's parked `after` (FIELD SCAR). The frozen parity copy `sim/director/test/combat-parity/templates.json` keeps its `beam.variants`. `loader_check` swaps it in, but neither plan reads the variant from the templates any more, so both read `sigvariants.json` and stay identical. The JS oracle `sim/director/beam.js` keeps its own table, as before.

## The proof (`sigvariants_check.gd`)

`godot --headless --path . --script res://sim/director/tools/sigvariants_check.gd -- [--matches=6] [--ticks=7200]` runs five parts and exits 1 on any FAIL:

- **built:** the seven built rows carry the retired tables' names, groove factors and looks exactly, equal to the bit. This is World's condition.

  | Row | Name | Groove | Looks |
  | :--- | :--- | :--- | :--- |
  | mountains | RIDGE BORE | 1.6 / 0.8 | grey dust |
  | desert | GLASS TRENCH | 0.8 / 1.3 | sand dust, 2 sparks |
  | forest | FIRESTORM | 1.0 / 1.1 | fire within 140 |
  | city, village | BOULEVARD RAZE | 0.8 / 1.0 | grey dust |
  | plains | FIELD SCAR | 1 / 1 | grey dust |
  | ocean | HORIZON CLEAVE | 1 / 1 | grey dust |

  Every built row has `structMul` 1, no `areaMul` and `trees` area.
- **gen 1:** on the hand-made world, every column picks the same row with `fineOn` off and on: `biomeAt`'s, named as in the retired table.
- **gen 2:** on gen 2 planets with `fineOn` off, every column picks `biomeAt`'s row. With it on, every column picks `fineNameAt`'s, and all 17 rows are picked.
- **beam:** a beam is fired along the ground over a column of each row and sampled every 4 units. Every scorch event carries the row's name and its width, which is (HW0 + HW_P × P) × the width factor × 2, equal to the bit; for a built row that equals the retired factor's width. The dust, sparks and fire each sample throws at its own place are the row's. The bite is the ladder's times `structMul`.
- **play:** gen 2 AI matches with `fineOn` off and on: what the signatures were planned over, and which variants the beams carved by. Off reads only the seven old names, and every tag's name is its row's.

## What it reads

The runs used three scratch exports of e1521ef5: one with no park (HEAD), one with the park as it ships (`fineOn` false) and one with the park plus `fineOn` set to true in the data.

- **The proof** passes in full (`--matches=6 --ticks=7200`):
  - **built:** all seven built rows match the retired tables exactly.
  - **gen 1:** all 4,800 columns pick the same row off and on.
  - **gen 2 off:** 24,000 columns on 10 planets pick `biomeAt`'s row.
  - **gen 2 on:** all 17 rows are picked. The rarest are sea_ice (10 columns) and volcanic (37); the first places found are seed 25 at x 71,024 and seed 7 at x 3,632.
  - **beam:** all 17 rows: 81 samples each, except 52 over the ice sheet, where the beam leaves the ground's reach. Widths run from 524.8 (RIDGE BORE, CRUST SEAR) to 852.8 (GLASS TRENCH). Fire shows only on FIRESTORM and GRASSLAND BLAZE, and sparks only on GLASS TRENCH.
  - **play off:** signatures were planned over the seven old biomes only.
  - **play on:** the tags read jungle VINE SHEAR 4, highland SCREE RUN 1, savanna GRASSLAND BLAZE 1 and tundra FROST HEAVE 1 beside the old names. The beams carved by FROST HEAVE, GRASSLAND BLAZE, SCREE RUN and VINE SHEAR.
- **Gen 2 against main** (World's `gen2_soak.gd`, 12 matches of 5,400 ticks, 4 played twice):
  - **off:** all 12 gameplay hashes equal HEAD's.
  - **on:** 7 of the 12 differ (their beams carve by the new rows) and 5 equal HEAD's.
  - Every repeat is the same twice.
- **The golden** is main's, byte for byte, both with the park as it ships and with `fineOn` on. It does not carry `DirData.dataHash`: its `fightHash` covers `data/fight/` only. `determinism` exits 0 with `fineOn` on.
- **The data hash** moves, once, at the fold. `DirData.dataHash` is a85fd0a57d54337c on HEAD, ba3702d24f766acd with the park and 0d9cb111d248bdf2 with `fineOn` on. The replay header's hash is 2ea0c3d0bac1d4ba, b8c3e48c761b0e92 and e647ce71e9e275fe. No stored replay pins it.
- **The gates, with the park as it ships:**
  - The import is clean. validate reads 276 files with 0 errors, and the self-test passes.
  - All 35 of Encounter's gate runs exit 0: the golden, npm, parity, determinism (and `--intro`), seam, anim_check, the lead, joint and held scans, cue, reads, hud, brawl cases, World's five tools (`probe.gd` with its grant line), QA's run-all, flash worst and count, mash, the nine input tests and the loader at 200 matches. The loader passed on its own run, because the chain's first run was cut off after its banner: 51,576 plans, 848 of them signatures, identical to the frozen copy's.
  - Rendering's 16 headless checks exit 0 (cue also with `--profile=spaced`; outline and cull need a window), and so do split_sweep and campaign_episode.
