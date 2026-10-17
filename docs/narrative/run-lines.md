# Run lines: offer cards, the boss's lines and the endings

Owner: Narrative and Fighter Identity. Version 1, 2026-10-16. Game Design's asks from `docs/design/run-mode.md` section 2: "each offer card's one line, by kind and the place's state; the boss's lines by boss; the ending: one beat each for the planet's state and the hero's branch history." The data is `pending/run_lines.json`. Every line passes the lint (`writing-quality.md` section 0) and a sensitive-word check (no *nuclear*, *atomic*, *bomb*, *siren*, *countdown*, *radiation*, *school*, *hospital*, *church*). **Legal reads the endings for c08 before Orb sees them.** Everything is an option for Orb. Original; no franchise echoes. `{place}` is a place's name (`place-names.md`).

## 1. The offer cards

Before each stage the globe turns and three touch-downs are offered. A card shows the place's name and kind, what the slice holds, each place's state, the opponent, the tier, the reward and **one line (below)**. The line is flavour: it never states a rule or a score.

**Rampage** (a populated place; the opponent is already in the streets)

| Place state | Line |
|---|---|
| fresh | "He's already in the streets of {place}." |
| fresh | "{place} is full of people. He's walking in." |
| fresh | "Get to {place} before he reaches the square." |
| fresh | "{place} is quiet. That won't last." |
| damaged | "{place} has been hit before. He's back." |
| damaged | "What's left of {place} is in his way." |
| damaged | "They rebuilt {place}. He doesn't care." |

**Proving ground** (a sparse place; the opponent is a tier up)

| Place state | Line |
|---|---|
| fresh, mountains | "Thin air, hard rock. He's waiting up there." |
| fresh, desert | "Nothing out here but sand and him." |
| fresh, ice | "Cold, white and empty. He's stronger now." |
| fresh, ocean | "Open water, no cover. He's already risen." |
| fresh | "He's gone up a step. Come and see." |

**Crossing** (a plain stage; from the second chapter it touches or crosses a place hurt earlier)

| Place state | Line |
|---|---|
| fresh | "A quiet road and a plain fight." |
| fresh | "{place} is on the way. Catch your breath." |
| fresh | "Just a fight. Rest comes after." |
| damaged | "You've been through {place} before. It remembers." |
| damaged | "{place} again. The rubble hasn't moved." |
| damaged | "Cross {place}. Mind the broken streets." |
| fallen | "Cross the ruins of {place}. Quietly." |

**The reward line** (the system's plain words, for UI): Rampage, "People you save count double."; Proving ground, "Two plan cards." (early runs: "1,500 points"); Crossing, "A rest: your broken bones heal a little."

**Rules the lines keep.** No Rampage line promises or celebrates a death. None names a school, hospital or place of worship (and none is ever a target). No line cheers a toll, and none is worded as a prize for a count.

## 2. The boss's lines

Ten moments each, for the rival (the MVP's boss), the Empress, the Cyborg and a generic boss. They follow the fight's phases: the first blow, a hit taken, the tremor when the boss's first region breaks, the tier-5 form, the three catastrophe moves (a crust breach, a blast cloud, the exosphere), the brink, and the two endings.

| Moment | The rival | The Empress | The Cyborg | Any |
|---|---|---|---|---|
| The boss lands the first blow | "Too slow. Try keeping up." | "A fine opening, petitioner. We approve." | "Compliments of the chef, sir." | "You're quicker than I expected." |
| The boss takes a hit | "Good hit. Now do it again." | "You struck us! Remember this, guard!" | "That one cost you extra, sir." | "That stung. Do it again." |
| The ground answers: the quake | "Feel that? Even the ground's afraid." | "The ground trembles. It knows who rules." | "Please remain seated. The floor is moving." | "Feel that? The ground knows me." |
| The boss takes the tier-5 form | "You wanted all of me. Here." | "Revision Twelve, petitioners! Do admire it." | "Our full menu is now open, sir." | "Here's what I really am." |
| A crust breach starts | "Watch your footing. It's getting hot." | "Mind the cracks, petitioners. They're our decree." | "Mind the heat, sirs. The kitchen's open." | "Hold on. The floor's about to go." |
| A blast cloud starts | "Look up. This is what I've got." | "A blast cloud! How very grand." | "Smoke's rising, sirs. Please stay clear." | "Look at the sky. All mine." |
| The boss takes the fight up | "Follow me up, if you can." | "Up we go. The view is better." | "Dining upstairs tonight, gentlemen. Follow me." | "Come up and meet me." |
| The boss reaches the brink | "Not yet. I still have more." | "Guard! This is not on the schedule!" | "Sir, I'm out of order. Please hold." | "Not yet. I'm still standing." |
| The boss's finisher lands on him | "Fine. You beat my best." | "We appeal! No, I appeal!" | "Sir, I must go offline now." | "You win. This time." |
| The boss beats the hero | "I told you not to hold back." | "Case closed. Collect your belongings, petitioner." | "Thank you for dining. Come again, sir." | "Is that all you had?" |

**Voices.** The rival is short and insulted; the Empress says "petitioner" and "we", slipping to "I" when hurt; the Cyborg keeps the service script. All meet the brevity rules. **Legal's c06 and c07:** no line names a charged sphere above the head; the blast cloud is a *blast cloud*, never a bomb word; the Cyborg's blast-cloud line is a polite warning ("Smoke's rising, sirs. Please stay clear."), not a joke about it.

## 3. The endings

One beat for the planet's state (most alive, about half lost, most lost), one for the hero's branch history (always witnessed, always tested, crossing between) and one for a darkened sky that has not cleared. They play after the boss. (The end-of-run beat for a lost run is in `story-beats.md`.)

**end_planet_most_alive** (The planet's state: most of its people alive.)
> Radio: "Most of the planet's people are safe."
> A civilian: "We're alive. The cities will take time."
> Protagonist: "Then we start rebuilding. Together."

**end_planet_half** (The planet's state: about half lost. The toll is a count, never bodies (Legal c08).)
> Radio: "Half the planet's people are gone."
> Protagonist: "Half. I'll carry that."
> A civilian: "Remember them. Please do."

**end_planet_most_lost** (The planet's state: most of its people lost. No cheer, no score.)
> Radio: "Most of the planet's people are gone."
> Protagonist: "I'm sorry. I couldn't stop it."
> A civilian: "The cities are quiet now."

**end_branch_witnessed** (The hero's branch history: always witnessed.)
> Protagonist: "I stopped joking after the first city."
> A civilian: "We saw you go quiet. We understood."

**end_branch_tested** (The hero's branch history: always tested.)
> Protagonist: "I let them go first, every time."
> Rival: "And you loved every second of it."

**end_branch_crossing** (The hero's branch history: crossed between the two.)
> Protagonist: "Quiet or loud, I just kept fighting."
> Rival: "Make up your mind, will you?"

**end_sky_dark** (When the blast cloud darkened the sky and it has not cleared.)
> Radio: "The sky is still dark. The ash is slow to fall."
> Protagonist: "It'll clear. It always does."


**For Legal (c08).** The toll is a count and the planet's state ("Half the planet's people are gone"), never bodies, close-ups or a score. No ending sounds worth having for a rising count: the most-alive ending names who is safe, not who was lost; the half and most-lost endings are sorry and quiet, with no triumph and no joke. No line mentions a school, hospital or place of worship, or a child as a victim. The branch endings are about the hero's manner, not the dead.

## 4. What it needs

- **Game Design:** how the endings are chosen (the planet-state thresholds in 4.3: "most alive" is over 66%, "half" 33 to 66%, "most lost" under 33% is my suggestion), and the one line per card by kind and state.
- **World:** a place's name and state on the card.
- **UI:** the card layout with the one line; the ending screen (the lines one at a time, a face cut-in per speaker).
- **Legal:** read the endings and the boss lines.

## 5. Questions for Orb

1. Should the **endings** be this quiet, or do you want them to land harder?
2. Is **one line per card** the right amount?
3. Do you want the **boss's lines** to change the way they talk as the fight goes up (the rival gets quieter, the Empress ruder)?
