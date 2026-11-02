# The places the fight reached: the test and the records (World, 2026-11-02)

Legal's RL-244 (`docs/legal/review-log.md`): QA's civilian band is re-based to **12 to 30% of the people in the places the fight reached**, the whole planet's total reported beside it as information only. Condition 1: "'places reached' is fixed by a rule written in data before the read ... and is never chosen after the fact to land inside the band." The EP's ask: propose the test and a per-place people count in the records QA reads, with Simulation if the records are theirs, then park; **Legal sees the test before it is used.**

## The test, in plain words (this is what Legal reads)

**A place is reached when the fight has come to it, by one of two stated tests, and then all of its people count.**
1. **The first ring's places** (the places on the line the fight starts on: the town and its outskirts; seven places on planet 7) **count from tick 0**, all of them, whether or not a fighter has been to each.
2. **A far place** (every other place on the planet, laid whole and planet-fixed) **counts once it is posed**: once a fighter has been within `plans.farReach` (9,000 units, about 120 fighter heights) of its first building, tested every 30 ticks. This is the rule that already wakes the place's people (`WorldCollateral.wakeFar`, RL-228); it is not a second test. Once posed, the place and **all** its people count, whatever happens next; a place is never un-reached.
3. **Nothing else counts**: not a place a beam or a blast reached from afar, not a place the camera showed, not a place chosen by how many people it has.

The rule is data: `data/biomes/field.json` `plans.placesReached` = `{"firstRing": "all", "far": "posed"}` (the schema allows only these words, so a change is a change to data and to the schema, visible in a diff). The reach distance is the existing `plans.farReach`.

## The records QA reads

`WorldCollateral.placesReached(S)` (a pure read: it writes nothing and hashes nothing; `PLACESREACHED` proves the hash is unchanged) returns:
- **per place:** `{place, far, reached, pop, alive, lost}`: the people it holds (its base), the people alive now, the people lost there;
- **the band's figures:** `pop` and `lost`: the people in the places reached and the people lost in them (so the band is `lost / pop`), and **`whole` and `wholeLost`**: the whole planet's, information only (RL-228: reported every read, a surprise goes to Legal).

How the numbers are made: the first ring is `S.world.pop0` and the toll `S.world.casualties` (the existing scalar, the one place a civilian dies: `kill`, no new count); a far place's people are its buildings' `pop`, and its loss is its people less those alive (no one in a far place flees: the far branch of `kill` only removes them). **A place not posed is asleep: its people are not there yet, so they are not lost; they are in the whole planet's total only.**

**What QA changes** (QA's file, so a grant): in `qa/godot/records.gd` beside `rec.civPct`, `rec.pop0` (about line 660):
```
var pr: Dictionary = WorldCollateral.placesReached(S)
rec.reachedPop = pr.pop
rec.reachedLost = pr.lost
rec.reachedPct = pr.lost / maxf(pr.pop, 1.0) * 100.0
rec.wholePop = pr.whole
rec.wholeLost = pr.wholeLost
rec.places = pr.places   # per place, for the report
```
and the report's band row reads `reachedPct` with the slice figure `civPct` beside it for the one maximum-tier read (RL-244 condition 3), and the civilians-removed run repeats on the new base (condition 4).

## For Simulation, if they want it (not needed by the test)

- **A first-ring place's own loss is not kept per place** (the toll is one number), so its `lost` is -1 and the first ring's loss is the toll. QA's band needs only the sum, which is exact. A per-place figure for the first ring needs one unhashed counter on the building that `kill` adds to: a `Building` field and one line in `kill` (Simulation's `state.gd`, my `collateral.gd`); I have not built it.
- **`farMask` holds 62 places** (two 32-bit words), so a planet's 63rd far place and beyond can never be posed or reached. Planet 7 has 47. It matters only on a planet with more places than that; the test would then under-count the reached, never over-count.
- **Far people are off by default** (`plans.farPeople` false: a far building holds none): with them off the band is the first ring's, as today. The read must be taken with `farPeople` on for the far places to count.

## What is not decided here

Whether a fight that never leaves the first ring should still be read against the first ring alone (it is: the band is then exactly today's `civPct`, a slice-style figure); the maximum-tier read's use of the new denominator waits for Legal, as RL-244 says. Park: `docs/world/pending/places-reached/`.
