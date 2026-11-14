# Backlog (draft): one table keyed by register id

_Draft for the Executive Producer, who owns and commits it (row A-PROCESS-02; Production Operations drafts). Built for 2026-11-14 by tools/build-tracker.mjs from the audit's register (270 rows), the tracker's status and the corrective plan of 2026-11-07. Rows marked † are held to the EP's tables (see milestones.md). Status words as in the tracker; "not placed" is a row outside the milestones (the nice-to-have pool, or after Alpha)._

**What is still missing from this draft.** The sources the EP passes: the EP's owed-by-owner list, QA's bug list (the register notes it holds 1 of the 52 problems Orb reported from 2026-11-01 to 2026-11-09: row A-QA-03) and the list of parked folders (494 uncommitted paths under pending/). Anything in those that has no register row goes in the last table, with a source and an owner; nothing is dropped.

## A. The register, by milestone

| Id | Where | Owner | Size | Severity | Status | Corrective item | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-AI-03 | A1 | qa-balance | S | major | not started |  | Medium and Hard have no win-rate record for Orb's scheme on any build since 2026-11-01; the only figures on a… |
| A-AI-04 | A1 | qa-balance | S | major | not started |  | No win rate has been measured on the played build's own packed data: every record was made on a scratch tree… |
| A-AI-05 | A1 | encounter-systems | S | major | reported |  | Main's computer-opponent data is not the played build's: Easy's pace matching, the beam pacing against a… |
| A-AI-10 | A1 | encounter-systems | S | minor | briefed |  | The fix for Orb's remark that the computer perfect-blocks charged attacks too easily is parked and not on… |
| A-AI-11 | A1 | qa-balance | S | minor | not started |  | Forty matches a cell cannot tell neighbouring bands apart (about 15 points either way), and the drop the EP… |
| A-AI-13 | A1 | encounter-systems | S | minor | briefed |  | The parked one-versus-many work was last rebuilt on 2026-10-16 and applies by exact-text patches; whether it… |
| A-ANIM-06 | A1 | ep | S | minor | not started |  | The animation runtime, its tools and its data (render/anim, data/anim) are on no director's owns line;… |
| A-AUDIO-01 | A1 | audio-music | S | major | reported |  | On main five sound sets are off, so a build made plainly from main has no beam, knock-out, launch, struggle… |
| A-CAMERA-01 | A1 | camera | S | major | reported |  | The camera Orb played (swing, peak launch shot, launch director, close brawl, readable size, 70/30 share,… |
| A-CODE-01 | A1 | ep | L | blocker | not started |  | Main does not hold the game Orb plays: 72 of the 92 build switch rows differ between main and Orb's solo… |
| A-CODE-02 | A1 | simulation-engine | M | major | briefed |  | The golden record and five gates are valid only with the switches off, so the configuration Orb plays has no… |
| A-CODE-03 | A1 | tools-pipeline | M | major | reported |  | Orb's solo build carries code that is not on main: the preview patches a scratch copy of the main scene to… |
| A-CODE-04 | A1 | tools-pipeline | L | major | landed |  | CI runs 116 of the 262 check and test scripts: none of the input, audio or UI checks, one of 26 camera tests,… |
| A-COMBAT-05 | A1 | encounter-systems | S | major | reported |  | A released stick beam that cannot start waits up to 90 ticks and then fires into whatever the player is… |
| A-COMBAT-08 | A1 | qa-balance | M | major | not started |  | No tool measures X-03 (move coverage), X-04 (forms reached), X-13 (the pillars in one match) or X-16 (beam… |
| A-COMBAT-11 | A1 | encounter-systems | S | minor | reported |  | RT + B stays a signature for as long as the fighter is not channelling, not for 12 ticks, because the rule… |
| A-COMBAT-14 | A1 | combat-choreography | S | minor | not started |  | The mixed string's switch reads 'on' in the played build but no game code reads its data file; the feature… |
| A-COMBAT-15 | A1 | game-design | S | minor | landed |  | Six of Orb's 'workshop this' combat items have no decision: beam stages, the timed swat, the catch, what RT… |
| A-CONTROLS-02 | A1 | controls-feel | M | major | reported |  | The pad as the owner plays it is not the default in data: eleven input switches are off on main and on in… |
| A-CONTROLS-04 | A1 | game-design | S | major | reported |  | The flight speed the owner preferred (3500) exists only as a slider on the private browser page; the data's… |
| A-CONTROLS-06 | A1 | controls-feel | M | major | reported |  | No moveset coverage probe exists: the nearest tool presses each input alone for 90 ticks and its saved result… |
| A-ENERGY-02 | A1 | game-design | S | major | landed |  | No single written page states the model: it is spread over six design pages, the oldest still a proposal that… |
| A-ENERGY-04 | A1 | simulation-engine | S | major | briefed |  | The "one energy model" is off in the data on main and in both played builds, and is on in Orb's build only… |
| A-ENERGY-05 | A1 | simulation-engine | M | major | briefed |  | The backburnered hero and villain meters, hiding and ambush, and signature variants by biome still act in… |
| A-ENERGY-06 | A1 | tools-pipeline | S | major | landed |  | The tool X-15 names does not measure X-15: the two-fighter ratchet counts four spellings of "exactly two… |
| A-LEGAL-02 | A1 | tools-pipeline | M | blocker | briefed |  | No desktop package for an outside tester can be made today: the build workflow needs a recorded approval file… |
| A-LEGAL-09 | A1 | legal-ip | S | major | landed | CD-06 | Whether a restricted, key-only itch.io page may go up before the title search is not confirmed anywhere:… |
| A-LEGAL-10 | A1 | orb | S | minor | landed |  | The owner's one-line licence choice is not on record, so the build says the licence is not chosen yet and no… |
| A-MODES-01 | A1 | ui-ux | M | blocker | reported |  | The start menu has no list of modes: its rows are one or two players, each player's device, the computer's… |
| A-MODES-06 | A1 | ui-ux | M | blocker | reported |  | There is no fighter select: a match's fighters default to the first two ids of the roster file, so player one… |
| A-MODES-07 | A1 | encounter-systems | S | major | briefed |  | On main the rules that end a match as the last played build did (knockout only by a finishing move, wear for… |
| A-MODES-08 | A1 | tools-pipeline | M | major | reported |  | No mode smoke suite exists: the one smoke check drives the browser build by clicking fixed screen points and… |
| A-MODES-11 | A1 | ui-ux | S | major | reported |  | With a pad alone a player can go back to the menu but cannot close the game: the pause and match-over lists… |
| A-MODES-15 | A1 | ui-ux | S | minor | reported |  | The Rail menu the owner picked is switched off on main and on only in the played build, so a candidate built… |
| A-NET-05 | A1 | simulation-engine | S | major | reported |  | A replay carries a hash of its data, its format and its input version but no build id, so a replay from a… |
| A-PERF-04 | A1 | performance-platform | S | major | not started |  | Nothing about frame rate, loading or memory has been measured on the build Orb last played, and no windowed… |
| A-PERF-06 | A1 | performance-platform | S | major | not started |  | No loading time is on file for the desktop game with menus, the tile ground and generated planets; the last… |
| A-PERF-07 | A1 | performance-platform | S | major | not started |  | Memory has never been measured on a desktop build, and growth over time is marked not measured, so the soak's… |
| A-PERF-08 | A1 | rendering-techart | S | major | briefed |  | The game sets no window: there is no display section in the project file and no fullscreen, resolution,… |
| A-PROCESS-01 | A1 | production-ops | S | major | landed |  | No written change-control rule for the feature freeze and no ideas log exist, and the EP's playbook points to… |
| A-PROCESS-02 | A1 | ep | S | major | reported |  | There is no single backlog: open work sits in the corrective plan, the EP's messages and per-machine memory… |
| A-PROCESS-03 | A1 | ep | M | major | briefed |  | The working tree carries 14,805 uncommitted paths, including run records, parked work, the terrain plan and… |
| A-PROCESS-04 | A1 | production-ops | S | major | landed |  | The risk register is the starting set of 2026-09-28, never updated, and lists none of the risks that have… |
| A-PROCESS-05 | A1 | production-ops | S | major | landed |  | There is no milestone tracker or live roadmap, and the Production Operations director who owns them has no… |
| A-PROCESS-06 | A1 | ep | S | major | not started |  | The P0 to P5 roadmap in CLAUDE.md no longer describes the project: no phase gate result is on record, P3 and… |
| A-PROCESS-07 | A1 | ep | S | major | not started | CD-23 | The corrective plan of 2026-11-07 has not been kept: 13 of 27 rows have no closing entry, 8 items have… |
| A-PROCESS-08 | A1 | ep | S | minor | reported |  | No weekly token record exists: the EP has no clean figures for the last three weeks, so milestone lengths in… |
| A-PROCESS-09 | A1 | ep | S | minor | not started |  | The /sprint-plan and /sprint loop is installed but has never run, and its input, the audit's path-to-Alpha… |
| A-PROCESS-10 | A1 | ep | S | minor | not started |  | The project's running state depends on one EP session: four commands hard-code its session id, and its… |
| A-PROCESS-11 | A1 | ep | S | minor | not started |  | CLAUDE.md and ADR 0005 still tell every session the project is on a Pro plan with no workflows, against Orb's… |
| A-PROCESS-13 | A1 | ep | S | minor | not started |  | The director roster has no Alpha mapping and carries stale parts: charters list backburnered duties, one… |
| A-PROCESS-14 | A1 | ep | S | minor | not started |  | The commands the sprint loop replaces are still live: /crunch is tracked with its 2026-11-01 priorities,… |
| A-PROCESS-15 | A1 | ep | S | minor | not started | CD-20 | The standup command does not read CI first, although the corrective plan's CD-20 asks for that step in both… |
| A-PROCESS-16 | A1 | ep | S | minor | reported |  | 'Done' exists only as one general rule; no page lists each Alpha feature with its own done test, and the exit… |
| A-QA-03 | A1 | qa-balance | S | major | not started | CD-23 | The bug list holds 1 of the 52 problems Orb reported in play from 2026-11-01 to 2026-11-09, and its newest… |
| A-QA-04 | A1 | qa-balance | M | major | not started |  | Balance between the two fighters is not measured on the build Orb plays: the last full reading (48.9%, in… |
| A-QA-07 | A1 | qa-balance | S | minor | not started |  | The bug list has no severity field (it has a release horizon and a closing step), and its title still names… |
| A-QA-09 | A1 | qa-balance | S | minor | not started |  | The scripted player that matches Orb's scheme lives in Tools' gauntlet, plays 40 matches in slot 0 only, and… |
| A-RENDER-01 | A1 | rendering-techart | M | major | briefed |  | The look Orb plays (globe ground, crater look, meteor trail, the swing camera that rides with it) is switched… |
| A-RENDER-04 | A1 | rendering-techart | M | major | briefed |  | (see the full table) |
| A-RENDER-07 | A1 | ep | S | major | not started | CD-22 | No record ties a visible landing to its side-by-side: landings arrive as batches, the gate records of the… |
| A-RENDER-11 | A1 | ep | S | minor | not started |  | The look gate's reference build is still d3f1ca0e of 2026-10-15, which predates the globe ground and… |
| A-SAVES-01 | A1 | qa-balance | S | major | not started |  | No record on file shows a replay saved by the baseline build verifying to its last tick on that build, and… |
| A-TOOLS-01 | A1 | tools-pipeline | L | blocker | briefed | CD-12 | No one command or CI run makes the Windows and Linux desktop builds of the game as Orb plays it, the solo… |
| A-TOOLS-07 | A1 | tools-pipeline | S | major | briefed |  | A build carries a commit and a date but no version number, the Windows program's version fields are empty, no… |
| A-TOOLS-08 | A1 | tools-pipeline | S | major | landed |  | The Godot check job's time swings from about 35 to 62 minutes on unchanged game code against a 75-minute… |
| A-TOOLS-09 | A1 | tools-pipeline | S | major | landed |  | The owner's builds, play files, reports and clips sit in one git-ignored folder of about 2.9 GB on one disk,… |
| A-TOOLS-10 | A1 | tools-pipeline | S | minor | landed |  | The playbook's build-verification rule cites a script that is not in the repository and a tool name that… |
| A-TOOLS-13 | A1 | tools-pipeline | S | minor | landed |  | No CI job ever starts a Windows build: every job runs on Linux, and the desktop workflow reads the Windows… |
| A-TOOLS-15 | A1 | tools-pipeline | S | minor | landed | CD-21 | Corrective item CD-21 (stop silent passes: 'grandfathered', 'report only' and 'CHECK' lines that print as… |
| A-UI-01 | A1 | ui-ux | S | blocker | reported |  | With the Rail menus on (as in the build Orb played), the pause menu's slide-in is timed on a HUD clock that… |
| A-UI-02 | A1 | tools-pipeline | M | blocker | reported |  | On main, and so in any plain desktop build, the one-press report and 'Save this match' save nothing: the hook… |
| A-UI-04 | A1 | ui-ux | M | major | reported |  | Making the Rail the default is unfinished: its switch is off on main, three older HUD checks fail with it on,… |
| A-UI-06 | A1 | ui-ux | S | major | reported |  | The start menu's d-pad behaves unevenly, as Orb reported: Up from the top row jumps to Start while Down from… |
| A-UI-09 | A1 | ui-ux | S | major | reported |  | X-22 cannot be measured today: there is no still of any screen at 1280 by 800 and no tool that sweeps every… |
| A-WORLD-01 | A1 | world-environment | M | blocker | briefed |  | On main the round planet is not the game's world: a match with no planet setup key plays the old hand-made… |
| A-WORLD-14 | A1 | orb | S | minor | landed |  | No default world is decided: Orb's solo copy opens on planet 7 through a shortcut's page word, LAN fixes… |
| A-ACCESS-01 | A2 | accessibility-localization | S | major | not started |  | There is no accessibility pass or record newer than 2026-10-31 and no runs folder for the area, so the… |
| A-ACCESS-02 | A2 | ui-ux | S | minor | not started | CD-14 | The Hit pause slider is still shown on the Accessibility page and still has no reader outside the user… |
| A-ACCESS-04 | A2 | ep | S | minor | not started | CD-14 | Corrective item CD-14 has an empty progress cell and no commit or record names it since 2026-11-07, although… |
| A-AUDIO-03 | A2 | audio-music | S | major | not started |  | Nothing in the area is proved by ear: Audio's pages say nobody has listened, and Orb's latest word… |
| A-AUDIO-04 | A2 | audio-music | S | major | not started |  | Sound on the Alpha's platforms (a Windows desktop build, Linux, the Steam Deck) is not evidenced: every proof… |
| A-CAMERA-02 † | A2 | camera | S | major | not started | CD-04 | (see the full table) |
| A-CAMERA-03 | A2 | camera | S | major | not started |  | No camera test or saved record runs at the Steam Deck's 1280 by 800: every camera test fixes 1280 by 720, and… |
| A-CONTROLS-03 | A2 | controls-feel | S | major | not started |  | A pad unplugged mid-match does not pause or show a notice: player two's fighter is handed to the computer and… |
| A-CONTROLS-07 | A2 | controls-feel | S | major | not started |  | The Steam Deck's built-in controls have never been tried: no run on a Deck or through Steam's pad layer is on… |
| A-CONTROLS-08 | A2 | performance-platform | S | minor | not started |  | The press-to-picture latency record is not current: it measures the browser build with keyboard presses on 22… |
| A-LEGAL-01 † | A2 | camera | XL | blocker | not started | CD-04 | (see the full table) |
| A-LEGAL-03 | A2 | legal-ip | S | major | briefed |  | The list of gates that must be green before an outside tester plays did not exist before this audit, and… |
| A-LEGAL-05 | A2 | legal-ip | S | major | not started |  | The tester note is a draft for the owner to send, its review row is still open on two conditions, and nothing… |
| A-LEGAL-06 | A2 | tools-pipeline | M | major | not started |  | Legal asked that report files be checked for account names and file paths before a tester sends them, and no… |
| A-LEGAL-07 | A2 | orb | S | major | not started |  | The report channel is undecided: the owner's words were to convert an existing server, Legal's first flag… |
| A-LEGAL-08 † | A2 | tools-pipeline | M | major | briefed | CD-09 | (see the full table) |
| A-LEGAL-12 | A2 | legal-ip | S | minor | not started |  | The privacy words differ between the package README, the in-game About page and the tester note, and none of… |
| A-LEGAL-13 | A2 | ui-ux | S | minor | not started |  | (see the full table) |
| A-MARKET-01 | A2 | tools-pipeline | S | major | not started |  | There is no fixed shot list: the recipe file covers three of the six named shots and has no recipe for a… |
| A-MARKET-02 | A2 | tools-pipeline | S | major | not started |  | No job renders the shots at a milestone and no archive exists: clips land in a git-ignored folder with no… |
| A-MARKET-03 | A2 | tools-pipeline | M | major | not started |  | The capture hook exists only in a browser build, so the Alpha candidate's own Windows and Linux programs… |
| A-MARKET-04 † | A2 | tools-pipeline | S | major | not started |  | (see the full table) |
| A-MARKET-07 | A2 | tools-pipeline | S | minor | not started |  | No rule says what happens to a shot when an old replay stops playing: a replay is refused on different data,… |
| A-PERF-01 | A2 | performance-platform | M | blocker | not started |  | No Linux build has ever drawn a picture or run on a Steam Deck, so whether it starts, whether every shader… |
| A-PERF-03 | A2 | performance-platform | M | blocker | not started |  | There is no one-click bench a Deck tester can run that saves a file: the existing kits are Windows batch and… |
| A-PERF-05 | A2 | rendering-techart | M | major | not started |  | The frame spikes Orb has felt since 2026-11-01 are still open: two causes were fixed on main but never… |
| A-QA-02 | A2 | qa-balance | M | blocker | not started |  | No soak test exists for the Godot game: nothing records crashes, hangs, script errors over hours or memory… |
| A-QA-11 | A2 | qa-balance | S | minor | not started |  | Five older bug entries (GB-002, GB-003, GB-005, GB-006, GB-007) are open or fixed but never re-checked in… |
| A-RENDER-02 | A2 | rendering-techart | M | major | not started |  | Two look bugs from Orb's play of 6a30b4c9, fighters clipping into the ground and a row of three humps in a… |
| A-RENDER-03 | A2 | rendering-techart | S | major | not started |  | A thick black diagonal line across the whole picture, found when Tools replayed Orb's 'hump of ocean water'… |
| A-RENDER-08 | A2 | rendering-techart | S | major | not started |  | The boot warm-up's list does not name the clash, meteor trail or blast-head shaders, the park that warms… |
| A-SAVES-02 † | A2 | ui-ux | S | minor | not started |  | (see the full table) |
| A-TEXT-01 | A2 | ui-ux | S | major | not started |  | No record shows that Orb has seen the menu, how-to, hint, notice or settings text: the strings list made for… |
| A-TOOLS-02 | A2 | tools-pipeline | M | blocker | not started |  | Nothing for itch.io exists: no page set-up note, key procedure, channel names, upload script or rehearsal… |
| A-TOOLS-03 | A2 | tools-pipeline | S | blocker | not started |  | No rollback procedure or release checklist exists, so nothing says how testers are returned to the previous… |
| A-TOOLS-04 | A2 | tools-pipeline | M | blocker | not started |  | Nothing captures a crash or a hang: no game code writes a file when the game dies, the project sets no… |
| A-TOOLS-05 | A2 | tools-pipeline | M | blocker | not started |  | The one-press report folder works only on Orb's PC: its launcher is a Windows command file that runs Node… |
| A-TOOLS-06 | A2 | legal-ip | S | major | not started |  | The desktop package rules were written for private test builds and conflict with an Alpha on itch.io: files… |
| A-UI-03 † | A2 | rendering-techart | S | major | not started |  | (see the full table) |
| A-UI-07 | A2 | ui-ux | S | major | not started |  | The feedback panel cannot be worked with a pad: a pad's only actions there are B or Start to close, so tags,… |
| A-UI-10 | A2 | ui-ux | S | major | not started |  | Settings and remapped controls surviving a restart has never been tested across a real restart on Windows or… |
| A-AI-07 | A3 | encounter-systems | S | major | not started |  | No standing check proves the computer uses only inputs a player has: on main its signature is still the old B… |
| A-CAMERA-05 | A3 | camera | M | major | not started |  | The rig has no input naming this PC's player: the large pane goes to the one fighter of slots 0 and 1 with no… |
| A-COMBAT-01 | A3 | encounter-systems | L | blocker | not started |  | Beam option A is not built: a beam is still an exchange that always reaches its target and is decided by a… |
| A-COMBAT-02 | A3 | encounter-systems | L | blocker | not started |  | Signatures are not on Orb's inputs: RT + RB + a right-stick flick and RT + a flick cannot be pressed (the… |
| A-COMBAT-03 | A3 | simulation-engine | XL | blocker | not started |  | No gravity well exists in code: no well, zones, draw, snap or intent read, only two pieces of the LT speed… |
| A-COMBAT-07 | A3 | controls-feel | S | major | not started |  | In Orb's last full match the player's fighter never left tier 1 while the computer reached tier 3; the… |
| A-CONTROLS-05 | A3 | encounter-systems | M | major | not started |  | The latest count of unanswered presses is from an older build: 225 of 760 presses not honoured (30 percent),… |
| A-ENERGY-01 | A3 | game-design | L | blocker | not started |  | No stamina and no "body" number exist in any code or data, so the energy, stamina and health loop Orb defined… |
| A-ENERGY-03 | A3 | simulation-engine | M | major | not started |  | Energy's own numbers (start, cap, regain, charge rate, hit gain, guard drain and the older costs) are… |
| A-ENERGY-07 | A3 | ui-ux | S | major | not started |  | No record shows that a player can read their own health, energy or readiness from the fighter at speed; the… |
| A-ENERGY-08 | A3 | ui-ux | S | minor | not started |  | The HUD's power pip is computed at 25 per tier while the data's thresholds are 35, 65 and 100, so it reads… |
| A-ENERGY-10 | A3 | simulation-engine | S | minor | not started |  | A new kind of meter cannot be added as data: the loader accepts only the two backburnered meter names. |
| A-LEGAL-04 | A3 | legal-ip | M | major | not started |  | No ruling or package covers an outside tester playing the LAN modes: the locked package refuses any network… |
| A-MODES-04 | A3 | netcode-online | L | blocker | not started |  | LAN play is not part of the game a tester would get: it reaches the game only through text patches the LAN… |
| A-MODES-05 | A3 | netcode-online | M | blocker | not started |  | A LAN match cannot be rematched or left to a menu: the program plays one match and tells both players to… |
| A-MODES-10 | A3 | netcode-online | M | major | not started |  | Every LAN match is the same match: the seed, the planet and the fighters are constants in the LAN code, so… |
| A-NET-01 | A3 | netcode-online | S | major | not started |  | No LAN match on the played build (6a30b4c9) has a record from two real PCs: its only LAN records are nine… |
| A-NET-02 | A3 | netcode-online | L | major | not started |  | An outside tester could not set up LAN without help: the folder is built on the hosting PC with that PC's… |
| A-NET-03 | A3 | netcode-online | S | major | not started | CD-10 | A PC that falls silent is declared gone after 8 seconds, not the 5 seconds X-08 proposes, and no pulled-cable… |
| A-NET-04 | A3 | netcode-online | S | major | not started |  | Every LAN status except a dropped PC (waiting, could not connect, could not start, out of step, match over)… |
| A-PERF-02 | A3 | netcode-online | M | blocker | not started |  | LAN play has no Linux build path: the LAN kit exports the Windows preset only, the Linux preset excludes the… |
| A-RENDER-13 | A3 | vfx | S | minor | not started |  | The zip and press effects draw marks on and round the fighters (a charge ring, a diamond, a double ring, a… |
| A-WORLD-03 | A3 | world-environment | M | major | not started |  | Terrain step 2 (no shafts, settling, the record list) is built and parked but not on main, held because the… |
| A-WORLD-04 | A3 | world-environment | S | major | not started |  | Any ground dug below the shore line reads as sea at once, wherever it is, because the sea is derived from… |
| A-WORLD-06 | A3 | world-environment | S | major | not started |  | X-14's three times the crater width at the top tier is not met for the same blow and no check asserts any… |
| A-WORLD-07 | A3 | world-environment | L | major | not started |  | A skid trench on the planet is cut at one fixed half width of 32 units (about one body height across) at… |
| A-WORLD-10 | A3 | world-environment | L | major | not started |  | A body that hits a building or an outcrop still bounces back like a ping-pong ball, which Orb reported on… |
| A-AI-01 | A4 | encounter-systems | L | blocker | not started |  | There is no computer control for many weak enemies: henchmen are paper only, the one-versus-many director… |
| A-AI-06 | A4 | encounter-systems | M | major | not started |  | The computer never throws a right-stick strike, the main attack of Orb's scheme: the only right-stick input… |
| A-AI-08 | A4 | encounter-systems | M | major | not started |  | There is no computer ally: the only 2v2 line-up puts both computers on the enemy team, and no menu or host… |
| A-AI-09 | A4 | encounter-systems | S | minor | not started |  | The computer's level is one value for the whole match, not one per fighter, so an ally weaker or stronger… |
| A-ANIM-01 | A4 | art | M | major | not started |  | A transformation changes only the aura: both fighters play the same three placeholder poses for every form… |
| A-ANIM-02 | A4 | art | S | major | not started |  | In a 2v2 the two copies of each fighter are drawn identically, and the mirror match is held off for the same… |
| A-ANIM-03 | A4 | animation | S | minor | not started |  | The animation coverage table is of 2026-10-03, was built from Combat's then-parked files, still marks 180 of… |
| A-CODE-05 | A4 | simulation-engine | L | major | not started |  | Adding a third fighter needs code today: 365 places in shipped code name exactly two fighters, and… |
| A-COMBAT-04 | A4 | combat-choreography | XL | blocker | not started |  | The move table is incomplete for both fighters: 18 of 101 cells have no outcome, 65 reach the same entry as… |
| A-COMBAT-06 | A4 | game-design | L | major | not started |  | Transformations are the shared three-tier ladder for both fighters: the Protagonist's own forms are switched… |
| A-COMBAT-12 | A4 | simulation-engine | S | minor | not started |  | A live transformation blocks new exchanges but damage has no transformation guard, so 'respected' is not… |
| A-CONTROLS-01 | A4 | controls-feel | M | major | not started |  | Couch 2v2 with four pads cannot be played: the input hub holds two human slots per PC and every pad routine… |
| A-MODES-02 | A4 | game-design | XL | blocker | not started |  | The co-op horde mode does not exist: there is no horde design page, the henchmen page says it is paper only,… |
| A-MODES-03 | A4 | rendering-techart | L | blocker | not started |  | Couch 2v2 cannot be started: the game's host only ever starts a two-body match, the input hub has two player… |
| A-MODES-09 | A4 | rendering-techart | L | major | not started |  | LAN 2v2 exists only as two humans, one on each PC, against two computer fighters, and each screen shows only… |
| A-NET-06 | A4 | netcode-online | S | minor | not started |  | LAN 2v2 has been played on two real PCs only in its team form and only on the 2026-11-07 build; the apart… |
| A-QA-06 | A4 | qa-balance | M | major | not started |  | QA has no script or band for team play or the horde, though the balance page sets 45 to 55% for every 2v2… |
| A-WORLD-02 | A4 | world-environment | L | blocker | not started |  | Custom planet setup has nothing under it: the generator takes a seed only, the planet's size is a constant,… |
| A-WORLD-09 | A4 | world-environment | S | major | not started |  | The planet hash comparison X-11 asks for is not a check: the fingerprint tool prints lines with no verdict… |
| A-AI-02 | A5 | game-design | S | major | not started |  | Easy is too hard for a scripted player using Orb's scheme: it won 19 of 40 (47.5%) on the tree that became… |
| A-AUDIO-02 | A5 | audio-music | M | major | not started |  | No sound exists for a building being damaged or collapsing, bystanders scattering, the gravity well, or any… |
| A-MARKET-05 | A5 | tools-pipeline | S | minor | not started |  | Footage is made at 960 by 540, shrunk to 480 wide at 12 pictures a second, as GIF or browser-recorded WebM… |
| A-MARKET-06 | A5 | tools-pipeline | S | minor | not started |  | The clips shared so far were staged on a private test copy with behaviour the game does not have (both at top… |
| A-MARKET-08 | A5 | community-marketing | S | minor | not started |  | The marketing plan predates Orb's Alpha definition: it stages a public browser build and public itch.io page,… |
| A-QA-01 | A5 | qa-balance | S | blocker | not started |  | No tester guide, tester checklist, Deck checklist or playtest protocol exists: nothing tells a tester how to… |
| A-QA-05 | A5 | game-design | M | major | not started |  | A right-stick-only pad loses almost every match in QA's latest reads: 0 of 60 against Medium on 2026-11-07… |
| A-QA-08 | A5 | qa-balance | S | minor | not started |  | Match length is not measured on the current build against the 6 to 8 minute target; Orb's one finished match… |
| A-RENDER-05 | A5 | rendering-techart | S | major | not started |  | The Settings screen offers 'Effects quality' (auto, high, medium, low) but no game code reads the choice, so… |
| A-RENDER-06 | A5 | rendering-techart | L | major | not started |  | The quality range Orb asked for (performance to maximum) is a paper ladder and a research prototype: the game… |
| A-SAVES-08 | A5 | tools-pipeline | S | minor | not started |  | Where the game keeps its files is written nowhere a tester would read, and the folder is the engine default… |
| A-TEXT-03 | A5 | ui-ux | S | minor | not started |  | The how-to card names keyboard keys to a pad player: its corner hint reads "Enter: next Esc: close" whenever… |
| A-TEXT-04 | A5 | legal-ip | S | minor | not started |  | The title is shown and stamped as plain "Orb Combat EX" with no working-title mark, while Legal's page says… |
| A-UI-05 | A5 | ui-ux | S | major | not started |  | The Rail's match-over screen is a full-height panel over the left 30% of the screen, which is where player… |
| A-UI-08 | A5 | ui-ux | S | major | not started |  | (see the full table) |
| A-WORLD-05 | A5 | rendering-techart | L | major | not started |  | The ground drawn is not the ground stood on: the tile ground draws only the 16 nearest crater bowls, and the… |
| A-ACCESS-03 | pool | ui-ux | M | minor | not placed |  | Sounds are captioned for two cues only (the beam struggle and an opening), and that caption line is off by… |
| A-ACCESS-05 | pool | controls-feel | S | minor | not placed |  | The Simple controller layout binds no brace button, so whether the 'Button only' brace style leaves a… |
| A-ANIM-04 | pool | animation | S | minor | not placed |  | The creative rulebook's held-pose rows still fail the animation check, which is a line of the EP's full gate,… |
| A-ANIM-05 | pool | orb | S | minor | not placed |  | The rulebook's three questions to Orb (which numbers move, a named-exception list, who signs a change) are… |
| A-ANIM-08 | pool | animation | S | minor | not placed |  | Animation's parked-work page still says Parked for patches the inventory found on main, and the wave files'… |
| A-AUDIO-05 | pool | orb | M | minor | not placed |  | There is no music: no track has been handed back, the encoder install was not approved, and the pipeline has… |
| A-AUDIO-06 | pool | audio-music | S | minor | not placed |  | Stacked impacts overdrive the engine's limiter (peaks +1.1 to +9.3 dBFS before it) on the mixer path a… |
| A-AUDIO-07 | pool | audio-music | S | minor | not placed |  | The pad-only silent start in the browser is half fixed: the engine-side hook and the start-menu line that… |
| A-AUDIO-08 | pool | legal-ip | S | minor | not placed |  | Legal's ruling on the music tool rests on summaries of its terms read on 2026-10-04, and says so; no re-read… |
| A-CAMERA-04 | pool | camera | M | major | not placed |  | No picture-in-picture for an ally exists: the only built inset is the slanted panel cut-in for the pair on… |
| A-CAMERA-06 | pool | camera | S | minor | not placed |  | The written list of cuts is behind the code: the code's table has 13 reasons, and two of them (a cut the… |
| A-CAMERA-07 | pool | camera | S | minor | not placed |  | How long the opponent is out of the picture after a launch is printed but never checked: the chase check… |
| A-CAMERA-08 | pool | camera | S | minor | not placed |  | Nothing has been tried since Orb asked on 2026-11-09 for more stylised versions of the hard-line merge and… |
| A-CAMERA-09 | pool | camera | S | minor | not placed |  | Camera pages and parks disagree with main: the split vision page still says today's merge has a dissolve… |
| A-CAMERA-12 | pool | encounter-systems | S | minor | not placed |  | The director's camera-intent feed is off in main's data and in Orb's build, so the rig's reader for planned… |
| A-CAMERA-13 | pool | qa-balance | S | minor | not placed |  | The known-bugs row for the split-screen jolt on a knock-away is still open and says no measure exists, though… |
| A-CODE-06 | pool | simulation-engine | S | minor | not placed |  | Code and data that nothing in the game reaches are still tracked: a keyboard class, a swing reader, two world… |
| A-CODE-08 | pool | tools-pipeline | S | minor | not placed |  | The export presets leave test and tool code inside every build: the input tests, the render and camera test… |
| A-CODE-09 | pool | tools-pipeline | S | minor | not placed |  | The saved record of the last gate keeps one summary line per check and no logs, so engine warnings cannot be… |
| A-CODE-10 | pool | tools-pipeline | S | minor | not placed |  | Twelve switch rows are already at their on value on main and five are held off in every build, so 17 rows of… |
| A-COMBAT-09 | pool | game-design | XL | major | not placed |  | Launches are not physics-based: the meteor is an authored curve and no attack has a force or any fighter a… |
| A-COMBAT-10 | pool | encounter-systems | M | major | not placed |  | Chaining hits on a flying foe is only the tap chase; the LT chase, a chain window after a knock-back and a… |
| A-CONTROLS-09 | pool | game-design | S | minor | not placed |  | The quick LT tap still carries the fighter further than the ruled step when far from the rival (9.9 body… |
| A-CONTROLS-10 | pool | controls-feel | S | minor | not placed |  | Keyboard play is bound for every action on the solo layout but is unproven on the played build, and two… |
| A-ENERGY-09 | pool | rendering-techart | S | minor | not placed |  | Body marks only grow to the worst stage reached and never fade, so the fighter cannot show recovery or the… |
| A-ENERGY-11 | pool | simulation-engine | M | minor | not placed |  | The old hit-point number is still tracked beside the wounds as a second health value, and QA's tools and… |
| A-ENERGY-12 | pool | simulation-engine | S | minor | not placed |  | Several damage numbers are code constants shared by all fighters: the stance table, combo growth, the… |
| A-LEGAL-11 | pool | legal-ip | S | minor | not placed |  | Three older Legal pages still recommend the permissive pairing that the current rundown says never to use. |
| A-LEGAL-15 | pool | ep | S | minor | not placed | CD-11 | The public repository's safety net ordered on 2026-11-07 (CD-11: secret scanning, push protection, a… |
| A-MARKET-09 | pool | legal-ip | S | minor | not placed |  | The project's notes disagree with each other on Valve's waiting period and are stale on the licence: three… |
| A-MARKET-10 | pool | rendering-techart | S | minor | not placed |  | Bystanders' run cycles follow the shader's clock, not the tick, so two renders of the same shot differ in the… |
| A-MODES-12 | pool | game-design | M | minor | not placed |  | There is no practice mode: the grey reference dummy is third in the roster file but nothing in the menu or… |
| A-MODES-13 | pool | game-design | S | minor | not placed |  | The time cap is a rules event at 11 minutes (14 in 2v2) with a pause, but no picture of the planet giving way… |
| A-NET-07 | pool | netcode-online | S | minor | not placed | CD-10 | The handshake refuses a proposed input wait above 8 ticks but not a negative one, which by the code leaves… |
| A-NET-09 | pool | ep | S | minor | not placed | CD-10 | The corrective plan's row for hardening the LAN link has an empty status cell although the delay cap, the… |
| A-NET-10 | pool | tools-pipeline | S | minor | not placed |  | The determinism lint has no rule for the engine's pow, exp or log, so a future bare use in the sim would pass… |
| A-NET-11 | pool | tools-pipeline | S | minor | not placed |  | The Web export preset does not leave out the network folder, so the browser build's pack carries the… |
| A-PERF-09 | pool | performance-platform | S | minor | not placed |  | The budget table and its build gate are stale: the Today column is the browser build of e6fa72ff… |
| A-PERF-10 | pool | audio-music | S | minor | not placed |  | Whether stalls crackle the sound on a desktop build is not evidenced: the proven mechanism is the browser… |
| A-PROCESS-12 | pool | ep | S | minor | not placed | CD-03 CD-24 | The public test build's delegated decision lapses on 2026-11-15 with nothing written about who holds it… |
| A-PROCESS-17 | pool | ep | S | minor | not placed |  | The sprint loop's contract and report pages live in the git-ignored homework folder, so Orb's approval of a… |
| A-PROCESS-18 | pool | ep | S | minor | not placed |  | Decisions since 2026-11-01 (the Alpha's scope, the sprint loop, the token order) are in vision.md only, not… |
| A-PROCESS-20 | pool | ep | S | minor | not placed | CD-18 | Corrective item CD-18 is half done: Legal listed 69 process and engineering items to move out of the safety… |
| A-QA-10 | pool | qa-balance | S | minor | not placed |  | QA's tools still measure the backburnered meters and biome signature variants and still use a placeholder… |
| A-QA-12 | pool | tools-pipeline | S | minor | not placed |  | Orb's saved play files carry no checkpoints, so QA's replays of them are checked only by running without… |
| A-RENDER-09 | pool | vfx | M | minor | not placed |  | The re-entry heat trail exists as a ribbon in the fighter's own energy colours, on only by a launch word; the… |
| A-RENDER-12 | pool | vfx | M | minor | not placed |  | Auras fall short of the taste page: the three-dimensional aura Orb asked for is parked and absent from main,… |
| A-RENDER-14 | pool | vfx | S | minor | not placed |  | Seven effect modules keep their numbers in code because their data files do not exist (beam plays, glare,… |
| A-RENDER-15 | pool | rendering-techart | S | minor | not placed |  | The crowd's drawing code still has a path and wording for casualties who 'are simply gone', written before… |
| A-RENDER-16 | pool | performance-platform | S | minor | not placed |  | The beam clash's air distortion copies the whole frame while a clash is on, and its only frame-cost record is… |
| A-SAVES-03 | pool | ui-ux | S | minor | not placed |  | The settings file and the controls file are overwritten in place, so a write cut short leaves an unreadable… |
| A-SAVES-04 | pool | controls-feel | S | minor | not placed |  | Neither settings file can change shape between builds: the settings file has no version, and a controls file… |
| A-SAVES-05 | pool | simulation-engine | S | minor | not placed |  | Three loaders do not check the types of what they read (a replay's seed, ticks, toggles and checkpoints; a… |
| A-SAVES-06 | pool | ui-ux | S | minor | not placed |  | The settings file is opened and parsed again on per-frame paths, as the safety audit of 2026-11-07 noted, and… |
| A-SAVES-07 | pool | netcode-online | S | minor | not placed |  | LAN match files and the LAN log grow without a cap, in a folder beside the program. |
| A-TEXT-02 | pool | narrative-identity | S | minor | not placed |  | The fighters say nothing in a match: the approved lines are switched off on main and in the build Orb last… |
| A-TEXT-06 | pool | narrative-identity | S | minor | not placed |  | A few how-to lines are not plain or not true for a desktop tester: the planet bar is called "the strip", the… |
| A-TOOLS-11 | pool | tools-pipeline | S | minor | not placed |  | On main, a push that queues behind a running CI run is cancelled unrun when a newer push arrives (15 of the… |
| A-TOOLS-12 † | pool | ep | S | minor | not placed |  | (see the full table) |
| A-TOOLS-14 | pool | tools-pipeline | S | minor | not placed |  | The desktop workflow builds macOS in the same job as Windows and Linux, CI's world-check comment gives a… |
| A-TOOLS-16 | pool | tools-pipeline | S | minor | not placed | CD-25 | Corrective item CD-25 (one machine-read list of Legal's clip conditions that blocks a public pin) has no… |
| A-TOOLS-17 | pool | tools-pipeline | S | minor | not placed | CD-26 | (see the full table) |
| A-UI-11 | pool | ui-ux | S | minor | not placed |  | Settings lists two rows that do nothing in this build: Beat ring, which the minimal HUD never draws even when… |
| A-UI-12 | pool | game-design | M | minor | not placed |  | First-time help is the How to play card and one-line hints only; the guided first match is a proposal from… |
| A-UI-13 | pool | ui-ux | S | minor | not placed |  | Leftovers of the backburnered hero and villain meters and of hiding remain in the UI code and words, switched… |
| A-UI-14 | pool | ui-ux | S | minor | not placed |  | Three UI pages or headers state a status the code has moved past: the minimal HUD page and the report page… |
| A-WORLD-08 | pool | world-environment | L | major | not placed |  | World sizes (tiny to colossal) exist only as a plan: the planet is 4,800 columns round by a constant, and… |
| A-WORLD-11 | pool | encounter-systems | S | minor | not placed |  | The launch planner still weighs whether a building is lived in through a fighter's care number, and a comment… |
| A-ACCESS-06 | after Alpha | accessibility-localization | S | minor | not placed |  | Nothing written says the Alpha is English only, the game has no language choice, and the translation tools… |
| A-ACCESS-07 | after Alpha | ui-ux | M | minor | not placed |  | There is no screen reader or menu narration: the area's own audit found no text-to-speech call, and a search… |
| A-AI-12 | after Alpha | encounter-systems | S | minor | not placed |  | Some of the computer's numbers are constants in code, not data: how often an attack beat attacks, the share… |
| A-ANIM-07 | after Alpha | combat-choreography | S | minor | not placed |  | The rival's four tail strikes sit in his live pools as waiting rows with no key set and no tail bones in the… |
| A-CAMERA-10 | after Alpha | camera | S | minor | not placed |  | Rejected or backburnered looks are still in the camera code behind switches: the cut cross-dissolve, the… |
| A-CAMERA-11 | after Alpha | camera | M | minor | not placed |  | The camera's numbers live in code, not data: camera_params.gd holds about 500 constants while data/camera has… |
| A-CODE-07 | after Alpha | simulation-engine | S | minor | not placed |  | The JavaScript core is no longer compared with the GDScript sim: CI only checks that the frozen JavaScript… |
| A-CODE-11 | after Alpha | simulation-engine | L | minor | not placed |  | Change is riskiest in four files of 4,300 to 5,900 lines and a handful of functions of 250 to 670 lines, two… |
| A-CODE-12 | after Alpha | simulation-engine | S | minor | not placed |  | Several file headers and comments say the opposite of what the code does (a live stick path described as off,… |
| A-COMBAT-13 | after Alpha | combat-choreography | S | minor | not placed |  | Two planned-exchange templates have a single outcome, and all templates key on the retired four-stance states. |
| A-ENERGY-13 | after Alpha | simulation-engine | S | minor | not placed |  | Leftovers of hiding still sit in the energy and health code (faster regain and healing while hidden, x1.5… |
| A-LEGAL-14 | after Alpha | legal-ip | S | minor | not placed | CD-13 | The content-rating records disagree with the game: the owner's early answer says graphic violence with a… |
| A-MARKET-11 | after Alpha | ui-ux | M | minor | not placed |  | A player cannot hide the HUD and there is no photo mode; both are absent from the game and neither is in… |
| A-MODES-14 | after Alpha | orb | S | minor | not placed |  | The campaign is sim groundwork only (about 1,180 lines across three files) with its switch off, no caller in… |
| A-NET-08 | after Alpha | netcode-online | M | minor | not placed |  | The LAN link is plain, unencrypted ENet, which is acceptable on a home network and must change before any… |
| A-NET-12 | after Alpha | netcode-online | S | minor | not placed |  | Groundwork for online play (a spectator, a seat take-over proposal, a rollback bench that estimates a phone)… |
| A-PERF-11 | after Alpha | performance-platform | S | minor | not placed |  | ADR 0013 says minimum specs are set before launch with no date, owner or method. |
| A-PROCESS-19 | after Alpha | orb | S | minor | not placed | CD-02 | Corrective item CD-02's manual unpublish rehearsal is still owed: the take-down workflow exists and has run,… |
| A-RENDER-10 | after Alpha | rendering-techart | L | minor | not placed |  | Nothing above today's picture exists for Orb's PC: the 'maximum' Orb liked was a research prototype's level,… |
| A-TEXT-05 | after Alpha | narrative-identity | S | minor | not placed |  | The placeholder names KAI and VORR remain in data and code a player does not see: a placeholder line file no… |
| A-WORLD-12 | after Alpha | world-environment | XL | minor | not placed |  | Much of the world is built, switched off and never in a played build (craters by material, forest fire, beam… |
| A-WORLD-13 | after Alpha | rendering-techart | L | minor | not placed |  | Orb's ask for a cheap tessellation engine with destructible, deformable terrain meshes has no design page;… |

## B. The corrective plan of 2026-11-07, row by row (27 items)

The plan's own closing column, read as written; "register row" is the row the audit made from that item (the register's source field). Items titled with a held word show a neutral title.

| CD | What it is | Plan's closing column | Register row(s) |
| --- | --- | --- | --- |
| CD-01 | CI running again; a separate workflow-lint workflow; run check in the landing steps | closed (has a commit or record) | none |
| CD-02 | Take-down with no game job; manual unpublish written down; a contact route | entry, with something still owed | A-PROCESS-19 |
| CD-03 | The public test build decision goes back to Orb | entry, with something still owed | A-PROCESS-12 |
| CD-04 | (see the corrective plan) | open | A-CAMERA-02 A-LEGAL-01 |
| CD-05 | The villain feeding on civilian deaths | closed (has a commit or record) | none |
| CD-06 | A trademark search before any store page | closed (has a commit or record) | A-LEGAL-09 |
| CD-07 | Personal details in the public repo | closed (has a commit or record) | none |
| CD-08 | Make the public text true (README, CLAUDE.md, /about/, the pin's notice) | closed (has a commit or record) | none |
| CD-09 | (see the corrective plan) | no closing entry | A-LEGAL-08 |
| CD-10 | Harden the LAN link (delay cap, slot and input validation, a dropped-PC notice, the… | no closing entry | A-NET-03 A-NET-07 A-NET-09 |
| CD-11 | Secret scanning, push protection, branch protection | no closing entry | A-LEGAL-15 |
| CD-12 | Desktop workflows can't publish an unlocked build | closed (has a commit or record) | A-TOOLS-01 |
| CD-13 | One store-readiness list with owners | no closing entry | A-LEGAL-14 |
| CD-14 | Accessibility (cue captions, Hit pause wired or removed, brace_key on pads, ship main's… | no closing entry | A-ACCESS-02 A-ACCESS-04 |
| CD-15 | Pose and look rules move to a creative rulebook | closed (has a commit or record) | none |
| CD-16 | Close the stale rows; commit RL-247 or remove citations to it; RL-248 to 255 back in the… | closed (has a commit or record) | none |
| CD-17 | Correct the overstated records | closed (has a commit or record) | none |
| CD-18 | Take process and engineering items out of the safety records | entry, with something still owed | A-PROCESS-20 |
| CD-19 | Check what players get: a daily job on /play/'s pin, the interim end date and the… | closed (has a commit or record) | none |
| CD-20 | Someone watches CI: the standup reads `gh run list` first | no closing entry | A-PROCESS-15 |
| CD-21 | Stop silent passes ("grandfathered", "report only", "CHECK" print as exceptions) | no closing entry | A-TOOLS-15 |
| CD-22 | Keep evidence: gate results saved under docs/<area>/runs/<sha>/ | no closing entry | A-RENDER-07 |
| CD-23 | Horizon tag and closing step on safety records; re-check at each baseline | no closing entry | A-QA-03 A-PROCESS-07 |
| CD-24 | Every delegated safety decision has a named owner and written conditions; "don't raise it… | no closing entry | A-PROCESS-12 |
| CD-25 | One machine-read list of Legal's clip conditions that blocks a pin | no closing entry | A-TOOLS-16 |
| CD-26 | (see the corrective plan) | no closing entry | A-TOOLS-17 |
| CD-27 | A public-repo content screen on every push | closed (has a commit or record) | none |

## C. Items with no register row (listed apart)

From the corrective plan: none. Every item without a closing entry, or with an open one, has a register row.



**From the EP's owed list:** the EP's list is in memory and summarised in docs/ep/sprints/A1-sprint.md; items on it with a register id are already rows in table A. Anything without one is added here by the EP.

**From QA's bug list** (qa/known-bugs.md; the register's row A-QA-03 says it holds 1 of the 52 problems Orb reported from 2026-11-01 to 2026-11-09, so it is not the whole bug list). Entries: KB-001 to KB-006 (the pinned prototype, open as coded, no release blocked) and GB-001 to GB-009. Not closed: GB-003 camera jolt on a knock-away (with Camera), GB-004 a design call, GB-005 mountain tumbles (with World), GB-007 rocks round a fast fighter (not reproduced), GB-009 the blaster's balance. Fixed but not re-verified in play: GB-002, GB-006. None has a register row; they are listed apart until QA's rows A-QA-03 and A-QA-07 re-read the list against the played build.

**From the parked folders** (docs/*/pending, file counts read 2026-11-14): accessibility 0, animation 9, architecture 17, art 4, audio 82, camera 53, combat 147, controls 57, director 161, narrative 20, net 2, perf 0, rendering 127, tools 139, ui 41, vfx 51, world 33 (943 files in all). A parked folder is not proof of unlanded work (grep main first); the EP's A-PROCESS-03 sorts them by owner.
