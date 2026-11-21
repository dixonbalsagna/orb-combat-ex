# Parked: a released charge closes the gap

Encounter, 2026-11-02, on Game Design's `docs/design/press-decides.md` section 2. **Behind its own switch, off:** `data/director/interrupts.json` `brawl.chargeClose.enabled`.

**The first of six press-decides parks. Apply them in this order on the stack, after `../candidates-heights/`:** this, `../press-wait/`, `../b-one-rule/`, `../beam-aim/`, `../stance-circle/`, `../stick-steal/`. This one also applies alone, on main or on the stack: `git -c core.autocrlf=false -c core.eol=lf apply charge-close.diff`. It brings `press_decides_check`, which checks all six; each section runs only once its own data is in.

## What it does

| | Off (today) | On |
| :--- | :--- | :--- |
| A B released past the first flash, at a rival stepping back | Misses: he gave ground | **It travels up to `firstBh` 3 body heights to him** |
| Released at the full flash | Misses | **Up to `fullBh` 6** |
| How fast | | The gap over at most `maxTicks` 12, never quicker than the blow's own lead |
| Further than that | Misses | Still misses: past the reach it doesn't fly |
| The right stick's stage 2 and 3 | As today | The same, 3 and 6, and its reach rises to match |

What the rival gave on the way no longer counts once it travels.

## Read

`press_decides_check`, a B held and let go at a rival walking away:

| | Off | On |
| :--- | :--- | :--- |
| Held 36 ticks (past the first flash) | Missed, 0 taken | KNOCK BACK, 83 taken |
| Held 46 (the full flash) | Missed, 0 taken | SMASH ACROSS, 86 taken |
| 8 body heights away, full flash | | Didn't travel, 0 taken |

## Grants

| Whose | What |
| :--- | :--- |
| Tools' | the switch: `{ id: 'chargeClose', file: 'data/director/interrupts.json', path: ['brawl', 'chargeClose', 'enabled'], from: false, to: true, needs: [], optional: true }`, and `press_decides_check` in CI (verdict `PRESS: n check(s) failed`) |

## Not done

- **The stick's stage 2 and 3 aren't checked on their own.** The check holds B, not the stick.
- **Nobody's looked at it.** He travels up to 6 body heights in 12 ticks with the rush the brawl already uses; Animation and Camera haven't seen it.
