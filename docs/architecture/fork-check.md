# fork_check: statics a rolled-back branch leaves behind

## The check

`rollback_check` runs its sims in one process, so they share every static, and a table one branch filled is there for the other. This runs fresh processes on one real timeline, a rematch on a field world, and compares them. In one, a 30-tick predicted branch sends a fighter into the ground, and a rollback undoes it. Then the line turns 40°. They must agree on every column's surface (read through `WorldContact.surfaceAt`, so it still works when World's table goes) and on the state after eight landings.

`--negative-control` moves a fighter by a unit in one process, and the compare must catch it. `--location` also compares `DirLocation`'s table.

| Tree | Result |
| :--- | :--- |
| Today's main | `FORK: 3`: the surface differs on planets 7, 12 and 3 |
| With `surfaceAt` called right after `newMatch`, standing in for World's first step | `FORK: 0`, and the negative control catches 3 of 3 |
| Today's main with `--location` | The surface and the location table both differ, on all three |

**The state row is the weaker one:** the eight landings didn't land on a differing column today. `surf_main`, the scratch script before this, showed a state hash differ on planets 7 and 3 by landing on a chosen column. A fix has to pass the surface row.

## The sweep of `sim/`, 2026-11-01

781 static variables outside `tools/` and `test/`. I listed the ones written outside plain loaders, and every function that writes a static and reads the sim's state (36), and read those.

**One more of the same class: `DirLocation._bucketBiome`** (Encounter's). It's built from `WorldBiomes.biomeAt`, keyed on the arena and the world, at the first `roam` of a match, so on a field world it holds whichever line was there. `roam` only runs for an AI fighter, so a player's match never reads it, and in an AI match it usually fills before the first swing. Lower risk than the surface table, but `--location` shows the table differing when the first read moves. It also goes stale after a swing: the hero's AI picks where to lead the fight from the first line.

**No other was found to depend on when it was filled:**

| Statics | Why not |
| :--- | :--- |
| `SimField`'s column memos and `groundCeilAt` | Keyed on the frame's numbers and the store's hash, and they hold only the field and records. `S.deform` and `S.water` are read live |
| `SimField.buildingGround`, `WorldStore._ix`, `waterrec._ix` | Keyed on the store's hash |
| `WorldPlan._memo`, `WorldField` nodes, `WorldPlanet`'s caches | A pure function of planet and place, on a scratch state |
| `DirAlchemy.read`'s memo, `DirData.perfectBlock`, `DirIntro`'s `_flat`, `SimPressRead`, `SimAim` | Keyed on all they read |
| `DirBrawl`'s line frame, `_inTick`, `holding`, `WorldTerrain`'s `rowZ`, `crater._lastLive`, `DirExchange.plan*`, `rally._noDown`, `contact._hk` | Set and cleared inside one call or one tick. A rollback happens between ticks |
| `WorldBiomes.worldId` | Names a world in this process, differs between processes by design, and the hash and the digest skip it. **Nothing may seed from it** |
| `WorldEpoch`'s plans and jobs | Derived, and `two_states` covers the turn |

**How far this goes:** I read the code; I didn't run a fork for each row. The pattern to look for in review: a static filled on first use from `biomeAt`, `groundY`, `baseAt` or a `SimField` read. On a field world those change with the line.

**A cold restore has the same exposure:** restoring a mid-match snapshot in a fresh process builds both tables on the line as it is then. Nothing does that yet, but a reconnect would.

After it lands: delete this folder.
