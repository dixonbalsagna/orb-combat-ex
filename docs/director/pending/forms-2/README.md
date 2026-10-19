# The forms, round 2: hard's hold, and the Trial extras (parked, 2026-10-18)

Owner: Encounter Systems Director. It covers:
- Game Design's ruling of 2026-10-18 (`docs/design/rulings-2026-10-18.md` §1d);
- the director's side of Simulation's Trial extras (`docs/architecture/forms-core.md` §7: `SimForms.blockWiden` and `followBonus`).

It goes on main with the forms holds (1a5dac67) and Simulation's branches (421134e0).
- **It sits behind Simulation's forms switch** (`data/fight/forms.json` `enabled`, off). With forms off, play is the same to the bit.
- **Built and read in scratch. Not applied.**

## To build it

`node fh2.cjs <root>` from this folder.
- `--check` reads every anchor and writes nothing; any other option is refused.
- No new golden.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/ai.gd` | Encounter | `_formHold`: the level's conditions all have to hold |
| `data/director/ai.json` | Encounter | hard's `forms`: `holdS` 75, `whenAbove`, `coilUnder` 60, `untilBattered` |
| `sim/director/interrupt.gd` | Encounter | The perfect-block window gains `SimForms.blockWiden` |
| `sim/director/brawl.gd` | Encounter | A riposte (the perfect follow-up) gains `SimForms.followBonus` brawl lights |
| `tools/schemas/director-ai.schema.json` | **Tools** | `forms.untilBattered` |

## As built

**1d. Hard holds a ready step while its rival is above it,** until the first of these:
- its coil reaches 60;
- 75 s pass;
- a region of its own is battered.

Then it releases at the next break. Medium keeps its 10 s while its rival is above. Easy never holds.

**The level's conditions are now all required.** They are:
- `whenAbove`: the rival's tier above its own;
- `coilUnder`: its coil under this;
- `untilBattered`: none of its regions battered.

Medium's meaning is unchanged.

**The Trial extras** (0 with forms off, or on another branch):
- `SimForms.blockWiden` ticks widen the perfect-block window: 1 at II, 2 at IV.
- `SimForms.followBonus` brawl lights are added to a riposte: a perfect follow-up is worth 1 more.

## What it read

In scratch on main 4cf5802e with forms on (`{"forms": true}`). The probe is `probes/fp.gd`: AI v AI at hard, eight matches of 5 minutes, the Protagonist in slot 0.

**Gates, forms off:** with the other two parks, 33 of 35 and the golden is main's, byte for byte. The two failing gates are main's own (see `../grapple-g3/`).

| | Read |
| :--- | :--- |
| Holds on purpose (a ready step he could take now, held by the rule) | **15**, the longest 4.5 s, every tick with his rival's tier above his and his coil under 60 |
| Releases | 15, held a median 2.2 s, at most 5.5 s (the wait for a break included) |
| The coil at release | 0 in 14 of 15 (1.4 in one) |

- **AI v AI, the rival is rarely above him,** so hard now holds seldom and briefly.
- The coil-60, 75 s and battered limits weren't reached in these matches. The rule held each time on the rival's tier.
- The old 30 s holds came from the coil rule alone.

**The Trial extras aren't read here.** They need forms on with the Trial branch taken. Both return 0 otherwise, and the gates show nothing moves with forms off.
