# Parked: the one energy model on in main's data, with the dash (A-ENERGY-04)

Simulation, 2026-11-14, sprint A1 (`05-directives/A1/simulation-engine.md`, criterion 2). It replaces the old `power-flip/` park. **It changes the state hash, so it lands in golden window GW1a:** with it, main's data plays the energy model as the 9 November build did from the page's setup. GW1a's target golden (`docs/sim/runs/6a30b4c9/gw1a-target/`) was recorded with exactly these two switches on.

## What changes

- **`data/fight/power.json`** (a grant: the EP lands it with Game Design's flight speed, A-CONTROLS-04, in one edit): `"enabled"` true, and `"dash": {"enabled": true}`.
  - The page sent `"power": true` in every match, and `"dash": true` with the model on.
  - A setup's `"power": false` or `"dash": false` still turns either off for a match.
- **Mine, the rows written for the model or the dash off:**
  - `power.gd`'s and `hash.gd`'s notes;
  - `two_states_check`'s `power` setup becomes the match with the model off;
  - parity's rows written for the model off are pinned `"power": false`: the wired probes, the free-flight reads, the forms rows;
  - parity's spawn-floor row is pinned `"dash": false` (see the finding below);
  - `power_check`'s rows compare against the data's own switches rather than "no word", for the dash and the slip. The model's flight table runs with the dash off. So power_check passes on main's data as it is now, and as it will be once GW1a lands the 9 November data (the slip, the kick and the arrival on);
  - `kick_check`'s keepTop rows run with the dash off, because the traversal's old fall they compare against exists only without the dash at any range.
- **Tools (asked, not in a patch):** once the data is on, the page's code patch that turns the model and the dash on (`tools/preview/switches.mjs`, `powerLines` and `dashLines`) goes.

## A finding for World: a dashing fighter can sit inside a rising lake floor

With the dash on, a computer fighter flying low along a rising lake floor sat **2.259 units inside it** at tick 2 (parity's spawn-floor lake: planet 3, gen 2, the floor on).
- `SimFighter.floorFor` lifts a fighter who starts a tick below the floor he moves onto by at most the water's rise limit (`WorldWater.riseMax`). That's the deliberate ease that never snaps him up.
- At plain flight speeds one tick's slope stays inside it. At the dash's speed (25 to 83 units a tick) he outruns it, then eases out over a tick or two.
- With the model on and the dash off, or the model off, it never happens (`floor_probe`).
- **It happens in the 9 November build too,** which plays the dash. It belongs with A1's clipping scope ("no fighter sinking into a crater"). Whether the rise limit should scale with his own speed, or not ease him while he flies under his own power, is World's rule.

## Other owners' checks it breaks

Each passes on clean HEAD and fails with this park; the baseline is in `docs/sim/runs/78425d6d/energy-on/`. Each owner pins `"power": false` (or `"dash": false`) to keep testing the off path, or re-reads under the model.

| Owner | Check | Fails |
| :--- | :--- | :--- |
| World | `brunt_check` | 6: the tier ladder's rows (with the model on, `WorldBrunt` uses energy against mass) |
| World | `deepencheck` | 1: a bowl at the radius cap deepened (704 to 154) |
| World | `ground_check` (World's) | 2: gen 1 planet matches and a gen 1 turn hash as before (the hash reads `powerFlat`) |
| World | `interior_check` | 3: tier 3 and 4 down reach the ceiling; a fast steep send at tier 1 bounces |
| World | `repeat_check` | 1: the same send does 1.00x three times |
| World | `meteor_crater_check` | 1: an ordinary dig held to 8 bh |
| World | `wrecks_check` | 1: the scrap the same at every tier |
| World | `wall_hold_check` | 3: the fight's freeze at the hit, and repeats breaking the building |
| Encounter | `arc_check` | 1: the meteor's own bowl |
| Encounter | `follow_check` | 3: 60 ticks after the send |
| Encounter | `loader_check` | the code path's launch beat lacks `"share": "chainLink"` |
| Encounter | `floorlift_check` | 1: the control's pop table (passes on HEAD) |
| Rendering | `after_check` | 1: "the match has a rush in it" (its scripted match has no rush with the dash on; passes on HEAD) |

**Not this park:** Netcode's `spectator_check --negative-control` misses 9 breaks on clean HEAD as well. Camera's `chase_rush_check`, which the old flip broke, passes (130).

## The GW1a preview: today's code reproduces the target

Today's code (an export of 1af10db5) with `energy-on.patch`, `../a1-owed/close-rows.patch` and the data of GW1a's target tree (the kept 9 November data with these two switches on) copied over main's data:
- **The golden reproduces GW1a's target byte for byte** (sha256 `a2b9ed1c…`). So once every switch group's data has landed, main's golden is the target.
- `power_check` passes on that data: 0 failed.
- **My other gates don't pass on it yet** (A-CODE-02, the gates that only pass with the switches off):
  - parity fails 9 rows, the golden matches among them. Inside parity's process an earlier row's switches leak into them;
  - `kick_check` fails 2 rows written for the kick off in the data.
  - Records in `docs/sim/runs/1af10db5/gw1a-preview/`.

## Apply

`git -c core.autocrlf=false apply data-power-on.patch energy-on.patch`, on HEAD 78425d6d. Each applies alone. With `../a1-owed/`'s `close-rows.patch` it applies in either order (checked).

| Patch | Owner | sha1 | sha256 starts |
| :--- | :--- | :--- | :--- |
| `data-power-on.patch` (`data/fight/power.json`: `enabled` and `dash.enabled` true, the note) | a grant: the EP lands it with Game Design's flight speed | 778cbae46942252232c620a5458bc3fdbbfa2330 | ab9aca1681ea |
| `energy-on.patch` (6 files: `power.gd`, `hash.gd`, `two_states_check.gd`, `parity.gd`, `power_check.gd`, `kick_check.gd`) | mine | 75fcede6574c0918684feb6bd983011232636e92 | ef516a67cbca |

**The golden moves** (9 matches, 169,765 ticks with this alone on main's data). The window's golden is GW1a's target, which this reproduces once the switch groups land (see the preview below).

## Proof

On 78425d6d (records in `docs/sim/runs/78425d6d/energy-on/`), the re-gate with the fixes:
- The golden regenerated; **parity against it through `gate.mjs`: exit 0**, no SCRIPT ERROR lines. Against HEAD's golden it fails, as it should: every match moves.
- `power_check` through `gate.mjs --verdict`: 0 failed, on main's data with the model and the dash on. Its negative control: 0 failed.
- `two_states` (default, power, dash, slip, fights) and its negative control 3 of 3.
- Rollback (AI), desync, `replay_xproc`, determinism, `kick_check`, `load_split`: all pass.
- Rendering's 15: 14 pass; `after_check` fails 1, as in the table (it passes on HEAD).
- Validator and self-test (no fixture change needed), lint, ratchet 365.
- The first gate on 9431211a ran the other owners' checks above. The baseline on clean HEAD, and the floor probe, are in `summary.txt`.
