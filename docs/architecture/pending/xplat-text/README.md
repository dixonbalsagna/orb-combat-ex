# Parked: text the golden hashes reads the same on every platform (main red after GW1b, CI run 45046244728)

Simulation, 2026-11-22. GW1b landed (7b69eafc..b624340a) and CI went red: parity's "matches" row failed for swap-flip seed 2 and mirror-villain-flip seed 2 ("checkpoints agree: the difference is between checkpoints, in the feed text or in the fx events"). Web parity was red too.

## What was wrong

**The sim is identical on every platform. A debug line's text wasn't.**
- The swing planner's line in the fight feed formats its scores with `"%.1f"` (`sim/director/swing.gd`, `_n()`).
- Windows Godot's printf rounds an exact half away from zero. glibc (Linux) and musl (the web build) round it to even. A score of exactly -22.25 read "-22.3" on Windows and "-22.2" on Linux and the web.
- Swing scores land on x.25 often. On the planet that happened 20 times in swap-flip seed 2 and 15 times in mirror-villain-flip seed 2.
- Feed text goes into the golden's per-tick digest, but never back into the sim. That's why every checkpoint agreed.
- **Proof** (`docs/sim/runs/e14136a3/xplat-text/proof.txt`): the two matches re-run on Windows with only `_n()` rounding x.25 the Linux way give CI's digests exactly (c1b9f67b806bc6d7 and be6df1cf39c74ba6). The other seven matches have no such tie.

**A second fault, in my web parity probe** (`sim/core/tools/web_parity.gd`):
- It ran the golden's matches and replays without their recorded setup. Since GW1b, two matches and both scripted replays name the hand-made arena, so the probe played them on the planet, and they differed from tick 0.
- Its "planet: slices" was the same miss. `planetSlices()` named no generation and read the one in force, which is whatever the last match left. A planet match leaves 3, an arena match leaves none (the data's 2). build() runs the arena replays just before it; the probe ran its replays on the planet.
- **This is run order inside a test process, not a leak into a game.** Every match sets its generation as it starts (`WorldClimate.genFor(setup)`).

## The fix

| Patch | Files | Owner | sha1 | sha256 starts |
| :--- | :--- | :--- | :--- | :--- |
| `xplat.patch` | `sim/core/mathx.gd`, `sim/core/tools/{golden_recipes,parity,web_parity}.gd`, `sim/core/test/golden.json` | mine | 808517d21c9b7ac59ec5ec5d4bb7a19416a84a10 | 787a3531d233 |
| `grant-encounter-swing.patch` | `sim/director/swing.gd` (one line) | Encounter, as a grant (approved by the EP) | 53cc52f48850697e8c97aaaed65d88eaaee336c4 | 64b3c562ddae |

Apply on main e14136a3 (checked): `git -c core.autocrlf=false apply grant-encounter-swing.patch xplat.patch`.

- **`SimMathx.fixed(v, n)`**: a float as n-decimal text, the same on every platform. It uses printf for every value except an exact half, which it rounds to even itself, as glibc and musl do. So Windows now prints what Linux and the web already printed. The half test is exact: it scales by a power of two.
- **The swing line** (`DirSwing._n`) uses it.
- **One place each for a golden match and a golden replay** (`SimGolden.matchEntry`, `replayEntry`, `REPLAYS`). build() and web_parity.gd both run them, so the probe can't drift from the golden again.
- **`planetSlices()` names its generation** (2, the one the golden's slices were made with) and puts the one in force back.
- **Parity:**
  - a new row, "a number with decimals reads the same on every platform": `SimMathx.fixed` on halves and non-halves, and the swing line through it. On Linux and the web it holds with or without the fix; on Windows it fails without it;
  - the planet row also reads the slices with a planet match's generation left in force.
- **The golden: two values move, nothing else.** `matches[5].light` a8c663b84748e0be → c1b9f67b806bc6d7 and `matches[6].light` 69140510d1d9f971 → be6df1cf39c74ba6, exactly CI's Linux values (`golden_diff.txt`).

## Proof (records: `docs/sim/runs/e14136a3/xplat-text/`)

- On a clean export of main e14136a3 with both patches: import clean. The golden made from a cold cache differs from main's in exactly those two values.
- **Parity exit 0 through `gate.mjs`**: 87 rows, the new row and "planet worlds (golden)" included, no SCRIPT ERROR lines.
- **Not run here:**
  - the web parity workflow on the new golden (running locally next; CI runs it on the push);
  - Rendering's 15 (the change is a feed line's text and test tools; no state, view or camera hash reads it).

## Not changed, said for the record

- Encounter's two other feed lines that show decimals, brawl.gd's "pops up" and recoil.gd's "recoils", print `str(snappedf(...))`. A snapped value at 14 decimals is never an exact half, so they read alike everywhere.
- The other `"%.Nf"` uses in sim code feed no hashed text: World's campaign notes and its settlement load errors, and Netcode's LAN lines.
- A determinism lint rule for `"%.Nf"` in sim text, pointing to `SimMathx.fixed`, would be Tools' to add (`tools/lint-determinism.mjs`).
