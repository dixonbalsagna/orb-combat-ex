# Fighter identity workflow: what a fighter needs from Narrative

Owner: Narrative and Fighter Identity. Version 1, 2026-10-12. Answers the EP's brief from Orb ("each character should have their own 'flavor' of attack animations and movesets, with a large common pool of attacks to pull from. Can we establish a workflow for the characters so I can get at least four into the playable build soon?"). It is Narrative's part of `docs/design/fighter-pipeline.md` (steps 0 and 2) and sits beside `docs/animation/fighter-onboarding.md`. **Everything here is an option for Orb.** Orb writes the universe; our drafts are templates only. KAI and VORR are retired placeholders, and every name is Orb's to choose (`ui/data/fighter_names.json` holds today's stand-ins).

## 1. The short version

- **Before Combat, Animation, Audio, UI or Art can start a fighter, they need one page from Narrative.** The page is eight fields (section 2). Game Design's step 0 asks Orb for five of them in three sentences; the rest I pre-fill so Orb marks and changes, and does not write from nothing.
- **The page already exists, in draft, for all four.** Section 3 shows what, and section 5 pre-fills the page for each. What does not exist is **anything Orb has marked**: he has marked no line in the voice lab (0 of 1,386 rows), and the lists he said he would hand back on 2026-10-06 are not in the repository that I can find.
- **The smallest thing Orb must do per fighter for tier 1** is mark one page: six choices and ten lines, about fifteen minutes (section 6). Nothing else of his is needed for a fighter to play with his own look, voice and moveset flavour on today's systems.
- **No line is written in volume again.** A fighter's voice grows ten lines at a time, each with a speaker and a moment, marked by Orb (`writing-quality.md`).

## 2. The one-page identity: eight fields, and who reads each

| # | Field | What it is (limits) | Who reads it, and for what |
|---|---|---|---|
| 1 | **How he fights, and why** | Three verbs and one sentence of why. His range home, and what he does to the world (tends it, ignores it, annexes it, feeds on it). | Combat: the moveset weights (`identity.json`) and his leanings. Game Design: his row on the roster's axes and his care. AI: his leanings. |
| 2 | **What he wants** | One sentence, plain. The thing the match is about for him. | Narrative: the intro plotlines and taunt reactions. Art: the expression of the face. |
| 3 | **His voice in ten lines** | The voice device, then ten lines: an arrival, a taunt, a hit landed, a hit taken, a miss, a launch, a perfect block, a win, a loss, and one only he would say. Each at most 8 words, each with its moment. | Audio: the grunt, laugh and effort palette (the babble's voice). UI: the captions' look. The line system: the seed of his voice. |
| 4 | **What he says when he lands, takes and misses a blow** | Three short sets (three lines each) of the lines he is heard saying most. | The line system's most-used slots (`line-system.md`). Audio's cue priorities. |
| 5 | **His names for the things the HUD shows** | His meter's name; his rally's name; his signature's name; his finisher's; how he calls his stages. All Orb's to pick; mine are options. | UI: `ui/data/terms.json` and `fighter_names.json`. Combat: the move-name lexicon (`move-names-draft.md`). |
| 6 | **His look in words** | Silhouette in one sentence, one thing you notice at a distance, the palette's mood. Not a design. | Art: three silhouettes for Orb to pick from. Animation: his shape key and pose profile. |
| 7 | **How he moves** | Three words of flavour (heavy or light, wide or economical, patient or restless). | Animation: the pose profile and idle (`fighter-onboarding.md` section 1). Combat: his weights. |
| 8 | **Vetoes and hooks** | The stances he never speaks in; the types of plotline he never takes; three relationship hooks to the others. | Narrative's intro plot data (`pending/intro_plots.json`); the dynamic intros' pair rows. |

**Two rules for the page.** It is **one page**; a fighter who needs two has not decided who he is. And **it carries no unique mechanic**: tier 2 (his meter, forms, wounds) is a second trip through Game Design's pipeline.

## 3. What exists today for each of the four

"Draft" means ours and unmarked by Orb.

| | The Protagonist | The Anti-hero (the rival) | The Empress (the Tyrant of the vision) | The Cyborg |
|---|---|---|---|---|
| **Identity text** (field 1, 2) | `identity.md`: a tagline, a two-sentence blurb. Draft | Same. Draft | Same. Draft | Same. Draft |
| **Voice bible** (field 3) | `voices/protagonist.md`: future tense, fights first and repairs after. Orb approved the tone fix | `voices/anti-hero.md`: past tense about the opponent, ranks. Orb read "Fifth." as "Filth.", so the rank gag is "Fifth. Behind the goons." | `voices/empress.md` v3: **approved by Orb**: revision numbers, the royal "we" slipping to "I", "petitioner" | `voices/cyborg.md`: Orb liked the manager. Draft |
| **Lines** (fields 3, 4) | 187 draft rows (`voice-lab/protagonist.csv`) + 208-row taunt batch (52 each) | 165 rows | 185 rows | 160 rows |
| **Shouts, taunts, last stand** | `data/narrative/combat_barks.json`: one block each. Unwired | Same | Same | Same |
| **HUD names** (field 5) | Meter RESPECT, rally SECOND WIND, signature "Keeper's Lance" (placeholders) | PRIDE, SPITE, "The Barrage" | WRATH, ENCORE, "Decree Line" | HUNGER, REBOOT, "Portal Blitz" |
| **Moveset flavour** (field 7) | **Built:** palms, blade hands, arcs (`docs/combat/pending/movegen`, 46 moves) | **Built:** fists, plates, straight lines (46 moves) | None. Orb's note: "precise cutting beams from range", tail and power attacks | None. Game Design's tier-1 reading: a brawler in a town. Orb's notes: eats civilians, molts, fastest in the last form |
| **Look** (field 6) | A stand-in body in the build (`PROTAGONIST`) | A stand-in body (`RIVAL`) | Art's concepts only; no rig | Art's concepts only; no rig |
| **Matchups, intros** (field 8) | `matchups.md` (10 pairs); plot row for the launch pair; `dynamic-intros.md` | Same | In `matchups.md` and the roster doc only | Same |
| **Tier 1 as it can play today** | Yes, on the stand-in | Yes, on the stand-in | A look and a moveset: **no minions, no stages** | A look and a moveset: **no consumption, no molts** |

**What this shows.** Two fighters are nearly complete on paper and built in the build (as stand-ins). The other two have voices and no body. And for the Empress and the Cyborg the identity is **leaning on the mechanic**: her paperwork joke needs revisions to be said about, and his appetite needs a crowd to eat. A tier-1 page for them has to say what they *lack* (section 7).

## 4. What Orb has written or approved himself

So far as the repository records it. **Everything not on this list is a template of ours.**

| | Orb's own words or approvals | Source |
|---|---|---|
| **All four** | The one-paragraph description of each (kept in `.private/`, summarised in `vision.md`); "staples yes, signatures no"; the tone blend; the player is the fighter; names pinned (Orb thinks them up; they must not sound machine-made); *each fighter has his own flavour from a large common pool* (2026-10-12) | `vision.md` first sections; 2026-10-12 |
| **The Protagonist** | The tone: "I'll help fix it once I'm done with you"; power as blood heated, simmering, boiling; the fold with a reason ("we can't hurt anyone innocent here") | `vision.md`, 2026-09-29 |
| **The Anti-hero** | Likes Drop the Act and Humbled; read "Fifth." as "Filth."; wants the power-up recognisable but non-infringing | same |
| **The Empress** | **Approved: the voice** (revisions, "we" to "I", "petitioner"); the guard of honour; paperwork **diegetic only**; the Encore comeback; goons fall and leave | same |
| **The Cyborg** | Likes the manager; sandwiches, not sweets; graphic consumption in tone (Mature target) | `vision.md` |
| **Lines** | "get the voice line packet ready for me to edit"; dialogue density 6 of 10; faces on every quip; Banjo-Kazooie-style grunts under captions | `vision.md`, 2026-10-01 and earlier |
| **The lists** | Orb said he would hand back taunt, quote and canon-ledger lists on 2026-10-06 evening | `vision.md`, 2026-10-05 |

**What is not there:** a single marked row in the voice lab (0 of 1,386, counting the 156 rows of batch 1 he was sent first, which the Protagonist's sheet repeats), and the lists. Game Design's pipeline says the Protagonist's "lines are in Orb's hands already"; they are in his hands, **unmarked**. That is what I read the pipeline's gate as: *no fighter's lines are used until Orb has marked ten of them.*

## 5. Each fighter's page, pre-filled (Orb marks: keep, change, or cut)

These are **our proposals**, drawn from the bibles and from Orb's own notes (section 4). Names are placeholders. Each line passes `writing-quality.md` or is marked as not yet.

### The Protagonist

1. **Fights:** *redirects, closes, stays.* He lures the fight to empty ground (care above 0), and every broken building costs him (anguish).
2. **Wants:** a real fight, and for nobody to be hurt by it.
3. **Voice device:** future tense, promises; plain words; mild self-teasing. **Ten lines (mine, to mark):** see `voices/protagonist.md` and `voice-lab/protagonist.csv`; the sample batch in `writing-quality.md` has five for the brawl.
4. **Names:** meter *Respect* (today's HUD word, filled when the rival commits fully); rally *Second Wind*; signature *Keeper's Lance* (placeholder).
5. **Look:** warm, open, an easy stance; one thing you notice at a distance: his hands are never in fists. Palette: warm.
6. **Moves:** *open, arcing, patient.* Palms, blade hands and arcs.
7. **Vetoes:** never `formal`, `cold` or `smug`. **Hooks:** the rival (old rivals); the Veteran (a teacher); the Prodigy (an admirer).

### The Anti-hero

1. **Fights:** *softens, ranks, finishes.* He shows off on a skyline; a levelled building is a point.
2. **Wants:** to be first, and to be seen to be.
3. **Voice device:** past tense about the opponent, ranks; present tense and contractions when his facade cracks. **Ten lines:** the bible and `voice-lab/anti_hero.csv`; five for the brawl in `writing-quality.md`.
4. **Names:** meter *Pride*; rally *Spite*; signature *The Barrage* (placeholder).
5. **Look:** straight lines, glasses always on, a regalia that grows with his forms; a still stance.
6. **Moves:** *flat, hard, straight.* Fists, plates and straight lines.
7. **Vetoes:** never `warm` or `awed`. **Hooks:** the Protagonist (a respect he will not admit); the Veteran (a lesson gone wrong); the Empress (a clown he despises).

### The Empress

1. **Fights:** *watches, commands, cuts.* Precise cutting beams from range, behind a guard; a tail and power attacks (Orb's note). **At tier 1 she is the fighter of her late stages, alone.**
2. **Wants:** the empire tidy, and her image kept.
3. **Voice device:** the royal "we" slipping to "I" when hurt; "petitioner"; revision numbers. **Ten lines:** `voices/empress.md` (approved) and `voice-lab/empress.csv`. **At tier 1 the revision joke has no revisions to be about**: her lines lean on the "we" and the court, and the paperwork stays a muttered dread (diegetic, as Orb ruled).
4. **Names:** meter *Wrath*; rally *Encore*; signature *Decree Line* (placeholder).
5. **Look:** an upright, ornate silhouette; a train that is also a blade; Legal's rule on the revisions 9 to 12 silhouette stands.
6. **Moves:** *precise, cold, cutting.*
7. **Vetoes:** never `awed` or `wounded` (she never admits fear). **Hooks:** the Protagonist (a filing to process); the Turncoat (a betrayal); the Cyborg (two departments).

### The Cyborg

1. **Fights:** *crowds, clamps, feeds.* A brawler at home in a town: clamps, slams, twitches. **At tier 1 he eats nobody.**
2. **Wants:** to be served, and then to eat.
3. **Voice device:** customer-service politeness over appetite; a stutter when the chip is hit. **Ten lines:** `voices/cyborg.md` and `voice-lab/cyborg.csv`. **At tier 1 the appetite has no crowd:** his hunger is in his lines, not in what he does.
4. **Names:** meter *Hunger*; rally *Reboot*; signature *Portal Blitz* (placeholder).
5. **Look:** a dark red body wrapped in wiring and chain-like plating; a servo glance; the chip in a translucent housing (Orb's note, rated for the Mature target).
6. **Moves:** *close, wide, twitching.*
7. **Vetoes:** never `warm` or `awed`; he is always polite, so `cold` is rare. **Hooks:** the Protagonist (a customer); the Anti-hero (a dish that complains); the Empress (a bureaucrat).

## 6. The smallest thing Orb must write or choose, per fighter, for tier 1

**One page, six marks, about fifteen minutes.** Everything else is ours to prefill and Orb's to veto.

| # | Orb does | Takes | If he does nothing |
|---|---|---|---|
| 1 | **Says yes or no to the page above** (fields 1, 2, 6, 7: how he fights, what he wants, his look in words, how he moves) | 3 minutes | The draft stands; Art offers three silhouettes from it |
| 2 | **Marks ten lines**: keep, cut or rewrite (the batch in `writing-quality.md` for the pilot pair; a new ten per fighter after) | 5 minutes | No line of his is used in the build; the fighter has grunts and captions only |
| 3 | **Picks or renames his three names**: meter, rally, signature (placeholders are fine) | 2 minutes | Placeholders stay (Legal has ruled they do not hold promotion) |
| 4 | **Picks one silhouette** of Art's three | 2 minutes | Art picks nothing; no look is final |
| 5 | **Names two stances he never speaks in** (my veto list is the default) | 1 minute | The defaults stand |
| 6 | **Says whether he wants the two thin ones shown at tier 1** (Game Design's question 2) | 1 minute | They wait for their mechanics |

**What is deliberately not asked of Orb at tier 1:** the universe, the backstory, the canon ledger, the intros' plotlines, the names of anything in the world, the taunt and quote lists. Those arrive in his time (his lists were due 2026-10-06) and the fighter does not wait for them.

## 7. The workflow, in order

| Step | Who | What | Gate |
|---|---|---|---|
| **0** | Narrative | The page, **pre-filled** (this document, section 5) | Orb's marks |
| **0b** | Orb | The six marks (section 6) | Orb's own |
| **1** | Narrative | **Ten lines** for the fighter, for his moments (a hit landed, taken, a miss, a launch, a perfect block; an arrival; a taunt; a win; a loss; one only he would say), written to `writing-quality.md` and marked by Orb | **Orb marks ten**; rules grow from the marks |
| **2** | Narrative | His names, in `terms.json` and `fighter_names.json` (UI owns the files; I give the strings) and his move-name lexicon (`move-names-draft.md`) | Orb picks or accepts |
| **3** | Art, Legal, Animation, Combat, Audio | Their steps in Game Design's pipeline (steps 3, 5, 6, 8), fed by fields 1, 5, 6 and 7 | Their own gates |
| **4** | Narrative | After Orb's marks: his voice rules and lint additions (the voice lab's method), and his rows in the intro plot data | Orb's marks |
| **5** | Narrative | More lines **ten at a time**, only as Orb asks | Orb marks each ten |

**What does not wait.** Combat, Animation, Audio and UI can start from field 1 and 7 the day Orb says yes to the page. The ten lines run beside them (Game Design's step 2 runs beside step 3).

## 8. Risks, and what I would watch

- **The thin two.** At tier 1 the Empress has no revisions and the Cyborg eats nobody. If Orb wants them shown, their pages should say so in the character's own mouth (a limit, not a flaw): she is "between filings", he is "off the clock". I have not written that joke; it needs Orb's approval first.
- **The pilot's lines are unmarked.** Game Design plans the Anti-hero first and the Protagonist second. Neither has a marked line. Step 1 above makes the first ten lines the gate.
- **"Edits the dialogue by hand."** The About page (`ui/data/howto.json`, the About page) says Orb "edits the dialogue by hand". No dialogue is in the build and none is marked yet, so the sentence is true only after the first batch is marked. UI and Legal should hold it until then, or reword it.
- **Voice volume.** The packet I sent has 1,386 draft rows. That was a mistake of method: no one can mark that many with care. They are now a reservoir, not content.
- **Names.** Placeholders stay in the build. A name that is not Orb's will sound machine-made to him, as he has said; nothing named by us is final.

## 9. What I would do next, if the EP agrees

1. Hold this page and `writing-quality.md` for Orb's marks (the ten lines in that document are for the pilot pair).
2. When Orb says yes to a fighter's page, write his ten lines in his voice, to the standard.
3. Fold Orb's marks from the voice lab into a **short rule set per fighter** (the lint), not into more lines.
