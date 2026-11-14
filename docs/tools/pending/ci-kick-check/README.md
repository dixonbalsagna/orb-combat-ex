# ci-kick-check (Tools, 2026-11-01): the kick check's CI step, landing WITH the kick

`git -c core.autocrlf=false apply docs/tools/pending/ci-kick-check/ci-kick-check.patch` (`.github/workflows/ci.yml`, one step after the two-states check, through `tools/gate.mjs --verdict`): `sim/core/tools/kick_check.gd`, Simulation's check of the kick and the coin turn (each row of the table, two runs with one hash, a rollback across kicks and plants, off equals no word of it). It ends on `KICK: N check(s) failed`, which `--verdict` reads, so a run that quits early fails too.

**The file arrives with Simulation's kick (`docs/architecture/pending/kick/kick.patch` adds it), so this lands with that park, not before**: a CI step for a missing script fails. The step sits away from the tile check's step, so the two CI patches apply in either order. `check-workflows` passes with both on; it reverses clean.

The schema, the map row, the four cases and the fixture are in `kick.patch` (the grant to Tools is given), not here.
