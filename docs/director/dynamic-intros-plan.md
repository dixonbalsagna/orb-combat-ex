# Dynamic intros: a plan for an intro composer

Owner: Encounter Systems Director. Date: 2026-10-04. Status: plan only, nothing built. Asked by Orb (2026-10-04): intros assembled from parts, mixed and matched between characters. Narrative writes the scenario content in `docs/narrative/dynamic-intros.md` in parallel; this plan gives the shape its beat lists drop into.

## 1. What the intro does today, and what is fixed in it

The intro phase is built (`docs/architecture/intro-phase.md`; `sim/core/intro.gd`, `SimIntro`; `data/fight/intro.json`). **It is Simulation's file, not the director's.** The composer below is a director module that Simulation's phase would play; see §9 for who changes what.

| Today | Detail |
| :--- | :--- |
| **A run of pre-clock ticks** | `SimCore.step` returns false, `S.T` stays 0, no input is consumed, nothing else in the sim runs. 300 ticks (5 s) |
| **One fixed timeline** | A falls (ticks 0 to 36) and lands in a crater; B falls (84 to 114) and lands in a crater; the staredown starts at 144; the clock starts at 300 |
| **Who is A** | The fighter on the left start spot. It is the spot, not the slot, so QA's swapped arms dig the craters in the same order |
| **The world effect** | Two entrance craters (World's dig, energy 1.5, nobody's), both fighters standing on their start spots |
| **Skip** | Any press on a human slot from tick 30 skips: the landings left are applied at once, in order. **The state at the clock is the same whether it ran or was skipped** |
| **The default** | A match that does not ask for the intro starts from the intro's end state with no pre-clock tick. So the game, QA's batches and the goldens share one opening |
| **Events** | `intro_start`, `entrance_fall`, `entrance_land`, `staredown_start`, `clock_start`. Camera, UI and Animation read them |
| **No draw** | The fall is a closed-form path. Nothing in the intro draws a random number |
| **The look** | Animation plays one small staredown beat a fighter, picked by his shape (`data/anim/intro.json` `beats`): render only, outside the sim |

**Fixed today:** the order (A then B), the entrance kind (a fall into a crater), the timing, the one staredown, and no voice line. Nothing depends on who the fighters are.

## 2. The composer in one paragraph

When a match starts, the composer picks a **scenario template** for the pair and fills each of its **slots** with one **part** from that slot's pool. The picks are keyed draws on the match seed, so no stream shifts and a replay matches. The result is a timeline of beats on pre-clock ticks, which the intro phase plays in place of its fixed one. Every pick is written to the feed with its reason. **Whatever is picked, the state at the clock is the same** (§6), so a skip, QA's batches and the goldens do not depend on the choice.

## 3. Part types

| Part type | What it is | Examples for the first cut | Later |
| :--- | :--- | :--- | :--- |
| **Entrance** | How one fighter arrives at his start spot. One for each fighter | The fall into a crater (today's). Already there: he stands in his crater as the intro opens | A slow descent, a flight in from off screen, a burst from the sea or the ground |
| **Reaction** | What the fighter already present does as the other arrives | Looks up and tracks the fall. Does not turn until the landing | Guards against the landing's dust, steps back, turns his back |
| **The look or gesture** | The beat between them before the fight. It carries the voice-line slot | Animation's two staredown beats (the cuff, the roll). A held stare with no gesture | A power flare, a point, a nod, a taunt gesture from the taunt system |
| **The cut to the fight** | How the clock starts | Both set their stance together. One steps first and the other answers | A flash of both auras, a first step that becomes the first approach |

A part is a short list of beats with ticks counted from the part's start. It has no effect on the world except through the entrance's landing, which is the same for every entrance (§6).

## 4. The data shape

One new file, `data/director/intros.json`. Narrative's beat lists become `templates` and `parts` rows; nothing in code names a fighter.

```json
{
  "schema": "director.intros/1",
  "roles": {
    "first":  "the fighter who is on stage first (he enters first, or is already there)",
    "second": "the fighter who arrives second"
  },
  "templates": [
    {
      "id": "arrival",
      "weight": 1.0,
      "when": { "pair": ["any", "any"], "biome": ["any"], "ground": true, "rematch": "any" },
      "firstIs": "left",
      "slots": [
        { "slot": "entrance", "who": "first",  "pool": ["entrance.fall"] },
        { "slot": "entrance", "who": "second", "pool": ["entrance.fall"], "after": 48 },
        { "slot": "reaction", "who": "first",  "pool": ["reaction.look_up", "reaction.hold"], "with": "second.entrance" },
        { "slot": "look",     "who": "both",   "pool": ["look.stare", "look.gesture"], "after": 30 },
        { "slot": "cut",      "who": "both",   "pool": ["cut.set", "cut.step_first"] }
      ],
      "maxTicks": 300
    }
  ],
  "parts": {
    "entrance.fall": {
      "type": "entrance", "ticks": 36,
      "tags": ["any"],
      "beats": [ { "t": 0, "cue": "entrance_fall" }, { "t": 36, "cue": "entrance_land", "land": true } ]
    },
    "look.gesture": {
      "type": "look", "ticks": 156,
      "tags": ["any"],
      "beats": [
        { "t": 0,  "cue": "staredown_start" },
        { "t": 54, "cue": "intro_gesture", "who": "second" },
        { "t": 70, "line": { "speaker": "second", "intent": "challenge" } }
      ]
    }
  }
}
```

| Key | Meaning |
| :--- | :--- |
| `roles` | Parts and templates name `first` and `second`, never a fighter. Any pair works in either role |
| `templates[].when` | The filter (§5). `pair` is two tag sets, matched in either order unless the template says `ordered` |
| `templates[].firstIs` | Who is `first`: `left` (today's rule), `loser` or `winner` of the last match, or `tag:<name>` (the fighter who carries that tag) |
| `slots[]` | The scenario's order. `pool`: the parts that may fill it. `after`: ticks after the slot before it ends. `with`: it runs alongside another slot |
| `parts[].tags` | Which fighters may play the part: `any`, or tags from the fighter's data (§5) |
| `parts[].beats` | Ticks from the part's start. `cue`: an event for Animation, Camera, VFX and Audio. `line`: a voice-line slot (§7). `land`: the touchdown, the only world effect |
| `maxTicks` | The template's length may not pass it. A fill that would is not offered |

**Four fighters later.** Nothing changes in the shape: templates filter by tags, so a new fighter joins every template his tags allow. A scenario written for one pairing names the two fighters' tags in `when.pair`.

## 5. What the selection reads

| Input | Where it comes from | Used for |
| :--- | :--- | :--- |
| **The pair** | Each fighter's tags in his data: a personality tag (the one who cares, the one who menaces), his roster id as a tag, and any tag Narrative adds | `when.pair`, `parts[].tags`, `firstIs: tag:` |
| **A mirror** | The two roster ids are the same | A tag `mirror` on the pair, so a template can ask for it or refuse it |
| **Biome at the spawn** | `WorldBiomes.biomeAt` at each start spot | `when.biome`. Today both spots are open ground |
| **Altitude at the spawn** | On the ground, over the sea, in the air. Today always the ground | `when.ground`; sea and air entrances wait until a match can start there |
| **Forms** | Each fighter's tier as the match starts. Today always 1 | A filter for power-flare looks later |
| **The last result** | The setup: who won the last match of this session, if the host says | `when.rematch`, `firstIs: loser` |
| **A no-repeat memory** | The setup: a short list of the template and part ids played lately (below) | Those ids are passed over while another choice is left |
| **The seed** | The match seed | Keyed draws: `SimRng.keyed(seed, "intro.template", 0)` and one for each slot |

**Where the no-repeat memory lives.** Not in the sim. The host (the game's shell) keeps the last few intro picks for each pair in the session or the profile, and passes them in `newMatch`'s setup:

```json
"intro": { "play": true, "avoid": ["arrival/entrance.waiting/look.stare"], "last": "A" }
```

The setup is in the replay header, so a replay gets the same list and composes the same intro. A match with no list (QA's batches, the goldens) simply avoids nothing. The sim never reads a file or a clock for it, so determinism holds.

**Explainable.** One feed line a pick, on the first pre-clock tick: `INTRO: arrival (3 templates fit; 1 passed over as played lately)`, then `INTRO first: entrance.waiting (of 2)`, and so on. A feed line can be sent on a pre-clock tick like any event.

## 6. The rule that keeps goldens and replays safe

**Every composed intro ends in the same state:** both fighters standing on their start spots, each in his entrance crater, the clock at 0.

- Every entrance digs the same crater at its `land` beat. "Already there" lands on tick 0.
- A skip applies the landings left, in order, as today. So does the default start with no pre-clock tick.
- The picks are keyed draws: they take nothing from the match's stream.

So the choice of intro cannot change a fight. QA's batches and the nine golden matches start from the same state as now and do not move. An entrance that changes the world (no crater, a different spot, a splash) would break this; it waits for a later slice, where the picked end effects are applied at the skip too and the goldens are regenerated once.

## 7. Voice lines: slots with an intent

A `line` beat says who speaks and why, and nothing else:

| Field | Values |
| :--- | :--- |
| `speaker` | `first`, `second` |
| `intent` | A small closed list for Narrative to fix: `challenge`, `dismiss`, `greet`, `warn`, `respect`, `mock`, `vow` |
| `to` | Optional: the other fighter's tag, for a line that depends on who he faces |

The sim sends one event, `intro_line` {speaker's slot, intent, template, part}. Narrative's line system (`docs/narrative/line-system.md`, `dialogue-director.md`) picks the words from Orb's lines. The composer never holds text, and **the voice lab is not touched.** A slot with no line written for it plays silent; the beat's timing does not change.

## 8. Cues the other directors would need

| Who | Cues or events | What exists |
| :--- | :--- | :--- |
| **Animation** | `entrance_fall`, `entrance_land` (kept); `entrance_waiting` (the idle of a fighter already there); `intro_react` {kind}; `intro_gesture` {kind}; `intro_cut` {kind} | The fall, the landing and two staredown beats exist. Animation picks the staredown beat by shape today; with the composer the event names it |
| **Camera** | The same events, each with the part's id and length, and `intro_start` with the whole timeline (ticks of every part) so it can plan its cuts | Camera reads the five events today and writes nothing |
| **VFX** | `entrance_land` (the dust and the crater, kept); later an aura flare on a look and a splash on a sea entrance | The landing's effects exist |
| **Audio** | A sting for each part type; `intro_line` for the voice; `clock_start` (kept) | No audio yet |
| **UI** | `intro_start` with the skip time (kept); subtitles from `intro_line` | The intro phase's plan gives UI the HUD hidden until `clock_start` and the skip prompt |

## 9. A first cut small enough for one slice

**Content:** 3 templates and 9 parts, all on the ground, all ending as today.

| Templates | Parts |
| :--- | :--- |
| `arrival` (first enters, second enters, the look, the cut): today's intro as data | Entrances: `fall`, `waiting` |
| `waiting` (first is already there, second falls in, first reacts) | Reactions: `look_up`, `hold` |
| `together` (both fall at once, land a few ticks apart) | Looks: `stare`, `gesture` (Animation's existing beat), `line` (a stare with one voice-line slot) |
| | Cuts: `set`, `step_first` |

That gives 30 different intros (arrival 12, waiting 12, together 6) before the voice lines vary them.

**Who changes what:**

| Who | What |
| :--- | :--- |
| **Encounter** | `sim/director/intro.gd` (`DirIntro`): the filters, the keyed picks, the timeline, the feed lines. `data/director/intros.json` |
| **Simulation** | `SimIntro` plays a timeline held in `S.intro` (integers, hashed) in place of its static ticks; the setup's `intro` may be an object (`play`, `avoid`, `last`); `data/fight/intro.json` keeps `skipFrom`, the fall height and the crater energy. Its file: a patch from Simulation, or a grant |
| **Animation** | The waiting idle and the two reactions (three short clips); the staredown beat named by the event |
| **Camera** | Cuts planned from the timeline in `intro_start` |
| **Narrative** | The templates' beat lists and the intents; Orb writes the lines |
| **Tools** | The schema for `intros.json`; a check that every template has at least one fill inside `maxTicks` for every pair of tags, and that every entrance has exactly one `land` |
| **QA** | Nothing new in the batches (they skip). One row: every template plays for every pair |

**What it costs.**

| | Cost |
| :--- | :--- |
| **Goldens** | The nine golden matches' ticks and results do not move (§6). `S.intro` grows and is hashed; whether the stored digests change with it is Simulation's to say. Simulation's intro vectors (its parity check, and any golden that plays the intro) are redone for a composed intro |
| **Parity checks** | The intro check grows: every template and every fill reaches the same state at the clock; a skip at several ticks does too; a replay with an `avoid` list composes the same intro |
| **Match length** | None. The intro runs on pre-clock ticks: `S.T` is 0 until the clock, so it is outside the 480 s median by construction. QA's batches skip it and run no pre-clock tick |
| **Wall-clock time** | Today 5 s. The first cut's templates are capped at `maxTicks` 300, so no intro is longer than today's |
| **Machine** | A few keyed draws and one small file at match start. Nothing a tick |

## 10. Skip and accessibility

| Case | Behaviour |
| :--- | :--- |
| **Skip** | As today: any press on a human slot from `skipFrom` skips for both players. The landings left are applied at once and the clock starts. A line that was playing is cut by the line system on `clock_start` |
| **Intros off** | A host setting. The setup says `"intro": "skip"`: no pre-clock tick, the same start state |
| **Short intros** | A host setting. The composer keeps only the entrances and the cut (a template may mark slots `"short": false`), about 2 s |
| **Seen before** | The no-repeat list avoids a repeat while another choice is left. The host may also turn on short intros by itself after the first match of a session |
| **Reduced motion** | A setting for Camera to honour (it may not exist yet): one wide two-shot held through the intro, the cut hints ignored. The sim sends the same events |
| **Flashes** | No part in the first cut flashes. A later power flare goes through VFX's photosensitivity limits |
| **Hearing** | Every `intro_line` has a subtitle from the line system; the look's gesture carries the meaning without it |
| **The skip prompt** | Shown from `intro_start`, as today; the skip time comes with the event |

## 11. Open questions

1. **Ownership.** The intro phase is Simulation's as built. The plan puts the composer in the director and the playing in Simulation's phase. Confirm the split, or move the phase.
2. **Does an entrance ever change the world?** The first cut says no (§6). If Orb wants entrances without a crater, or at a different spot, that is a second slice with one golden regeneration.
3. **Should the pair's history matter beyond the last result?** A session tally (two wins in a row) would be one more host-supplied field.
4. **Who is `first` by default?** The plan keeps the left start spot, so QA's swapped arms stay symmetric. Narrative may prefer the challenger.
