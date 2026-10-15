# One versus many, stage 1: N bodies in the core (parked build)

Owner: Simulation and Engine. 2026-10-15. **Built and proved in scratch; nothing is in the tree.** It is the core's part of stage 1 in Encounter's `docs/director/one-v-many.md`: N bodies in the roster, the hash and the replay. The director's part of stage 1 (`DirBrawl.partner`, the keyed draws given a namespace of their own) is Encounter's.

**Apply** from the repo root: `python docs/architecture/pending/n-bodies/n_bodies.py .`. No class is new, so no import is needed. Re-run the proof below on the HEAD of the day first.

## What a match of N bodies is

- A match holds 2 to 5 fighters (`SimRoster.MAX_BODIES`). The setup names them: `{"slots": ["PROTAGONIST", "RIVAL", "REFERENCE", ...]}`, from the roster or the bench, an id more than once if wanted, with `"names"` to tell them apart in the feed.
- **Slots 0 and 1 are the pair, exactly as in a 1v1:** where they stand, which way they face, who they fight. Slot 0 is the one.
- **A body past the pair** stands beyond the second, `SimRoster.GUARD_SPACING` (240 units) apart and as far again for the next, on the side away from the first. He faces the first, and the first is his opponent: `SimRoster.opp` already gives every fighter but the first the first.
- **He is idle unless the setup's `ai` names him** (`"p3"` to `"p5"`): no AI and no intent, so he stands. Stage 2 gives the ring its AI.
- **The step** controls the pair in today's order (one draw of the seeded stream a tick, as now) and the bodies past it after them, in slot order. A host that passes two intents gives the others none.
- **The intro** brings in the pair only. The others stand on the ground from tick 0, take no entrance and dig no crater.

## The replay and the hash (Encounter's question)

- **A guard's input is a slot like any other.** An entry is `[tick, slot, low, high]`, written only when a slot's intent changes. A human-driven guard writes entries for his slot. An AI guard writes nothing: his intents come from the AI and the seed.
- **The header's `ai` names p3 to p5** when there are such bodies. A 1v1's header is as it was, so a 1v1 replay is the same file.
- **The hash grows by the list:** it walks every fighter in slot order, one block each, as it already did. Nothing in it was sized for two.
- A replay with an entry for a slot the match does not have is refused.

## Every place in sim/core that assumes two

**Changed by the build** (each is the same as today with two fighters):

| Where | What it assumed | Now |
| :--- | :--- | :--- |
| `sim.gd`, `newMatch` | Two slots; two fighters made, named, placed, faced | 2 to 5 slots; the rest placed beyond the second |
| `sim.gd`, `step` | Control order `[0, 1]` or `[1, 0]`; an intent for each of two | The same draw for the pair, then the rest in slot order; no intent past the host's list |
| `replay.gd`, the recorder and playback | `_last` and `cur` of two; `range(2)`; `ai` of p1 and p2 | Sized by the match; p3 to p5 in the header when present; a slot out of range refused |
| `mood.gd` line 443, the style counters | `fs[1 - k]`, "the other one" (with a third body it read the last fighter) | `SimRoster.opp(S, f)` |
| `intro.gd`, `setup` and `_order` | Every fighter falls in; with more than two, every fighter landed and dug a crater | The pair only |

**Already general** (checked, nothing to change):

| Where | Why it holds |
| :--- | :--- |
| `hash.gd` | Walks every fighter, building and shot; the clash's two by index |
| `wounds.gd` line 384, the battered mask at an exchange's start | Four bits a fighter: room for eight |
| `pause.gd`, the set pieces seen | Four bits a slot: room for eight |
| `act.gd`, `setup` | Every fighter; `v2` and the assists default past the setup's lists |
| `shots.gd` | A shot meets every fighter |
| `fx.gd` | Events carry slots as numbers |
| `roster.gd`, `opp`; its users in `fighter.gd`, `hiding.gd`, `act.gd`, `damage.gd` | Every fighter but the first has the first as his opponent |

**Questions for later stages, not plumbing:**

| Where | The question | Whose |
| :--- | :--- | :--- |
| `damage.gd`, `ko` | Any fighter's KO ends the match. A guard knocked out must not; he comes back on a cooldown (stage 5) | Game Design rules it; a few core lines |
| `mood.gd` lines 408 and 415 | "Both aggressive" and "both guarded" read the pair. Whether a guard's stance counts | Game Design |
| `mood.gd`, the act | The act counts every fighter's form steps and wounds. Whether a guard's count | Game Design |
| The hit-stop and the pauses | One for the whole match: a hit anywhere stills everyone. It is what keeps a brawl's freeze share readable | Encounter, with the freeze-share row |
| `view/camera.gd` | It frames the pair; a guard can be off the frame | Camera |

**The director** (Encounter's count, for the record): `S.dirS.ex` read in 116 places, 26 calls of `opp`, 21 "the other one", 8 keyed draws built as `n * 2 + slot`. With the guards idle none of them reaches a guard in stage 1.

## Proof

On a clean export of 63e3b9b4:

- **Parity against the committed golden, unregenerated: 55 of 55,** with no script error. **The golden regenerated is byte-identical** to HEAD's. So every 1v1 match, replay and checkpoint is the same to the bit.
- **The new check, "one versus many: a match of three to five bodies":**
  - five slots, flipped and not: each body in his slot with his keys, the guards where the spacing puts them, idle, facing the first, with the first as their opponent; the pair's opponents unchanged;
  - matches of 3, 4 and 5 bodies, the pair the AI's and the rest idle, 1,500 ticks each: every body stays in the world, and each replays to the same hash;
  - the hash sees the fifth body;
  - a recorded match of four bodies with a human guard (he walks) and an AI guard plays back; the header names p1 to p4; an entry for a slot the match does not have is refused; a 1v1's header still names p1 and p2 only;
  - an intro brings in the pair only: the guard stands on the ground and is not in the intro, and a skipped intro digs two craters;
  - six slots, or an unknown id among them, play the default pairing.
- The window 3 check ("a match's slots name two fighters the data has") now takes six slots as its case of too many.
- An AI guard ran 600 ticks against the one with no script error. What the director made of him is Encounter's to read in stage 2.

**The cost a tick, measured** (stage 1's last row in Encounter's table). The pair is the AI's and the rest stand idle; three matches of up to 6,000 ticks each, run twice, on Orb's PC while other sessions ran:

| Bodies | Mean, first and second run | 99th percentile |
| ---: | :--- | :--- |
| 2 | 322 and 317 µs | 935 and 979 µs |
| 3 | 379 and 354 µs | 1,046 and 1,026 µs |
| 4 | 439 and 404 µs | 1,193 and 1,137 µs |
| 5 | 468 and 443 µs | 1,235 and 1,223 µs |

An idle body costs about 35 to 60 µs a tick: his step, and the loops that walk every fighter. A guard who fights adds his AI and the director's work on top; that is stage 2's to measure.

## Size

| File | Lines added | Lines removed |
| :--- | ---: | ---: |
| `sim/core/roster.gd` | 20 | 1 |
| `sim/core/sim.gd` | 24 | 14 |
| `sim/core/replay.gd` | 19 | 8 |
| `sim/core/mood.gd` | 1 | 1 |
| `sim/core/intro.gd` | 8 | 4 |
| `sim/core/tools/parity.gd` | 120 | 3 |

No data file, no new class, no event. **No golden moves.**
