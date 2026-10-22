# Public page: three drafts for when the build returns

Status: draft, private. The fixed lines were replaced on 2026-10-22 by Legal's `docs/legal/page-fixed-lines.md` (RL-166), word for word, in American spelling; the description is Orb's chosen version A. Nothing here is live: the demo is offline until Tools' change to the gate lands. Written 2026-10-16 by Marketing for the EP's brief; Orb sees every public line before it is used. Orb's note: "high quality before you show me, don't be afraid to iterate until it reads perfectly."

## What these are

Three versions of the page's description, in three tones, each 80 to 150 words (the counts are in the headings). Each was drafted, then revised three times against the checklist below. The revision log shows what failed each time, so nothing here is a first draft.

The words around the description are **fixed and identical** in all three: the AI line, the flash notice, the in-development line, the lock line, and the privacy and license lines. They are Legal's wording (see "The fixed parts" below) and are not counted in the 80 to 150.

**Order on the page** (Legal's, from `page-fixed-lines.md`): title; AI line; the flash box with its lock line; the description; the play button ("Play in your browser: a notice comes first"); the small lines.

## Final: version A, as Orb chose (2026-10-18)

Orb's answers to homework 28 (through the EP): version A; American spelling; cut "Slam your rival into a building and the building pays for it" (it was in version B only, so version A never had it); keep "fight director" if it is accurate; add Orb's own pitch as the honest selling point: "the goal was to have a fighting game where the combos are spectacular and look choreographed, but are in the hands of the player and real-time."

**Final description (135 words):**

> This is a fighting game set on a planet you can fly all the way around. Go one way for long enough, through ocean, city, desert and mountains, and you come back from the other direction, so nobody gets cornered. The goal is combos that look choreographed but stay in your hands, in real time. You fly, dodge, guard and hit light or heavy. There are no combo lists to learn: you pick the moment and the blow, and the fight director strings them together. Beams dig trenches. Buildings crack and come apart in stages, and the damage stays until the match ends. Play against the computer, or share one screen with a friend, on keyboard or controller. It is free and runs in your browser. It is an early test version, with two fighters.

What changed from version A above:
- **New sentence 3:** "The goal is combos that look choreographed but stay in your hands, in real time." It is Orb's pitch, kept as a goal ("the goal is"), not a promise. I dropped "spectacular" because that is a judgment the visitor should make, and the goal sentence is true without it. Orb may put it back; Legal's writing note allows puffery.
- **"the game strings them together"** became **"the fight director strings them together."** It is accurate: the fight director is the system that composes each exchange from the moves you press (pillars.md pillar 2; docs/combat/exchange-templates.md), and Legal's AI line directly above the description already says it is ordinary game code. The word is explained by the page itself.
- **No signature, close-up or finishing move** is mentioned anywhere in the text (Legal's rule).
- **American spelling:** the description had no British spellings to change.
- Checks: 135 words; the script's only flags are "choreographed" and "director", the two team words Orb has now chosen to keep.

**American spelling and the fixed lines: settled (2026-10-22).** Legal's RL-166 gives the fixed lines in American spelling ("analyzer", "License") and adds the lock line. They are copied word for word under "The fixed parts" below. Tools changes the live gate in the same pass and updates its word-for-word checks.

**New claim for Legal, P14:** "The goal is combos that look choreographed but stay in your hands, in real time." Evidence: Orb's pitch (docs/ep/vision.md, 2026-10-18); howto.json ("No combo inputs to learn"); pillars.md pillar 2. Check on the day: play a fight and see that combos form from your button presses in real time. It is a goal statement. P4 (the fight director strings them together) is unchanged.

**Routing:** my charter bars me from messaging Legal directly, so the EP routes this to Legal.

## What is true today (what the page may describe)

Everything in the three versions is something a visitor can do or see in the playable demo. Sources: `ui/data/howto.json` (the in-game How to play), `docs/ui/start-menu.md` (the menu), the cleared claims C1, C5, C6 and C7 in `store-copy-draft.md`, and the EP's overnight note of 12 to 13 October for the wall slam. **I have not played the live demo for this; every row needs checking on the day.**

| Thing the pages say | Evidence |
|---|---|
| Free, runs in the browser | C1; the live play page |
| A planet you fly all the way around: no edges, no corners; ocean, city, desert, mountains | C7; pillars.md pillar 1 |
| You fly, dodge, guard, hit light or heavy, charge, transform (when the prompt shows), end the fight with a finishing move | howto.json, "What you control" and "Controls" |
| No combo lists; the blows string together | howto.json: "No combo inputs to learn. Blows and combos play out on their own." |
| Send your rival flying (the launch) | howto.json, "Reading the fight": "Get an opening, then press launch" |
| Beams leave trenches | C6 |
| Buildings crack and fall in stages; towers lose windows, crack, strip to a shell and come down | C5; docs/rendering/building-stages.md |
| The damage stays until the match ends | C6 |
| A counter at the top keeps a tally of the damage to the world | howto.json: "The box at the top counts the damage to the world." |
| Slam your rival into a building and the building takes it (version B only) | the wall slam (EP note 12 to 13 Oct; docs/world/crowd-cars-buildings.md). **New, unreviewed by Legal** |
| One or two players on one screen, keyboard or controller; play against the computer | docs/ui/start-menu.md |
| An early test version with two fighters | data/fighters/roster.json (PROTAGONIST, RIVAL; there is no fighter select yet, so the pages never say you can choose) |

**Not said anywhere:** a story, more fighters coming, online play, a date, hiding, the sky cycle, the grapple, or anything about civilians. None is in the demo, or each needs its own check.

## The checklist (every draft is scored against all fourteen)

| # | Check | How it is checked |
|---|---|---|
| 1 | 80 to 150 words | counted by script |
| 2 | The first sentence says what the game is, in plain words | read |
| 3 | The opening line is distinctive: the planet that loops or the lasting damage, never a generic action line | read |
| 4 | Every sentence is something a visitor can do or see in the demo today (the table above) | read, against the evidence table |
| 5 | No "Planned", "designed to", "meant to" or "we are building": the page describes the game, and one in-development line covers the rest (Legal's writing note) | script |
| 6 | Plain words a player would say; no team words (director, choreographer, slice, pass, procedural, build, and so on) | script plus read |
| 7 | Active voice and ordinary verbs; no strange images or invented story | read aloud |
| 8 | The player is the fighter and keeps agency: it never reads as if the game plays itself | read |
| 9 | No sales voice: no superlatives, no hype, no call to buy, no wishlist, no advert tone (GitHub's rules) | script plus read |
| 10 | No graphic lead: destruction is described plainly as a feature, with nothing about people being hurt | script plus read |
| 11 | Legal's never-use words, the placeholder names, "safe", "tested" and the rejected lines (the "every press" and "every blow" taglines, the falling-tower tagline, "a brawl you can move with the stick") are absent | script |
| 12 | Nothing reads as human-made, and nothing hides or jokes away the AI disclosure | read |
| 13 | Honest about the rough edges: an early test version, two fighters | read |
| 14 | The three read differently: plain, vivid, dry | read |

## The fixed parts (identical around all three)

Copied word for word from `docs/legal/page-fixed-lines.md` (Legal, RL-166, 2026-10-22). American spelling. The page's flash box and the gate carry the same words. Do not edit them here; change them only on Legal's word.

- **Title:** Orb Combat EX (working title)
- **AI line:** "Orb Combat EX is a one-person project. Orb directs it, and AI tools write the code and draft the art, animation, dialogue and design documents. Nothing in the game is generated by AI while you play: the fight director and the world are ordinary game code."
- **Flash notice** (the page's box and the gate, identical): "This game contains flashing effects. Our own automated check found some scenes that go over the recommended limit of three flashes a second, and they are not fixed yet. No independent analyzer has been run. If you or someone in your family has photosensitive epilepsy, please do not play this version."
- **Lock line** (under the flash box on the page, and under the gate's button): "Reduce flashing is on and cannot be turned off in this version. It lowers some effects but does not remove the flagged scenes."
- **Buttons:** "I understand, start" and "Not now". Never "safe", "tested" or "compliant".
- **In development:** "Everything here is in development and may change."
- **Privacy:** "This game collects and sends no personal data. The web version is hosted on GitHub Pages, which keeps its own server logs. The feedback button copies a report to your clipboard for you to paste to Orb; nothing is sent by the game."
- **License:** "License: not chosen yet, so all rights are reserved for now." Link: "Licenses, notices and privacy". Third-party notices keep their official spelling ("MIT License", "SIL Open Font License 1.1").
- **Play button label:** "Play in your browser: a notice comes first".

**Order on the page:** title; AI line; the flash box with its lock line; the description; the play button; the small lines (in development, privacy, license).

The earlier sentence "We are fixing them" is gone: Orb paused flash work on 2026-10-18, so the honest words are "they are not fixed yet" (Legal's reasoning in RL-166).

## Version A: plain (119 words)

> This is a fighting game set on a planet you can fly all the way around. Go one way for long enough, through ocean, city, desert and mountains, and you come back from the other direction, so nobody gets cornered. You fly, dodge, guard and hit light or heavy. There are no combo lists to learn: you pick the moment and the blow, and the game strings them together. Beams dig trenches. Buildings crack and come apart in stages, and the damage stays until the match ends. Play against the computer, or share one screen with a friend, on keyboard or controller. It is free and runs in your browser. It is an early test version, with two fighters.

Calm and explanatory. The safest for a page hosted on GitHub.

## Version B: vivid (121 words)

> This is a fighting game on a planet with no edges. Fly one way and the horizon brings you back round: ocean, city, desert, mountains. Fights wreck the scenery. Beams gouge trenches. Towers lose their windows, crack open and come down in stages. Slam your rival into a building and the building pays for it. The damage stays until the match ends, and a counter at the top keeps the tally. You are the fighter: fly, dodge, guard, hit light or heavy, charge up, send your rival flying, end it with a finishing move. You pick the moment; the game strings the blows together. Free in your browser, for one or two players, on keyboard or controller. Two fighters so far.

Short sentences and action verbs. Leads with the loop and the wreckage. Still describes, and does not sell.

## Version C: dry (119 words)

> Two fighters, one planet, no corners. Fly in a straight line and you come back from the other side, so there is nothing to be backed into. You fly, dodge, guard, hit light or heavy, charge, send your rival flying, and transform when the game lets you. Learning combos is not required: you pick the moment and the blow, and the game strings them together. The beams leave trenches. Buildings crack and fall in stages, and the damage stays until the match ends. A counter at the top keeps a running total and does not judge. One or two players, keyboard or controller, free in your browser. It is an early test version, so size your expectations to match.

Deadpan and understated. The humour comes from precision and from being honest about size. It never jokes about the AI line.

## My recommendation

**Version B**, because it leads with the two things nobody else has (the loop and the lasting wreckage) and keeps the energy Orb asked for. **Version C's last sentence** ("so size your expectations to match") is worth borrowing for B's ending if Orb wants more of the humour. **Version A** is the fallback if Legal reads B's "pays for it" as too much. Orb's tone answer is all four at once (mature destruction, humour, sincerity), so a mix of B and C is a fair choice.

## Revision log

The script checks length, Legal's never-use and claim words, the placeholder names, "safe" and "tested", the hedge words, the rejected lines, team words, sales words and graphic words, and flags passive voice and sentences over 28 words. The rest is a read-aloud pass. The script found little. The read-aloud pass found most of the problems.

**Draft 0 to draft 1**
- **A:** the opener ("a free fighting game you play in your browser") was generic, the lead should be the planet; "(working title)" was repeated in the body; "Two fighters fly around a planet" put the player outside the game; "button strings" and "build" are jargon.
- **B:** the opening did not say what the game is; "Fights don't stay polite" was filler; "floor by floor" is not something I can verify; "into the skyline" was vague; "the rest of the roster is still being built" is a promise.
- **C:** an invented story ("two people who cannot settle an argument without flattening a city") when no story ships, and "flattening a city" is an overclaim; "takes the dust personally" is exactly the bizarre writing Orb objects to.

**Draft 1 to draft 2**
- **A:** "your blows join into combos by themselves" reads as if the game plays itself, which is Orb's own worry; reworded so the player picks the moment and the blow. Added the biomes to the lead.
- **B:** the opener still skipped what the game is; "launch" is a team word and "finish" was ambiguous, so "send your rival flying" and "a finishing move"; it never said free or browser; "Every scar" was an absolute.
- **C:** "Combos happen without your help" had the same plays-itself problem; a 29-word sentence with "excuses for being cornered", which nobody says; "launch" and "transform" were bare; "the counter only goes up" is not something I can verify, so "keeps a running total".

**Draft 2 to draft 3 (final)**
- **A:** "Play the computer" became "Play against the computer".
- **B:** "Out there, fights wreck the scenery" implied they happen off the planet, so "Fights wreck the scenery"; "no edge" became "no edges".
- **C:** "Two fighters" appeared twice (first line and last), so the last sentence now says "size your expectations to match"; the damage and counter sentences were reordered so the counter has its own line; "total of the damage" became "a running total".

## Claims these pages make

All are claims about the playable demo. None is a promise. Legal status is "unreviewed" until Legal says otherwise; the ones already cleared elsewhere are marked.

| ID | Claim | Evidence | Check on the day | Legal |
|---|---|---|---|---|
| P1 | Free, and runs in your browser | C1 | open the play page | clear (C1) |
| P2 | A planet you can fly all the way around, no edges or corners; ocean, city, desert, mountains | C7; pillars.md | fly across the seam | clear (C7) |
| P3 | You fly, dodge, guard, hit light or heavy, charge, transform when the game allows | howto.json | read the in-game How to play | unreviewed |
| P4 | No combo lists to learn; you pick the moment and the blow and the game strings the blows together | howto.json | play a fight | unreviewed |
| P5 | Send your rival flying | howto.json | get an opening and press launch | unreviewed |
| P6 | Beams leave trenches | C6 | fire a beam at the ground | clear (C6) |
| P7 | Buildings and towers crack and come down in stages; towers lose their windows first | C5 | break one building | clear (C5) |
| P8 | The damage stays until the match ends | C6 | play to the end | clear (C6) |
| P9 | A counter at the top keeps a tally of the damage | howto.json | read the top of the screen | unreviewed |
| P10 | Slam your rival into a building and the building takes damage | wall slam, EP note 12 to 13 Oct | launch a rival into a tower and look | **unreviewed, new** |
| P11 | One or two players on one screen; keyboard or controller; play against the computer | start-menu.md | use the start menu | unreviewed |
| P12 | An early test version with two fighters | roster.json | count them | unreviewed |
| P13 | A finishing move ends the fight (B only) | howto.json | play a fight to the end | unreviewed |

## Open questions

1. ~~The word "director" in the AI line.~~ Settled: Orb said to keep "fight director" because it is accurate (2026-10-18).
2. **Legal: P10** ("slam your rival into a building and the building pays for it"). It appears in version B only; A and C do not carry it.
3. **EP: the live demo.** Please have someone play it once against each claim in the table, since I have not.
4. ~~Spelling.~~ Settled: American (Orb, 2026-10-18; Legal's RL-166 applies it to the fixed lines).
5. ~~The tone.~~ Settled: version A (Orb, 2026-10-18). Versions B and C stay in the file for reference only.
6. ~~The placement of the flash notice and play button.~~ Settled by Legal's page order (RL-166).
