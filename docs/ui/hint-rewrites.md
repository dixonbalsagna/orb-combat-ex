# The three on-screen hints: two rewrites for Orb to pick (UI, 2026-10-15)

Owner: UI & UX. **Text only; nothing is built and no game file is touched** (the hints are step 3 of `docs/ui/brawl-teaching.md` section 6, behind `perfect_followup`, and not in `terms.json` yet). Against Orb's marks (`docs/ep/vision.md`, last section) and Narrative's rules (`docs/narrative/writing-quality.md` section 0): short, plain, no team nouns, said to the player in second person.

## What each line has to say

- **"Held to the click: a knock-back."** is shown the first time a held Medium or Heavy reaches full charge. "Click" is our word for the arc closing. What the player needs: **let go now, and he gets knocked back.**
- **"He missed. Medium stops him."** is shown the first time the rival swings and misses. "Medium" is a strength name from the legend that a new player has not met. What the player needs: **he is open, hit him now.** (The Medium button is the one that lights.)

## Pick one for each

| | Hint 9 (the full charge) | Hint 10 (the rival's miss) |
| :-- | :-- | :-- |
| **A** | Full! Let go to knock him back. | He missed! Hit him now. |
| **B** | Fully charged. Release to send him flying. | He's open. Hit the lit button. |
| **C** | Keep holding, then let go to knock him back. | He missed. Strike before he recovers. |

My picks: **9-A** (it appears at the moment it is true, and it is the action) and **10-B** (it points at the lit button, so it works on every layout without naming a key). Hint 8, "Tap as your hit lands.", stays as Orb ruled; revisit if the mechanic changes.

## Rumble on a perfect

Orb ticked **on by default**. The option is mine: **"Rumble on a perfect"**, accessibility group, default on, needs Vibration on (the existing `haptics` option), a short pulse for a perfect and a stronger one for the chain's close. The row and the `haptic_requested` signal land with step 3, behind `perfect_followup`, so it is on by default the day the follow-up goes live and invisible until then. Nothing changed today; the host plays the pulse (Controls' side; Safari has no vibration API).

## Checks I owe on these when they land

Both lines are shown once per profile (`UiPrefs taught`), only with Control hints on, data in `terms.json` prompt; `hud_words_check` and `hud_check` get a case for each (fits the hint line at the small sizes, never says safe, tested or compliant).

**Question for Encounter (through the EP):** is a Medium press the only answer to a miss, or may a light also stop him? Hint 10-B is true either way; 10-A and 10-C are true either way too. Only a line that names "Medium" needs the answer.

## Orb's picks, 2026-10-19 (homework 6)

Hint 9 (the full charge): **A, "Full! Let go to knock him back."** Hint 10 (the rival's miss): **B, "He's open. Hit the lit button."** Built in `docs/ui/pending/minimal-hud-on/` (`prompt.hint_full`, `prompt.hint_miss`).
