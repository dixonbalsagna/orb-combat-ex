# Parked: a beam fires where the stick aims

Encounter, 2026-11-02, for Orb's "make the controls feel really responsive and engaging", on Controls' `docs/controls/beam-aim-feel.md`. **Behind its own switch, off:** `beamPlays.front.aim.enabled`, and it acts only with `front.stationary`.

**Apply fourth of the six press-decides parks, after `../b-one-rule/`** (its slots follow `DirChaseTap`'s): `git -c core.autocrlf=false -c core.eol=lf apply beam-aim.diff`. It also applies alone on the stack, not on main. **It wants Controls' `beam-aim` park on,** or the throw's aim is the stick springing home. This cut is the same code as the earlier one, on the new stack.

## What it does

RB and the right stick only. The signature stays aimed at him, always, as Game Design ruled.

| | |
| :--- | :--- |
| **While he charges** | His aim is the stick's sector (`rsAim`, 32 ways). `DirBeamAim.aimDeg(f)` gives it in degrees for the arm and the beam's elevation, and the cue `beam_aim` fires each time it moves |
| **The throw** | Takes `rsAim` on the release edge, or the last aim he held if the edge has none |
| **Within `assistDeg` 35° of him** | A shot at him, as today: it can be answered, and it reaches him |
| **Wider** | It goes where it was aimed, carves what it crosses and misses him. The exchange ends at once, so both are free, and the cue is `beam_wide` |

## Read

`beam_front_check`, a beam on RB held 50 ticks and let go, from 2,400 away:

| Aimed | Read |
| :--- | :--- |
| Right, at him | A shot at him: he took 144 |
| 22.5° up | A shot at him |
| 45° up | Wide: it rose at 0.71, he took nothing, the exchange was over |
| Straight up | Wide: it rose at 1.0 |
| Switch off, aimed up | A shot at him, as today |

The charge's aim followed the stick in each.

## Grants

| Whose | What |
| :--- | :--- |
| **Animation's or Rendering's, to use it** | The arm and the beam's start following `aimDeg` while charging. Nothing reads it yet |
| **Tools'** | the switch: `{ id: 'beamAim2', file: 'data/director/interrupts.json', path: ['beamPlays', 'front', 'aim', 'enabled'], from: false, to: true, needs: ['beamFront'], optional: true }`, beside Controls' `beamAim` |

## Not done

- **Game Design:** is 35° right, and should a wide beam do anything to a fighter it crosses? Today it doesn't.
- **Nobody's looked at it.** A wide beam carves what it crosses; how that looks, and whether the camera follows it, is unseen.
