# The bowed rush and the drop

2026-10-05. Two core pieces for Encounter's zip, as built. Both are neutral until the director uses them: nothing in the game sets an arc or drops a fighter yet.

## 1. A bowed rush (`Rush.arc`)

A rush is a straight line to a point or to a fighter, arriving exactly on its end time. With an arc it bows off that line, round or over whatever is between.

**What the director sets:** one field, as it makes the rush.

| Field | Meaning |
| :--- | :--- |
| `Rush.arc` | How far the path is off the straight line at the middle, in units. 0 is straight |

- **The sign.** Above 0 bows to the mover's left: up when he travels toward +x, down when he travels toward -x. So "over the rival" is the height times the sign of his travel. Set it from the direction, not as a fixed up or down.
- **The shape.** The straight line from where the rush began to its target, in the same time, plus `arc x 4u(1 - u)` square to that line, where `u` runs from 0 to 1. It is zero at both ends and `arc` at the middle.
- **It arrives where and when the straight rush would.** The arrival is the same code.
- **On the way** the ground and the ceiling hold a bowed path. A straight rush still ignores the ground, as before.
- It works for a point rush and a rush at a fighter, and across the seam. Depth is untouched.

**What the core keeps:** `Rush.x0`, `Rush.y0` (where the rush began) and `Rush.dur` (how long it had left then). The core takes them on every rush's first step. The director never sets them. With `arc` they are four hashed fields on a rush.

**For a view, and for sampling a path:**

| Function | Gives |
| :--- | :--- |
| `SimFighter.rushAt(S, f, u)` | The place on `f`'s rush at `u` from 0 to 1, bow included: `[x, y]` as two float64 (a `PackedFloat64Array`; a `Vector2` is 32-bit). Before the rush's first step it begins where he is. With no rush it is where he is |
| `SimFighter.rushU(S, f)` | How far along he is now, 0 to 1. After a tick's step it is where that step put him. 1 with no rush |

- The step of a bowed rush is `rushAt` itself, so a view cannot disagree with the sim. The path's direction is `rushAt(u + a little) - rushAt(u)`.
- Use `rushU`, not `1 - (end - S.T) / dur`: that is one tick behind where the step put him.
- A straight rush steps as it always did, toward its target by the time left. That is the same line as `rushAt` while the target stands still.

## 2. A drop (`SimFighter.drop`)

Game Design's knock-down for a zipper shot on his way out (`docs/design/melee-press-feel.md` section 2c): "a drop and nothing more".

| Call | What it does |
| :--- | :--- |
| `SimFighter.drop(S, f, ticks, vx, vy)` | `f` is out of control for `ticks` live ticks and falls from where he is. `vx` and `vy` are the speed he starts with; left out, he falls straight down. Returns true if it took |
| `SimFighter.dropEnd(S, f, how)` | Ends it now and frees him. `how` is the word on the event: left out it is `end`; the director passes its own for a tech |

- **The state** is `dropped`, with `f.dropT` ticks left (hashed). `f.stateT` counts up from 0. His rush ends at the drop. He reads no stick.
- **The fall:** 1,000 units a second squared, his sideways speed dying away as in the air. `vx` and `vy` are his live speed. His spin is 0 and his rotation eases out as a free fighter's does.
- **The ground only stops him.** Nothing is hurt, worn or dug, and nothing is scored. He has no launcher and no ground-contact journey, so no `land`, `bounce`, `tumble_end` or `journey_end` is sent for him. He stays `dropped` on the ground until the ticks run out.
- **Then he is `free`** where he is, in the air or on the ground.
- A frozen tick (a hit-stop, a pause) does not count.
- **Refused,** returning false: a fighter who is launched, down or already dropped; after a KO; `ticks` of 0 or less.
- **Ki does not regenerate while dropped,** as while launched.

**Events:** `drop_start {actor, dur, x, y, z}`, `drop_land {actor, x, y, z}` (once, when he reaches the ground) and `drop_end {actor, kind, x, y, z}`.

**What is not in the core.** "He can tech out of it in the usual way": nothing in the sim ends a tumble early today, so the tech's press and its window are the director's to write, calling `dropEnd`. What may hit a dropped fighter is the director's too: the core has no strikes.

## 3. Proof

- **Neutral.** One golden regeneration: every light digest and tick count is identical on the nine matches and the two replays. Full-state checkpoints and tick-0 states move, by the new hashed fields.
- **Checks** (`sim/core/tools/parity.gd`): "a bowed rush" plays five rushes beside a straight twin (level both ways, a climb, across the seam, at a fighter) and compares every tick with the formula, the arrival, the sign, the ground's hold, the hash, and `rushAt` at `rushU`. "A drop" plays a fall that ends in the air and one that reaches the ground, with a stick held and a hit-stop in the middle, and checks the path, the events, that nothing is hurt or dug, the early end and the refusals.
