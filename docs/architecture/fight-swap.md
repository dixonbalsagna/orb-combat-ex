# Two fights on one line: the fight swap

Simulation, 2026-11-01, for Orb's versus and co-op structure. The plan is `two-v-two-globe.md`, the rules are Game Design's `docs/design/two-v-two.md`, and the mechanism is the one Encounter and I agreed in `docs/director/two-fights-sizing.md`.

**The setup:** `{"fights": 2}`, on a field world or any other. Slots can be left out (the roster's first two, twice), or be four ids. Slots 0 and 1 are the first fight, slots 2 and 3 the second, half a ring away. The second pair are the computer's unless the setup's `ai` says otherwise. **Any other match has `S.stage` null and runs what it ran.**

## How it works

Each fight is a plain 1v1 to everything that reads `S`: its pair in `S.fighters`, its director, its clock, its holds. `SimStage.enter(S, i)` swaps fight i's fields into `S`. `SimCore._stepFights` runs the line's tick once, then each fight's tick in slot order, then puts fight 0 back. So between ticks `S` holds fight 0, and whatever reads `S` then, the drawing included, sees the first fight.

| A fight's own | Everyone's |
| :--- | :--- |
| `fighters`, `dirS`, `T`, `dt`, `rng`, `game` (with its seed), `beams`, `shots`, `shotSeq`, `mood`, `pause`, `hs`, `cata`, `out` | The line (`frame`, `swing`), the planet and its store, `deform`, `water`, `scorch`, `crack`, the buildings, the trees, `craters`, `slides` |
| `world`: its people and budget, so one fight's losses don't feed the other's menace | `S.tick`: the same count for both |
| `popHist`: what its AI lures by | |
| `waterWin`, `waterTick`, `aftermathJobs`: the windows it opened, on its own clock. The water itself is shared | |
| `epoch`: the calm turn stays with fight 0 | |

**Holds.** `S.dirS.stop` is a fight's, so every writer already holds the right fight, with no change to any of them. A signature's or a form's pause is the same, through `S.pause`. Each fight has its own hit-stop budget.

**The record of the fight in `S` holds blanks.** No array is in two places, which is what a rollback snapshot needs. A snapshot walks `S.stage` by itself, as it does any class of the state. A fight's `out` isn't in it, like `S.out`, and it's cleared at that fight's tick.

**The line.** It belongs to no fight's clock. It ticks once, ahead of the fights, while any fight is running. For its length `S.fighters` is everyone, so all four stay on the floor as it turns, and the sweep limit answers to all four. Its pivot is their middle.

**Apart.** Game Design's rule, with the EP's number: a swing starts only if everyone's within `apartReach` (`data/fight/swing.json`, 4,000 units) of the middle, and one under way rests when someone leaves. `DirSwing.on` asks the same, so a director with its swing switch on plans as if it were off.

**Changing fights.** `SimStage.trade(S, a, b)` has two bodies change places, each taking the other's slot, so each fight stays a pair and its director needs nothing new. Every time a body carries (`STAMPS`, a beam's charge, a rush's end) moves by the difference between the clocks. It's refused while either fight has something that names a slot or a fighter: an exchange, a clash, a beam, a shot, a pause, a KO, a launch. A real tag, and one fight of three, is Encounter's side.

**The hash and the digest** walk fight 0 and the world, then each other fight.

## What it doesn't do yet

- **Bodies don't meet.** A blow, a shot or a beam reaches only its own fight. Game Design's "every blow can reach any enemy" comes after this.
- **The intro** holds both fights and only plays fight 0's. Use `"intro": false`.
- **The picture** is fight 0's. Fight 1's fighters and events are readable in `S.stage.fights[1]`, and nothing reads them yet.
- **The AI only.** Two fights' inputs are `inputs[0..1]` and `inputs[2..3]`, and the net session sends the first two.
- **Shared arrays, own clocks.** `aftermathT` is stamped by the water clock of whichever fight wrote it, so two fights on the same columns would read each other's stamps wrongly. They aren't there while apart.

## One thing to know: the line's anchor

At rest the line's numbers are put back on fight 0's pair as it travels (`_anchorAtRest`, every eighth of the ring). That moves far ground reads in the last digits, so **fight 1 can hang on fight 0 by about 1e-13 units**. It's the same on every machine and in every replay, so it isn't a desync. It's why `fights_check`'s independence test blinds the anchor (`SimSwing.anchorBlind`). With it blinded, fight 1 is identical with fight 0 fighting or idle, on all six runs. Unblinded, two of the six differed in the last digits, at ticks 1722 and 2635.

The anchor also puts x0 about half a ring from fight 1, so the strip's wrap is under fight 1. A read across it doesn't jump: 0.002 units either side, a point moves 0.000000138 on the unit sphere and the ground 0.0000, and a fighter walks across with at most 0.09 units of height in a tick.

## Proof

`sim/core/tools/fights_check.gd` (`--long` for 3,600 ticks, the default is 1,800; `--negative-control` for its planted break), verdict line `FIGHTS: n check(s) failed`.

| Test | Result, `--long` |
| :--- | :--- |
| Fight 0 against a plain 1v1, 3 worlds, 3 seeds, 3,600 ticks | **Identical on every tick** (clock, hold, RNG, both fighters' position, HP, ki, state). The fights were never close |
| The same with the director's swing switch on | Identical, 0 ticks of swing |
| Each fight's holds stop only its own clock | Fight 0 held 456 to 843 ticks, 365 to 644 of them with fight 1 running; the other way round, 414 to 817 and 340 to 667. The clocks end up to 4.2 s apart |
| Fight 1 fights | 181 to 418 blows a run |
| Two runs, two processes | One hash and one digest |
| Rollback across holds, flat and field | 700 ticks, 0 differ, by hash and digest |
| Rollback across a swing | 60 ticks, 34 of them swinging, 0 differ |
| A trade on clocks 3.02 s apart | The rush ends on its tick (60 and 60), and the cooldown has what it had left |
| Apart | No swing apart, a swing together, and one under way rested 15 ticks after a fighter left |
| The hash and digest see fight 1 | Its fighters and its clock, and reading writes nothing |
| Fight 1 with fight 0 fighting or idle, anchor blinded, 3 worlds, 2 seeds | Identical on every tick |
| The negative control | A planted draw shows on its tick, and in the hash and digest after a restore |

**Cost,** rough, on a loaded PC, the sim alone on a field world: a plain 1v1 averages 365 µs a tick (worst 3.7 ms), two fights 727 µs (worst 4.8 ms). That's about double, as you'd expect, with the swap itself too small to see.

On a four-fighter setup: `two_states_check --setups=fights` (now in its default list), `rollback_check --setup=fights` (lan and p120, 1,200 comparisons), and `render/tools/determinism.gd --fights` (60 Hz, 144 Hz, jitter): all pass.
