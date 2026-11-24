# Parked: a replay of a sized planet plays anywhere (support for World's five planet sizes)

Simulation, 2026-11-14, sprint A1 (the EP's order 5: support World on the five planet sizes). **Re-cut 2026-11-23 for World's hold on tiny, small and huge** (below). It applies after World's `globe-step2` and `planet-sizes` (`docs/world/pending/`), because it reads `WorldPlanetSize`. `a-world-01` is on main since GW1b.

## The fault, found with World's park applied

`SimReplay.dataHash` takes a gen-3 planet's field hashes (`SimField.dataHash`, `SimField.keyHash`) at whatever size the host's static (`SimConst.PLANET_NC`, a per-match static with World's park) last held.
- A replay of a match on a big or a tiny planet, played by a host that last played medium (a fresh process, or after any medium match), was **refused as "data" before its first tick**.
- The LAN handshake compares the same hash, so two PCs on different static sizes would disagree the same way.
- Before the fix, on World's stack (`size_replay_probe`): big and tiny were both refused, and each header taken again at medium differed.

## The fix

- `dataHash` binds the setup's own size (`WorldPlanetSize.colsOf(setup)`) around the planet's part of the header, and puts the host's static back after. So a header is made, and checked, at the match's own size.
- **The size table is in the header** when a setup names a size (`planetSize`), so a replay recorded before a change to `sizes.json` is refused as "data", not played on a different planet. A setup that names none (medium) hashes exactly as before.
- **Parity's new row:** a replay of 60 ticks on a tiny planet, played by a host bound to medium, plays to its last tick. Its header is the same taken at either static. A changed size table refuses it. The host's static is as it was.

## The re-cut for World's hold (2026-11-23)

World holds tiny, small and huge: `offered: false`, so a setup that names one plays medium unless the test-only `WorldPlanetSize.heldOverride` is set.
- **The header hashes `WorldPlanetSize.hashData()`**, which is the size table without `offered`. So un-hiding a held size later moves no replay's header.
- **The parity row runs with `heldOverride` on** (it names tiny) and puts the previous value back. It also asks one more thing: flipping a size's `offered` doesn't move a sized replay's header.
- **The parity hunk is re-cut on today's main**; the old one failed at line 111. The `replay.gd` hunk is as it was, apart from that one word.

## Apply

On main with World's GW1c stage-2 list (`docs/world/planet-stack-recut.md`, its order), at any point after `planet-sizes.diff`: `git -c core.autocrlf=false apply replay-sizes.patch`. Checked straight after `planet-sizes.diff` (with Rendering's field-memo grant and VFX's meteor patch) and after the whole stage-2 list, on main d0e48be5.

| Patch | Files | sha1 | sha256 starts |
| :--- | :--- | :--- | :--- |
| `replay-sizes.patch` | `sim/core/replay.gd`, `sim/core/tools/parity.gd` | 13143eb17184d8df8c712141470d9b20de3099d9 | 9f85e794daf7 |

## Proof

**The re-cut** (records in `docs/sim/runs/d0e48be5/replay-sizes-hold/`), on main d0e48be5 with World's whole stage-2 list. Every piece applied strictly in order; `gw1b-w1-w2` is already on main.
- **The re-cut moves nothing:** the golden made on the stack alone and on the stack with this patch is one file.
- **Parity through `gate.mjs`: 83 rows ok, 5 failed. All five are the stack's golden move** (below), not this patch: tick-0 state, the intro phase (golden), composed intros (golden), matches, planet worlds (golden). The new row is ok, and so is every other row.
- **Negative control:** with the header back on `WorldPlanetSize.data()`, the row fails ("un-hiding a size moves a sized replay's header"). With `hashData()` it passes.
- World's `SIZES` check: 0 failed (its replay rows and its "the flip moves no hash" row included). `replay_xproc_check`: pass. Rendering's 15: all pass.

**Found on the way, for the EP and World:** World's GW1c stage-2 stack moves main's golden (`golden_moves_stack.txt`):
- the tick-0 states, the intro and composed intro hashes, all 7 planet matches from tick 0, and the planet match (seed 29) from tick 0;
- the two arena matches, both replays and the planet slices don't move.

Since GW1b's flip a match that names no world plays planet 7, so World's planet changes now reach the golden. GW1c needs its own re-record.

**The first cut** (2026-11-14, on bf6c4538 with World's three parks; records in `docs/sim/runs/bf6c4538/replay-sizes/`): golden unchanged, parity exit 0, `SIZES` 0 failed, `replay_xproc` pass, `size_replay_probe` big and tiny play back (both refused before the fix), Rendering's 15 pass.
