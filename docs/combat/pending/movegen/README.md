# Generated movesets: the five stances, both fighters

Owner: Combat and Choreography. Date: 2026-10-06. Status: parked. Nothing here is loaded or hashed, and nothing in the tree is edited. Design: `../../moveset-generator.md`. Built on Animation's real data and with Legal's rows merged; the martial arts stance was regenerated for three strengths on HEAD `972e598` (section 0, and `three-strengths.md`).

| File | What it is | Becomes |
| :--- | :--- | :--- |
| `parts.json` | the grammar: the strike parts, the travel, shot and reading parts the other stances add, and Legal's banned shapes, sequence rules and conditions | `data/combat/parts.json` |
| `identity.json` | how each fighter bends the grammar: weights, "never" rows, entries, energy hands, specials, how strongly to prefer what is posed | `data/combat/identity.json` |
| `cells.json` | Game Design's matrix, all five stances: what each button holds, its count, quotas, readings and what it needs from others; the seed | `data/combat/cells.json` |
| `lock.json` | **generated:** every strike move's id and shape, so an id never changes shape | `data/combat/movesets/lock.json` |
| `gen_moveset.py` | the reference generator: standard library only, no state, no clock | a script under `tools/`, Tools' to hold |
| `moveset.rival.json`, `moveset.protagonist.json` | **generated:** 128 rows each over the five stances | `data/combat/movesets/<fighter>.json` |
| `review-sheet.md` | **generated:** every move on one row, by stance, with Legal's conditions and what each stance needs | stays in docs |
| `three-strengths.md` | the note for the slice C2a: the mediums on 12 ticks, the heavy tier, the burst, the string check, and what Animation, Tools and Legal need | stays in docs |
| `c2t-content.md` | the note for the slice C2t: the launcher, energy in reach, a plan for vicious, and the lists for Animation, VFX, Legal, Tools and Encounter | stays in docs |
| `second-pass-plan.md` | a plan, not built: what the brawl's second pass (`docs/design/brawl-second-pass.md`) needs from parts, identity and cells, in the EP's build order, with sizes | stays in docs |

- **To generate:** `python docs/combat/pending/movegen/gen_moveset.py`. It refuses to write if anything matches one of Legal's rows.
- **To check:** add `--check`: exit 1 when the files are not what the inputs give, on any match with Legal's rows, or when a string runs out of blows (a strike button left with fewer than 3 pieces after some two blows, or a light that cannot open a burst). It passes now, and a second run changes nothing.
- **To prove the refusals:** `--self-test`, 88 cases.
- **To start a cell over:** `--relock` ignores the lock. Without it, locked moves stay and only free places are filled.
- **The seed** is 20261004, in `cells.json`.

## 0. Three strengths (2026-10-06, for the slice C2a)

Orb moved the martial face buttons to three strengths: X light, Y medium, B heavy, and a burst on a held X (`docs/design/brawl-second-pass.md`). The note is `three-strengths.md`; in short:

| Cell | What it holds now | The rival: rows, posed, derived, waiting | The Protagonist |
| :--- | :--- | :--- | :--- |
| X | the same 30 lights | 30: 27, 3, 0 | 30: 24, 6, 0 |
| X held | the burst: 5 strings of 8 lights, one for each lean | 5: 1, 4, 0 | 5: 0, 5, 0 |
| Y | the same 16 strikes, re-tagged as mediums; 12 and 11 read on a 12-tick wind-up, the rest are flagged for a held Y | 16: 14, 2, 0 | 16: 14, 2, 0 |
| B | a new tier of 10 heavies: whole-body blows, each a shape and a drive | 10: 0, 0, 10 | 10: 0, 0, 10 |
| B, stand-ins | posed pieces that can play on B until the tier is drawn; not locked | 5: 0, 5, 0 | 5: 0, 5, 0 |

- **For the slice C2t** (`c2t-content.md`): a heavy that reads on half of B's wind-up and lands on the trunk or the head carries the form `launch` (rival 8, Protagonist 7); a heavy whose place is an arm or a leg carries the form `wrench` (one of each a fighter; the rival's rows 09 and 10 were re-aimed for it, by Game Design's ruling), and each fighter has 6 energy pieces in reach, 4 point-blank bolts and 2 blasts, in the cells `energy.x.reach` and `energy.y.reach`. Rows are 128 a fighter with two sample runs of mashed bolts ordered by Legal's e09: rival 74 posed, 25 derived, 29 waiting; Protagonist 69, 30, 29.
- No id changed and no strike changed shape. The lock's 34 heavy rows were re-tagged as medium.
- The signature frame that sat on the martial B is the charging stance's B (RT + B) now.
- Sections 1 and 2 below were written before this: where they say heavy for the martial Y, read medium.
- `second-pass-plan.md` was written for two strengths. Its B section, the charged light and the quick heavy are withdrawn; the cell addressing, the pairs, the tackle and the `pair` kind stand.

## 0b. The nine cells (2026-10-12)

Animation posed the ten heavies of each tier (rows 09 and 10 are provisional, and in its working tree only on this date) and the energy pieces in reach, and the generator (version 13) reads its four packs: `rival7` and `protag10` through `tierWaves` in `identity.json`, `rival8` and `protag11` through `energyWaves` and the rules of `energy.reach.posed`. The note is `../nine-cells.md`.

| Cell | The rival: rows, posed, derived, waiting | The Protagonist |
| :--- | :--- | :--- |
| B | 10: 10, 0, 0 | 10: 10, 0, 0 |
| B, stand-ins (now B's fallback) | 5: 0, 5, 0 | 5: 0, 5, 0 |
| RB + X in reach | 4: 4, 0, 0 | 4: 4, 0, 0 |
| RB + X mashed: two loops of twenty | 2: 0, 2, 0 | 2: 0, 2, 0 |
| RB + Y in reach | 2: 2, 0, 0 | 2: 2, 0, 0 |
| All five stances | 128: 90, 23, 15 | 128: 85, 28, 15 |

- The table of section 0 is superseded for B.
- A run of mashed bolts is a loop: the generator checks the join, so it keeps Legal's e09 however long it is played (`cells.json`, `loop`).
- `--check` also tests the hand-kept data: each energy key set named in `identity.json` is a row of its pack, on the rule's path and place.
- The energy ids are Animation's. A rule may carry `strikeNow` while a rename is on its way; none does now.
- **Version 14 (2026-10-12, later):** Legal's e06 counts the delivery, so a blast after a bolt of the same hand is not a repeat. Legal's file now also holds groups no move is made of (`world`, `withdrawn`, `public`). `parts.json` `legal.mirrored` names the groups that are copied and compared, and `--check` names the others on its Legal line with their row counts, so a new group is seen.

## 0c. The sharing rule, and rows for fighters who are not in the build (2026-10-12, version 15)

The note is `../../roster-rows.md`; the rows and their generated files are in `../roster/`.

- **`share` on a cell** (`cells.json`, the heavy cell): `own` by tier and `maxWithOne`. A fighter has so many pieces that are his alone, shares no more than that part of the cell with any one other fighter, and leaves the fighter he borrows from his own share. `--check` fails when a cell breaks it.
- **In a fighter's identity:** `tier` (1 when it is not said); `borrows`, the packs that are another fighter's; `alt`, a word shared by rows that are options for one place in the roster; `borrowIds`, a list of strike ids, the only ones he reads from a pack he borrows.
- **A quota may ask for a form and a send together.** The heavy cell has one for a launcher that sends each way, filled first.
- **The search for a mashed run of bolts** goes on to another order of pieces when the first has no arms that keep Legal's e09. The two fighters' runs are as before.
- **The two fighters' files** changed by their inputs line and by the counts of the heavy cell's quotas. No move changed, and `../recipes.brawl.json` is byte for byte the same.
- **The data scripts' order** is now `merge_legal2.py`, `three_strengths_data.py`, `c2t_data.py`, `nine_cells_data.py`, `share_data.py`.

## 0d. A fighter's own, the floors and the gate on blows (2026-10-12, version 16)

Game Design's borrowing policy (`docs/design/fighter-pipeline.md` section 1). The note is `../../roster-rows.md`.

- **`own` on a move:** it is his own piece. It is of a pack of his own and not a common piece (one that more than one fighter has posed), or it is a new shape nobody else holds. A blow that is another fighter's own is no candidate for a new one of his, at any strength.
- **`share` on the light and medium cells** beside the heavy's: his own, at least, by tier (3 and 2 at tier 1; 5 and 3 at tier 2). The light cell also has a quota for three of his own that fit the flurry.
- **`gate` in `cells.json`:** the measured mix of blows by cell, which generated moves each cell draws on, a quarter and a fifth, and `ownWeight` (1: today's even draw). `--check` prints a fourth line, `own blows`, and fails when a fighter is under a fifth. It is never a reason to refuse to write.
- **`waives` in a fighter's identity:** a floor Game Design has let him off (`wrench.legs`, for the Bell). **`armsOf`:** how many arms a key set uses, where its pack is stale (Legal's RL-133).
- **Legal's b14 and s09 are merged** (a leap by hand, elbow or head; the stomp). Its `signature` group is not mirrored: no generated move is made of it.
- **The two fighters' files** gained the `own` mark and the counts of the new quotas. No move changed; the Protagonist's falling palm lost "(both arms)" from its name. `../recipes.brawl.json` is byte for byte the same.
- **The data scripts' order** now ends `share_data.py`, `rl133_data.py`.

## 0e. The split by path, places added to a cell, and kit rows (2026-10-15, version 17)

The EP's brief of 2026-10-15. The note is `../../split-and-pieces.md`.

- **The split as quotas** in `cells.json` (`_quotasSplit`). Y: the stop (a quick medium on a line or a rise) and the grind (a quick one that drops or arcs), at least 5 each. B: the advance (a line or a drop) and the big read (an arc, a rise or a spin), at least 5 each. A quota may now name a form and a shape together.
- **`adds` in a fighter's identity:** places added to a cell whose locked moves leave a group short. The Protagonist +1 medium and +1 heavy, the Anti-hero +1 heavy; the quotas fill them. A roster sketch never inherits them.
- **One pick meets as many short quotas as it can,** in strike cells. Without it, the Protagonist's added medium went to an older quota first. The energy tables keep the old rule, so their picks stay as they were.
- **`chargedHeavy` in a fighter's identity:** his charged heavy as Game Design names it. The pool builder keeps it in the held B's pool; the generator doesn't read it.
- **A kit row** (`kit` in an identity row: the Empress's guards). It has only the cells its kit names, with its counts and any quotas of its own. It draws only on posed common pieces, or a new shape of a weight the kit allows. It is never another fighter's own blow. It has no share rule and no floors, is outside the gate, is never counted when the common pieces are found, and only its lights and mediums are read for the string rules.
- **The two fighters' files** gained the three added moves and the new quotas' counts. No move changed, and `../recipes.brawl.json` is byte for byte the same.

## 0g. Animation's eighth pieces read as posed (2026-10-16, version 19)

The note is `../../split-and-pieces.md` section 5c.

- **A pack may mix lights with its heavies.** In a pack of the tier only the heavy rows are tier heavies. The fighters now list protag12 and rival9 among their packs and their tier packs.
- **`ownPacks` in a kit:** packs drawn for that kit alone, the guards' rival10. The guard row names Animation's `bm.guard_bolt` as his bolt.
- **A pack the tree doesn't have yet reads as empty,** and `--check` names it. The files are made against Animation's fourth patch; until it lands, the check on main says "out of date".
- **The Anti-hero's three straight fists** (two more places, his row's quota) are pinned in his skill pool. Legal's e10 is mirrored.

## 0f. A fighter's named pieces, and the burst's lean (2026-10-16, version 18)

The note is `../../split-and-pieces.md` section 5b.

- **`cellQuotas` in a fighter's row:** quotas of his own for a cell, read before the cell's. With `adds` they generate the pieces Game Design names. The Protagonist's second falling launcher is by an open or bladed hand; his turning palm-heel goes to the body; the Anti-hero's straight fist. A launcher's quota may now name a shape as well as a send.
- **`burst.favour`:** a filter and a factor. The burst's strings lean toward it, and the pool builder's `--lean` keeps only those hands in the fast and mid classes, when at least `min` are posed.
- **`skillAlso`:** a move pinned into the skill strike's pool, whatever its form, once it is posed.
- **Never lent, everywhere.** A fighter's own blow is no candidate for another fighter even when he hasn't been built yet in this run: his current file's own marks are read.
- **The roster builder** keeps a fighter's named pieces (`adds`, `cellQuotas`, `chargedHeavy`, `skillAlso`) out of the sketches built like him.

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
| **Manoeuvre** | X: zip strike, step strike, light charge, zip away | a kind, a direction, a posed entry, a way out, and a light from his martial X whose path suits the direction | 8: 7, 1, 0 | 8: 7, 1, 0 |
| | Y: zip heavy, heavy on the move, heavy charge, pursuit | the same with a heavy from his martial Y | 8: 6, 2, 0 | 8: 6, 2, 0 |
| **Energy arts** | X: bolts | a hand of his own, a release, what his body does, and the delivery: a bolt (speed, tech) or a volley of three (heavy) | 6: 6, 0, 0 | 6: 5, 1, 0 |
| | Y: the heavy shot | the same; the delivery is a shot, a charged shot, a short beam, or for the rival a split | 6: 5, 0, 1 | 6: 4, 1, 1 |
| **Defensive** | X: the check | a short light from the strike grammar (a line, a rise or an inward arc, by hand, elbow or knee), thrown over the guard | 6: 5, 1, 0 | 6: 5, 1, 0 |
| | Y: the push | a shape on a line to the chest or gut: a palm, the shoulder, both forearms, or the boot. No leaping key set | 6: 3, 3, 0 | 6: 4, 2, 0 |
| **Charging** | X, Y, A: his three specials | each special is a frame of his own; the generator makes its looks | 14 looks, all waiting | 14 looks, all waiting |

- **Every A cell is a list, not generated:** the pressed and held actions of the matrix.
- **Every B cell but the martial one is a generic frame** with its readings (the martial B is a strike cell since the three strengths). The kinds are not final, and the defensive and manoeuvre signatures will differ for each fighter (Orb), so nothing is hand-picked.
- **Quotas:** each zip direction and each step direction appears; the energy cells hold moves for all three readings; the checks cover the high and the mid line and include 2 by elbow or knee. All are met.
- **Identity shows without new rules.** The rival's zips go in on a dash and land plates and lines; the Protagonist's go in on a spiral or an arc dive and land arcs. The rival pushes with the shoulder, the forearms and the boot, since he has no palm strike; the Protagonist pushes with palms.
- **The Protagonist's three specials are placeholders** (a turning step, three curving shots, a turn aside). They are Combat's first offer so that his charging row is not empty, and they are marked so in the data and on the sheet.
- **Which of the rival's specials sits on which button is my guess:** the cutting step on X, the barrage volley on Y, the grip and drag on A.

**All five stances:** 128 rows a fighter: the rival 74 posed, 25 derived, 29 waiting; the Protagonist 69, 30, 29. The 29 waiting are the 10 new heavies, the 14 special looks, the short beam, two new releases of the point-blank bolt and the two sample runs that use them.

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

`parts.json` holds Legal's file whole (`docs/legal/movegen-banned.json`, through its screen of the three strengths, `bb6fc1e`), and `--check` fails if any row there is missing from it or differs. The merge takes every group of rows in Legal's file, whatever its name, so a new group no longer needs a change here.

| Rows | Judge | What the generator does |
| :--- | :--- | :--- |
| The 13 shape rows (b01 to b13) and 7 sequence rules (s01 to s07) | **strike pieces only:** the martial cells, the checks, the pushes, and the blow of every zip, step and charge | refuses a match; no move matches |
| Energy, e01 to e05 | energy pieces. **b09 is not applied to them:** a lit fist is allowed where the light sits on the plate and knuckle edges, never as a ball at the hand (e01) | refuses a match, from the hand table in `parts.json` (`shot.hands`: shape, where the light sits, one hand, shoulder height) and the move's delivery and release |
| Motion, m01 to m08 | zips and their marks | refuses a far-side zip that does not leave over the rival or round him (m04); the rest are how a zip is drawn and timed: conditions for Animation, VFX and Simulation |
| Grabs, g01 to g03 | grabs | no grab is generated; the hold points a grab may use are listed and checked (g01) |
| Held, h01 to h03 with `heldScope` (RL-087), and stacking, k01 and k02 | any pose held 12 ticks or more, by its class (the pair test on every held pose; the emitter test on charges, tells, signatures, energy poses and a held heavy's hold); every tick of a tell or a charge | not checkable from parts: conditions H1 and K1 on every signature frame and held action, for Animation's lint and VFX. `heldScope` is copied whole into `parts.json` `legal`, and `--check` compares it |

**The screen of the launcher and energy in reach** (`docs/legal/launcher-and-reach-screen.md`, `e9a57791`): all 17 rows pass. e06 names the rival's lit fist as a third hand, R1 is e08, k05 is a flash ceiling for VFX, and s08 applies s02 by place inside a hold (an arm is three places), which the string rules now do for any blow that carries a place. Details in `c2t-content.md`.

**The screen of the three strengths** (`docs/legal/three-strengths-screen.md`): all 41 of Combat's rows passed with conditions. b03 and b12 changed, h05 to h07, f04 and f05 are new, and f01 is restated. What the generator does with each, and the conditions carried into the sheet (W1, U1, D1 to D5, B1), are in `three-strengths.md` section 8. `--check` also tests the pools by button in `../recipes.brawl.json` (the burst's pools, its samples, and that every pool named exists).

**RL-098 to RL-101, for the brawl's second pass** (`docs/legal/brawl-screen.md`). None of these moves is generated yet, so the new rows refuse nothing today. The plan for them is `second-pass-plan.md`.

| Rows | What the generator does |
| :--- | :--- |
| Flurry, f01 to f03 (a new group) | **f02 is checked:** `string_breaks` judges s01 and s02 on a whole string, whatever mix of buttons made it. f01 (the blur) and f03 (voice) are conditions for VFX and Audio |
| Energy, e06 and e07 | **e06 is checked:** a burst, a blast or a flurry on B is refused from any hand that is not one open or blade hand at the shoulder or lower, and a string is refused if it throws the same hand, release and body twice running. e07 (a steered beam) is how it is drawn |
| Grabs, g04 and g05 | **checked:** the hold points of a tackle (waist, shoulders) and of a clinch (collar, elbow, waist) are listed in `grab.kinds` and compared with the rows |
| Motion, m09 to m11; held, h04; stacking, k03 and k04 | conditions for their owners: how a zip chain, a chase, a slip, a charge pose and a flash are drawn and timed |

- **A fault of mine, fixed.** My merge script wrote the far-side zip's pivot row again at each re-merge, so `parts.json` at `a9df651` listed it three times. No move was ever picked differently for it: only the candidate counts of the manoeuvre cells were too high (the rival's X showed 252 and has 214). The script now drops a repeated row, and the generator refuses to run on a table that lists a move twice.
- **What the RL-081 to RL-087 rows refuse today: nothing.** Legal reworded e05 on 2026-10-06: a volley is one motion of one hand or arm (a sweep, a flick or a single thrust), never both palms pumping in turn or one hand pumping repeatedly. So a volley on a single thrust is allowed again, and the generator refuses a pumped volley or one from two hands, neither of which the grammar can produce.
- **One change to my own grammar,** to fit m04: a zip to the far side leaves on a pivot round the rival or an arc dive over him. It had left on a lane step.
- **Counts:** still 100 moves a fighter. No cell lost a move.
- **Still needs Legal's eye when drawn** (Legal's own list): the short beam and its braced pose; each fighter's counter and terrain art when designed; the specials when designed.

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

**Added for Legal's new rows (2026-10-06)**
- `parts.json` `legal`: `applies`, a note; and the groups `motion`, `energy`, `grabs`, `held`, `stacking`, each a list of `{id, kind, rule, why}`. By `kind`: travel and move have `if` and `then` (filters), and a move row may have `hand` with a `need`; hand has `never` and optionally `need` (a hand property to a list of values); holdPoints has `never` (a list); numbers has `owner` and `check`; drawn has `owner`.
- `parts.json` `shot.hands`: a hand to `{shape, light, hands, height}`. `parts.json` `grab.holdPoints`: a list.
- `travel` has the direction `far_side`.
- `cells.json`: a frame or context cell may have `asks`, a list of condition ids.
- A moveset's travel and table cells have `refused`: for travel `{move: {kind, direction, exit}, rows}`; for a table `{move: {delivery, release}, rows, candidates}`. Frame and context cells carry `asks`.
- `parts.json` `legal` may also hold a block that is not rows, copied from Legal's file as it stands (`heldScope`: `classes`, `pairTest`, `emitterTest`).
- Added with the three strengths (the full list is in `three-strengths.md` section 7): a weight may be `medium`; `parts.json` `strike` gains `weights`, `animWeight`, `legalWeight`, `legalForm`, `windup`, `heavy` and `burst`; a cell may hold `presses` and `standIn`, and may be of the kind `string`; a medium move has `wind`, a heavy has `drive` and `name`; an id may have a third part (`mv.rival.martial.x.hold.01`).
- Added with RL-098 to RL-101: `parts.json` `legal` takes any group of rows Legal adds (`flurry` is the first new one); a row's `kind` may be `string` (`uses`: the sequence rules it widens, `ignores`); a `holdPoints` row may name a `grab` and its `allowed` points, matched against `grab.kinds`; a `move` row may carry `string` (`same`, `max`).
- Cross-checks: every energy hand a fighter lists is in `shot.hands`; every row of Legal's file is in `parts.json` with the same rule and why; no hold point is one of g01's.

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
