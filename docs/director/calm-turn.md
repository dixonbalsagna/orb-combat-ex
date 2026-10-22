# The calm turn: the director's calm moments and steering, for World's window 3 (paper, 2026-10-22)

Owner: Encounter Systems Director. Paper only; nothing is built. For World's `docs/world/shifting-arena-design.md` §4 (window 3, the turn), under Game Design's `rulings-2026-10-19b.md` §1 (1a to 1d). Every number is a first value.

## 1. Who does what

| Owner | Part |
| :--- | :--- |
| **World** | The plane: the pivot, the bearing within 10°, the caps (4 a fight, 60 s of fight apart, 40° of drift a match). The read (the time-sliced loader) and the carry. The check that nothing is in flight: no beam, shot, flight, slide, failing stack, magma or crowd on the move |
| **Simulation** | The swap tick, the epoch in the hash and the replay, the calm-tick gate (World's check and mine together) |
| **Camera** | The hard cut that covers the swap |
| **Encounter** | When a calm moment is coming and when it holds (§2). The director's own part of calm (§3). The steering: the side the fight was pushed, and the pick of the coolest place (§4) |

The director reads; it never draws and never writes play state for this. With the arena's switch off, nothing here runs.

## 2. The three calm moments

Game Design's 1a, as the director sees them. Each has an **ask** (it is coming, so World's loader can start) and a **hold** (it is calm now). The read takes 0.15 to 0.7 s, so the ask goes out as early as each moment allows.

| Moment | The ask, and its lead | The hold |
| :--- | :--- | :--- |
| **A form step that pauses** (a tier-up; the Protagonist's II, IV, V) | At the step's start: its pause and its own camera are known then (Simulation's step) | The step's pause is running |
| **The moment after a launch has landed** | At the send. The planner knows the touchdown (`predictFlight`, the `cam_intent` launch cue), so the lead is the flight plus the settle, 1 to 2 s. The pivot is the predicted landing point (World's "the landing point in a flight") | Within `landedTicks` (30) of the sent body's journey end (any kind but `brake`, where he recovered in the air), and **both fighters down or set.** Down: his state `down`. Set: free, no rush, under `setSpeed` (60 u/s), on his feet or steady in the air. Under Camera's cut back to the pair |
| **A set piece's cutaway** (the inside chain's, a collapse's) | At its start: World's chain start, the collapse's first failing slab | Its cutaway is on screen (Camera's), and its own motion has stopped (World's check) |

If World's read isn't ready at the hold, there is no turn: the ask lapses with its moment.

## 3. The director's part of calm

The hold also needs every one of these. They are what "never in a brawl" means to the director:
- no exchange running, planned or brawl, except the set piece's own whose cutaway this is;
- no approach (a lunge, a far flight, a charge), no taunt, no zip, no catch or clinch;
- no recoil flip in the air, no counter-rush pending;
- no attack request waiting in either queue that would start this tick. A press must never be swallowed by a turn: a waiting press defers the turn, and the moment may lapse;
- no finisher, no brink contest.

## 4. Steering

**The side** (1c: "the turn leans the way the fight has been pushed"). It's a sign along the ring, +1 toward +x and −1 toward −x. World maps it to a bearing. It is the sign of the push since the last turn:
- the brawl's drag: the net distance the pair's centre was moved by the sticks over the last brawl, along the ring;
- plus the last launch's travel, signed by its direction (`ux`).

A tie or no push (0) leaves the side to World's keyed draw.

**The pick** (1c: "the coolest place into view by combat alchemy's score"). At the ask, World offers the candidate bearings on that side, from about 2.5° up to 10°. For each, it lists the places the turn brings into view, from its place index, without reading the ring. The director scores each candidate and returns one, deterministically:

| A place it brings into view | Score (first values, `data/director/calm.json`) |
| :--- | ---: |
| An opponent's home (a story stage) | 5 |
| A landmark | 4 |
| A city | 3 |
| A town | 1 |
| The fighter's own home | 2 |
| Not yet seen this match | +2 |
| Already fought in this match | −2 |

- The hero adds his `care` term against the people a place would put near the fight; the Anti-hero adds his.
- A tie goes to the smaller bearing, which keeps the drift.
- A candidate whose places score nothing is still a turn: the smallest bearing.

## 5. The interface

| Call | Owner | Says |
| :--- | :--- | :--- |
| `DirCalm.ask(S)` | Encounter | `{why, pivot, side, due}` when a moment is coming (`due`: the tick it is expected), or nothing |
| `DirCalm.pick(S, candidates)` | Encounter | The candidate's index. `candidates`: World's list of `{bearing, places: [{id, kind, owner}]}` |
| `DirCalm.hold(S)` | Encounter | True while the moment holds and §3 is met |
| World's check, the caps, the read, the plane | World | As in its design |
| The gate and the swap | Simulation | `hold` and World's check, on a live tick |

## 6. For Game Design

1. Is the landing's settle `landedTicks` 30, and is "set" under 60 u/s right?
2. Does a landing in the water count as landed? I'd say yes: he surfaces set.
3. May the hero's pick bring a city into view? 1c says the coolest place. His care term only lowers its score.

## 7. QA's rows (proposed)

- Every turn on one of the three moments, and none in a brawl, an approach or a clinch: 0 exceptions.
- No press swallowed by a turn: 0.
- The side matches the push in every turn with a push.
