# UI: UI and the first-time player (Alpha audit, area 9)

Baseline 8901d351; game code as in the last played build, 6a30b4c9 (`git diff 6a30b4c9 8901d351 -- ui render/core` is empty). Read-only: nothing was run, so every "by reading" below is the code's text, not a result. "The Rail" is the new menu frame Orb picked on 2026-11-09 (a dark panel down the left edge). "Minimal HUD" is the switch that removes everything drawn on or near the fighters. Paths marked (uncommitted) are in `baseline-status.txt`.

## Summary

- **Works:** the notice-then-menu start, Reduce flashing on by default, pause and match-over lists on a pad (older layout), settings saved to the user folder, nothing sent by the game, and a HUD that keeps off the fighters with no health bar.
- **Does not:** with the Rail on, a pause shows no menu (a stopped clock, by reading); a plain desktop build can't save a report at all; developer keys, three of them flash keys, are live for anyone with a keyboard.
- **Biggest gap:** newcomer step 7 (X-21). The one-press report only writes a file in the patched Windows LAN program; a Deck tester has nothing to save and nothing to pack.
- X-05 and X-19 also fail on the menu's missing rows (modes, fighter, planet, quit): those are the MODES area's findings F-MODES-01, -06, -07, -13, not repeated here.

## Questions and answers

**Q1. The Rail menus: on in Orb's build by a switch, off on main. What's needed to make them the default?**
The switch is `menus_rail`, false on main (`ui/data/features.json:49`), on in Orb's build (`docs/tools/runs/6a30b4c9/pck-verify.txt:82`). Needed, in order:
1. Fix the pause with no menu (Q2, F-UI-01): it is a Rail fault.
2. Rewrite the three older HUD checks that fail with the switch on (`docs/ui/runs/592a807b/menus-rail/gate-switch-pinned-on.txt:1` (uncommitted): 8,288 checks, 3 failed, all reading the old card's words).
3. Move Tools' smoke test off fixed click points: its first run on this build failed because "the Rail start menu's button is not where the old clicks went" (`docs/tools/runs/6a30b4c9/build-and-smoke.txt:6`).
4. Add 1280 by 800 to the Rail's size list (`ui/tools/hud_check.gd:10824` has 1600x1000 but not the Deck's size) and save stills of every Rail screen; only the Start still is on file (`docs/ui/runs/592a807b/menus-rail/README.md:8` (uncommitted)).
5. Settle the match-over panel's side (Q8) and Orb's open question on the comfort switches (`docs/ui/menus-modern.md:79`; `docs/ui/menus-rail.md:48`).
6. Flip the flag, regenerate the strings page and the stretched-text test copies, and run the look gate's side-by-side.
The Rail keeps the older layout on touch screens and on anything under 1000 by 600 or narrower than 1.3 to 1 (`ui/widgets/ui_rail.gd:18`); the Deck's 1280 by 800 qualifies.

**Q2. The bugs Orb hit on 2026-11-09: a pause with no menu, and the start menu's d-pad.**
Both are open, unowned and unmeasured: QA "measured nothing for them" (`docs/qa/runs/6a30b4c9/README.md:33`), no UI commit follows 6a30b4c9, and the EP lists them under "No owner yet" (`questions.md:16`).
- *Pause with no menu.* By reading, the cause is a stopped clock. The Rail slides in over 180 ms, timed as "seconds since it opened" on the HUD's clock (`ui/hud/ui_hud.gd:2116`, `:2149`). That clock only moves in `advance(dt)` (`:512`), and the host passes 0 while the game is paused (`render/core/main.gd:811`); opening the pause menu is what pauses it (`:1326`). So the slide stays at 0 and the rail is drawn its whole width off the left edge, the detail card off the right (`ui/widgets/ui_pause.gd:356-357`), leaving only the dim. Reduce motion skips the slide (`ui/widgets/ui_rail.gd:28`), which would hide the bug for anyone with it on. The Rail's own test missed it because it steps the clock itself after opening (`ui/tools/hud_check.gd:10961-10972`). With the Rail off the older card has no slide, so main is not affected. Not reproduced: no run allowed. A second, smaller path to the same symptom: F2 swaps in the grey-box HUD, where pause is a bare freeze (`render/core/main.gd:1368-1369`).
- *Start menu d-pad.* By reading, two things match Orb's words. "Up and down inconsistent": a pad's Up on the top row jumps to the last row (`ui/hud/ui_hud.gd:1816-1818`), but every other move stops at the ends (`ui/widgets/ui_menu.gd:302-303`), so Down on the last row does nothing. "Left and right change the option underneath": Left or Right on Players sets one or two players (`ui/hud/ui_hud.gd:1708-1709`), and that swaps the third row between the computer's level and player two's device (`ui/widgets/ui_menu.gd:76-79`). Not reproduced.

**Q3. The notice screen, onboarding, how-to-play, on-screen hints, results and rematch.**
- *Notice:* works. The start menu opens at boot (`ui/hud/ui_hud.gd:448-451`) carrying Legal's words from data (`ui/widgets/ui_menu.gd:61-62`); the match starts on "I understand, start"; Reduce flashing is on unless a saved choice says off (`ui/hud/ui_hud.gd:1622`). The lock that would force it on is off on main (`ui/data/features.json:12`).
- *Onboarding:* a first-run How to play card (`ui/hud/ui_hud.gd:1168-1176`) and one-line hints. The guided first match is a proposal only (`docs/ui/tutorial-proposal.md:3`).
- *How to play:* seven pages (`ui/data/howto.json:10`, `:23`, `:60`, `:70`, `:85`, `:95`, `:109`). Its "Reading the fight" page is out of date: it describes a flashing ring, finishing-move rings, the planet strip and a damage box (`:73`, `:77`, `:78`, `:79`) that the minimal HUD no longer draws (`ui/hud/ui_hud.gd:771`, `:891`, `:802`, `:795`); nothing filters them (`ui/widgets/ui_howto.gd:180-193`). F-UI-11.
- *Hints:* beam teaching, struggle teaching, refusal words and launch marks are on; the lines for transformations, specials, brace and vanish are off until those presses are real (`ui/data/features.json:40`), and nothing names the signature inputs (F-UI-15).
- *Results and rematch:* the match-over card opens after any match a human played (`ui/hud/ui_hud.gd:523-527`), keeps the winner's line and the two world counts (`:2096-2105`), and Play again restarts with the last choices and no intro (`:2181-2189`). On the Rail it would hit the same stopped clock as the pause (see "Not evidenced").

**Q4. Every screen at 1280 by 800 (X-22).**
Not evidenced as pictures: no still at that size exists anywhere in the repository (search for "1280x800" in file names: none). What exists: the text-size check plans the older screens at 1280 by 800 (`ui/tools/text_size_check.gd:7`), two HUD rules include it (`ui/tools/hud_check.gd:9876`, `:9954`), and the text floor is 14 real pixels (`ui/core/ui_look.gd:12`, `ui/core/ui_text.gd:51-52`). No result of the text-size check is saved for this build. The Rail is not checked at that size (Q1).

**Q5. Settings that persist (X-20): where are they saved on Windows and on Linux?**
Two files in the engine's user folder: `user://ui_prefs.json` (options, the start menu's choices, hint counters; `ui/core/ui_prefs.gd:7`, `ui/hud/ui_hud.gd:2478`, `:1783`) and `user://input.json` (remapped controls; `sim/input/remap.gd:13`, `:421`). `project.godot` sets only the name "Orb Combat EX" (`:8`) and no custom folder, so the folder is the engine's default per-project one, named after the project: under the user's roaming application-data folder on Windows and under the user's local share folder on Linux. The exact paths are not written anywhere in the project and were not observed on a machine: not evidenced. A failed write is ignored without a word (`ui/core/ui_prefs.gd:36-38`).

**Q6. The report button and the feedback form.**
- *The one press* is F9, or View and RB together on a pad (`ui/hud/ui_hud.gd:3488-3495`), taught once in each of the first two matches (`:3504-3515`). It writes a file only when the host has set a report hook (`:3537`). Only the LAN kit sets it, in a patched scratch copy (`net/tools/lan_kit.mjs:58`); the game on main has no such line. So a plain desktop build answers "This build can't save a report yet" (`ui/data/terms.json:94`), and Save this match on the results card the same (`ui/hud/ui_hud.gd:3584`). A browser build downloads a small record instead (`:3540-3543`).
- *The feedback form* opens from Pause or the results card. Copy puts the text on the clipboard (`:3596-3600`). Send is hidden because the target is "none" (`ui/data/send.json:4`). With a pad it can only be closed (`ui/hud/ui_hud.gd:1402-1404`): tags, Copy and Save need a click or a tap.
- *F9 is also a host key:* it switches the split screen on or off (`render/core/main.gd:1560-1569`), and the HUD does not consume the press (`ui/hud/ui_hud.gd:3952-3953`).
- *Packing for Orb:* "Make my report folder" is Orb's own Windows tool: it needs the repository and Node, and writes to Orb's homework folder (`tools/preview/lan-report.mjs:4`, `:10`). Nothing exists for a tester.

**Q7. Nothing drawn on, over or between the fighters (taste page). Any exceptions in the build?**
In the UI layer, none found with the minimal HUD on, and it is on (`ui/data/features.json:15`): crown, beat ring, beam-struggle track, finisher rings, head label and strip are all gated (`ui/hud/ui_hud.gd:771`, `:778`, `:852`, `:891`, `:926`, `:802`). What stays is at the edges. Exceptions a player can reach: F2's grey-box HUD and F4's feed (F-UI-09). The EP's pointer to markers drawn by the perfect block and the zip (`questions.md:15`) is effects code, outside `ui/`: not checked here; it belongs to the RENDER and COMBAT areas.

**Q8. The match-over panel covering the player's own portrait.**
By reading, yes on the Rail: the panel is the full height of the screen at the left edge (`ui/widgets/ui_pause.gd:210`), 30% of the width (`ui/widgets/ui_rail.gd:44`), which is player one's plate corner. No still is on file (`docs/ui/runs/592a807b/menus-rail/README.md:8` (uncommitted)); the only statement that it was seen is the EP's note (`questions.md:16`), a pointer.

## Exit criteria

| Id | Status | Proof or gap | Measuring tool, and whether it exists |
| --- | --- | --- | --- |
| X-05 | gap | The menu can start two of eight modes (F-MODES-01); no quit row (F-MODES-13); on the Rail the pause list is not visible (F-UI-01). | Mode smoke suite: does not exist (F-MODES-09). The one smoke check clicks fixed points and broke on the Rail (`docs/tools/runs/6a30b4c9/build-and-smoke.txt:6`). |
| X-19 | gap | Notice and menu work on a pad; picks of mode, fighter and planet do not exist (MODES); pause on the Rail fails (F-UI-01); the d-pad is uneven (F-UI-06); How to play misdescribes the screen (F-UI-11). | The real-Deck checklist: does not exist (no tester guide in `git ls-files`). |
| X-20 | not measurable today | The saving code is there (F-UI-21); the only checks are in-process round trips (`ui/tools/hud_check.gd:7859`, `:5877`), not across a restart, not on Linux. | Settings round-trip test per platform: does not exist (F-UI-13). |
| X-21 | gap | No report is saved outside the Windows LAN program (F-UI-02); no tester-side packing, no Linux version, no size cap (F-UI-08). Nothing is sent automatically: met (F-UI-22). Discord's limit: 20 MB on one of its pages, 10 MB on others (`web-checks.md:25`). | Exists in part: the press and the words (UI), the LAN save (Netcode), Orb's folder tool (Tools). Missing: a save in the plain game, a Linux path, a cap. |
| X-22 | not measurable today | Text floor 14 px in code (F-UI-24); no still at 1280 by 800; the Rail unchecked at that size (F-UI-12). | Screen sweep at 1280 by 800: does not exist. `text_size_check` plans four sizes but saves no pictures and is not in CI. |

**Proposed numbers.** X-22: keep 9 px as the failing floor and 12 px as the aim, as the audit's web check proposes (`web-checks.md:35`); the code's own floor of 14 already clears both, so the sweep should fail on any text under 12, not 9. X-21: cap the report file at 10 MB, the lower of the two published figures; the one black-box play file on Orb's disk is 1.8 MB (`homework/Files/orb-first-play-20261107-1229.json`, private and git-ignored), and no LAN save was measured.

## Findings

Evidence is abbreviated here; the full list for each row is in `UI.findings.json`.

| id | kind | statement | evidence | criterion | severity | alpha | owner | cost | hash |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F-UI-01 | gap | With the Rail on, the pause menu's slide-in runs on a clock the game stops while paused, so the menu stays off the screen (by reading; not reproduced). | `ui/hud/ui_hud.gd:2149`, `:512`; `render/core/main.gd:811`, `:1326`; `ui/widgets/ui_pause.gd:356`; `docs/ep/vision.md:1683` | X-05, X-19, X-20, X-21 | blocker | required | ui-ux | S | no |
| F-UI-02 | gap | A plain desktop build saves no report and no match file: the hook that writes them exists only in the LAN kit's patched copy. | `ui/hud/ui_hud.gd:3537`, `:3545`, `:3584`; `ui/data/terms.json:94`; `net/tools/lan_kit.mjs:58` | X-21 | blocker | required | tools-pipeline | M | no |
| F-UI-03 | gap | Developer keys are live in every build, three of them flash keys: F8 (the shapes from before Legal's conditions, unless a lock that is off), Alt with a key (fires a flash), F7. Off Orb's page. | `render/core/main.gd:1588`, `:1593`, `:1524`, `:1582`; `ui/data/features.json:12` | X-02 | blocker | required | rendering-techart | S | no |
| F-UI-04 | gap | Making the Rail the default is unfinished: switch off, three checks fail with it on, the smoke test mis-clicks, no 1280 by 800 check, one still. | `ui/data/features.json:49`; `docs/ui/runs/592a807b/menus-rail/gate-switch-pinned-on.txt:1` (uncommitted); `docs/tools/runs/6a30b4c9/build-and-smoke.txt:6`; `ui/tools/hud_check.gd:10824` | X-05, X-19, X-22 | major | required | ui-ux | M | no |
| F-UI-05 | gap | The Rail's match-over panel covers the left 30% of the screen, player one's plate corner; no still on file. | `ui/widgets/ui_pause.gd:210`; `ui/widgets/ui_rail.gd:44`; `questions.md:16` | X-19 | major | required | ui-ux | S | no |
| F-UI-06 | gap | The start menu's d-pad is uneven: Up wraps at the top, Down stops at the bottom, and Left or Right on Players swaps the row two below. | `ui/hud/ui_hud.gd:1816`, `:1708`; `ui/widgets/ui_menu.gd:302`, `:76`; `docs/ep/vision.md:1690` | X-19 | major | required | ui-ux | S | no |
| F-UI-07 | gap | The feedback panel cannot be worked with a pad: B or Start close it and nothing else answers. | `ui/hud/ui_hud.gd:1402`, `:1406` | X-19, X-21 | major | required | ui-ux | S | no |
| F-UI-08 | gap | The report-folder tool is Orb's own Windows tool (repository and Node needed, no size cap); nothing packs a tester's report or works on Linux. | `tools/preview/lan-report.mjs:4`, `:10`; `net/tools/lan_kit.mjs:28`; `web-checks.md:25` | X-21 | major | required | tools-pipeline | M | no |
| F-UI-09 | gap | F2, F3, F4 and F6 reach a tester: a grey-box HUD with MENACE and ANGUISH bars, debug text and a pause with no menu, a performance overlay, the debug feed, effects off. | `render/core/main.gd:1543`, `:1546`, `:1549`, `:1368`; `render/core/hud.gd:121`, `:230`; `docs/ep/taste.md:28` | X-19 | major | required | rendering-techart | S | no |
| F-UI-10 | gap | F9, taught as the report key, also switches the split screen in the host; Escape in play closes the desktop game at once. | `ui/hud/ui_hud.gd:3488`, `:3953`; `render/core/main.gd:1566`, `:1596` | X-19, X-21 | major | required | rendering-techart | S | no |
| F-UI-11 | gap | How to play's "Reading the fight" page describes four things the minimal HUD no longer draws. | `ui/data/howto.json:73`, `:77`, `:78`, `:79`; `ui/hud/ui_hud.gd:771`, `:795`, `:802`, `:891` | X-19 | major | required | ui-ux | S | no |
| F-UI-12 | gap | X-22 cannot be measured: no still at 1280 by 800 and no sweep tool. | `ui/tools/text_size_check.gd:7`; `ui/tools/hud_check.gd:10824`; `I-05-ui-audio-loc.md:9` | X-22 | major | required | ui-ux | S | no |
| F-UI-13 | gap | X-20 has no test across a restart or on Linux; a failed save is silent; the folder is written down nowhere. | `ui/tools/hud_check.gd:7859`; `ui/core/ui_prefs.gd:36`, `:7`; `project.godot:8` | X-20 | major | required | ui-ux | S | no |
| F-UI-14 | gap | No UI check runs in CI; the 8,288-check suite is run by hand. | `I-05-ui-audio-loc.md:9`; `docs/ep/runs/6a30b4c9/gate-full-s415.txt:123` | X-05 | major | nice | tools-pipeline | S | no |
| F-UI-15 | gap | Teaching for transformations, specials, brace and vanish is off, and nothing names the signature inputs. | `ui/data/features.json:40`, `:3`; `ui/widgets/ui_howto.gd:198`; `ui/data/howto.json:36` | X-19 | minor | required | ui-ux | S | no |
| F-UI-16 | gap | Settings lists two rows that do nothing: Beat ring and Show recipe. | `ui/data/settings.json:46`, `:47`; `ui/hud/ui_hud.gd:778`; `ui/widgets/ui_recipe.gd:3` | none | minor | nice | ui-ux | S | no |
| F-UI-17 | gap | First-time help is the card and hints only; the guided first match is a proposal. | `docs/ui/tutorial-proposal.md:3`; `docs/ep/vision.md:249` | X-19 | minor | nice | game-design | M | no |
| F-UI-18 | gap | Leftovers of the hero and villain meters and of hiding remain in UI code and words, unseen. | `ui/core/ui_sim_bridge.gd:9`; `ui/data/terms.json:9`; `ui/widgets/ui_plate.gd:444`; `ui/data/features.json:5` | none | minor | after | ui-ux | S | no |
| F-UI-19 | gap | Three UI pages or headers state a status the code has passed (minimal HUD "off", report "parked", prefs "one value"). | `docs/ui/minimal-hud.md:3`; `docs/ui/lan-report.md:3`; `ui/core/ui_prefs.gd:4` | none | minor | nice | ui-ux | S | no |
| F-UI-20 | works | The notice comes first, the match starts only on "I understand, start", and Reduce flashing defaults on. Off Orb's page. | `ui/hud/ui_hud.gd:448`, `:1622`; `ui/widgets/ui_menu.gd:61` | X-19, X-02 | none | n/a | ui-ux | n/a | no |
| F-UI-21 | works | Settings are saved on change and read at start-up, in two files in the user folder. | `ui/hud/ui_hud.gd:2478`, `:2485`, `:1783`; `sim/input/remap.gd:421` | X-20 | none | n/a | ui-ux | n/a | no |
| F-UI-22 | works | Nothing in the game code sends data by itself; Send is hidden. | `reads/RR-04.md:420`; `ui/data/send.json:4`; `ui/widgets/ui_feedback.gd:288` | X-21 | none | n/a | ui-ux | n/a | no |
| F-UI-23 | works | The UI layer draws nothing on, over or between the fighters with the minimal HUD on, and there is no health bar. | `ui/data/features.json:15`; `ui/hud/ui_hud.gd:771`, `:778`, `:852`, `:891`; `ui/widgets/ui_plate.gd:3` | X-15 | none | n/a | ui-ux | n/a | no |
| F-UI-24 | works | The UI's text floor is 14 real pixels, above the Deck guidance's 9 and 12. | `ui/core/ui_look.gd:12`; `ui/core/ui_text.gd:52`; `web-checks.md:35` | X-22 | none | n/a | ui-ux | n/a | no |
| F-UI-25 | works | The HUD suite passed on the played build's code with the Rail off: 8,288 checks, 0 failed. | `docs/ep/runs/6a30b4c9/gate-full-s415.txt:123` | none | none | n/a | ui-ux | n/a | no |
| F-UI-26 | works | Pause, results and rematch are wired for a pad on the older layout. | `render/core/main.gd:1456`; `ui/hud/ui_hud.gd:2257`, `:2270`, `:2101`, `:2181` | X-19 | none | n/a | ui-ux | n/a | no |

Owner notes. `render/core/` is Rendering's by its owns line (`DIRECTORS.md:647`), so the host's keys (F-UI-03, -09, -10) sit there, though the fix is a build switch UI and Tools will also touch. F-UI-01 is placed with UI because the Rail can keep its own clock without a host change. F-UI-02 follows the specification's own column for X-21 (Tools), with UI, Rendering and Netcode needed. No cost has a comparable job on record: every cost is "estimate, no comparable". No finding changes the sim's state hash.

## Gaps the questions missed

- **Developer keys in a tester's hands** (F-UI-03, F-UI-09, F-UI-10). The questions ask about on-screen exceptions, not about keys that produce them. The three flash keys are the serious ones and go to the EP, not to Orb's page.
- **The report does not exist outside LAN** (F-UI-02). The question assumes a report button; in the game a tester would get, it answers that it can't.
- **The feedback form on a pad** (F-UI-07).
- **How to play describes a HUD that was removed** (F-UI-11).
- **Settings rows that do nothing** (F-UI-16), against the project's own rule that "a setting never does nothing" (`ui/data/features.json:3`).
- **No window or full-screen setting.** `project.godot` has no display section (its sections are application, audio, rendering, shader_globals: lines 6, 12, 16, 21) and no option in `ui/data/options.json`'s display group sets one. On a Deck the system shows games full screen; on Windows the game opens in the engine's default window. Not raised as a finding here: it belongs with the PERF area's platform rows.
- **A pad pulled out mid-match** is only forgotten by the input hub (`render/core/main.gd:1495-1499`); no pause and no notice was found. That is X-07, the CONTROLS area's.
- **Leaving the game with a pad:** no quit row (F-MODES-13). Not repeated.

## Not evidenced

| What could not be checked | The one measurement that settles it |
| --- | --- |
| That the stopped clock is what Orb saw as "a pause with no menu" | One still of the pause screen from a Rail build, Reduce motion off, then on. |
| Whether the Rail's match-over panel shows at all in the real game (the same clock stops there: `ui/hud/ui_hud.gd:527`, `render/core/main.gd:1326`) and, if it does, what it covers | One still at match over from the same build. The EP's note that it covers the portrait and this reading can't both hold as stated; the still decides. |
| What Orb felt on the start menu's d-pad beyond the two behaviours read | A recorded pad session on the start menu (presses and the lit row). |
| Any screen's look at 1280 by 800 | The screen sweep (F-UI-12). |
| Where the two settings files land on Windows and on a Deck, and that they survive a restart | Start, change three settings, quit, start again, on each platform; note the folder. |
| Whether one F9 press both saves a report and switches the split | Press F9 once in a LAN build with split screen on. |
| Whether F8 overrides Reduce flashing or only changes shapes | Legal's and VFX's read of `flash_view.legacy`; outside `ui/`. |
| The size of a saved LAN match file after a long match | `wc -c` on one real save; none was found on disk. |
| Whether the feedback panel is usable by touch on a Deck, and whether its text box raises the Deck's keyboard | A Deck tester's two-minute try. |
| A result of `text_size_check` or the overflow check on 6a30b4c9 | Run both and save the output under `docs/ui/runs/6a30b4c9/` (no such folder exists). |
| Markers drawn by effects code on the fighters (the EP's pointer) | The RENDER area's read of `render/vfx/`. |

## Decisions for Orb

1. **Are the Rail menus the Alpha's menus?** You picked the look on 9 November; they are still switched off outside your own build. *Recommended: yes, once the pause fault is fixed and the screens are checked at the Deck's size.*
2. **When a match ends, where should the result panel sit?** Today's Rail puts it down the left edge, over player one's corner. *Recommended: keep it off the winner's corner (for one player, off your own).*
3. **Should the comfort switches (Intros, Captions, Move guide, Screen shake, Reduce flashing) stay on the start screen or move to Options?** UI asked on 8 November and has no answer. *Recommended: keep Reduce flashing on the start screen beside the notice and move the other four to Options.*
4. **Should a tester's report be one small file they post themselves, with clips left out?** *Recommended: yes: one file under 10 MB, saved by one press in every build, with a line on screen saying where it is.*

The flash keys (F-UI-03) are not on this list: they go to the EP under the delegated-safety rule.
