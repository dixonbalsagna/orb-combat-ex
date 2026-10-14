# Writing quality: why it reads rushed, and what a line must pass

Owner: Narrative and Fighter Identity. Version 1, 2026-10-12. Orb, 2026-10-12: "I just get frustrated that the quality of writing I'm presented with for forward facing things like web-pages and in-game dialogue seems so rushed and bizarre." They are right, and this is a diagnosis, not a defence. They have also rejected "bring the towers down" ("an extraordinarily out-of-place piece of writing"), "Every press is a blow" (generic) and "a brawl you can move with the stick" (reads like a forgotten basic feature). Those three are the pattern in miniature.

## 1. What went wrong, in four sentences

1. **We wrote notes to ourselves and shipped them as copy.** The HUD and the guide use the team's own nouns (*launcher*, *chip*, *prompt*, *station*), because that is how the design documents talk.
2. **We wrote in volume.** 1,386 draft lines in a packet is nothing a person can read aloud with care; it produced the machine's habits (repeating a word for feeling, a one-word zinger on the end, the same joke on every line) and gave Orb a pile to sort, not a voice to listen to.
3. **No line had a speaker and a reason.** "A fighter says something when he is hit" produced a sentence that any fighter in any game could say.
4. **Nobody outside the project read it first.** Copy that only its authors have seen reads as fluent to them.

## 2. Ten real lines, and what is wrong with each

"Build" means it is in the shipped data or the holding page today. "Draft" means it is in our drafts (the voice lab, the unwired barks) and was put in front of Orb.

| # | The line | Where | What is wrong |
|---|---|---|---|
| 1 | "Your transformation is ready. Nobody will stop you." | Build, tutorial hint | **A voice with no speaker, and a tone swing.** It is the rule (a transformation is not interrupted) delivered as a menacing aside; in a how-to hint it reads as a threat or a villain's line, not a tip. |
| 2 | "You read it and answered it. That's the game." | Build, tutorial hint | **The game congratulating itself.** "That's the game" is a slogan in a place for a nudge, and it says nothing about what the player did. |
| 3 | "You are the fighter. Fly, dodge, guard, hit light or heavy, hold power, call your signature, transform. Transform when the prompt shows: you hit harder for the rest of the match." | Build, the guide | **A list of verbs in one breath, a word twice ("transform"), and an internal noun ("the prompt").** It is a feature list, not a sentence a person would say to another. |
| 4 | "A launch needs an opening, and the launcher rests after it lands: until it is ready again the same button only knocks him back." | Build, the guide | **A mechanic described in the design's own words** (*launcher*, *rests*), in a single clause chain with a colon, and "him" for an opponent who may not be one. The player must decode it. |
| 5 | "The top chip counts what the fight costs the world." | Build, the guide | **An internal name ("chip") and a grand, vague phrase ("costs the world")** for a counter of lost buildings and people. Over-compressed and portentous. |
| 6 | "Planned: steer a flurry across the sky. Charge a heavy that shrugs off jabs. Aim a launcher with the stick. Fire point-blank energy. Zip past a rival's guard and out the other side." | Build, the holding page | **Release notes as ad copy:** five fragments, each a feature, with "a launcher" again. It lists what the code does and does not make anyone want to play. |
| 7 | "The fight director is designed to chain your light, medium and heavy strikes into combos on the fly... No two exchanges are meant to play out the same way twice." | Build, the holding page | **Hedges stacked on a promise** ("is designed to", "are meant to") and "twice" repeated in sense. It sounds as if it expects to fail. |
| 8 | "CORE: BOILED OVER" (beside STRAINED, SCALDED, BOILED) | Build, the card text | **Two near-identical words for adjacent things** (BOILED is the last stage, BOILED OVER is the card) and a cooking metaphor with no speaker. The player cannot tell the card from the stage; it is a joke the HUD makes about its own system. |
| 9 | "Fourth. Behind the furniture. You leave the ranks as you entered them." | Draft, the Anti-hero's win | **Over-compressed: it does not parse.** "Leave the ranks as you entered them" means nothing, so the rank joke has lost its sense and kept its rhythm. |
| 10 | "They're getting out! Go, go, go, that's it!" and "Thank you, thank you." | Draft, the Protagonist's evacuation barks | **Repetition standing in for feeling.** A word said three times is the machine's way of showing relief; a person would say one thing and mean it. |

**The families.** (a) A mechanic described in the design's words, not a person speaking: 3 to 6. (b) A voice with no one behind it, and swings of tone: 1, 2, 8. (c) Hedges and over-compression: 7, 9. (d) Repetition and the neat button, the machine's tells: 10 (and the list in `voice-lab/known-tells.md`).

## 3. What a line has to pass before Orb sees it

A line fails if any answer is no. The writer answers them aloud, and a second reader who has not seen the design documents checks the ones marked *cold*.

1. **Read aloud.** Say it as the named speaker. If you would not say it, it is not a line.
2. **A named speaker and a reason.** Who says it, at which moment, and why *now*? "A fighter, when hit" is not a reason; "the rival, the instant he is hit while he was sure he would not be" is.
3. **Could it be in any game?** Swap the name for another fighter or another game. If it still works, it is empty. *(cold)*
4. **Does it describe a mechanic?** A line a person speaks does not explain a rule. For the HUD: it uses only the words on the screen, and the same word for the same thing. *(cold)*
5. **No repeated word to carry feeling.** Once, with meaning.
6. **One idea, one register.** No swing from menace to a tip to a joke. No hedge ("designed to", "meant to").
7. **A joke is in the situation, not the vocabulary.** One joke at most per line, and not a stock gag (the manager, the five stars, the triplicate) more than once a fighter. No joke written to look like one.
8. **Would Orb say it?** The fan-game comedy the vision asks for is easy and a little silly, without trying hard; if the line is working, cut the effort.

**For forward-facing copy** (the holding page, the guide, store text), add: a cold read by someone who has never seen a design document; no sentence that exists only to cover a duty (the disclosure and photosensitivity texts are written plainly and kept apart from the sales copy); and no word that is the project's internal noun.

## 4. A working method that respects Orb's time

- **Ten lines, not two hundred.** Each batch is ten, each with the **speaker and the moment** beside it. Orb marks each *keep*, *cut* or *rewrite* in one pass (about five minutes).
- **The rules grow from Orb's marks.** Every cut or rewrite is read for the rule behind it, and the rule goes into a short list per fighter (and into the lint). The next ten is written against the rules Orb has actually shown.
- **Nothing forward-facing ships unseen.** Lines, the holding page, the guide and tooltips carry a status: *marked by Orb*, or *not used*. Unmarked text may exist in drafts and never in the build. If the deadline is near, the build ships with captions and grunts, not unmarked lines.
- **The 1,386 drafts are a reservoir.** I mine them for lines worth putting in a batch of ten, rewritten to the standard; I do not send them on as they are.
- **Orb is never the proofreader of last resort.** The writer's tests (section 3) and a cold reader come first; Orb sees what has passed them.

## 5. A sample batch: ten lines for the pair in a brawl

For the Protagonist and the stand-in rival, in a brawl: a hit landed, a hit taken, a miss, a launch, a perfect block. Each is at most eight words (a caption of about a second). **Mark each keep, cut or rewrite, and a word of why if you can.**

| # | Speaker | The moment | The line | Why it is there |
|---|---|---|---|---|
| 1 | Protagonist | He lands a clean hit | "That one was harder than I meant." | He is sorry and pleased at once: the fixation on the fight that costs him later. Plain words. |
| 2 | Protagonist | He takes a hit | "Okay, that one counted." | Sportsmanship: he keeps the score aloud, the way friends do when they spar. |
| 3 | Protagonist | His swing misses | "I was showing off. I missed." | Honest and slightly embarrassed; he names the reason his own blow failed. |
| 4 | Protagonist | He launches the rival | "Mind the roofs!" | He shouts after the opponent as he sails: his first thought is what is under the flight. |
| 5 | Protagonist | A perfect block | "Your shoulder dropped. I saw it." | A specific read: he knows his opponent's tell, which is why the block worked. |
| 6 | Rival | He lands a hit | "You blinked before it landed." | Contempt by detail: he watched the whole of it and counts the flinch. Past tense about the opponent. |
| 7 | Rival | He takes a hit | "I allowed that one." | His pride rewrites the hit as a courtesy. No button on the end: he does not need one. |
| 8 | Rival | His blow misses | "That was aimed where you should have been." | He expects the opponent to stand where he decides. The pomp is the joke. |
| 9 | Rival | He launches the Protagonist | "Take your time coming back." | Dry dismissal: the launch is a way to be rid of him for a while. |
| 10 | Rival | A perfect block | "I watched the whole wind-up." | He tells the opponent he read it from the start; cold and plain. |

**What the marks will tell me:** 1 to 5 test whether *plain and warm* is the Protagonist's voice or reads as soft; 6 to 10 test whether *cold and exact* is the rival's or reads as mean; and whether eight words is the right length for a caption in a brawl.
