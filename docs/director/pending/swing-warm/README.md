# Parked: the place table, read a few places a tick from the fight's start

**WITHDRAWN, 2026-11-02 (the EP's ruling): Simulation's `docs/architecture/pending/places-records/` lands instead.** It takes the same walk from about 30 ms to under 1, and the two conflict in `_builtPlaces`. Don't apply this; the folder can go.

Encounter, 2026-11-01, re-cut 2026-11-02, on Orb's "launches seem to cause frame spikes". It only acts with the swing on. No switch: it changes no answer.

**A plain patch on HEAD,** in `sim/director/swing.gd` only. It replaces the first cut (8bb02532).

**Apply in a scratch export:** `git -c core.autocrlf=false -c core.eol=lf apply swing-warm.diff`. Then copy.

## What it does

The first swing offer of a match worked out which places have buildings near them, all at once: 35 to 45 ms in one tick. It's a pure read of the world with a memo, not state.

- **The first cut** did it in the match's first live tick. That moved the cost, but didn't remove it: in Orb's second match the intro runs first, so it landed on tick 456, the moment the fight starts, at 34 to 41 ms.
- **This cut** reads six places a live tick from the fight's start, and finishes in about a second. If an offer comes before it's done, the offer reads the rest at once. **The table is the same whichever ticks build it.**

## Read

Both of Orb's matches, on `field-place` and its grant, with the bake and the page's switches. **Every checkpoint and both final hashes hold** (630154cb09579ddc, c130250f9f984886).

| | Before | First cut | This cut |
| :--- | ---: | ---: | ---: |
| First match: the first swing, tick 252 | 30 to 35 ms | 5.6 ms (and 42 ms at tick 0) | **6.3 ms; no warm tick over 4.3 ms** |
| Second match: the first swing, tick 583 | 44 to 45 ms | 7.8 ms (and 34 to 41 ms at tick 456) | **7.0 ms; no warm tick over 4.6 ms** |

The machine was busy during these reads, so single ticks wander by a few ms.

## Proof

Replays only, as above. Golden, determinism and rollback weren't re-run for this cut. It's a memo of a pure read, as the first cut was, but your gate should run them.
