# Parked: one rule for B

Encounter, 2026-11-02, on Game Design's `docs/design/press-decides.md` section 1. **Behind its own switch, off:** `data/director/interrupts.json` `brawl.oneRuleB.enabled`. Launch anywhere stays off.

**Apply third, after `../press-wait/`:** `git -c core.autocrlf=false -c core.eol=lf apply b-one-rule.diff`. It doesn't apply alone. **It replaces the earlier `press-send` park,** which made a tap a knock-back.

## What it does

| B | Off (today) | On |
| :--- | :--- | :--- |
| A tap | Depends on a hidden rule: in a brawl a heavy recoil, starting an exchange a launch the planner may pick | **A stagger (share 0.125),** in a brawl or starting an exchange |
| A lit tap (the launcher) | | The launcher, as today (0.5) |
| Past the first flash | | A knock-back (0.5) |
| The full flash | | A send (1) |

The hidden rule goes: a send is only earned by a held B. A tapped B starting an exchange gives a stay and the stagger's stun.

## Read

`press_decides_check`, on an idle dummy:

| | Read |
| :--- | :--- |
| A tapped B in a brawl | `stagger heavy`, nothing sent |
| A tapped B starting an exchange from 160 away | Nothing sent, no knock-back |
| Held 36 ticks | KNOCK BACK |
| Held 46 ticks | SMASH ACROSS |

## Grants

| Whose | What |
| :--- | :--- |
| Tools' | the switch: `{ id: 'oneRuleB', file: 'data/director/interrupts.json', path: ['brawl', 'oneRuleB', 'enabled'], from: false, to: true, needs: [], optional: true }` |

## Not done

- **QA's arm.** With it on, a masher's tapped B never sends; the masher row and the match length want reading.
- **Combat:** their parked sell and recoil pieces that key off a tapped heavy.
