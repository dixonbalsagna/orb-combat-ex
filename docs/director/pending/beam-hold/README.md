# Parked: holding a beam, he barely moves

Encounter, 2026-11-01, for Orb's first play: "the fighter should more or less remain stationary." The ruling is the last section of `docs/design/power-scale.md`. **It acts with `beamPlays.front.stationary`,** so with `beamFront` on the page. With the front off, nothing moves.

**Apply on `../beam-still/` and `../charge-armour/`:** `git -c core.autocrlf=false -c core.eol=lf apply beam-hold.diff`. Then copy.

## The look

Side by side, without the shove on the left and with it on the right, from 58 apart at an idle rival, at ticks 55, 65 and 85 of Tools' capture scene (scratch staging: the pair are held together until the beam's out): `docs/director/img/shove-t00055.png`, `shove-t00065.png`, `shove-t00085.png`. The beam fires at about tick 52.

**It reads better.** Without the shove the beam starts in the rival's face, and the rival stands inside it; with it the rival's clear by tick 58 and the front visibly crosses the gap, so it looks like a shot. No dissolve, fade or marker is added.

**What's wrong with it:**
- **The rival just slides,** in a standing pose, and nothing says a blast did it. It's a shock wave with no reaction: it wants a piece from Animation and something at the start from VFX, on the cue `beam_shove`.
- **The view moves fast for those ticks.** The split opens as the rival goes and the right pane follows: the tower on the right moves about 60 px in 3 ticks at 960 wide. It's a pan, not a cut, but Camera should read it.
- **Seen in both sides, so not this patch:** a black block with a square top at the foot of the building behind them, from about tick 55. It may be the point-blank charge's damage, drawn wrong. Rendering's to look at.

**Orb's eye decides** between this and a shorter floor, as ruled.

## What it does

| | Was | Now |
| :--- | :--- | :--- |
| **Left stick while holding, past 0.2 s** | Full flight, dash too | **10% of flying speed, no dash.** A flick's first ticks move as ever |
| **The kite's hold (LT + RB)** | A charged beam, built while sprinting | **Withdrawn.** The release is the quick blast, whatever the hold |
| **Firing from under 9 bh** | The front creeps, at their hands | **The other fighter's thrown back to 9 bh over 0.25 s,** no damage and no stun. It stops at a wall. He can still answer |
| **A hold in a brawl** | With beam-still: lost at once, as "taken" | **Kept.** It's lost to a blow its armour doesn't take, a stun, or being sent or knocked down |

The shove replaces a shorter floor, as ruled. The cue is `beam_shove`, on the one thrown. A dodge or guard press still cancels the hold.

**This corrects a fault in my `beam-still`:** being in a brawl was enough for its "taken" rule, so a hold in a brawl never lasted a tick.

## Read

`beam_front_check`:

| Test | Read |
| :--- | :--- |
| Holding, flat out with dash | 43 a second, once it has slowed, against 430 plain flight |
| Kite's hold, 60 ticks | Not a charge, and no beam fires |
| Fired from 58 | 675 apart after 16 ticks, shooter unmoved, no damage or stun, he can fire back, 41 ticks to arrive |
| Fired from 3,000 | Nothing moves him |

**Slowing takes time:** he doesn't stop dead if he's flat out when the hold passes 0.2 s. Flight's own lag brings him down, in under 1.5 s. With the kick's overspeed on, the hold skips it, or he moved at 581.

`stick_check`: a beam held and released inside a brawl, with a light taken on the way, fires a beam.

## Proof

As part of the stack: golden byte-identical, validate, self-test 9,977. With the page's switches and the charge armour on: determinism on the field, rollback, `two_states`, `beam_front_check` 0, `stick_check` 0.

**One line came after those:** a cancelled hold now stops showing as a charge (`beam-still` left it showing). After it I re-ran only `beam_front_check` and `stick_check`, off and on.

## Grants

| Whose | File | What |
| :--- | :--- | :--- |
| **Simulation's** | `sim/core/fighter.gd` | `flightSpeed`, 4 lines; `stepFighter`, one condition: no kick while holding |
| **Simulation's** | `sim/core/dir.gd` | `holdMove`, the forward, 3 lines |

## Not done

- **Against the computer:** whether it answers well from the shove isn't read.
