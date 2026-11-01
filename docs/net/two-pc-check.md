# Do two PCs' processors agree?

Netcode, 2026-11-01. LAN play only works if two different processors compute exactly the same match. This checks that with **no network: no socket, no port, no firewall box.** Each PC plays the same match with no picture and writes its check numbers to a small file, and then the two files are compared.

## Running it

`node net/tools/two_pc_kit.mjs --out=FOLDER --godot=PATH\Godot_v4.7.2-stable_win64_console.exe --build=<commit>` makes a folder of about 184 MB: Godot's console build, `sim/`, `data/`, `net/`, and two double-click files. Run it on a tree that has been imported (`godot --headless --path . --import`), and on one with World's rematch fix (`contact-surf-derive`).

1. Copy the folder to each PC. Double-click `run-on-this-pc.cmd`, which takes under a minute on a fast PC, at below-normal priority. It writes `report-<a random number>.txt`. Legal RL-230 clears this check while it stays headless and its report names no person, account or address: only the CPU, the OS and numbers. So the file isn't named for the PC either.
2. Put exactly two reports in one folder and double-click `compare-two-reports.cmd`. On the command line: `--compare=A,B`.

| It says | Exit | Meaning |
| :--- | ---: | :--- |
| `THE SAME` | 0 | The two processors agree on every line |
| `DIFFERENT: ... first disagree in match A at tick 540, in: digest, state hash` | 1 | **A real finding.** Bring both reports to Netcode |
| `DIFFERENT: a report is cut short` | 1 | A run was stopped, or a file was damaged in copying |
| `NOT COMPARABLE: data differs` | 2 | They weren't from one kit. Says nothing about processors |

## What's played

One process, as the game's host plays it (one `SimState`, a second `newMatch` on it), on planet 7, `planetGen` 3, whole planet, with the tree's own data switches:

- **The match:** seed 77, the sim's AI on both sides, 3,600 ticks.
- **The rematch:** seed 78, a `NetBot` against the AI, 1,800 ticks.
- **In both:** a scripted turn of the line every 300 ticks, 17 in all, since `DirSwing` is off in the data today.

## The report

Plain text, about 14 KB, one fact to a line. Performance's page can carry it as it is.

```
format 1
build <commit>            must match
godot 4.7.2-stable        must match
proto 5                   must match
data <hash>               must match
setup <json>              must match
cpu ...                   read only, from here to the ---
cores 16
os Windows
ticks 5400
swings 17
tick_ms mean 1.225 worst 42.7
snapshot_ms take 0.43 restore 0.40
---
A 60 <digest> <state hash> <feed and fx> <fighters' x and y, raw bytes>
...
B 1800 ...
end
```

Everything below `---` must match byte for byte. A plain file compare would do too, as long as it skips the read-only lines. **`tick_ms` and `snapshot_ms` are the old PC's first real numbers for rollback.** They're readings, and only count if nothing else was running.

## The tests

Both run in fresh processes and print `TWO_PC: N check(s) failed`.

**`--self-test`:** two clean runs agree, and a rematch equals the same match played first in a fresh process, so the first match leaves nothing behind.

**`--negative-control`,** each must be caught:

| Break | Caught as |
| :--- | :--- |
| One ulp of a fighter's hit points at tick 500 | DIFFERENT, at tick 540 |
| A number changed in the data | NOT COMPARABLE |
| One digit changed in a report | DIFFERENT |
| A report cut short | DIFFERENT |
| A report from another build | NOT COMPARABLE |

A report made by the kit and one made from the project folder, with the same build name, agree on all 90 lines.

## What it doesn't show

- **It has only ever run on this PC.** Nobody has seen two different processors agree yet. That's the point of running it.
- **It uses Godot's console build, not the game's exported one.** Both PCs run the same file, which rules out two builds differing. The Linux desktop build's bench has already matched the project's hash, which is a good sign for the exported build, not proof.
- **A pass isn't proof for every match.** It's two matches on one planet. A difference that only one kind of fight reaches could still be there.
- **A rollback isn't in it.** Both PCs run the same timeline here, so a table one branch fills is `fork_check`'s job, and it stays there.
- **A failure doesn't name the field,** only the tick and which number. Finding it takes a second run with a dump, which isn't built.
