# The GW1b review's B-17: Encounter's riders stacked on GW1a, run together

Encounter, 2026-11-21. On main b0e20f9a (GW1a, landed), in the review's order, a commit each in a scratch git:

1. `gw1b-riders`
2. `index-stage`
3. `wall-cone` + its Tools schema grant + Tools' `wall-cone-cases`
4. `launch-cone`
5. `stray-beams` (re-cut) + its grant + `dash-probe` + Controls' `stray-beams-input`
6. `beam-aim-throw`

Every output went through `tools/gate.mjs`, with no script error.

## The golden, one lane per rider

Each step's golden is compared with the step before it.

| Step | The golden |
| :--- | :--- |
| The base (main b0e20f9a) | **byte-identical to main's committed golden** |
| `gw1b-riders` | moves **9 of 11 rows**, from early checkpoints. Matches 0 to 7 move, and match 8 ran 40,833 ticks and now runs to the backstop (43,200). Tick 0 and the two replays don't move (`goldcmp_b4916fb.txt`) |
| `index-stage` | identical |
| `wall-cone` | identical |
| `launch-cone` | moves **1 row**: match 2, from checkpoint 91 of 151 (`goldcmp_4000908.txt`) |
| `stray-beams` | moves **both human-input replays**, from their second checkpoint; no match row |
| `beam-aim-throw` | no gameplay digest moves; one full-state checkpoint each in matches 0 and 7 (checkpoints 117 and 61) |

The re-cuts below change checks only, so these goldens stand for them.

## The checks on the first stack, and what broke where

| Check | Failing rows | First fails at | Cause |
| :--- | ---: | :--- | :--- |
| `beam_front_check`, `morning_fixes_check`, `outside_check`, `push_mode_check` | 21, 3, 2, 1 | `stray-beams` | Each fires the signature with RT held (`stanceMask` 4) and B on one tick, with no RT press. With GW1a's `bNoBeam` and `bNoBeamKeepRt` on, stray-beams makes RT + B the signature only inside RT's window after its press, so their B became the heavy |
| `aim_throw_check` (beam-aim-throw's own) | 3 | `beam-aim-throw`, on top of stray-beams | The same staging |
| `bark_reads_check` | 1 | `launch-cone` | "low_health_swing fired in the seeded matches": none in its three seeded matches, because the cone changes those matches |
| Controls' `stray_beams_input_test` | 1 | `stray-beams` | See "Not mine" below |

The bisect is in `bisect_A.txt` and `bisect_B.txt`: the seven scripts at every commit. `gw1b-riders`, `index-stage` and `wall-cone` break none of them.

## The re-cuts

- `stray-beams.diff`: the `interrupts.json` context line now reads `"enabled": true` (GW1a turned the beam's own move on; a plain apply failed at line 294). The four checks press RT on the tick they fire, as a real pad does on RT's first tick.
- `beam-aim-throw.diff`: `aim_throw_check` presses RT the same way.
- `launch-cone.diff`: `bark_reads_check` runs five seeds (12345, 777, 31337, 4242, 2026). All three beats fire across them.

**On the re-cut stack, every director check passes: 47 of 47** (`recut_stack_log.txt`, and the `b17v2` folder).

## The rest of the set, on the full first stack

The re-cuts changed checks only, so these stand.
- **Controls' input suite:** 45 of 46 pass.
- **Rendering's 15 checks:** all pass.
- **`two_states`, `load_split`:** pass.
- **Validate:** 0 errors. The determinism lint is clean. The two-fighter ratchet is 365 of 365.
- **`parity.gd`** fails on the full stack, as it must: the riders move the golden above. It passes at the base, where the golden is main's byte for byte.

## Not mine: Controls' `stray_beams_input_test`, one row

"RT, then B 12 ticks later (one tick after the window) is the heavy, no beam" fails on the stack: a beam fires. The events of that run include `brawl_end` and `press_refused`, so on GW1a's data a brawl now runs inside RT's window. The window counts live ticks (a hit-stop doesn't eat it), so B 12 ticks of the clock after RT is still inside it. My reading is that the test needs re-staging on the GW1a data (the fighters apart, or the window counted in live ticks). It's Controls' file.
