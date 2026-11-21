# Parked: he stays still, and letting go fires

Encounter, 2026-11-01, for Orb's first play: "when I fire a beam, the character slowly drifts in a direction, then fires ... Holding the right stick should start the charging, letting go should release the attack, the fighter should more or less remain stationary."

**A plain patch on HEAD.** It acts with `beamPlays.front.enabled` on, by its own key `front.stationary`, true in the data. With the front off, nothing moves.

**Apply in a scratch export:** `git -c core.autocrlf=false -c core.eol=lf apply beam-still.diff`. Then copy.

## What Orb saw

Replaying Orb's match (it matches 36 of 36 checkpoints), both beams were fired from far off, 12,000 and 19,500 units away, so **it wasn't the stand-off.** It was the older rise at the start of a beam's charge: over about 0.55 s he flew to the rival's height plus a lift. In Orb's two beams that moved him 218 and 321 units down. Then the beam left **47 ticks after he let go of the stick,** so what Orb read as a slow drift and a late shot was that charge running after the release.

## What it does

| | Was | Now |
| :--- | :--- | :--- |
| In a beam's charge | He flies to the rival's height, and from under 9 bh is kicked back too | **Nothing moves him** |
| Holding the stick (RB) | Nothing to see, and no charge | **The hold is the charge,** and shows on him as the charge does |
| Letting go | A 48-tick charge starts | **It fires:** after what's left of the 48-tick warning, and at least `releaseTell` 6 |
| Something takes him during the hold | The stick's let-go still tried to fire | **The charge is lost,** with `stick_refused`, source `taken` |

RT + B, and the computer's signature, keep the 48-tick charge, standing still. The stand-off stays in the code, reached only with `stationary` false.

## Read

`beam_front_check`:

| Test | Read |
| :--- | :--- |
| Fired from 58 or 3,000, rival 200 higher | Moved 0 |
| The stick held 36 ticks | Fires 13 ticks after the release |
| The stick held 60 ticks | Fires 7 after |
| `stationary` false, from 58 | Moved 682: the old rise and stand-off, as before |

## Point blank, for Game Design

**With the stand-off gone, a signature from reach is what the ruling feared.** From 58 apart, the front takes its 36-tick floor to cross under 1 bh, so it creeps, and a fire-back meets at their hands. The time to answer is unchanged, so it still plays. **It just doesn't look like a shot.** Orb's words rule out the kick, so the choices are a shorter floor at very close range, or an answer such as a shove at the fire. Nothing's built.

## Not done

- **Moving while holding:** the left stick still flies him at full speed during the hold. "More or less stationary" may want it slower. It's E45's half speed, and I've left it for Orb's next play.
- **The hold's ki:** it's still paid at the fire, not while held.
