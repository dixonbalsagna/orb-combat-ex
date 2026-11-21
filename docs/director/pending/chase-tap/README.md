# Parked: the chase after a launch, by a plain tap

Encounter, 2026-11-01, for Orb's first play: "the follow-up floats." The ruling is `docs/design/power-scale.md` section 4. **Behind its own switch, off:** `data/director/interrupts.json` `chase.tap.enabled`.

**A plain patch on HEAD 0fb027c0.**

**Apply in a scratch export:** `git -c core.autocrlf=false -c core.eol=lf apply chase-tap.diff`. Then copy.

## What it does

While the one you sent is in the air, press X, Y or B and you rush him. The blow lands as you catch him, and sends him on.

| | Ruling | As built |
| :--- | :--- | :--- |
| **Who** | The far tap, with no LT | Any press out of reach, in the mid band too: a press right after a send is still in the mid band. Inside the 0.33 s below, in reach too |
| **Price** | First tap of a send free, then X 20 or Y 30, ×1.5 each | Free, 20, 30, 45 for X. A full bar runs out at the fifth |
| **During the rush** | Newest press picks the blow: X strike, Y heavy, B drives down at Y's price | Yes. A dearer blow pays the difference and a cheaper one gives it back. A free chase stays free. No queue |
| **After the blow** | A press inside 0.33 s starts the next. No press and you peel off | `nextTicks` 20. Nothing carries him, and he's free to fly. A far tap later, with him still in the air, is a chase at the chain's price |
| **The meteor's curve** | The apex spike, or every tap to the landing | **Every tap goes to the landing,** for the first move, free, with no blow. The spike waits |
| **The riding-along** | Removed | `DirFollow.keepOn` is off with this on |

**A press made while the send still holds him** waits for his first free tick, up to `holdTicks` 24, newest first. Without this the first press after a send was often lost. It's the send's own hold and not a queue of chases.

**Not chases:** a knock-back isn't a send, and a stick strike never sends. A stick strike at him in the air is refused and says so.

## The ease: `chase-ease.diff`, on top of this

**Apply after `chase-tap.diff`.** The EP's ask, for Camera: the rush went from still to 28,000 a second in one tick. Now its top speed builds over `easeTicks` 10 (2,000, 4,000, 6,000 and so on), and `maxSpeed` is 20,000.

| Top speed, arrive, ease | X early (0 to 8 ticks after the send) | X at 20 | X at 30 | X at 45+ | Chain gap |
| :--- | ---: | ---: | ---: | :--- | ---: |
| 30,000, 60, none (`chase-tap.diff` alone) | 16 to 23 | 22 | 60 | he lands first | 17 ticks |
| 30,000, 60, 10 | 19 to 23 | 22 | 60 | he lands first | 17 |
| **20,000, 60, 10 (with the ease)** | **35** | **63** | **60** | he lands first | **17** |
| 20,000, 90, 10 | 35 | 69 | he lands first | he lands first | 17 |
| 20,000, 90, 16 | 34 to 42 | he lands first | he lands first | he lands first | 17 |
| 15,000, 90, 10 | 81 to 88 | he lands first | he lands first | he lands first | 17 |

One seed, a real pad, the page's switches on. The tables below this are the read without the ease.

## My first values, not ruled

| Key | Value | Why |
| :--- | ---: | :--- |
| `arriveTicks` | 60 | At 1.25 times the body's speed a chase took up to 192 ticks, which is the floating Orb disliked. It now reaches him within a second |
| `maxSpeed` | 30,000, 20,000 with the ease | Reaching him before his landing could jump him 8,000 units in one tick. Now it never goes faster, and if he lands first the blow lands where he is |
| `minCatchTicks` | 12 | A press in the blow's own hit-stop caught him at once, with no flight at all |
| `landReadTicks` | 12 | The forecast of his landing was read every tick of a chase. It's a walk of the flight, so now it's every 12 |

## Read

Orb's page switches on, a real pad through `SimInputHub`, after a real send by B held to the flash, on an idle rival. `chase_route.gd` repeats it (copy it into `sim/director/tools/`, with the switch on).

| X pressed after the send | Ticks to the catch |
| :--- | ---: |
| 0 to 4 | 19 to 23 |
| 8 to 12 | 12 to 16 |
| 20 | 22 |
| 30 | 60 |
| 45, 60, 90 | He lands first: the chaser arrives after he's down, and the blow lands there |

Y and B at 20: 22 ticks, 125 damage. X at 20: 25 damage. X as soon as you can: 4 catches, about 17 ticks apart, spending 95 ki.

**The chaser can read up to 53,000 a second** for a few ticks when he's on a fresh body, as he moves with it, and bodies are fast on screen because of the ×6 along the line. The energy model's ×2 should take this down. It isn't a jump: it's the body's own speed.

## Cues, for UI

| Cue | When |
| :--- | :--- |
| `chase_ready` | A send a press can chase, once a send, for a player. **For the hint** |
| `chase`, text `start` | The rush starts |
| `chase`, text `catch` or `landing` | It ended in the air, or where he came down |
| `press_ack`, text `chase_no_ki` | No ki for the next: he doesn't go |
| `press_ack`, text `chase_held`, `chase_late` | A press waiting for the send to let him go, and one that ran out |
| `press_ack`, text `chase` | A press during the rush took |
| `stick_refused`, source `chase` | A stick strike at him in the air |

## Proof

On HEAD 0fb027c0, one job at a time, below normal:
- **Off:** golden byte-identical. Validate 302 files, self-test 9,977. `chase_tap_check` 0, `follow_check` 0, `arc_check` 0.
- **On, with the page's switches:** determinism on the field, rollback, `two_states` and `stick_check` 0, `chase_tap_check` 0, `follow_check` 0.
- `stick_check` shows 6 failures with the page's switches off. All 6 pass with them on, and none is about chases: the pool and direction rows read the page's data.
- `arc_check` shows 2 failures with the page's switches on: "full, foe not weak" and "the blast takes what's in it". `ground-settle` already fixes both.
- `follow_check` now forces the tap off, since its rows are about the follow.
- **The field determinism and rollback runs are computer against computer, and the computer doesn't use this.** So what covers the chase is `chase_tap_check`'s two runs, one hash. All its state is on `f.act.dirI`, which is hashed, and in the rush.

## Grants

| Whose | What |
| :--- | :--- |
| **Tools'** | `tools/preview/switches.mjs`: `{ id: 'chaseTap', file: 'data/director/interrupts.json', path: ['chase', 'tap', 'enabled'], from: false, to: true, needs: [], optional: true }`, and `chase_tap_check` in CI |

## Not done

- **Nobody's looked at it.** No captures under the low-load rule. Camera's read of a rush this fast is unseen. Look gate before it's on for anyone but Orb.
- **No tech for the one chased.** The rally's tech isn't cheap to take: it's tied to who owns a rally. So it's the price alone, the known gap Game Design allowed for the first read.
- **The computer doesn't chase by tap.** It keeps `chase.enabled`'s route, which stays off, so only a human chases.
- **The send's force** is still `sendForce` 1600. The tapped launcher's share comes with the energy model.
- **Not read:** how this moves launches a match, wear, match length or the masher. That's QA's.
