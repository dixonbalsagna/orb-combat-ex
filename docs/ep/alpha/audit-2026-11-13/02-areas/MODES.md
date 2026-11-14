# MODES: modes and match flow

Alpha audit, area review. Baseline 8901d351 (game code as in the last played build, 6a30b4c9). Read-only; nothing was run. Reading request RR-03 had no answer file when this was written, so its reading was done here. None of the paths cited below is listed in `baseline-status.txt`. Paths under `homework/Files/builds/` are the kept builds' own files (git-ignored), cited as `build:<folder>:<file>`.

## Summary

- **Works:** solo against the computer at three levels and two players on one PC both start from the start menu with a pad, play to a knockout, and offer Play again, Menu and Send feedback on a match-over card.
- **Works in private only:** LAN 1v1 and a LAN 2v2 (two humans against two computer fighters) run from Windows shortcut files in a separately made folder, one match per launch.
- **Does not exist:** a list of modes, fighter select, planet select or custom planet, couch 2v2, the horde mode, a practice mode, and any campaign screen.
- **Biggest gap:** the game has one start screen that can only say "one player or two". Six of the eight Alpha modes cannot be started from it (X-05), and the horde mode (X-10) has no design page and no code.
- Seven blockers, six majors, four minors, five things that work.

## Questions and answers

### Q1. For each of the eight modes: menu entry, start, finish, rematch, leave with a pad; what's missing

The start menu's rows are fixed in `ui/widgets/ui_menu.gd:8` and built per state at `:74-86`: Players (one, two), Player 1 device, Player 2 device or the computer's level, five comfort boxes, Start. The host turns them into a match at `render/core/main.gd:1337-1362`. The pad's D-pad, A, B and Start drive it (`ui/hud/ui_hud.gd:1811-1830`).

| Mode | Menu entry | Start with a pad | Finish | Rematch | Leave | What's missing |
| --- | --- | --- | --- | --- | --- | --- |
| Solo against the computer | Yes: Players "one" plus the level row (`ui_menu.gd:79`, `:284-288`) | Yes (`ui_hud.gd:1811-1830`, `main.gd:1337-1348`) | Knockout; the match-over card opens (`ui_hud.gd:523-526`) | Yes: Play again (`ui_pause.gd:12`, `ui_hud.gd:2181-2189`) | To the menu yes (`ui_hud.gd:2178-2180`); no quit row (F-MODES-13) | Fighter and planet picks; the ending rules are off on main (F-MODES-08); no saved smoke run per platform |
| Two players on one PC | Yes: Players "two" (`ui_menu.gd:76-77`) | Yes; devices claimed at `main.gd:1350-1361` | As solo | As solo | As solo | Same as solo. Pad unplugged mid-match is the CONTROLS area's (X-07) |
| LAN 1v1 | **No.** Windows shortcut files only (`build:orb-lan-6a30b4c9:Host (main PC).cmd`, `Join (old PC).cmd`); flags read at `net/lan.gd:116` | Only after the shortcut: then the normal start menu on each PC (`net/tools/lan_words.txt` step 6) | Knockout; the window title says the match is over (`net/lan.gd:386`) | **No:** "One match only", close both windows (`net/tools/lan_words.txt:38`) | Close the window | A Host and Join row, an address entry, Linux, rematch, picks (F-MODES-04, -05, -11) |
| LAN 2v2 | **No.** Shortcut files (`Host 2v2 together (main PC).cmd`, `Host 2v2 (main PC).cmd`); flags at `net/lan.gd:117`, `:129-130` | As LAN 1v1 | The match ends when a team has nobody standing (`sim/core/sim.gd:460-463`) | No | Close the window | As LAN 1v1; also only one line-up and the partner's fight is not drawn (F-MODES-10) |
| Couch 2v2 | **No** | **No:** the host never asks for two fights (`main.gd:1337-1348`); the input hub has two slots (`sim/input/hub.gd:26-28`) | n/a | n/a | n/a | The whole mode on one PC (F-MODES-03) |
| Co-op horde | **No** | No | n/a | n/a | n/a | Design page and build (F-MODES-02) |
| Custom planet setup | **No:** "the menu has no such choice yet" (`main.gd:441-442`) | No. A seed can be given only on the command line (`main.gd:33`, `:261`) or by a page word in a private preview copy (`tools/preview/switches.mjs:623-628`) | n/a | n/a | n/a | The picker and the four dials (F-MODES-07) |
| Campaign | **No** | No: no host calls it (`sim/core/run.gd:391` is the only game caller of `SimCampaign`) | n/a | n/a | n/a | Everything above the sim groundwork (F-MODES-16) |

"On Windows and on Linux" is **not evidenced** for any mode: the one smoke record is the browser build (`docs/tools/runs/6a30b4c9/build-and-smoke.txt`), and `gh run list --workflow desktop-builds.yml` returned no runs.

### Q2. Fighter select and planet select: do they exist?

**No to both.**
- Fighters: a match's fighters default to the first two ids of the roster file (`sim/core/sim.gd:202`; `data/fighters/roster.json:1`). No menu row or host code sets the `slots` setup key. The sim would accept one (`sim/core/roster.gd:53-59`).
- Planet: `render/core/main.gd:443-449` reads a `planet` key from the menu's choices, but the menu never sets one (comment at `:441-442`). A loading screen for a chosen planet exists (`main.gd:452-464`).

### Q3. The horde mode: design page, smallest version for X-10, what it reuses

- **Design page: none.** "Horde" appears only as a campaign stage type (`docs/design/campaign.md:66`, `:78-79`, `:87`) and in the henchmen page, which says "Paper only: no data file, nothing built" (`docs/combat/henchmen-grades.md:3`). Game Design's rulings on that page are recorded (`:5-12`).
- **What exists to reuse:**
  - The many-body match ("one versus many"): two principals plus up to three more bodies, five in all (`sim/core/roster.gd:36-40`); only a principal's knockout ends the match (`:44-47`). No waves, no respawn (no such code in `sim/core` or `sim/director`).
  - The many-body camera and animation (`render/camera/split_rig.gd:3460`, off by default; `render/anim/anim_many.gd:3`).
  - The henchmen grades as a paper spec, with test bands ("a wave of 12 fodder falls ... in 10 to 20 s", `henchmen-grades.md:183`).
  - The cross-fight mail of 2v2 (`sim/core/cross.gd`, switch off in data, `data/fight/cross.json:4`; on per match by setup key, `net/lan.gd:32`) for two players in different fights.
  - Research's study of co-op shapes and its smallest slice (`docs/research/co-op-brawler.md:141-172`), which itself defers grunts.
- **Smallest version that meets X-10 (a proposal for Game Design's page, not a design):** one or two players on one PC as one team; weak bodies of the lowest two grades arrive in waves through the existing many-body slots; a fallen body's slot is refilled (the respawn) until the wave's count is spent; a run is a fixed number of waves and ends on the last wave cleared or the players down; the result screen is the existing match-over card with waves cleared. The wave's size on screen is the open design number: the sim holds five bodies today against the page's wave of twelve.
- **X-10's proposed numbers:** the project's own record for a horde *stage* is 3 to 7 minutes (`docs/design/campaign.md:66`). A stand-alone run of several waves at 5 to 10 minutes is consistent with it; no record contradicts it. Confirm on the design page.

### Q4. Couch 2v2: which line-ups are possible with split screen today?

**None.** The split screen draws two panes, one per fighter of a single two-body fight (`render/core/main.gd:54`, `:467-474`). The host starts only `{p1, p2}` matches (`main.gd:1339`) and the input hub holds two slots (`sim/input/hub.gd:26-28`). The sim can run two fights with four bodies (`sim/core/stage.gd:59-62`) and a private flag can draw the other fight (`main.gd:242`, off). The design record's first line-up is two humans against two computer fighters, with four humans "for later" (`docs/design/two-v-two.md:20-22`). Whether a computer *partner* exists is the AI area's question; the LAN 2v2 seats are human, computer, human, computer (`net/lan.gd:34`).

### Q5. A practice mode with the dummy: place it

The dummy is in the roster file as the third id (`data/fighters/roster.json:1`; `data/fighters/REFERENCE/fighter.json:3-5`, role "reference"). Orb ticked "Put it in the roster as a training dummy" (`docs/ep/vision.md:1263`) and the first scope table lists a training sandbox for 1.0 (`:31`). Nothing can start a match with it (Q2). **Placement: nice to have for Alpha, after the mode row and fighter select** (F-MODES-14): once those two exist, Practice is a solo match with the dummy in the second slot. Whether the computer can be told to stand still is not evidenced.

### Q6. What ends a match, and is each built?

| Ending | Built? | Evidence |
| --- | --- | --- |
| Knockout | Yes | `sim/core/sim.gd:460-463` |
| 2v2: a team with nobody standing | Yes, in CI | `sim/core/sim.gd:461-462`; `.github/workflows/ci.yml:243` |
| Knockout only by a finishing move; wear for an idle player; the last event | Written; **off on main, on in both kept builds** | `sim/director/ending.gd:3-13`; `data/director/interrupts.json:251`; `build:orb-lan-6a30b4c9:tree/data/director/interrupts.json:251` |
| Time cap ("the planet giving way") | The rule is built: at 660 s every decisive win on a fighter at the brink is a finisher, with a pause (840 s in 2v2). **A picture of the planet giving way: not evidenced** | `data/combat/finishers.json:15`; `data/fight/cross.json:14`; `sim/director/exchange.gd:721-730`; `sim/core/pause.gd:23-24` |
| No contest (nobody played since the cap) | Written, with the ending rules | `sim/director/ending.gd:7-8`; `ui/hud/ui_hud.gd:525` |

### Q7. The campaign: what exists; minimal or none

- `sim/core/campaign.gd` (480 lines): an episode's state, seeds and route bookkeeping, behind one switch that is off (`campaign.gd:3-7`; `data/fight/campaign.json:4`). Its only caller in the game is a validity check (`sim/core/run.gd:391`); two tools drive it and neither is in CI (`sim/core/tools/campaign_episode.gd`, `campaign_recipes.gd`; `01-inventory/I-01-sim-core-input.md:53`).
- `sim/core/run.gd` (570 lines): the run's state and the pick of each stage's ground; "Nothing here runs in a match's tick" (`run.gd:3-11`); switch off (`data/fight/run.json:5`).
- `sim/core/boons.gd` (126 lines): three run-only starting-form boons, applied only when a setup names one (`boons.gd:3-5`).
- No screen, no host, no stage types (horde, defence, pursuit) built.
- **Recommendation: none for Alpha.** Orb put it last ("least priority on the campaign", `docs/ep/vision.md:1727`); every stage type but the duel is unbuilt; and the horde mode is the campaign's horde stage made stand-alone, so Alpha still tests the campaign's riskiest piece.

## Exit criteria

| Id | Status | Proof or gap | Measuring tool, and whether it exists |
| --- | --- | --- | --- |
| X-05 | **Gap** | Two of eight modes start from the menu (Q1). LAN has no menu entry, no rematch, no Linux launcher. Four modes do not exist | Mode smoke suite: **missing.** Precursors: `tools/preview/smoke.mjs` (browser build, fixed click points) and `tools/preview/wake-steps-padonly.json` (pad-only start steps) |
| X-09 | **Gap** | No line-up is possible (Q4). Line-ups not decided for couch; the LAN record names two humans against two computer fighters first (`docs/design/two-v-two.md:20`) | Manual checklist: missing. Decision: Game Design's, then Orb's (see Decisions) |
| X-10 | **Gap** | No design page, no code (Q3). Proposed 5 to 10 minutes: keep, consistent with the 3 to 7 minute horde stage (`docs/design/campaign.md:66`) | Mode smoke: missing. Frame-time record at the largest wave: not measurable until a wave exists; Performance's bench is another area's |
| X-11 | **Gap** | No picker; the generator takes a seed only (`sim/world/planet.gd:328`) | Planet hash check: **exists in part.** `sim/world/tools/planet_digest.gd` prints fingerprints with no verdict and is excluded from the world checks (`tools/world-checks.json:32`); nothing compares Windows with Linux |
| X-12 | **Not decided** | Recommendation here: none for Alpha (Q7). Orb's decision | None needed |

## Findings

Gaps first by severity, then things that work. Full fields (cost basis, risk, other directors) are in `MODES.findings.json`.

| Id | Kind | Statement | Evidence | Criterion | Severity | Alpha | Owner | Cost | Hash |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F-MODES-01 | gap | The start menu has no list of modes; six of eight Alpha modes have no menu entry | `ui/widgets/ui_menu.gd:8`, `:74-86`; `render/core/main.gd:1337-1348` | X-05, X-19 | blocker | required | ui-ux | M | no |
| F-MODES-02 | gap | The horde mode does not exist: no design page, henchmen are paper only, the many-body match holds five bodies with no waves or respawn | `docs/combat/henchmen-grades.md:3`, `:183`; `sim/core/roster.gd:36-40` | X-10, X-05 | blocker | required | game-design | XL | yes |
| F-MODES-03 | gap | Couch 2v2 cannot be started: the host starts two-body matches only and the input hub has two slots | `render/core/main.gd:1337-1362`; `sim/input/hub.gd:26-28`; `net/lan.gd:32-35` | X-09, X-05 | blocker | required | rendering-techart | L | no |
| F-MODES-04 | gap | LAN play is a separate private Windows program started by shortcut files, with the host's address baked in; desktop exports leave the network code out | `net/lan.gd:3-4`; `net/tools/lan_kit.mjs:1-3`, `:11-14`; `export_presets.cfg:55`, `:101` | X-05, X-08 | blocker | required | netcode-online | L | no |
| F-MODES-05 | gap | A LAN match cannot be rematched or left to a menu: one match, then close both windows | `net/lan.gd:386`; `net/tools/lan_words.txt:38` | X-05, X-08 | blocker | required | netcode-online | M | no |
| F-MODES-06 | gap | There is no fighter select: player one is always the Protagonist, player two always the rival | `sim/core/sim.gd:202`; `data/fighters/roster.json:1` | X-05, X-19 | blocker | required | ui-ux | M | no |
| F-MODES-07 | gap | Custom planet setup does not exist: no planet row, and the generator takes a seed only (no size, cities, climate, water) | `render/core/main.gd:441-449`; `sim/world/planet.gd:328`; `sim/world/planet_world.gd:206-211` | X-11, X-05, X-19 | blocker | required | world-environment | L | yes |
| F-MODES-08 | gap | The match-ending rules of the played build are off on main and on only in the kept builds | `data/director/interrupts.json:250-251`; `build:orb-lan-6a30b4c9:tree/data/director/interrupts.json:251` | X-05, X-13 | major | required | encounter-systems | S | yes |
| F-MODES-09 | gap | No mode smoke suite: one browser smoke that clicks fixed points (it failed once when the menu moved), a Linux bench in a workflow with no run on record | `tools/preview/smoke.mjs:1-6`; `docs/tools/runs/6a30b4c9/build-and-smoke.txt`; `.github/workflows/desktop-builds.yml:108-113` | X-05 | major | required | tools-pipeline | M | no |
| F-MODES-10 | gap | LAN 2v2 has one line-up (a human on each PC against two computer fighters) and each screen shows only its own fight | `net/lan.gd:34-35`; `net/tools/lan_words.txt:26`; `render/core/main.gd:242`; `docs/ep/vision.md:1662` | X-08, X-09 | major | required | rendering-techart | L | no |
| F-MODES-11 | gap | Every LAN match is the same: seed, planet and fighters are constants in the LAN code | `net/lan.gd:26`, `:30-35` | X-08, X-11 | major | required | netcode-online | M | no |
| F-MODES-12 | gap | X-11's planet hash comparison is not a check: the fingerprint tool has no verdict, and CI runs on Linux only | `sim/world/tools/planet_digest.gd:2-4`; `tools/world-checks.json:32`; `.github/workflows/ci.yml:389` | X-11 | major | required | world-environment | S | no |
| F-MODES-13 | gap | No quit row for a pad; the keyboard's Escape closes the game at once with no question | `ui/widgets/ui_pause.gd:8-14`; `render/core/main.gd:1596-1598` | X-05, X-19 | major | required | ui-ux | S | no |
| F-MODES-14 | gap | No practice mode: the dummy is in the roster file but nothing can put it in a match | `data/fighters/roster.json:1`; `data/fighters/REFERENCE/fighter.json:3-5`; `docs/ep/vision.md:1263` | X-19 | minor | nice | game-design | M | no |
| F-MODES-15 | gap | The time cap is a rule at 11 minutes with a pause; no picture of the planet giving way was found, and the cap is above X-13's 6 to 8 minute match | `data/combat/finishers.json:15`; `sim/director/exchange.gd:721-730`; `render/camera/split_rig.gd:1640` | X-13 | minor | nice | game-design | S | yes |
| F-MODES-16 | gap | The campaign is sim groundwork only, switched off, with no host and no screen; recommend none for Alpha | `sim/core/campaign.gd:3-7`; `data/fight/campaign.json:4`; `sim/core/run.gd:391` | X-12 | minor | after | orb | n/a | no |
| F-MODES-17 | gap | The Rail menu Orb picked is off on main and on only in the played build | `ui/data/features.json:49`; `ui/widgets/ui_rail.gd:3-5`; `docs/tools/runs/6a30b4c9/build-and-smoke.txt` | X-05, X-22 | minor | required | ui-ux | S | no |
| F-MODES-18 | works | Solo starts from the menu with a pad; the level row lists the three levels in the data and passes the choice to the match | `ui/hud/ui_hud.gd:1811-1830`; `ui/widgets/ui_menu.gd:10-13`; `data/director/ai.json:52-53`; `render/core/main.gd:1342` | X-05 | none | n/a | ui-ux | n/a | no |
| F-MODES-19 | works | Two players on one PC start from the menu; a missing second pad falls back to the computer | `render/core/main.gd:1350-1361`; `ui/hud/ui_hud.gd:1771-1774` | X-05 | none | n/a | ui-ux | n/a | no |
| F-MODES-20 | works | The match-over card offers Play again, Menu and Send feedback; Play again keeps the choices and skips the intro | `ui/widgets/ui_pause.gd:12-14`; `ui/hud/ui_hud.gd:2178-2189` | X-05 | none | n/a | ui-ux | n/a | no |
| F-MODES-21 | works | The sim already takes fighters, a second fight and a planet seed as setup keys, and a 2v2 ends by team; most missing modes are menu and host work | `sim/core/sim.gd:201-202`, `:460-463`; `sim/core/stage.gd:59-62`; `.github/workflows/ci.yml:243` | X-05, X-09 | none | n/a | simulation-engine | n/a | no |
| F-MODES-22 | works | The played build's LAN folder passed its nine self-test rows with no script errors and all state checks matched; the LAN check is in CI | `docs/net/runs/6a30b4c9/lan-folder/lan-loop-rows.txt`; `.github/workflows/ci.yml:354-356` | X-08 | none | n/a | netcode-online | n/a | no |

Owner notes: `render/core/main.gd` and `sim_host.gd` (the game's host) fall under Rendering's owned path `render/core/` (`DIRECTORS.md:647`), which is why two host findings carry that slug; the specification's own note that no single director owns "a mode from menu to result" (line 388) stands, and the judgment session may prefer to name a lead for the whole flow.

## Gaps the questions missed

1. **LAN on Linux.** Every launcher in the LAN folder is a Windows file (`.cmd`, `.ps1`, `.exe`: `build:orb-lan-6a30b4c9`), and its firewall step is Windows-only (`net/tools/lan_words.txt` steps 1 and 8). Two Steam Deck testers cannot play LAN with each other or with a PC today (inside F-MODES-04).
2. **LAN is fixed to one match** in every sense: one seed, one planet, one pair (F-MODES-11).
3. **No way to close the game with a pad**, and Escape closes it with no question (F-MODES-13).
4. **Main is not the build Orb played for match flow:** the ending rules (F-MODES-08) and the Rail menu (F-MODES-17) are both off on main. A candidate built from main's data would differ from the judged build in how a match ends and what the menu looks like.
5. **The menu asks "keyboard or controller" per player** (`ui/widgets/ui_menu.gd:290`) before play. On a Deck that is a question with one right answer; the code already corrects it when Start is pressed on a pad (`ui/hud/ui_hud.gd:1773-1774`). A small point for the newcomer flow (X-19), not a separate finding.
6. **The many-body limit of five** (`sim/core/roster.gd:40`) is below the henchmen page's wave of twelve (`docs/combat/henchmen-grades.md:183`); the horde's design page has to settle which gives (inside F-MODES-02).
7. **Leftovers of post-Alpha work in this area's code:** the campaign, run and boons files (about 1,180 lines, switches off) stay in the sim's compile and warm-up (`inventory.md:17` names `render/core/boot_entry.gd:23`). Harmless while off; say so in the X-12 decision so nobody builds on them during Alpha.

## Not evidenced

| What | What one measurement would settle it |
| --- | --- |
| That solo and two-player play start, finish, rematch and return to the menu on the **Windows and Linux desktop builds** | One pad-only smoke run per mode on each desktop build, saved under `docs/tools/runs/<sha>/` |
| That a real two-PC LAN match completes with no state mismatch on 6a30b4c9 (the record on file is the folder's self-test, `lan-loop-rows.txt`; the EP lists "the first real LAN save through lan-report" as owed, `questions.md:16`) | The two PCs' `saved` folders and `lan-log` files from one played match, read by `tools/preview/lan-report.mjs` |
| The EP's pointers "a pause with no menu", "the start menu's d-pad" and "the match-over rail covers the left portrait" (`questions.md:16`) | A still of each screen from the played build with the pad steps that led to it |
| Whether the computer can be set to stand still for a practice dummy | A read of `data/director/ai.json` levels and `sim/director/ai.gd` by the AI area |
| Whether the time cap shows anything on screen beyond the pause and the frozen clock | One scripted match run past 660 s with stills at the cap |
| Whether a mirror match (the same fighter twice) reads on screen | One still of a match started with the `slots` key naming one fighter twice |
| Same seed, same planet on Windows and Linux | `planet_digest.gd` run on both platforms and the lines compared |

## Decisions for Orb

1. **Campaign for Alpha: minimal or none?** Recommendation: **none.** The sim groundwork stays switched off; the horde mode carries the campaign's horde stage into Alpha.
2. **Couch 2v2's line-up for Alpha?** Recommendation: **two humans as a team against two computer fighters**, on a two-way split, the same line-up as LAN 2v2. Four pads after Alpha.
3. **Do outside testers get LAN inside the Alpha build?** Recommendation: **yes**, as a Host and Join row, with Legal reviewing the rule that keeps network code out of desktop builds. Otherwise LAN 1v1 and 2v2 stay a private folder and cannot count toward X-05 for testers.
4. **Is a first horde of small waves enough?** Recommendation: **yes**: one or two players against waves that put at most three weak bodies on the field at a time (today's limit), with bigger waves after Alpha.
5. **If the four planet dials slip, is a seed picker with a few presets an acceptable first custom planet?** Recommendation: **yes.**
6. **Practice against the dummy as a ninth mode?** Recommendation: **yes, as nice-to-have**, built only after the mode row and fighter select.
