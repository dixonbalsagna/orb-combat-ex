# Filler episodes: four families of beat templates, the "Episode 12.5" card, and the side-story call-out

Owner: Narrative and Fighter Identity. Version 1, 2026-10-25. Orb: "filler episodes, filler arcs could be considered separate categories in the game, but not all missions will be filler episodes." Game Design's revision (`docs/design/campaign.md` section 1) makes filler one kind of episode and arc beside the main story. This page gives the filler kind its templates: **four families (a training day, a rivalry game, a tournament on a stage, a rescue), each with a cold open, a rise, a twist, an escalation, a climax and a cliffhanger,** the title-card format for a half-numbered episode, and the call-out the ring shows when a side story appears. The data is `pending/filler_templates.json` (the same shape as `beat_templates.json`); the marking sheet is `homework/voice-story-names/LATER - story - filler episodes.md`. **Templates only: no new lore, no new names.** Orb writes the universe and the main story. Every sample line passes the lint. Nothing is marked by Orb; Legal has not screened the filler kinds.

## 1. What filler is, for the templates

- **Lighter, but still in each fighter's voice.** A filler episode is the anime's breather: lower stakes, more play. The Rival still ranks and is grudging, the Empress laughs, the Cyborg talks about wreckage and his appetite for fighters, the Protagonist grins.
- **Generated and lore-free.** A filler arc's villain is a roster fighter, its places come from the planet's names, and a template never adds a place, body (a league, a council), rule or history. A tournament has a stage and rounds, nothing more.
- **Nothing to do with a toll.** A game or a tournament counts rounds (a whole number out of a total), never damage, wreckage or the lost. A rescue is about a **stranded** fighter, not a captive or a victim. Every ruined place is read as wear (Legal c08, ln05, mc02).
- **Fighters never change from what happened to the player** (Legal mc01). A rematch is tone ("angrier"), never "stronger because he beat you". There is no ranking or promotion of enemies, and henchmen are anonymous and remember nothing; the rival's rank gag stays a voice habit (mc03 asks the same of the mechanics).
- **The Cyborg** reads wear and a thing wrecked only, and `home_wear` only for his own yard (ln04, ln05).
- **Filler never touches the main story.** A filler episode inside a main arc may read its open threads as colour, but it never resolves, opens or skips one, and nothing it does carries back (campaign.md 1.2). **The main story's beats are Orb's:** the main-story slots in section 6 are labelled and empty, never content.

## 2. The new slots

| Slot | What it is |
|---|---|
| `filler_kind` | training_day, rivalry_game, tournament or rescue. |
| `episode_number` | The main episode a filler episode follows, as a whole number n; the card reads n.5. Absent for a standalone filler episode. |
| `side_place` | The place on the ring that shows a side story (its name). |
| `round` | A whole number and its total (round 2 of 3) for a game or a tournament. Never a score of damage or deaths. |
| `contest` | What a rivalry game or a tournament is played for: a clean launch, a race along the ring, a best of three. Never a count of wreckage or of the lost. |
| `stranded` | A cast fighter who is stranded across the ring by wrecked ground or a flooded valley (a rescue). Never a captive and never a victim. |
| `guest` | A cast fighter who drops in to a filler episode. |

## 3. The templates, family by family

### The training day

A practice ground, a sparring partner and low stakes: the lightest filler.

| Template | Column | Reads | What the beat does | Notes |
|---|---|---|---|---|
| `training_day.cold_open` | 1. Cold open | `place`, `opp`, `p1` | enjoys the practice ground; tells them to warm up | A practice place, a sparring partner, low stakes. |
| `training_day.rise` | 2. Rise | `opp`, `p1` | corrects the player's guard; asks to be shown | The Rival's correction is grudging, never open respect. |
| `training_day.twist` | 3. Twist | `guest`, `place` | arrives to watch or join; welcomes them | The Cyborg reads wear and a thing wrecked only, never a toll or a person (ln04, ln05). |
| `training_day.escalation` | 4. Escalation | `place`, `home_wear` | a practice wall is cracked; aims the fight away from it | Place and wear only. |
| `training_day.climax` | 5. Climax | `opp`, `place` | sets the last drill; accepts |  |
| `training_day.cliffhanger` | Cliffhanger card | `next` | class is over; a harder drill is next |  |

**Samples** (placeholder names):

*training_day.cold_open* (place=the practice yard, opp=RIVAL)
> **Protagonist:** "Training ground! My favourite kind of place!"
> **Rival:** "Don't get excited. Warm-up first."

*training_day.rise* (opp=RIVAL)
> **Rival:** "Your guard's dropping. Fix it."
> **Protagonist:** "Okay! Show me how!"

*training_day.twist* (guest=CYBORG, place=the practice yard)
> **Cyborg:** "Training? Is there a wreck to hit?"

*training_day.escalation* (place=the practice yard, home_wear=damaged)
> **Radio:** "The practice wall is cracked. Careful."
> **Protagonist:** "Easy with the wall! Aim at me!"

*training_day.climax* (opp=RIVAL)
> **Rival:** "Final drill. Hit me if you can."
> **Protagonist:** "Bring it! Best lesson yet!"

*training_day.cliffhanger* (next=a harder drill)
> **Radio:** "Class dismissed. Tomorrow, a harder drill."

### The rivalry game

Two rivals play a game for bragging rights: a clean launch, a race, a best of three. It counts rounds, never damage and never the lost.

| Template | Column | Reads | What the beat does | Notes |
|---|---|---|---|---|
| `rivalry_game.cold_open` | 1. Cold open | `opp`, `contest`, `p1` | proposes the game; accepts | Bragging rights only; no stakes of harm. |
| `rivalry_game.rise` | 2. Rise | `opp`, `round` | calls the round; wants the next | A round count is a whole number, never a damage or death tally. |
| `rivalry_game.twist` | 3. Twist | `guest`, `contest` | asks to play too; objects |  |
| `rivalry_game.escalation` | 4. Escalation | `opp`, `round` | calls the last rounds serious |  |
| `rivalry_game.climax` | 5. Climax | `opp`, `round`, `contest` | calls the deciding round; names what it decides |  |
| `rivalry_game.cliffhanger` | Cliffhanger card | `opp`, `next` | a rematch is promised; the loser picks the ground |  |

**Samples** (placeholder names):

*rivalry_game.cold_open* (opp=RIVAL, contest=best of three)
> **Rival:** "Best of three. Loser picks the ground."
> **Protagonist:** "Deal! I'm hungry for a win!"

*rivalry_game.rise* (opp=RIVAL, round=1 of 3)
> **Radio:** "Round one goes to the Rival."
> **Protagonist:** "One down! Next round!"

*rivalry_game.twist* (guest=EMPRESS, contest=best of three)
> **Empress:** "Make room, rats. We're playing too."
> **Rival:** "This is a private game."

*rivalry_game.escalation* (opp=RIVAL, round=2 of 3)
> **Rival:** "Last rounds. Nobody holds back now."

*rivalry_game.climax* (opp=RIVAL, round=3 of 3, contest=best of three)
> **Radio:** "Final round. The winner picks the ground."
> **Rival:** "Everything rides on this one."

*rivalry_game.cliffhanger* (opp=RIVAL, next=a rematch)
> **Radio:** "A rematch is promised. The loser picks."

### The tournament on a stage

Rounds on one stage. No league, council or rule is named; the stage and the round count are the whole of it.

| Template | Column | Reads | What the beat does | Notes |
|---|---|---|---|---|
| `tournament.cold_open` | 1. Cold open | `place`, `round` | announces the first round on the stage; is delighted | The tournament is a stage and rounds: no new body, league or rule is named. |
| `tournament.rise` | 2. Rise | `opp`, `round` | meets the player in the early rounds |  |
| `tournament.twist` | 3. Twist | `guest`, `round` | turns out to have entered too | The Cyborg reads wear and a thing wrecked only, never a toll or a person (ln04, ln05). |
| `tournament.escalation` | 4. Escalation | `opp`, `round`, `place` | the semi-final shakes the stage | The stage shakes; no one is hurt. |
| `tournament.climax` | 5. Climax | `opp`, `round` | calls the final; wants the title |  |
| `tournament.cliffhanger` | Cliffhanger card | `next` | the winner is crowned; a rematch is promised |  |

**Samples** (placeholder names):

*tournament.cold_open* (place=the stage, round=1 of 3)
> **Radio:** "Round one on the stage. Four fighters."
> **Protagonist:** "A tournament! This is great!"

*tournament.rise* (opp=RIVAL, round=1 of 3)
> **Rival:** "First round. Don't embarrass me."

*tournament.twist* (guest=CYBORG, round=2 of 3)
> **Cyborg:** "I signed up too. Is food free?"

*tournament.escalation* (opp=EMPRESS, round=2 of 3, place=the stage)
> **Empress:** "Gahaha! Even the stage trembles!"

*tournament.climax* (opp=EMPRESS, round=3 of 3)
> **Radio:** "The final. One fighter takes the stage."
> **Empress:** "The title is ours, rat!"

*tournament.cliffhanger* (next=a rematch)
> **Radio:** "A winner is crowned. A rematch is coming."

### The rescue

A cast fighter is stranded across the ring by wrecked ground or a flooded valley. Never a captive and never a victim.

| Template | Column | Reads | What the beat does | Notes |
|---|---|---|---|---|
| `rescue.cold_open` | 1. Cold open | `stranded`, `place` | a cast fighter is stranded across the ring; sets out to fetch them | Stranded by wrecked ground or flood; never a captive or a victim. |
| `rescue.rise` | 2. Rise | `opp`, `place` | bars the way |  |
| `rescue.twist` | 3. Twist | `stranded`, `guest` | turns out to be unexpected, and cheerful | The Cyborg reads wear and a thing wrecked only, never a toll or a person (ln04, ln05). |
| `rescue.escalation` | 4. Escalation | `place`, `home_wear` | the ground gives way near the route; hurries | Place and wear only. |
| `rescue.climax` | 5. Climax | `opp`, `stranded` | dares them to win the way through |  |
| `rescue.cliffhanger` | Cliffhanger card | `stranded`, `next` | safe at last, with one question left open |  |

**Samples** (placeholder names):

*rescue.cold_open* (stranded=CYBORG, place=the far ridge)
> **Radio:** "A fighter is stranded across the ring."
> **Protagonist:** "Then let's go and fetch them!"

*rescue.rise* (opp=RIVAL, place=the road)
> **Rival:** "Turn back. The road is mine."

*rescue.twist* (stranded=CYBORG, guest=EMPRESS)
> **Cyborg:** "About time! I'm starving down here!"

*rescue.escalation* (place=the far ridge, home_wear=damaged)
> **Radio:** "The ground is giving way near the route."
> **Protagonist:** "Hurry! Fly over it!"

*rescue.climax* (opp=EMPRESS, stranded=CYBORG)
> **Empress:** "Win, rat, and take your friend home!"

*rescue.cliffhanger* (stranded=CYBORG)
> **Radio:** "Safe at last. But how did they get there?"

## 4. The "Episode 12.5" title card

A title card is **one line, at the edge of the screen, never on the fighters** (campaign.md 1.3). It says which kind of episode it is:

| Kind | Format |
|---|---|
| main | `EPISODE {n}: {title}   (Orb's number and Orb's title)` |
| filler in main | `EPISODE {n}.5: {title}   (n = the main episode it follows; a generated title)` |
| standalone filler episode | `SIDE STORY: {title}   (no number: it sits outside the season)` |
| filler arc | `{ARC TITLE} · EPISODE {k} OF 3   (the arc's own short title: The {planet} Special)` |

- **The half number** is the main episode it follows plus one half: after Orb's Episode 12, a filler episode is **Episode 12.5**, as the anime would number one. A standalone filler episode is not placed in the season, so it carries no number: **SIDE STORY** and its title. A filler arc has its own short title and counts its three episodes.
- **The title is generated from a pattern by family** (never lore, never a new name; the place is the planet's own, the stranded fighter a roster fighter). Three patterns each:

| Family | Title patterns |
|---|---|
| training day | "A Day at {place}" / "Training at {place}" / "The Long Drill" |
| rivalry game | "The Bet at {place}" / "Best of Three" / "The Game at {place}" |
| tournament | "The {place} Tournament" / "Four on the Stage" / "The Final at {place}" |
| rescue | "Bring {stranded} Home" / "Cut Off at {place}" / "The Far Road" |

Examples: **EPISODE 12.5: A Day at the Practice Yard**; **EPISODE 3.5: Bring the Cyborg Home**; **SIDE STORY: The Bet at the Harbour**; **THE HARBOUR SPECIAL · EPISODE 2 OF 3**.

## 5. The side-story call-out (what the ring shows)

When a main-story episode ends, the ring sometimes shows **one more place: a side story, with its own beacon** (campaign.md 1.3). Flying to it starts the filler episode there and then; nothing is picked from a list. Two things appear:

- **A beacon caption at the edge, one line:** the words **SIDE STORY** and the family's icon, never on the fighters.
- **A radio call-out, one in-world line (4 to 12 words), said once as the place appears.** It names what is there and asks, never orders. Three each:

| Family | Call-out lines |
|---|---|
| training day | "A practice yard on the ring. Spar?" / "A training ground ahead. Warm up?" / "Someone is drilling at {place}." |
| rivalry game | "A game is on at {place}." / "Two rivals, a bet, a side story." / "A friendly game ahead. Join?" |
| tournament | "A tournament on the stage ahead." / "Rounds are starting at {place}." / "A side story: the stage is open." |
| rescue | "Someone's stranded at {place}." / "A rescue ahead. Fly to it?" / "A fighter is cut off. Help?" |

## 6. The main-story slots (Orb's, left empty)

For a main-story episode the same five columns apply, but their beats are Orb's. The templates here leave only these labelled slots; the generator never fills them, and a filler template never reads them:

| Slot | Meaning |
|---|---|
| `ORB.episode.cold_open` | Orb writes: who, where, what happens. |
| `ORB.episode.rise` | Orb writes. |
| `ORB.episode.twist` | Orb writes. |
| `ORB.episode.escalation` | Orb writes. |
| `ORB.episode.climax` | Orb writes: the climax's opponent and place (at least). |
| `ORB.episode.cliffhanger` | Orb writes the card. |
| `ORB.arc.finale` | Orb writes the finale. |

## 7. What it needs

- **Game Design:** the filler kinds as the doors campaign.md 1.3 names; `episode_number` and `side_place` from the ledger; and whether a filler arc uses the same families with its own villain.
- **UI and Camera:** the one-line title card at the edge, and the beacon caption with the family icon.
- **Legal:** a screen of the filler kinds (the rescue's "stranded" wording, the game's rounds, the tournament's stage), and the Cyborg's three lines.
- **Tools:** a schema for `filler_templates` once Orb has marked the samples.
- **Orb:** the main story's slots are yours.

## 8. Questions for Orb

1. Are **these four kinds** the right filler, or do you want others (a festival, a heist, a rain day)?
2. Is **"Episode 12.5"** the right card, and should a standalone filler episode say **SIDE STORY** or take a number of its own?
3. Should the radio **call-out** ask ("Spar?") or only name ("A training ground ahead.")?
