# Dynamic intros: the content side

Owner: Narrative and Fighter Identity. Version 2, 2026-10-06 (section 11 added: the generative layer of implied plotlines; Orb allows longer intros and says the first to land is an even draw). Version 1, 2026-10-04. Answers the EP's brief from Orb ("if we can script a system that creates dynamic intros and mixes and matches different scenarios between characters I'd like to see it"). This is the **content**: what an intro is built from, eleven scenario templates as beat lists, which parts need a voice line (as slots, intent only: **Orb writes the lines**), and the rules that keep it coherent and fresh. The sim side is Simulation's and Encounter's (`docs/architecture/intro-phase.md`); this document changes none of it and says what it needs. Presentation text treats the player as the fighter. No franchise scenes, names or poses.

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

**A third layer, above both** (section 11): a **plotline** (a relationship type, the state it is in, and an event) chooses and bends the template, so the same two fighters tell a different small story each time their relationship is in a different place, without anyone writing a scene for each pair.

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
10. **No repeat of a template** within the last **5 intros of the same pair** or the last **3 intros of any pair** (and, in section 11, no repeat of a *plot id* within 5 intros of the same pair). A template's weight is multiplied by 1 / (1 + recent uses), so repeats lose but never vanish when little else is eligible.
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

## 11. The generative layer: implied plotlines (version 2, 2026-10-06)

Orb's answers on the first cut: **longer intros are allowed**; for who lands first, "P1 then P2 is pretty standard" (the build draws the order evenly, which is fine); and the real ask: "as long as the dynamic intros can create many distinct implied plotlines between each character I'd like to see these handled as generatively as possible." This section is the layer above the eleven scenarios that answers it. **Everything here is an option for Orb, and the vocabulary is a draft.**

### 11.1 The idea: a scenario is how it looks, a plotline is what it is about

A **scenario** (section 4) is a sequence of beats: who lands when, the wait, the look. It has no opinion about the two fighters. A **plotline** is the small story the pair is *in*: "a student early for a lesson", "an old grudge about to be renewed", "a rival who has just lost". A plotline **picks a scenario and bends it**, so the same Double Drop can be a warm reunion, a cold ranking or a wounded rematch, and the same two fighters have a different opening every time their story is in a different place.

Nobody writes 66 scenes (twelve fighters, 66 pairs). Three things are written **once and for everyone**: the **grammar** (types and states, below), the **bend table** (what each state and each type does to a scenario), and each fighter's **lines by stance**. A pair adds only a few facts: what its relationship is, where the record puts it, and which event (if any) is in its past.

### 11.2 The grammar of a plotline

A plotline is four things: **a type, a state, an event and the roles.** All four are data, and none is a scene.

**1. The type** (what the relationship is). Eleven, drawn from the stakes in `matchups.md` and the new stakes in `roster-twelve-identity.md` section 5.3. Each has two roles.

| Type | Roles (A / B) | Tones | What it is about |
|---|---|---|---|
| `sparring` | ahead / behind | light, neutral | Nothing but pride, between friends. |
| `rivalry` | leader / chaser | light, neutral, grave | Who is ahead, by the record. |
| `world_at_stake` | protector / threat | neutral, grave | A planet or its people in the balance. |
| `appetite` | hunter / hunted | light, neutral | One means to eat the other. |
| `lesson` | teacher / student | light, neutral | What one was taught by the other. |
| `grudge` | ahead / wronged | neutral, grave | An old defeat or injury, still sore. (Who is wronged comes from the pair's data, not the last bout: see 11.12.) |
| `betrayal` | betrayer / betrayed | neutral, grave | A changed allegiance, and what it cost. |
| `performance` | performer / audience | light, neutral | One is playing to a crowd. |
| `awe` | admirer / admired | light, neutral | A newcomer in front of a legend. |
| `debt` | debtor / creditor | neutral, grave | Something owed, unspoken. |
| `kinship` | elder / heir | neutral, grave | A mantle handed down, or refused. |

**2. The state** (where the story is). Four, the same for every type.

| State | Meaning | How it is read from the record |
|---|---|---|
| **fresh** | A beginning: they have not been here before. | No meeting yet (or the first of this plot). |
| **simmering** | Unsettled, and heating. | A close record, a recent bout, or a return after a long gap. |
| **settled** | Resolved, a habit, even affectionate. | Many meetings, a long streak, or a decided score. |
| **reversed** | The order has flipped: the leader fell, an ally turned, a debt was paid. | An upset: the loser of the last bout is the long-time leader, or the streak was broken. |

States move as the record does (section 11.6), so a pair's intros tell a progression: fresh, then simmering after a close first bout, then settled after a long run, then reversed on an upset, then simmering again.

**3. The event** (what has happened that they are both thinking of). Three kinds, so a pair never has *nothing*:

| Kind | From | What a line can do with it |
|---|---|---|
| `record` | The pair's rivalry record (`user://rivalry.json`): who won last, how it ended (a knockout, a scarred planet, the time cap), a broken streak. | Name the *last time*, truthfully. |
| `ledger` | A **canon ledger** event both fighters belong to (section 3.4 of `roster-twelve-identity.md`): "the lighthouse", "the bridge". | Refer to it by name; never explain it. |
| `unseen` | Nothing named: a deliberately unexplained reference ("that night", "the last time we spoke"). | Hint that there is a past, which is the fourth-season feeling. |

A ledger event can also **seed a type**: if two fighters share a `betrayal` event, `betrayal` becomes an eligible type for that pair without anyone listing it.

**4. The roles** (who is which). Fixed by the pair's data where the type is asymmetric (the Veteran is the teacher), or by the record where it is symmetric (the leader is whoever is ahead). **Arrival order then crosses with role**: who lands first is a draw (Orb's rule, an even draw), so the **same plotline has two readings**. The teacher arrives first (waiting, unhurried) or the student does (early, nervous); the leader arrives first (arrogant, ahead of time) or the chaser (hungry, early). That cross is where the generativity comes from, and it needs no extra authoring.

### 11.3 What a plotline bends: six channels

A plotline changes a scenario only through six named channels, all small and all optional, so a scenario that ignores one is still coherent.

| # | Channel | What it does | In the composer |
|---|---|---|---|
| 1 | **Scenario weights** | Multiplies each template's weight: a grudge favours the Long Look; awe favours the Latecomer; a settled, light plot favours the Double Drop. | `facts.weights` |
| 2 | **The gap** | Bends the gap between landings toward the short end (tension) or the long (one waits) within the template's range. A number from -1 to 1. | `facts.gap` |
| 3 | **The look** | Prefers a look part: `hold`, or `long` (the Long Look's stretched stare); `away` (one breaks the stare first) when the pose exists. | `facts.look` |
| 4 | **Gestures** | Inserts small non-verbal beats at named points (`land_first`, `land_second`, `look_start`, `look_end`), by role. A closed list of ten **gesture intents**; Animation maps each to the fighter's own pose, and a missing pose is a silent skip. | `facts.gestures` |
| 5 | **Voice intents** | Tags each voice slot with a **stance** and an **angle** (below), and a probability of speaking, so the line system picks a line in the right mood about the right thing. | `facts.intents` |
| 6 | **Length** | Adds or removes ticks from the clock (a settled plot is brisk, a simmering one holds) within the loader's check. | `facts.clock` |

**The two closed vocabularies Orb's lines are tagged with.**

| | Values |
|---|---|
| **Stances** (the mood a line is said in) | warm, wry, formal, guarded, cold, wounded, smug, awed |
| **Angles** (what a line is about) | `you` (the other, an appraisal), `me` (oneself), `us` (what they share), `then` (a past event, with `{event}`), `now` (the place and the moment), `them` (a third party: the crowd, a settlement, the world) |
| **Gesture intents** | acknowledge, appraise, dismiss, defer, brace, ease, claim, check, soften, harden |

A gesture intent is a **meaning**, not a pose: `check` is a glance at the sky, a cuff or a watch (each fighter's own); `defer` a small step back or bow; `claim` planting the feet and taking the space. That is how one grammar fits twelve different bodies.

### 11.4 The bend table (written once)

A plotline's bend is **a state's bend plus a type's bend**. Four rows for the states, eleven for the types.

**The state bends** (the same for every type):

| State | Weights (x) | Gap | Look | Clock | Gestures | Voice (probability, angle) |
|---|---|---|---|---|---|---|
| fresh | none | 0 | hold | 0 | both `appraise` at the look | 0.8; `you` |
| simmering | long_look 1.5, double_drop 0.9 | -0.6 (short, tense) | long | +24 | the last loser `harden` at the look; the last winner `check` at the first landing | 0.9; the last loser `then`, the last winner `us` |
| settled | double_drop 1.2, long_look 0.5 | 0 | hold | -24 | both `ease` at the look; the last winner `acknowledge` at its end | 0.6; the last winner `us`, the other `now` |
| reversed | latecomer 1.5 | +0.5 (a wait) | hold | +36 | the last winner `claim`; the last loser `harden` | 1.0; the last loser `me`, the last winner `us`, the rest `then` |

The `weights` the host passes are **the product** of the state's and the type's multipliers, template by template.

**The type bends** (stance by role, the scenarios it favours, a gesture at two points). A weight only counts for a scenario the type's tones admit (the Double Drop is `neutral`, the Latecomer `light`, the Long Look `grave`), so none is listed that the tone gate would remove. The gestures follow one convention: **a state's gestures sit at the look's start and the first landing, a type's at the second landing and the look's end**, so a state and a type never name the same fighter at the same point.

| Type | Tones | Stance: A / B | Favours (a multiplier) | Gestures: at the second landing / at the look's end |
|---|---|---|---|---|
| `sparring` | light, neutral | warm (wry) / warm (wry) | double_drop 1.2, latecomer 1.0 | both `acknowledge` / both `ease` |
| `rivalry` | all three | formal (cold, warm) / guarded (wry, warm) | double_drop 1.0, latecomer 1.0, long_look 1.2 | leader `appraise` / chaser `harden` |
| `world_at_stake` | neutral, grave | guarded / smug (cold) | double_drop 1.0, long_look 2.0 | protector `brace` / threat `claim` |
| `appetite` | light, neutral | smug / guarded | latecomer 1.2, double_drop 1.0 | hunter `check` / hunted `brace` |
| `lesson` | light, neutral | wry (formal) / awed (guarded) | latecomer 1.5 (the teacher waits), double_drop 1.0 | student `defer` / teacher `appraise` |
| `grudge` | neutral, grave | smug (formal, guarded) / wounded (cold) | long_look 1.8, double_drop 0.7 | wronged `harden` / ahead `dismiss` |
| `betrayal` | neutral, grave | guarded (wry) / wounded (cold) | long_look 1.8, double_drop 0.8 | betrayer `dismiss` / betrayed `harden` |
| `performance` | light, neutral | smug / wry | double_drop 1.3, latecomer 1.0 | performer `claim` / audience `dismiss` |
| `awe` | light, neutral | awed / warm (formal) | double_drop 1.0, latecomer 1.5 | admirer `defer` / admired `acknowledge` |
| `debt` | neutral, grave | guarded / formal | double_drop 1.0, long_look 1.2 | debtor `check` / creditor `acknowledge` |
| `kinship` | neutral, grave | warm (formal) / guarded (awed) | long_look 1.4, double_drop 1.0 | elder `soften` / heir `brace` |

Bracketed stances are the second pick, used when the pair's voice vetoes the first (the rival never speaks `warm`; the Empress's guard is never `awed`). A fighter's data lists the stances it never says.

**How the bend lands on the three built scenarios.**

| Scenario | The gap channel | The look channel | Gestures at | Voice slots tagged |
|---|---|---|---|---|
| **Double Drop** | Moves the second fall closer or further (30 to 70 ticks) | `hold` or `long` | `land_first`, `land_second`, `look_start` | `arrive_remark` (first), `staredown_pair` (left then right) |
| **Latecomer** | Lengthens or shortens the wait (100 to 200 ticks) | `hold` | `land_first`, the wait (`check`, `ease`), `land_second` | `wait_remark` (first), `late_reply` (second), `staredown_pair` |
| **Long Look** | Fixed | `long` | `look_start`, `look_end` | none (silent): the bend lives in the two gestures and the length |

Every other scenario (S3 to S11) takes the same six channels.

### 11.5 What the composer reads: the `facts` record

The host resolves a plotline into a **flat, resolved `facts` record** and passes it in the setup. **The grammar stays on the host's side** (`data/narrative/intro_plots.json`, a draft shape below), and the composer reads only flat keys, so it stays small and deterministic. The whole record is stored in the replay header, so a replay reproduces the intro even if the grammar is edited later.

New keys beside today's `tones` (`pending/dynamic-intros.md` section 3):

| Key | Shape | The composer |
|---|---|---|
| `tones` | list of `light`, `neutral`, `grave` | As today: filters the templates. |
| `plot` | a string id, such as `rivalry.simmering.record` | Shown in the feed: `INTRO plot: rivalry.simmering.record`. Nothing else. |
| `weights` | `{ "template id": multiplier }` | Multiplies each template's weight before the draw. A missing id is 1. |
| `gap` | a number, -1 to 1 | Moves the drawn gap that fraction toward the short or long end of the template's range. Left out: no bend. |
| `look` | a part id, such as `long` | Prefers it for the `look` slot when the template's pool holds it. |
| `clock` | integer ticks, may be negative | Added to the template's clock, then the loader's fit check runs. |
| `gestures` | list of `{ at, who, intent }` | Appended as beats of kind `gesture` at the named points. `who` is `first`, `second`, `left`, `right` or `both`. |
| `intents` | `{ slot: { stance, angle, p, event } }` | Passed through in the `intro_line` event: the sim holds no words. |
| `avoidPlot` | list of plot ids played lately for this pair | Host-owned memory (no repeat, section 11.8). |

**New fields on events** (additions only, so nothing reading today's events breaks): `intro_line` gains `stance`, `angle`, `event` and `p`; a new `intro_gesture {actor, intent, at}` is sent at the gesture's tick; `intro_start` carries the `plot` id. Unknown keys are ignored, so the first cut keeps working when only `tones` is passed.

**Presentation stays presentation.** The sim passes `stance`, `angle`, `event` and `p` through and reads none of them; the line system decides whether the line plays (using `p`, on its own seeded stream) and which line it is. A replay shows the same intro, and the same lines, because the facts and the line stream are both recorded.

**The grammar file** (`data/narrative/intro_plots.json`, draft; host side):

```json
{ "schema": "narrative.intro_plots/1",
  "stances": ["warm","wry","formal","guarded","cold","wounded","smug","awed"],
  "angles": ["you","me","us","then","now","them"],
  "gestures": ["acknowledge","appraise","dismiss","defer","brace","ease","claim","check","soften","harden"],
  "states": {
    "simmering": { "gap": -0.6, "look": "long", "clock": 24,
      "gestures": [{"at":"look_start","who":"wronged","intent":"harden"}, {"at":"land_first","who":"other","intent":"check"}],
      "voice": {"p": 0.9, "angles": ["then","us"]} } },
  "types": {
    "grudge": { "roles": ["ahead","wronged"], "tones": ["neutral","grave"],
      "stance": {"ahead": ["smug","formal"], "wronged": ["wounded","cold"]},
      "weights": {"long_look": 1.8, "latecomer": 1.0, "double_drop": 0.7} } },
  "derive": { "see": "section 11.6" } }
```

**The resolved `facts` for example B in section 11.7** (the Protagonist arrives first, so `first` is the Protagonist and `second` the rival; `last_ko` is the record's event). The composer uses only the slots the template it draws has: the Long Look is silent, so the voice intents apply if it draws the Double Drop or the Latecomer instead.

```json
{
  "tones": [
    "light",
    "neutral",
    "grave"
  ],
  "plot": "rivalry.simmering.record",
  "weights": {
    "double_drop": 0.9,
    "latecomer": 1.0,
    "long_look": 1.8
  },
  "gap": -0.6,
  "look": "long",
  "clock": 24,
  "gestures": [
    {
      "at": "land_first",
      "who": "second",
      "intent": "check"
    },
    {
      "at": "look_start",
      "who": "first",
      "intent": "harden"
    }
  ],
  "intents": {
    "arrive_remark": {
      "who": "first",
      "stance": "guarded",
      "angle": "then",
      "p": 0.9,
      "event": "last_ko"
    },
    "late_reply": {
      "who": "second",
      "stance": "smug",
      "angle": "us",
      "p": 0.9
    },
    "staredown_pair": {
      "lines": [
        {
          "who": "left",
          "stance": "guarded",
          "angle": "then",
          "event": "last_ko",
          "p": 0.9
        },
        {
          "who": "right",
          "stance": "smug",
          "angle": "us",
          "p": 0.9
        }
      ]
    }
  },
  "avoidPlot": [
    "rivalry.fresh.unseen"
  ]
}
```

### 11.6 How a plotline is chosen for a pair

All of it on the host, from the pair's data and the record, with **keyed draws on the match seed** (`intro.plot.type`, `intro.plot.event`) so a replay and an online peer agree; a peer or replay may pass `facts` and skip the draw.

1. **Eligible types.** From the pair's data. If it has none, the default by the two fighters' circles (`roster-twelve-identity.md` section 5.3): the Circle with the Circle gives `sparring`, `lesson`, `awe`; the Circle with the Court gives `world_at_stake`, `appetite`; the Old Guard pair gives `rivalry`, `grudge`, `debt`; the Drifters give `debt`, `betrayal`, `performance`. A shared ledger event seeds its own type. A fighter's veto removes types.
2. **The type** is drawn by weight from the eligible ones; one played lately weighs 1 / (1 + its uses in `avoidPlot`).
3. **The state** is derived from the record (table below). With no record the state is `fresh`.
4. **The event** is the best of: the record's last ending (if there is one), a shared ledger event of this type, any shared ledger event, else `unseen`.
5. **The roles** are fixed by the pair's data, or by the record (the leader is who is ahead).
6. **The bend** is read from the grammar, resolved into `facts`, and passed in the setup. The composer then draws the scenario, order and gap as before.

**How the state follows the record** (so the plotline advances). These are the `stateRules` in `pending/intro_plots.json`, in order; **the first row that holds wins**. The numbers are the ones the host's `history` gives (`meetings`, `lead`, `trailingJustWon`, `streakEnded`, `sinceMet`, `lastWasTimecap`, `lastScarred`).

| # | State | When |
|---|---|---|
| 1 | fresh | `meetings` 0 |
| 2 | reversed | `streakEnded` 3 or more (a run of 3 has just been broken) |
| 3 | reversed | `trailingJustWon` 1 and `meetings` 3 or more (two meetings is only a split) |
| 4 | simmering | the last bout ran to the time cap |
| 5 | simmering | the last bout scarred or destroyed a planet |
| 6 | simmering | `sinceMet` 11 or more (a return after a long gap) |
| 7 | settled | `meetings` 5 or more and `trailingJustWon` 0 |
| 8 | settled | **a long-time leader**: `lead` 3 or more and `trailingJustWon` 0 |
| 9 | simmering | everything else: 1 to 4 meetings, **a close score** (`lead` 0 or 1) included |

### 11.7 Three states of one pair: the Protagonist and the rival

The type is `rivalry` throughout (the Protagonist warm to the rival, the rival contemptuous with a hidden envy). **No line text is shown**: Orb writes the lines, so each voice slot is a stance, an angle and, where there is one, an event. The first cut's slots are `arrive_remark`, `wait_remark`, `late_reply` and `staredown_pair`.

**A. Fresh: their first bout of the season.** The record is empty. The event is `unseen`.

- **Chosen:** type `rivalry`, state `fresh`, all three tones. The weights are the type's alone (a fresh state adds none): Double Drop 1.0, Latecomer 1.0, Long Look 1.2. Gap 0, look `hold`, clock 0.
- **Gestures:** both `appraise` at the look.
- **If the Protagonist is first:** he lands, glances round at the empty second spot with open interest (his `arrive_remark`: `warm` about *you*, `p` 0.8; on a tie he is the leader and, as he never says `formal`, `cold` or `smug`, the data gives him `warm`), the rival lands without hurry, and at the staredown each speaks in his own stance about *you*: the Protagonist `warm` (sizing him up fondly), the rival `guarded` or `wry` as the chaser (he never says `warm`). Nobody mentions a past; the stare has weight because it is the first.
- **If the rival is first:** he lands, stands still (a held, wordless `appraise`), and the Protagonist arrives with his easy, slightly apologetic energy (`late_reply`, `warm`, about *you*). Same facts, a different opening.

**B. Simmering: a rematch, the rival won last by a knockout.** The record says the rival won, and it ended in a KO. The event is `record`.

- **Chosen:** type `rivalry`, state `simmering`; roles: leader is the rival, chaser the Protagonist. All three tones. The weights are the product of the type's and the state's: **Long Look 1.2 x 1.5 = 1.8**, Latecomer 1.0, Double Drop 1.0 x 0.9 = 0.9. Gap -0.6 (short), look `long`, clock +24.
- **Gestures:** the Protagonist (the last loser) `harden` at the look; the rival (the last winner) `check` at the first landing; and, from the type, the rival (the leader) `appraise` at the second landing and the Protagonist (the chaser) `harden` again at the look's end (the resolver keeps one).
- **If the Protagonist is first:** he lands and braces (`arrive_remark`: `guarded`, `then`, the event is the last KO: a remark about *last time*, plainly said, `p` 0.9). The rival arrives close behind (a short gap), unbothered (`late_reply`: `smug`, `us`). The Long Look holds both in the two-shot, faces cut in, no more words.
- **If the rival is first:** he arrives early to claim the ground (`claim`), says nothing, and watches the Protagonist land. The Protagonist's `staredown_pair` line is `guarded`, `then`.

**C. Reversed: the Protagonist has just beaten the rival, after losing three in a row.** The record says a streak of three just ended. The event is `record`.

- **Chosen:** type `rivalry`, state `reversed`; roles now: leader is the Protagonist, chaser the rival. Gap +0.5 (a wait), look `hold`, clock +36. The weights: **Latecomer 1.0 x 1.5 = 1.5** (the one who is waiting is the point), Long Look 1.2, Double Drop 1.0.
- **Gestures:** the Protagonist (the last winner) `claim`, quietly, with no gloating; the rival (the last loser) `harden`. (The shape cannot swap `harden` for `defer` by a fighter's voice: 11.12, note 5.)
- **If the rival is first:** he is early, to prove it was a fluke, and he waits (his `wait_remark`: `wounded`, `me`, the old "this does not count" mood). The Protagonist lands, a little embarrassed to be ahead (`late_reply`: `warm`, `us`, said gently). The rival does not take it as kindness.
- **If the Protagonist is first:** he waits, uneasily, and the rival is late: **wounded pride**, a long walk to the stare. The staredown lines are `wounded` and `warm` about *us*.

**What this shows:** one type gives the same pair six distinguishable readings (three states x two arrivals), and more once the scenario draw is added; only the lines by stance and angle need writing, once, for every pair.

### 11.8 The count of distinct openings

**What counts as distinct.** A *story* is a type, a state, an event and a reading (who arrives first). An *opening* is a story in a scenario. Two openings are distinct if their story or their scenario differs (the gap, the gestures and the exact lines make them feel different again, and are not counted).

| Per pair, an assumption | Value | Why |
|---|---|---|
| Eligible types | 3 (1 to 5) | Defaults by circle, plus a shared ledger event |
| States over a relationship | 4 | Fresh, simmering, settled, reversed, as the record advances |
| Events | 2.5 | The record's last ending, 0 to 2 shared ledger events, and `unseen` |
| Readings | 2 | Who arrives first |
| Scenarios eligible after the tone gate | 2 in the first cut (of 3); about 7 with all eleven | The weights, not a rule |

| | Stories | Openings, first cut (3 scenarios) | Openings, all eleven |
|---|---|---|---|
| **One pair** (3 types) | 3 x 4 x 2.5 x 2 = **60** | 60 x 2 = **120** | 60 x 7 = **420** |
| **The launch pair** (rivalry, grudge, sparring, lesson if Orb picks it: 4 types) | 4 x 4 x 2.5 x 2 = **80** | **160** | **560** |
| **Twelve fighters** (66 pairs) | 66 x 60 = **about 4,000** | about **8,000** | about **28,000** |

**The honest reading.** These are counts of *what the system can compose*, not of what a player can tell apart. What a player learns to *read* is the **story shape**: 11 types x 4 states x 2 readings = **88 shapes**, the same for every pair ("a teacher waiting", "a grudge renewed"). The pair adds the event and the voice. So the freshness a player feels is: the shape (88), the pair's own event, and the stance lines. With the no-repeat rule (a plot id not played within 5 intros for the same pair) a pair gives **at least 60 stories before one can return**, and because the **state follows the record**, the stories are not drawn at random: they *advance*, which is the point (a pair's openings read as a serial, not a shuffle).

**What would make the number a lie:** if every state's bend looks the same on screen, or if the lines are not tagged by stance and angle, then 88 shapes collapse to a handful. The cheapest guard is Animation mapping the ten gesture intents for each fighter, and Orb writing at least one line for each slot and stance.

### 11.9 What Orb must author, and what Narrative authors

| Orb | How much | Why only Orb |
|---|---|---|
| **The canon ledger rows** (events: a name, a season, who was there, what changed, and optionally the type it seeds) | 4 to 6 for the launch pair; about 24 for twelve (two a fighter) | They are the universe. |
| **The lines, by slot and stance** | The first cut's four slots, for each of the 8 stances: **32 lines a fighter** at the least, plus 3 to 5 `then` lines with `{event}`. 2 fighters: about 80 lines. 12: about 480. | They are the voice. |
| **The staredown lines already in the voice lab, tagged** with a stance and an angle | The existing staredown pairs (`staredown-last-stand.csv`) get two more columns when Orb next edits | One edit, two uses. |
| **Pair data for marquee pairs** (about 12): the types, and who is which role | A line each | A relationship is Orb's to decide. The rest come from the circles. |
| **Each fighter's stances never said** (a veto) | A short list | A voice rule. |

| Narrative (this document) | |
|---|---|
| The grammar, the bend table and the vocabularies | Done, as a draft in this section; Orb edits |
| The derivation rules (default types by circle, states from the record) | Done (11.6) |
| The `data/narrative/intro_plots.json` file | On request, as a draft with every type and state filled |
| A first batch of lines by slot and stance for the launch pair | On request, in the voice lab's format, after Orb's pass |

### 11.10 What this needs, beyond section 9

- **Encounter and Simulation:** the composer reads `weights`, `gap`, `look`, `clock` and `gestures` from `facts` and ignores the rest; `intro_line` carries `stance`, `angle`, `event` and `p`; a new `intro_gesture` event; the setup stores the whole `facts` record. A `gesture` beat kind. The existing parts (`hold`, `long`) cover the look channel for now.
- **The host (UI and Rendering):** the plot pick (11.6) and the rivalry record, with `avoidPlot` as its memory. The record's state machine is a small function.
- **Animation:** a pose or small motion for each of the ten gesture intents, per fighter, starting with the launch pair; and a missing one is a silent skip.
- **Camera:** none beyond section 9; the gestures play inside the existing shots.
- **Audio:** none beyond section 9.
- **The line system (Narrative):** a line carries `slot`, `stance` and `angle` (and `event` for `then`); the picker takes the best match and falls back from exact to stance to slot to silence; the seen memory still applies.
- **Tools:** the schema for the new `facts` keys and for `intro_plots.json`.

### 11.11 Questions for Orb

1. Should a pair's **state advance with the record** (the openings tell a serial), or should the host draw a state at random so a first meeting can still feel old?
2. Is **the type list** right (eleven)? Which would you cut, and what is missing?
3. Do you want **the event named** when it is the last bout (a line may say "last time"), or left to `unseen` so it is only ever hinted?
4. Should some pairs **never** get certain types (for example, the Anti-hero and the Cyborg never `sparring`)? Say which, and I add the vetoes.
5. How many **stances** do you want each fighter's voice to cover: all eight, or a subset (the rival never `warm`)?

### 11.12 Answers to Simulation, and what the shape cannot express (2026-10-05)

The grammar is now real data, parked as **`docs/narrative/pending/intro_plots.json`** (states, stateRules, types, pairs, fighters, vocab and a default pair; the launch pair filled, using the neutral ids `protagonist` and `rival`; no spoken lines). Every row uses only the selectors in `docs/architecture/dynamic-intros.md` section 15, the six gesture points, the ten gesture intents and the closed stance and angle lists; a script checks all of it, and that no weight sits on a scenario the type's tones would remove.

**1. Is "the wronged" always the last bout's loser, and "the new leader" its winner? No.**
- In the **states** (the generic bends) I now write exactly what the record knows: **`last_loser`** and **`last_winner`**. They are whoever lost and won the latest bout, with no claim about who was wronged.
- In the **types**, the roles are the type's own. For `rivalry` and `sparring` they come **from the record** (the leader is who is ahead), and for `grudge`, `betrayal`, `lesson`, `awe`, `debt`, `kinship`, `performance`, `appetite` and `world_at_stake` they come **from the pair's data**. *The wronged* in a grudge is whoever the pair's row names (an old defeat or injury from the canon ledger), and may well **not** be the last loser.
- "The new leader" is not "the last winner" either: a win can close a gap without taking the lead. The state's rows now say `last_winner` and mean only that.

**2. One angle a fighter, or one per slot? One a fighter, for the whole intro.** A fighter has one thing on their mind for the opening (the last bout, what they share, the moment), and an angle that jumps between slots reads as two characters. The stance is the same: one per fighter. The two lines of the staredown pair are two fighters, so they differ naturally. A fighter who is wry at the arrival and cold at the stare is not expressible (note 6 below); I do not think the first cut needs it.

**3. "Close score" and "long-time leader" as numbers.** *Close score* is **`lead` 0 or 1**; *long-time leader* is **`lead` 3 or more** (with at least 5 meetings for `settled`'s other row). They are rows 8 and 9 in the table in 11.6. I define `trailingJustWon` as 1 when the last winner had **strictly fewer wins before that bout** (level at a tie: 0), so a first win by the trailing side is a reversal only from the third meeting on (row 3).

**What the shape cannot express** (listed in the file under `_notExpressed`, not bent to fit):
1. **A state a pair starts in.** Every first meeting is `fresh`, but a fourth season gives most pairs a past; a `pairs[].startState` would let a marquee pair open `simmering`.
2. **Default types by circle** (a flat `defaultPair` only): a `circles` table and a `circlePairs` table would give 66 pairs defaults without 66 rows.
3. **A tone a state adds:** a simmering plot cannot lean grave except through weights; a `states.<id>.tones` filter would do it.
4. **A gesture that depends on role and arrival order together** (the teacher waits calmly, the student nervously): `wait` rows name only first, second, left or right, so none is written.
5. **A per-fighter gesture veto or swap** (`harden`, or `defer` when the voice vetoes it): `fighters` has `neverStance` and `neverType` only.
6. **A stance or angle that changes by slot.**
7. **A tie rule** for two rows that name the same fighter at the same point. The convention avoids it (state gestures at the look's start and the first landing, type gestures at the second landing and the look's end), but the resolver should drop the type's row if they meet.
8. **Weights between ledger events** (an ordered list only).
9. **A pair's own register** (the Protagonist warm to the rival). Stance lists are per type and role, so the register comes only from the vetoes: the Protagonist never says `formal`, `cold` or `smug`, so a rivalry leader falls through to `warm` for him and stays `formal` for the rival. A `fighters.<id>.stanceTo.<other>` would say it directly.
10. **A look of `away`** (one breaks the stare first): no part or pose exists.

**Placeholders in the file, for Orb:** which fighter carries the old injury in the launch pair's `grudge` (set to the Protagonist), the two events (`ledger_1`, a canon-ledger placeholder that seeds `grudge`, and `unseen_1`, an unnamed reference), and each fighter's vetoed stances.
