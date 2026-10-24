# Intent version 5: the right stick's second packed word (what it would cost)

Owner: Simulation and Engine. 2026-10-23, paper only, on the EP's heads-up: Game Design's `right-stick-pitches.md` §10 R19 and Controls' `docs/controls/right-stick.md`. Nothing is built, and nothing will be until Orb picks a pitch (homework 49).

## Where the intent is today

- **One packed integer a slot a tick** (`SimIntent.pack`, `sim/input/intent.gd`, version 4): 53 bits used of the 63 a non-negative 64-bit integer holds.
- **The replay** stores an entry `[tick, slot, low, high]` only where a slot's intent changed, the integer split into its low 32 bits and the bits above, so JSON's 53-bit limit never bites (`sim/core/replay.gd`). Another intent version is refused.
- **The gameplay hash** takes each fighter's intent fields by name (`SimHash.INTENT`).
- **The golden** stores its scripted replays as fields, not packed integers, so the packing is not in it.

## What Controls asks for

`right-stick.md`, "Intent fields and version":
- `rsHold`: active, a 16-way direction, 3 magnitude bands (7 bits);
- `rsEvent`: none, flick, pump, zig-zag, half circle or circle, with a direction or orientation and a turn bit (7 bits);
- `rsLag`: ticks since the onset, like `waited` (2 bits).

That is about 16 bits, behind `switches.rightStick` (off). With 10 bits free, they don't fit the one word. **Folding I3 in doesn't save it either.** I3 removes the legacy `stance`, `dash` and `charge` bits (5 bits, already due to leave at version 5), which leaves 15 free.

## The build: a second word

| Piece | What | Files |
| :--- | :--- | :--- |
| **The fields and the word** | `rsHold`, `rsEvent` and `rsLag` on `SimIntent`, and `pack2` / `unpack2` for a second integer: 16 bits used, 47 reserved. `canon` covers both. A neutral right stick is a zero word | `sim/input/intent.gd` (Controls have kept it; the change is the transport's, so mine with their yes) |
| **The version** | `VERSION` 5. **Old replays stay valid:** an intent-4 replay plays back with every second word zero, in place of being refused (the stick is off in all of them). A 5 replay is refused by a build that only knows 4, as now | `intent.gd`, `replay.gd` |
| **The replay's entries** | `[tick, slot, low, high, word2]`. The second word goes as one number while it is under 2^53, and as two numbers once its reserve passes that. An entry is written where either word changed. A 4-tuple reads as word 2 = 0 | `replay.gd` (mine) |
| **The hash** | `rsHold`, `rsEvent` and `rsLag` join `SimHash`'s fighter intent only while `switches.rightStick` is on for the match. With it off, every hash, checkpoint and replay is as it is | `hash.gd` (mine) |
| **The switch** | `setup.switches.rightStick` (a match input, so in the replay header), read by `newMatch` into `S.rightStickOn` | `sim.gd`, `state.gd` (mine) |
| **Rollback, later** | The net layer carries both words: 8 bytes more a slot a tick, before compression | Whoever builds `net/` |
| **The recognizer** | The flick, hold and pattern reads in the layout layer, which fills the fields | Controls' |
| **What a gesture does** | The sim reads the fields per stance (aim line, step, boost) | Encounter, Game Design |

## The checks

- Pack and unpack both words round trip, for every field at its ends; a neutral stick is a zero word.
- An intent-4 replay (a 4-tuple entry) plays back to its checkpoints under version 5.
- A version-5 replay with right-stick events plays back bit for bit.
- An entry is written when only word 2 changes.
- The hash is unchanged with the switch off, and moves with it on.
- The golden is untouched: it has no packed intents, and the switch is off.
- `web_parity` covers the new paths once a golden key uses them.

## The cost

- **The core:** about 60 lines (the word, the version and old replays, the entry, the hash's gate, the switch) and about 40 lines of checks. Small, because the transport already splits an integer into two numbers.
- **The fields in `intent.gd`:** about 30 lines, Controls' yes needed.
- **Others:** no Tools schema covers a replay file today (none was found), so Tools has nothing unless one is added. The recognizer and the gestures' meaning are Controls', Encounter's and Game Design's.
- **Golden and replays:** no golden key moves, and every existing replay stays valid.
