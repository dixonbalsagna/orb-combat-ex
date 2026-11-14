# Parked: my gates on the 9 November data (A-CODE-02, parity and kick_check)

Simulation, 2026-11-14, sprint A1. The GW1a preview showed today's code reproducing the target golden on the 9 November data, but parity failing 9 rows and `kick_check` 2 on that data. **This park makes both pass on main's data now and on the 9 November data.** It's test-only (no sim code, no data), so the golden doesn't move. **It lands with or before the first switch group in GW1a,** after `../a1-owed/close-rows.patch` and `../energy-on/` (it's cut on top of both).

## The leak, and the rows written for switches off

- **A leak.** Parity's spawn-floor row switched the water's surface and floor on, then put the floor back to a hard-coded *off*.
  - On main's data, where it is off, nobody noticed.
  - On the 9 November data, where it's on, every later row, the golden matches among them, ran with the floor off. "matches" differed from tick 11,280.
  - **The row now reads its three switches (surface, floor, the director's water), sets them off itself for its "floor off" part, and puts back what it found.**
- **Rows written for switches off now name what they test:**
  - the plain lag's read: the kick off (its takeoff isn't the lag);
  - hit-stop by weight, off and on alone: the budget on any table off (with it on, the window exists and its floor of 1 replaces the table's);
  - hit-stop's replay key: the budget off on both sides.
- **Rows that now read the data's own switch:**
  - the ring turn's header: a setup with no turn key turns as `rings.json` says;
  - Animation's view field: the event's stop counts whole ticks whenever the budget's window is there;
  - `kick_check`: "a match with no word takes the data's switch", and plays as it says.
- **The run's and the campaign's rows run on the world switches they were built on** (generation 1, the ring's turn off, the water's floor and surface off), put back after. Their pinned seeds and places were written for main's world.
  - The cross-back row searches from its pinned arc for the first arc that passes in full: column 2's untaken place asked, then offered and leading at column 4. On main that's still the pinned one.
  - **A finding for World, for when the campaign comes back** (it isn't in Alpha, Orb's decision 7): on the 9 November data, a seeded arc's cross-back place (arc 0bac000000017335, place 9) is asked but not offered at column 4. It holds even on main's world switches, so it's the fight data (which places an episode takes), not the world. The row now searches for an arc that passes in full, and prints the first asked-but-not-offered arc as a note for World. Searching only for an arc that leaves a place untaken would hide exactly what the row exists to catch.

## Apply

After `../a1-owed/close-rows.patch` and `../energy-on/` (both patches): `git -c core.autocrlf=false apply gates.patch`.

| Patch | Files | sha1 | sha256 starts |
| :--- | :--- | :--- | :--- |
| `gates.patch` | `sim/core/tools/parity.gd`, `sim/core/tools/kick_check.gd` | 379a064e4cfbb7a96dccc602d9892d745b9749ac | cae2ebb86c57 |

## Proof

Records in `docs/sim/runs/4f06e7a3/gates-shipped/` (four runs as the fixes went in; the last is the final patch). Cut on 4f06e7a3 on top of close-rows and energy-on, and checked again on b82a243d: it applies and reproduces the tested files.
- **Main's data with the model on:** parity through `gate.mjs` against its regenerated golden, exit 0, no SCRIPT ERROR lines. `kick_check` and `power_check` 0 failed.
- **The 9 November data (GW1a's target tree's data):**
  - the golden reproduces GW1a's target byte for byte;
  - **parity against the target, exit 0** (it was 9 failing rows), with the World note above printed;
  - `kick_check` (it was 2 failing rows) and `power_check` 0 failed.
- Rendering's 15 on main's data with the model on: 14 pass; `after_check` is Rendering's energy-model row, re-scripted in their own park.
- Validator, lint. Test files only: no sim code, no data.
