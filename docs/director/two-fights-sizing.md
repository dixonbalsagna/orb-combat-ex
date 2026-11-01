# Two fights on one globe: sizing

Encounter, 2026-11-01. **Paper only: nothing is built.** Orb's order (`docs/ep/vision.md`) is versus on the globe, with the structure tuned toward LAN co-op. This covers two exchanges at once, and both humans against computer fighters with both fights on one globe.

## The answer

**Don't make `S.dirS.ex` an array. Step the match one fight at a time, on a shared world.**

| Shape | What changes | My sessions |
| :--- | :--- | :--- |
| An array of exchanges | Every read of the exchange, plus everything that assumes the pair | Not sized, and I don't recommend it |
| **One fight at a time (recommended)** | One function swaps a fight's state into `S`, and the step runs once for each fight | **2 for the director** |

**My number:** 2 sessions of mine and 1 to 2 of Simulation's for two fights stepping side by side, so **3 to 4 in all, on the low end of Netcode's 3 to 5.** That number **doesn't cover a second line across the globe**, which is World's to size and is the larger unknown (see below). It also leaves out the render and split-screen work.

## Why not an array

On the stack through row 1, not counting tools and tests, `dirS.ex` is read on **174 lines in 40 files**:

| Where | Lines | Files |
| :--- | :--- | :--- |
| `sim/director` | 135 | 25 |
| `sim/core` | 11 | 8 |
| `render` | 26 | 6 |
| `ui` | 2 | 1 |

The EP's 111 in 26 was a lower count of the same thing. The exchange is also not the only single-fight assumption. `S.dirS.stop` (the hit-stop) is read 81 times, `SimRoster.opp` is called 74 times, and `S.fighters[0]` and `[1]` are used directly. An array would change all of those call by call, across Animation's, VFX's and Rendering's code.

## The shape

A **fight** holds what belongs to one pair. `SimStage.enter(S, i)` puts fight `i`'s state into the fields of `S`, and the step runs as it does today:

```
world tick, once
for each fight, in a fixed order:
    enter(S, i)
    the fighters, the director, the beams, the shots, the mood
    leave
```

Every existing read then means "the fight being stepped", with no change at the call.

**Swapped per fight:**

| Field | Why |
| :--- | :--- |
| `S.fighters` | The pair, with any guards. `opp`, `[0]`, `[1]` and the state my parks keep on `fighters[0]` all follow |
| `S.dirS` | The exchange, the hit-stop and the variety counts |
| `S.T` | The fight's own live clock. A big hit freezes that fight, not the other side of the planet |
| `S.game` | KO, clash and time scale, **and the seed.** Keyed draws use seed, key and `exN`, so a seed per fight stops the two fights drawing the same numbers |
| `S.beams`, `S.shots` | A blast meets only its own fight's bodies, for the first cut |
| `S.mood`, `S.pause`, `S.hs` | Each fight's mood, set-piece pause and freeze budget |
| `S.out` | Events by fight: `e.target` is a slot in the fight, so render and audio need to know which |

**Shared, once:** the planet, its stored damage, buildings, civilians and water.

## What needs real work

1. **The second line across the globe (World and Simulation).** A fight lives on one line: `S.frame` and `SimField.cur`, with its columns, buildings and trees baked along that line. Two fights on one globe need two lines baked at once, both reading one stored planet. The swing already re-bakes one line as it turns, so the pieces exist, but holding two at once **costs twice the memory and bake time on the old-laptop budget.** World should size this. I can't.
2. **Statics in my code.** `sim/director` has 112 `static var`s. Most are data caches or tool switches, but some are per-fight:
   - The brawl's frame (`_frA`, `_frD` and the rest) and `_inTick` are set and cleared inside a tick, which is safe under a swap.
   - `DirLocation`'s tables follow the line, and `DirAlchemy`'s read cache is keyed by tick. **Under a swap each would rebuild twice a tick,** so each needs one copy per fight.
   - This audit is most of my first session.
3. **Rollback and the hash.** The hash and the snapshot have to walk every fight. This is Netcode's and Simulation's, and the cost roughly doubles.
4. **Render and UI.** They read one fight per viewport by entering it, without writing. Split-screen is what makes this work, and Rendering owns that cost.

## Both humans against computer fighters

This is the first case the shape serves, and it needs no new rules:

- **Fight 0** is P1 against a computer fighter, and **fight 1** is P2 against another, on one planet.
- **They share damage.** A city one fight levels stays levelled when the other fight flies through it.
- **Bodies don't meet in the first cut.** A blow or blast only reaches its own fight, and starting on opposite sides of the planet keeps them apart. Two fights that do cross pass through each other, so the swing's choice of where to go needs a small score against the other fight's position. That's mine, and about half a session.
- **Each fight has its own clock,** so one player's hit-stop or set piece doesn't stop the other.

## Rules calls for Game Design, through the EP

1. **When one fight ends.** Does the winner fly to the other fight and make it two on one, which `MAX_BODIES` and the guards' code partly allow? Or does that player watch? I'd have the winner fly over, as it's the better story.
2. **True 2v2, partners changing.** With this shape, a swap of partners is moving fighters between fights **when neither has an exchange running,** so it needs no second exchange on one pair. That's a design of its own, later.
3. **The same computer level for both?** Balance's, not a structure question.

## Order, when it's asked for

1. World sizes the second line. If it doesn't fit the budget, two fights on one globe becomes two fights on one line, kept far apart.
2. Simulation's `enter` and the step, with one fight, must leave the golden byte-identical.
3. My statics audit and a second fight in a test, with determinism and rollback.
4. Render's viewport.
