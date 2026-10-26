# Story-beat templates for the co-op campaign: 30 templates, 45 samples

Owner: Narrative and Fighter Identity. Version 2, 2026-10-23 (Legal's ln05 applied: section 6). The EP's brief: a template library for the between-stage story beat that works for **any** of the three co-op campaign pitches in homework 41 (**A** the Planet Run, **B** Episodes, **C** the Siege). **Slots only, no new lore and no new names: Orb writes the universe.** Nine families, about thirty templates, the slots each reads, voice hooks for each fighter, Legal's ln04 for the Cyborg, and five filled samples a family for Orb to read. The data is `pending/beat_templates.json` (the samples there are lint-checked). It builds on `story-beats.md` (the run's grammar) and `opponent-grounds.md` (the claims). Every sample line follows the voice bibles and passes the lint. Sample place names are placeholders. Nothing is marked by Orb.

## 1. The idea

A **template** is a small plan for a beat: which slots it reads, when it may play, and what each line does (an opponent speaks to the player, the partner needles, a radio reports). The lines themselves come from each fighter's voice. The picker chooses by the same rule as the run's beats: keep the templates whose conditions fit, score by how many slots they read and how rare they are, play the best, and play nothing if none fits. A beat is two or three lines, skippable, and never decides an outcome.

**How the three campaign shapes use it.** **A (Planet Run):** the beat card between nodes, plus detour nodes (`ambush_road`). **B (Episodes):** the episode's five parts map onto families: cold open (`arrival`), rising (`grudge`, `rematch`), twist (`third_party`, `ally_switches`), climax (`boss_taunt`, `home_threat`), cliffhanger (`cliffhanger`). **C (Siege):** `cliff_front` and `home_threat` carry the stakes; the board's move is a place and its wear.

## 2. The slots

| Slot | What it is |
|---|---|
| `opp` | The opponent fighter of the stage (a roster id; the display name comes from the names file). |
| `p1` | The first player's fighter. |
| `p2` | The second player's fighter, or the CPU partner. Absent in a solo run. |
| `ally` | Whichever of p2 or a CPU partner is on the player's side. |
| `third` | A fighter who is neither opponent nor player (a roster id), or `silhouette` when unknown. |
| `home` | The opponent's home place name (World's homes: Mendquay, Rankhold, Crownreach, Slagholt; names pending Orb). |
| `home_wear` | The home place's wear state: untouched, damaged or fallen. A place state only. |
| `place` | This stage's place name. |
| `prev_place` | The previous stage's place name. |
| `claim` | The opponent's claim phrase (listed below), from World's ring claim. |
| `last` | The last result between these fighters: none, won, lost, won_close, lost_close, draw (time cap). |
| `wrecked` | What the last meeting wrecked, from events the sim has: a tower, a crater, a fire, the pier (or `nothing`). |
| `mode` | 1v1, 2v1 (co-op vs one), 3v1 (the Empress and her guards), or horde. |
| `n_left` | Stages left before the boss. |
| `next` | The next stage's opponent and place, for a cliffhanger. |
| `toll_band` | none, some or many: a coarse band of the run's toll. NEVER read by a Cyborg line (Legal ln04) and never worded as a score (c08). |

**Claim phrases** (from World's ring claims, `{claim}`): Rival: "the high ground", Empress: "the open ground", Cyborg: "the wreckage", Protagonist: "the water".

## 3. Voice hooks, by fighter

- **Protagonist.** Warm, quick, tactile. He grins, grades the blow, asks for the opponent's best. Concern for people is said to the opponent ("Fight me over here"). No apology during a fight; an apology and an offer to rebuild come after the fight. *Never:* an apology during a fight; a righteous speech; talking to objects or off-screen helpers.
- **Rival.** Short, clipped, contractions. Live trash talk and the rank gag, now and then (third-rate, barely top ten, amateur, clown). Denies the opponent's skill; never admits respect openly; hates a head start. *Never:* Pathetic; I dare you; tired complaints.
- **Empress.** Royal "we", a booming laugh (Hahaha, Gahaha), sadistic and theatrical. Insults: rat, insect, clown. "Petitioner" at most once a beat and rarely. Never calls a guard in a 1v1; in a 3v1 she commands them. *Never:* calling guards in a 1v1; whining about her silk; dry bureaucratic jokes.
- **Cyborg.** Ravenous bio-mech: protein, calories, chassis, limiter, sensors, snack, wreckage as fuel. Loud and lurching, never polite. No "sir", no waiter, chef or restaurant words. **Legal ln04:** he reads a place's wear state (damaged, fallen) and a thing wrecked, never a casualty count (`toll_band` is not a slot for him), never a person, never a toll. No line, caption or card mentions people at a fallen place. No advantage grows with deaths. Nothing about him changes with the toll. *Never:* sir, madam, menu, table, chef, order, kitchen; a line that changes with casualties; hunger for civilians or children.

A partner or a third fighter speaks in their own fighter's voice. A radio or a civilian is plain (the run's grammar).

## 4. The rules every template follows

- Slots only; no new lore or names.
- A beat is two or three lines (4 to 12 words each), skippable, and never decides an outcome.
- A place state (untouched, damaged, fallen) and a thing wrecked are readable; a casualty count is not, and never for the Cyborg (ln04).
- A home is colour and set piece, never numbers.
- The Protagonist apologises only after a fight.
- The Empress's guards speak only in a 3v1 (mode 3v1).
- At most two beats a gap (one aftermath, one ahead), as in story-beats.md.

## 5. The templates and the samples

### Arrival

Someone is already there, or a stage opens on a claim.

| Id | Name | Reads | When | Fits | Notes |
|---|---|---|---|---|---|
| `arr_waiting` | Waiting at home | `opp`, `home`, `p1` | The stage is the opponent's home or a place its claim picked | A B C | The home is colour and set piece, never numbers. |
| `arr_claim` | A claimed ground | `opp`, `claim`, `place` | A ring was picked by the opponent's claim | A B C |  |
| `arr_horde_first` | The warm-up crowd | `opp`, `place`, `mode` | A horde stage comes first, the opponent after | A B C | Henchmen carry no lines of their own and no names. |
| `arr_first_stage` | Home, and a visitor | `p1`, `home`, `opp` | First stage of a run, round the player's own home | A B | Shown at most once a run. |

**Five filled samples** (placeholder names):

*arr_waiting* (opp=RIVAL, home=Rankhold, p1=PROTAGONIST)
> **Rival:** "Took you long enough. Come up, amateur."
> **Protagonist:** "Nice view! Is the whole stair yours?"

*arr_claim* (opp=EMPRESS, claim=the open ground, place=Furrowlea)
> **Empress:** "Our plains now, petitioner. Admire the horizon!"
> **Protagonist:** "Flat and clear. I'll see you coming!"

*arr_waiting* (opp=CYBORG, home=Slagholt, p1=PROTAGONIST)
> **Cyborg:** "Come in! Plenty of scrap, plenty of room!"
> **Protagonist:** "Big yard! Where do the cranes go?"

*arr_first_stage* (p1=PROTAGONIST, home=Mendquay, opp=RIVAL)
> **Protagonist:** "Same crooked plank. Good to be home!"
> **Rival:** "Cute pier. Shame about the company."

*arr_horde_first* (p1=PROTAGONIST, ally=RIVAL, mode=horde)
> **Protagonist:** "Warm-up crowd! Save some for me!"
> **Rival:** "Keep up. I'm taking the left."

### Grudge

A past event, held against the player.

| Id | Name | Reads | When | Fits | Notes |
|---|---|---|---|---|---|
| `grudge_wrecked` | You wrecked my ground | `opp`, `wrecked`, `home` | The player wrecked something on the opponent's ground earlier | B C | A thing wrecked, never a person. |
| `grudge_humbled` | Humbled, returning | `opp`, `last` | last is won (the player beat them) | A B C |  |
| `grudge_unfinished` | Unfinished business | `opp`, `last` | last is draw (the time cap) | B C |  |

**Five filled samples** (placeholder names):

*grudge_wrecked* (opp=EMPRESS, wrecked=a tower, home=Crownreach)
> **Empress:** "You broke our tower, rat. We'll break your arm."
> **Protagonist:** "Fair! Hit me as hard as you like!"

*grudge_humbled* (opp=RIVAL, last=won)
> **Rival:** "Lucky swing. I've been counting the days."
> **Protagonist:** "Count harder! I've been training too!"

*grudge_unfinished* (opp=CYBORG, last=draw)
> **Cyborg:** "Time called it. My stomach didn't!"
> **Protagonist:** "Fine! Round two. Bring more plating!"

*grudge_wrecked* (opp=CYBORG, wrecked=a crater, home=Slagholt)
> **Cyborg:** "You left good wreckage back there. Thanks!"
> **Protagonist:** "Don't thank me. Fight me!"

*grudge_humbled* (opp=RIVAL, ally=EMPRESS (co-op))
> **Rival:** "You, the loud one. I owe you a rematch."
> **Empress:** "Hahaha! Come and collect, clown!"

### Rematch

Who beat whom, and what was wrecked.

| Id | Name | Reads | When | Fits | Notes |
|---|---|---|---|---|---|
| `rematch_beaten` | They beat you | `opp`, `last` | last is lost | B C |  |
| `rematch_beat_them` | You beat them | `opp`, `last` | last is won | B C |  |
| `rematch_close` | A near thing | `opp`, `last` | last is won_close or lost_close | B C |  |
| `rematch_wreck` | What was wrecked | `opp`, `last`, `wrecked`, `prev_place` | last was at prev_place and left something wrecked | B C | For the Cyborg the wreckage is fuel; nothing about people (ln04). |

**Five filled samples** (placeholder names):

*rematch_beaten* (opp=RIVAL, last=lost)
> **Rival:** "Back again? I ranked you last time."
> **Protagonist:** "Rank me again. I'll climb!"

*rematch_beat_them* (opp=EMPRESS, last=won)
> **Empress:** "We let you win, rat. Try that twice!"
> **Protagonist:** "You let me? Then let me again!"

*rematch_close* (opp=RIVAL, last=won_close)
> **Rival:** "A fluke. Flukes don't repeat."
> **Protagonist:** "Then show me the real one!"

*rematch_wreck* (opp=CYBORG, wrecked=a crater)
> **Cyborg:** "Your crater's still warm. Good steel in it!"
> **Protagonist:** "Keep your eyes on me, not the dirt!"

*rematch_beat_them* (opp=EMPRESS, last=draw)
> **Empress:** "Time ended it. We refuse to be timed!"
> **Protagonist:** "Ha! Then no clock this time!"

### Ambush

A fight nobody chose.

| Id | Name | Reads | When | Fits | Notes |
|---|---|---|---|---|---|
| `ambush_road` | On the road | `opp`, `place` | An unplanned fight between stages (A: a detour node; B: a twist) | A B C |  |
| `ambush_drag` | Dragged to their ground | `opp`, `claim`, `home` | The opponent's claim pulls a stage onto their ground | A C |  |
| `ambush_split` | One of you alone | `opp`, `p1`, `p2`, `mode` | Co-op: the opponent catches one player apart from the partner | A B C | Never a rule that punishes the split. |

**Five filled samples** (placeholder names):

*ambush_road* (opp=RIVAL, place=the coast road)
> **Rival:** "Did you think the road was empty?"
> **Protagonist:** "Oh, hello! Ready when you are!"

*ambush_drag* (opp=CYBORG, home=Slagholt, claim=the wreckage)
> **Cyborg:** "Shortcut! It goes right through my yard."
> **Protagonist:** "This is not on the map!"

*ambush_split* (opp=EMPRESS, p1=PROTAGONIST alone, ally=RIVAL)
> **Empress:** "Only one of you? How careless, rat."
> **Rival:** "Careless? I'm exactly where I meant to be."

*ambush_road* (opp=PROTAGONIST, p1=RIVAL)
> **Protagonist:** "Surprise! I've been waiting up here!"
> **Rival:** "Predictable. I counted your footsteps."

*ambush_road* (opp=RIVAL, mode=2v1)
> **Radio:** "Streets are clear. Something is coming this way."
> **Protagonist:** "Everyone inside! I'll meet it!"

### A third party arrives

A fighter who is neither opponent nor player.

| Id | Name | Reads | When | Fits | Notes |
|---|---|---|---|---|---|
| `third_interrupts` | A third arrives mid-fight | `third`, `opp`, `p1` | A third fighter arrives while two fight | B C | Never names a third beyond the roster. |
| `third_steals` | A third takes the prize | `third`, `opp` | The opponent's claim (its wreckage, its high ground) is taken | B C |  |
| `third_watches` | Someone is watching | `third`, `place` | A third is on the ring and not fighting | A B C |  |

**Five filled samples** (placeholder names):

*third_interrupts* (third=EMPRESS, opp=RIVAL, p1=PROTAGONIST)
> **Empress:** "Hahaha! Carry on. We'll take the winner."
> **Rival:** "Stay out of this."
> **Protagonist:** "The more the merrier! Who's first?"

*third_steals* (third=CYBORG, opp=RIVAL)
> **Cyborg:** "That wreck is mine. I smelled it first!"
> **Rival:** "Back off, scrap. I'm busy."

*third_watches* (third=silhouette, place=the ridge)
> **Radio:** "Someone's watching from the ridge. Not moving."
> **Protagonist:** "Let them look. Show them something!"

*third_interrupts* (third=PROTAGONIST, p1=RIVAL)
> **Protagonist:** "Need a hand? Keep your guard up!"
> **Rival:** "I didn't ask. Stay out of my way."

*third_watches* (third=silhouette)
> **Radio:** "Nobody knows who it is yet."
> **A civilian:** "Is that another fighter?"

### An ally switches

A partner or an opponent changes sides.

| Id | Name | Reads | When | Fits | Notes |
|---|---|---|---|---|---|
| `ally_leaves` | The partner goes | `ally`, `opp` | A CPU partner leaves the player's side | B C | Co-op only if the partner is the CPU's; a human partner never leaves. |
| `ally_arrives` | An opponent helps | `opp`, `p1` | An opponent fights with the player for one stage | B C |  |
| `ally_torn` | The partner hesitates | `ally`, `opp` | A partner is split between two claims | B C |  |

**Five filled samples** (placeholder names):

*ally_leaves* (ally=RIVAL (CPU), opp=EMPRESS)
> **Rival:** "I rank myself first. Goodbye, amateur."
> **Protagonist:** "Fine! I'll beat you both!"

*ally_arrives* (opp=EMPRESS, p1=PROTAGONIST)
> **Empress:** "Hahaha! We choose our side. Today, yours."
> **Protagonist:** "Welcome aboard! Try to keep up!"

*ally_torn* (ally=CYBORG, opp=RIVAL)
> **Cyborg:** "Wrecks on both sides. I'm torn!"
> **Protagonist:** "Pick me! I promise a good fight!"

*ally_leaves* (ally=RIVAL returns)
> **Rival:** "I never switched. I outranked you."
> **Protagonist:** "Sure! Whatever you say!"

*ally_leaves* (ally=EMPRESS (CPU))
> **Empress:** "Partners? We have a court."
> **Protagonist:** "Then bring your court along!"

### A home under threat

A place that matters is in danger, or is wreckage.

| Id | Name | Reads | When | Fits | Notes |
|---|---|---|---|---|---|
| `home_player` | The player's home | `p1`, `home`, `home_wear` | The player's own home is damaged or in danger | A B C | A place and its wear only, no counts. |
| `home_opp` | The opponent's home | `opp`, `home`, `home_wear` | The opponent's home is threatened by a third | B C |  |
| `home_wear` | Home is wreckage | `opp`, `home`, `home_wear` | home_wear is damaged or fallen | B C | The Cyborg's lines read WEAR STATE only: never a casualty count, never people (ln04). |
| `home_after` | After the fight, the mending | `p1`, `home`, `place` | After a stage that damaged a home | A B C | The apology is after the fight, never during it (Orb). |

**Five filled samples** (placeholder names):

*home_player* (p1=PROTAGONIST, home=Mendquay, home_wear=damaged)
> **Radio:** "Smoke over Mendquay! The pier's burning!"
> **Protagonist:** "Not my pier! Move, move!"

*home_opp* (opp=RIVAL, home=Rankhold, home_wear=damaged)
> **Rival:** "Someone's climbing my stair. Hold the fight."
> **Protagonist:** "Go! Then I want my turn!"

*home_wear* (opp=CYBORG, home=Slagholt, home_wear=fallen)
> **Cyborg:** "Home's all wreckage now. Lovely fuel!"
> **Protagonist:** "Come on, then. Fight me for it!"

*home_opp* (opp=EMPRESS, home=Crownreach, home_wear=damaged)
> **Empress:** "Someone cracks our banners? Move, rat!"
> **Protagonist:** "Go! I'll wait right here!"

*home_after* (p1=PROTAGONIST, home=Mendquay  [after the fight])
> **Protagonist:** "Sorry about the pier, everyone. I'll help rebuild."
> **A civilian:** "Just don't break it twice!"

### The boss's taunt

The boss speaks before or after the stage.

| Id | Name | Reads | When | Fits | Notes |
|---|---|---|---|---|---|
| `taunt_afar` | From afar | `opp`, `n_left` | n_left is 2 or more; the boss reaches the player before the stage | A B C |  |
| `taunt_arrival` | On arrival | `opp`, `claim` | Boss stage starts | A B C |  |
| `taunt_loss` | After a loss | `opp`, `last` | last is lost to the boss | A B C |  |

**Five filled samples** (placeholder names):

*taunt_afar* (opp=EMPRESS, n_left=3)
> **Empress:** "We are watching, rat. Do hurry up!"

*taunt_arrival* (opp=CYBORG, claim=the wreckage)
> **Cyborg:** "Tick tock, snack. My stomach's counting!"
> **Protagonist:** "Let it count. I'm ready!"

*taunt_loss* (opp=RIVAL, last=lost)
> **Rival:** "That's all? Third-rate, start to finish."
> **Protagonist:** "Again! I just found your timing!"

*taunt_arrival* (opp=EMPRESS, ally=RIVAL)
> **Empress:** "Your friend looks lost, rat. Poor thing!"
> **Rival:** "Lost? I'm taking your crown."

*taunt_arrival* (opp=RIVAL, home=Mendquay)
> **Rival:** "Your pier's still crooked. So are you."
> **Protagonist:** "Crooked but standing! Come and see!"

### Cliffhanger: next time

The end of an episode, or a front that moved.

| Id | Name | Reads | When | Fits | Notes |
|---|---|---|---|---|---|
| `cliff_next` | Next time | `next`, `opp`, `home` | The end of an episode (B) or a node (A) | A B |  |
| `cliff_shadow` | A shadow | `third` | The end of an episode with a twist unresolved | B |  |
| `cliff_front` | While you fought | `place`, `n_left` | C: a front moved while the player fought elsewhere | C | A place and its wear only: no toll, no remains (c08, ln04). |

**Five filled samples** (placeholder names):

*cliff_next* (next=RIVAL at Rankhold)
> **Radio:** "Next: Rankhold. Someone's waiting on the stair."

*cliff_shadow* (third=silhouette)
> **Radio:** "Someone's coming. We'll meet them next time."

*cliff_front* (place=the harbour (damaged))
> **Radio:** "While you fought, the harbour took damage."
> **Protagonist:** "Then let's go and help!"

*cliff_next* (opp=EMPRESS)
> **Empress:** "We will see you at the throne, rat."

*cliff_next* (ally=RIVAL (co-op))
> **Protagonist:** "Same time next stage? Don't be late!"
> **Rival:** "I'm never late. You're early."

## 6. Legal's ln05, enforced in the tools (2026-10-23)

Legal passed the library with three conditions (`docs/legal/beat-templates-screen.md`). They are now rules the tools check, not only words on paper.

1. **The Cyborg never reads a toll, and his lines never name people.**
   - **The lint** (`line-lint.py`, the `cyborg_ln04_ln05` tier in `line-lint.json`) now fails any line in a Cyborg block that contains people, person, civilians, kill/killed, dead, died, death, victims, bodies, corpse, remains, survivors, residents, villagers, townsfolk, children, kids, humans, population, toll, casualties, count or tally (whole words). "Gone" and "lost" print a CHECK for a human, because they must not be about people. It ran over all 117 Cyborg lines we have (homework, taunts, run lines, beats, templates, Gemini's 7); **it caught one**, "Two warm bodies!" (final_4_arrive_cyborg), which is now "Two of you! My stomach's been waiting!".
   - **The picker's filter** is `picker_rules` in `pending/beat_templates.json` and the function `usable()` in `beat-check.py`: a template is refused for a Cyborg opponent if it reads `toll_band` or any slot whose name contains toll, casualt, people, lost_n or count. `toll_band` and any count are never put into a Cyborg line's context at all.
2. **`wrecked` is a structure or terrain event only** (a tower, a bridge, a crater, a fire, the pier), never derived from a casualty event. **`home_wear` for the Cyborg is read only for his own breaking yard** (the home with no residents). Three templates read it (`home_player`, `home_opp`, `home_wear`) and each now carries `cyborg: {home_wear: own_yard_only}`; if his claim picks a town or city the template is off for him.
3. **Place and wear only** for the fronts and homes (`cliff_front`, `home_player`, `home_opp`, `home_wear`): no toll, count, body, school, hospital, place of worship or child as a victim. `beat-check.py` scans their sample lines for those words.

**Run it:** `python docs/narrative/beat-check.py` (30 templates, 45 samples, 9 Cyborg lines, 0 failing). Standard library only, and it runs in a second.

## 7. What it needs

- **Game Design:** which events fill `last`, `wrecked`, `home_wear`, `third` and `mode` in a co-op run (the run ledger), and whether a 3v1 beat is allowed.
- **World:** nothing new: a place name, its kind and its wear state.
- **UI:** the beat card already exists (`beat-card`); a partner's face cut-in needs a speaker tag for `ally`.
- **Tools:** a schema for `beat_templates` when Orb has marked the samples; it stays in `pending/` until then.
- **Legal:** passed with ln05 (above). The picker (whoever writes it) must apply `picker_rules`; `beat-check.py` is the reference.

## 8. Questions for Orb

1. Which sample lines sound right, and which fighter reads wrong? (Mark the samples.)
2. Should a partner (human or CPU) speak in a beat, or only the opponent and the radio?
3. How long should a beat be: one line, two or three?

**Provenance (ai01).** Every sample line here is drafted by Claude (Anthropic) from the voice bibles and carries `source: claude` in the data; no line is Orb's yet (Orb's marks will be recorded as `source: orb`). The public AI statement names categories, never vendors.
