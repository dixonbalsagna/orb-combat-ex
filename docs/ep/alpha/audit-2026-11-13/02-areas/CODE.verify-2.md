# CODE: verifier 2

Read-only check of two findings at commit 8901d351. The cited files are unchanged in the working tree.

| id | verdict | new severity | what I checked | note |
| :--- | :--- | :--- | :--- | :--- |
| F-CODE-13 | corrected | minor | sim/README.md:25; docs/decisions/0006-gdscript-source-of-truth.md:1-23; .github/workflows/ci.yml:45-60, :190-193; CLAUDE.md:56; sim/package.json:5; sim/core/tools/run-all.js:4-10, :27-29; sim/core/roster.js:5 | The substance holds: ADR 0006 line 23 ends the JS-against-GDScript gate, sim/README.md:25 says the frozen record "is not a gate", and CLAUDE.md:56 and sim/package.json:5 still say "parity oracle". One fact is narrow: CI's `npm test --prefix sim` (ci.yml:60) also runs the frozen core against the prototype tick for tick and a 1000-match soak (run-all.js:27-29), not only its own golden record. |
| F-CODE-18 | confirmed | unchanged | tools/preview/switches.mjs:30, :157-169 (five `held:` rows); data/input/timing.json:41; I-08-data-schemas-switches.md:145; read-back of every data-key row of SWITCHES against main's data files | The read-back gives exactly 12 rows at their `to` value on main (rightStick, quickRead, hapticLadder, specialsOff, signatureRtOnly, beamAim, hapticRefused, hapticIncoming, webRumble, nodeWarm, stallKeep, hapticImpact) and 5 held rows at `from` (wallPush, wallPushAi, slamTurn, cityHold, aimCuts). The five held rows do record a pending choice (four wait on QA's city read, one on the next batch's page), so "no choice anyone is making" is strictly true only of the twelve. |
