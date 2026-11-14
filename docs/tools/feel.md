# Feel replays, the refusal ledger and the scheme gauntlet (Tools, 2026-11-06)

Three tools that check a change against Orb's real hands before anyone plays it. Both read a saved match of Orb's (`homework/Files/orb-first-play-*.json`), replay it headless on the kept tree of the build it was played on, and count what happened to the pad. Nothing is shown on screen and nothing is sent.

## Feel replay: "what would this rule have done to my match?"

```
node tools/feel/feel.mjs homework/Files/orb-first-play-20261106-1934.json --override "data/director/interrupts.json:brawl.heldPressTicks=0"
```

A rule is one data value: `file:dotted.path=value`. Repeat `--override` for several, or give `--switch signatureRtOnly=false` (a switch is `switches.<name>` in `data/input/timing.json`), or `--overrides-file rules.json` (a list of `{file, path, value}`).

It prints two before/after tables:

- **FORKED** (the fair one). At every press of interest (a right-stick start, a signature, a special; change with `--interest light,heavy,sig,rsStart,...`) the game state is saved, the rule is put in, the next 240 ticks (4 seconds; `--window`) are played from what Orb really pressed, and the state is put back. The baseline column is the same 4 seconds of Orb's real match. So each press is asked: what would you have done with this rule, starting from exactly where Orb was?
- **WHOLE MATCH.** The match replayed from the first tick with the rule on. It drifts from Orb's real match after the first difference (the foe answers a different fight), so read it as a rough run.

The counts, for the pad: **beams fired** (and his), **presses refused** and the reason of each, **side swaps** (the two fighters changing sides), **seconds without control** (locked, launched, down, stunned, reeling), **hits landed**, **clean hits** (a hit with none taken in the 30 ticks before), **hits taken**. A line under the forked table says how many presses went from refused to fired and the other way.

### Reading it

- The first lines say whether the saved final hash was **reproduced exactly** on the kept tree. If it was, the baseline column is Orb's match as he played it. If not (some saves do not replay exactly on their own tree, for a reason outside this tool: `blackbox-verify.mjs` fails on them too), the baseline is the replay on that tree and the report says so.
- **A rule in the input hub will show NOTHING CHANGED.** The replay feeds the recorded intents straight to the sim and skips the hub (the layer that turns the pad into intents), so a hub rule such as `quickRead` cannot be seen here. The report says so when nothing moved. Those rules go through the scheme gauntlet (a scripted pad through the hub).
- **Which rules can fork.** `data/input/timing.json` and `data/director/interrupts.json` are changed in memory, so they fork. Any other data file is patched into a scratch copy of the tree and plays the whole match only (no forks), slower.
- **The pad slot** is found itself (the slot with most recorded inputs; Orb sometimes took slot 1); `--slot N` overrides.
- Needs the kept tree of the build named in the file (`homework/Files/builds/orb-first-play-<commit>-<folder>/tree`), or `--tree <a tree folder>`. The tree is copied to a scratch folder (`%TEMP%\meridian-feel`) and never touched.
- A 4-minute match takes about 40 seconds (one Godot, headless, below-normal priority, with a time limit). `--max-forks 120` thins the presses evenly; `--no-whole` or `--no-fork` skip a half; `--json out.json` keeps every fork's row.

## The refusal ledger: "every press the game did not honour"

```
node tools/feel/ledger.mjs homework/Files/orb-first-play-20261106-1934.json --out ledger.txt
```

The same replay with no rule; every press of the pad (light, heavy, signature, special, dodge, guard, a right-stick start, transform, context, power) is watched for 12 ticks. Each gets one verdict:

- **refused**: the game said no and gave a reason (a stunned press, a press into a zip or a double hit, a stick start that was `taken`, `late`, `replaced`, a refused grab, a refused driver or answer) and nothing else came of it;
- **partly**: a refusal, and something else happened too;
- **silent**: nothing answered the press, no blow, no cue, no refusal. These are the ones that felt like the game ignored him;
- **honoured**: something answered.

The ledger lists the counts by press and by reason, then every press not honoured with the time (minutes:seconds), the tick, the press, the state the fighter was in, his energy and the reason. `--all` lists every press; `--json` keeps the rows.

An answer goes to the oldest press with no answer yet (three presses and one blow leave two unanswered, which is how "each press is a blow" reads). A refusal goes to the latest press. "Silent" is a read of the sim's cues, not a proof: a press that did its work without a cue of its own shows as silent, so look at a silent row before changing a rule for it.

## The scheme gauntlet: "is a stick player stuck losing?"

```
node tools/feel/gauntlet.mjs --scheme "hand=data/input/timing.json:switches.signatureRtOnly=false" --n 10
```

Scripted pads play whole seeded matches against the computer at each level (easy, medium, hard), once for the shipped rules and once for each scheme you name. A **scheme** is a named set of data overrides (`name=file:dotted.path=value;file:dotted.path=value`, or `--schemes-file schemes.json`). They are written into a scratch copy of the tree, so a rule in the input hub counts here, which a replay of recorded intents cannot show. Every scheme plays the same seeds, so the comparison is paired and a scheme equal to the shipped rules gives exactly the shipped result.

The five arms are one scripted pad on the real hub each: **stick-only** (a right-stick flick every 8 to 24 ticks), **masher** (X every 8 ticks), **timing** (LB for 10 ticks on any wind-up cue of his, lights too, then X; X every 8 ticks otherwise), **beam-first** (RB and the right stick held toward him, let go to fire, X to build energy meanwhile), **circle-first** (LT with the left stick toward, up, down, away or neutral, and a face button). Each walks at the rival with the left stick.

Per scheme, arm and level the table gives **win %** (with a plain 95% interval, because ten matches say little: about plus or minus 31 points at 50%), **refusals per 100 presses**, **seconds without control per minute** and **beams a match**; a scheme's rows show the change from the shipped rows in brackets. `--json` keeps the raw counts and the refusals by reason.

- `--arms stick,beam`, `--levels easy,hard`, `--n 10` matches a cell from `--seed 1`, `--tree <folder>` (default: the newest kept build's tree).
- A match takes about 12 seconds; a cell of 10 about 2 minutes; the full grid (5 arms, 3 levels) is 15 cells a scheme, so about 30 minutes a scheme with 3 jobs. One Godot a cell, at most 3 at a time (six Windows processes), below-normal priority. Start a long grid when the machine is quiet.
- The arms are the scripts of `tools/feel/gauntlet.gd`; the shared base is QA's `stickplay.gd` and `players.gd` (read, not changed).

## Self-test

`node tools/feel/feel-selftest.mjs` checks the parsers and tables (no Godot), then on the kept build `orb-first-play-10d8b8cf-68ee07cc` with Orb's saves: the baseline reproduces the saved final hash with forks taken (the restore leaves the timeline alone), a rule equal to the shipped value changes nothing, a real rule changes the match, and the ledger's verdicts add up. `node tools/feel/gauntlet-selftest.mjs` does the same for the gauntlet: every arm plays and presses, a scheme equal to the shipped rules gives exactly the shipped result, and a scheme that changes a rule changes a result. It skips the Godot part, and says so, if those files are not on this PC. `--no-e2e` skips it too (about 2 minutes with it).

## Where things are

`tools/feel/feel.gd` (the replay, run by Godot), `gauntlet.gd` (the five scripted pads), `lib.mjs`, `feel.mjs`, `ledger.mjs`, `gauntlet.mjs`, `feel-selftest.mjs`, `gauntlet-selftest.mjs`. The shared base is `qa/godot/trace_replay.gd` and `ai_compare.gd` (read, not changed).

**2026-11-07 gauntlet fixes.** `press_refused` with reason `stun_limit` (a landed blow on a stunned rival) is not counted as a refusal; the timing pad guards on the rival's `windup` start cue and taps X every 8 ticks; `set_struggle` gets the push word (`DirBeam.pushModeOf == "stick"`, looked up by name so an older tree still runs). Results on the morning page: `docs/tools/gauntlet-e80b8e3d.md`.
**The "orbs" arm** (`--arms orbs`, not one of the default five): Orb's scheme, a right-stick flick every 30 to 48 ticks (thumb pace) and LB for 10 ticks on every wind-up of the rival's; nothing else. Results next to stick-only: `docs/tools/gauntlet-orbs-scheme-e80b8e3d.md`.

## A run's output is kept in bounds, and a run stops at its first script error (2026-11-14)

`runGd` (tools/feel/lib.mjs, used by the feel replay, the gauntlet and the ledger) used to push every chunk the child printed into one array until it closed. On 9 November a gauntlet cell ran out of heap (4 GB) after 16 minutes: its scratch tree held a new class that had not been re-imported, so a script failed to compile and Godot printed about 10,800 SCRIPT ERROR lines (22 MB) in three minutes. Now:

- **`OutputKeeper`** keeps the first 16 KB, the last 64 KB, every line that starts with `FEEL ` or `GAUNTLET ` (at most 64 KB), the counts of bytes and lines, the FIRST script error line and the three most repeated ones. The `text` a caller gets is the whole output when it was short, or head, a line saying how much was left out, the kept lines, the most repeated errors and the tail. A node-only check feeds it 300 MB of one error: text 82 KB, the result line survives, the error is named.
- **`failFast`** (on by default): the child is stopped, by its own PID (`taskkill /PID <pid> /T /F` on Windows), at the first `SCRIPT ERROR:`, `Parse Error:` or `ERROR: Failed to load script` line, and the result's `killedOn` names it. The gauntlet's failed-cell line says "stopped at the first script error ... a scratch tree with a new class needs a re-import first". Checked on a real Godot run of a scratch project whose script fails: stopped in 365 ms with the error named, where the same run without failFast hung until its time limit (Godot does not exit after a script error in a `SceneTree` script).
- **A scratch tree needs a re-import when a class is new** (`godot --headless --path <tree> --import` once), or its scripts fail to compile and the first error is the one that stops the cell.

Not reproduced: the original flood. A script error ends the script that raised it in this Godot, so I could not make a scratch script print thousands of errors; the bound is proven by the keeper's own check, not by a real flood.
