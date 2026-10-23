# The determinism lint (parked: not wired into CI yet)

Owner: Tools. 2026-10-23. The EP's brief after two slips in one week (World's epoch.gd `sin`/`PI`, Encounter's calm.gd `sin(deg_to_rad)`): the simulation must use our own math, RNG and clock, never the engine's.

## What it does

`node tools/lint-determinism.mjs [--all] [--json] [--allow <file>]` scans every `.gd` file under `sim/core`, `sim/director`, `sim/world` and `sim/input` (not their `tools/` and `test/` folders, which are headless checks outside a match; `--all` includes them) and fails (exit 1) on a **bare** use of:

| Rule | Finds |
| :--- | :--- |
| `engine-trig` | `sin cos tan asin acos atan atan2 sinh cosh tanh deg_to_rad rad_to_deg` |
| `engine-pi` | `PI`, `TAU` |
| `engine-random` | `randf randi randf_range randi_range randfn rand_range randomize`, `.shuffle()`, `.pick_random()`, `RandomNumberGenerator` |
| `engine-clock` | `Time.*`, `OS.get_ticks_msec/usec`, `OS.get_unix_time`, `OS.get_system_time_*`, `OS.get_datetime/get_time`, `OS.delay_*`, `Engine.get_frames_drawn/get_physics_frames` |
| `engine-vector-trig` | `.angle() .angle_to() .angle_to_point() .rotated() .from_angle() .slerp() .looking_at()`, `lerp_angle`, `rotate_toward` (sin, cos and atan2 inside) |
| `waiver-reason` | a `# det-ok:` with no reason |

"Bare" means not after a dot or a name: `SimDetMath.sin(x)`, `SimMathx.PI`, `rng.randf()`, `WorldPlanet.acosf(x)`, `_PI` (the sim's own, from its bits) all pass. A definition (`static func sin(x)`) is not a use. Comments and the inside of strings are ignored.

**Allowed:** a single line with `# det-ok: <reason>` on it or on the line directly above (a reason is required); a whole file listed in `tools/determinism-allow.json` (empty today: the wrappers SimDetMath, SimMathx and SimRng are clean, so they are scanned too and a regression inside one fails).

Self-test: `node tools/lint-determinism-selftest.mjs` (67 checks: every kind found, our wrappers, comments, strings and definitions not, the waiver, the folders scanned and skipped, the allow list).

## Today's hits on main (e09dbbbf plus the working tree)

24 hits in 7 files. **All are the constant `PI`/`TAU`; no engine trig, random number or clock is in the sim.** The value is the same double on every platform (0x400921fb54442d18, what `calm.gd` and `epoch.gd` build with `SimMathx.f64`), so none changes a result today: they break the rule, not the numbers. Switching them is mechanical (`_PI`/`_TAU` from bits as epoch.gd does, or one shared constant).

| Owner | File | Lines |
| :--- | :--- | :--- |
| Encounter | sim/director/beamplay.gd | 241, 261, 266 |
| Encounter | sim/director/launch.gd | 85 |
| Encounter | sim/director/zip.gd | 603 |
| World | sim/world/contact.gd | 302 (`TAU`) |
| World | sim/world/planet.gd | 89, 98, 107, 108, 110, 112, 291, 441, 509, 622 |
| World | sim/world/ringpick.gd | 175, 182, 217, 241, 267, 270, 451 |
| World | sim/world/terrain.gd | 53 |

sim/core and sim/input have none. Suggestion for the EP (Simulation's file, not mine): one shared `SimMathx.PI` / `SimMathx.TAU` built from bits would make each fix a one-word edit and give the lint a name to point to.

## To wire it (parked until the 24 are cleared, or the owners waive them), in one commit

1. `.github/workflows/ci.yml`, in the data job beside the validator, two steps:
   ```
   - name: Determinism lint self-test
     run: node tools/lint-determinism-selftest.mjs
   - name: Determinism lint (no engine trig, PI, random numbers or clock in the sim)
     run: node tools/lint-determinism.mjs
   ```
2. Nothing in `validate.js`: the lint reads GDScript, not data, so it stays its own command (validate's job is data).
