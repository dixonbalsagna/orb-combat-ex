# Park: gw1b-planet, my checks on the planet (Netcode, 2026-11-21; GW1b re-cut, after the planet flip)

On the EP's GW1b stack (s426: main plus the stand-in's 44 lines plus extras, with the planet flip, so the default match is the round planet), two of my CI checks failed. They passed on the arena. I read both on the planet:

| Check | What was wrong | The re-cut |
| :--- | :--- | :--- |
| `spectator_check --negative-control`: "MISSED flip ... SimHash differs ... after tick 310 (no spectator desync)" | **A real gap in the cheap digest, not staging.** A probe (straight against flipped, slot 1's stick thrown the other way for 12 ticks from 303) shows SimHash differing from tick 310 to 580, while the digest was the same at every checkpoint in between (360, 420, 480, 540). The field walk at 360 finds the difference only in fighter 1's **director integers** (`act.dirI`: stamps and counters, indices 14 and 64 to 66). SimHash hashes them; the digest never read them. On the arena the same flip also moved the fighter (which the digest reads), so the gap never showed | **The digest reads each fighter's `act.dirI`** as SimHash does: the sizes with the other numbers, then the arrays as blocks into the MD5 (`net/desync.gd`). `NetDesync.dirIBlind` is a test switch. Detection is wider, not looser |
| `desync_check` (default): "injection director healed every time: it tested nothing" | **Staging.** On the planet the director's cool-down resets before the next checkpoint: the divergent peer's full SimHash equals the straight run's again at 240, so there's nothing to detect. A probe of five changes after tick 207: the cool-down and one director integer heal; the stop timer, the exchange count and another integer persist, and the new digest sees each | **On a planet match the director's injection is its stop timer**, the same size (1e-6), which the cool-down's reset doesn't touch (`desync_check._fieldWorld`, `net/tools/desync_check.gd`). The arena keeps the cool-down, still caught to the bit |

Proof (`docs/net/runs/e5306b02/gw1b-planet/`):
- **On a copy of s426:** the two failures reproduced before the re-cut. With it, **all 45 of my CI lines** (every `res://net/tools` line in its ci.yml but `enet_check`) pass: exit 0, 0 SCRIPT ERROR, at most 3 Godot processes, below normal. The spectator control catches 5 of 5, the flip on every profile. desync detects the director at 240 on the planet.
- **Causality:** the spectator control with `dirIBlind` (the digest as it was) misses the flip again on all three profiles. So the new digest lines are what catch it.
- **The arena** (main, desync-marks, desync-fdmg and this park; no flip): desync and its control, the spectator control (5 of 5), rollback. All pass, and the director is still the cool-down.

## Re-cut for the stand-in's landing review (N-1, N-2), 2026-11-21

**N-1, the protocol number: bumped, 5 to 6** (`net/handshake.gd`). Nothing else refuses a mismatched build:
- The hello compares the protocol number (`net/handshake.gd:82`, a different `v` fails the handshake) and the match key.
- The key is the seed, the AI, the setup and `SimReplay.dataHash(setup)` (`:112`), so it catches different data but not a code-only change.
- The GW1b digest changes are code only: marks and floor damage (desync-marks, desync-fdmg), the director's integers, and the fighter fields below. So a GW1a build and a GW1b build would pair up and then report false desyncs.
- With PROTO 6 they refuse each other at the hello. The one bump covers all three GW1b digest parks.
- The A3 setup-in-hello plan in `docs/net/a1-wave2.md` and `docs/net/planet-sizes-net.md` moves to PROTO 7.

**N-2, fighter fields SimHash reads and the digest didn't: all added, none left out.** Covering them is cheaper and surer than arguing each one is safe. `NetDesync._fighterRest`, in SimHash's fighter-block order, takes:
- **Scalars:** launchPower, wetT, ctrlT, skateV, skateDir, skateTv, boon, brink, stunTicks, wallZ, rally, rallied, rallies, rallyCool, breathWear, id, sigReadyT, limbBreaks, brinkSetups, brinkOpen, brinkEx, flightHits.
- **The rush:** its target, then off, end, arc, x0, y0, dur, loop, lr, lm, lu, ls, px, py, pz.
- **Who launched him, and where he was last seen:** launchBy; lastSeen x and y.
- **The intent's first word** (`SimHash.INTENT`).
- **Wounds:** wear and stage, all four regions.
- **The tower chain** while inside one (interior).
- **The act:** v2, guardSince, dodgeTick, dodgeCool, burstCool, mode, assist, formReady, burstFired, breakIn, flow.
- **Records while their switch is on:** the brake, forms, flight and ricochet, each by its own `HASHED` list.
- **Lists:** the act's queue, splashed, and the style (its six arrays and nine fields).

The digest already read FIGHTER, the AI's timers, the second word, the kick, the slip and (this park) the director's integers. Where SimHash appends a value only while it's set, the digest takes it always: its numbers needn't match an older digest, since PROTO 6.
- **The coverage row** (`desync_check._coverage`, in its default and setup runs): a match to tick 300 with the bots, then each of fighter 1's fields changed once on that live state. **56 of 56 move the digest.** It fails if any field doesn't, or if fewer than 40 were tried.
- **Its control** (`--negative-control`): with `NetDesync.restBlind`, the digest as it was, the row finds 56 of 56 that don't move it (caught).
- **Not fighter fields, so outside N-2:** SimHash also reads `S.world`'s match counters. Say if they should follow.

`gw1b-planet.patch`, sha1 387607e0ad00aaa9b7ae7830da428bec5c1968f7. It now covers `net/desync.gd`, `net/handshake.gd`, `net/tools/desync_check.gd` and the two docs. **It applies after `desync-marks` and `desync-fdmg`**, checked in turn on HEAD c304e2ed. Net and docs only, so it rides after the flip.
- **On a copy of s426, which already had the first cut:** all 45 of my CI lines pass, exit 0, 0 SCRIPT ERROR (`docs/net/runs/812627d6/gw1b-planet-n12/`).
- **The first cut's records** stay in `docs/net/runs/e5306b02/gw1b-planet/`.

The probes (`probes/`) were scratch scripts in the copy, never in the repo.
