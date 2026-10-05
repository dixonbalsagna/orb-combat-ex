# Dynamic intros, the first cut (as built)

Owner: Simulation and Engine. Status: **in the tree since 2026-10-06, applied on 648c637** (after intent version 4 and World's staged destruction). It was built and proven in scratch first; this is that plan, kept as the record of what was built.

Revision 2 folded in Narrative's generative layer (`docs/narrative/dynamic-intros.md` section 11): the host's `facts` record bends the composer through five keys, gestures play as beats, and voice slots carry the facts' tags. The EP's rulings are in: Narrative's lengths stand, `"intro": true` stays classic, and who is first is an even draw.

Sources: Encounter's composer plan (`docs/director/dynamic-intros-plan.md`), Narrative's content (`docs/narrative/dynamic-intros.md`: S1 Double Drop, S2 Latecomer, S9 Long Look; voice intents V1, V2, V3, V8), the intro phase as built (`docs/architecture/intro-phase.md`).

## 1. What changes, in one paragraph

The intro phase stops playing one fixed sequence. It plays a **timeline composed at match start**: a scenario (a template), who arrives first, the gap between the arrivals, and the part in each slot. The composer picks them with keyed draws on the match seed; the phase plays the result on pre-clock ticks as before. **Every composed intro ends in today's state,** so a fight does not depend on its intro, and skips, QA's batches and the nine golden matches are untouched.

## 2. Who does what (the EP's ruling)

| Piece | File | Owner |
| :--- | :--- | :--- |
| The pick: scenario, order, gap, parts, and the reasons | `sim/director/intro.gd` (`DirIntro`), new | Encounter's file, written by Simulation under the EP's grant in this slice |
| The playback: the ticks, the falls, the landings, the skip, the events | `sim/core/intro.gd` (`SimIntro`), rewritten | Simulation |
| The timelines | `data/fight/intro.json` | Simulation; Narrative's beats are its rows |

## 3. The setup's `intro` record

`newMatch`'s setup takes one of four forms. The setup is stored whole in the replay header, so a replay gets the same record and composes the same intro.

| `"intro"` | What plays |
| :--- | :--- |
| `"skip"`, or no key | The end state at once, no pre-clock tick. Unchanged. This is what QA's batches and the goldens use |
| `false` | The old flat start. Unchanged |
| `true` | **The classic opening:** the template marked `classic` (the Double Drop), the left spot first, its default gap. It is today's intro, tick for tick |
| `{"play": true, ...}` | **A composed opening.** The record below |

| Key of the record | Meaning |
| :--- | :--- |
| `play` | `true` (the default); `"skip"` and `false` mean what they mean above |
| `scenario` | Fixes the template by id. Left out: drawn |
| `order` | Fixes the slot that arrives first (0 or 1). Left out: an even draw |
| `gap` | Fixes the gap in ticks (clamped to the template's range). Left out: drawn in the range |
| `avoid` | The host's no-repeat list: template ids played lately, the newest first |
| `facts` | What the host resolved about the pair: Narrative's flat record (section 6b). The composer reads `tones`, `weights`, `gap`, `look`, `clock` and `gestures`; it passes `plot` and `intents` through on events; it ignores every other key (`avoidPlot` is the host's own memory). Left out: no bend |
| `classic` | `true` asks for the classic opening whatever else is said |

- **The host owns memory.** The sim never reads a file or a clock. The host keeps the last few scenarios for a pair and passes them as `avoid`. A match with no list avoids nothing.
- **A peer or a replay** may pass `scenario`, `order` and `gap` and get exactly that intro with no draw.
- **The data hash.** `data/fight/intro.json` is in the fight data hash and the replay header already, so a replay refuses other timelines.

## 4. The data shape (`data/fight/intro.json`, schema `fight.intro/2`)

Templates and parts, as in Encounter's plan, with Narrative's beats as the rows.

```json
{
  "skipFrom": 30, "fallHeight": 6000.0, "craterEnergy": 1.5,
  "parts": {
    "drop":  {"type": "entrance", "mode": "drop", "ticks": 36,
              "beats": [{"t": 0, "kind": "fall"}, {"t": 36, "kind": "land"}]},
    "wait":  {"type": "reaction", "ticks": 0,
              "beats": [{"t": 14, "kind": "wait"}, {"t": 44, "kind": "line", "intent": "wait_remark"}]}
  },
  "templates": [
    {"id": "latecomer", "weight": 2.0, "tone": "light", "clock": 456,
     "gap": {"min": 100, "max": 200, "default": 154},
     "slots": [
       {"slot": "entrance", "who": "first",  "pool": ["drop"]},
       {"slot": "wait",     "who": "first",  "pool": ["wait"], "with": true},
       {"slot": "entrance", "who": "second", "pool": ["drop_quick"], "gap": true},
       {"slot": "reply",    "who": "second", "pool": ["reply"], "with": true},
       {"slot": "look",     "who": "both",   "pool": ["hold"], "after": 80}
     ]}
  ]
}
```

| Key | Meaning |
| :--- | :--- |
| `parts.<id>.type` | `entrance` (exactly one `fall` and one `land`), `reaction` or `look` |
| `parts.<id>.mode` | The arrival mode an entrance reports. The first cut has `drop` only |
| `parts.<id>.ticks` | How far the part moves the template on |
| `parts.<id>.beats[]` | `t` from the part's start; `kind`: `fall`, `land`, `wait`, `line`, `staredown`; `intent` for a line; `who` to override the slot's role |
| `templates[].clock` | The intro's length in ticks. The look takes what is left |
| `templates[].gap` | The range and the default of the gap: ticks from the first landing to the second fall |
| `templates[].weight`, `tone`, `notTwice`, `classic` | The draw's weight; the tone the `tones` fact filters on; never right after itself; the one a plain `true` plays |
| `slots[].who` | `first`, `second` (by arrival), `left`, `right` (by start spot) or `both` |
| `slots[].pool` | The parts that may fill the slot. A part the facts name (`facts.look`) is taken when the pool holds it. Otherwise an even keyed draw, or the pool's first part when the slot says `"draw": false` |
| `slots[].after`, `gap`, `with`, `draw` | Ticks after the slot before it ends; add the drawn gap; run alongside without moving the template on; `false`: the part is not left to chance |
| `clockBend {min, max}` | The most the facts may shorten or lengthen a template, in ticks (-60 to 60) |
| `gesturePoints` | Where a facts gesture plays: ticks after `land_first`, `land_second`, `wait` and `look_start`; `look_end` is counted back from the clock |

A part may also write a `gesture` beat itself (`{"t", "kind": "gesture", "intent"}`); none does yet.

**The look.** The Double Drop's look pool is `["hold", "long"]`, the Latecomer's `["hold"]`, the Long Look's `["long"]` (the part was `long_hold`; it is `long` now, Narrative's word). All three look slots are `"draw": false`, so with no facts the look is `hold` where a template has it, as before.

**The three templates, at their default gap.**

| Tick of | Double Drop (S1) | Latecomer (S2) | Long Look (S9) |
| :--- | ---: | ---: | ---: |
| First falls, lands | 0, 36 | 0, 36 | 0, 36 |
| First waits (the `waiting` state) | | 50 | |
| Second falls, lands | 84, 114 | 190, 220 | 84, 114 |
| The staredown | 144 | 300 | 144 |
| The clock | 300 | 456 | 420 |
| Voice slots | V1 at 60 and 138; V8 at 156 and 228 | V2 at 80; V3 at 250; V8 at 312 and 384 | none |
| Gap range | 30 to 70 (48) | 100 to 200 (154) | 48 |
| Weight, tone | 3, neutral | 2, light | 1, grave, never twice running |

The loader checks every way to fill every template at its shortest, default and longest gap: each fighter enters once, the staredown follows both landings, and everything fits inside the clock.

## 5. The length question: does the Latecomer fit in 300 ticks?

**No.** The first landing is at 36, the second fall takes 30 ticks and the staredown needs room after it. Inside 300 ticks:

| Gap | Second lands | Staredown starts | Look left |
| ---: | ---: | ---: | ---: |
| 100 | 166 | 196 (no room for V3) | 104 ticks |
| 154 | 220 | 250 | 50 ticks |
| 200 | 266 | 296 | 4 ticks |

The staredown's two lines need about 144 ticks, so a wait long enough to read as a wait leaves no look. The build therefore uses **Narrative's own lengths: 456 ticks for the Latecomer and 420 for the Long Look** (7.6 s and 7.0 s; the Double Drop stays 300). Both are data: `clock` and `gap`.

- The pre-clock ticks are outside the match clock (`S.T` is 0), so match length and QA's batches are untouched.
- A press skips from tick 30, as today.
- **If 300 is a hard cap,** the Latecomer becomes a 100-tick wait with a short silent look, and the Long Look cannot be told from the Double Drop. That is a data edit, not a code change. The EP's or Orb's call.

## 6. The pick (`DirIntro.compose`)

| Step | Rule | Keyed draw |
| :--- | :--- | :--- |
| The scenario | Among templates whose tone the pair allows, by weight. One played lately weighs 1 / (1 + its uses in `avoid`). One marked `notTwice` is passed over when it is the newest in `avoid`. If nothing is left: the classic | `intro.scenario` |
| Who is first | An even draw between the two slots | `intro.order` |
| The gap | Even over the template's range | `intro.gap` |
| Each slot's part | Even over its pool, when it has more than one | `intro.part`, by slot |

- All four are `SimRng.keyed(seed, key, n)`: stateless, so `S.rng` is not read and no stream shifts.
- **Explainable.** On the first pre-clock tick the feed gets a line a pick: `INTRO: latecomer` with `3 of 3 fit; double_drop at 1/2 (played lately)`, then `INTRO first: <name>` with the reason and the gap.
- Narrative's preferences (who is never early, who lands soft) are the host's to pass as `order`, or later facts; the first cut reads only `tones`.

## 6b. The host's facts: what bends a pick

Narrative's grammar (relationship, state, event) stays on the host. The composer sees only its flat result.

| Key | Shape | What the composer does |
| :--- | :--- | :--- |
| `tones` | a list | Filters the templates, as before |
| `weights` | `{template id: multiplier}` | Multiplies each template's weight before the draw. A missing id is 1; 0 removes it; below 0 counts as 0 |
| `gap` | -1 to 1 | Moves the drawn gap that share of the way to the short end (below 0) or the long end (above 0) of the template's range. A gap the setup fixed is not moved |
| `look` | a part id | Any slot whose pool holds that part takes it |
| `clock` | ticks, may be negative | Added to the template's length, inside `clockBend`. If the intro then has no room for its beats the bend is dropped. The look takes the difference |
| `gestures` | `[{at, who, intent}]` | Each becomes a gesture at its point's tick. `who`: `first`, `second`, `left`, `right` or `both`. A point the template does not have (`wait` outside the Latecomer), an unknown `who`, or a tick outside the intro is skipped. 16 at most |
| `plot` | a string | The feed (`INTRO plot: ...`) and `intro_start`. Nothing else |
| `intents` | `{slot: {who, stance, angle, p, event}}`, or `{slot: {lines: [...]}}` | Not read. Each voice slot's event carries its entry's tags (section 8) |
| anything else | | Ignored. The first cut's records (only `tones`) work unchanged |

Every bend's reason goes to the feed on the first pre-clock tick, beside the picks.

## 7. The playback

- **State** (`S.intro`, integers, hashed): `scenario` (the template's index, -1 when none plays), `first`, `gap`, `picks`, `clock` (the composed length) and `dug` (a bit a slot: his crater is dug), beside today's `left`, `t`, `landed`. The beats are worked out from those and the data; they are not state.
- **Payload, not hashed:** the facts as given and the gestures resolved from them. They only fill events and never touch gameplay state; they come from the setup, which is in the replay header, so a replay rebuilds them.
- **Fighter states:** `intro` as today, and **`waiting`** for the first to arrive, from his `wait` beat to the staredown. The sim holds through the intro, so the state is for the view.
- **Skip:** as today. The landings left are applied at once, the first to arrive first.
- **The end state is the same for every intro.** Both fighters free on their start spots, each in his crater. One thing had to be made order-proof: the crater records are a list. When the right spot's fighter lands first, the two records are put back in the order of the start spots as the second one is dug. So the state at the clock equals the state the setup's `skip` gives, whatever was composed and whenever it was skipped. The check proves it for every template, either order, three gaps and four skip points.
- **Two fighters.** Four wait for a later cut, as the plans say.

## 8. Events, and what each director reads

| Event | Fields | Change |
| :--- | :--- | :--- |
| `intro_start` | dur, delay, **kind** (the scenario), **actor** (the slot that arrives first), **n** (the gap), **text** (the facts' plot id) | Four new fields. `dur` is the composed length |
| `entrance_fall` | actor, x, y, z, y1, dur, **mode** (`drop`) | One new field |
| `entrance_land`, `staredown_start`, `clock_start` | as today | |
| `intro_beat` | actor, kind (`wait`), dur (seconds until the staredown) | New |
| `intro_line` | actor (who may speak), kind (the slot: `arrive_remark`, `wait_remark`, `late_reply`, `staredown_pair`), variant (his role by arrival: `first` or `second`), **stance**, **angle**, **event**, **p** | New. A voice slot. The four tags are the facts' entry for this slot and this speaker, passed through unread; with no entry they are empty and `p` is 1. The sim holds no words |
| `intro_gesture` | actor, kind (the gesture's intent: a meaning, not a pose), text (the point: `land_first`, `land_second`, `wait`, `look_start`, `look_end`, or `part`) | New. Narrative's field names `intent` and `at` are `kind` and `text` here: the shared event fields, and the names Animation's render reads (`docs/animation/intro-gestures.md`) |

`SimIntro.timeline(S)` returns the whole composed timeline at any time (the scenario, the plot id, who is first, the gap, the composed length, and every beat with its tick and slot, the facts' gestures among them), so nobody has to rebuild it from events.

**Which entry of `intents` a slot gets.** The slot's name picks the entry. An entry with `lines` holds one row a speaker: the row whose `who` is the speaker's role (`first` or `second`, or `left` or `right`). A plain entry with a `who` applies only to that speaker, so the second fighter's `arrive_remark` carries no tags when the entry says `first`.

| Who | Reads | Does |
| :--- | :--- | :--- |
| **Rendering, UI (the host)** | The setup's record | Sends `{"play": true, "avoid": [...], "facts": {...}}` for a varied intro; `true` for Classic; `"skip"` for intros off. Keeps the no-repeat list for each pair, runs Narrative's grammar and resolves it into `facts`. Nothing changes until it does: `true` still plays today's intro |
| **Animation** | `f.state == "waiting"`; `intro_beat` kind `wait`; `entrance_fall.mode`; `intro_gesture` | A waiting idle. Its intro code tests `state == "intro"` today, so a waiting fighter needs a pose before the host asks for the Latecomer. A pose for each gesture intent, a fighter at a time; a missing one is a silent skip |
| **Camera** | `intro_start.kind` and `dur`; `SimIntro.timeline(S)`; `staredown_start.dur` | A shot recipe for each scenario: the hold on the empty spot (Latecomer), the long two-shot (Long Look). Its cuts must come from the events' durations, not from 300 |
| **UI** | `intro_start.dur` and `delay` | The skip prompt, as today. Captions from `intro_line` through the line system. The opening setting (Varied, Classic, Skip) |
| **Audio** | `intro_line`; `intro_start.kind` | The voice; the sound dropping out for `long_look` |
| **Narrative** | `intro_line.kind`, `variant`, `stance`, `angle`, `event`, `p` | The line system picks the words and decides whether the line plays, on its own stream. Two lines can be offered close together (V1 at 138 and V8 at 156 in the Double Drop); which plays is the line system's rule |
| **QA** | Nothing in the batches (they skip) | One row: every template plays for every pair |

## 9. As applied (2026-10-06, on 648c637)

- `sim/core/intro.gd` (the playback, rewritten), `sim/director/intro.gd` (new: the composer, `DirIntro`), `data/fight/intro.json` (the three scenarios), and the anchored edits in `sim/core/state.gd`, `fx.gd`, `hash.gd`, `view/fx.gd`, `tools/parity.gd` and `tools/golden_recipes.gd`.
- In the same window, three lines in `sim/core/wounds.gd`: a stun ends the stance mask and the two held levels of intent version 4, as it ends `lightHeld` and `heavyHeld` (the EP's ruling), with a check.
- **In the tree:** the classic intro's per-tick state digest is identical before and after the code; the regenerated goldens have identical light digests and tick counts for all 9 matches (172,424 ticks) and both replays; `npm test` 5 of 5; parity 38 checks; render determinism, the loader check, the touch test, the seam sweep and Animation's `anim_check` pass.
- **Against Animation's render:** a Double Drop and a Latecomer with five facts gestures each, run through the game's own scene headless: every `intro_gesture` event (`actor`, `kind`, `text`) started a motion on its fighter, none skipped.
- **Tools' schema** (`docs/tools/pending/apply-intro2.cjs`, run by the EP at the commit): with it the validator is at 0 errors and its self-test passes (3,969 of 3,969), proven in a scratch copy of the tree. Without it the validator reports 7 errors on `data/fight/intro.json`.

## 10. Goldens and proofs (first in a scratch copy of baaba63; the same in the tree, section 9)

**What moves in the goldens.**

| | Moves? |
| :--- | :--- |
| The nine golden matches and both replays | **No.** After `code`, every checkpoint is equal, light and full. After `hash`, light digests and tick counts are identical; the full-state checkpoints and the six tick-0 states move, because `S.intro`'s six new fields are in every state hash |
| The fight data hash | Yes: `intro.json` changed |
| The intro vector (`intro`: seed 7 with `"intro": true`) | Yes, by its events only: the classic opening now sends four voice slots and the new event fields |
| A new vector, `introComposed` | New: nine composed intros (two free draws, two with a no-repeat list, each template by name, two with Narrative's example facts), every tick's fighters and events, and what was composed. It pins the keyed draws, the bends and the timelines across platforms |

One regeneration covers both parts.

**Proofs.**

1. **A plain `"intro": true` is today's intro, state for state.** A per-tick digest of the whole gameplay state over four matches that play it (900 ticks each, one skipped by a press) is identical on HEAD and on the build.
2. **`code`:** parity passes on HEAD's goldens but for the fight data hash and the two intro vectors. Regenerated: all 9 matches (172,441 ticks) and both replays equal at every checkpoint.
3. **`hash`:** light digests and tick counts identical.
4. **The check "composed intros"** runs every template with either fighter first at its shortest, default and longest gap (14 intros). For each: every beat's event comes on its tick with its slot; the first to arrive is `waiting` only where the template says and only until the staredown; the state at the clock equals the state the setup's `skip` gives; the tick after the clock is live; a skip press at four points gives the same state. Then the composer over 600 seeds: the same seed and record compose the same intro; the shares follow the weights; both orders come up; the gaps stay in range and vary; a `notTwice` template never follows itself; one played three times lately is drawn less; the `tones` fact filters; a record's `scenario`, `order` and `gap` are obeyed and the gap clamped; nothing fitting gives the classic. Then two recorded matches with a record (one played through, one skipped) replay exactly, and the header keeps the record.
5. **The facts, in the same check.** A template the weights put at 0 is never drawn in 300 seeds and one at x10 is drawn more than without; unknown keys change nothing. The gap bend at -1, -0.6, 0, 0.5 and 1 lands where the rule says, for every template over 59 seeds, and does not move a gap the setup fixed. Then four played intros (either fighter first, with the facts' look and with the slot's own): the look part, the gap and the bent clock are what the facts ask; each gesture's event comes on its point's tick for the right slot, `both` gives two, an unknown point and an unknown `who` are skipped; each voice slot carries its own tags and no other's; the plot id is on `intro_start`, in the timeline and in the feed; the staredown's length follows the bent clock; **the state at the clock is still the one the setup's skip gives.** A clock bend past the range is clamped and one with no room is dropped. A recorded match with the facts replays exactly, and the header keeps them.
6. **Gates on the build:** parity 37 checks, determinism, the loader check, the touch test (167), the seam sweep, `npm test` 5 of 5, and Animation's `anim_check` (it starts matches with `"intro": true`).
7. **The validator** reports 7 errors, all on `data/fight/intro.json` against the old schema (section 11).
8. **Cost:** the composer runs once a match. Nothing is added to a live tick.

## 11. New keys for Tools (`tools/schemas/fight-intro.schema.json`)

The file's shape changes, so its schema is replaced, not extended.

- Gone: `ticks {fallA, landA, fallB, landB, staredown, clock, skipFrom}`.
- Top level: `schema` (`fight.intro/2`), `skipFrom` (integer, at least 0), `fallHeight`, `craterEnergy` (kept), `clockBend {min (0 or less), max (0 or more)}` (integers), `gesturePoints {land_first, land_second, wait, look_start (0 or more), look_end (0 or less)}` (integers), `parts` (an open table), `templates` (an array, at least one).
- A part: `type` (`entrance`, `reaction`, `look`), `mode` (string; required for an entrance), `ticks` (integer, at least 0), `beats[]` of `{t (integer), kind (fall, land, wait, line, staredown, gesture), intent (string, required for a line and a gesture), who (first, second, left, right)}`.
- A template: `id`, `weight` (at least 0), `tone` (`light`, `neutral`, `grave`), `clock` (integer), `gap {min, max, default}` (integers, min <= default <= max), `notTwice` and `classic` (booleans, optional), `slots[]` of `{slot (a label), who (first, second, left, right, both), pool (part ids, at least one), after (integer), gap, with, draw (booleans)}`.
- Cross-checks worth having: every pool id is a part; exactly one template is `classic`; ids are unique. The loader already refuses a template that does not fit its clock.

Until the schema lands, the validator reports the new file.

**The `facts` record is not a data file,** so it has no schema of mine: it is the setup's, passed by the host. Narrative's section 11.5 is its definition, and its grammar file (`data/narrative/intro_plots.json`) is Narrative's and Tools' to give a schema. If Tools wants a check that a grammar's output is a valid record, the shape is section 6b's table.

## 12. Decisions taken, and open points

1. **`true` stays the classic opening.** Animation's and Camera's checks start matches with `"intro": true` and assume today's ticks and the `intro` state. Keeping `true` classic lets this land without breaking them; the host opts into composed intros with the record form when the poses and shots exist. If the EP wants `true` to compose, it is one line.
2. **Lengths past 300** (section 5).
3. **Who is first is an even draw.** Today it is always the left spot. Narrative's rules about who waits belong to the pair, so the host passes `order` when it has a preference.
4. **The Long Look's gap does not vary.** Narrative lists no gap swap for it.
5. **The voice slots' ticks are mine, from Narrative's "about" times.** They are data.
6. **`facts` is Narrative's flat record** (section 6b). The grammar, the history and the plot pick are the host's.
7. **The look is not left to chance.** Its slots are `"draw": false`: the facts choose it, or the template's own first part plays. An even draw would have made half of the plain Double Drops a silent long stare.
8. **A fifth gesture point, `wait`.** Narrative's table lists gestures "at the wait" for the Latecomer beside its four named points, so the build has it; it is skipped in a template with no wait.
9. **Mine, as data, for Narrative to tune:** the gesture points' ticks (12 after a landing, 20 into the wait, 24 into the look, 48 before the clock) and the clock bend's range (60 either way; Narrative's bends are 24 and 36).
