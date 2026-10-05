# Generated movesets: the five stances, both fighters

Owner: Combat and Choreography. Date: 2026-10-05. Status: parked. Nothing here is loaded or hashed, and nothing in the tree is edited. Design: `../../moveset-generator.md`. Built on HEAD `d309a54`, on Animation's real data and with Legal's rows merged.

| File | What it is | Becomes |
| :--- | :--- | :--- |
| `parts.json` | the grammar: the strike parts, the travel, shot and reading parts the other stances add, and Legal's banned shapes, sequence rules and conditions | `data/combat/parts.json` |
| `identity.json` | how each fighter bends the grammar: weights, "never" rows, entries, energy hands, specials, how strongly to prefer what is posed | `data/combat/identity.json` |
| `cells.json` | Game Design's matrix, all five stances: what each button holds, its count, quotas, readings and what it needs from others; the seed | `data/combat/cells.json` |
| `lock.json` | **generated:** every strike move's id and shape, so an id never changes shape | `data/combat/movesets/lock.json` |
| `gen_moveset.py` | the reference generator: standard library only, no state, no clock | a script under `tools/`, Tools' to hold |
| `moveset.rival.json`, `moveset.protagonist.json` | **generated:** 100 moves each over the five stances | `data/combat/movesets/<fighter>.json` |
| `review-sheet.md` | **generated:** every move on one row, by stance, with Legal's conditions and what each stance needs | stays in docs |

- **To generate:** `python docs/combat/pending/movegen/gen_moveset.py`. It refuses to write if anything matches one of Legal's rows.
- **To check:** add `--check`: exit 1 when the files are not what the inputs give, or on any match with Legal's rows. It passes now, and a second run changes nothing.
- **To prove the refusals:** `--self-test`, 17 cases.
- **To start a cell over:** `--relock` ignores the lock. Without it, locked moves stay and only free places are filled.
- **The seed** is 20261004, in `cells.json`.

## 1. The martial arts stance, regenerated on Animation's data

The generator no longer uses my reading of each strike. It reads the tip, the path and the pose flags from Animation's manifests, and how far a key set can be re-aimed from `data/anim/tips.json`. My strike table and my guessed neighbour table are gone from `parts.json`.

| Fighter | Cell | Before: posed, derived, waiting | Now |
| :--- | :--- | :--- | :--- |
| The rival | X, 30 lights | 14, 3, 13 | **27, 3, 0** |
| The rival | Y, 16 heavies | 12, 2, 2 | **14, 2, 0** |
| The Protagonist | X, 30 lights | 16, 6, 8 | **24, 6, 0** |
| The Protagonist | Y, 16 heavies | 14, 2, 0 | **14, 2, 0** |

- **No move waits for a key set.** Animation's 23 new key sets (`rival4`, `protag7`) match the 23 waiting shapes one for one.
- **All 92 moves kept their ids and shapes,** through the new lock. Nothing was dropped and nothing was refused.
- **Two moves were read again,** one a fighter: the crossed-arm ram (rival Y 12, Protagonist Y 13). I had read it as an elbow arcing in; Animation reads both forearms as a wedge on a line. The key set and the id are the same; it now sends across and not turned, and every quota is still met.
- **Derived moves: still 13.** The rival has 3 re-aims and 2 closed hands; the Protagonist has 8 re-aims. Animation measured 10 of the 11 re-aims as ok; one, the rival's backfist to the jaw (X 20), lands at the edge and needs a look.
- **The fighters share 20 of 46 shapes, 43%,** as before.
- **Animation's pose flags changed no move.** The only flagged key sets are the drop kick (a leap) and the body ram (a leap and a turn), and no banned row matches them. A key set Animation has measured with no flag now counts as cleared of the twelve flags, so those rows no longer show as conditions for posed moves.

## 2. The other four stances

Game Design's matrix (`docs/design/melee-press-feel.md` section 10): X quick, Y strong, A the context action with a press and a hold, B the signature; X, Y and B each read speed, tech and heavy. Moves, then posed, derived and waiting:

| Stance | Cell | How it is made | The rival | The Protagonist |
| :--- | :--- | :--- | :--- | :--- |
| **Manoeuvre** | X: zip strike, step strike, light charge, zip away | a kind, a direction, a posed entry, a way out, and a light from his martial X whose path suits the direction | 8: 6, 2, 0 | 8: 7, 1, 0 |
| | Y: zip heavy, heavy on the move, heavy charge, pursuit | the same with a heavy from his martial Y | 8: 6, 2, 0 | 8: 6, 2, 0 |
| **Energy arts** | X: bolts | a hand of his own, a release, what his body does, and the delivery: a bolt (speed, tech) or a volley of three (heavy) | 6: 6, 0, 0 | 6: 5, 1, 0 |
| | Y: the heavy shot | the same; the delivery is a shot, a charged shot, a short beam, or for the rival a split | 6: 5, 0, 1 | 6: 4, 1, 1 |
| **Defensive** | X: the check | a short light from the strike grammar (a line, a rise or an inward arc, by hand, elbow or knee), thrown over the guard | 6: 5, 1, 0 | 6: 5, 1, 0 |
| | Y: the push | a shape on a line to the chest or gut: a palm, the shoulder, both forearms, or the boot. No leaping key set | 6: 3, 3, 0 | 6: 4, 2, 0 |
| **Charging** | X, Y, A: his three specials | each special is a frame of his own; the generator makes its looks | 14 looks, all waiting | 14 looks, all waiting |

- **Every A cell is a list, not generated:** the pressed and held actions of the matrix.
- **Every B cell is a generic frame** with its three readings. The kinds are not final, and the defensive and manoeuvre signatures will differ for each fighter (Orb), so nothing is hand-picked.
- **Quotas:** each zip direction and each step direction appears; the energy cells hold moves for all three readings; the checks cover the high and the mid line and include 2 by elbow or knee. All are met.
- **Identity shows without new rules.** The rival's zips go in on a dash and land plates and lines; the Protagonist's go in on a spiral or an arc dive and land arcs. The rival pushes with the shoulder, the forearms and the boot, since he has no palm strike; the Protagonist pushes with palms.
- **The Protagonist's three specials are placeholders** (a turning step, three curving shots, a turn aside). They are Combat's first offer so that his charging row is not empty, and they are marked so in the data and on the sheet.
- **Which of the rival's specials sits on which button is my guess:** the cutting step on X, the barrage volley on Y, the grip and drag on A.

**All five stances:** 100 moves a fighter. The rival: 72 posed, 13 derived, 15 waiting. The Protagonist: 69, 16, 15. The 15 waiting are the 14 special looks and the short beam.

"Posed" here means the poses exist. Most of what these four stances lack is not a pose but the action itself, which is the next section.

## 3. What does not exist yet

By team. The sheet lists the same under each stance, cell by cell, and `cells.json` holds it as `needs`.

| For | What |
| :--- | :--- |
| **Simulation** | *Manoeuvre:* the zip as a move (in, the blow, out; its ki; the floor on its travel ticks; where it ends by the stick); the step strike and its slip; the zip heavy, the heavy on the move, the pursuit; the snatch on the fly and the zip tackle. *Energy:* the volley as one press; the short beam as a shot kind; the split for the rival; the aimed mine and the long shove. *Defensive:* the check, the parry and the guard strike; the push, the short shove and the stuff; the guard throw and the aimed deflect. *Charging:* a special's charged cut and its mark. *Martial:* the held context level, the aimed throw, the grab lockout |
| **Animation** | *Manoeuvre:* the dash, the fade and the lane step played at zip speed and drawn the whole way; a pass to the far side; the snatch. *Energy:* a braced pose for the short beam; the split's second release; an aimed lob of a mine; the Protagonist's flat palm as an energy hand. *Defensive:* the guard layer a check is thrown over; a push as a strike key set with no impact snap; the guard throw. *Charging:* each special's cuts (none is posed as a whole). *Martial:* a second look for each grab and throw |
| **VFX** | The zip's blur in each reading; each fighter's bolt, short beam and split in his own family, with no ball in the palm; the parry's mark |
| **Game Design** | Which special sits on which button; the Protagonist's specials; the signature kinds |
| **Encounter** | The run-time picks for the new cells, and the sequence rules on the strings presses make |

## 4. Legal

- **Applied automatically** to every strike on the sheet: the martial cells, the checks, the pushes, and the blow of every zip, step and charge. No move matches a banned row, and `--check` proves it.
- **Conditions** are on the sheet as before, with four more for the new stances: Z1 (a zip is drawn the whole way), G1 (grabs), E1 (energy hands), P1 (pushes).
- **Needs Legal's person screen,** because the rows only know the martial vocabulary:
  - the five signature frames, and each fighter's version of the counter and the terrain art when they are designed;
  - the travel kinds and their directions (the zip was screened as a rule, RL-076; the moves were not);
  - the energy hands, releases and deliveries, the push and the guard layer;
  - every special's frame, and the Protagonist's three placeholders;
  - the new grabs: the aimed throw, the guard throw, the zip tackle, the snatch.

## 5. Keys for Tools

What changed since the keys I gave for the martial stance. A filter is as before; keys starting `_` are notes.

**`combat-parts.schema.json`**
- Gone: `strikes` (the posed strikes are read from the manifests) and `strike.reaim.neighbours`.
- `strike.reaim`: `source`, a path; `levels`, `ok` and `edge` to a level name.
- `strike.tips.elbow.plate` is new vocabulary; `strike.swap` now includes `heel`.
- `strike.conditions`: a row has `when` or, for a stance-wide one, `stance`.
- `travel`: `kinds`, a kind to `{band, what, moves}`, a move being `{direction, entries, exit}`; `arrive`, a direction to a list of paths.
- `shot`: `release`, `body`: lists; `rules`, a list of `{if: filter, then: filter, why}`; `forms`, a list of `{form, when: filter}`.
- `readings`: a stance to a reading to a list of forms.

**`combat-identity.schema.json`**
- `entryWaves`, a list of wave names; `weights.entry`, an entry name to a number.
- `reuse` gains `re_aim_edge` and `hand_state_re_aim_edge`.
- `energy`: `hands`, a hand to a weight; `posedHands`, a hand to a pose id; `release`, a release to a weight; `split`, a boolean; `posed`, a list of `{when: filter, set}`.
- `specials`: `x`, `y`, `a`, each `{id, what, status, parts, rules}`; `parts` is a part name to a list of values, `rules` as in `shot`.

**`combat-cells.schema.json`**
- A strikes cell may have `layer`, `as`, `anyWeight`, `notFlags` (a list of flags) and `readings` (a list).
- New kinds: travel (`blows`, a cell id; `kinds`; `count`; `readings`; `quotas`), table (`block`; `delivery`; `count`; `quotas`), special (`slot`; `count`; `readings`).
- A context cell has `pressed` and `held`, lists. A frame cell may have `readings`, a reading to a sentence, and `legal`.
- Any cell may have `needs`, a list of `{who, what}`.

**`combat-moveset.schema.json`**
- A strikes cell no longer differs between runs: it has `kind`, `valid`, `refused`, `quotas`, `moves`. A move's `keys.level` gains `re_aim_edge` and `hand_state_re_aim_edge`; `keys` may have `wave` and `layer`; a move may have `as`; `review` is `locked`.
- A travel move: `id`, `kind`, `band`, `direction`, `entry` and `exit` (`{id, set}`, or null for no way out), `blow` (`move`, the parts, `set`), `forms`, `status`, `flags`, `legal`, `asks`, `review`.
- A table move: `id`, `hand`, `release`, `body`, `delivery`, `forms`, `keys` (`set`, `hand`), `status`, `asks`, `review`.
- A special cell: `special`, `what`, `state`, and moves of `id`, `look` (a part to a value), `forms`, `status`.

**`combat-moveset-lock.schema.json`** (`combat.moveset.lock/1`): `fighters`, a fighter to a cell id to a list of `[id, [limb, tip, path, target, weight], key set id or null]`.

Cross-checks, added to the earlier ones:
- every id in `lock.json` is in its fighter's moveset with the same shape, and every strike move is in the lock;
- a travel move's `blow.move` is a move of the cell named in `blows`, its path is in `travel.arrive` for its direction, and its entry and exit are rows of the fighter's entry manifests;
- a table move breaks no rule of its block;
- `--check` passes. With `--recipes data/combat/recipes.json` it also tests the live blur patterns.

## 6. Before these land

| Who | What |
| :--- | :--- |
| **Legal** | The person screen of section 4 |
| **Animation** | A look at the one re-aim at the edge (rival X 20) and at the derived moves of the new cells; the list in section 3 |
| **Game Design** | Section 3's three questions; the rival's special on each button |
| **Tools** | Section 5 |
| **Orb** | The sheet |
