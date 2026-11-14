# LEGAL: legal and player safety for outside testers

Alpha audit, phase 2 area page. Baseline 8901d351 (game code as in the last played build, 6a30b4c9: `git diff 6a30b4c9 8901d351` over `sim render ui net audio data` is empty). Read-only review; every line cites a file, record, run or build. "Off the owner's page" marks the flashing topic, which goes to the Executive Producer (EP), not to Orb.

## Summary

- **Works:** the flashing notice before play, Reduce flashing on by default with a lock the packaging tools set, the licences page, bystanders that never die, and a game that sends nothing by itself.
- **Works on paper:** Legal's licence rundown (version 2) and a one-page tester note that covers every paperwork item.
- **Does not work:** no build an outside tester could be given can be made today, and the list of gates such a build must pass did not exist.
- **Biggest gap (off the owner's page):** on the ground the played build shows, the beam-clash scene reads about twice the flash limit even with Reduce flashing on, and the played commit has no reading at all (F-LEGAL-01).
- **Owner decisions waiting:** the licence line, the report channel, whether outside testers get the LAN modes, and the title on a private itch.io page.

## Questions and answers

**Q1. The list of gates that must be green before an outside tester plays (X-02).**
No such list existed before this audit (F-LEGAL-03). Built here from the open corrective items, Legal's rows and the code. "Record" is where the proof is or should be saved for the candidate commit `<sha>`.

| # | Gate | Source | State at the baseline | Record |
| --- | --- | --- | --- | --- |
| G1 | All CI jobs green on the candidate | CD-01, CD-20 | Last green CI is run 42866500996 on 3a03e03f (same game code); the run on 8901d351 (43554356718) was still pending when read | The run id, copied to `docs/tools/runs/<sha>/` (pattern: `docs/tools/runs/3eca67eb/`) |
| G2 | The EP's local gate | CD-22 | Exists for 6a30b4c9: `docs/ep/runs/6a30b4c9/README.md:3` | `docs/ep/runs/<sha>/` |
| G3 | The build's own packed data matches the plan | AQ-05 | Exists for 6a30b4c9: `docs/tools/runs/6a30b4c9/pck-verify.txt` (pointer from `questions.md:7`, not re-read here) | `docs/tools/runs/<sha>/pck-verify.txt` |
| G4 | Flash reading of the candidate, both modes, on the ground players see, inside Legal's limits (RL-203 condition 2: 2.5 / 3 / 2) | RL-203 (`docs/legal/review-log.md:232`), CD-04 | **Red.** Clash reads 6.5 reduced, 5.5 normal (`docs/rendering/runs/d985eb15/crater-look-default.txt:24-25`); no reading on 6a30b4c9 | `tools/flash/release-pass.json` for `<sha>`, and `docs/tools/runs/<sha>/` |
| G5 | The flash measuring chain repaired | CD-09 | **Red.** No commit (`reads/RR-09.md:27`) | Commits, and the self-test in CI |
| G6 | Notice before play; no route skips it | RL-119, RL-206 | Green in code (`ui/widgets/ui_notice.gd:3`, `ui/hud/ui_hud.gd:1530`) | `tools/desktop-package.mjs routes` and `verify` output, saved under `docs/tools/runs/<sha>/` (no saved output exists yet) |
| G7 | Reduce flashing on by default and locked | RL-260 condition (`review-log.md:289`) | Default on (`ui/data/options.json:45`); lock set only by the packaging tools; Tools' confirmation still open | Same as G6 |
| G8 | The owner's recorded yes for desktop test builds | RL-203, CD-12 | **Red.** `docs/ep/approvals/desktop-test-builds.txt` does not exist (`.github/workflows/desktop-builds.yml:54`) | That file, in the candidate commit |
| G9 | README.txt and NOTICES.txt in the package: the flashing notice, the AI line, the privacy line, the engine and font licences | RL-204 | **Red.** The text step reads a draft notice file (F-LEGAL-02); the checks themselves exist (`tools/desktop-package.mjs:282-298`) | `verify` output under `docs/tools/runs/<sha>/` |
| G10 | Nothing leaves the PC unless the tester sends it | X-32, RL-204 | Green by a code read (Q5); the package check covers a build with no network code only (`tools/desktop-package.mjs:211`); no check exists for a LAN-capable build | `routes` output; a new check for LAN builds (missing) |
| G11 | Bystanders never die, and no death count is shown | CD-05, RL-257 | Green (`sim/world/collateral.gd:305`; `tools/world-checks.json:5`, `:17`) | CI world job run id |
| G12 | No personal details or banned words in the public repository | CD-27 | Green: run 43554356728 on 8901d351 | The run id |
| G13 | Report files hold no account names or paths | `docs/legal/alpha-discord-flags.md:6` | **Red.** No check exists (F-LEGAL-06) | A scan result under `docs/tools/runs/<sha>/` (tool missing) |
| G14 | Tester paperwork signed off item by item | X-32 | **Red.** Draft only (F-LEGAL-05) | One row per item in `docs/legal/review-log.md` |
| G15 | Report channel set up privately | `alpha-discord-flags.md:5-7`, `:16` | **Red.** Undecided (F-LEGAL-07) | The owner's line in `docs/ep/vision.md`, and a Legal row |
| G16 | Each tester told, an adult, and acknowledged | `alpha-tester-note.md:11` | **Red.** No mechanism (F-LEGAL-05) | A dated list kept privately by the owner (never in the repository) |
| G17 | Licence line recorded | RL-260 | **Red.** Not recorded (F-LEGAL-10) | `docs/ep/vision.md` |
| G18 | Title on the itch.io page cleared or excused in writing | CD-06, RL-024 | **Red.** Not confirmed (F-LEGAL-09) | A Legal row; `docs/legal/name-screening.md` |
| G19 | LAN modes for outside testers ruled on, if testers get them | RL-230 | **Red.** Not covered (F-LEGAL-04) | A Legal row |
| G20 | Accessibility baseline in the build | CD-14 | See the ACCESS area page | `docs/accessibility/runs/<sha>/` (folder does not exist yet) |

Nine of twenty are green or have a record; G4, G5, G8, G9 and G13 to G19 are red.

**Q2. Player safety and comfort settings: what an outside tester gets by default.**
From `ui/data/options.json`: Reduce flashing on (`:45`), reduced motion off (`:46`), captions on (`:40`), camera shake 2 (`:57`), hit-pause scale 1.0 (`:50`), rumble on (`:53`), colour-vision help off (`:91`), text size 1.0 (`:92`), all volumes 1.0 (`:96-98`), mono off (`:99`). The notice shows once every session with nothing remembered (`ui/hud/ui_hud.gd:1553`). In a locked build the Reduce flashing row is not offered at all (`ui/widgets/ui_settings.gd:88`). The lock itself is off on main (`ui/data/features.json`, `"lock_reduce_flashing": false`) and is set at package time (`tools/desktop-package.mjs:132`, `net/tools/lan_kit.mjs:110`). Read from the kept builds' own data: the LAN build is locked, the solo build is not (build:orb-lan-6a30b4c9 `orb-combat-lan.exe`; build:orb-first-play-6a30b4c9-6627cb9d `web/index.pck`). So the owner's solo copy is not a tester build.

**Q3. The AI disclosure up front.**
Present in three places: the tester note, bold, in its first section (`docs/legal/alpha-tester-note.md:7`); README.txt in a desktop package, checked word for word (`tools/desktop-package.mjs:282`); and the in-game About page (`ui/data/howto.json:88`, `:105`). Not present on the desktop start notice, which carries only the flashing words (`ui/widgets/ui_notice.gd:24`); the web gate does carry it (`tools/site-interim-owner.json:21`). Words for the itch.io page's own AI field are guidance only (`docs/legal/go-to-market.md:28`, `:35`); no Alpha page text is drafted: not evidenced. See F-LEGAL-13.

**Q4. What a tester agrees to.**
The note says it in plain words: 18 or older (`alpha-tester-note.md:11`), private and not to be shared, streamed or clipped (`:12`), play and give feedback only with all rights reserved (`:20`), ideas sent may be used (`:23`), reports go to a private Discord server run by a third party (`:29`), deletion on request (`:30`). It is "Legal's draft ... for Orb to send" (`:3`). Nothing in a build repeats the adults-only or private terms (`git grep` for "adult" and "18 or older" over `ui/data` and the notice file: no hits), and no record says how a tester confirms. Setting up the server is the owner's action and is not done on any record (F-LEGAL-05, F-LEGAL-07).

**Q5. Privacy: confirm from the code that nothing leaves the PC.**
Confirmed by read for the shipped folders (`sim render ui net audio`), tools excluded. (The reading request RR-04 had no answer file, so this was read directly.)
- No web request, web socket or raw TCP/UDP class is used in any game script (`git grep` at the baseline: the only hits are two comments in `net/transport.gd:5`, `:9`).
- The only socket is the LAN link, ENet, bound to an address and port the player's shortcut gives (`net/enet_transport.gd:38`, `:52`), and `net/*` is excluded from the Windows and Linux presets (`export_presets.cfg:55`, `:101`).
- The only hand-off to another program is the feedback button's `OS.shell_open` (`ui/widgets/ui_feedback.gd:288`). Its target is "none" by default, which hides SEND and leaves only COPY REPORT (`ui/data/send.json:4`), and both kept builds read "none" in their packed data. One of the selectable targets is a public issue page (`ui/data/send.json:3`); a tester build must never select it.
- The report text holds build, seed, set-up, time, screen size, operating system name, engine version, settings, tags and typed notes (`ui/widgets/ui_feedback.gd:152-164`): no account name or path.
- Files written: settings (`ui/core/ui_prefs.gd:36`), control remaps (`sim/input/remap.gd:421`), the planet cache (`sim/world/field_cache.gd:170`), and in LAN builds a log and saved matches beside the program (`net/lan.gd:423`, `:520`). A saved match holds no account name, path or address (`net/lan.gd:507-518`).
- Not covered: the engine's own behaviour, the web page shell, and whatever a report script adds around the game's files (F-LEGAL-06).

**Q6. The licence, with a recommendation.**
Legal's rundown version 2 is current (commit 74a46ed4; `docs/legal/guide-licence-rundown.md:3`). It treats code, art/writing/name and sound separately (`:9-15`), lists five options from all rights reserved to copyleft against itch.io, Steam, commercial control and contributors (`:19-27`), and ends with one recommendation (`:40-42`): keep everything all rights reserved through Alpha with a plain permission page, decide about public code at Beta after a lawyer's one-hour read, source-available for code only if it is to be visible, never the permissive pairing. This audit agrees: it matches the owner's wish for commercial control and nothing in a private Alpha forces a choice. What is open: the owner's one line (`:54`; F-LEGAL-10); the permission page and contributor note are offered "on request" and not written (`:55`); older pages still recommend the opposite (F-LEGAL-11); Legal says its note on AI-made work and copyright was last checked in October (`:38`). The repository has no licence file at its root (`git ls-tree` at the baseline), and the build says "License: not chosen yet. All rights reserved for now." (`ui/data/howto.json:98`).

**Q7. Credits and the third-party list inside the exported builds.**
Engine and font: yes. The licences page builds its text from the engine at run time (`ui/widgets/ui_licences.gd:19-28`); the About page names the engine and Open Sans (`ui/data/howto.json:99-100`); the package tool writes NOTICES.txt and refuses a package without the engine and font licences (`tools/desktop-package.mjs:104`, `:297-298`). Sound: effects are synthesised by the project's own code and need no notice (`docs/legal/licence-register.md`, row LR-005); no music ships (`ui/data/features.json`, `"about_music": false`). Credits: "Directed by Orb. Built with AI tools." (`ui/data/howto.json:105`). Not evidenced: a NOTICES.txt from a real desktop package, because the build workflow has never run (F-LEGAL-02).

**Q8. The title's clash with a small project of a similar name.**
Open: RL-024 is "Open [store]" (`docs/legal/review-log.md:53`) and the CD-06 row has no progress (`docs/ep/corrective-plan-2026-11-07.md:14`). The specification's assumption that a restricted itch.io page does not need it is **not confirmed by Legal**: Legal's own page says the formal search comes "before any store page, itch.io page or the first promotion" (`docs/legal/name-screening.md:186`) and the audit directive says "before any store or itch.io page" (`audit/2026-11-07/corrective-directive.md:17`). The only Alpha-era Legal words are that the server be named with "(working title)" and that "the title search is still open" (`docs/legal/alpha-discord-flags.md:13`). See F-LEGAL-09.

**Q9. The content rating.**
The owner's early answer was "Graphic ... Rating target: Mature" (`docs/ep/vision.md:63`); since 2026-11-07 nobody among bystanders dies (`docs/ep/vision.md:1671`; `sim/world/collateral.gd:305`). Legal's notes say a store survey must declare all mature content in the build even if not shown, answered honestly from the real build with a copy kept (`docs/legal/steam-readiness.md:44`), and that boards weigh who the victim is, realism, detail, reward and how optional it is (`docs/legal/guide-stomp-and-ratings.md:8-13`). On today's game that means declaring: frequent stylised fighter-against-fighter violence; large-scale destruction of buildings and terrain; bystanders thrown or scattering without injury or death; no blood or gore found in the UI words (`git grep` for death words over `ui/data`: no hits); and one finisher still in data that its own row calls graphic and Mature (`data/combat/finishers.json:224`). Also for the survey: AI-made content, pre-generated yes and live-generated no (`steam-readiness.md`, rows C1-C2). A restricted itch.io page needs no rating answer: not evidenced either way. The single store-readiness list (CD-13) is not rebuilt (`corrective-plan-2026-11-07.md:21`). See F-LEGAL-14.

## Exit criteria

| Id | Status | Proof or gap | Measuring tool, and whether it exists |
| --- | --- | --- | --- |
| X-02 | **Gap** | The list did not exist (now Q1); 11 of its 20 gates are red, G4 the most serious | The list: now drafted here, to be owned by Legal. Per-gate records: tools exist for G1-G3, G6, G7, G9, G11, G12 (CI, `run-gate.sh`, `desktop-package.mjs`, `content-screen.mjs`); the flash reading tool exists (`tools/flash/run-pixels.mjs`, `release-pass.mjs`) but has no clip set on the ground players see (`corrective-plan-2026-11-07.md:12`); **missing:** a report-file scan (G13) and a sends-nothing check for a LAN-capable build (G10). No `docs/legal/runs/` folder exists; `docs/*/runs/` has 14 areas, none Legal's (`reads/RR-09.md:8`) |
| X-32 | **Gap** | The words exist for every item (F-LEGAL-22) and the notices are in the game (F-LEGAL-20); there is no "sign-off row per item" (one row, RL-260, still open on two conditions: `review-log.md:289`), no agreed acknowledgement step, and the privacy words differ between places (F-LEGAL-12) | Legal's review log exists; the per-item rows do not |

No numbers in these two criteria are marked proposed.

## Findings

Full records, with risk and cost basis, are in `LEGAL.findings.json`. Gaps first.

| id | kind | statement | evidence | criterion | severity | alpha | owner | cost | hash |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F-LEGAL-01 | gap | On the tile ground the played build shows, the beam-clash clip reads 6.5 with Reduce flashing on and 5.5 with it off against a limit of 3, and 6a30b4c9 has no pixel reading. Off the owner's page. | `docs/rendering/runs/d985eb15/crater-look-default.txt:24-25`; `corrective-plan-2026-11-07.md:12`; `render/camera/camera_params.gd:150`; `tools/flash/release-pass.json:3` | X-02 | blocker | required | camera (with rendering-techart, vfx, tools-pipeline) | L | no |
| F-LEGAL-02 | gap | No desktop package for an outside tester can be made today: the approval file is absent, the text step reads a draft notice, and the workflow has never run. | `.github/workflows/desktop-builds.yml:54`; `tools/desktop-package.mjs:31`, `:35`; `tools/site.json:5`; `tools/site-interim.json:3`; `gh run list --workflow desktop-builds.yml`: none | X-02, X-32, X-29 | blocker | required | tools-pipeline (with legal-ip) | M | no |
| F-LEGAL-03 | gap | The before-an-outside-tester gate list did not exist, and several gates have no saved record or no tool. | `alpha-audit-specification.md:169`; `review-log.md:289`; `reads/RR-09.md:49` | X-02 | blocker | required | legal-ip (with tools-pipeline, accessibility-localization) | S | no |
| F-LEGAL-04 | gap | No ruling or package covers an outside tester on the LAN modes: the locked package refuses network code and the LAN folder's terms name only the owner and the trusted second player. | `tools/desktop-package.mjs:211`, `:348`; `export_presets.cfg:55`, `:101`; `review-log.md:259`; `net/tools/lan_kit.mjs:195` | X-02, X-08, X-32 | major | required | legal-ip (with netcode-online, tools-pipeline) | M | no |
| F-LEGAL-05 | gap | The tester note is a draft to send, its row is open on two conditions, and nothing records how a tester confirms being an adult or agrees. | `alpha-tester-note.md:3`, `:11`; `review-log.md:289`; `alpha-discord-flags.md:9` | X-32, X-01 | major | required | legal-ip (with community-marketing) | S | no |
| F-LEGAL-06 | gap | No check strips account names and paths from report files, and the LAN report script points at the owner's own project folder and needs Node. | `alpha-discord-flags.md:6`; build:orb-lan-6a30b4c9 `Make my report folder.cmd`; `net/lan.gd:520` | X-21, X-32 | major | required | tools-pipeline (with legal-ip) | M | no |
| F-LEGAL-07 | gap | The report channel is undecided: the owner spoke of converting an existing server, and Legal's first flag says not to. | `docs/ep/vision.md:1741`; `alpha-discord-flags.md:5`, `:16`; `questions.md:20` | X-21, X-32 | major | required | orb (with legal-ip) | S | no |
| F-LEGAL-08 | gap | The flash measuring-chain repairs (CD-09) have no commit, no reading runs on a schedule, and the newest records are from October on old commits. Off the owner's page. | `corrective-plan-2026-11-07.md:17`; `reads/RR-09.md:27`; `tools/flash/release-pass.json:4`; commit b83782fa | X-02 | major | required | tools-pipeline (with accessibility-localization) | M | no |
| F-LEGAL-09 | gap | Whether a restricted itch.io page may precede the title search is unconfirmed, and Legal's own page says it may not. | `name-screening.md:186`; `corrective-directive.md:17`; `corrective-plan-2026-11-07.md:14`; `review-log.md:53` | X-31, X-32 | major | required | legal-ip | S | no |
| F-LEGAL-10 | gap | The owner's one-line licence choice is not recorded, so the build says "not chosen yet" and no permission page exists. | `guide-licence-rundown.md:54`; `review-log.md:289`; `ui/data/howto.json:98` | X-32 | minor | required | orb (with legal-ip) | S | no |
| F-LEGAL-11 | gap | Three older Legal pages still recommend the permissive pairing the current rundown rules out. | `guide-licence-rundown.md:40`; `pre-store-checklist.md:34`; `steam-readiness.md:37`, `:21` | none | minor | nice | legal-ip | S | no |
| F-LEGAL-12 | gap | The privacy words differ between README, About page and tester note, and no words in a build mention the two-PC link or the report channel. | `tools/desktop-package.mjs:43`; `ui/data/howto.json:102`; `alpha-tester-note.md:28-29`; `review-log.md:233` | X-32 | minor | required | legal-ip (with ui-ux, tools-pipeline) | S | no |
| F-LEGAL-13 | gap | In a desktop build the AI disclosure is not on the first screen; it is in README.txt and on the About page. | `ui/widgets/ui_notice.gd:24`; `ui/data/howto.json:88`, `:105`; `tools/desktop-package.mjs:282` | X-32 | minor | nice | ui-ux (with legal-ip) | S | no |
| F-LEGAL-14 | gap | The rating records disagree with the game, a finisher marked graphic is still in data, and the store-readiness list (CD-13) is not rebuilt. | `docs/ep/vision.md:63`; `sim/world/collateral.gd:305`; `data/combat/finishers.json:224`; `corrective-plan-2026-11-07.md:21` | none | minor | after | legal-ip | S | no |
| F-LEGAL-15 | gap | The repository safety net (CD-11) has no commit or record; its state today is not evidenced. | `corrective-plan-2026-11-07.md:19`; `reads/RR-09.md:29` | none | minor | nice | ep | S | no |
| F-LEGAL-16 | works | The flashing notice is first in a session, has no timeout, shows every session, and a locked build honours no skip word. Off the owner's page. | `ui/widgets/ui_notice.gd:3`; `ui/hud/ui_hud.gd:1530`, `:1553` | X-02 | none | n/a | ui-ux | n/a | no |
| F-LEGAL-17 | works | Reduce flashing is on by default, the packaging tools set the lock, and the kept LAN build's data shows it on. Off the owner's page. | `ui/data/options.json:45`; `tools/desktop-package.mjs:132`; `net/tools/lan_kit.mjs:110`; `ui/widgets/ui_settings.gd:88` | X-02 | none | n/a | tools-pipeline | n/a | no |
| F-LEGAL-18 | works | Nothing in the game's scripts sends data by itself; the feedback target is off by default and in both kept builds. | `net/enet_transport.gd:38`; `ui/widgets/ui_feedback.gd:288`; `ui/data/send.json:4` | X-32, X-21 | none | n/a | ui-ux | n/a | no |
| F-LEGAL-19 | works | Bystanders never die in the sim, and two checks for it are on the world job's list. | `sim/world/collateral.gd:4`, `:305`; `tools/world-checks.json:5`, `:17` | X-02 | none | n/a | world-environment | n/a | no |
| F-LEGAL-20 | works | Credits and third-party notices are inside the game and the package tool writes and checks NOTICES.txt. | `ui/widgets/ui_licences.gd:19`; `ui/data/howto.json:99-100`; `tools/desktop-package.mjs:104`, `:297` | X-32 | none | n/a | ui-ux | n/a | no |
| F-LEGAL-21 | works | Legal's licence rundown is current and answers the specification's question in full. | `guide-licence-rundown.md:3`, `:9`, `:19`, `:40`; commit 74a46ed4 | none | none | n/a | legal-ip | n/a | no |
| F-LEGAL-22 | works | The tester note's words cover every X-32 item. | `alpha-tester-note.md:7`, `:11`, `:12`, `:20`, `:28`, `:29`, `:34` | X-32 | none | n/a | legal-ip | n/a | no |
| F-LEGAL-23 | works | The public test build is down and its daily watch passed on the last three days. Off the owner's page. | `tools/site.json:3`; runs 43505870115, 43310625749, 43103011241 | none | none | n/a | tools-pipeline | n/a | no |
| F-LEGAL-24 | works | The content screen and the workflow lint passed on the baseline commit. | runs 43554356728, 43554356732 | X-02 | none | n/a | tools-pipeline | n/a | no |
| F-LEGAL-25 | works | A saved LAN match file holds no account name, path or network address. | `net/lan.gd:507`, `:518`, `:415` | X-21, X-32 | none | n/a | netcode-online | n/a | no |

Owner notes: `data/combat` has no "owns" line in DIRECTORS.md; the finisher row in F-LEGAL-14 would fall to combat-choreography by charter, named there as a needed director. F-LEGAL-01 is given to camera because the corrective plan names Camera as CD-04's lead (`corrective-plan-2026-11-07.md:12`).

## Gaps the questions missed

1. **There is no tester build at all** (F-LEGAL-02). The specification asks what a tester gets by default; the honest answer is that the only two kept builds are the owner's browser copy (unlocked) and the owner's two-PC folder, and the one pipeline that would make a locked, noticed desktop package is blocked at two steps and has never run.
2. **The package's notice words belong to the public web interim.** The non-draft notice file carries the public interim's row id (`tools/site-interim-owner.json:7`, "RL-161"), and that delegated decision ends on 2026-11-15 (`docs/ep/vision.md:1667`). No notice file is written for a private Alpha, so the words a tester's README would carry are not ones Legal has read for that use.
3. **The safety pipeline and the Alpha's mode list pull against each other** (F-LEGAL-04). Legal's privacy line is "true only while the desktop build makes no network connection" (`review-log.md:233`), and the package check enforces that by refusing `net/` (`tools/desktop-package.mjs:348`); the Alpha wants LAN 1v1 and 2v2. A LAN-capable tester build needs new words, a new check and a ruling before it can pass X-02.
4. **A public issue page is one data word away from a private build.** The feedback panel's targets include a public issue link (`ui/data/send.json:3`, `:23-24`). It is off today. Nothing in the package check refuses a tester build with that target selected: not found in `tools/desktop-package.mjs`.
5. **The last green CI run is not on the baseline.** The CI runs on the three commits before the baseline were cancelled and the baseline's own run was pending when read (runs 43554229393, 43554014217, 43553622347, 43554356718). Game code is unchanged since the green run on 3a03e03f (42866500996), so this is a record gap, not a known failure.
6. **Legal has no runs folder.** Every other gate saves under `docs/<area>/runs/<sha>/`; Legal's sign-offs live only as rows in one long table (488 lines, 77 rows open: 12 private, 35 web, 30 store, by `grep` on `review-log.md`). X-32's "sign-off row per item" needs a place per candidate.
7. **Leftover scope in the open rows.** 35 rows are open against "web", a horizon the Alpha does not use while the public page stays down. They are not Alpha gaps; they should not be read as Alpha blockers either.

## Not evidenced

| What could not be checked | What one measurement would settle it |
| --- | --- |
| The flash reading of 6a30b4c9 in either mode | One run of the pixel reading on the candidate with the tile ground on, both modes, saved under `docs/tools/runs/<sha>/` |
| Whether a real desktop package carries the notices and the lock | One `desktop-builds.yml` run on a candidate, with the `verify` output saved |
| Whether Linux or Steam Deck shows the notice and the licences page correctly | A still of each on a Deck (the tester checklist of X-19 can carry it) |
| What the engine or the operating system sends by itself | A packet capture during one solo match on each platform |
| What a full report folder contains once a script has gathered it | A scan of one real folder from a tester-like account for the account name and home path |
| Secret scanning, push protection and branch protection (CD-11) | The repository's settings page, read by the owner or the EP |
| Whether itch.io needs any content or age answer for a restricted page | Legal reads itch.io's current creator rules and cites them in a row |
| Whether the audit folder or other loose files are packed into an export (`export_presets.cfg:55` does not exclude `audit/*`) | The file list of one exported package |
| Legal's October note on AI-made work and copyright | Legal re-checks and dates it (`guide-licence-rundown.md:38`) |
| RR-04 (the full write-and-send table) | The reading session's answer file; this page read the call sites directly |

## Decisions for Orb

1. **Licence.** Do you agree to keep everything all rights reserved through Alpha, with a short friendly permission page, and decide about public code at Beta? *Recommendation: yes; it is Legal's recommendation and the only choice you can undo later.*
2. **Report channel.** Will you use a new private server (or a new channel locked to a tester role) rather than converting an existing one, and keep the promise to delete a tester's reports on request? *Recommendation: a new private server, and keep the promise.*
3. **LAN for friends.** In the first Alpha round, are the LAN modes for you and the trusted second player only, or for outside friends too? *Recommendation: you two only at first; outside friends get solo, couch and horde, and LAN follows once Legal has ruled and a tester-ready LAN package exists.*
4. **The title on the private itch.io page.** May the key-only page go up under the working title, marked "(working title)", before the paid title search? *Recommendation: yes, if Legal first writes one row saying an unlisted, unpromoted page is acceptable; the search still comes before any public or Steam page.*
5. **Desktop test builds.** When the gates are green, will you record one line saying yes to desktop test builds for named outside testers? *Recommendation: yes, at that point and not before; the build workflow refuses to run without it.*

For the EP, not for Orb's page: F-LEGAL-01 and F-LEGAL-08 (flashing). The safeguards themselves (notice, Reduce flashing, lock) are in force, so nothing has lapsed; the open part is the reading and its measuring chain.
