# Core backlog

Owner: Simulation and Engine. A list of what is asked of `sim/core` and not yet built, so it survives between sessions. Each item names who asked and what it would add. Nothing here is designed in detail; an item gets its plan when its turn comes.

## Planned, in order

| Item | Plan | Waits for |
| :--- | :--- | :--- |
| Fight lanes, the rest (World's lane table, true collisions, terrain rows, the switch-on, beams) | `fight-lanes.md` | the ragdoll physics (Orb's ruling) |

## For the agency pass (EP, 2026-10-02)

- **Done 2026-10-02:** shots (`shots.md`), and the small lines: the `knockback`, `exchange_end`, `flow` and `embed` events, the flow value, the embed fields, `autoCharge`.
- **Left:** Controls' `intent-hash.patch` (one line in `hash.gd`; with Encounter's charge slice). The press log stays in Encounter's state.

## At M0 (Combat's moveset milestone), asked through the EP on 2026-10-02

| Item | Who needs it | What the core would add |
| :--- | :--- | :--- |
| A `held` state for throws | Combat, Animation | Per fighter: the holder's slot, the socket he is held by, the start and release ticks; hashed. The held fighter's position follows the holder until the release |
| `react` on the `damage` event | Animation | A field naming the reaction the blow asks for (the strike's class or direction), so the hit reaction does not have to be guessed from the amount and the region |
| The broken side per limb region | Animation, Art, UI | Which arm or leg broke (left or right), decided when the limb breaks and hashed, so the body, the wound card and the readout agree |
| A `path` event for curved rushes | Animation, Camera, VFX | When a rush follows a curve, an event with the path's shape and end tick, so the trail and the camera can lead it. **The curve is built (`Rush.arc`, `zip-core.md`), and a view can read the path from `SimFighter.rushAt` and `rushU`.** The event itself waits until a consumer asks for it |
| A per-slot AI level in the match setup | Encounter, QA, UI | `"aiLevel": [n, n]` in the setup (and so in the replay header), in place of Encounter's static `DirAI.level` |

## Buildings in a fight: what the core would add (sizing only, 2026-10-12)

For Game Design's `docs/design/buildings.md` and World's `docs/world/destruction-hook.md`. Nothing here is built.

| Rule | What exists and serves | What the core would add | Hash and goldens |
| :--- | :--- | :--- | :--- |
| **The wall slam:** twice the building's hit | The damage door for a collision, `SimDamage.hurt`, which World's brunt already calls. The factor is World's number | Nothing. A mood unit for it would be one key and two lines, if Game Design wants one | No new state. Matches with a wall hit change, in World's window |
| **The wall slam:** staggered at the wall for 24 ticks | The hit-stop for the moment he is seen in the wall; then `SimFighter.drop(S, f, ticks)`: he reads no stick and falls, and its three events are sent | Nothing | None of the core's |
| **The lodge:** held 0.5 to 0.9 s in the last building | World builds it on the hit-stop, which stops both fighters | Nothing, as built. **If the attacker is to move while he is held,** a pinned state: one state word, one hashed timer, two events, about 35 lines and a parity case. It is the plain half of the `held` state above | The pin is one more hashed number a fighter: a regeneration in which no event digest and no tick count moves |
| **The falling stack:** 6 a floor, 100 at most, either fighter | `SimDamage.hurt` takes any amount on any fighter, with an attacker or with none. A region can be named | Nothing. Combat says who is credited and where it lands. A new `kind` word on the damage event for the readers | No new state |
| **The falling stack:** buried for 0.5 to 1 s | World's embed (`embedT`, the down state), which the director's bury rules already read | Nothing | None |
| **The collapse that takes seconds** | | World's three fields a building (`failT`, `failDir`, `failK`), by Simulation's lines in `state.gd` and `hash.gd`; its warning and fall events, by lines in `fx.gd`, the hash's event table and the view | Every checkpoint's building list gains three numbers: a regeneration. The feature then changes matches |
| **No approach for 45 ticks** after a launch, a wall slam or a knock-back | The director's per-fighter integers, which are hashed | Nothing: the rule and its count are Encounter's. It sees him come free each tick, and it knows its own shoves | One more director integer a fighter: a regeneration in Encounter's window, with no digest moved until the rule acts |

## Smaller, approved or noted

- **Done 2026-10-02:** the intro phase, the last stand, the mood's form impulse.
- **Rename `act1Damping` to `act1WearMul`** (EP approved): the data, the loader and Tools' schema together.
- **I3:** remove the legacy `stance`, `dash` and `charge` intent fields and the `act.v2` flag; move `transformSource` into `SimAct`.
- **Done 2026-10-05:** `Rush.arc` (a rush that bows off its line) and `SimFighter.drop` (the zip's knock-down). As built: `zip-core.md`.
- **World's data in the replay's data hash:** `contact.json` is in (below). `settlements.json` and the lane table join when World has a `dataHash()` for them.

## Notes from reviews, for other owners

- **World, `WorldContact.dataHash()`** hashes the file's raw text. The other loaders hash the parsed data with keys that start with an underscore left out (`FighterData._canon`), so a changed note or a reformat does not refuse old replays. Line endings are normalised by `.gitattributes`, so this is a consistency point, not a bug.
- **World, `WorldContact.spinFighter`:** a stop (`SPIN_STOP`) is called once, not every tick, so `rot` is barely eased there; the free ease then takes it to 0 through every whole turn it holds (a body that stops with `rot` at 25 radians unwinds four turns in about a second). Wrap `rot` by whole turns at the stop first: that is not a jump, and the ease then goes the short way. It also reads `how` as the literals 0 and 1; `SimFighter.SPIN_AIR` and `SPIN_FREE` are the names.
