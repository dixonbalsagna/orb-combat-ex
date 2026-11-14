# Parked: the authored curves on small planets (arcBySize, GW1c)

Encounter, 2026-11-14, sprint A1 (GW1c). Game Design's ruling is `docs/design/planet-sizes.md` section 2. On tiny and small, the meteor and the high arc peak at most 1.0 × the planet's radius and go sideways at most a quarter of the lap. On medium, big and huge they are unchanged. The numbers live in `power.json` `arcBySize`, and `DirArc` reads them.

**Built on World's stack: globe-step2, a-world-01, planet-sizes, gw1c-world, then this park.** a-world-01 is applied without its two GW1a data-flip patches. The stack's patches then apply in that order to a clean export of 5263c1a6, and reproduce my scratch tree byte for byte. This park touches none of the data-flip files, so it applies with them too.

## What the stack does today, and what this changes

`DirArc._scale()` was the arena's length over medium's lap (`launch.json` `arc.wholeRing`, 153,600). It was written for a ring smaller than the planet, so the curve keeps its angle round. With planet sizes the arena is the whole planet at every size, so the scale follows the planet:
- **Tiny ×0.27 and small ×0.53.** These were already under the caps (0.67 of the radius, a sixth of the lap).
- **Big ×2 and huge ×4.** The meteor would peak at 32,800 and 65,600 units, above the 24,000 flight ceiling. The ruling says "unchanged".

This park makes two changes:

1. **A size is a distance** (the ruling's first line). The scale is now the arena over its own planet's lap. On the whole of any planet the curve is absolute, as on medium. A smaller ring still scales it.
   - **Medium is bit for bit today's:** the factor is W / 153,600 × 1.0.
2. **On the sizes `arcBySize` names** (tiny and small), the curve's rise is held to `peakOfRadius` × the radius, and its sideways distance to `sideOfLap` × the lap.

| Size | Meteor: rise, across (lap share) | High arc | Before this park (the stack's scale) |
| :--- | :--- | :--- | :--- |
| Tiny (radius 6,519) | 6,519, 10,240 (0.25) | 6,519, 10,240 (0.25) | meteor 4,373, 6,783 |
| Small (13,038) | 13,038, 20,480 (0.25) | 9,900, 15,355 (0.19) | meteor 8,747, 13,566 |
| Medium | 16,400, 25,436 (0.17) | 9,900, 15,355 | the same |
| Big | 16,400, 25,436 (0.08) | 9,900, 15,355 | meteor 32,800, 50,872 |
| Huge | 16,400, 25,436 (0.04) | 9,900, 15,355 | meteor 65,600, 101,744 |

- On tiny, both curves hit both caps, so they fly the same shape and differ only in time (6.2 s and 4.8 s).
- The curve's time is unchanged at every size. Only its rise and its distance are held.

## Apply

On the stack: `git -c core.autocrlf=false -c core.eol=lf apply arc-by-size.diff grant-simulation-power.patch grant-tools-schema.patch`.

| Patch | Owner | sha1 |
| :--- | :--- | :--- |
| `arc-by-size.diff`: `sim/director/arc.gd` (`_scale`, `_bySize`, `_dist`, `_rise`, read in send, step, landing and the landing score) and the new check `sim/director/tools/arc_size_check.gd` with its `.uid` | Encounter | 7a7508da0be2d9f1ab3588a351a60ccc81e1d347 |
| `grant-simulation-power.patch`: `data/fight/power.json` `arcBySize` and its comment; `sim/core/power.gd` `SimPower.arcBySize()`, three lines | Simulation | b9302e1a9b2386e919d7d5931570b4f3ec4d5abb |
| `grant-tools-schema.patch`: `tools/schemas/fight-power.schema.json`, the `arcBySize` property | Tools | 24a9d843622f78e8ef75ac8b40583192b3822d45 |

## The check

`arc_size_check.gd`, 17 checks. Each curve is flown on each of the five sizes (planet 7, touch 1).
- Tiny and small stay within both caps, flown to their landing (0.251 of the lap at most).
- Medium, big and huge fly medium's absolute curve.
- A ring of half its planet halves it.
- **Negative control:** with `arcBySize` taken out, tiny's meteor rises 16,400 over a radius of 6,519 and goes 0.62 of the lap. It fails both caps.
- The peak flown can stand a little over the rise: the measure is over the start's ground, and the curve runs between two grounds. Small's meteor flies to 13,255 against a radius of 13,038.

## Proof

On the stack plus this park. Records are in `docs/director/runs/5263c1a6/arc-by-size/`, and every output went through `tools/gate.mjs`.
- **The golden check passed, so the golden doesn't move.** The arc is off in main's data, and at medium the scale is today's bit for bit.
- These checks pass:
  - `arc_size_check` 17 of 17, its negative control included;
  - `arc_check`, `flight_strike_check`, `floorlift_check` and `follow_check`;
  - World's `size_check`;
  - the core checks `two_states` and `load_split`.
- The two-fighter count is 365 of 365. Validate: 0 errors.
- The self-test has 2 failures, both on the stack and not from this park: World's new `biomes-sizes` and `biomes-world` schemas have no invalid cases yet.

**With a-world-01's GW1a data flips also applied:**
- The golden fails, as it must: that is GW1a's own move.
- **World's `size_check` fails two rows:** tiny's and small's tallest building is 4,875, against caps of 1,956 and 3,911. The height cap of gw1c-world doesn't hold under GW1a's world data. That's a finding for World, not this park; the park's checks pass either way.

## NEEDS FROM EP

- **Game Design, one word.** I read "unchanged" on medium, big and huge as today's absolute numbers, which is what the ruling's "why" assumes (15,700 up, 25,400 across). The stack's code would have flown them 2× and 4× on big and huge.
- **Simulation** (the power.json key and the reader) and **Tools** (the schema): the grants.
- **World:** the building-height cap on tiny and small fails with GW1a's data flips on (above). Tools also needs invalid cases for World's two new schemas.
- **Note for the golden window:** a new key in `power.json` changes `SimPower.dataHash()`. That only matters to a replay recorded with the energy model on.
