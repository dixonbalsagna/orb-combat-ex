# The director's cue names for multi-fighting, the tenth round and the return (agreed list, 2026-10-16)

Owner: Encounter Systems Director. One list for VFX (`docs/vfx/multi-fight-plan.md`), Animation (`docs/animation/tenth-round.md` section 3) and UI (`docs/ui/brawl-teaching.md` section 3), so that every reader gets the same event under the same name. Each is a `cue` event (`type "cue"`, `kind` the name).

## The rules for the fields

- `actor` and `target` are body slots. A ring guard is slot 2 or more; nothing assumes two bodies.
- `n` is an absolute tick. The approach cues (`charge_`, `lunge_` and `return`) are the one exception: as before, their `n` is the approach's length.
- `k` is a count or a level.
- `text` names the moment.
- `source` names the cell (`x`, `y`, `b`) where there is one.
- `dur` is in live ticks.
- `x` and `y` give the lean. The beam struggle's cues are the exception: their `x` is the meeting point.
- A 1v1 match never sends `interject` or `guard_volley`.

## Built (live, or in a park)

| `kind` | `text` | actor, then target | `n` | Other fields | Read by |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `windup` | `interject` | The ring guard, then the one | The contact tick | `source`: `x` for a light, `y` for a medium (`bolt` once built). `dur`: the ticks from the grant to the contact (10 or more) | Animation (the tell). VFX (its chevrons) |
| `windup` | `return` | The fighter back from a send, then the defender | The landing tick of his first blow back | `source`: his cell (`""` in a planned exchange). `dur`: the tell, 10 | VFX (`reach.gd` already draws a wind-up ring on any `windup` but `end`). Animation |
| `return` | `charge`, `lunge` or `far` | The same two | The approach's length | `amount`: its crouch in ticks | Camera (to catch him on his way back). VFX, Animation, Audio |
| `return_met` | none | The defender who pressed into his approach | none | The meeting's own `meet` events follow | Camera, UI |
| `launcher_open` (changed by the wider window, `launcher-window/`) | why it opened | The fighter whose B is the launcher, then the rival | The window's end: the stagger's, or 24 ticks after the close if later | `dur`: the stagger, in which his B always lands | UI (B lit until `launcher_close`), Audio |
| `launcher_close` | `used` or `lapsed` | The same fighter | Its tick (the window's end, when it lapses) | none | UI, Audio |
| `beam_struggle` | `start` | The fighter who fired, then the other | The tick it ends by at the latest | `x`: the meeting point (0 at the actor's hands, 1 at the target's) | VFX, Camera, Audio, UI |
| `beam_pulse` | none | The same two | The pulse's tick | `k`: the pulse, 1 to 15. `x`: the point | Audio (the beat), VFX, UI, Controls (the pad) |
| `beam_surge` | `surge` or `sharp` | The fighter who surged, then the other | none | `k`: the pulse. `x`: the point after it | VFX (the bulge), Audio |
| `beam_stray` | none | The fighter who strayed, then the other | none | `k`: the nearest pulse. `x`: the point after it | VFX (his own beam flickers) |
| `beam_end` | `overwhelmed`, `detonate` or `time` | The winner, then the loser (none for `detonate`) | none | `x`: the point | VFX, Camera, Audio |

The beam struggle's views also read `S.game.clash.mid` each tick (`beam-struggle/README.md`).

## Asked for since (to build)

| `kind` | New fields | Meaning | Read by |
| :--- | :--- | :--- | :--- |
| `blow` | `run`, `run_to` | **`run`:** the striker's run on the target as the blow is thrown, in whole points, 0 to `runToClose` (4). **`run_to`:** the blows he must still land for the close, this one included, counted as lights: 1 when this blow, if it lands, is the close (so also after a trade he won) | UI (`brawl-teaching.md` section 3: the run as pips and a caret on the target's plate) |

- **The event class has neither field.** It is two new fields on `SimState.FxEvent` (Simulation's `sim/core/state.gd`), and a few lines in the brawl's `blow` cue.
- **The hash is untouched:** a cue hashes only its actor, kind, text and source.

## To build (Game Design's tenth round): the names and fields are agreed

| `kind` | `text` | actor, then target | `n` | `k` | Other fields | Read by |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `perfect_window` | The landed hit's strength (light, medium or heavy) | The attacker whose hit landed, then the defender | The tick it closes | none | `source`: its cell. `dur`: the window. `at`: the ticks until it opens | UI, VFX |
| `perfect_made` | The follow-up's strength | The attacker | The tick the follow-up lands | The chain after it | `source`, `link`, `close` (UI's section 3) | UI, VFX |
| `perfect_broken` | `missed`, `early`, `stopped`, `staggered` or `timeout` | The attacker | none | What was lost | none | UI, VFX |
| `duel` | none | The fighter who perfect-blocked and answers, then the other | none | Level 1 to 8 | `x`, `y` | VFX, Camera, Audio |
| `duel_end` | `amplified`, `cash_in` or `apart` | The one whose blow lands, then the one sent | none | The level | `x`, `y`. The send's `damage` event carries `duel` (the level; 0 or absent: none) | VFX reads the cue, Animation the damage field |
| `cash_in` | none | The attacker, then the defender | The contact tick (2 after the press) | none | Its strike beat carries `cash_in: true` | VFX reads the cue, Animation the beat field |
| `chase` | `start`, `blow`, `arrive` or `end` | The chaser, then the rival | On `blow` and `arrive`: the contact tick | On `blow`: 1 to 6 | none | VFX, Animation |
| `tech` | none | The rival who techs, then the chaser | none | none | none | Animation, VFX |
| `barrage_hand` | `sweep`, `thrust` or `flick` | The thrower, then his target | The release tick | The volley, 1 to 3 | none | VFX, Animation |
| `barrage_land` | `hit`, `guard` or `miss` | The same two | none | The volley | `x`, `y` | VFX |
| `guard_volley` | none | The guard, then the one | The release tick | The bolt, 1 to 3 | none | VFX |

## Three differences, settled

1. **The interjection's tell is one cue:** Animation's `windup` with text `interject`, not a separate kind `interject` as VFX proposed.
   - Every wind-up the renderers draw is already a `windup` cue, and two events for one moment would double the stream.
   - VFX still gets every field its row asked for: the guard, the one, the contact tick in `n`, and the strength in `source` (where the other wind-ups carry their cell).
   - It is sent at the grant, 10 ticks or more before the contact.
2. **A chase blow's number is in `k`, not `n`** (Animation asked for `n` 1 to 6). Across these cues `n` is an absolute tick, and VFX reads it that way. A chase blow's `n` is its contact tick.
3. **`perfect_window`'s text is the landed hit's strength,** as UI's section 3 has it and as was ruled earlier, not `open` or `close` as VFX proposed.
   - The window opens with the cue, and `n` is the tick it closes.
   - `perfect_made` or `perfect_broken` ends it early. VFX reads its close from those three.
