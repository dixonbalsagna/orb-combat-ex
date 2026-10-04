# Dynamic intros: the content side

Owner: Narrative and Fighter Identity. Version 1, 2026-10-04. Answers the EP's brief from Orb ("if we can script a system that creates dynamic intros and mixes and matches different scenarios between characters I'd like to see it"). This is the **content**: what an intro is built from, eleven scenario templates as beat lists, which parts need a voice line (as slots, intent only: **Orb writes the lines**), and the rules that keep it coherent and fresh. The sim side is Simulation's and Encounter's (`docs/architecture/intro-phase.md`); this document changes none of it and says what it needs. Presentation text treats the player as the fighter. No franchise scenes, names or poses.

Read with: `docs/architecture/intro-phase.md` (the fixed timeline today), `docs/camera/rule-of-cool-shots.md` row 7 (the shot), `matchups.md` (stakes and registers per pair), `taunt-system.md` (the challenge and accept lines), `dialogue-director.md` section 3.3 (the seen memory), and `voice-lab/staredown-last-stand.csv` (the staredown lines Orb is editing; not touched here).

## 1. What there is today

One intro, always the same (`data/fight/intro.json`, 60 ticks a second): the left fighter (A, slot 0) falls from 6,000 units and lands in a crater at tick 36; the right one (B) falls at 84 and lands at 114; both stand from tick 144 (the staredown, with two face cuts); the clock starts at 300. Any press skips, with no change to the fight. It looks good (Orb's word is "pretty good") and it is the same every time. That is what the system below breaks up, **without** changing what the fight starts from: the end state at the clock stays two fighters on open ground, facing, with craters dug.

## 2. The axes an intro is built from

An intro is a **template** (a curated sequence of beats, section 4) with its **parameters** filled in from seven axes. Every axis is data, every choice comes from the seeded stream (section 7), and every choice is written into the match setup.

| # | Axis | Values | Where the value comes from |
|---|---|---|---|
| 1 | **Who arrives first, and who is already there** | A first, B first, both at once, one already there (the host) | The template, then the pair's `arrival.prefer` and `arrival.veto` (section 5). |
| 2 | **How each fighter arrives** | `drop` (falls and lands in a crater), `descend` (slow, composed, no crater), `retinue` (guard first, then the lead), `host` (already in place, doing something small) | Each fighter's `arrivals` list in data, weighted by character. The Protagonist drops, or descends if a settlement is in view; the rival descends or drops with no expression; the Empress arrives with her guard; the Cyborg drops on one knee with a polite bow. |
| 3 | **Where** | The biome the spots lie in (plains, desert, mountain foothills, and similar open ground), the altitude of the fall (high from the sky, or a low skimming landing), time of day, and whether a settlement is in view | The world's spots (`START_GAP` 900 on open ground) and its sky. Water spots are not used (a crater cannot be dug there). |
| 4 | **The relationship beat** | The pair's stakes and registers: `sparring`, `rivalry`, `world_at_stake`, `appetite` | `matchups.md`. It sets tone (section 7, rule 4) and picks which slots may speak. |
| 5 | **Each fighter's mood and form** | Calm, tense, frenzied (the fight-mood model); base form or a form carried in (arcade); fresh or wearing the last bout | The mode (versus, arcade ladder, survival) and the fight-mood model. |
| 6 | **A recent-history hook** | First meeting; a rematch (the number); who won last; how the last bout ended (a knockout, a planet scarred or destroyed, the time cap); a streak | A small local record per pair (section 6). |
| 7 | **The closing** | `hold` (the staredown, nothing more), `look-away` (one of them breaks the stare first), `dare` (a challenge and an accept, from the taunt system), `rush` (both launch at the clock) | The template; `dare` and `rush` need the sim's first-move support (section 9). |

**Two layers of mixing.** The **template** is curated, so every combination of beats is coherent. **Swap points** inside it let the parameters change without a new template: each template lists which axes may vary (section 4). So a pair of fighters does not only get a different template; it gets a different order, a different arrival and a different closing within one.

## 3. Roles, and a common vocabulary

A template is written in **roles**, not names, so it works for the Protagonist and the rival in either position, for mirror pairs, and for every other fighter.

| Role | Meaning |
|---|---|
| **First** and **Second** | Arrival order. Either fighter, either slot (the sim already puts A on the left spot, but First can be A or B). |
| **Host** and **Guest** | The Host is already in place (the Guest arrives). Chosen by the fighter's `host_activity` data, or by who "owns the ground" in the history. |
| **Winner** and **Loser** | Of the last meeting, for the history hook. |
| **Lead** and **Retinue** | A fighter with followers (the Empress and her guard) and the followers. |

**Times** are ticks from the intro's start (60 a second) for a typical run. They are the template's defaults, kept in data. **Voice slots** are named `V1` to `V11` (section 5) and are said by a role, never by a name.

## 4. The scenario templates

Eleven templates. Each has a tone (`light`, `neutral` or `grave`, which gates which pairs may use it), a length, the beats, the voice slots, what plays silent, and how it extends to four fighters. Where a template says "crater", it is World's entrance crater, scaled by `crater` (1.5 today; 0 digs none).

### S1. The Double Drop (the baseline, today's intro)

- **Tone:** neutral. **Length:** 5 s (300 ticks). **Use:** the default for any pair; the most common.
- **Beats:** 0 First falls. 36 First lands, crater. 84 Second falls. 114 Second lands, crater. 144 both stand; the staredown. 300 the clock.
- **Voice:** V1 (optional, by First, about 60), V1 (optional, by Second, about 150), V8 (the staredown pair, left-spot fighter first, then the other, about 1.2 s each).
- **Silent:** the falls, the landings, the staredown's push.
- **Swap points:** which fighter is First; each fighter's arrival (`drop` or `descend`); the gap between landings (30 to 70 ticks); the closing (`hold` or `look-away`).
- **Four fighters:** each falls and lands 30 to 50 ticks after the last; the staredown is the first two pairs of neighbours.

### S2. The Latecomer

- **Tone:** light or neutral. **Length:** 6.5 s. **Use:** a fighter who is impatient, or who wants to keep another waiting.
- **Beats:** 0 First falls. 36 lands. 50 to 170 First waits (an idle of the fighter's own: arms folded, stretching, checking the sky). The camera holds on the empty second spot and the sky. 190 Second falls, unhurried. 220 Second lands. 300 the staredown. 456 the clock.
- **Voice:** V2 (First, waiting, about 80), V3 (Second, about 250, on being waited on), V8.
- **Silent:** the wait itself, apart from V2, so the quiet is the joke.
- **Swap points:** the waiting idle (impatient, polite, bored); who is late (from the pair's `prefer`); the length of the gap (100 to 200 ticks).
- **Four fighters:** the last to arrive is the latecomer; each earlier fighter reacts in order as the last one lands.

### S3. The Same Instant

- **Tone:** light. **Length:** 4.5 s. **Use:** symmetrical pairs: mirrors, sparring peers, fighters who see each other as equals.
- **Beats:** 0 both fall together (a level two-shot, the two descending in step). 36 both land on the same tick, a shared dust cloud and two craters. 40 each turns toward the other on the same beat. 120 the staredown (short, 100 ticks). 260 the clock.
- **Voice:** V5 (one fighter only, the left, optional), V8.
- **Silent:** everything else; the match of the two landings is the point.
- **Swap points:** the arrival (drop or descend, the same for both); the closing.
- **Four fighters:** two drops together, two together, or all four on the same tick; the look goes round the ring.

### S4. Already There (the host)

- **Tone:** neutral or light. **Length:** 6 s. **Use:** a fighter with a small, characteristic thing to be doing.
- **Beats:** 0 the Host is in place at their spot, doing something small and characteristic (the Protagonist mending something, the rival sitting on a stone with his back half turned, the Cyborg with a sandwich, the Empress's guard arranging her place). 60 the Guest falls (the camera tilts up to a dot). 96 the Guest lands, crater; the Host's head turns last. 130 the Host finishes the task (puts it down, stands, swallows). 160 V5 or V8. 336 the clock.
- **Voice:** V4 (the Host, murmuring over the task, before the Guest lands), V5 (the Host's first words to the Guest), V8.
- **Silent:** the task; the camera's slow approach; the Host's one-beat pause.
- **Swap points:** who is Host (by fighter data); the activity (each fighter has two or three); the Guest's arrival.
- **Four fighters:** one host, the others arrive in turn; or two hosts back to back.

### S5. The Entourage

- **Tone:** light. **Length:** 6.5 s. **Use:** a Lead with a retinue (the Empress's guard of honour), against anyone, who arrives first and waits.
- **Beats:** 0 First (the opponent) falls. 36 lands, crater. 60 First waits. 100 the Retinue lands, one after another, in formation: the Shield, the Herald-Archer, the Runner, and the aide last (smaller craters, no collateral). 160 the Lead descends slowly between them, no crater, a ring of dust. 220 lands. 260 the aide's pained look at a wristwatch. 290 the staredown. 450 the clock.
- **Voice:** V9 (the guard's chorus, once, about 110), V2 (First, optional, about 80), V8. The aide's sigh is non-verbal and can stand in for V9.
- **Silent:** the formation; the aide's expression.
- **Swap points:** which guard members arrive and in what order; the Lead's descent; First's waiting idle.
- **Four fighters:** the Lead's retinue is her "second" in a free-for-all; others arrive around her.
- **Gate:** only a Lead with a retinue; the guard must be in the frame (Encounter, section 9).

### S6. The Rematch (the history hook)

- **Tone:** neutral, or grave if the last bout ended in a scarred planet. **Length:** 6 s. **Use:** any pair that has met.
- **Beats:** 0 the Loser falls (they have come early to prepare, or simply to wait). 36 lands. 60 the Loser waits. 130 the Winner descends, unhurried. 170 lands. 200 V6 (the history callback, one of them). 250 the staredown. 360 the clock.
- **Voice:** V6 (by the Winner or the Loser, intent by who won and how it ended: unfinished business, respect, gloating, a grudge), V8 (with a rematch variant if Orb writes one).
- **Silent:** the Loser's wait; the pointed look at the Winner's face.
- **Swap points:** who speaks V6; whether the Loser wears a mark of last time (a scuff, a torn cloth: a cosmetic only); the arrival modes.
- **Four fighters:** only the pair with a history gets the callback; the others keep their usual arrival.
- **Gate:** the record says the pair has met (section 6).

### S7. The Settlement in View

- **Tone:** grave or neutral. **Length:** 6 s. **Use:** stakes of `world_at_stake` or `appetite`, with a settlement close enough to see in the wide shot.
- **Beats:** 0 First falls. 36 lands (the Protagonist, near a settlement, lands soft: `crater` low; a villain lands hard). 60 First looks toward the settlement, a held beat (the camera shows the lights). 90 Second falls. 124 lands. 150 Second looks at the same settlement, or at First. 180 the staredown, with the settlement between and behind them. 340 the clock.
- **Voice:** V7 (the fighter who cares about the settlement, or the one who covets it), V8.
- **Silent:** the looks; the wide frame with the village's lights.
- **Swap points:** who looks first; whether the second fighter looks at the village or at the first; the landing's softness.
- **Four fighters:** each fighter's look is in character: protective, appraising, or hungry.
- **Gate:** a settlement within about 1,800 units of either spot (World knows); the stakes are not `sparring`.

### S8. Soft and Hard (the contrast)

- **Tone:** neutral. **Length:** 5.5 s. **Use:** a pair whose arrival modes differ.
- **Beats:** 0 First falls hard (a streak, a shake on the landing). 36 lands, a big crater. 84 Second descends slowly, composed, with no crater. 140 lands (a ring of dust, no impact). 150 First's reaction (a small, clipped look). 170 the staredown. 330 the clock.
- **Voice:** V1 (the soft arriver, after landing, unbothered), V8.
- **Silent:** the contrast itself.
- **Swap points:** who is soft (by fighter data); who is First.
- **Four fighters:** a mix of drops and descents, in order.
- **Gate:** the two fighters' preferred modes must differ (`arrivals`).

### S9. The Long Look (silent)

- **Tone:** grave. **Length:** 6 s. **Use:** a pair whose stakes are grave, or whose last bout was a disaster; the one scenario with no voice at all.
- **Beats:** 0 First falls (the sound drops out). 36 lands. 84 Second falls. 114 lands. 144 the staredown stretches to 260 ticks: a near-still two-shot, a wind, a push of 10%, then the two face cuts, held. 420 the clock, and the sound returns.
- **Voice:** none. **Silent:** everything.
- **Swap points:** the arrival modes; which face comes first.
- **Four fighters:** a long look round the ring, one face at a time.
- **Frequency cap:** one in six, and never twice in a row (section 7).

### S10. The Opening Challenge

- **Tone:** light or neutral. **Length:** 6 s. **Use:** a pair at `sparring` or `rivalry`, where both would accept.
- **Beats:** 0 First falls. 36 lands. 84 Second falls. 114 lands. 144 the staredown. 220 First performs the taunt gesture (a challenge, never a beckoning gesture). 270 Second answers by pressing forward, an accept. 300 the clock, and both rush.
- **Voice:** V11 (the taunt system's `challenge` line, First, and its `accept` line, Second, at the rush), V8 is dropped.
- **Silent:** the gesture; the rush.
- **Swap points:** who challenges; the gesture (each fighter's taunt gesture).
- **Four fighters:** the challenge is to the nearest, and the rest look on.
- **Needs:** the sim's first-move support (section 9). Without it the closing falls back to `hold` and the lines still play.

### S11. The Mirror

- **Tone:** light. **Length:** 5.5 s. **Use:** a fighter against themselves (the matchup matrix has four mirror pairs).
- **Beats:** 0 both fall together. 36 both land, mirrored, the same crater twice. 50 each turns on the same tick, then each stops, a half-beat late. 110 each tries to out-stand the other (a small, comic posture race). 160 V10, both at once. 220 the staredown. 330 the clock.
- **Voice:** V10 (each claims to be the real one, spoken at nearly the same instant: the one place lines may overlap), V8.
- **Silent:** the posture race.
- **Swap points:** the arrival; the posture.
- **Four fighters:** a mirror of each pair.
- **Gate:** the same fighter on both sides.

### Which templates suit which pairs

The pair's stakes and registers (`matchups.md`) set the tone, and the fighters' vetoes remove templates. A short guide (not a list of exclusions: the gates in section 7 decide):

| Pair | Likely | Often | Never |
|---|---|---|---|
| Protagonist v Anti-hero | S1, S4 (the Protagonist hosts, the rival lands), S6 | S2 (the rival late), S9, S10 | S3, S11 (not a mirror) |
| Protagonist v Empress | S5, S7, S9 | S1, S6 | S3, S10 (grave) |
| Protagonist v Cyborg | S7 (appetite), S1, S4 (the Cyborg hosts, eating) | S6, S8 | S3, S9 |
| Anti-hero v Empress | S5, S2, S8 | S1, S6 | S3, S10 |
| Anti-hero v Cyborg | S8, S1 | S2, S4 | S3 |
| Empress v Cyborg | S5, S4 | S1, S2 | S9, S10 |
| Mirror pairs | S11, S3 (not the rival's) | S1 | S2 |

## 5. Where a voice line goes: the slots

Slots carry **intent only**. Orb writes the lines (and the lines may later be tagged by pair, history and tone). Each slot has a speaker role, a point in the intro, a length cap in words (about 1.4 s of speech), and the facts it needs. A line is always optional: a template plays without it.

| Slot | Speaker | Intent | Cap | Needs |
|---|---|---|---|---|
| **V1 `arrive_remark`** | The arriver, after landing | A first word that sets the mood on arrival: nonchalant, solemn, amused, unbothered. | 5 words | none |
| **V2 `wait_remark`** | First, while waiting | How the waiting feels: impatient, patient, amused, a silent judgment turned into a word. | 8 words | S2 or S5 |
| **V3 `late_reply`** | Second, on landing late | Unbothered, dismissive, mock-apologetic; the answer to being waited on. | 8 words | S2 |
| **V4 `host_mutter`** | The Host, over the task | Absorbed in a small job and a little annoyed to be interrupted. | 7 words | S4 |
| **V5 `first_look`** | Either, at the look | An appraisal of the other: what has changed, what is the same. | 8 words | none |
| **V6 `history_callback`** | The Winner or the Loser | Unfinished business, a grudge, respect, gloating; varied by who won last and how it ended. | 10 words | `history` |
| **V7 `stakes_line`** | The fighter who cares, or covets | Protect, claim, or appraise what is in view. | 8 words | S7 |
| **V8 `staredown_pair`** | Both, left spot first, then the other (about 1.2 s each) | The pair's register, a call and an answer. These are the staredown lines in the voice lab; the director's ruling stands. | 8 words each | none |
| **V9 `retinue_call`** | The guard, in chorus; the aide may sigh | A formal salute or report; the aide's weary non-verbal beat. | 5 words | S5 |
| **V10 `mirror_claim`** | Both, nearly together | Each claims to be the real one. | 6 words | S11 |
| **V11 `dare` and `accept`** | First, then Second | The taunt system's `challenge` and `accept` lines, reused. | 4 words (accept) | S10 |

**Which parts play silent.** The falls and the landings (the impact audio carries them), the waiting in S2 and S5 except V2, the host's task, the formation, the looks, the long look in S9, the posture race in S11, the taunt gesture, the rush. Silence is a feature: **at most 3 lines in an intro, and an intro with V8 has at most 4**, so most of an intro is image and sound.

**Speech never covers the beats it belongs to.** No line starts within 24 ticks (0.4 s) of a landing, so the crater and its audio land first. No two lines overlap, except V10. Each line is a caption of about 1.4 s, and the intro's own face cuts (Camera's, at 240 to 288 today) carry the speaker's face; the UI's side cut-in is off during the intro (the HUD is hidden until the clock).

## 6. The history hook: a small record per pair

For the rematch hook (axis 6) the game keeps a small **local record**, `user://rivalry.json`, by **pair of fighters** (character ids, sorted), never by player, so it reads as story:

```json
{ "protagonist+rival": { "meetings": 4, "wins": { "protagonist": 3, "rival": 1 },
  "last_winner": "rival", "last_ending": "ko", "streak": { "who": "rival", "n": 1 },
  "planet_scarred": 1 } }
```

- **Facts the hook can state:** `first_meeting`, `rematch` (and the number), `last_winner`, `last_ending` (`ko`, `planet_scarred`, `planet_destroyed`, `time_cap`), `streak`, `rubber` (tied, deciding match).
- **Where it lives.** A few hundred bytes, local only, never sent anywhere, reset from a setting; the same local save family as the dialogue seen memory (`dialogue-director.md` section 3.3).
- **Online and replays.** The record is read by the **host**, and the chosen facts go into the match setup, so both clients and a replay see the same intro (section 7, rule 9).

## 7. The rules that keep it coherent and fresh

**Coherence.**

1. **Gates.** A template is eligible only if its facts are true: a history for S6, a settlement for S7, a retinue for S5, the same fighter on both sides for S11, differing arrival modes for S8, first-move support for S10's rush.
2. **Time order.** Nobody remarks on an arrival before it has happened, and a line never refers to what has not been shown.
3. **Fighter vetoes.** Each fighter's data has `arrivals` (the modes they use, weighted) and `veto` (templates they never take part in). The rival is never simultaneous (no S3; the mirror, S11, is the one comic exception) and is never early and waiting except as a Loser in S6; the Empress prefers to arrive with her guard (`retinue`) and may descend alone, subject to question 5; the Protagonist lands soft near a settlement (the pillar-5 personality term).
4. **Tone.** A template has a tone (`light`, `neutral`, `grave`); the pair's stakes allow a range. `world_at_stake` allows only `neutral` and `grave`, and no jokes in V1 or V2 there; `sparring` allows all three; `appetite` allows `light` and `neutral`. The tone carries through to V8 (the staredown matches the arrival), so a comic arrival never runs into a grave stare.
5. **Register.** A line comes from the pair's register in `matchups.md` (the Protagonist warm to the rival and grim to the Empress; the Empress leering).
6. **Voice devices hold.** The Anti-hero's lines keep no contractions and the past tense; the Empress her "we"; and so on. (Orb is editing the voice lab; the devices follow his pass.)
7. **Length.** An intro is 4.5 to 7 s on first sight. The player can always skip with any press, with the same state at the clock. A **short mode** (a setting, and automatic after a session's tenth intro) drops to 3 s: no V1 to V7, V8 only. A **classic** setting always plays S1.
8. **Accessibility.** Under reduced motion each template falls back to Camera's still, dissolving cuts (no falls with shake, no push); every line has a caption; no flashing.

**Freshness.**

9. **Determinism.** The template and all parameters are chosen from a **seeded stream** (the match seed plus the constant `"intro"`), with weights, and written into the setup's `intro` record (`scenario`, `order`, `arrivals`, `closing`, `facts`), so the replay and an online peer reproduce the intro exactly. The selector reads the history record only on the host, and sends its facts in the setup.
10. **No repeat of a template** within the last **5 intros of the same pair** or the last **3 intros of any pair**. A template's weight is multiplied by 1 / (1 + recent uses), so repeats lose but never vanish when little else is eligible.
11. **No repeat of an arrival mode** by the same fighter two intros in a row; no repeat of a **line** within 10 intros (the seen memory); no S9 twice in a row and at most one in six.
12. **Rare things stay rare.** S9, S10 and S11 carry low base weights, so a player meets them as an occasion.
13. **Honest count.** With 11 templates, two orders, about 6 compatible arrival combinations, four closings and a few times of day, a pair has **a few thousand variants**, but a player recognises a *template* after a few uses, so the freshness that matters is the 11 skeletons and the swap points, and **about 8 to 10 intros between two that feel alike** with the no-repeat rules. Lines add more.

**The data shape (a sketch, for Encounter and Tools).**

```json
{ "id": "s2_latecomer", "tone": "neutral", "ticks": 456,
  "gates": ["not:grave"], "weight": 1.0,
  "swap": ["wait_idle", "gap", "closing"],
  "beats": [
    { "t": 0,   "kind": "fall",  "role": "first" },
    { "t": 36,  "kind": "land",  "role": "first", "crater": 1.0 },
    { "t": 50,  "kind": "wait",  "role": "first", "idle": "$wait_idle" },
    { "t": 80,  "kind": "line",  "role": "first", "slot": "V2" },
    { "t": 190, "kind": "fall",  "role": "second" },
    { "t": 220, "kind": "land",  "role": "second", "crater": 1.0 },
    { "t": 250, "kind": "line",  "role": "second", "slot": "V3" },
    { "t": 300, "kind": "staredown", "slot": "V8" },
    { "t": 456, "kind": "clock" } ] }
```

Beats are data, roles resolve to slots at setup, and **the sim only needs the ticks and the events** (falls, landings, staredown, clock); everything else is presentation.

## 8. Extending to four fighters

A template is written for two roles. For N fighters (2v2 rules are deferred; Orb: focus on 1v1), the arrival beats repeat per fighter in order, 30 to 50 ticks apart; the staredown pair slot runs for the first two pairs of neighbours; and the closing is shared. Retinues, hosts and mirrors extend naturally; S3 becomes pairs of simultaneous arrivals. Each new fighter adds only data: `arrivals`, `veto`, `host_activity`, and a gesture for the look.

**What each launch fighter brings (proposals, for Animation and Legal to check):**

| Fighter | Arrival modes | Waits by | Hosts by | Veto |
|---|---|---|---|---|
| Protagonist | `drop` (lands in a crouch, one hand down), `descend` near a settlement | Stretching, bouncing on his toes | Mending something small | none |
| Rival (Anti-hero) | `descend` (composed), `drop` (no expression) | Standing motionless, a glance at a cuff | Sitting on a stone, back half turned | S3 (S11 only as a mirror) |
| Empress | `retinue` (guard first, then a slow descent), `descend` | The aide checks a watch; she smooths her train | Her guard arranges her place | S3 (unless mirror) |
| Cyborg | `drop` on one knee with a polite bow | Wipes a plate | A sandwich | S9 |

Every pose passes Legal's silhouette check (RL-038: no one famous landing, and the staredown is not a duel-movie pose).

## 9. What it needs

**Encounter (the intro phase) and Simulation:**
- `data/fight/intro.json` becomes **a set of timelines**, one per template, with the beats above as data; the sim stays scripted and deterministic.
- The setup's `"intro"` gains a record: `scenario`, `order` (which slot is First), `arrivals` (a mode per slot), `closing`, `facts` (the history, the settlement flag), `tod`. It is in the replay header and the data hash.
- Events carry the scenario: `intro_start` gets `scenario`; each fighter's `entrance_fall` gets `mode`; a new `intro_beat {kind, actor, slot}` is sent for the non-fall beats (wait, look, task, challenge), so Camera, Animation, Audio and Narrative key off the sim's clock.
- Per-fighter intro states beyond `intro`: `waiting`, `host`, and the retinue spawned in the intro (S5).
- **First-move support** for S10: a setup key `opening: "rush"` that gives both fighters a rush intent for the first 24 ticks. If it is not wanted, S10 closes on `hold`.
- The **crater scale** per beat (`crater`), so a soft landing digs little or nothing.
- **World:** a settlement-in-view query from a spot (for S7) and the biome and sky of the spots.

**Animation:** arrival poses (`drop`, a slow `descend` and a no-impact landing), waiting idles (impatient, patient, bored), host activity loops (mending, sitting, eating, arranging), a head-turn to the rival with a half-beat delay, the formation landing, the mirror posture race, and a taunt gesture that works as a challenge. All inside the joint limits (`docs/animation/joint-limits.md`).

**Camera:** a shot recipe per template, from the beats: the long wait on the empty spot and sky (S2); the tilt up to the dot (S4); the village between them (S7); the long look and its face cuts (S9); the split level two-shot (S3, S11); face cuts **timed to the lines** (a line is about 1.2 s and today's face cut is 24 ticks, so the faces need about 48 to 72 ticks); and Camera's reduced-motion and skip rules for every one.

**Audio:** the impact on each landing; wind and ambience that can drop out for S9 and return at the clock ("silence just before a huge hit", Orb's own pick, at the scale of an intro); a different landing for `descend`; and the babble reads each caption's length.

**UI:** a setting for the opening (`Varied` by default, `Classic`, `Short`, `Skip`), worded to the player; no HUD until the clock (unchanged); the skip prompt.

**Tools:** schemas for the timelines and the setup record.

**Narrative (this document):** the slot catalogue is the interface. After Orb's voice pass I will draft a first batch of lines for each slot, in the voice lab's format, only when asked.

## 10. Questions for Orb

1. Is **a rivalry record by character pair** (what story the intro tells) what you want, or should local two-player matches remember each *player* instead?
2. Should an intro ever be **entirely silent** (S9), as an occasional occasion, or should every intro have at least one line?
3. How long may a **first-time intro** run? The templates run 4.5 to 7 s; the baseline is 5 s today.
4. Do you want the **opening challenge** (S10), where the clock starts with both fighters rushing, or should the fight always begin from a stand?
5. Should the **Empress's guard** be on screen in the intro (S5), or arrive only when the fight starts?
