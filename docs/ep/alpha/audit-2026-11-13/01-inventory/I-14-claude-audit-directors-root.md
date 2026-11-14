# I-14 inventory: .claude/, audit/ (index files), docs/directors/, repository root

- **Slice:** I-14 (claude-audit-directors-root)
- **Covers:** `.claude/` (commands; no tracked skills, agents or settings), `audit/` index files, `docs/directors/` (24 charters + roster README), every root file.
- **Tracked files:** 369 (`.claude/` 7, `audit/` 330 of which 312 under `audit/2026-11-07/evidence/`, `docs/directors/` 25, root 7). Source: `git ls-files`.
- **Total lines:** 26,154 (slice dirs 25,058 + root 1,096; `wc -l`). The bulk is audit evidence (e.g. `audit/2026-11-07/evidence/claims-inventory.json` 6,712), counted, not read.
- **Uncommitted paths (baseline-status.txt):** 3, all untracked (`??`): `.claude/commands/overnight.md` (13 lines, a live command), `a2.txt`, `a3.txt` (root, both 0 bytes). None modified or deleted.
- Also on disk, not tracked and not in baseline: `.claude/scheduled_tasks.lock` (124 bytes, 2026-11-13 19:46), `.claude/worktrees/` (empty, git-ignored `.gitignore:14`). No `.claude/settings.json`, no `.claude/skills/`, no `.claude/agents/`; `.claude/settings.local.json` is git-ignored (`.gitignore:13`).

## Systems

| System | What it does | Files (lines) | Data/schemas | Switches | Tests / CI job | Reached? | Leftovers | Owner |
|---|---|---|---|---|---|---|---|---|
| `/director` command | Turns a session into a director: reads `docs/directors/$ARGUMENTS.md`, renames the session to the charter title, loads SendMessage, waits (`.claude/commands/director.md:5-10`) | `.claude/commands/director.md` (10) | charters in `docs/directors/` | none | none found | yes: each charter's kickoff line, e.g. `docs/directors/art.md:3` | none | unplaced (EP "shared files", `DIRECTORS.md:63`) |
| `/gate` command | EP runs a phase gate: briefs QA, Production Ops, Legal; scores each CLAUDE.md exit criterion pass/fail/not evidenced (`.claude/commands/gate.md:5`) | `.claude/commands/gate.md` (5) | CLAUDE.md roadmap | none | none found | user-invoked only; no file caller found (grep `/gate`) | none | unplaced |
| `/standup` command | EP briefs active directors, collects standard reports, writes one page for Orb, updates risk register (`.claude/commands/standup.md:4`) | `.claude/commands/standup.md` (4) | `docs/production/risk-register.md` (exists) | none | none found | user-invoked only | none | unplaced |
| `/crunch` command | Starts "Orb's stand-in" session that messages the EP, hourly cron at minute 13 (`.claude/commands/crunch.md:4-13`) | `.claude/commands/crunch.md` (80) | memory notes, `docs/ep/vision.md`, `docs/ep/taste.md` | hard-coded EP session id (`crunch.md:6`) | none found | user-invoked only | refers to a dated handover `ep-handover-2026-11-01.md` (`crunch.md:10`) and the 2026-11-01 priorities (`crunch.md:19-20`) | unplaced |
| `/overnight` command | Stand-in forwards the approved tasks in `homework/1 Urgent/0 Overnight plan.md` to the EP; 15-min cron (`.claude/commands/overnight.md:4-13`) | `.claude/commands/overnight.md` (13) **untracked** | `homework/` (git-ignored) | hard-coded EP session id (`overnight.md:11`) | none found | user-invoked; listed as an available skill in this session | file never committed (baseline `??`) | unplaced |
| `/sprint-plan` command | Stand-in, with Orb present, turns a goal into a one-page plan for approval (`.claude/commands/sprint-plan.md:6-20`) | `.claude/commands/sprint-plan.md` (96) | newest `docs/ep/alpha/audit-*/04-path-to-alpha.md` (`sprint-plan.md:20`) | `disable-model-invocation: true` (`:4`) | none found | user-invoked only | none seen in header | unplaced |
| `/sprint` command | Stand-in executes the APPROVED plan page with the EP, stops itself (`.claude/commands/sprint.md:6-20`) | `.claude/commands/sprint.md` (105) | `homework/1 Urgent/0 Plan - next sprint.md` | `disable-model-invocation: true` (`:4`); status-line gate (`:13`) | none found | user-invoked only | none seen in header | unplaced |
| `/alpha-audit` command | Starts this audit as two sessions (`reading` / `judgment`), resume via `progress.md` (`.claude/commands/alpha-audit.md:6-17`) | `.claude/commands/alpha-audit.md` (73) | `docs/ep/alpha/audit-2026-11-13/` | `disable-model-invocation: true` (`:4`); token cap arg (`:18`) | none found | yes: this run (`/alpha-audit reading`) | none | unplaced |
| Director charters | 24 generated role files: session title, model, owned paths, kickoff, duties, report format (e.g. `docs/directors/camera.md:3`) | `docs/directors/*.md` (24 files, 50-59 each) | generator `tools/gen_directors.py` | model per charter | none found; no workflow references `docs/directors` (grep `.github/workflows`) | yes via `/director` | backburnered mechanics in duties: menace/anguish, hiding/ambush, ego abilities, signature variants (see Notable) | unplaced (output of a `tools/` script; tools-pipeline owns `tools/`) |
| Director roster README | Kickoff table: slug, model, effort, session title, first phase (`docs/directors/README.md:14-39`) | `docs/directors/README.md` (39) | generated (`README.md:3`) | none | none found | read by `/gate` and `/standup` (`gate.md:5`, `standup.md:4`) | camera row says sonnet (`:20`) vs charter opus | unplaced |
| Roster generator | Single source that writes DIRECTORS.md, each charter and the roster README (`tools/gen_directors.py:1-3`, `:506-509`) | `tools/gen_directors.py` (not counted; outside slice) | in-file `d(...)` table | `effort()` opus=xhigh else high (`:19`) | none found | manual only (`README.md:65`); no CI caller (grep `gen_directors` in `.github`) | rerun would overwrite hand edits in `camera.md` | tools-pipeline (`DIRECTORS.md:472`) |
| DIRECTORS.md | Roster of EP + 24 directors, report format, activation schedule, duties (`DIRECTORS.md:1-29`) | `DIRECTORS.md` (691) | generated | phases list (`:29`) | none found | read by `/standup` (`standup.md:4`) | menace/hiding/ego/HUD "minimap strip" duties (`:99,152,202,327,331,353,377,380,453,627`); `mods/` owned (`:672`) but folder absent | unplaced (EP shared file) |
| Disclosure pack index | EP's pointer list for the 2026-11-07 independent audit, 8 files (`audit/disclosure/README.md:1-14`) | `audit/disclosure/README.md` (16) + 8 files (15-50 each, 209 total) | none | none | none found | not evidenced | memory path redacted (`README.md:16`, CD-07) | unplaced |
| 2026-11-07 audit record | Auditor's report, findings, false alarms, notice, directive (`audit/2026-11-07/report.md:1-12`) | 9 top-level md (report 72, findings 207, false-alarms 1,175, ir-log 20, post-notice-changes 47, + 4 not wc'd) + 312 evidence files | evidence JSON/txt | none | none found | not evidenced | report flags villain growth from civilian kills (`report.md:9`) | unplaced |
| Project settings | Godot project: name "Orb Combat EX", main scene `res://render/boot_entry.tscn` (exists), Compatibility renderer, `globe_r` shader global (`project.godot:8-26`) | `project.godot` (26) | none | `rendering_method="gl_compatibility"` (`:18-19`); web playback type 0 (`:14`) | path filter in `web-parity.yml:14,23` | yes (engine entry) | comment says Simulation & Engine holds it until Tools takes over (`project.godot:2`) | simulation-engine per file comment (`:2`); DIRECTORS.md: unplaced |
| Export presets | 4 presets: Web, Windows, Linux, macOS with build/ paths and exclude filters (`export_presets.cfg:1-133`) | `export_presets.cfg` (172) | `include_filter="build_info.json"` (`:10`) | exclude lists `:11`, `:55` | `ci.yml:97` (web head block check), `web-parity.yml:15,24` | yes (CI) | Web exclude omits `audit/*`; Windows adds `net/*` but Web does not (`:11` vs `:55`) | unplaced (build/ is tools-pipeline, `DIRECTORS.md:472`) |
| Root docs/config | `CLAUDE.md` (133) brief; `README.md` (30) public page; `.gitignore` (40); `.gitattributes` (4, LF normalise) | as listed | none | `* text=auto eol=lf` (`.gitattributes:2`) | none found | CLAUDE.md loaded by every session | README lists only 3 commands (`README.md:18`); prototype as sanity check (`:30`) | unplaced (EP shared files) |
| Stray root files | `a2.txt`, `a3.txt`, 0 bytes, untracked | 0 + 0 | none | none | none | not evidenced | look like accidental shell redirects | unplaced |

## Charter vs DIRECTORS.md (owned paths)

All 24 charters' `owns:` lines (line 3 of each charter) match the `owns:` lines in DIRECTORS.md (`:92` to `:672`) word for word. One field differs: **camera model** is `opus` in `docs/directors/camera.md:3` but `sonnet` in `DIRECTORS.md:297`, `docs/directors/README.md:20` and the generator (`tools/gen_directors.py:140`). Commit `4bb10168` hand-edited only the charter. Camera's ADR 0010 anti-goal ("Trading the look...") is also in `camera.md` only, not in the generator (grep count 0 in `tools/gen_directors.py`).

| Slug | Owns (charter line 3) | Agrees? |
|---|---|---|
| game-design | docs/design/ | yes |
| combat-choreography | data/atoms/, data/exchanges/, docs/combat/ | yes |
| encounter-systems | sim/director/, data/director/, docs/director/ | yes |
| simulation-engine | sim/core/, docs/architecture/ | yes |
| world-environment | sim/world/, data/biomes/, docs/world/ | yes |
| art | art/, docs/art/ | yes (overlaps animation, vfx under art/) |
| animation | art/animation/, docs/animation/ | yes |
| vfx | render/vfx/, art/vfx/, docs/vfx/ | yes |
| camera | render/camera/, docs/camera/ | paths yes; model no |
| audio-music | audio/, docs/audio/ | yes |
| narrative-identity | docs/narrative/, data/fighters/ | yes |
| ui-ux | ui/, docs/ui/ | yes |
| controls-feel | sim/input/, docs/controls/ | yes |
| netcode-online | net/, docs/net/ | yes |
| qa-balance | qa/, prototype/tools/ | yes |
| tools-pipeline | tools/, build/, .github/ | yes |
| production-ops | docs/production/ | yes |
| legal-ip | docs/legal/ | yes |
| community-marketing | docs/marketing/ | yes |
| performance-platform | docs/perf/ | yes |
| accessibility-localization | docs/accessibility/, localization/ | yes |
| research-prototyping | research/ | yes |
| rendering-techart | render/core/, render/shaders/, docs/rendering/ | yes |
| modding-extensibility | mods/, docs/modding/ | yes (`mods/` does not exist) |

## Notable

1. `.claude/commands/overnight.md` is a live command (shown as an available skill) but untracked (baseline-status.txt `?? .claude/commands/overnight.md`).
2. Camera model drift: charter opus (`docs/directors/camera.md:3`) vs DIRECTORS.md sonnet (`DIRECTORS.md:297`) and generator (`tools/gen_directors.py:140`); rerunning the generator reverts the charter.
3. Charters are generated (`docs/directors/README.md:3`, `tools/gen_directors.py:506-509`) but camera.md carries hand edits not in the generator (git `4bb10168`).
4. Backburnered systems still listed as duties: menace and anguish (`docs/directors/game-design.md:23`, `ui-ux.md:22`, `audio-music.md:21`), hiding/ambush (`encounter-systems.md:24`, `world-environment.md:22`, `qa-balance.md:22`, `audio-music.md:25`), ego abilities (`narrative-identity.md:22`), signature variants by terrain (`world-environment.md:22`), "planet minimap strip" (`ui-ux.md:22`).
5. Phase list still names menace (`DIRECTORS.md:29`, `tools/gen_directors.py:5`).
6. `mods/` is owned (`DIRECTORS.md:672`) but absent from the repo (`ls mods` fails).
7. Hard-coded EP session id `local_2d9e...` in `crunch.md:6`, `overnight.md:11`, `sprint-plan.md:10`, `sprint.md:8`; commands break if the EP session is replaced.
8. README is stale: lists only `/director`, `/standup`, `/gate` (`README.md:18`) of 8 commands; sanity check still points to the JS prototype (`README.md:30`).
9. `audit/2026-11-07/report.md:9` records "the villain gets stronger for every civilian he kills, in the public build too", against design pillar 5.
10. `audit/2026-11-07/report.md:7-8` records CI switched off since 6 Nov by a typo and the take-down switch not working (state as of 2026-11-07; current state not checked here).
11. Web export exclude filter (`export_presets.cfg:11`) omits `audit/*` and the git-ignored local `homework/`; whether any of those files get packed is not evidenced.
12. Windows preset excludes `net/*` (`export_presets.cfg:55`), Web does not (`:11`).
13. `project.godot:2` assigns the file to Simulation & Engine, while DIRECTORS.md has no owner for root files (EP "shared files", `DIRECTORS.md:63`).
14. Root has two empty untracked files `a2.txt`, `a3.txt` (baseline `??`).
15. No tracked `.claude/settings.json`, skills or agents; all eight commands are prompt files only, with no tests and no CI coverage.

## Not covered

- `audit/2026-11-07/evidence/` (312 files) and the bodies of `audit/disclosure/1-8`, `false-alarms.md`, `findings.md`, `claims.md`, `checks-review.md`, `00-notice.md`, `corrective-directive.md`: counted, not read (the brief asked for index files only).
- Bodies of `crunch.md`, `sprint.md`, `sprint-plan.md`, `alpha-audit.md` past line 20: headers only.
- `CLAUDE.md` and DIRECTORS.md duties beyond the owns lines and leftover grep: not re-read in full.
- `.claude/settings.local.json`: git-ignored, per machine, not read.
