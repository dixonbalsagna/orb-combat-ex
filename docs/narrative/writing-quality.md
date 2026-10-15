# Writing quality: why it reads rushed, and what a line must pass

Owner: Narrative and Fighter Identity. Version 2, 2026-10-15 (section 0 added: Orb's marks and the rules; the first sample batch withdrawn; R8 revised the same day: the ellipsis is allowed, sparingly). Version 1, 2026-10-12. Orb, 2026-10-12: "I just get frustrated that the quality of writing I'm presented with for forward facing things like web-pages and in-game dialogue seems so rushed and bizarre." They are right, and this is a diagnosis, not a defence. They have also rejected "bring the towers down" ("an extraordinarily out-of-place piece of writing"), "Every press is a blow" (generic) and "a brawl you can move with the stick" (reads like a forgotten basic feature). Those three are the pattern in miniature.

## 0. Orb's marks, and the rules they set (2026-10-15)

Orb marked the first ten lines. **Every one was rewritten**, and Orb wrote the rules (verbatim in `docs/ep/vision.md`, "Orb marks the first ten lines", and in `homework/done/1-ten-lines.md`). Orb's verdict: "just strange, lame, wording, most reeked of LLM generated nonsense and hardly felt believable for something anyone would say in a real animated shonen fight. quips should be pithy, punchy, passable." **These rules replace sections 3 and 5 where they differ, and the old sample batch below is withdrawn.** Orb's twenty reference lines and the directives that came with them are a style target, not material: none of the twenty is reused.

### The rules, each traced to Orb's own words

| # | Rule | Traced to |
|---|---|---|
| R1 | **Four to twelve words.** One breath, said mid-punch. If it cannot be shouted in one breath, cut it in half. | Directive "Mid-Punch Brevity"; marks 3 ("minimal chattiness") and 10 ("short, simple") |
| R2 | **Talk like a person:** contractions, fragments, interruptions, a question with a tag ("right?", "are you?"). | Directive; Orb's own rewrites ("You're really strong!", "I'll give you that", "aren't you") |
| R3 | **Plain words only.** No theatrical, archaic or literary word (the banned list below). | Directive "Ban LLM Thesaurus Words"; the general note ("strange, lame, wording") |
| R4 | **React to what just happened:** the speed of a kick, a smile after a hit, heavy breathing, a suspicion that the opponent is holding back. Physical, blue-collar words (*dirt, teeth, ribs, breath, hit, drop, bleed, grin, pace, choke*). | Directive "Physical, Blue-Collar"; marks 3 ("you're fast"), 5 ("rotate your shoulder"), 7 |
| R5 | **Never explain the dynamic aloud.** A line that says what the relationship is has failed. | Directive "Write for the English Dub" |
| R6 | **Say it to the opponent:** second person ("you", "your"). | All ten rewrites are addressed to the other fighter |
| R7 | **No passivity.** The speaker acts or answers as a person; he does not describe the blow ("that one was harder than I meant"). | Mark 1 ("less passivity") |
| R8 | **Punctuation is the speaker's:** exclamation marks are natural for the Protagonist. **An ellipsis marks hesitation, regret or performative exhaustion; use it sparingly and in context**, at most one line in ten per fighter. | Orb's rewrites 2, 3, 4 ("!") and 1, 4, 5 ("..."); Orb, 2026-10-15: "the ellipsis can be used to signify hesitation, regret, perhaps performative exhaustion among others, they should be used sparingly but in context it's a good literary device" |
| R9 | **Reference lines are a target, never reused.** | "sound like these, but just trimmed down and punchier" |

### The two voices, from Orb's rewrites and whys

| | The Protagonist | The rival (the Anti-hero) |
|---|---|---|
| **What he is** | An excited athlete in a heavy sparring match: casual, grinning through pain | Impatient, abrasive, insulted |
| **His interest** | **Fascinated by technique** and martial arts (mark 2) | **Probes for hidden strength** (mark 7); treats less than full effort as an insult (directive) |
| **How he talks** | **Respectful banter, minimal chattiness** (mark 3); playful, **disrespectful by accident** (mark 5: "Try not to rotate your shoulder like that...") | **Ego-driven and mocking** (mark 6); **tepid compliments**, plays his hand close (mark 8); **short, simple** (mark 10); **never patient** (mark 9) |
| **What he wants** | The rival **at full strength, without restraint**, to test himself (mark 4) | The Protagonist's **hundred percent**; hates pity and hates the grin (directive) |
| **When a crowd is near** | **Concerned** when a launch heads at people (mark 4: "Everyone, get to safety!") | Indifferent |
| **What Orb's rewrites retire** | The promise gag ("I'll fix it after") as a default; the passive description of a blow | The no-contractions rule, the past-tense obituaries, and the rank gag as a default: his own rewrites use contractions and plain questions ("You're not holding back, are you?", "I'll give you that") |

The Empress and the Cyborg **keep their established voices** (her royal "we" and "petitioner", his service script and sandwiches) but meet the same rules: four to twelve words, contractions, plain words, a reaction to what just happened.

### The banned-words list

In `docs/narrative/line-lint.json`, for the lint. **Orb's list** (from the directive): *commence, futile, demise, symphony, dance, crescendo, reckon, mere, behold, destiny, abyss, limit, surpass, eternal*. **Narrative's additions** (the same family of literary or archaic words, and words from lines Orb rewrote; for Orb to veto): *indeed, shall, hence, thus, whom, regalia, splendid, sovereign, endure, adequate, dignity, courtesy, permit, allowed*.

### What this does to the method

- A batch is still small and every line still has a speaker and a moment. **Orb asked for thirty at a time for the six homework batches**, which overrides "ten at a time" for those six; the rest of the method stands.
- **Every batch is linted before Orb sees it** against R1 to R9 and the banned list, and against the known tells (`voice-lab/known-tells.md`).
- **The rules are Orb's, not ours.** Each new rule is added only with the line it came from.

---

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

## 5. The first sample batch (WITHDRAWN: Orb rewrote all ten; see section 0)

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
