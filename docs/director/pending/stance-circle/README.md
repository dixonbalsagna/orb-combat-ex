# Parked: LT + Y in reach is the circle

Encounter, 2026-11-02, from Orb's second play ("my guy would fly around in a tight circle then deliver an attack... I want it to get a lot of polish"), with the price and the stops Game Design ruled in `docs/design/press-decides.md` section 4. Read: `../../second-play-read.md` section 1, and the clips. **Behind its own switch, off:** `data/director/interrupts.json` `stances.circle.enabled`, and it needs `stances` on. **Its input waits for Orb's pick of the clips,** so it ships off.

**Apply fifth, after `../beam-aim/`:** `git -c core.autocrlf=false -c core.eol=lf apply stance-circle.diff`. It doesn't apply alone. It replaces the earlier stance-circle (3 ki, stopped by any blow).

## What it does

LT + Y in reach: he flies round the rival in one curve, over him, or under him with the stick down, and the medium lands as he arrives on the far side.

| | |
| :--- | :--- |
| `ticks` | 24, the curve and the blow's landing together |
| `riseBh` | 1.3, how far over or under |
| Price | `ki` 10, times `repeatMul` 1.5 for each one inside `repeatSec` 3 |
| What stops it | A heavy or a grab: he stops where he is. **A light doesn't** |

## Read

`press_decides_check`, on an idle dummy:

| | Read |
| :--- | :--- |
| Three in a row | Paid 9.9, 14.9 and 22.4 ki |
| A light thrown at him as he rises | His medium still landed, from the far side |

The flight itself is the earlier cut's (same curve and values): it lands on the far side at tick 23, 98 units over him at the top, no step over 16 units.

## Grants

| Whose | What |
| :--- | :--- |
| Tools' | the switch: `{ id: 'circle', file: 'data/director/interrupts.json', path: ['stances', 'circle', 'enabled'], from: false, to: true, needs: [the stances switch], optional: true }` |

## Not done

- **Orb hasn't said which of the clips is the move they loved.** If it's the zip or the step strike, this park is the wrong one.
- **Nobody's looked at it.** A body moves along a curve with nothing authored for it: an Animation piece for the flip, a streak from VFX, and Camera holding both bodies are the polish Orb asked for.
