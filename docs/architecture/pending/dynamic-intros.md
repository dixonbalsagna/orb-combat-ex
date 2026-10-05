# Patch plan: dynamic intros, the first cut

Owner: Simulation and Engine. Date: 2026-10-04. Status: **built and proven in a scratch copy of fd326de, parked, not applied.** Encounter has the sim tree (the brawl's groundwork), World is next; this applies after them.

Sources: Encounter's composer plan (`docs/director/dynamic-intros-plan.md`), Narrative's content (`docs/narrative/dynamic-intros.md`: S1 Double Drop, S2 Latecomer, S9 Long Look; voice intents V1, V2, V3, V8), the intro phase as built (`docs/architecture/intro-phase.md`).

The build is in `docs/architecture/pending/dynamic-intros/`: `dynintro.py` and the three files it installs (section 9).

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
| `facts` | What the host knows about the pair. Today one fact is read: `tones`, the tones the pair allows (`light`, `neutral`, `grave`). Left out: all |
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
| `slots[].pool` | The parts that may fill the slot. The first cut's pools hold one part each; the pick is built and drawn for more |
| `slots[].after`, `gap`, `with` | Ticks after the slot before it ends; add the drawn gap; run alongside without moving the template on |

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

## 7. The playback

- **State** (`S.intro`, integers, hashed): `scenario` (the template's index, -1 when none plays), `first`, `gap`, `picks`, and `dug` (a bit a slot: his crater is dug), beside today's `left`, `t`, `landed`. The beats are worked out from those and the data; they are not state.
- **Fighter states:** `intro` as today, and **`waiting`** for the first to arrive, from his `wait` beat to the staredown. The sim holds through the intro, so the state is for the view.
- **Skip:** as today. The landings left are applied at once, the first to arrive first.
- **The end state is the same for every intro.** Both fighters free on their start spots, each in his crater. One thing had to be made order-proof: the crater records are a list. When the right spot's fighter lands first, the two records are put back in the order of the start spots as the second one is dug. So the state at the clock equals the state the setup's `skip` gives, whatever was composed and whenever it was skipped. The check proves it for every template, either order, three gaps and four skip points.
- **Two fighters.** Four wait for a later cut, as the plans say.

## 8. Events, and what each director reads

| Event | Fields | Change |
| :--- | :--- | :--- |
| `intro_start` | dur, delay, **kind** (the scenario), **actor** (the slot that arrives first), **n** (the gap) | Three new fields |
| `entrance_fall` | actor, x, y, z, y1, dur, **mode** (`drop`) | One new field |
| `entrance_land`, `staredown_start`, `clock_start` | as today | |
| `intro_beat` | actor, kind (`wait`), dur (seconds until the staredown) | New |
| `intro_line` | actor (who may speak), kind (the intent: `arrive_remark`, `wait_remark`, `late_reply`, `staredown_pair`), variant (his role by arrival: `first` or `second`) | New. A voice slot: the intent only. The sim holds no words; a slot with no line plays silent |

`SimIntro.timeline(S)` returns the whole composed timeline at any time (the scenario, who is first, the gap, the length, and every beat with its tick and slot), so nobody has to rebuild it from events.

| Who | Reads | Does |
| :--- | :--- | :--- |
| **Rendering, UI (the host)** | The setup's record | Sends `{"play": true, "avoid": [...], "facts": {...}}` for a varied intro; `true` for Classic; `"skip"` for intros off. Keeps the no-repeat list for each pair. Nothing changes until it does: `true` still plays today's intro |
| **Animation** | `f.state == "waiting"`; `intro_beat` kind `wait`; `entrance_fall.mode` | A waiting idle. Its intro code tests `state == "intro"` today, so a waiting fighter needs a pose before the host asks for the Latecomer |
| **Camera** | `intro_start.kind` and `dur`; `SimIntro.timeline(S)`; `staredown_start.dur` | A shot recipe for each scenario: the hold on the empty spot (Latecomer), the long two-shot (Long Look). Its cuts must come from the events' durations, not from 300 |
| **UI** | `intro_start.dur` and `delay` | The skip prompt, as today. Captions from `intro_line` through the line system. The opening setting (Varied, Classic, Skip) |
| **Audio** | `intro_line`; `intro_start.kind` | The voice; the sound dropping out for `long_look` |
| **Narrative** | `intro_line.kind` and `variant`, with the pair | The line system picks the words. Two lines can be offered close together (V1 at 138 and V8 at 156 in the Double Drop); which plays is the line system's rule |
| **QA** | Nothing in the batches (they skip) | One row: every template plays for every pair |

## 9. The build, and how to apply it

`docs/architecture/pending/dynamic-intros/`:

| File | What it is |
| :--- | :--- |
| `dynintro.py` | The slice, in two parts: `python docs/architecture/pending/dynamic-intros/dynintro.py . code`, then `... hash`. It stops if `sim/core/intro.gd` or `data/fight/intro.json` has changed since it was built, or if `sim/director/intro.gd` exists |
| `src/intro_core.gd.txt` | The new `sim/core/intro.gd` |
| `src/intro_dir.gd.txt` | The new `sim/director/intro.gd` |
| `src/intro.json` | The new `data/fight/intro.json` |

It also edits `sim/core/state.gd`, `fx.gd`, `hash.gd`, `view/fx.gd`, `tools/parity.gd` and `tools/golden_recipes.gd` by anchored text. After `code`, run Godot's `--import` once: `DirIntro` is a new class.

## 10. Goldens and proofs (scratch copy of fd326de; the files it touches are unchanged on e87d8e5)

**What moves in the goldens.**

| | Moves? |
| :--- | :--- |
| The nine golden matches and both replays | **No.** After `code`, every checkpoint is equal, light and full. After `hash`, light digests and tick counts are identical; the full-state checkpoints and the six tick-0 states move, because `S.intro`'s five new fields are in every state hash |
| The fight data hash | Yes: `intro.json` changed |
| The intro vector (`intro`: seed 7 with `"intro": true`) | Yes, by its events only: the classic opening now sends four voice slots and the new event fields |
| A new vector, `introComposed` | New: seven composed intros (two free draws, two with a no-repeat list, each template by name), every tick's fighters and events, and what was composed. It pins the keyed draws and the timelines across platforms |

One regeneration covers both parts.

**Proofs.**

1. **A plain `"intro": true` is today's intro, state for state.** A per-tick digest of the whole gameplay state over four matches that play it (900 ticks each, one skipped by a press) is identical on HEAD and on the build.
2. **`code`:** parity passes on HEAD's goldens but for the fight data hash and the intro vector. Regenerated: all 9 matches (174,956 ticks) and both replays equal at every checkpoint.
3. **`hash`:** light digests and tick counts identical.
4. **The new check "composed intros"** runs every template with either fighter first at its shortest, default and longest gap (14 intros). For each: every beat's event comes on its tick with its slot; the first to arrive is `waiting` only where the template says and only until the staredown; the state at the clock equals the state the setup's `skip` gives; the tick after the clock is live; a skip press at four points gives the same state. Then the composer over 600 seeds: the same seed and record compose the same intro; the shares follow the weights; both orders come up; the gaps stay in range and vary; a `notTwice` template never follows itself; one played three times lately is drawn less; the `tones` fact filters; a record's `scenario`, `order` and `gap` are obeyed and the gap clamped; nothing fitting gives the classic. Then two recorded matches with a record (one played through, one skipped) replay exactly, and the header keeps the record.
5. **Gates on the build:** parity 37 checks, determinism, the loader check, the touch test (167), the seam sweep, `npm test` 5 of 5, and Animation's `anim_check` (5,346 checks; it starts matches with `"intro": true`).
6. **The validator** reports 5 errors, all on `data/fight/intro.json` against the old schema (section 11).
7. **Cost:** the composer runs once a match, about 30 microseconds. Nothing is added to a live tick.

## 11. New keys for Tools (`tools/schemas/fight-intro.schema.json`)

The file's shape changes, so its schema is replaced, not extended.

- Gone: `ticks {fallA, landA, fallB, landB, staredown, clock, skipFrom}`.
- Top level: `schema` (`fight.intro/2`), `skipFrom` (integer, at least 0), `fallHeight`, `craterEnergy` (kept), `parts` (an open table), `templates` (an array, at least one).
- A part: `type` (`entrance`, `reaction`, `look`), `mode` (string; required for an entrance), `ticks` (integer, at least 0), `beats[]` of `{t (integer), kind (fall, land, wait, line, staredown), intent (string, required for a line), who (first, second, left, right)}`.
- A template: `id`, `weight` (at least 0), `tone` (`light`, `neutral`, `grave`), `clock` (integer), `gap {min, max, default}` (integers, min <= default <= max), `notTwice` and `classic` (booleans, optional), `slots[]` of `{slot (a label), who (first, second, left, right, both), pool (part ids, at least one), after (integer), gap, with (booleans)}`.
- Cross-checks worth having: every pool id is a part; exactly one template is `classic`; ids are unique. The loader already refuses a template that does not fit its clock.

Until the schema lands, the validator reports the new file.

## 12. Decisions taken, and open points

1. **`true` stays the classic opening.** Animation's and Camera's checks start matches with `"intro": true` and assume today's ticks and the `intro` state. Keeping `true` classic lets this land without breaking them; the host opts into composed intros with the record form when the poses and shots exist. If the EP wants `true` to compose, it is one line.
2. **Lengths past 300** (section 5).
3. **Who is first is an even draw.** Today it is always the left spot. Narrative's rules about who waits belong to the pair, so the host passes `order` when it has a preference.
4. **The Long Look's gap does not vary.** Narrative lists no gap swap for it.
5. **The voice slots' ticks are mine, from Narrative's "about" times.** They are data.
6. **`facts` reads one fact.** History, the settlement in view and the rest wait for the scenarios that need them.
