# The AI's holds of a ready step (parked, 2026-10-17)

Owner: Encounter Systems Director. Game Design's `docs/design/hero-forms.md` §4b (edd7dcd8): "The AI takes a ready step at its first break unless it is holding on purpose." This is Encounter's line of §8's table ("The AI: the holds of §4b and §5").
- **It sits behind Simulation's forms switch** (`data/fight/forms.json` `enabled`, off). With forms off, play is the same to the bit.
- **Built in scratch. Not applied.**

## To build it

`node fh.cjs <root>` from this folder, on main with Simulation's forms (8f157894).
- `--check` reads every anchor and writes nothing; any other option is refused.
- No new golden.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/ai.gd` | Encounter | The AI's press of Transform waits on `DirAI._formHold` |
| `data/director/ai.json` | Encounter | The level's `forms` block: easy `holdS` 0; medium `holdS` 10 with `whenAbove`; hard `holdS` 30 with `coilUnder` 60 |
| `tools/schemas/director-ai.schema.json` | **Tools** | The same keys |

## As built

- With forms on, and for a fighter with steps of his own, the AI presses Transform for a ready step at once, so the director takes it at the first break (`SimForms.canTake`). The exception is a hold on purpose:
  - **medium:** while its rival's tier is above its own, for up to 10 s of the step held;
  - **hard:** while its coil is under 60, for up to 30 s;
  - **easy:** never.
- When the hold ends, it presses, and the release comes at the next break.
- The hold is measured by the form's own clock (`FormState.holdT`, live ticks a ready form has been held).

**Not here:**
- spending `SimForms.armoured` on a blow that lands;
- predictFlight's recovery;
- §5's holds.

These come with the rest of the forms window.

## What it read

In scratch on main b0542bae with forms on (`{"forms": true}`). The probe is `probes/fp.gd`: AI v AI, eight matches of 5 minutes a level, the Protagonist in slot 0.

**Gates, forms off:** 35 of 35 with the other parks, and the golden is main's, byte for byte.

| Level | Holds on purpose (a ready step he could take now, held by the rule) | Releases | Held at release |
| :--- | :--- | ---: | :--- |
| easy | **none** | 32 | median 4.5 s, up to 24.5 s: the wait for a break, which every level has |
| medium | **4 holds**, the longest 3.2 s, every tick of them with the rival's tier above his | 26 | median 2.2 s, at most 12.9 s |
| hard | **108 holds**, the longest 8 s, every tick with his coil under 60 | 15 | **30 to 40 s**: the 30 s cap, then the next break |

- At hard the coil reached only 16 to 40 by the release. Simulation's slower coil rates don't fill it to 60 inside 30 s, so the slingshot is thrown small.
- That is Game Design's to weigh against "so players see the slingshot thrown at them".
