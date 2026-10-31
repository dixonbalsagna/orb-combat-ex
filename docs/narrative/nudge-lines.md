# Nudge lines: the voice line that justifies a gentle turn

Owner: Narrative and Fighter Identity. Version 1, 2026-10-31. **Paper only; every line is a draft for Orb to mark.** Nothing is in the game or in `data/`. Orb (`docs/ep/vision.md`, "The fight's bearing"): the world may gently nudge a player's fighter toward a landmark during a flight, with no moment where the player wonders why the character began turning, and "cases like these could often be justified with a voice line." This page is the lines. It waits on Game Design's section 13 (`docs/world/ring-any-angle/game-design.md`, not written yet) for **when** a nudge fires.

## 1. What the line is for

A nudge is only fair if the fighter appears to choose it. So the line does one job: **it tells the player what the fighter has noticed, in the fighter's own voice, just as the turn begins.** The player hears "Open water dead ahead!" and the small bend toward the sea reads as the fighter's idea. A stick held at full speed never feels hijacked. Three rules follow:

1. **The line is the licence.** A nudge above the silent size (Game Design's number) fires only if its line can play. If the bark limits would hold the line back, the nudge is held or made smaller. A big silent turn is the one thing Orb ruled out.
2. **Early, and true.** The line plays at the start of the bend, never after it. It names a thing that really is ahead (the landmark's class), never a vague "something's there".
3. **Small turns stay silent.** Most nudges are a degree or two and need no line. Lines are for the noticeable ones, a few a match.

## 2. Kinds of line

| Kind | What the fighter does | Class tags (what he saw) |
|---|---|---|
| **Notice** | Spots a feature ahead and invites or taunts the opponent toward it | `water`, `coast`, `open`, `high`, `ridge`, `tower`, `seawall`, `road`, `hulls`, `wear`, `cranes`, `wreck` |
| **Pull** | His own ground calls (the claim in `opponent-grounds.md`), so the bend is a homeward lean | `home` |
| **Own choice** | A neutral line naming no landmark: he simply decides where to go, for a small bend with nothing worth naming | `own` |

Each fighter has lines for the classes his claim suits (water and open ground for the Protagonist, height for the Rival, plains for the Empress, wreckage for the Cyborg), plus a `tower` and a `home` line. A class is a tag on the landmark, never a place name, so a rename of any ground costs nothing here.

## 3. How they fit the voice rules and the slots

- **The mid-combat rules apply as they are:** 4 to 15 words, a complete clause preferred to a telegram, contractions, tactile words rotated (no "ribs", "shoulder", "rhythm" or "calories" in neighbouring beats), the banned word list, the lint. Every line is **aimed at the opponent**: it invites, taunts or dares him toward the landmark. None talks to the scenery. The fighter's voice bible holds: no Protagonist apology, no "Pathetic" for the Rival, the royal "we" and about one laugh in three for the Empress, no waiter words and no people words for the Cyborg.
- **Two new beats in `live_barks.json`** when this goes in: `nudge_notice` and `nudge_pull`. Each line carries its class tag and the same `cues`, `source` and `lint` fields as today. The speaker is the fighter being nudged.
- **One new presentation read.** The emitter reads a new event, say `world_nudge {actor, class, size, tick}`, sent by whoever computes the nudge (Game Design's section 13 decides who). Only the class and size are read, so the bark stays a function of (seed, tick, events) and the sim's hash is untouched, as with the other 16 beats. The line is chosen by (fighter, class); a `home` nudge uses a `home` line.
- **Limits:** the existing ones (8 seconds a fighter, 4 a minute, 3 seconds between any two, 180 seconds a line). A nudge line outranks an ordinary bark (priority 3 against 2) so it is not the one dropped. The caption time is the new one (up to 4.4 seconds).
- **No names.** A line says "that tower", "my ground", never a place name, so the four home names stay in one table.

## 4. Legal's limits (RL-213 to RL-215), and where they bite

- **No line says people are the goal** (RL-213 (3)). No line says a swing or a nudge brings the fighter to people. No line mentions people, a crowd or a toll. **Orb's own example** (Bolus nudged toward a city to fill his meter) is kept to steel: the Cyborg's lines name wreckage, hulls, cranes and broken steel, never a city or what is in it. His hunger is for wreckage and fighters only (`voice-bibles.md`, Legal condition 4). **RL-216 (EP, 2026-10-31):** fine are lines like "Smells like scrap that way" and "Sensors say there's metal east", and neutral lines like "I'll take the long way"; not fine is anything naming people or a crowd as the draw ("dinner's in the city") or reward language. The Cyborg feeds by putting scrap into the grille or chest, with no biting, chewing or swallowing words, and so I took "free fuel", "refill" and "snack" out of his nudge lines.
- **A landmark is a structure, terrain or a place's wear,** never a school, hospital or place of worship (RL-213 (2), RL-214). So there is no chapel and no bell tower class, only `tower`.
- **A line never answers the toll** (RL-213 (5), RL-215). The class tag comes from the ground ahead; nothing in whether a line fires reads casualties, crowd or menace. The Cyborg's `wear` class means a place's wear state, not what happened in it.
- **The hero leads toward empty ground** (RL-213 (5)): the Protagonist's lines go to water, open ground and shoreline, which is also his claim.
- **Originality:** every line is ours; none echoes another work. Two lines are near the approved ground lines (the Rival's home, the Empress's plains) and were reworded so none repeats.

## 5. What this needs from Game Design's section 13

1. **When a nudge fires, and its silent size:** the angle or rate below which no line is needed, and the size above which the line is required.
2. **How early:** how many tenths of a second before the bend the line should start, and whether a held full-speed flight gets a longer lead.
3. **How often:** a cap per match, so the lines stay rare. My guess is two to five.
4. **Who is nudged:** the player's fighter only, or an AI fighter too (an AI fighter's line is free colour).
5. **Where the class comes from:** the landmark list the picker already scores (`encounter.md`), mapped to my tags, so I do not invent classes the game cannot report.

## 6. Twenty-four drafts for Orb to mark (six a fighter)

Mark **x** to keep, **alt** to ask for another (I will write one), or type your own. The last row for each fighter (`own`) is a neutral line that reads as his own choice, with no landmark named. Lint run: 24 lines, 0 failing, no repeats of any approved line.

| id | Fighter | He sees (class) | Line | Mark |
|---|---|---|---|---|
| NL-01 | Protagonist | `water` | Open water dead ahead! Follow me out over the waves! | |
| NL-02 | Protagonist | `open` | Nothing out there but empty ground! Let's cut loose! | |
| NL-03 | Protagonist | `tower` | See that tower? Let's circle it and find out who's faster! | |
| NL-04 | Protagonist | `home` | My old stomping ground's coming up! Try to keep up! | |
| NL-05 | Protagonist | `coast` | Let's take this down the shoreline, where there's room to swing! | |
| NL-06 | Rival | `high` | Higher ground ahead. Try to keep up, amateur. | |
| NL-07 | Rival | `ridge` | Follow me up that ridge. You'll lose there. | |
| NL-08 | Rival | `tower` | That tower's tall enough to watch you drop from. | |
| NL-09 | Rival | `home` | My ground's close. Mind the stairs, eyesore. | |
| NL-10 | Rival | `seawall` | Sea wall coming up. I'll finish this on it. | |
| NL-11 | Empress | `open` | Hahaha! Look at all that flat land, rat! Run across it! | |
| NL-12 | Empress | `tower` | A fine tall tower ahead! We'll finish you in its shadow! | |
| NL-13 | Empress | `road` | A straight road, insect! Run along it while we watch! | |
| NL-14 | Empress | `home` | Our own plains are near! Come and bleed on them! | |
| NL-15 | Empress | `coast` | That long straight coast is perfect for our beam, clown! Gahaha! | |
| NL-16 | Cyborg | `wreck` | Wreckage ahead! Scrap straight into the grille! | |
| NL-17 | Cyborg | `hulls` | Smells like scrap that way! Race me to those hulls! | |
| NL-18 | Cyborg | `wear` | Broken steel ahead! Straight into the chest furnace it goes! | |
| NL-19 | Cyborg | `home` | My scrapyard's close! Plenty of rust to burn through! | |
| NL-20 | Cyborg | `cranes` | Rusty cranes ahead! My chassis is already humming! | |
| NL-21 | Protagonist | `own` | I'll take the long way round! Try to keep up! | |
| NL-22 | Rival | `own` | I'll pick the ground this time. Follow me. | |
| NL-23 | Empress | `own` | We choose the road, insect! Follow, if you dare! | |
| NL-24 | Cyborg | `own` | Sensors say there's metal east. I'm heading that way! | |

**Trusted most:** NL-01, NL-07, NL-16. **Weakest:** NL-05 (the Protagonist's longest) and NL-15 (the beam tie is a stretch).
**For Legal to read closely:** the Cyborg's NL-16 to NL-20 and NL-24 (feeding on scrap through the grille or chest, as Orb's city example is turned into wreckage), and "bleed on them" in NL-14.
