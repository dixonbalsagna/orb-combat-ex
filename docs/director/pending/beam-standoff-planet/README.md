# Parked: the beam's stand-off shove works on the planet (a real fault GW1b uncovered)

Encounter, 2026-11-22, from the six director checks that failed on main after GW1b (`docs/director/pending/gw1b-director-checks/`). **It goes on top of that park, and moves the golden, so it lands in a golden window.**

## The fault

A signature fired from under the stand-off kicks the other fighter back to 9 body heights, so the fronts don't meet at their hands (`DirBeamPlay._shove` and `standoffX`). The rule: **"he stops at a wall: ground or a roof that stands above where he's rising to."**

As built, a wall is any floor above his height. That never binds on the hand-made arena, where both fighters stand about 74 units above the floor. **On the planet they start on the ground.**
- In `beam_front_check`'s staging there, the ground beside the rival rises gently: 6, 9, 12 and on to 46 units over 768.
- So the first 32-unit step already meets "a wall", and he isn't moved at all: 58 apart 16 ticks after the fire, against 675 on the arena.
- **On the planet, a beam fired up close on rising or flat-ish ground doesn't push the rival back.**

## The fix (`sim/director/beamplay.gd`, Encounter's)

- `standoffX`: the height he goes at is `y`, or the ground he rides up. A wall is ground or a roof rising steeper than **the wall rule a slide already uses** (`WorldContact.K_WALL`, 0.8) above that height. A roof's edge or a cliff still stops him, and a gentle slope doesn't. There's no new number.
- `_shove`: his rush ends on the ground where it rose under him (`max(D.y, floor at x)`).
- The arena is unchanged: there the ground is always far below.
- The diff also takes `beam_front_check` and `beam_move_check` off the arena pin the staging park gives them, so they test the planet, the shipped default.

## What it does to the gates (main bce578a7 + the staging park + this)

- `beam_front_check` and `beam_move_check` pass on the planet: 58 to 675 apart.
- **45 of 47 director checks pass.**
  - `loader_check` ran out of its 3,000 s on a busy machine (it passes on main in 2,000 to 4,900 s).
  - **`floorlift_check` fails its fight row.** With the shove working, the whole-match computer fight on the planet takes another course. It reaches a free fighter lifted 50.76 units in one tick, with no rush and no exchange (RIVAL at tick 48,826, from 2,005.7 to 2,056.5, the floor at 2,206.5, the ground at 1,951.4).
  - That lift is not the shove's. It's a latent floor case that main's fight never reaches, like the 85.99-unit lift the first cut of the X-06 candidate exposed (`docs/director/pending/x06-bands/`).
- **Parity:** the golden moves (the composed intros, and the swap match from tick 13,680).
- **The look gate applies:** on the planet, a close beam now visibly pushes the rival back.
- Record: `docs/director/runs/bce578a7/beam-standoff-planet/standoff_gates.txt`.

## NEEDS FROM EP

- **World or Simulation:** the free fighter's 50.76-unit lift under the floor in `floorlift_check`'s fight with this fix. Until it's fixed, this park leaves that row red.
- **A golden window,** a re-record and the look gate (a side-by-side of a close beam on the planet).

| Patch | Owner | sha1 |
| :--- | :--- | :--- |
| `beam-standoff-planet.diff` (`sim/director/beamplay.gd`; the arena pin off `beam_front_check` and `beam_move_check`), on top of `gw1b-director-checks.diff` | Encounter | 1b2d0beffcc1c627a995111d210a47e24098b250 |
