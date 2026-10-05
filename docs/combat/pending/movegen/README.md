# Generated movesets: the martial arts stance, both fighters

Owner: Combat and Choreography. Date: 2026-10-05. Status: parked. Nothing here is loaded or hashed, and nothing in the tree is edited. Design: `../../moveset-generator.md`. Built on HEAD `c4c497b`, with Legal's rows merged (`docs/legal/movegen-banned.json`, RL-072 to RL-075).

This folder is the generator's inputs, its reference script, and its output for the two launch fighters.

| File | What it is | Becomes |
| :--- | :--- | :--- |
| `parts.json` | the strike grammar; every posed strike as a shape of it; Legal's banned shapes, sequence rules and conditions | `data/combat/parts.json` |
| `identity.json` | how each fighter bends the grammar: weights, "never" rows, how strongly to prefer what is posed | `data/combat/identity.json` |
| `cells.json` | Game Design's matrix for the martial arts stance: counts, quotas, the seed | `data/combat/cells.json` |
| `gen_moveset.py` | the reference generator: standard library only, no state, no clock | a script under `tools/`, Tools' to hold |
| `moveset.rival.json`, `moveset.protagonist.json` | **generated:** 30 lights and 16 heavies each, with the context cell and the signature's frame | `data/combat/movesets/<fighter>.json` |
| `review-sheet.md` | **generated:** every move on one row, with Legal's conditions for Animation | stays in docs |

- **To generate:** `python docs/combat/pending/movegen/gen_moveset.py`. It refuses to write if anything matches one of Legal's rows.
- **To check:** add `--check`. It exits 1 when the files are not what the inputs give, or when a move on disk, the `links` table or one of Combat's blur patterns matches one of Legal's rows.
- **To prove the refusals:** `--self-test` runs 15 made-up moves and strings through the rows.
- **The seed** is 20261004, in `cells.json`.

## 1. Identity, as Orb confirmed it

- **The Protagonist:** palms, blade hands, arcs.
- **The rival:** fists, plates, straight lines. A closed fist on his heavies and enders (a blade hand on a heavy is a "never" row; a plate may lead). Blade hands first on his lights. **No palm strike at all:** the palm to the head is gone, and so is his posed palm heel, which stays posed and out of his cells.
- **The stick leans the limb:** the five leans are quotas of 5 on the light cell.
- **A juggle is up to 5 skill strikes:** the light cell has quotas of 10 moves that can be a flurry blow and 10 that can be a skill strike.
- **The signature's kind is not final,** so martial B is a generic frame with nothing hand-picked.

## 2. What came out

| Fighter | Cell | Moves | Posed | Derived | Waiting (a new key set) |
| :--- | :--- | ---: | ---: | ---: | ---: |
| The rival | X, lights | 30 | 14 | 3 | 13 |
| The rival | Y, heavies | 16 | 12 | 2 | 2 |
| The Protagonist | X, lights | 30 | 16 | 6 | 8 |
| The Protagonist | Y, heavies | 16 | 14 | 2 | 0 |

- **23 new key sets,** 21 of them lights; 13 derived moves. Each new one is listed at the end of its fighter's part of the sheet, with its conditions.
- **Playable on the first day:** the rival 17 lights and 14 heavies, the Protagonist 22 and 16.
- **Every quota is met.**
- **The two fighters share 20 of 46 shapes, 43%.** Today's pools share 97%.
- **With a leg broken on the ground,** the playable lights are 11 for the rival and 13 for the Protagonist, and the heavies 9 and 8.

## 3. Legal's rows

Merged into `parts.json` as they stand: 13 shape rows (`strike.banned`) and 7 sequence rules (`strike.bannedSequences`). Each sequence rule keeps Legal's words and gains a form a program can check.

**How a refusal works.** A row matches a move when every part it names matches. Its `flags` are about how the piece is posed, and for each move a flag is one of three things:

| A flag is | When | What the generator does |
| :--- | :--- | :--- |
| **Known present** | the fighter's own way of showing a tip says so (`identity.json` `tipFlags`), or the key set's manifest row lists it | the move is **refused**: it is never a candidate |
| **Known absent** | no part of the grammar can produce it, or the posed key set carries the Legal tag that rules it out | the row does not apply |
| **Unknown** | anything else: a new or derived shape, or a posed one with no tag for it | the row becomes a **condition** in the sheet's Legal column, for Animation to keep to |

**How each flag is set:**

| Flags | Set by | Needs Animation's data |
| :--- | :--- | :--- |
| `claw` | the fighter's `tipFlags`: the rival's palm is drawn clawed | no (later, the hand state at contact can replace it) |
| `two_fingers`, `pointing_finger`, `to_forehead`, `beckon`, `grip`, `vanish`, `blink_cut`; the targets throat, hair and tail | never: the grammar has no such hand state, step or target. A new one is new vocabulary and gets Legal's screen | no |
| `leap`, `spin` on a blow that is not a spin, `multi_turn`, `travelling` | the key set's `flags`; ruled out by the tags `no_leap` and `single_turn` | **yes** |
| `clasped`, `wrists_together`, `two_hand_chamber` | the key set's `flags`; ruled out by `no_clasp` and `wrists_apart` | **yes** |
| `cupped_at_hip`, `drawn_to_hip_then_thrust`, `hip_chamber` | the key set's `flags`; ruled out by `not_at_hip` | **yes** |
| `held_raise_overhead` | the key set's `flags`; ruled out by `no_held_raise` | **yes** |
| `passes_through` | the contact solve: a reach past the surface | **yes** (a lint on the solve) |
| `glow`, `energy_ball`, `growing_orb`, `afterimage_hides_body` | VFX's data for the piece; a melee piece carries none | VFX's, not Animation's |

**What Animation would add:** a `flags` list on a manifest row, for the 12 flags marked yes. The generator already reads it. No row has one today, so today's only definite flag is the rival's clawed palm, and every other row is a condition on the sheet.

**The sequence rules:**

| Rule | Checked by the generator | Left to |
| :--- | :--- | :--- |
| s01, at most 3 of the same limb, tip and path running | on any string it composes | the director, on the strings the presses make |
| s02, at most 2 blows running at one place, never 2 to the gut | on the blur patterns, wrap included | the director |
| s03, no repeated shouted syllable | no: it is not in the parts | Audio and the director's line picker |
| s04, no spin after a spin | on the `links` table: a spin never links to a spin | the director, as a hard rule and not a preference |
| s05, no rise after a rise in the air | on the `links` table, in every state | the director, in the air |
| s06, no two-hand drop after a launch | on any string it composes | the director |
| s07, only drawn steps | every move's steps are in, hold, around or out | Animation and VFX for what is drawn |

**What the check found.** Two of Combat's own blur patterns in the live `data/combat/recipes.json` break s02: `pendulum` ends with three blows running to the chest, and `undercut` has two running to the gut. They are fixed in the parked `../recipes.brawl.json` (pendulum's last step goes to the gut; undercut is legs, gut, chest, head, head). `--check` passes against the parked file and exits 1 against the live one, until the live file is edited in a window.

**Legal's conditions for Animation** are on the sheet: eight of them (L1 to L8) in a legend at its top, and on each row the ones that apply. Every heavy carries L6, the held-heavy rule; every rising hand blow carries L1.

## 4. Two rules the generator has beyond the design

1. **Legal's tags travel with a key set.** A hand-state swap stays inside them: a key set tagged "hands open or claw" is never closed into a fist (`tagTips`).
2. **A one-armed source is preferred** when two posed strikes could give the same shape, since a generated move is one limb.

## 5. Keys for Tools

A **filter** is an object of part to a list of allowed values (parts: `limb`, `tip`, `path`, `target`, `weight`, and `arms` as integers); all must hold. `any` is a list of filters of which one must. Keys starting `_` are notes everywhere.

### `combat-parts.schema.json` (`combat.parts/1`)

| Key | Shape |
| :--- | :--- |
| `strike.tips` | limb to tip to a list of paths |
| `strike.targets` | limb to path to a list of targets |
| `strike.lightNever` | a list of filters: a shape matching one is never light |
| `strike.sends` | path to across, up, down or turned |
| `strike.links`, `strike.step` | path to a list of paths; path to a list of in, hold, around, out |
| `strike.beat` | path to an integer from 20 to 28 |
| `strike.forms` | a list of `{form, when: filter}` or `{form, any: [filter]}`, with an optional `unless` naming a form that rules it out |
| `strike.swap` | a list of hand tips |
| `strike.tagTips` | a Legal tag to the hand tips a swap may show |
| `strike.reaim` | `limbs`, a list; `neighbours`, target to a list of targets |
| `strike.banned` | Legal's rows: a list of `{id, match, why}`. `match` is a filter that may also name `form` (a list of forms) and `flags` (a list of flag names) |
| `strike.bannedSequences` | a list of `{id, kind, rule, why}` and, by `kind`: run: `same` (a list of parts), `max`, and optionally `tighter`, a list of `{when: filter, max}`. after: `after` (a filter, or `event`), `never` (a list of filters), optionally `state`. steps: `drawn`, a list of steps. audio: nothing more |
| `strike.flags` | `clearedBy`, a Legal tag to the flags it rules out; `byVocabulary`, `fromAnimation`, `fromVfx`: lists of flag names; `fromTip`, a note |
| `strike.conditions` | a list of `{id, when: filter, rows, ask}`; `rows` are ids of banned rows and sequence rules |
| `strikes` | strike id to `{limb, tip, path, target, weight, uses, ground}` |

Cross-checks: every row of `strikes` is a valid shape; every path has a send, links, a step and a beat; a strike id is the `combat` id of a manifest row whose limb and target agree (the grammar's `arm` is the near arm's socket); every flag a banned row names is in exactly one of the flag lists or is a key of an identity's `tipFlags`; every id in a condition's `rows` exists; **a banned row is never removed or loosened without Legal** (compare with `docs/legal/movegen-banned.json`: every row there is here, unchanged).

### `combat-identity.schema.json` (`combat.identity/1`)

| Key | Shape |
| :--- | :--- |
| `fighters` | fighter id to the block below |
| `waves` | a list of wave names, in the order their rows replace each other |
| `weights` | `limb`, `path` and `tip`, each a name to a number of 0 or more; a tip is written `limb.tip` |
| `weightsBy` | a list of `{when: filter, tip}`: weights that replace the plain ones for shapes the filter matches |
| `never` | a list of `{shape: filter, why}` |
| `tipOf` | strike id to a tip: his own reading of a shared strike |
| `tipFlags` | `limb.tip` to a list of flags: how he shows that tip |
| `reuse` | `posed`, `hand_state`, `re_aim`, `hand_state_re_aim`: numbers of 1 or more |
| `rejected` | a list of `{fighter, shape, why}`, the shape as limb, tip, path, target, weight |

Cross-checks: every wave has a manifest; every tip key is a tip of `parts.json`; the fighters are the fighter keys of `recipes.json`.

### `combat-cells.schema.json` (`combat.cells/1`)

| Key | Shape |
| :--- | :--- |
| `seed` | an integer |
| `spread` | `path`, `target`, `tip`, `shape`: numbers over 0 and at most 1 |
| `stances` | stance name to `{held, x, y, a, b}`; `held` is the stance mask |
| a strikes cell | `kind` strikes; `what`; `filter`; `count`; `quotas`, a list of `{name, min}` with one of `filter`, `any`, `form` or `sends` |
| a context cell | `kind` context; `what`; `actions`, a list of names; `held` |
| a frame cell | `kind` frame; `what`; `slots`, a list of `{slot}` with any of `ticks`, `count`, `from`, `order`, `by` |

### `combat-moveset.schema.json` (`combat.moveset/1`)

| Key | Shape |
| :--- | :--- |
| `fighter` | the fighter id |
| `generator` | `version`, `seed`, and `inputs`, a hash of the three input files and the manifest rows read |
| `cells` | cell id (`stance.button`) to a cell |
| a strikes cell | `kind`; `valid`, how many shapes were candidates; `refused`, a list of `{shape, rows}` Legal's rows turned away; `quotas`, name to how many moves meet it; `moves` |
| a move | `id` (`mv.<fighter>.<stance>.<button>.<nn>`); `limb`, `tip`, `path`, `target`, `weight`; `arms`, an integer; `forms`, `step`, `links`: lists; `sends`; `beat`; `keys`; `ground`; `status`: posed, derived or waiting; `flags`, the pose flags it is known to have; `legal`, the tags on its key set; `asks`, condition ids; `review`: new, accepted, change or rejected |
| `keys` | `level`: posed, hand_state, re_aim, hand_state_re_aim or new. Unless new: `from`, a strike id, and `set`, a key set id; `hand` on a swap; `aim` on a re-aim |

Cross-checks:
- every move is a valid shape, matches no `never` row of its fighter, and no cell holds a shape twice;
- **no move matches a banned row,** with its own `forms`, `arms` and `flags`; no move's steps break s07;
- `sends`, `links`, `step`, `beat`, `forms` and `asks` are what `parts.json` derives for the shape;
- `status` follows `keys.level`; `keys.set` is a row of one of the fighter's manifests and `keys.from` its `combat` id;
- each cell has the count and meets the quotas `cells.json` asks;
- **the files are up to date and clean:** the generator's `--check` passes. This is the check to wire into CI, with `--recipes data/combat/recipes.json` once the patterns are fixed there.

## 6. Before these land

| Who | What |
| :--- | :--- |
| **Animation** | A look at the 13 derived moves, and the 23 new key sets with the conditions listed beside each. A `flags` list on manifest rows for the 12 pose flags; a `tip` and a `path` there would replace my reading in `parts.json` |
| **Encounter** | The sequence rules it holds at run time (s01, s02, s04, s05, s06). The brawl reads a pool for each kind of press (`../recipes.brawl.json`); when these files land the generator writes those pools from the two cells |
| **Combat, in a window** | The two blur patterns in the live recipes |
| **Tools** | The four schemas above, and the generator under `tools/` |
| **Orb** | The accepted sheet |
