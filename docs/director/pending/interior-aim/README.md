# The interior aim (parked, 2026-10-19)

Owner: Encounter Systems Director. World's finding: the planner's sends into a tower fly at 3 to 22 degrees, where World's interior chain starts at 15 to 60 (`../../camera-intent.md` §5).
- **It sits behind `interiorAim.enabled` (false)** in `data/director/launch.json`. It also needs World's `interiorChain` on (brunt.json, 0 on main). Off, there is no candidate and no draw, so the golden doesn't move.
- **Built and read in scratch. Not applied.**

## To build it

`node ia.cjs <root>` from this folder, and with World's OK `node grant_world.cjs <root>`. Without the grant the planner offers nothing new. `--check` reads every anchor and writes nothing. It composes with the camera-intent, recoil-flip and balance parks.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/launch.gd` | Encounter | `_insideAim` and `_insideScore`; `chooseLaunch` offers the inside send beside each building's low one |
| `data/director/launch.json` | Encounter | `interiorAim`: enabled, uy [0.3, 0.45, 0.65, 0.9], score {hero −8, villain 8} |
| `tools/schemas/director-launch.schema.json` | **Tools** | The same key |
| `sim/world/brunt.gd` | **World** (`grant_world.cjs`) | `aimInside`: `aim`'s loop over the planner's angles, keeping only a flight whose arrival fits `WorldInterior`'s band; its plan's `brunt` carries `inside`. `aim` is unchanged (both share `_aimBy`) |

## What it read (main 5385a86d, in scratch; World's interior chain on in memory)

| AI v AI, 10 matches of 3 min | Building sends (the Protagonist sent, the Anti-hero sent) | Interior chains | Share |
| :--- | ---: | ---: | ---: |
| The usual start, aim off | 2, 0 | 0 | 0% |
| The usual start, aim on | 2, 0 | 1 | 50% |
| From the city, aim off | 5, 10 | 0, 4 | 27% |
| From the city, aim on | 7, 11 | 3, 5 | 44% |

- With it on, the Anti-hero's sends of the Protagonist into a tower start the chain 3 times in 7, from 0 in 5. The hero's sends of the Anti-hero start it about as before (4 in 10, then 5 in 11): their low aims already fit sometimes, and the inside send scores −8 for him.
- Building sends are rare away from town, so the read is small. QA's rows decide.
- **Off:** in the gate list over all five parks together (5385a86d), the golden is main's, byte for byte, and 34 of 35 pass. The one red is main's own anim_check.

## Probe (`probes/iap.gd`, from a copy's root)

`iap.gd -- <matches> <seed0> [--ticks=10800] [--aim=on|off]`: AI v AI, World's interior chain on in memory. It reads building sends and interior chains started, by the fighter sent, and the share of building sends that start a chain.
