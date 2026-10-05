# Generated movesets: the martial arts stance, both fighters

Owner: Combat and Choreography. Date: 2026-10-05. Status: parked. Nothing here is loaded or hashed, and nothing in the tree is edited. Design: `../../moveset-generator.md`. Built on HEAD `df75bce`.

Orb lifted the hold for the martial arts stance (`docs/ep/vision.md`, questionnaire 17). This folder is the generator's inputs, its reference script, and its output for the two launch fighters.

| File | What it is | Becomes |
| :--- | :--- | :--- |
| `parts.json` | the strike grammar, and every posed strike as a shape of it | `data/combat/parts.json` |
| `identity.json` | how each fighter bends the grammar: weights, "never" rows, how strongly to prefer what is posed | `data/combat/identity.json` |
| `cells.json` | Game Design's matrix for the martial arts stance: counts, quotas, the seed | `data/combat/cells.json` |
| `gen_moveset.py` | the reference generator: standard library only, no state, no clock | a script under `tools/`, Tools' to hold |
| `moveset.rival.json`, `moveset.protagonist.json` | **generated:** 30 lights and 16 heavies each, with the context cell and the signature's frame | `data/combat/movesets/<fighter>.json` |
| `review-sheet.md` | **generated:** every move on one row, for Combat, Animation and Legal, then Orb | stays in docs |

**To generate:** `python docs/combat/pending/movegen/gen_moveset.py`. **To check** that the committed files are what the inputs give: add `--check` (exit 1 when they differ). **The seed** is 20261004, in `cells.json`.

## 1. What changed for Orb's answers

- **The rival's hands are a mix.** A closed fist on his heavies and his enders: a blade hand or a palm on a heavy is a "never" row, and a plate may still lead. Blade hands on his lights, weighted first. His posed heavies with open hands (the haymaker, the rib shot) come out as the same key sets with the hand closed.
- **The Protagonist** is unchanged: palms, blade hands, arcs.
- **The stick leans the limb:** the five leans are quotas of 5 on the light cell.
- **A juggle is up to 5 skill strikes:** the light cell also has quotas of 10 moves that can be a flurry blow and 10 that can be a skill strike.
- **The signature's kind is not final,** so martial B is a generic frame (a tell, a lunge from the mid band, a rush of four from X in `links` order, a launcher from Y by where it sends) with nothing hand-picked.

## 2. What came out

| Fighter | Cell | Moves | Posed | Derived | Waiting (a new key set) |
| :--- | :--- | ---: | ---: | ---: | ---: |
| The rival | X, lights | 30 | 14 | 4 | 12 |
| The rival | Y, heavies | 16 | 12 | 2 | 2 |
| The Protagonist | X, lights | 30 | 16 | 6 | 8 |
| The Protagonist | Y, heavies | 16 | 14 | 2 | 0 |

- **22 new key sets,** 20 of them lights. Each is listed at the end of its fighter's part of the sheet.
- **Playable on the first day:** the rival 18 lights and 14 heavies, the Protagonist 22 and 16. Waiting moves are in the files and the director skips them.
- **Every quota is met:** at least 5 lights under each lean of the stick, at least 3 heavies for each send, at least 4 lifts and 4 guard breakers.
- **The two fighters share 20 of 46 shapes, 43%:** half of the lights and under a third of the heavies. Today's pools share 97%.
- **With a leg broken on the ground,** the playable lights are 12 for the rival and 13 for the Protagonist, and the heavies 9 and 8.

## 3. Two rules the generator gained while it was built

1. **Legal's tags travel with a key set.** A move that starts from a posed strike keeps that strike's tags, and a hand-state swap stays inside them: a key set tagged "hands open or claw" is never closed into a fist (`tagTips`). So the rival's straight fist to the chest comes from the rib shot, not from the double palm.
2. **A one-armed source is preferred** when two posed strikes could give the same shape, since a generated move is one limb.

## 4. Keys for Tools

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
| `strike.legalTags` | a list of `{tag, when: filter, why}` |
| `strike.banned` | a list of `{shape: filter, why}` |
| `strikes` | strike id to `{limb, tip, path, target, weight, uses, ground}` |

Cross-checks: every row of `strikes` is a valid shape (its tip takes its path, its path reaches its target, and a light matches no `lightNever` row); every path has a send, links, a step and a beat; a strike id is the `combat` id of a manifest row whose limb and target agree (the grammar's `arm` is the near arm's socket).

### `combat-identity.schema.json` (`combat.identity/1`)

| Key | Shape |
| :--- | :--- |
| `fighters` | fighter id to the block below |
| `waves` | a list of wave names, in the order their rows replace each other |
| `weights` | `limb`, `path` and `tip`, each a name to a number of 0 or more; a tip is written `limb.tip` |
| `weightsBy` | a list of `{when: filter, tip}`: weights that replace the plain ones for shapes the filter matches |
| `never` | a list of `{shape: filter, why}` |
| `tipOf` | strike id to a tip: his own reading of a shared strike |
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
| a strikes cell | `kind`; `valid`, how many shapes were candidates; `quotas`, name to how many moves meet it; `moves` |
| a move | `id` (`mv.<fighter>.<stance>.<button>.<nn>`); `limb`, `tip`, `path`, `target`, `weight`; `forms`, `step`, `links`: lists; `sends`; `beat`; `keys`; `ground`; `status`: posed, derived or waiting; `legal`, a list of tags; `review`: new, accepted, change or rejected |
| `keys` | `level`: posed, hand_state, re_aim, hand_state_re_aim or new. Unless new: `from`, a strike id, and `set`, a key set id; `hand` on a swap; `aim` on a re-aim |

Cross-checks:
- every move is a valid shape, matches no `never` row of its fighter and no banned shape, and no cell holds a shape twice;
- `sends`, `links`, `step`, `beat` and `forms` are what `parts.json` derives for the shape;
- `status` follows `keys.level`; `keys.set` is a row of one of the fighter's manifests and `keys.from` its `combat` id;
- each cell has the count and meets the quotas `cells.json` asks;
- **the files are up to date:** the generator's `--check` passes. This is the check to wire into CI.

## 5. Before these land

| Who | What |
| :--- | :--- |
| **Animation** | A look at the 14 derived moves (a hand closed or opened, or a blow landed one place over), and the 22 new key sets. A `tip` and a `path` on the manifest rows would replace my reading in `parts.json` |
| **Legal** | A screen of the sheet: 92 rows, of which the 22 waiting shapes are new. `strike.banned` is empty and is Legal's to fill |
| **Encounter** | The brawl reads a pool for each kind of press (`../recipes.brawl.json`). When these files land, the generator writes those pools from the two cells, and the names stay |
| **Tools** | The four schemas above, and the generator under `tools/` |
| **Orb** | The accepted sheet |
