# NET: netcode (Alpha audit, phase 2)

Baseline 8901d351; game code is the played build's, 6a30b4c9. Read-only review. No file cited below is in `baseline-status.txt`. Files under `homework/Files/builds/` are untracked kept builds, cited as `build:<folder>:<file>`; the home-network address in them is not copied here.

## Summary

- **Works:** the rollback netcode, its state checks and the home-network hardening pass CI with broken-on-purpose control runs (`ci:43553420852`), and two real Windows PCs have played LAN 1v1 and a team 2v2 with every state check matching (2026-11-07 and 2026-11-08 builds).
- **Does not:** LAN is a private Windows-only folder made by patching a scratch copy; it has no menu, no rematch, no Linux build, and its status messages live in the window's title bar.
- **Not proven on the played build:** no two-PC record exists for 6a30b4c9, no real saved LAN match exists, and the report folder has never been made from one.
- **Biggest gap:** X-08 cannot be measured today as written, and LAN cannot be handed to an outside tester; whether it must be is Orb's decision.

## Questions and answers

**Q1. LAN 1v1 and 2v2: what's proven on two real PCs, and what only in tests?**

Proven on two real PCs (both Windows):
- 2026-11-07, build a8bc66e2: three connections; both PCs' logs end at 690 state checks matched near tick 41,440; no "OUT OF STEP" line. The log shows "You're out" lines, so the team 2v2 was played (`build:orb-lan-a8bc66e2-c:lan-log-old.txt`, `lan-log-main (old PC).txt`). Orb: "both lan tests worked right out of the box" (`docs/ep/vision.md:1660`) and "the 2v2 together was the only 2v2 test we performed. there were some stuttering issues" (`docs/ep/vision.md:1662`).
- 2026-11-08, build 091dfac9: the main PC's log reaches tick 43,103 with 718 checks matched, no "OUT OF STEP" (`build:orb-lan-091dfac9:lan-log-main.txt`). Which mode it was: not evidenced (the log line of that build does not say).
- Two different processors computed one seeded match identically with no network (`docs/perf/oldpc-result-2026-11-01.md:11-12`).

Only in tests:
- The played build, 6a30b4c9: nine rows with the other PC simulated in the same program, no socket opened (`docs/net/runs/6a30b4c9/lan-folder/README.md:5`, `lan-loop-rows.txt`). Its `saved` folder holds only a note. No two-PC record.
- 2v2 "apart" (nothing crosses between the two fights): never played on two PCs (`docs/ep/vision.md:1662`).
- A dropped PC, hostile packets, an oversized wait: `net/tools/lan_check.gd:374-397`, `:599-620`, in CI.
- A real link between two programs: CI only, on one Linux machine at 127.0.0.1, with scripted players (`.github/workflows/ci.yml:377-382`).
- Rematch: does not exist (`net/tools/lan_words.txt:38`; F-MODES-05).

**Q2. Determinism across machines and across Windows and Linux. Is a Windows PC against a Deck expected to work at Alpha? Is the sim's own maths used everywhere it must be?**

- Across machines: yes for one pair of x86-64 Windows PCs (above). The doc itself says "not ARM, not another OS" (`docs/perf/oldpc-result-2026-11-01.md:14`).
- Across Windows and Linux: indirect only. The Linux CI job and the local Windows gate both compare with the same expected hashes (`ci:43553420852`, job "Godot headless checks"; `docs/ep/runs/6a30b4c9/README.md:6`), using the editor program, not exported builds. `docs/net/rollback.md:214` records native x64 and the web as proven and ARM as not.
- A Windows PC against a Deck: **not possible today and never run.** The kit exports the Windows preset only (`net/tools/lan_kit.mjs:120`), the Linux preset leaves the network folder out (`export_presets.cfg:101`), and the launchers are Windows scripts. No record states it is expected at Alpha: a decision for Orb (below).
- The sim's own maths: the lint scans `sim/core`, `sim/director`, `sim/world`, `sim/input` (`tools/lint-determinism.mjs:21`) for the engine's trig, PI, random numbers and clocks, runs in CI with a self-test (`.github/workflows/ci.yml:84-86`), and its allow list is empty (`tools/determinism-allow.json`). It has no rule for `pow`, `exp` or `log`; a `git grep` of the four folders finds no bare use today (only the project's own definitions at `sim/core/detmath.gd:87`, `:109`, `:127`). The nightly native-against-web comparison passes (`ci:43414223230`).

**Q3. Open hardening from the corrective plan (CD-10): delay cap, input validation, a dropped-PC notice.**

All three are in the code since 4890bdd9 (2026-11-08) and tested in CI:
- Delay cap: a proposal over 8 ticks fails the handshake with a reason (`net/handshake.gd:25`, `:88-91`). Leftover: a negative proposal is not refused and leaves the start waiting (F-NET-10; traced, not run).
- Input validation: every game packet is checked for field kinds, counts and reach, and dropped whole if bad (`net/host.gd:120-122`, `:154-186`); only `bytes_to_var` decodes, so no object can be made from a packet (`net/transport.gd:20`, `:68`).
- Dropped-PC notice: after the link closes or 8 seconds of silence the computer takes the gone PC's fighter and a banner shows several times over 15 seconds (`net/lan.gd:45-47`, `:459-476`).
- Still open: encryption (plain ENet, `net/enet_transport.gd:38`), needed only before internet play. The plan's own row has no status written (`docs/ep/corrective-plan-2026-11-07.md:18`).

**Q4. The LAN folder's setup for a tester: firewall steps, finding the other PC, could an outside tester do it without help?**

No. Today's steps (`build:orb-lan-6a30b4c9:READ ME FIRST.txt`, from `net/tools/lan_words.txt`):
- The folder is built on the PC that hosts, with that PC's address written into every shortcut (`net/tools/lan_kit.mjs:12-19`, `:127`). There is no search for the other PC; if the address changes, the fix is "Tell the EP" (`net/tools/lan_words.txt:42`).
- An administrator firewall step before play and its removal afterwards (`net/tools/lan_kit.mjs:160-193`). Whether the rule stops Windows' own prompt is, in the folder's words, untested (`net/tools/lan_words.txt:35`).
- The program is unsigned, so the second PC gets a Windows warning to click through (`net/tools/lan_words.txt:18`).
- The folder is copied by hand to the second PC (`net/tools/lan_words.txt:17`). Windows only.
- Legal's terms allow only Orb and Orb 2, with nobody else in the room (`net/tools/lan_words.txt:5`; `docs/legal/review-log.md:259`, `:282`); the kit stops if that line is changed (`net/tools/lan_kit.mjs:196`).

So LAN is "Orb and Orb 2 only" as built. What would change that: LAN inside the normal desktop build and menu (F-MODES-04), a way to find or type the other PC, a Linux build, in-game status messages, and a Legal ruling for outside testers on a network mode (F-LEGAL-04).

**Q5. The report folder from both PCs.**

- Each PC saves `lan-<commit8>-<main|old>-<time>-<reason>.json` beside the game at the end, at each pause, on closing and on a report press (F9, or View and RB), with the replay, checkpoints, marks, slow frames and the build's commit (`net/lan.gd:481-538`). CI plays saved matches back (`net/tools/lan_check.gd:425-429`, `:628-635`).
- "Make my report folder" gathers both PCs' files, films clips and zips them (`docs/tools/lan-report.md:9`, `:26`). It runs Node on this repository's tool by a fixed path, so it works on Orb's main PC only (`docs/tools/lan-report.md:34`), and the second PC's files are carried over by hand.
- **Never done for real:** "a real LAN save: none exists yet" (`docs/tools/lan-report.md:33`), and none is in the kept folders.

**Q6. Confirm LAN is the only network mode for Alpha; online is after launch.**

Confirmed in code and record. The only sockets under `net/` are ENet's, UDP port 47100 (`net/lan.gd:25`, `:352`; `reads/RR-04.md:321-358`). Orb: online is after launch (`docs/ep/vision.md:32`). Groundwork for online (spectator, take-over, a bench) is present and unused (F-NET-15).

## Exit criteria

| Id | Status | Proof or gap | Measuring tool, and whether it exists |
| --- | --- | --- | --- |
| X-08 | **Gap** | 1v1 and team 2v2 matched every state check on two real PCs on older builds (F-NET-18), but: no two-PC record on the candidate's code (F-NET-01); 2v2 apart never played (F-NET-09); one match per launch, so "five full matches" means ten launches per mode (F-MODES-05); the gone-PC notice comes at 8 s of silence, not 5 (F-NET-04); a pulled cable has never been tried. | The LAN log's "checks matched" count and "OUT OF STEP" line: **exists** (`net/lan.gd:377-378`, `:417`). Saved matches: **exist**, never made for real. Report folder: **exists, unproven** (F-NET-06). Pulled-cable trial: **missing**; `lan_check` simulates silence only. |
| X-27 | **Gap (met in part)** | A replay is refused on another format, input version or data hash (`sim/core/replay.gd:116-136`); LAN saves carry the build's commit (`net/lan.gd:511`) and CI plays them back (F-NET-23). But the replay has no build id, same-data builds are not refused (F-NET-08), a plain message to a player is not evidenced, and no real LAN save has been verified. | "Build id in the replay": **missing** from the replay itself; present beside it in the LAN save. A foreign-replay test: **exists for data and format** (refusal reasons), **missing for build**. |

Numbers marked proposed:
- **Five full matches each:** keep. The 2026-11-07 and 2026-11-08 sessions each ran over 40,000 ticks with about 700 checks, so five matches gives a few thousand state checks per mode.
- **Notice within 5 seconds:** change to **10 seconds**, or lower the constant. The code waits 8 s (`net/lan.gd:45`) and the hand-over to the computer cannot be undone: a PC that comes back "finds the match parted" (`net/lan.gd:457-458`), so a short limit risks dropping a PC that only stalled. Orb's old PC has shown single frames near 190 ms (`docs/perf/oldpc-result-2026-11-01.md:33`), far under either number, so 5 s is also reachable if preferred.

## Findings

| id | kind | statement | evidence | criterion | severity | alpha | owner | cost | hash |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F-NET-01 | gap | No LAN match on the played build has a record from two real PCs; its records are nine in-program rows, and the real logs are from two older builds | `docs/net/runs/6a30b4c9/lan-folder/README.md:5`, `:9`; `build:orb-lan-6a30b4c9:saved/`; `build:orb-lan-a8bc66e2-c:lan-log-old.txt`; `docs/ep/vision.md:1662` | X-08 | major | required | netcode-online | S | no |
| F-NET-02 | gap | An outside tester could not set up LAN without help: address written in at build time, administrator firewall step, unsigned Windows program, and words that allow only Orb and Orb 2 | `net/tools/lan_kit.mjs:12-19`, `:127`, `:170-184`; `net/tools/lan_words.txt:5`, `:18`, `:42`; `docs/legal/review-log.md:259` | X-08, X-05 | major | required | netcode-online | L | no |
| F-NET-03 | gap | No LAN build for Linux or the Deck, and no Windows-against-Linux match has ever run | `net/tools/lan_kit.mjs:28`, `:120`; `export_presets.cfg:101`; `docs/net/rollback.md:214` | X-08, X-05 | major | required | netcode-online | M | no |
| F-NET-04 | gap | A silent PC is declared gone after 8 seconds, not X-08's 5, and no real pulled-cable trial is on record | `net/lan.gd:45`, `:459-466`; `net/tools/lan_check.gd:608-620` | X-08 | major | required | netcode-online | S | no |
| F-NET-05 | gap | Every LAN status except a dropped PC shows only in the window's title bar, and a detected state mismatch writes no report of its own | `net/lan.gd:371-395`, `:402-408`; `net/desync.gd:375`; `net/tools/desync_check.gd:341` | X-08 | major | required | netcode-online | S | no |
| F-NET-06 | gap | The report folder from both PCs has never been made from a real LAN save, and its shortcut works only on Orb's main PC | `docs/tools/lan-report.md:33`, `:34`, `:26`; `build:orb-lan-6a30b4c9:Make my report folder.cmd:3` | X-08, X-21 | major | required | tools-pipeline | S | no |
| F-NET-07 | gap | LAN reaches the game only through text patches to a scratch copy, and neither the kit nor the patched game's window, menu and pads are run by CI | `net/tools/lan_kit.mjs:30-39`, `:43-60`; `docs/net/lan-v1.md:120-125` | X-08, X-05 | major | required | netcode-online | M | no |
| F-NET-08 | gap | A replay has a data hash but no build id, so a replay from a same-data build with different code is run and fails at a checkpoint instead of being refused in plain words | `sim/core/replay.gd:43`, `:116-136`; `net/lan.gd:506-512`; `docs/tools/lan-report.md:17` | X-27 | major | required | simulation-engine | S | no |
| F-NET-09 | gap | LAN 2v2 was played on two PCs only in its team form on the 2026-11-07 build; the apart form has no real record | `docs/ep/vision.md:1662`; `build:orb-lan-a8bc66e2-c:lan-log-main (old PC).txt` | X-08 | minor | required | netcode-online | S | no |
| F-NET-10 | gap | The handshake refuses a wait above 8 ticks but not a negative one, which leaves the start on Waiting with no message (traced, not run) | `net/handshake.gd:88-93`, `:98-100` | none | minor | nice | netcode-online | S | no |
| F-NET-11 | gap | The LAN link is unencrypted; fine at home, required before internet play | `net/enet_transport.gd:38`; `audit/2026-11-07/findings.md:145` | none | minor | after | netcode-online | M | no |
| F-NET-12 | gap | The corrective plan's LAN hardening row has no status though the work is in code and CI | `docs/ep/corrective-plan-2026-11-07.md:18`; `commit:4890bdd9` | none | minor | nice | ep | S | no |
| F-NET-13 | gap | The determinism lint has no rule for the engine's pow, exp or log (none is used in the sim today) | `tools/lint-determinism.mjs:24-37`; `sim/core/detmath.gd:127` | X-08 | minor | nice | tools-pipeline | S | no |
| F-NET-14 | gap | The Web preset does not leave out the network folder, so the browser pack carries unreached network scripts, 26 test scripts among them | `export_presets.cfg:11`; `docs/net/runs/6a30b4c9/lan-folder/README.md:10` | none | minor | nice | tools-pipeline | S | no |
| F-NET-15 | gap | Online groundwork (spectator, take-over proposal, a bench that estimates a phone) is kept and tested in CI with no Alpha use | `net/spectator.gd:3-6`; `net/session.gd:328`; `.github/workflows/ci.yml:301-304` | none | minor | after | netcode-online | S | no |
| F-NET-16 | works | Rollback, mismatch, transport, handshake and two-program ENet checks pass in CI with control runs | `ci:43553420852`; `.github/workflows/ci.yml:294-382` | X-08 | none | n/a | netcode-online | n/a | no |
| F-NET-17 | works | The corrective plan's hardening is in code and tested (cap, packet checks, gone PC handed to the computer with a banner) | `net/handshake.gd:88-91`; `net/host.gd:154-186`; `net/lan.gd:459-476`; `net/tools/lan_check.gd:599-620` | X-08 | none | n/a | netcode-online | n/a | no |
| F-NET-18 | works | Two real PCs played LAN with every state check matching: 690 on both logs (2026-11-07), 718 on the main PC's (2026-11-08) | `build:orb-lan-a8bc66e2-c:lan-log-old.txt`; `build:orb-lan-091dfac9:lan-log-main.txt`; `docs/ep/vision.md:1660` | X-08 | none | n/a | netcode-online | n/a | no |
| F-NET-19 | works | The played build's LAN folder passed nine in-program rows and its packed data equals the solo build's | `docs/net/runs/6a30b4c9/lan-folder/lan-loop-rows.txt`; `README.md:9-10` there | X-08 | none | n/a | netcode-online | n/a | no |
| F-NET-20 | works | Two different processors agreed on all 90 lines of the no-network two-PC check | `docs/perf/oldpc-result-2026-11-01.md:11-12` | X-08 | none | n/a | netcode-online | n/a | no |
| F-NET-21 | works | The determinism lint and self-test run in CI with an empty allow list; nightly native-against-web passes | `.github/workflows/ci.yml:84-86`; `tools/determinism-allow.json`; `ci:43414223230` | X-08 | none | n/a | tools-pipeline | n/a | no |
| F-NET-22 | works | The folder is held to the home network (private real-adapter address, /24 filter, one-port rule with removal, address kept out of the log) | `net/tools/lan_kit.mjs:13-19`, `:181`; `net/lan.gd:354-357` | none | none | n/a | netcode-online | n/a | no |
| F-NET-23 | works | Each PC saves the match with replay, checkpoints and build commit, and CI plays saved matches back | `net/lan.gd:481-538`; `net/tools/lan_check.gd:628-635` | X-27, X-21 | none | n/a | netcode-online | n/a | no |
| F-NET-24 | works | Two PCs on different data, setup, seed or protocol cannot start a match | `net/handshake.gd:82-87`, `:112-114` | X-08, X-27 | none | n/a | netcode-online | n/a | no |
| F-NET-25 | works | The kit locks reduce-flashing on and stops if it did not lock (off the owner's page) | `net/tools/lan_kit.mjs:109-115` | X-02 | none | n/a | netcode-online | n/a | no |
| F-NET-26 | works | LAN is the only network mode in the code; online is after launch | `reads/RR-04.md:321-358`; `net/lan.gd:25`; `docs/ep/vision.md:32` | none | none | n/a | netcode-online | n/a | no |

Cost bases: F-NET-02 uses `docs/ep/proposals/co-op-2v2.md:36` (one LAN co-op piece "with what else a human needs" at about 5.5M tokens); the rest are estimates with no comparable. No finding changes the sim's state hash: everything here is in `net/`, tools, records or the replay's wrapper.

Related findings in other areas, not repeated: F-MODES-04 (LAN is a separate private program), F-MODES-05 (no rematch), F-MODES-10 (one 2v2 line-up, the partner's fight not drawn), F-MODES-11 (seed, planet and fighters fixed), F-LEGAL-04 (no ruling for outside testers on LAN), F-PERF-03 (no Linux LAN build path).

## Gaps the questions missed

- **Status in the title bar (F-NET-05).** "Waiting for the other PC", "Couldn't connect", "Couldn't start", "OUT OF STEP" and "The match is over" are window-title text (`net/lan.gd:407-408`). Only the dropped-PC case and "REPORT SAVED" use an in-game banner (`net/lan.gd:475`, `:487`).
- **A mismatch leaves no report of its own (F-NET-05).** The writer that names the first differing fields is called only from its test (`net/desync.gd:375`; `net/tools/desync_check.gd:341`). The LAN code sets no mismatch callback; the next save still holds the replay.
- **Replays have no build id (F-NET-08),** which X-27 names as the tool to build.
- **The kit is untested glue (F-NET-07).** It stops if a patched line changed (`net/tools/lan_kit.mjs:35`), which is safe, but nothing runs it between LAN folders.
- **The lint's blind spot (F-NET-13)** matters more once a second operating system plays.
- **The plan's record is behind the code (F-NET-12).**

## Not evidenced

| What | One measurement that would settle it |
| --- | --- |
| LAN on the played build between two real PCs | Five matches per mode from the 6a30b4c9 folder; both PCs' logs and `saved` folders brought back |
| Time from a pulled cable to the banner on each PC | One trial with a stopwatch, or the log's time stamps on both PCs |
| How soon ENet itself reports a closed link (no timeout is set in `net/enet_transport.gd`) | The same trial: which fires first, the link closing or the 8 s rule |
| Whether the firewall rule stops Windows' own prompt (`net/tools/lan_words.txt:35`) | Orb's answer after the next session |
| Whether Orb's stutter of 2026-11-07 (deepest rollback 20 in that log) is gone after the later tuning (`net/lan.gd:38-42`) | The frames part of the next real log: worst frame, frames over 50 ms, most re-run |
| Windows against Linux on exported builds | The no-network two-PC check (`docs/net/two-pc-check.md`) run once on a Deck and once on a Windows PC from one kit |
| Which mode the 2026-11-08 session played | Not recoverable from the log; the next logs carry the mode in the saved file |
| A negative wait proposal hanging the start (F-NET-10) | One row in `lan_check`'s hostile set |
| CI on 6a30b4c9 itself | `gh run list --commit` returned nothing for it; the nearest full success with the same game code is `ci:43553420852` (35cc89e9) |

## Decisions for Orb

1. **Does LAN stay with you and Orb 2 only for Alpha?** Recommended: yes. Outside testers get the solo and same-PC modes; LAN for them needs a menu entry, a way to find the other PC, a Linux build and a Legal ruling first (F-NET-02).
2. **Should a Windows PC be able to play a Steam Deck over LAN at Alpha?** Recommended: no, Windows to Windows only. Ask for one no-network comparison between a Windows PC and a Deck so the answer is known before Beta (F-NET-03).
3. **How fast must "the other PC has gone" appear?** Recommended: within 10 seconds, keeping today's 8-second rule, because handing the fighter to the computer can't be undone if the other PC only stalled (F-NET-04).
