# Dynamic introduction lines: what they say, keyed by who, where, when and what happened

Owner: Narrative and Fighter Identity. Version 1, 2026-10-16. Orb, 2026-10-16: "I want dynamic fighter introductions, I want them to play out different every time based on who is fighting, where they spawn in at, any other variables we can think of." This is the **lines** half. The shots are Camera's (`docs/camera/varied-intros.md`); the beats, the order and the gestures are the intro composer's (`dynamic-intros.md`, `pending/intro_plots.json`). The data is `pending/intro_lines.json` (64 lines); a sample for Orb's marks is in `voice-lab/homework/27-story-beats.md`. Every line passes the lint (`writing-quality.md` section 0). Everything is an option for Orb. Original; no franchise echoes.

## 1. The three phases, and which voice slot each fills

| Phase | When it plays | The slot in `dynamic-intros.md` | Lines |
|---|---|---|---:|
| **Touch-down** | A fighter lands (his crater forms; the line starts at least 24 ticks later so the landing is heard first) | `arrive_remark` | 20 |
| **First sight** | Each sees the other (the look in the template) | V5 `first_look` | 26 |
| **Staredown** | The crossing look: the left fighter speaks, the other answers (about 1.2 s each) | `staredown_pair` | 18 |

**The speakers.** The Protagonist and the rival, in Orb's voices (`writing-quality.md`): the Protagonist is quick, curious and worried about people; the rival is impatient, short and insulted. **The training dummy (the reference fighter) does not speak**; it is the thing they talk about. There are 6 first-sight lines and 2 staredown lines for it.

## 2. The keys a line can carry

A line is tagged with any of these; the more it names, the more specific it is.

| Key | Values | Where it comes from |
|---|---|---|
| `phase` | touchdown, first_sight, staredown | the intro's beats |
| `who` | protagonist, rival | the speaker |
| `vs` | rival, protagonist, dummy | the other fighter (the matchup) |
| `place` | city, town, ice, ocean, desert, mountains | the biome at the spot, and the settlement in view |
| `tod` | dawn, day, dusk, night | the sky |
| `history` | first, rematch, after_loss, after_win, flattened_city | the pair's record; for a run, the last stage |
| `pair` | an id | two staredown lines said together: the first, then the answer |

**The history keys, in plain words.** *first*: they have not met. *rematch*: they have, and there is no clear winner to point at. *after_loss*: the speaker lost last time. *after_win*: the speaker won last time. *flattened_city*: the speaker's side flattened a city in the last stage (the run state).

## 3. How the lines are chosen

1. Keep the lines whose phase and speaker fit and whose keys the match satisfies. A key a line doesn't name is "don't care".
2. **Specificity first.** A line that names place and history beats one that names only a place. Among equals, a seeded draw (the match seed and the phase) decides, in the presentation layer; the sim never reads it, and a replay shows the same lines.
3. **One line per fighter per phase.** At touchdown a fighter says either a place line or a time-of-day line, never both: place wins in a city or town; time of day wins elsewhere unless the place is ice or mountains, which have more to say.
4. **No repeat** of a line in the last ten intros (the seen memory the dialogue director already keeps).
5. **A line is optional.** If no line fits, or the line system chooses silence (`p`, from the plot), the intro plays without it. Lines never overlap, and none starts within 24 ticks of a landing.
6. **The plot's stance and angle** (`intro_plots.json`) can be added to these lines later as tags; the first set only uses the match keys.

## 4. What is in the 64

| | Count | The point |
|---|---:|---|
| Touch-down by place | 12 | Six places, each fighter once: a city is "lots of windows" to one and "nice skyline, shame about it" to the other |
| Touch-down by time of day | 8 | Dawn, day, dusk, night, each fighter once |
| First sight by history, each way | 20 | Five histories times two fighters, two lines each |
| First sight at the dummy | 6 | Three lines for each fighter |
| Staredown pairs | 16 | Eight pairs: a first meeting, a rematch, after a loss, after a win, a city, ice, night, and after a flattened city |
| Staredown at the dummy | 2 | One line each; the dummy does not answer |

A few, as they will read:

> **Touch-down in a city.** Protagonist: "Lots of windows here. Careful!" / Rival: "Nice skyline. Shame about it."

> **First sight, the rival after he lost last time.** "Last time was a fluke. Watch this."

> **Staredown, a rematch.** Protagonist: "I've been waiting for this all week!" Rival: "Then stop talking and start swinging."

> **Staredown at night.** Protagonist: "Can you see me in the dark?" Rival: "I can hear that grin from here."

## 5. The event fields these lines need

Camera's `varied-intros.md` section 6 lists what it needs from Encounter, World and Rendering. These are the **fields my lines need**, and where they overlap with Camera's.

| Field | Values | Camera also wants it? | Used by |
|---|---|---|---|
| `place` per spot | biome id including **ice** and **ocean** | yes (biome) | touch-down, staredown |
| `settlement` per spot | none, town, city | yes (settlement in view) | the place choice at touchdown |
| `tod` | dawn, day, dusk, night | yes (Rendering's band) | touch-down, staredown |
| `matchup` | both fighters' ids, with the **reference fighter** named | partly (the pair) | first sight, staredown |
| `history.meetings`, `history.last_winner` | counts and a slot | yes (the history hook) | first sight, staredown |
| `history.flattened_last_stage` | per fighter, true or false | no | first sight, staredown |
| `intro_line.start`, `.dur` | ticks | yes (so cuts avoid the first word) | all |
| `intro_line.slot`, with `place`, `tod`, `history` echoed | strings | no | the line system's pick |

The first four are already on Camera's list; the last three are new. The dummy as a named matchup (the reference fighter's id) is the smallest of them.

## 6. What it needs

- **Encounter (the intro composer):** the match context in `intro_start` (place and settlement per spot, the time of day, the matchup, the history); the V5 `first_look` slot to be sent in the first-sight beat.
- **World and Rendering:** the biome with ice and ocean, the settlement kind, and the time-of-day band.
- **Game Design (run mode):** the "flattened a city last stage" flag per fighter; the stage number.
- **Camera:** the staredown family's timing so the left fighter's line lands across the face cut and not across a hard cut.
- **UI:** a caption with the face cut-in during the intro (Camera turns the HUD off until the clock).

## 7. Risks

- **The dummy is a prop, so its lines belong to the other two.** If Orb wants the dummy to speak, it will need a voice.
- **"Ocean" and "ice" as starting places are odd:** fighters land on open ground, and the planet's ice sheets and sea ice need to count as ground for a touch-down. If they cannot, those lines wait.
- **The first set has two speakers.** The Empress and the Cyborg get theirs when they join the roster.
- **Unmarked.** None of these 64 has been marked by Orb; none ships until they are.

## 8. Questions for Orb

1. Should a fighter **comment on the place** at all, or only the other fighter?
2. Are **the dummy lines** a good joke or a distraction?
3. Do you want the rival's **first-sight lines** to mention the last stage's damage, or leave it to the Protagonist?
4. Is **one line each** (touch-down, first sight, staredown) the right amount, or too much before a fight?
