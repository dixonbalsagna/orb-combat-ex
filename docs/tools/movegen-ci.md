# Gating CI on the moveset generator's `--check` (a recommendation, nothing ported)

Owner: Tools and Pipeline. Date: 2026-10-05. Status: a note for the EP. Nothing is ported or added to CI.

## What `--check` proves that the validator does not

`python docs/combat/pending/movegen/gen_moveset.py --check` regenerates both movesets and the sheet in memory and compares them with the committed files, and it also checks every move on disk, the `links` table and Combat's blur patterns against Legal's rows. The schemas and cross-checks in `apply-movegen.cjs` (the four schemas and the rules `parts-*`, `identity-ref`, `cells-quota`, `moveset-*`) already catch a malformed file, an invalid shape, a derived field that is wrong (`sends`, `links`, `step`, `beat`, `forms`, `arms`), a status that does not follow its key set, a key set that is no manifest row, a miscounted quota, a shape twice, and a move that matches a Legal row that names no pose flags. What only `--check` catches:

- **The files are what the inputs give.** A hand edit to a generated move, or a change to `parts.json`, `identity.json` or `cells.json` (or to an Animation manifest the generator reads) that was not followed by a regeneration. The `generator.inputs` hash is part of this.
- **Legal's rows that name pose flags** (`claw`, `leap` and so on): they need the generator's flag rules, which the validator does not copy.
- **The generator's own `--self-test`** (made-up moves and strings through the rows).

The check reads `data/anim/waves/*.manifest.json`. A manifest commit by Animation can therefore make `--check` fail with no change in `data/combat/`. That is the point (the movesets should follow the key sets), but it needs a rule for who regenerates: Combat, on the EP's word, in the same push or the next.

## Is Python available in CI?

Yes, but not under our control. Every job runs on `ubuntu-24.04`, whose runner image carries a Python 3 with no setup step (I have not run it there: check the image's published tool list before relying on it), and `actions/setup-python` can pin an exact version the way `setup-node` pins 24.19.0. The generator is standard library only, so no `pip` step is needed. The cost is about a second of CI time.

What it adds that we do not have today:

| | |
| :--- | :--- |
| A second pinned toolchain | CI pins Node (24.19.0), Godot and every action by SHA. An unpinned Python would drift with the runner image; a pinned one is one more thing to keep up |
| A second language for the data pipeline | The validator, the schemas, the self-test and every parity oracle are Node. A contributor who runs the validator today needs Node only; `--check` locally would need Python too |
| No shared code with the validator | The generator reads the same JSON files with its own loader, and the cross-checks in `xref-movegen.js` re-derive the same rules in JavaScript. Two implementations of one grammar will disagree over time, and nothing compares them |
| Byte-level reproducibility | The check compares bytes. Python's `json` output (`1.0` against JavaScript's `1`, escaping, key order) must stay exactly as it is |

## Recommendation: port the generator to Node, when its rules settle

1. **Keep one toolchain.** The data job is Node only, and the validator already hosts the rest of the movegen rules. A Node generator can run inside `node tools/validate.js` or beside it (`node tools/movegen.js --check`) with no new dependency, no second pinned version and nothing new to install on a contributor's machine.
2. **The port is small and safe.** The generator is 18 to 25 KB, standard library only, with no state and no clock. The randomness is a SHA-256 of a string plus integer arithmetic (`jitter`), which `node:crypto` and plain numbers reproduce exactly. The output is integers and strings, so number formatting only matters for the few floats (write them as the Python does, or keep them out of the generated files).
3. **Prove the port with the Python as the oracle.** The project already does this for the simulation (the JS core is the parity oracle for the GDScript port). Run both generators on the same inputs and require byte-equal output for the two movesets and the sheet, once, in the port's own check; then retire the Python from the gate and keep it in the history.
4. **Not yet.** The generator changed after it was first committed (version 2: the moves gained `arms`, `flags` and `asks`, the grammar gained Legal's banned rows, sequence rules and conditions). Port after Combat freezes the rules, with Legal's rows in.

**In the meantime** (until the port): the validator rules from `apply-movegen.cjs` are the gate, and `--check` is a step Combat runs before it hands a movegen change to the EP. If the EP wants it in CI at once, one job step does it: `actions/setup-python` pinned by SHA with `python-version: '3.12'`, then `python docs/combat/pending/movegen/gen_moveset.py --check` (the path moves with the files). I would add it only for the days before the port, and would not add `pip`.

## What I need from the EP

- A word on the recommendation (port to Node later, the validator rules now, an optional pinned-Python step until then).
- Who regenerates when an Animation manifest changes the check's result (my suggestion: Combat, on a note from the EP).
