# Fighters as data: what the core assumes today, and the windows to four fighters

Owner: Simulation and Engine. 2026-10-12. **Window 1 is built (section 2). Windows 2 and 3 are built in scratch and parked in `pending/fighters-w23/` (sections 3 and 5). Window 4 is paper.** It answers the five questions Game Design's `docs/design/fighter-pipeline.md` puts to Simulation and Tools. Line numbers are HEAD's (f4e57e63).

## In short

| Question | Answer |
| :--- | :--- |
| Can `wounds.json` and `ladder.json` each become one shared file, with a fighter's differences beside it? | **Yes, and the goldens need not move at all.** The two fighters' copies are identical today, value for value. The data hash is taken over what a fighter resolves to, so it stays the same to the bit |
| Does a new fighter folder and roster entry leave every existing golden unchanged? | **Every match, replay and checkpoint: yes.** A fighter added to the roster moves one recorded vector, the roster's data hash. **A fighter added to the bench moves nothing:** window 2 puts the reference fighter there, outside the roster, and he is hashed into a replay only when it names him |
| What assumes two fighters, or these two ids? | **The sim's rules name no id.** A match has exactly two fighters, and that stays. The ids are named only in my check and batch tools, and in other owners' data (section 4) |
| What does a match setup need to name any two of N? | **Nothing new:** `{"slots": [id, id]}` has been there since D1a, and a replay records it. Window 3 adds two guards (section 5) |
| What does `care` switched on do? | It moves where launches go, where the AI leads a fight and which way it leans in a brawl: three reads, all Encounter's. It is in the state hash, so every golden match moves from tick 0. **It is a re-baseline, once,** as Game Design says: one regeneration, and QA's bands read before and after |

## 1. What is there today

- `data/fighters/roster.json` is `["PROTAGONIST", "RIVAL"]`. Each id has a folder with four files: `fighter.json`, `wounds.json`, `ladder.json` and `meters.json`.
- `FighterData` (`sim/core/fighter_data.gd`) loads the roster once a process, checks every value, and gives each fighter one read-only record. A match copies a few numbers from it and points at the rest.
- **What differs between the two.** `fighter.json`: role, three colours, `dmgMul` (0.95 and 1.02), `spd` (1.0 and 0.95) and the finisher's key. `meters.json`: one has anguish and the other menace. **`wounds.json` (7.3 KB) and `ladder.json` (2.9 KB) do not differ in any value.**
- The data hash folds, in order: the roster, then for each id his four files under their names. A `_` key is skipped, so a note is free to change.

## 2. One wounds file and one ladder file (built, 2026-10-12)

**The layout.**

| File | What it holds |
| :--- | :--- |
| `data/fight/wounds.json` | The wounds model, whole: today's file |
| `data/fight/ladder.json` | The ladder, whole: today's file |
| `data/fighters/<id>/wounds.json`, `ladder.json` | **Optional.** Only what differs for him. Absent for both fighters today |

**Absent, and not an empty file.** A new fighter's folder then needs `fighter.json`, and `meters.json` if he has a meter. A wounds or ladder file appears in his folder only when he differs, so its being there says so. An empty file in every folder would say nothing, and would invite a full copy back.

**Where a tune goes now.** One edit each, in the game's files:

| What | Path |
| :--- | :--- |
| Wear for a point of damage | `data/fight/wounds.json`, `wearPerDamage` |
| The wait before the second breath | `data/fight/wounds.json`, `fade.breathAfterTicks` |
| Where a light lands | `data/fight/wounds.json`, `family.light` |
| The crippling roll's base | `data/fight/wounds.json`, `cripple.base` |
| The ladder's two rates | `data/fight/ladder.json`, `takenPerDamage` and `dealtPerDamage` |

- `data/fight/` is where the fight's own numbers live (the mood, the pauses, the shots), and Game Design's line puts the wounds model there: it is the game's.
- **The merge rule.** A fighter's file is laid over the shared one key by key. A dictionary is merged; a number, a word or a list replaces the shared one whole. A key the shared file does not have is refused, so a slip of spelling cannot hide. A `_` key is a note.
- **The hash is taken over what he resolves to,** under the names it uses today. With no differences, each fighter resolves to exactly today's file, so the roster's hash is the same to the bit and `golden.json` does not change by a byte.
- A tune of the game's wounds is then one edit. A fighter's own wound profile, at his tier 2, is a short file of his own.

**As built.** `FighterData` reads the game's two files once (`_load`), resolves each fighter (`_resolve`: his own file laid over the game's by `_over`, or the game's alone) and folds what he resolves to into the data hash under his own file's name. A test may point it at other folders (`loadFrom(dir, sharedDir)`); with no game's file a fighter's own file is the whole, as it was.

**Proof,** on a clean export of bc74150c. Parity against the committed golden, unregenerated: 52 of 52. The golden regenerated: byte-identical. The 30-match batch: the same digest before and after (`4d3ea14fa90475d9`), and the same report but for its timing line. The new check, "the game's wounds and ladder files, and a fighter's differences": no file of his own gives the game's, and the same hash; a full copy in each folder hashes the same again; his own file with one number, one nested number and one list changes those for him and nothing else, for nobody else; a misspelt key is refused, at the top and inside; with no game's file a fighter needs his own.

**Tools' part** is Tools' own (`tools/lib/shared.js`): the full schemas on the two shared files, a fighter's file with nothing required, the merged result checked, and its fixtures split the same way. The loader's rule and the validator's are written to be the same rule.

## 3. Adding a fighter: what moves, and the bench (window 2, built in scratch)

- **No match moves.** A match reads only the two fighters in it.
- **A fighter added to the roster moves the roster's hash,** because it is one hash over everyone: the `rosterHash` vector in the golden, and a part of every replay's data hash. He also joins what reads the roster as the list to cover: Tools' flash tools and Legal's list of pairings take one entry for every pair in `roster.json`.
- **So the reference fighter is not in the roster. He is on the bench:** `data/fighters/bench.json`, a list beside the roster. A bench fighter loads as any other and can be named in a match's slots. He is not on the select screen, not in the roster's hash, and not in the pairings.
- **A hash a fighter.** The loader keeps the hash of what each fighter resolves to (`FighterData.hashOf`). A replay's data hash is what it was, and a bench fighter's hash is folded in only when the replay's slots name him. So his data can change without turning away a replay of the roster's fighters, and a replay of his own is refused when they do.
- **No golden moves in window 2:** the roster file, its order and its hash are untouched.
- Moving him into the roster later, if Orb wants him on the select screen, is one line in each of the two lists, and then the roster's hash moves once.
- **The roster's own fighters still share one hash.** The Cyborg will move it when he joins, and with it every stored replay. Making the roster's hash one a fighter as well changes the golden's replay line, so it rides with a window that regenerates anyway.

**The reference fighter, as built.** `data/fighters/REFERENCE/fighter.json`: damage 1.0, speed 1.0, care 0, no meter file, no wounds or ladder file of his own, so the game's. Three values are provisional until Game Design rules: his role word (`reference`, which the loader now accepts), his Rally rule (`second_wind`, as the two in the build have) and his finisher (`generic`, which belongs to nobody).

**Proof,** on a clean export of 89b3e2f8, which has window 1: parity against the committed golden, unregenerated, 54 of 54; the golden regenerated byte-identical. The new check, "the bench, and the reference fighter": he loads plain, with the game's wounds and ladder; every fighter has a hash of his own; a replay of the roster's fighters keeps its data hash; matches of him against himself and against each of the two run; a replay that names him carries his hash and plays back; and after his data change, the roster's hash and a roster replay hold while his own replay is refused.

## 4. What assumes two fighters, or these two ids

| Where | What it assumes | For four fighters |
| :--- | :--- | :--- |
| The loader | Any number of ids. Each needs `fighter.json`; `meters.json` may be absent. The role must be hero, villain or rival. The meters it knows are anguish and menace | The reference fighter needs a role: I would add `reference`. Nothing in the sim's rules reads a role. A fighter with no meter file loads today; his first match is window 2's check |
| A match | Exactly two fighters: slots 0 and 1, "the other one", two intents a tick, an exchange's attacker and defender | Stays. More than two in a match is co-op, and a project of its own |
| The sim's rules (`sim/core`, `sim/director`, `sim/world`) | **No id is named in code** | Nothing |
| The state hash | His id, name, role and colours are in it | Nothing |
| A replay | Its header keeps the setup, slots included. With no slots it means the roster's first two. Its data hash covers the whole roster | Section 3, and the pin in section 5 |
| The JS parity copy | The frozen JS core carries its own two fighters as constants and reads no fighter file. Its golden is frozen (ADR 0006) | Nothing: it is untouched by any of this |
| My tools | `parity.gd` checks the roster's order against the two ids; the golden's arms (swap, the two mirrors) and `batch.gd --arm` name them | The roster check stays: it is what pins the default pairing. Window 3: `--a` and `--b` take any id |
| Other owners' data, as far as I saw | `data/director/ai.json` has one entry keyed by id (`digInBy`); the finisher's key is in his `fighter.json`; Combat's pools, Animation's `data/anim/fighters.json`, UI's `fighter_names.json` and Audio's voices are keyed by fighter | Each owner's part of a grey copy. A parity fixture already plays a match with an id nobody else knows (`TEST`), so the sim itself copes |

## 5. Naming any two of N (window 3, built in scratch)

- `SimCore.newMatch(S, seed, ai, {"slots": ["A", "B"]})` picks them, from the roster or the bench. `"flip": true` swaps the sides. The same id twice is a mirror, with `"names"` to tell the two apart in the feed. A replay keeps all three.
- **Two guards, built.**
  1. Slots that are not two fighters the data has are refused with an error, and the default pairing plays: the match is the default match to the hash. Before, it failed inside the fighter's construction.
  2. `batch.gd` takes ids: `--a=ID --b=ID`, a mirror with the same id twice. With the two real ids its digest is the default arm's.
- **The third guard is not built:** the default pairing written in the roster file. It would turn `roster.json` from a list into an object, and Tools' flash tools and Legal's pairing list read it as a list. The default pairing stays the roster's first two, a new roster id goes after them, and parity's roster check holds the order.
- The select screen, QA's runner and Rendering's host each pass the setup they want. Those are theirs.

**Proof,** on the same export: the check "a match's slots name two fighters the data has" (an id nobody has, one id, three, numbers and none each play the default match to the hash; good slots are taken). `batch.gd -- 4 1` and `-- 4 1 --a=PROTAGONIST --b=RIVAL` give the same digest; the reference fighter against the rival, and against himself with the sides swapped, run; an unknown id is refused with exit 2.

## 6. `care` switched on

- It is one number in `fighter.json`, from -1 to 1. Both are 0. Game Design's values are 0.8 for the Protagonist and -0.5 for the Anti-hero.
- **Three reads, all the director's.**
  - The launch planner's personality term (`launch.gd` lines 171, 199 and 241 to 245): a fighter who cares scores a launch down by the people near where it goes; one who does not scores it up, and likes a tall building.
  - Where the AI leads a fight (`location.gd` line 111): toward people or away from them.
  - The AI's lean in a brawl (`brawl.gd` line 1951): the same, by the stick.
- **What moves.** `care` is a hashed field of the fighter, so every golden match differs from tick 0, and each match parts from its old self at the first launch or roam that reads it. Collateral, where fights happen, what launches pick, and through them the match's length and the win rates.
- **So it is a re-baseline, once,** as the pipeline says: two data lines, one regeneration, in a window of its own. I have not measured it. The before is QA's baseline on the build of the day; the after is the same rows with the two values in. A new fighter's care is then read on his own rows, without moving the others.
- It should not share a window with anything else that moves matches, or the two effects cannot be told apart.

## 7. The windows, smallest first

| Window | What | Mine | Others | Golden |
| ---: | :--- | :--- | :--- | :--- |
| 1 | **One wounds file and one ladder file,** with a fighter's differences beside them (section 2) | The loader's merge and the resolved hash, about 60 lines; the parity cases, about 80; two files moved and four deleted; the loader's test hook gains the shared folder | Tools: the two schemas, the merged check, the fixtures. A session | **None,** proved byte for byte |
| 2 | **The reference fighter on the bench, and a hash a fighter** (section 3). **Built in scratch, parked** | `data/fighters/REFERENCE/fighter.json`, `data/fighters/bench.json`; the loader's bench, `has` and `hashOf`; the replay's data hash by setup; the role word. About 70 lines, a check of 75, a folder | Tools: a schema for `bench.json` (a list of ids that are not in the roster; the validator warns until then). UI, Animation, Audio, Combat: his rows as a grey copy, before he can be drawn or heard | **None** |
| 3 | **Selection** (section 5). **Built in scratch, parked** | The slot guard in `newMatch`; `--a` and `--b` in `batch.gd`. About 30 lines and a check of 35 | QA's runner; Rendering's host; UI's select | **None** |
| 4 | **`care` on** (section 6) | Two data lines, one regeneration | QA: before and after. Encounter and Game Design: the bands | **Every match moves.** The one re-baseline |
| Later | A fighter's own wound profile, a third meter, forms | With his tier 2 | | With his mechanic's switch |

- Windows 1 to 3 change no match and no golden, so each is proved against the golden as it stands and can land between other people's work. Windows 2 and 3 apply together: `pending/fighters-w23/bench_fighter.py`, then `select_guards.py`.
- Window 1 is worth doing first whatever follows: it ends the double edit that Encounter's tunes made.
- The parked `weight_event.py` moves every golden's event digest and no state. It can ride with window 4's regeneration, proved alone first.

## 8. Open

| For | Question |
| :--- | :--- |
| Game Design | The reference fighter's role word, his Rally rule and his finisher. The build has `reference`, `second_wind` and `generic` |
| Tools | A schema for `data/fighters/bench.json`, and the rule that a bench id has a folder and is not in the roster |
| Orb | The reference fighter on the select screen, or out of sight. He is out of sight on the bench; the roster is one line away |
| Game Design and Tools | Whether the stat band (0.95 to 1.05) is held by the schema |
