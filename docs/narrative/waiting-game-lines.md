# The waiting game and the slingshot: flavour lines

Owner: Narrative and Fighter Identity. Version 1, 2026-10-16. Orb, 2026-10-16: "I don't understand, but i'm happy if there is more flavor text for more situations", and "theory-craft protagonist's 'sling-shot'-type of transformation, where he stays in his base form and allows the opponent to grow, when he finally transforms he can get a bigger boost based on how long he waited and the damage traded before transforming."

These are drafts for Orb's marks. Every line passes the lint (`writing-quality.md` section 0, run with `python docs/narrative/line-lint.py docs/narrative/waiting-game-lines.md`). None is marked, and none reuses a reference line. No line explains the rule aloud: a fighter who waits never says "I am waiting to get stronger". He says what he sees, what he wants, or how his ribs feel.

**What the situations are.** Part 1 is two good fighters who both want the other to go first. Part 2 is the rival, who hates a head start. Part 3 is the Protagonist waiting in his base form while the opponent grows, taking hits and enjoying it. Part 4 is the change itself, with three sizes (the wait was short, long, or long and bloody). Part 5 is what the opponent says when he changes.

**Why these fit the system.** The AI holds a ready form for up to ten seconds so the Trial can fill. The lines for the hold are meant to play through that wait, so ten quiet seconds are a small scene and not a dead one. (They need a "holding" and a "released" signal from Simulation; I do not know whether one exists, so that is under NEEDS FROM EP.)

## Part 1. A good fighter, waiting (the Protagonist)

Warm, quick, a little cheeky. Exclamation marks are natural.

> "Go on. I'm not in a hurry."
> "Ready when you are. No rush!"
> "Come on, show me the next level!"
> "I've got all day. Go ahead."
> "Stop being polite and hit me!"
> "You're waiting for me, aren't you?"
> "Okay, you win. I'll go first!"
> "Ha! You blinked first!"
> "Wow, you actually did it. Nice!"
> "That was worth the wait!"
> "Still here? Good. Me too."
> "Fine, we'll both just stand here."

## Part 1b. Another good fighter, waiting (any ally; a plain friendly voice until each ally has their own)

> "After you. I mean it."
> "We could do this all day."
> "You look ready. Are you ready?"
> "Go on. I want to see it."
> "Nope. You first this time."
> "Ha! Fair enough. Here goes."
> "That's the form I wanted! Great!"
> "Careful, the town's right behind us."
> "Over here! Away from the houses!"
> "Good fight. Again tomorrow?"

## Part 2. The rival, who won't take a head start

Short, impatient, insulted. He uses contractions. He never says he is patient.

> "Keep your head start. Hit me."
> "Stop staring and fight me."
> "You're stalling. Why are you stalling?"
> "Move already. I'm getting bored."
> "Fine. Have it your way."
> "Don't you dare pity me."
> "Wasting my time. Fight me."
> "That all you're willing to show?"

## Part 3. The Protagonist waiting in his base form (the opponent is growing)

He takes hits. He is delighted, never smug.

> "Keep going! I want to see it all!"
> "Not yet. Show me what you've got!"
> "Ow! Okay, that one counts. Again!"
> "Higher? Perfect! Take your time."
> "I'm still good. Don't stop now!"
> "Whoa. That's a lot. I'm fine, keep going."
> "That's a nice hit. Do another!"
> "Ribs are talking. I like it."

## Part 4. The change: three sizes (the Protagonist)

**A short wait (a small boost).**

> "Quick change! Nothing fancy yet."
> "Just stretching. We're not done."
> "Warm-up's over. Here I come!"

**A long wait (a big boost).**

> "Okay! My turn. Hold onto something!"
> "Thanks for the warm-up. Here I come!"
> "Ready or not, here I come!"
> "You hit hard! Let me return it!"

**A long wait and a lot of damage (the biggest boost).**

> "That was the best warm-up ever!"
> "I felt every hit. Watch this!"
> "Everything you gave me? I'm using it."
> "Okay. Now I'm really awake!"

## Part 5. What the opponent says when he changes

**The rival** (probes for hidden strength).

> "You were holding out on me!"
> "That's what you were hiding?"
> "Took you long enough. Show me more."
> "Don't smile at me. Hit me."
> "Fine. Now this is worth my time."

**The Empress** (her royal "we"; "petitioner").

> "We did not expect that, petitioner."
> "Interesting. We will take that seriously."
> "You let us strike you. Why?"

**The Cyborg** (service script).

> "Power spike detected. Please remain calm, sir."
> "Threat level revised upward, sir."
> "Apologies for the underestimate, sir. Updating now."

## Notes for Game Design and Simulation

- The three sizes of Part 4 map to the boost: **short** under about a third of the maximum, **long** up to about two thirds, **biggest** above that. The bands are mine; Game Design owns the real numbers.
- Part 3 plays only while the Protagonist is in base form with the opponent's form higher than his. If both are in base form, Part 1 plays instead.
- The rival's Part 2 lines play when the Protagonist holds a ready form and the rival does not.
- A line plays at most once a minute, and a line is never repeated twice running.
- All of these are presentation; none is read by the sim.
