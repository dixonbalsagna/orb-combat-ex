# SAVES: saves, settings and replays

Alpha audit, phase 2, area 17. Baseline 8901d351 (game code of the last build Orb played, 6a30b4c9). Read-only; no Godot run, no browser. None of the files cited below is listed in `baseline-status.txt`, so none is marked (uncommitted).

## Summary

- **Works:** settings and remapped controls are written when changed and applied again at start-up, with bad or old values pulled to valid ones; a missing or unreadable file means defaults, not a crash path in the code read. Replay playback refuses other formats, other data and malformed inputs, and CI tests that. The planet cache is checksummed and self-checking.
- **Does not:** outside LAN, the desktop game saves no replay at all (the recorder is a patch applied only for the private browser page). The replay names no build; only the file wrapped around it does.
- **Not proven:** no record shows a replay saved by the baseline build verifying on it, and settings have never been tested across a real restart on Windows or Linux.
- **Biggest gap:** X-27 cannot be shown today for the modes outside testers will mostly play, because those modes record nothing (F-SAVES-01), and where a replay exists nothing on file shows it verifying (F-SAVES-03).
- No blocker found in this area; five majors, all small jobs.

## Questions and answers

**Q1. What does the game write to disk, and where, on Windows and on Linux?**

From the reading answer RR-04 (`reads/RR-04.md`, Table A), spot-checked in the files. Outside tools, tests and demos the game code writes five things:

| What | File | Where | Evidence |
| --- | --- | --- | --- |
| The UI's remembered choices: Settings options, the start menu's choices, "already taught" hint flags, touch controls used | `ui_prefs.json`, one JSON dictionary | the game's user folder | `ui/core/ui_prefs.gd:7`, `:33-38`; keys at `ui/hud/ui_hud.gd:1209`, `:1783`, `:2478`, `:3980` |
| Remapped controls, per player | `input.json` (`schema: 1`, `presets`, `presets_p2`, `options`) | the user folder | `sim/input/remap.gd:13`, `:420-425`; `sim/input/input_data.gd:372-380` |
| The planet cache (baked ground for generated planets) | `field-cache/*.wfc` and keyed blobs | the user folder | `sim/world/field_cache.gd:37`, `:200-213`, `:283-295`; switched on in data, `data/biomes/field.json:24` |
| LAN only: a match file (the replay, report marks, slow frames, net figures, the build) | `lan-<commit8>-<pc>-<stamp>-<reason>.json` | a folder named `saved` beside the program, or the `--lan-save` folder | `net/lan.gd:48`, `:492-535` |
| LAN only: a log line per interval and notes | the file named by `--lan-log` | wherever the launcher points it | `net/lan.gd:423`, `:450` |

Also: a desync report writer exists (`net/desync.gd:375-379`), but no caller outside `net/tools/` was found (`git grep writeReport` at the baseline). In the browser build a match file is offered as a download and a copy sits in the browser's own storage (`ui/core/ui_web_clip.gd:141`; `tools/preview/blackbox.mjs:7-8`); the browser is for private looks only in Alpha. A screenshot is written only with a `shot` argument (`render/core/main.gd:1749-1752`).

Where the user folder is: `project.godot:8` sets only the name "Orb Combat EX" and no custom user folder (`reads/RR-04.md:15`), so it is the engine's default per-user application data folder named after the project, on both platforms. The exact path on Windows and on a Steam Deck is **not evidenced** in the repository: no page states it for testers and no run has listed it (F-SAVES-11). Every build (solo, LAN, any commit) shares that one folder.

Nothing is sent: no HTTP, socket or upload call exists in the game code (`reads/RR-04.md:420`); the only network use is the LAN link.

**Q2. Does a settings or save file from an older build load safely in a newer one?**

Mostly yes by design, not by a cross-build test.
- Settings options: only keys the current data still lists are applied (`ui/hud/ui_hud.gd:2488-2490`); each value goes through a clamp that pulls numbers into range, snaps numeric choices to the nearest listed one, and maps a retired layout name to its replacement or the default (`ui/core/ui_data.gd:328-346`). The local gate at the baseline passed these (`docs/ep/runs/6a30b4c9/gate-full-s415.txt:123`; the retired-layout case is `ui/tools/hud_check.gd:2967`).
- Start menu choices: read field by field with defaults and clamps (`ui/hud/ui_hud.gd:1613-1629`).
- Remaps: unknown or retired layouts and unknown actions are dropped and listed (`sim/input/remap.gd:430-446`).
- No version number in `ui_prefs.json`; a controls file whose `schema` is not 1 is treated as absent and overwritten at the next save (`sim/input/remap.gd:415-417`). There is no migration path for a future change of shape (F-SAVES-07).
- There is no "save game" (no campaign progress, unlocks or profile is written by any file in Q1).
- Not evidenced: an actual file from an older build loaded in a newer build. No such record was found.
- One thing an old file can carry across builds: a saved Off for Reduce flashing, when the lock is off, as it is on main (F-SAVES-05; off the owner's page).

**Q3. Do replays carry which build made them (X-27)?**

The replay itself: no. Its header is `format, v, intent, data, seed, setup, ai, ticks, inputs, toggles, checkpoints, final` (`sim/core/replay.gd:5`, `:43`). `data` is a hash of the combat, fight, world and fighter data the match read (`sim/core/replay.gd:176-239`), not of the code or the commit.

The file around the replay: yes, in both kinds that exist. A LAN match file has `build` (read from the packed `build_info.json`) and the commit in its name (`net/lan.gd:511`, `:523-524`, `:541-545`; stamped by `net/tools/lan_kit.mjs:117`). The browser page's match file is stamped with the page's build (`tools/preview/blackbox.mjs:383-386`). The report tool picks the kept build by that commit (`tools/preview/lan-report.mjs:171-173`).

So: a replay from another build with different data is refused up front (reason `data`); one from a build with the same data but different code is run and fails at the first differing checkpoint (reason `checkpoint`), which reads like a determinism bug, not "wrong build" (F-SAVES-02). And non-LAN desktop matches have no replay to carry anything (F-SAVES-01).

**Q4. A corrupt or hand-edited file: handled, or a crash?**

- `ui_prefs.json`: missing, unopenable, not JSON or not a dictionary gives "nothing remembered" (`ui/core/ui_prefs.gd:10-17`). Handled.
- `input.json`: not JSON, not a dictionary or wrong schema gives a fresh empty one (`sim/input/remap.gd:412-417`). Entries inside a well-formed file are not type-checked (`sim/input/remap.gd:435-439`): outcome in an exported build not evidenced (F-SAVES-08).
- Planet cache: magic, key, length and SHA-256 are checked, then sampled cells are recomputed and compared; any fault falls back to a fresh bake (`sim/world/field_cache.gd:112-145`, `:239-262`). A tamper test exists (`sim/world/tools/field_cache_check.gd:98-124`) but is not in CI (F-SAVES-12).
- Replays: format, version, input layout, each input entry, slot numbers and the data hash are checked before anything runs (`sim/core/replay.gd:116-136`, `:146-148`), tested in CI's golden gate (`sim/core/tools/parity.gd:3560-3581`, `:4027`; `.github/workflows/ci.yml:191`). `seed`, `ai`, `ticks`, `toggles` and `checkpoints` are read without a check (`sim/core/replay.gd:138-153`). The game itself never loads a replay from disk; only tools and the LAN desync path do (F-SAVES-08).
- The safety audit of 2026-11-07 covered the network side: it found no way to run code through received data (`audit/2026-11-07/findings.md:148`) and rated the LAN peer's ability to freeze the game S3 for private builds (`audit/2026-11-07/findings.md:141-150`; that is the LAN area's to carry). Its only note on saved files is small runtime costs: the settings file re-parsed every frame after 45 s and two uncapped logs (`audit/2026-11-07/findings.md:196`); both are unchanged at the baseline (F-SAVES-09, F-SAVES-10). It did not test corrupt settings files.
- Saved files are read with the JSON parser only; no saved file is loaded as an engine resource or script (`reads/RR-04.md:259`).

## Exit criteria

| Id | Status | Proof or gap | Measuring tool, and whether it exists |
| --- | --- | --- | --- |
| X-20 Settings survive a restart on Windows and on the Deck | **not measurable today** (code path present; never measured across a restart or on Linux) | Save and load code is in place (F-SAVES-13, -14) and in-process tests pass in the local gate (`gate-full-s415.txt:105`, `:123`). No test ends the process and starts it again; nothing has run on Linux or a Deck; the checks are not in CI (F-SAVES-04, -12). | "Settings round-trip test per platform": **does not exist**. The nearest are `ui/tools/hud_check.gd:5913`, `:6268`, `:7859` and `sim/input/test/remap_test.gd:164-206`, which rebuild objects inside one process. A two-run test (run 1 sets and exits, run 2 reads) on each desktop build is the missing piece; it needs the desktop and Linux builds PERF found missing (F-PERF-01, -02). |
| X-27 Replays verify on their build; a foreign replay is refused plainly | **gap** | Half one: no replay is saved outside LAN (F-SAVES-01), and no verify record exists for a file saved by the baseline build (F-SAVES-03). Half two: a foreign replay with other data, format or input layout is refused without a crash and CI tests it (F-SAVES-16); one with the same data and other code is not refused up front (F-SAVES-02); the refusal is a reason code printed by a tool, not a plain message to a player (`tools/preview/blackbox-verify.mjs:41`). | "Build id in the replay": **exists in the wrappers only** (`net/lan.gd:511`; `tools/preview/blackbox.mjs:383`), not in the replay header. "A test loads a foreign replay": **exists for data and format** (`sim/core/tools/parity.gd:3560-3581`), **not for a build id**. Verify tools exist: `tools/preview/blackbox-verify.mjs`, `tools/preview/lan-report.mjs`, `sim/core/tools/replay_xproc_check.gd` (CI, `.github/workflows/ci.yml:207-209`). |

Neither criterion has a "proposed" number to confirm. One suggestion for X-27's wording: say where the refusal is shown (a tool line for Alpha is enough, since the game has no replay viewer and none is in Orb's Alpha definition).

## Findings

| id | kind | statement | evidence | criterion | severity | alpha | owner | cost | hash |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F-SAVES-01 | gap | A match in the solo, couch or any other non-LAN desktop game saves no replay: the only recorder outside LAN is a patch the private browser page applies to a scratch copy of the host. | `tools/preview/blackbox.mjs:2`, `:4`; no recorder hook in `render/`, `sim/`, `ui/`, `net/` at 8901d351 (git grep); `net/lan.gd:492-519`; `ui/tools/hud_check.gd:8992` | X-27, X-21 | major | required | tools-pipeline (with rendering-techart, simulation-engine, ui-ux) | S | false |
| F-SAVES-02 | gap | The replay names no build: a replay from a build with the same data but different code is not refused up front and only fails later as a state mismatch. | `sim/core/replay.gd:5`, `:43`, `:118-119`, `:135-136`, `:160-161`; `net/lan.gd:511`; `tools/preview/blackbox.mjs:383` | X-27 | major | required | simulation-engine (with netcode-online, tools-pipeline) | S | false |
| F-SAVES-03 | gap | No record shows a replay saved by the baseline build verifying to its last tick on that build, and the first real LAN save has not been put through the report tool. | `docs/qa/runs/6a30b4c9/README.md:5` (replayed for traces, no verify line); no "BLACKBOX OK" under `docs/*/runs/6a30b4c9`; `questions.md:16`; `tools/preview/blackbox-verify.mjs:5` | X-27 | major | required | qa-balance (with tools-pipeline, netcode-online) | S | false |
| F-SAVES-04 | gap | Settings surviving a restart has never been tested across a real restart, on Windows or Linux; the tests rebuild the screen inside one process and run in the local gate, not CI. | `ui/tools/hud_check.gd:5913`, `:6268`, `:7859`; `docs/ep/runs/6a30b4c9/gate-full-s415.txt:123`; `.github/workflows/ci.yml` (no hud_check or remap_test line) | X-20 | major | required | ui-ux (with controls-feel, tools-pipeline, performance-platform) | S | false |
| F-SAVES-05 | gap | On main the Reduce flashing lock is off, so a saved Off is read back at start-up, and every build shares one settings folder, so an Off saved in an earlier build carries into a later one. (Off the owner's page.) | `ui/data/features.json:12`; `ui/core/ui_data.gd:427-428`; `ui/hud/ui_hud.gd:2484-2495`, `:1622`; `project.godot:8` | X-02, X-20 | major | required | ui-ux (with legal-ip, accessibility-localization) | S | false |
| F-SAVES-06 | gap | The settings and controls files are overwritten in place, so a write cut short leaves an unreadable file and every remembered choice silently returns to default. | `ui/core/ui_prefs.gd:33-38`, `:10-17`; `sim/input/remap.gd:420-425`; contrast `sim/world/field_cache.gd:208-213` | X-20 | minor | nice | ui-ux (with controls-feel) | S | false |
| F-SAVES-07 | gap | Neither settings file can change shape between builds: no version in the settings file, and a controls file with another schema number is treated as absent and overwritten. | `ui/core/ui_prefs.gd:10-17`; `sim/input/remap.gd:412-417`; `sim/input/input_data.gd:372-380` | X-20 | minor | nice | controls-feel (with ui-ux) | S | false |
| F-SAVES-08 | gap | Three loaders do not check the types of what they read (a replay's seed, ticks, toggles, checkpoints; a controls file's entries; a slider option saved as text); what an exported build does with such a file is not evidenced. | `sim/core/replay.gd:138`, `:140-141`, `:152-153`; `sim/input/remap.gd:435-439`; `ui/core/ui_data.gd:330-346`; `qa/godot/trace_replay.gd:13-17` | X-27, X-20 | minor | nice | simulation-engine (with controls-feel, ui-ux, qa-balance) | S | false |
| F-SAVES-09 | gap | The settings file is opened and parsed again on per-frame paths, as the safety audit noted; unchanged at the baseline. | `ui/hud/ui_hud.gd:4171`, `:4205`, `:4213`; `ui/core/ui_prefs.gd:10-21`; `audit/2026-11-07/findings.md:196` | X-24 | minor | nice | ui-ux (with performance-platform) | S | false |
| F-SAVES-10 | gap | LAN match files and the LAN log grow without a cap, in a folder beside the program. | `net/lan.gd:48`, `:492`, `:520-530`, `:423`; `audit/2026-11-07/findings.md:196` | X-21, X-25 | minor | nice | netcode-online (with tools-pipeline) | S | false |
| F-SAVES-11 | gap | Where the game keeps its files is written nowhere a tester would read, and the folder is the engine default named after the working title, so a change of title leaves settings behind. | `project.godot:8`; `reads/RR-04.md:15`; `ui/core/ui_prefs.gd:7`; `sim/input/remap.gd:13`; `sim/world/field_cache.gd:37` | X-32, X-20 | minor | nice | tools-pipeline (with legal-ip, community-marketing) | S | false |
| F-SAVES-12 | gap | The checks that guard saved files (settings and remap persistence, the controls file, the cache's tamper cases) are not in CI; the only saved result at the baseline is the local gate output. | `.github/workflows/ci.yml` (none named); `docs/ep/runs/6a30b4c9/gate-full-s415.txt:105`, `:123`; `sim/world/tools/field_cache_check.gd:98-124` | X-20, X-02 | minor | nice | tools-pipeline (with ui-ux, controls-feel, world-environment) | S | false |
| F-SAVES-13 | works | A Settings choice is written at once and applied at the next start; unknown keys are skipped and bad values pulled to valid ones. | `ui/hud/ui_hud.gd:2473-2478`, `:2484-2495`; `render/core/main.gd:215`; `ui/core/ui_data.gd:328-346`; `gate-full-s415.txt:123` | X-20 | none | n/a | ui-ux | n/a | false |
| F-SAVES-14 | works | Remaps are saved per player and applied at start-up; unknown or retired layouts and actions are dropped and listed. | `sim/input/remap.gd:412-425`, `:430-446`; `sim/input/input_data.gd:372-380`, `:410`; `ui/core/ui_remap_model.gd:182`; `gate-full-s415.txt:105` | X-20 | none | n/a | controls-feel | n/a | false |
| F-SAVES-15 | works | A missing, unreadable or non-dictionary settings or controls file means "nothing remembered"; the menu's saved choices are clamped. | `ui/core/ui_prefs.gd:10-17`; `sim/input/remap.gd:412-417`; `ui/hud/ui_hud.gd:1613-1629` | X-20 | none | n/a | ui-ux | n/a | false |
| F-SAVES-16 | works | Playback refuses, without running, another format, version or input layout, a malformed input, a missing slot, and other data; CI tests each. | `sim/core/replay.gd:116-136`, `:146-148`; `sim/core/tools/parity.gd:3560-3581`, `:4027`; `.github/workflows/ci.yml:191` | X-27 | none | n/a | simulation-engine | n/a | false |
| F-SAVES-17 | works | Replays recorded in one process play back in a fresh one, in CI with a negative control; the baseline's local gate has the pass. | `.github/workflows/ci.yml:207`, `:209`; `gate-full-s415.txt:221`, `:222` | X-27 | none | n/a | simulation-engine | n/a | false |
| F-SAVES-18 | works | A LAN match file names its build in its body and file name, and the browser page's match file is stamped with its build. | `net/lan.gd:511`, `:523-524`, `:541-545`; `net/tools/lan_kit.mjs:117`; `tools/preview/blackbox.mjs:383-386`; `tools/preview/lan-report.mjs:171-173` | X-27 | none | n/a | netcode-online | n/a | false |
| F-SAVES-19 | works | Two LAN PCs cannot start a match on different data: the shared match key includes the replay's data hash. | `net/handshake.gd:109-114`; `sim/core/replay.gd:176` | X-08, X-27 | none | n/a | netcode-online | n/a | false |
| F-SAVES-20 | works | The planet cache is keyed by data hash and engine version, checksummed, spot-checked on load, written through a temporary file, and pruned. | `sim/world/field_cache.gd:40-42`, `:112-145`, `:208-213`, `:222-230`; `data/biomes/field.json:24` | X-11 | none | n/a | world-environment | n/a | false |
| F-SAVES-21 | works | Saved files are plain JSON read with the JSON parser only, none is loaded as code or an engine resource, and nothing sends a saved file anywhere. | `reads/RR-04.md:259`, `:420`; `ui/core/ui_prefs.gd:16`; `sim/input/remap.gd:414`; `audit/2026-11-07/findings.md:148` | X-21, X-32 | none | n/a | simulation-engine | n/a | false |
| F-SAVES-22 | works | With the Reduce flashing lock on, a saved Off is ignored on load and no screen can write Off; a test covers it. (Off the owner's page.) | `ui/hud/ui_hud.gd:2474-2475`, `:2492-2493`, `:1776-1777`; `ui/tools/hud_check.gd:7652-7658` | X-02 | none | n/a | ui-ux | n/a | false |

Cost basis for every gap: estimate, no comparable (no recorded job of this kind was found under `docs/ep/proposals/`). Owner notes: `sim/input/` is Controls' by its owns line (`DIRECTORS.md:397`), `ui/` is UI's (`:372`), `net/` Netcode's (`:422`), `tools/` and `.github/` Tools' (`:472`), `sim/core/` Simulation's (`:170`), `render/core/` Rendering's (`:647`). `project.godot` has no owns line; F-SAVES-11 is placed with Tools because the packaging text that would carry the folder's location is theirs.

## Gaps the questions missed

1. **Most Alpha modes record nothing (F-SAVES-01).** The questions assume replays exist. They exist for LAN matches and for the private browser page only. A Deck tester playing solo, couch or horde leaves no match file, so a report from those modes can carry no replay, and X-27 says nothing about them.
2. **No verify record for the baseline (F-SAVES-03).** The tools exist; the saved output does not. QA replayed the owner's two play files on the build's own tree to trace beams, which shows they play, but the page records no "reproduces to the last tick" line.
3. **One settings folder for every build (F-SAVES-05, -11).** Old and new builds, solo and LAN, read and write the same two files. That is convenient, and it is also how a comfort setting saved under one build's rules arrives in another.
4. **In-place writes (F-SAVES-06)** and **no shape versioning (F-SAVES-07)**: small today, cheap to close before testers have files worth keeping.
5. **Persistence checks outside CI (F-SAVES-12).** CI ran nothing for a day and a half earlier this month (`CLAUDE.md`, conventions); these checks would not have run even when CI was healthy.
6. **Leftover of a backburner item: none found in this area.** No saved file stores the hero or villain meters or a signature variant.

## Not evidenced

| What could not be checked | The one measurement that would settle it |
| --- | --- |
| The user folder's real path on Windows and on a Steam Deck, and that it is writable there | Start the Linux build once on a Deck, change one setting, list the folder |
| Settings and remaps survive a real restart on either platform | A two-run test per desktop build: run 1 sets and exits, run 2 reads |
| A settings or controls file from an older build loads in a newer build | Keep one pair of files from the baseline build and load them in the candidate |
| What an exported build does with a wrong-typed controls file, a slider saved as text, or a replay missing `seed` or `checkpoints` (stops, skips, or carries on) | Feed five broken files to each loader in a headless run and save the output |
| Whether the start menu's saved checkboxes (shake, captions, hints) can undo a later change made on the Settings screen at the next Start (`ui/hud/ui_hud.gd:1623-1625`, `:1778-1782`) | One scripted sequence in `hud_check`: set on Settings, restart, press Start, read the option |
| The Reduce flashing lock's value inside the baseline build's packed data (the kept tree has no `ui/data/features.json`) | Read the key from the build's pack, as Tools' pack check does for other keys |
| A replay saved by 6a30b4c9 verifies to its final hash on 6a30b4c9 | `tools/preview/blackbox-verify.mjs` on one of the owner's two play files with the kept tree; `lan-report.mjs` on the first real LAN save |
| CI's result on 8901d351 | `gh run list` returned no rows in this session; read the run when it is visible |
| The disk size of the planet cache at its kept count of 24 | List the folder after 24 different planets |

## Decisions for Orb

1. **Should every desktop match keep its replay on the player's own PC automatically (the last 20 or so, nothing sent), so any report can include the match?** Recommended: yes. It is what makes "report a problem" useful for solo and couch play, and the recorder already exists for the browser page.
