# gen2-read-speed-b: the B plates in steps, and the calm turn's read for Simulation's K (parked, window 20 second add-on)

World and Environment, 2026-10-26. Stacked on main (9538e6bf, the first park landed with its grant). The page is `docs/world/gen2-read-speed.md` (sections 3 and 4, in the diff). **Nothing changes a state as the data ships**: the golden does not move (`warmTotal` is absent from the data, so the calm turn is the turn it was, to the bit).

## Apply

On main (9538e6bf or later), from the repo root, in one commit:

```
git -c core.autocrlf=false apply docs/world/pending/gen2-read-speed-b/gen2-read-speed-b.diff     # sha1 d4254bbe3e81, 14 files
python docs/world/pending/gen2-read-speed-b/grant_sim_plates.py .                                # Simulation's sim/core/planet_load.gd: its plates step (a grant)
```

The makers (`mk_p22.py`, `mk_p23.py`, `mk_p24.py`, with `mk_wbc_lib.py`) rebuild `plateb`, `climate`, `planet`, `epoch` and `sites` from main byte for byte, in that order.

## What it changes

1. **Research's B plates in steps** (`mk_p22`): `WorldPlateB._make` is `_makeBegin` (cells, 0.6 ms), `_makeArea` (the 2,000-point area sample, 39 of the 46 ms, a few points a call) and `_makeEnd` (about 1 ms; the land share's order statistic from a native sort of the values, 5 ms saved); `WorldPlateB.step(P, units)`; `PlanetJob.step` makes the plates first when B is on. With B on a grid cell costs 3 units and a try 6, 10 or 32 (measured), so the planet job's longest call at a budget of 250 with B and rivers on is 7.5 ms (it was 17 for a grid slice and up to 126 for a try-set).
2. **The calm turn's read** (`mk_p23`): `warmTotal` in the turn data (read with a default of 0: Simulation adds the key and its schema line when it flips) shares `k` among the warm rings (`_warm` reads `k / rings` of each); each ring is read to its counted columns (`RingJob.readTo`) and counts as read by the state's count; `WorldEpoch.readAhead(S, units)` and `warmPlan(S)` for a host's idle time (no state touched).
3. **The ring's last step off the tick it completes on** (`mk_p24`): a warm ring's job is lazy; its fine-biome blend (stepped: `WorldSites.blendBegin/blendStep`) and held places are done in the preparation's first two ticks, the preparation proper in the other `prepTicks - 2`; the hash's biomes wait for the blend; the swap is allowed on the same tick as ever. The calm turn is the same turn (below).

## Proof (scratch: an export of main 9538e6bf, the grant applied, plus this)

- **Same to the bit:** `planet_digest` (now with a B-on pass: plates, `lift`, places, grid, flow and two slices) identical to the base for both generations and with B; `calm_digest` (a calm turn to its swap, gen 1 and 2, k 32 and 12, one and two rings, the gameplay hash every 100 ticks): all 12 lines identical to the base, and the same again with `warmTotal` 1 and a host reading ahead against none; `step_check` (the B plates made at 250 units equal the whole make's arrays and `lift`; a B planet by the job equals make's) and `calm_read_check` (warmTotal reads 6 of each ring a tick at k 12; read-ahead changes no state, with the job up to 2,184 columns ahead; a whole turn to its swap with and without read-ahead is the same state on the same tick; a lazy ring's blend and places made at 1, 37, 400 and whole units a call are `readSlice`'s, bit for bit).
- **Gates** (all on the scratch, the grant applied): all 45 World checks and both probes 0 failed (incl. `step_check`, `calm_read_check`, `b_check`, `epoch_check`, `rivers_check`); lint clean; validate self-test 9141 of 9141; `run-all` all 5 stages (parity, soak, golden, godot); `gen2_soak` 900 ticks, `--b` and `--rivers`, 12 of 12 each, 0 not the same twice; the render gates (`after`, `city`, `cue`, `depth`, `flash`, `flash_reg`, `flight`, `ground`, `hud_words`, `lane`, `open`, `pane`, `patch`, `shape`, `sky`, `stage`) and Audio's 9 pass (`cull` and `outline` refuse to run under --headless, as before).

## Numbers (native, this PC, other sessions running)

| | Before | After |
| :--- | :--- | :--- |
| The B plates' make | 46 ms in one call | 9 calls at 250 units, the longest 6.3 ms |
| A B planet's job, longest call at 250 units | 54.9 ms (plates) then 17 ms (a grid slice) | 7.5 ms |
| The calm turn at k 12 shared (`warmTotal` 1), worst tick | 8.1 ms (the two rings complete together: blend, hash, first stage, twice) | 4.4 ms (a fresh place's layout 2.3 ms, the swap 2.5) |
| The calm turn at k 12 shared, mean tick | 0.8 ms | 0.8 ms |

## Findings (for the EP, Simulation, Game Design)

- **The worst tick was not `_prep`** (calm-turn-read.md section 5 says it was, on World's earlier "probably"): at k 32 it is the two rings' reads; at the lower rate it is the tick the rings complete. The preparation's own steps are each 2.3 ms or less over the 80 warm ticks; `prepTicks` stays 6.
- **Skipping the carry zone's columns is not done**: the weights are 0 only inside `carryUnits / 4` (3,000 units: 188 of 2,400 columns, **8% not 31%**), and the swap's first stage reads the new ring's heights across every held place's span. Not worth the risk.
- **Simulation's load** (`grant_sim_plates.py`): its plates step makes the B plates a slice at a time (`WorldPlateB.step`); the progress total counts a grid cell as one unit though a B cell costs three (a small overshoot).
- **Still not World's to fix**: the web ring-read target needs `k` or a lazy ring (Simulation, Game Design); `warmTotal`'s key and schema line are Simulation's.
