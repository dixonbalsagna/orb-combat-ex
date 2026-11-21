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

`gw1b-planet.patch`, sha1 3b09b823400ffbd62fd0e8f7684d6f06d8673557 (`net/desync.gd`, `net/tools/desync_check.gd`). **It applies after `desync-marks` and `desync-fdmg`** (cut on s426's own net files), checked in turn on HEAD e5306b02. It touches only `net/`, so it rides after the flip and needs nothing from it on the arena.

The probes (`probes/`) were scratch scripts in the copy, never in the repo.
