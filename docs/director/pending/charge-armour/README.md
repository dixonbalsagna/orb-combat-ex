# Parked: a charged attack has B's armour

Encounter, 2026-11-01, for Orb's first play: charged attacks should be "much harder to interrupt, especially with light attacks." The ruling is `docs/design/power-scale.md` section 2. **Behind its own switch, off:** `data/director/stick.json` `armour.enabled`.

**A plain patch on HEAD.** It also applies on `chase-tap`.

**Apply in a scratch export:** `git -c core.autocrlf=false -c core.eol=lf apply charge-armour.diff`. Then copy.

## What it does

Past the quick flick (0.2 s), a right-stick hold has B's armour, and a beam's hold on the stick too.

| What lands on it | What happens |
| :--- | :--- |
| **A light** | Never stops it. 30% of its damage, by B's own `heavy.armour.lightMul` |
| **A medium** | Stops it before level 2 (0.5 s), and not after |
| **A heavy, a beam or a grab** | Stops it |
| **A guard** | Blocks it, with no stun, as before |
| **A dodge** | It misses, and he's open for 0.33 s |

It still can't break a guard, and it never sends. Those were already true. A flick in its first 0.2 s is as bare as it was.

**The computer** treats it as it treats a B winding up: one draw to answer with a medium while a medium can still stop it.

## Read

| Read | Result | Ruled band |
| :--- | :--- | :--- |
| Level 3 landing against the computer, by a real pad, one try a fight, 24 fights (`meteor_route`) | **5 of 24, 21%** (before: 0 of 792) | 15 to 40% |
| Meteors from it | **6 of 24** | |
| Stick share of blows | Not read | 10 to 30% |

**24 fights is a small read, on one script that tries once a fight.** It shows the route opens, and it's QA's to measure.

`stick_check`, `_armour`, on real blows from an idle dummy in a brawl:

| Press | Result |
| :--- | :--- |
| Light, 16 ticks into the hold | It goes on, 2.8 of 9.2 |
| Medium, 2 ticks in | Lost |
| Medium, 30 ticks in | It goes on |
| Heavy (B), 14 ticks in | Lost |
| Light on a beam's hold | It goes on, at 30% |
| Dodge with the stick away, 19 ticks in | It misses, open for 17 more ticks when read 3 ticks later |

## Proof

On HEAD, as part of the stack (chase-tap, this, idle-match, beam-still, beam-hold, chase-ease), one job at a time, below normal:
- **Off:** golden byte-identical. Validate 302 files, self-test 9,977.
- **On, with the page's switches:** determinism on the field, rollback, `two_states`, `stick_check` 0.
- `stick_check` shows 6 failures with the page's switches off, and 0 with them on: those rows read the page's data.
- **The dodge's miss has no cue of its own in the view yet.** `stick_refused` with source `dodged` is the sim's.

## Grants

| Whose | What |
| :--- | :--- |
| **Tools'** | `tools/preview/switches.mjs`: `{ id: 'chargeArmour', file: 'data/director/stick.json', path: ['armour', 'enabled'], from: false, to: true, needs: ['rightStick'], optional: true }` |

## Not done

- **If it dominates,** Game Design's first move is level 3's stun from 40 to 30. I haven't touched it.
- **Nobody's looked at it.** A light landing on a held charge shows the armour's own reaction, as on B. Whether that reads on a stick's charge is for Animation and VFX.
