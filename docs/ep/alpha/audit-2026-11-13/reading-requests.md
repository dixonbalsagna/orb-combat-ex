# Alpha audit: reading requests

Owned by the judgment session; nothing else edits this file. The reading session answers each request in `reads/RR-<nn>.md`. An answer file existing means the request is answered.

Rules for every answer: listing, counting, tabulating and extracting only; no rating, ranking or recommending. A `path:line` for every row, read from the file at the baseline (8901d351); "(uncommitted)" where the path is in `baseline-status.txt`; "not found" where there is nothing. If a path named here doesn't exist, say so in the answer and carry on with the rest.

"How soon" is counted from the inventory's COMPLETE line. Oldest first, as usual.

---

## Batch 1 (written 2026-11-13 20:07 PST, before the phase 2 briefing)

### RR-01. Both fighters' move tables, cell by cell
- **Paths:** `data/input/actions.json`, `data/input/layouts.json`, `data/input/stances.json`, `data/input/timing.json`; `data/combat/*.json` (stick.json, mixed.json, recipes.json, styles.json, templates.json, phrases.json, enders.json, finishers.json); `data/director/stick.json`; `data/fighters/PROTAGONIST/`, `data/fighters/RIVAL/`, `data/fighters/roster.json`; the code that reads them where the data alone doesn't say what a cell does (`sim/input/`, `sim/director/press.gd`, `mash.gd`, `melee.gd`, `brawl.gd`, `grapple.gd`, `blast.gd`).
- **Question:** for each fighter (PROTAGONIST, RIVAL), each held button (none, LB, RB, RT, LT), each face button (X, Y, B, A) and each way of pressing (tap, mash, hold): what does the data define? Then the same for the right stick (flick and hold, by direction if the data splits it, with and without each held button) and for any two-button pairs the data defines.
- **Format:** one table per fighter. Columns: held | button | press | what the data names (move, recipe or action id) | where (`path:line`) | per-fighter or shared between both | "not found" if the cell has no entry. After the tables: a count of cells with an entry, cells sharing an id with another cell, and cells not found. No comment on whether a cell is good.
- **How soon:** within the first two checks.

### RR-02. Forms and transformations in data and code
- **Paths:** `data/fight/forms.json`, `data/fight/power.json`, `data/fight/ladder.json`, `data/fighters/PROTAGONIST/`, `data/fighters/RIVAL/`, `sim/core/` (files that read forms or power), `sim/director/` (any file that starts or blocks a transformation), `render/` (any per-form look).
- **Question:** which forms does each fighter have in data; what input or condition starts each; what code reads each; is there a per-form look; and where, if anywhere, a hit on a transforming fighter is ignored or blocked.
- **Format:** table: fighter | form id | trigger as the data or code states it | fields that change with the form | per-form look file, if any | `path:line`. Then a list: every place a transformation in progress is protected from interruption, or "not found".
- **How soon:** within the first two checks.

### RR-03. The modes and the menu, as the code has them
- **Paths:** `ui/` (all), `project.godot` (main scene, autoloads), `sim/core/campaign.gd`, `sim/core/run.gd`, `sim/core/boons.gd`, `sim/core/cross.gd`, `net/` (lobby, host and join entry points), `data/fight/campaign.json`, `data/fight/run.json`.
- **Question:** list every menu screen and every row on it, and what each row starts. Then, for each of these eight modes, list every entry point that exists (a menu row, a page word, a command-line flag, a script in a build folder): solo against the computer; two players on one PC; LAN 1v1; LAN 2v2; couch 2v2; co-op horde; custom planet setup; campaign.
- **Format:** table 1: screen | row | what it starts | `path:line`. Table 2: mode | entry point | kind (menu, page word, flag, script) | `path:line` | "not found". Also list: fighter-select and planet-select screens, the result screen and its rows (rematch, leave), each with `path:line` or "not found".
- **How soon:** within the first two checks.

### RR-04. Everything the game writes to disk, and everything that could send data
- **Paths:** `sim/`, `render/`, `ui/`, `net/`, `audio/`, `qa/` (GDScript only), `project.godot`, `export_presets.cfg`. Not `tools/`.
- **Question:** (a) every place the shipped game writes a file or a setting: `FileAccess.open` with a write mode, `ConfigFile.save`, `ResourceSaver`, `DirAccess` make or remove calls, `user://` and `OS.get_user_data_dir`, `JavaScriptBridge` storage or download calls. (b) every place the game could send or receive anything over a network or hand off to another program: `HTTPRequest`, `HTTPClient`, `ENet`, `WebSocket`, `WebRTC`, `PacketPeer`, `StreamPeer`, `UDPServer`, `TCPServer`, `OS.shell_open`, `OS.execute`, `OS.create_process`, `JavaScriptBridge.eval`.
- **Format:** two tables: call | what it writes or sends, as the code states it | the path or address it uses | `path:line`. Counts per folder at the end.
- **How soon:** within the first three checks.

### RR-05. Leftover names and retired systems
- **Paths:** `sim/`, `render/`, `ui/`, `net/`, `audio/`, `data/`, `localization/`. Not `prototype/`, not `docs/`.
- **Question:** where do these still appear? (a) the placeholder names `KAI` and `VORR` (whole words, any case); (b) the backburnered meters: `menace`, `anguish`, `ego`, `respect`, `pride`, `wrath`, `hunger`; (c) the retired hiding system: `hidden`, `hiding`, `ambush`, `cover` as a hiding term; (d) casualties: `casualt`, `civilian` beside `kill`, `death`, `dead` or `lost`; (e) the old strip: `strip` as the flat arena, and any constant of 9600 or 1200 columns.
- **Format:** per term: total hits; hits per file (top 15 files); for each of those files, up to three `path:line` examples with the line's text. Mark a file "data" or "code". No judgement on whether a hit is live.
- **How soon:** within the first three checks.

### RR-06. The computer opponent's levels and their measured win rates
- **Paths:** `data/director/ai.json`, `sim/director/ai.gd`; `docs/director/runs/` (6eec6a75 first, then every folder dated from 2026-11-01), `docs/qa/runs/` (the same dates), `qa/` (the scripted players and their batch runners).
- **Question:** (a) every field in `ai.json` that differs between difficulty levels, side by side. (b) every win-rate figure on record for a scripted or human player against each level, from 2026-11-01 on. (c) which scripted players exist in `qa/`, and what inputs each uses (face buttons, right stick, LB guard).
- **Format:** (a) table: field | each level's value | `path:line`. (b) table: build or commit | level | who played (scripted player's name, or Orb) | matches | win rate | `path:line` of the record. (c) table: script | inputs it presses | `path:line`.
- **How soon:** within the first three checks.

### RR-07. Performance records on file
- **Paths:** `docs/perf/` (all, including `runs/`), `docs/rendering/runs/` (frame-time records only; count the rest), `tools/` (any bench, soak or frame-record script: list them).
- **Question:** what has been measured, on which machine, on which build?
- **Format:** table: record (`path`) | date | build or commit | machine as the record names it | scene or match | the headline numbers as written (frames a second, longest frame, load time, memory) | `path:line`. Then a list of bench, soak and frame-record tools with one line on what each does, from its code. Mark any record that says it was taken on a saturated machine.
- **How soon:** within the first four checks.

### RR-08. Orb's reported problems against the bug list
- **Paths:** `docs/ep/vision.md` from the entry "First play of versus on the globe, Orb (2026-11-01)" to the end; `docs/qa/runs/*/README.md` and the play notes beside them; `qa/known-bugs.md`.
- **Question:** list every problem Orb reported in play from 2026-11-01 on (one row each, in Orb's words, shortened), and whether `qa/known-bugs.md` has a row for it.
- **Format:** table: date | build | the problem, quoted | `docs/ep/vision.md:line` or the QA record's `path:line` | the matching row in `qa/known-bugs.md` (`path:line` and its status as written) or "not found". Match on the subject only; don't judge whether a row is right.
- **How soon:** within the first four checks.

### RR-09. The open corrective items, against the commit log
- **Paths:** `docs/ep/corrective-plan-2026-11-07.md`; `git log` from 2026-11-07 to the baseline; `docs/*/runs/` records that name a CD.
- **Question:** for each of CD-01 to CD-27, what the plan's last column says, and every commit or saved record since 2026-11-07 that names that CD.
- **Format:** table: CD | the plan's last column, quoted | commits naming it (sha, date, subject) | records naming it (`path`) | "none found".
- **How soon:** within the first four checks.

DONE 2026-11-13 21:53 PST
