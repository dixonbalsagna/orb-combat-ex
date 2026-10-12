# Fighters as data: what the core assumes today, and the windows to four fighters

Owner: Simulation and Engine. 2026-10-12. **Paper only: nothing here is built or run.** Sizes are estimates. It answers the five questions Game Design's `docs/design/fighter-pipeline.md` puts to Simulation and Tools. Line numbers are HEAD's (f4e57e63).

## In short

| Question | Answer |
| :--- | :--- |
| Can `wounds.json` and `ladder.json` each become one shared file, with a fighter's differences beside it? | **Yes, and the goldens need not move at all.** The two fighters' copies are identical today, value for value. The data hash is taken over what a fighter resolves to, so it stays the same to the bit |
| Does a new fighter folder and roster entry leave every existing golden unchanged? | **Every match, replay and checkpoint: yes. One recorded vector moves:** the roster's data hash covers the whole roster. Window 2 makes it one hash a fighter, so that it never moves again for a fighter nobody in the match is |
| What assumes two fighters, or these two ids? | **The sim's rules name no id.** A match has exactly two fighters, and that stays. The ids are named only in my check and batch tools, and in other owners' data (section 4) |
| What does a match setup need to name any two of N? | **Nothing new:** `{"slots": [id, id]}` has been there since D1a, and a replay records it. Three small guards are worth adding (section 5) |
| What does `care` switched on do? | It moves where launches go, where the AI leads a fight and which way it leans in a brawl: three reads, all Encounter's. It is in the state hash, so every golden match moves from tick 0. **It is a re-baseline, once,** as Game Design says: one regeneration, and QA's bands read before and after |

## 1. What is there today

- `data/fighters/roster.json` is `["PROTAGONIST", "RIVAL"]`. Each id has a folder with four files: `fighter.json`, `wounds.json`, `ladder.json` and `meters.json`.
- `FighterData` (`sim/core/fighter_data.gd`) loads the roster once a process, checks every value, and gives each fighter one read-only record. A match copies a few numbers from it and points at the rest.
- **What differs between the two.** `fighter.json`: role, three colours, `dmgMul` (0.95 and 1.02), `spd` (1.0 and 0.95) and the finisher's key. `meters.json`: one has anguish and the other menace. **`wounds.json` (7.3 KB) and `ladder.json` (2.9 KB) do not differ in any value.**
- The data hash folds, in order: the roster, then for each id his four files under their names. A `_` key is skipped, so a note is free to change.

## 2. One wounds file and one ladder file

**The layout.**

| File | What it holds |
| :--- | :--- |
| `data/fight/wounds.json` | The wounds model, whole: today's file |
| `data/fight/ladder.json` | The ladder, whole: today's file |
| `data/fighters/<id>/wounds.json`, `ladder.json` | **Optional.** Only what differs for him. Absent for both fighters today |

- `data/fight/` is where the fight's own numbers live (the mood, the pauses, the shots), and Game Design's line puts the wounds model there: it is the game's.
- **The merge rule.** A fighter's file is laid over the shared one key by key. A dictionary is merged; a number, a word or a list replaces the shared one whole. A key the shared file does not have is refused, so a slip of spelling cannot hide. A `_` key is a note.
- **The hash is taken over what he resolves to,** under the names it uses today. With no differences, each fighter resolves to exactly today's file, so the roster's hash is the same to the bit and `golden.json` does not change by a byte.
- A tune of the game's wounds is then one edit. A fighter's own wound profile, at his tier 2, is a short file of his own.

**Proof for the window.** Parity against the committed golden, unregenerated; the golden regenerated and compared byte for byte; and new cases: no file of his own gives the shared one; a difference replaces one leaf and nothing else; an unknown key is refused; the roster's hash equals the number it has today.

**For Tools.** The full schemas move to the two shared files. A fighter's file takes the same shape with nothing required. The validator checks the merged result against the full schema, and its fixtures split the same way.

## 3. Adding a fighter: what moves

- **No match moves.** A match reads only the two fighters in it.
- **The default pairing must stay.** It is the roster's first two. A new id goes after them. Section 5 pins it.
- **The roster's hash moves,** because it is one hash over everyone. That is the `rosterHash` vector in the golden, and it is in every replay's data hash. So adding the reference fighter would today turn away every stored replay of the first two.
- **Window 2 makes it one hash a fighter.** A replay's data hash then takes the game's data and the two fighters in its slots. Adding or tuning a third fighter leaves every replay and every vector of the first two alone, for good. The golden's one vector becomes one a fighter, once.

## 4. What assumes two fighters, or these two ids

| Where | What it assumes | For four fighters |
| :--- | :--- | :--- |
| The loader | Any number of ids. Each needs `fighter.json`; `meters.json` may be absent. The role must be hero, villain or rival. The meters it knows are anguish and menace | The reference fighter needs a role: I would add `reference`. Nothing in the sim's rules reads a role. A fighter with no meter file loads today; his first match is window 2's check |
| A match | Exactly two fighters: slots 0 and 1, "the other one", two intents a tick, an exchange's attacker and defender | Stays. More than two in a match is co-op, and a project of its own |
| The sim's rules (`sim/core`, `sim/director`, `sim/world`) | **No id is named in code** | Nothing |
| The state hash | His id, name, role and colours are in it | Nothing |
| A replay | Its header keeps the setup, slots included. With no slots it means the roster's first two. Its data hash covers the whole roster | Section 3, and the pin in section 5 |
| The JS parity copy | The frozen JS core carries its own two fighters as constants and reads no fighter file. Its golden is frozen (ADR 0006) | Nothing: it is untouched by any of this |
| My tools | `parity.gd` checks the roster's order against the two ids; the golden's arms (swap, the two mirrors) and `batch.gd --arm` name them | Window 2: the check reads the pairing from data; window 3: `--a` and `--b` take any id |
| Other owners' data, as far as I saw | `data/director/ai.json` has one entry keyed by id (`digInBy`); the finisher's key is in his `fighter.json`; Combat's pools, Animation's `data/anim/fighters.json`, UI's `fighter_names.json` and Audio's voices are keyed by fighter | Each owner's part of a grey copy. A parity fixture already plays a match with an id nobody else knows (`TEST`), so the sim itself copes |

## 5. Naming any two of N

- `SimCore.newMatch(S, seed, ai, {"slots": ["A", "B"]})` picks them. `"flip": true` swaps the sides. The same id twice is a mirror, with `"names"` to tell the two apart in the feed. A replay keeps all three.
- **Three guards for window 3.**
  1. An id the roster does not have is refused with an error, and the match falls back to the default pairing. Today it would fail inside the fighter's construction.
  2. The default pairing is written in the roster file (`"default": ["PROTAGONIST", "RIVAL"]`; the loader already takes the roster as an object). Then the order of the roster is the select screen's and can change freely, and a replay with no slots keeps its meaning.
  3. `batch.gd` and the golden's arms take ids, not the two names.
- The select screen, QA's runner and Rendering's host each pass the setup they want. Those are theirs.

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
| 2 | **The reference fighter, and a hash a fighter** (sections 3 and 4) | `data/fighters/REFERENCE/` (base stats, care 0, no meter); the role; one hash a fighter in the loader, the golden and the replay's data hash; the roster check from data. About 80 lines and a folder | Tools: the roster's schema. UI, Animation, Audio, Combat: his rows as a grey copy. Combat: which finisher a plain fighter has | Only the data-hash vectors change shape. No match moves |
| 3 | **Selection** (section 5) | The three guards; `--a` and `--b` in `batch.gd`. About 50 lines | QA's runner; Rendering's host; UI's select | None |
| 4 | **`care` on** (section 6) | Two data lines, one regeneration | QA: before and after. Encounter and Game Design: the bands | **Every match moves.** The one re-baseline |
| Later | A fighter's own wound profile, a third meter, forms | With his tier 2 | | With his mechanic's switch |

- Windows 1 to 3 change no match, so each can be proved against the golden as it stands and can land between other people's work.
- Window 1 is worth doing first whatever follows: it ends the double edit that Encounter's tunes made.
- The parked `weight_event.py` moves every golden's event digest and no state. It can ride with window 4's regeneration, proved alone first.

## 8. Open

| For | Question |
| :--- | :--- |
| The EP | The shared files' home: `data/fight/` as here, or a folder under `data/fighters/` |
| Game Design | The reference fighter's role word, and whether he has a Rally rule and a finisher |
| Tools | Whether the validator can check a merged file, or wants the fighter's file complete and generated |
| Game Design and Tools | Whether the stat band (0.95 to 1.05) is held by the schema |
