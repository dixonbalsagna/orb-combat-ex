# GW1a landing review by the stand-in (2026-11-20)

**Who:** Orb's stand-in, as the landing reviewer of sprint A1. Six reviewers read the stack; a checker tried to refute every blocker and major; this page is the merged result.

**When:** the evening of 2026-11-20.

**What was reviewed:**
- main at d55c612f, and the EP's applied tree (s422) at commit 3917885, which is that main plus the 59 patches of the stack;
- every park's README (a park is a patch waiting in a `docs/*/pending/` folder);
- the kept 9 November build (6a30b4c9), its pack, its switch list and the golden target record;
- the earlier review, `docs/ep/reviews/GW1a-review.md`.

**How:** read-only. Nothing was run: no Godot, no browser, no gate. The repo's HEAD had moved to 8baf6f8a by the time this was written.

**Which copy was read:** one park differs between the repo and the applied tree. `docs/world/pending/checks-gw1a/pins-gw1a.diff` was re-cut in 554430ad (the wrecks_check row only). The repo's current file is the one reviewed; the applied tree holds the older one (S-19).

Words used here:
- **pin:** a change to a check's expected value, set-up or scope so it passes on the new tree;
- **ceiling:** a row that holds a known fault at today's number, so it can't get worse unseen;
- **golden:** the recorded hashes of a fixed set of matches that the sim must reproduce;
- **strip ground / globe ground:** the old flat ground and the round one the 9 November build drew.

## Verdict

**Land after named fixes.** No blocker stands, the stack merges cleanly, and the tree's golden is the target byte for byte. Before the landing commit the EP rules on S-01 and S-03, takes Art's file (S-02), keeps the recorder's check out of the game's real reports folder (S-05), records one reference on the world the game really plays (S-07) and rebuilds the tree with World's current pins (S-19); the other majors are owned follow-ups with a date.

## The two re-cuts

| Re-cut | Fixed? | Evidence |
| :--- | :--- | :--- |
| World's energy pins (the earlier blocker) | **Fixed for the energy model. Not fixed for the pin's other switches** (S-09, S-10). | The applied tree (s422) `sim/world/tools/pin.gd:40` `SimPower.on_ = bool(_on0) if power else false`. The tree's diff adds 23 `WorldPin.shipped(true)` calls, 9 rows printed OFF-PATH and 3 printed KNOWN FAULT (2 in the repo's current diff). But `pin.gd:22-42` still forces the old world on every call: `WorldClimate.data()["gen"] = 1`, `WorldFill.K_ON = false`, `WorldPlan.everywhereOverride = 0`, `tn["on"] = 0`. |
| Encounter's pins (the earlier major 2) | **Fixed.** Both faults are now ceilings that run under the model, with the owed fix named. | The applied tree `sim/director/tools/arc_check.gd:516` `>= METEOR_BOWL_TODAY ... a GW1a ceiling at today's %.0f ... owed: gw1b-riders` (`:40` sets 4570.0). `sim/director/tools/beam_ai_check.gd:90` `lockedInCharge <= LOCKED_IN_CHARGE_TODAY ... owed: gw1b-riders` (`:12` sets 29). |

## BLOCKER

None. One finding was raised as a blocker (the launch travel, S-01). Its checker did not hold it at that level; two other checkers held the same fact as a major.

## MAJOR

| # | In short | Owner | Due |
| :--- | :--- | :--- | :--- |
| S-01 | Main's launches carry 2.0; Orb's play ran 1.5 | Simulation; the EP decides with Game Design | before the landing commit |
| S-02 | Art's tundra colours from the 9 November build are not in the stack | Art; the EP commits | with the landing |
| S-03 | A new start menu is switched on that the 9 November build did not have | UI & UX; the EP rules | before the landing commit |
| S-04 | Desktop builds tell the player the wrong folder for saved reports | UI & UX, Tools | before the first desktop build |
| S-05 | The recorder's check writes into, and prunes, the game's real reports folder | Tools | before the landing commit (the check); before the first desktop build (the cap) |
| S-06 | After GW1a the page build tool silently drops every match word | Tools | before the first page build after GW1a |
| S-07 | The golden does not play the world the game now starts | Simulation | before the landing commit |
| S-08 | Orb's 9 November play files are refused on main; the sprint's order is still wrong | EP, Simulation | before GW1a is called closed |
| S-09 | The rest of World's pin still forces the old world in 33 checks, unclassed | World | dated follow-up |
| S-10 | The no-deaths check does not play Orb's path | World | before the landing if cheap, else dated |
| S-11 | 12 render checks are pinned to a ground the game no longer starts on | Rendering | dated follow-up in the sprint record |
| S-12 | The side-by-side against the 9 November build is one scene, with its differences unread | Camera, Rendering, VFX | before the first desktop build |

### S-01. Main's launches carry 2.0; Orb's play ran 1.5

- **Park:** `docs/sim/runs/6a30b4c9/gw1a-target` (the target) and `docs/architecture/pending/energy-on`.
- **What is wrong.** Both shortcuts handed to Orb opened the 9 November page with `travel=1.5`, and the LAN copy hard-codes 1.5. Main after GW1a plays 2.0 in a solo match with no set-up word, and the value is hashed. So "main reproduces the target" is true, and "main reproduces the build Orb played" is false in this one value. After GW1a, solo plays 2.0 and LAN plays 1.5. The target's README says the travel word needed no edit; that is true of the page's first value, not of the address Orb used.
- **Evidence.**
  - `docs/tools/shortcuts/Open - Monday afternoon build.cmd:6` `...&go=1&blackbox=1&audiolog=1&travel=1.5`.
  - `docs/tools/runs/6a30b4c9/build-and-smoke.txt:8` `port 8772, travel=1.5`.
  - Kept LAN tree `net/lan.gd:28` `launches at top power outrun the camera at the data's 2.0`; `:30` `"travel": 1.5`.
  - The applied tree `data/fight/power.json:110` `"launchTravel": 2.0`; `sim/core/hash.gd:107` `out.append(S.powerTravel)`.
  - `docs/sim/runs/6a30b4c9/gw1a-target/README.md:19` `from their first values, 2 and 5,000 ... So they need no edit`.
  - `docs/architecture/pending/gw1b-energy/README.md:10` `launchTravel 1.5 (was 2.0): Orb's 9 November match ran ?travel=1.5`. So the fix exists, parked for GW1b.
  - A related fact from QA's record: Orb's two plays carried their own slider values. `docs/qa/runs/6a30b4c9/README.md:3` `(2,040 ticks, seed 8487607, flat-out 5000)` and `(19,388 ticks, seed 14617899, flat-out 3500, match over)`.
- **Fix.** The EP picks one before the landing commit, because the choice sets what the golden is re-recorded to.
  - (a) Keep 2.0 in GW1a. Simulation corrects README lines 19 and 20 (the target is the build at the page's first values, not at Orb's shortcut). The landing note says 1.5 lands with gw1b-energy. Every side-by-side between GW1a and GW1b opens the reference with travel 2, or says it differs.
  - (b) Move the one row into GW1a. Simulation re-records the target on the kept tree with that third edit, and the pins are re-read on it.
  - Either way A-CODE-01's closing line should not say "the build Orb played" until 1.5 is main's.
- **Owner:** Simulation (the record and the row). The choice is the EP's, with Game Design.
- **Note.** The three checkers disagreed on weight: two held it as a major, one as a minor. The claims that no record mentions the word, and that the LAN copy played 2.0, were wrong (see Refuted).

### S-02. Art's tundra colours from the 9 November build are not in the stack

- **Park:** none. `data/art/biomes.json` is still an uncommitted file in the repo.
- **What is wrong.** The 9 November build was the commit plus one park, `art-biomes-working-tree`: Art's uncommitted copy of this file. No GW1a patch carries it. So main after GW1a draws tundra rock and far ridges in the older colours. It is the only packed data value the build had that the stack does not give main, apart from the changes the READMEs explain. Nine values differ: three rock colours, three far-ridge colours and three colour-vision figures.
- **Evidence.**
  - `docs/tools/runs/6a30b4c9/build-and-smoke.txt:3` `parks in the build : art-biomes-working-tree`.
  - `tools/preview/stack.json:7` `the warmer tundra rock: lit #8c8270, mid #777472, shade #504d4e), uncommitted: laid over the commit`.
  - The applied tree `data/art/biomes.json:2125-2127` `"#787878", "#6e6e74", "#4a4a52"`; the kept build's tree has `"#8c8270", "#777472", "#504d4e"`. Lines 2151-2153: `"far1": "#a1b1ac"` against `"#a2b2ac"`.
  - The repo's working copy is byte-equal to the kept build's file. `git diff --stat HEAD` shows 9 lines changed.
  - The renderer reads it: the applied tree `render/core/biome_look.gd:120` `r = b.palette.rock`.
- **Fix.** Commit Art's working copy with or just before GW1a, as its own small commit, after the checks that read it pass on the stack. If the EP would rather hold it, the landing note lists tundra rock and far land as a known difference from the 9 November build.
- **Owner:** Art. The EP commits it.
- **Not verified:** where tundra shows on planet 7.

### S-03. A new start menu is switched on that the 9 November build did not have

- **Park:** `docs/ui/pending/a1-rail-default`, with `a1-start-flow` and its grants.
- **What is wrong.** The 9 November build opened on the left-panel menu's single "Start a match" screen. The stack turns `menu_modes` on, so main opens on a new "Choose a mode" list, then a setup page with a fighter pick, plus Quit rows and a version line. The sprint puts the mode list, fighter pick and quit row beside GW1a on scratch copies, not in it. No EP record makes them part of GW1a. The start-flow park says its words are "for Orb to see before use", and the page that asks Orb has no answer written. Only the start screen's side-by-side is in the repo.
- **Evidence.**
  - The applied tree `ui/data/features.json:49-51` `"menus_rail": true, "menu_modes": true, "testers_package": false`. The kept pack has `"menus_rail": true` and the string `menu_modes` nowhere.
  - `docs/ui/pending/a1-start-flow/README.md:3`: `menu_modes` "ships **false** in this park, so main is unchanged until the flip".
  - `docs/ui/pending/a1-rail-default/README.md` `What flips: the Rail frame on all screens, and the A1 start menu (the list of modes, the setup, Quit)`.
  - `docs/ep/sprints/A1-sprint.md:24` lists GW1a's groups ending `left-panel menus`; `:28-29` `Beside it all, on scratch copies: the mode list, fighter pick, quit row and mode smoke suite`.
  - `homework/1 Urgent/2 Decide - words in the new menus (2 min).md`: both answer lines are an empty `>`.
  - `docs/ui/runs/def3445a/rail-default/` holds one picture pair (the start screen) and one gate record.
  - The fighter pick adds `slots` to a menu-started match's setup. `_slots` and `p1_fighter` appear only in `render/core/main.gd` and `ui/tools/hud_check.gd`.
- **Fix.** The EP rules one of two ways and writes it in the sprint.
  - (A) UI re-cuts the patch with `menu_modes` false. The flip lands as its own small step after GW1a, with Orb's answer on the words and the setup, pause and match-over pictures filed.
  - (B) It lands on, recorded as a GW1a rider that does not touch the golden, with dated follow-ups: Orb's answer before the first desktop build goes to Orb, the missing pictures, and one check that starts a match with the pair swapped.
- **Owner:** UI & UX. The ruling is the EP's.
- **Checker's confidence:** medium on the second half (the fighter pick's cover).

### S-04. Desktop builds tell the player the wrong folder for saved reports

- **Park:** `docs/tools/pending/code-03` (`report-hook.patch`), with UI's words.
- **What is wrong.** The report hook is set on every build that is not the web page. The HUD then shows the LAN build's sentence, "Saved reports go in the 'saved' folder beside the game." The new recorder writes to the game's own data folder instead. A player or tester is sent to a folder that is never written. The same switch also swaps SEND for SAVE REPORT on every desktop build, which no README states. The README says the feature works "with no UI change".
- **Evidence** (the applied tree).
  - `render/core/main.gd:191-192` `if not OS.has_feature("web"): ui_hud.lan_report_fn = _record_report`.
  - `render/core/match_recorder.gd:15` `const DIR: String = "user://reports"`.
  - `ui/hud/ui_hud.gd:2334` `"where": UiData.t("prompt.report_where") if lan_report_fn.is_valid() else ""`; `:3877` `note = UiData.t("prompt.report_where")`; `:3883` passes `lan_report_fn.is_valid()` as the LAN flag.
  - `ui/data/terms.json:94` `"report_where": "Saved reports go in the 'saved' folder beside the game."`.
  - `net/lan.gd:48` `const SAVE_DIR: String = "saved"   # beside the game`.
  - `docs/tools/pending/code-03/README.md:10` `work with no UI change`; `:44` `The words a player sees stay UI's ... which already exist`.
- **Fix.** Before the first desktop build (A-TOOLS-01). Either the desktop recorder saves beside the game as the LAN save does, or UI adds a plain sentence that names the real place and the HUD picks the LAN sentence only on a LAN build. Add a hud_check row for the desktop case. Tools corrects README lines 10 and 44; UI updates `docs/ui/lan-report.md`.
- **Owner:** UI & UX (the words and the HUD's choice), Tools (the hook and the README).

### S-05. The recorder's check writes into, and prunes, the game's real reports folder

- **Park:** `docs/tools/pending/code-03` (`report-hook.patch`: `match_recorder.gd`, `match_recorder_check.gd`).
- **What is wrong.**
  - (a) The check saves four files through the real path, into the same folder Orb's desktop build will write to on this PC. Every save prunes that folder to the newest 20 `solo-*.json` files. Once Orb has 17 or more saved files there, each gate run deletes the oldest. Only the check's keep-20 case uses its own folder. The gate and CI run the check with no redirect.
  - (b) In the game the same cap applies to "Save this match" files and reports alike, and no player-facing word says only the newest 20 are kept. The path counts on these files as evidence for later comparisons.
- **Evidence** (the applied tree; read in the code, not run).
  - `render/core/sim_host.gd:694` `return recorder.save(S, reason, tag, note, _record_build_info())` (no folder, so the default).
  - `render/core/match_recorder.gd:16` `const KEEP: int = 20`; `:141` `_prune(dir)`; `:155` `DirAccess.remove_absolute(dir.path_join(by_time.pop_front()))`.
  - `render/tools/match_recorder_check.gd:47` `DirAccess.make_dir_recursive_absolute("user://reports")`; `:56`, `:85`, `:113`, `:125` are real saves; `:144` `var dir: String = "user://reports_check"` is the only isolated case.
  - `project.godot:8` `config/name="Orb Combat EX"`, with no custom data folder.
  - `tools/gate.mjs` has no data-folder redirect (only `tools/smoke/mode-smoke.mjs:34` sets one).
- **Today's state.** I listed the game's data folder on this PC, read-only: it holds no report files yet. So the current gate run had nothing to delete. The risk starts with the first desktop build.
- **Fix.** Tools re-cuts so the check never touches the real folder (a test-only folder override, every save under the check's own folder, and a case that asserts the real folder is unchanged). For the game: either do not prune files whose reason is a save, or put the cap to Orb with a plain line on the card. Until re-cut, the gate runs this check with the data folder pointed away.
- **Owner:** Tools.

### S-06. After GW1a the page build tool silently drops every match word

- **Park:** `docs/tools/pending/code-03` (`planet-entry-and-probe.patch`) and `tools/preview/switches.mjs`.
- **What is wrong.** Once main has its own planet entry, the page build tool skips its three planet edits. The page's own setup function is then called by no match start. A page build made from main after GW1a ignores every word that function carried: travel, flat-out and their sliders, power, dash, tier, peak, kick, hit-stop, and the hooks that hang on it. Orb's shortcuts use `travel=1.5` and `peak=1`. The tool's self-test asserts the skip, and the smoke check can't see it.
- **Evidence.**
  - `tools/preview/switches.mjs:1018-1020`: all three planet edits carry `skipIf: 'func _planet_setup('`.
  - The applied tree `render/core/main.gd:480` `func _planet_setup() -> Dictionary:`; its body reads only the menu's planet part and the `planet` and `touch` options.
  - `tools/preview/preview-selftest.mjs:146` `takes the patch (no anchor error) and routes nothing through the scratch entry`.
  - A reviewer and the checker each ran the tool's pure patch function on the tree's `main.gd`, writing nothing: the three starts still read `_planet_setup()`.
- **Fix.** Tools re-cuts the scratch layer before the first page build after GW1a: route main's three call sites through the page's function and make the page's base return `_planet_setup()`; or remove the dead words, sliders and sample addresses and say so on the page. Change the self-test row to prove a page word reaches the setup.
- **Owner:** Tools.

### S-07. The golden does not play the world the game now starts

- **Park:** `docs/sim/runs/6a30b4c9/gw1a-target` (what the target proves).
- **What is wrong.** The golden holds 9 computer matches and 2 scripted replays on the hand-made arena, and one planet match that names no generation, so it plays generation 2 from the data. No recipe plays generation 3, the world Orb played and the one the game sends by default once the globe ground is on. So "bit for bit" is proven for the arena and a generation 2 planet only. No record in the stack compares a generation 3 match on the applied tree with the kept build.
- **Evidence.**
  - The applied tree `sim/core/tools/golden_recipes.gd:648` `const PLANET_MATCH: Dictionary = {"seed": 1, "cap": 3600, "setup": {"planet": 7, "touch": 3}}` (no `planetGen`); `data/biomes/climate.json:4` `"gen": 2`.
  - The applied tree `render/core/main.gd:265` `RenderTileGround.gen = int(args.get("tilegen", 3))`; `:337` `host.new_match(seed, ai, RenderTileGround.setup_of(su) if RenderTileGround.on else su, own)`; `render/core/tile_ground.gd:108` `out["planetGen"] = gen`.
  - `docs/sim/runs/6a30b4c9/gw1a-target/README.md:27` `**Not in the record: the planet words.**`.
- **Correction to the reviewer.** The reviewer wrote that no saved match of the 9 November build exists. QA's record says otherwise: `docs/qa/runs/6a30b4c9/README.md:3` names two of Orb's play files from that afternoon, and `blackbox-verify-1646.txt` reads `BLACKBOX OK ticks=19388 final=27cf5381b18eb2cd` on the kept tree. I did not find the two files themselves in the repo or under `homework/Files`.
- **Fix.** Before the landing commit, record one generation 3 reference, in this order of preference.
  1. Replay Orb's 16:46 file on the applied tree's sim and compare the final hash with 27cf5381b18eb2cd. It needs a tools-only route, because main refuses the file for its data hash (S-08). If it differs, say whether the cause is the field-cache fix (S-17), which by its own page moves some building positions in the last bits.
  2. Failing that, the same seeded headless match (planet 7, touch 3, generation 3, model and dash on, a cold field cache) on a copy of the kept tree and on the applied tree, comparing checkpoint hashes.
  - Then add a generation 3 recipe to the golden at GW1b, when it is re-recorded anyway.
- **Owner:** Simulation, with QA for the files.
- **Note.** The checker held the finding but said one fact was wrong and that it changes the fix. The checker's text reached me cut short; the correction above is the one I could confirm in the files.

### S-08. Orb's 9 November play files are refused on main; the sprint's order is still wrong

- **Park:** `docs/architecture/pending/energy-on`, `docs/director/pending/director-rows/note-they.patch`, `docs/world/pending/cache-determinism`; `docs/ep/sprints/A1-sprint.md`. This is path-round-2's R2-07, still open.
- **What is wrong.**
  - (a) The sprint still builds the first desktop build after GW1b. The path and the EP's own brief put it on GW1a's commit.
  - (b) The path says Orb's 9 November play files "still verify" on GW1a's commit. By the code they are refused for their data hash. Two files that hash reads differ from the kept build after this stack: `data/fight/power.json` (two switches go false to true) and `data/director/interrupts.json` (hashed as raw text; one word changes in a note).
  - (c) The field-cache fix's own page says some recordings on such a planet are superseded.
  - The golden is not affected.
- **Evidence.**
  - `docs/ep/sprints/A1-sprint.md:26-27` `6. **GW1b:** the riders, straight after` then `7. **The first desktop build**`.
  - `docs/ep/alpha/audit-2026-11-13/05-directives/A1/ep.md:55` `the first desktop build and its same-replay comparison are made on that commit`.
  - `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md:26` `Orb's 9 November play files still verify`.
  - The applied tree `sim/core/replay.gd:198-199` `if rp.get("data", "") != dataHash(rp.get("setup", {})): return {... "reason": "data" ...}`; `sim/core/power.gd:57-58` hashes the whole of `fight/power.json`; `sim/director/interrupt.gd:98` `_text = FileAccess.get_file_as_string(DATA_PATH)`.
  - Kept build `data/fight/power.json:4` `"enabled": false`; the applied tree `:4` `"enabled": true`.
  - `docs/world/field-cache-determinism.md:11` `any recorded replay of an everywhere match in that case is superseded`.
- **Fix.** Before GW1a is called closed, the EP swaps sprint steps 6 and 7 and rewords the path: Orb's play files are replayed on the kept build's own tree and data, and the proof of "same game" on main is the target golden plus the reference of S-07. Simulation says in energy-on's README that every model-on replay from the page is refused on main. Encounter says in its README that the note change moves the director's data hash. If verifying those files on main is still wanted, Simulation and Tools add a tools-only route that replays a file against a named data folder.
- **Owner:** the EP (the records), Simulation, Encounter.

### S-09. The rest of World's pin still forces the old world in 33 checks, unclassed

- **Park:** `docs/world/pending/checks-gw1a`; `docs/world/pins-and-the-model.md`. The repo's current README and diff were read; the pin helper's hunk is the same in the applied tree.
- **What is wrong.** The re-cut classed the energy model's rows only. Every World check still runs on generation 1 with water, settle, plans everywhere, the calm turn and the biome launch off. The README says every failing row under the 9 November world data "pins a shipped value, a generation, or a hash". That is false: World's own record lists failing rows that are behaviour. One was traced: `struggle_meet_check` plays the field world and fails "every standing tower within the glass radius has its windows out (5 of 9)". No fault is proven. But this is the same class as the earlier blocker, and after landing nothing tests these rows on main's own world.
- **Evidence.**
  - `docs/world/pending/checks-gw1a/README.md:20` `(the number is failing rows; every one pins a shipped value, a generation, or a hash recorded on the old data)`.
  - `docs/world/runs/a-world-01/flipped-data-checks.md:46` `max: every standing tower within the glass radius has its windows out (5 of 9)`.
  - The applied tree `sim/world/tools/pin.gd:22` `WorldClimate.data()["gen"] = 1`; `:31` `WorldPlan.everywhereOverride = 0`.
  - `docs/world/pins-and-the-model.md:13` `(shipped(true); the rest of the pin stands)`.
  - The run record of the 23 checks holds verdict counts only, with no row text and no class.
  - The first failing lines come from a 14 November run; they need re-reading on the final tree.
- **Fix.** World runs each of the 23 "model on" checks with no pin on the final tree, keeps the failing row text, and marks each row: off Orb's path (with the reason), re-read on the shipped world, or a known fault with a ceiling and a named fix. Correct README line 20. This is check-only work and does not move the golden, so it can follow the landing if the EP gives it an owner and a date.
- **Owner:** World.

### S-10. The no-deaths check does not play Orb's path

- **Park:** `docs/world/pending/checks-gw1a` (`bystanders_check`, `struggle_dir_check`).
- **What is wrong.** The page says `bystanders_check` (Legal's proof that nobody dies) "plays Orb's path with the model on". It runs under the same pin as S-09, so it plays the old world with the model on. World's own counts show each of the two checks fails one row only when the 9 November world rows and the model are both on, and passes with either alone. That row was never named or classed, and the pin keeps it green. Only verdict counts were kept, so nobody can say which row it is.
- **Evidence.**
  - `docs/world/pins-and-the-model.md:13` `bystanders_check plays Orb's path with the model on: 81 people ran in the scatter runs, **none died** (the Legal row holds on Orb's path)`.
  - `docs/world/runs/checks-gw1a/before-the-pins-on-GW1a-rows-and-energy-on.txt:9` `BYSTANDERS: 1 check(s) failed`; `:74` `STRUGGLEDIR: 1 check(s) failed`.
  - `docs/world/pending/checks-gw1a/pins-gw1a.diff:555` adds `WorldPin.shipped(true)` with `the rest of the pin keeps the path main shipped`.
- **Fix.** Run both checks with no pin on the final tree and keep the full output. If `bystanders_check` passes, take its pin off, so the Legal row is proven on main's own data. If a row fails, name it and class it. Correct the sentence in the page and in README line 38.
- **Owner:** World.

### S-11. 12 render checks are pinned to a ground the game no longer starts on

- **Park:** `docs/rendering/pending/look-recut` (11 pins) and `gw1a-checks/props_strip.diff` (the 12th).
- **What is wrong.** GW1a makes the globe ground the default and, in the same landing, pins 12 checks to the strip ground: after, cover_water, depth, ground, lake_water, open, patch, props, seam_sweep, shape, sky, sweep. After landing, the seam sweep (P1's "no pop at the seam"), the after-image cap and the building sweep certify a ground the player does not see. Rendering's own record names things on the default ground that get neither a ceiling nor a row. All are the 9 November build's own behaviour, so this is not a regression. But the follow-up has no date and is in no EP record. The earlier review listed only props and water; this is the whole class.
- **Evidence.**
  - The applied tree `render/core/main.gd:247` `RenderTileGround.on = not args.has("notiles") and not strip_ground`; `main.strip_ground = true` in 12 check files (for example `render/tools/seam_sweep.gd:61`, `after_check.gd:38`).
  - `docs/rendering/runs/def3445a/globe-default-gates.txt`: `render gates exit 0: 10 of 20`; `ground check FAILED (117)` with a script error; `seam sweep FAILED (46)`; the shape row `REAL, already in the 9 November build ... street paint covers only 16 districts`; the after row `POSSIBLY REAL ... Rendering to look`.
  - `docs/rendering/pending/globe-default/README.md`, Owed: `The checks' globe versions, one per row of the record: Rendering's, after A1's look lands`.
- **Fix.** Land as stacked only with a dated, owned row in the sprint record for the globe versions, in this order: the after-image check on the globe ground (the 5-tick mismatch read, then fixed or held as a ceiling); a globe seam sweep; the street paint's cover held as a named ceiling; sweep and props on generation 3 planets. Until then the README says plainly that these 12 pass on the strip ground only.
- **Owner:** Rendering.

### S-12. The side-by-side against the 9 November build is one scene, with its differences unread

- **Park:** `docs/camera/pending/a-camera-01`, `docs/rendering/pending/look-recut`, `docs/vfx/pending/meteor-default`. This is the earlier review's major 4, fixed in part.
- **What is wrong.** ADR 0010 asks for the same scene at the same ticks on both builds. Rendering's pictures of the look defaults were taken before main's fight data matched, so the two halves play different matches. VFX's park has no picture of its own. The one same-match comparison is Camera's of 2026-11-20: one scripted scene, the default view only. Its record shows a difference on every one of 1,500 frames, peaking at 11.6%, and does not say what differs or which tree was compared. The commit calls it "same framing". The park's README still says the side-by-side "can't run yet".
- **Evidence.**
  - `docs/camera/runs/d55c612f/window/differences.txt:7` `clash: frames 1500; over 1%: 1500 in runs 1-end; over 10%: 454-460; worst 11.6% at 457`.
  - `docs/camera/runs/d55c612f/window/readings.txt:2` `before = g1 with the GW1a stack's camera (s422's split_rig and camera_params)`.
  - `docs/rendering/pending/globe-default/README.md` `The two matches play differently, since main's data isn't the 9 November build's yet (GW1a)`.
  - `docs/vfx/pending/meteor-default/README.md` `the picture is theirs and already recorded`.
  - `docs/camera/pending/a-camera-01/README.md` `The side-by-side against the 9 November build at the same ticks of one of Orb's saved play files can't run yet`.
- **A likely reading, not yet in the record.** One reviewer viewed the clash stills at five ticks and at frame 457. Framing, fighters, HUD, captions and beams matched. The constant difference was the page's two sliders on the kept side; the peak at 454 to 460 was the new crater look (S-36). Camera should confirm and write it down.
- **Fix.** On the final tree: one real match on the kept build and on the stack, same ticks, default mode, stills and a clip, with a line per difference naming its park. Name the tree's commit. Update the three READMEs to point at it. Owned and dated before the first desktop build.
- **Owner:** Camera (the capture window), with Rendering and VFX.

## MINOR

Each of these was checked against the files for this page. S-13 to S-18 were raised as majors and lowered by their checkers.

**S-13. `b_no_beam_test`: 18 rows are no longer asserted.** Park: `docs/controls/pending/gw1a-pins`.
- The rows for B pressed past the RT window are replaced by one row that is always true. Six of them fail because of a known thing in Orb's build (RT then B past the window is still the signature). Nothing now asserts today's behaviour past the window.
- Evidence: the applied tree `sim/input/test/b_no_beam_test.gd:157-159` `if not _has_window(): ok(true, "interim: (the RT window's far side is not checked here ...` then `return`. `docs/controls/runs/94ece92f/gw1a-pins/before-pins-failures-s422.txt`: `b_no_beam_test: 103 checks, 8 failed`; after: `86 checks, 0 failed`; with the stray-beams fix applied: `103 checks, 0 failed`.
- Fix: remove the always-true row and hold the far-side rows at today's result as named known-fault rows, so they go red and are restored when the fix lands. Measure first: the same patch makes the test wait out the opening clinch, so which rows pass today is not on record. Date the stray-beams landing in GW1b.
- Owner: Controls. Checker's confidence: medium.

**S-14. The building-memory follow-up is only a name; one ceiling can't fail.** Park: `docs/world/pending/checks-gw1a`.
- Both rows print the fault, and World owns it. It does not change GW1a: building memory is off in the kept build's data. But "memory-under-model" has no park, no date and no line in the sprint. `wall_hold_check`'s ceiling reads 0 >= 0 today. README lines 21 and 51 still name wrecks-power and say wrecks_check was "pinned for but not run".
- Evidence: the applied tree `sim/world/tools/wall_hold_check.gd:183` `ok(d2 >= d0, "KNOWN FAULT (owed: memory-under-model)`; `docs/world/pending/checks-gw1a/README.md:51` `the two owed World parks it names (memory-under-model, wrecks-power) only if briefed`; `docs/world/pins-and-the-model.md:19` `wall-hold-on's repeatMarks 2 is inert on Orb's path until it lands`.
- Fix: the EP briefs memory-under-model with a date. World tightens the wall-hold row to today's numbers and removes the stale lines.
- Owner: World.

**S-15. `own_pane_check` keeps two ceilings far above what it measures.** Park: `docs/camera/pending/gw1a-pins`.
- The check is new in this landing, so nothing is weakened. But the clash and launchai rows allow 52 and 35 ticks out of the pane where the stack measures 0, in both modes.
- Evidence: the applied tree `render/camera/tests/own_pane_check.gd:16` `const KNOWN: Dictionary = {"clash/1": 52, "signature/0": 26, "signature/1": 48, "launchai/1": 35}`; `docs/camera/runs/6b7e0ca9/gw1a-pins/after.txt:19` `clash normal, fighter 1: out of his pane at most 0 ticks (limit 52, a known loss)`.
- Fix: drop the two entries so those rows fall back to the 15-tick rule, and re-run the check.
- Owner: Camera.

**S-16. Four of `split_sweep`'s six full-length matches run with the dash off.** Park: `docs/camera/pending/split-sweep-energy-pins`, `gw1a-pins-2`.
- The dash is on in Orb's game. The sweep also runs with the travel budget on, which the game ships off. The README's support for the as-shipped set-up is one manual run, which fails other limits of the sweep.
- Evidence: the applied tree `render/camera/tests/split_sweep.gd:318`, `:320`, `:321`, `:326` carry `{"dash": false}`; `:72` `var budget_on: bool = true`. `docs/camera/runs/b1d9444e/gw1a-pins-2/runs.txt` `split sweep FAILED (7)` under `--budget=off (the shipped default ...)`.
- Fix: keep the pins; add an as-shipped pass for the same four rows (budget off, dash on) that asserts only the out-of-pane rule; record with a date the wider item, the sweep's limits for the camera the game ships.
- Owner: Camera. Checker's confidence: medium.

**S-17. The field-cache fix is a deliberate sim change, proven on planet 12 only.** Park: `docs/world/pending/cache-determinism`.
- It changes the key of a memo in sim code and drops old cache files. By its own page, building positions move in the last bits in some generation 3 matches. It belongs with GW1a, because GW1a turns plans everywhere on. The played default is planet 7.
- Evidence: the applied tree `sim/world/plan.gd:82` `const PLACES_REV: int = 2`; `:136` keys on the shift's exact bits; kept build `plan.gd:81` `PLACES_REV: int = 1`. `docs/world/field-cache-determinism.md:11` `155 lines of the 23,000 numbers of planet 12's swing`.
- Fix: land it, and name it in the landing commit as GW1a's one deliberate sim change on a played path. World runs the same warm-against-cold compare on planet 7, touch 3.
- Owner: World. Checker's confidence: medium (see the note under "How this was done").

**S-18. The played world comes from a render switch, and two records say otherwise.** Park: `docs/rendering/pending/look-recut`; `docs/world/pending/a-world-01/README.md`; `docs/tools/pending/code-03`.
- With the globe ground on by default, a game-started match with no planet key plays planet 7, touch 3, generation 3, as the 9 November build did. A headless sim match still plays the hand-made arena. The code is not new; only the default flipped. World's README says "GW1a plays the hand-made arena" and the sprint says the round planet is not in GW1a: both are true of the sim's default only.
- Also: on the 9 November page `planet=7` always meant generation 3. On main the planet entry returns planet and touch only, so with the old ground the same word plays generation 2.
- Evidence: the applied tree `render/core/tile_ground.gd:105-108` `if not out.has("planet"): out["planet"] = RenderLook.TILE_PLANET ... out["planetGen"] = gen`; `render/core/main.gd:484` `return {"planet": int(args["planet"]), "touch": int(args.get("touch", 3))}`. `docs/world/pending/a-world-01/README.md:11` `GW1a plays the hand-made arena`.
- Fix: no code change for GW1a. The EP records the decision as it is. World corrects its line. At GW1b Rendering removes the fallback so the data's world is the one source, and Tools says in the code-03 README where the generation comes from.
- Owner: Rendering, World, Tools, the EP.

**S-19. The gate ran on an older `wrecks_check` than the one that will land.** Park: `docs/world/pending/checks-gw1a/pins-gw1a.diff` (re-cut 554430ad).
- World's claim holds: the wrecks row was staging, not a fault. But the applied tree still carries the older row.
- Evidence: the applied tree `sim/world/tools/wrecks_check.gd:150` `KNOWN FAULT (owed: wrecks-power)`; the repo's current diff `:579` `+ St.fighters[0].tier = tier`. `git apply --check` of the current diff on HEAD exits 0.
- Fix: rebuild the landing tree with the current diff, re-run wrecks_check there (model off and on), and keep the output.
- Owner: World; the EP's gate re-runs.

**S-20. Two lake-floor checks are pinned off Orb's path by set-up.** Parks: `docs/architecture/pending/energy-on`, `docs/director/pending/energy-on-pins`.
- Parity's lake row runs with the dash off; floorlift_check's pop table runs with the model off. So no check measures that clip with the water floor, the model and the dash all on.
- Evidence: the applied tree `sim/core/tools/parity.gd:5828` `"planetGen": 2, "dash": false}   # its touch-down is in a lake. The dash off`; `sim/director/tools/floorlift_check.gd:148` `_match(false, false, 1, true)   # (the model off`. `docs/architecture/pending/energy-on/README.md:21` `sat **2.259 units inside it** at tick 2`; `:25` `It happens in the 9 November build too`.
- Fix: keep both pins; each README names the GW1b park that takes its pin off, with the date. Optional: a parity row with the dash on that holds the depth at today's 2.26 units or under.
- Owner: Simulation, Encounter.

**S-21. `beam_front_check`'s pad pin covers rows that don't need it.** Park: `docs/director/pending/gw1a-pins`.
- The whole of one section runs with every pad switch off, including its two right-stick rows, which the README says pass unpinned. So the one beam answer Orb's pad has is tested only on main's old pad.
- Evidence: the applied tree `sim/director/tools/beam_front_check.gd:224` `SimInputData.pin_switches_off()`; `:226` the rows end `[18, 2, "stick"], [38, 2, "stick"]`; `:255` `SimInputData.load_and_apply()`.
- Fix: pin only the four signature rows; run the two stick rows on the data's pad.
- Owner: Encounter.

**S-22. Parity's campaign cross-back row now searches for an arc that passes.** Park: `docs/architecture/pending/gates-shipped`.
- An arc whose cross-back place is asked but not offered prints a note and no longer fails. The note has no owner of record and no date. The campaign is not in Alpha.
- Evidence: the applied tree `sim/core/tools/parity.gd:6567` `for k in range(24):   # the first seeded arc that leaves column 2 a place untaken`; `:6580` `print("parity note (for World, the campaign): a cross-back place asked but not offered at column 4`.
- Fix: record it as an owed item for when the campaign returns, and fail the row if the count of such arcs rises above today's.
- Owner: Simulation (the row); World and Game Design (the cause).

**S-23. World rows that state the shipped data now read the pin.** Park: `docs/world/pending/checks-gw1a`.
- Each sets the value just before reading it, so it prints a statement that is false for main after GW1a and cannot fail. The page's count also adds to 32 of 33.
- Evidence: the applied tree `sim/world/tools/floor_check.gd:145` `WorldPin.shipped(true)` then `:147` `"the floor ships off, and wade.below is 75"`; `fill_check.gd:79` `"the switch (data/biomes/water.json enabled) is off in the data"`; `data/biomes/water.json:4` `"enabled": true`. `docs/world/pins-and-the-model.md:11` `Of the 33: 23 run with the model on, 8 run both ways, 1 stays on the old path`.
- Fix: reword the rows ("with the pin: ...") and add one row, read before the pin, that asserts the shipped values of World's five files.
- Owner: World.

**S-24. `dash_handover_test`'s ceiling has slack and no named fix.** Park: `docs/controls/pending/gw1a-pins`.
- A 4-tick tap carries 8.2 body heights; the ruling is 1.5; the row allows under 10.
- Evidence: the applied tree `sim/input/test/dash_handover_test.gd:159` `ok(on_tap - none < 10.0, "9 Nov build: and %.1f body heights beyond the stick alone (the slip's brake, not the ruled 1.5`; `docs/design/overnight-2026-11-08.md:63` `A slip let go by tick 6 travels at most 1.5 bh`.
- Fix: set the ceiling at today's value so it can only come down; name the owner and the park that closes the gap; or record Game Design's acceptance of 8.2.
- Owner: Controls (the row); Simulation and Game Design.

**S-25. The flash register reads the camera a frame late, and no row bounds it now.** Park: `docs/rendering/pending/gw1a-checks` (`flashreg_settle.diff`).
- The register's limits and its Reduce flashing rows are untouched. Two camera rows, in both modes, now wait for a steady camera first.
- Evidence: the applied tree `render/tools/flash_reg_check.gd:224` `_settle(host)   # on a steady camera: the opening can pull the zoom more than 5% in a frame`; `:309` `the register's distance is the frame before's`. README `:8` `the register got 0.48 ... against the tick's camera at 0.4766`.
- Fix: land the re-read; add a row over a real match and a hard cut that records the worst one-frame gap and shows the weighted limits still hold.
- Owner: Rendering, with VFX.

**S-26. `sweep_check`'s control moved to a seed its main rows don't play.** Park: `docs/rendering/pending/gw1a-checks` (`sweep_ctl.diff`).
- The seed 4 city scene changes no building in 1,800 frames on the stack, so that scene compares two views in which nothing happens.
- Evidence: `docs/rendering/runs/809e93e5/gw1a-checks.txt:11` `seed 4: nothing to miss (1800 frames ... 0 building changes`; `:13` `seed 6: 186 differences in view found`. The applied tree `render/tools/sweep_check.gd:23` `var seeds: Array = [4, 12345]`.
- Fix: run the city scene on the seed the control found too, or fail a city scene that reads 0 building changes.
- Owner: Rendering.

**S-27. Seven `anim_check` tests are held to switches the 9 November game has the other way.** Park: `docs/animation/pending/gw1a-pins`.
- The README is plain about it. The cost: no row plays the zip's view with flight strikes on, or the grip with its director on. The park named as cover is an untracked file outside the GW1a and GW1b lists.
- Evidence: the applied tree `render/anim/tools/anim_check.gd:88-89` `func _pin_flight_strikes_off() ... DirZip.setFsForce(0)`; `:99` `RenderTileGround.on = false`. README `:23` `The grapple director ON is read by no row`; `:24` `until then no row plays the zip with them on`. `docs/tools/runs/6a30b4c9/switch-list.txt:61` `flightStrikes    ON`.
- Fix: land the pins; record with a date a zip-view row and a grip row that play as the data ships.
- Owner: Animation.

**S-28. The flight reveal's rows now run on a world Orb's game does not lay.** Park: `docs/camera/pending/gw1a-pins` (`flight_shots_check.gd`).
- Plans everywhere is forced off around the whole reveal loop, to clear one staging jolt of 0.307 against 0.30.
- Evidence: the applied tree `render/camera/tests/flight_shots_check.gd:40` `WorldPlan.everywhereOverride = 0`, `:71` `= -1`. README `:14` `Nothing in play drops a fighter 900 units in a tick`.
- Fix: keep the data's world and remove the artefact at its source (land the staged pair over a few ticks, or exempt the staging tick). A ceiling of 0.307 on that one row would also be more honest than a different world.
- Owner: Camera.

**S-29. The foot-slice README says "nothing drawn changes" without a drawn comparison.** Park: `docs/rendering/pending/foot-slice`.
- The proof is gate passes and a missing error line. The footing array is shared between panes, so in split screen the first pane may now stand a building again where the 9 November code skipped it.
- Evidence: README `:14` `One guard; nothing drawn changes.` The applied tree `render/core/planet_view.gd:1517-1518` `if source != null: return   # a second pane: the first stands the buildings for both (its _foot and _falls are shared`.
- Fix: show it with a record of the buildings' written positions in a split scene, with and without the guard; or say the guard fixes a 9 November split-screen fault and may move a footing.
- Owner: Rendering.

**S-30. `chase_rush_check`'s first five rows no longer describe what they run.** Park: `docs/camera/pending/gw1a-pins`, `gw1b-chase-measure`.
- They set no power word, so with the model on in the data they play the same matches as the "energy model, base" rows, held to the looser old limits. Nothing is lost; the strict rows exist.
- Evidence: the applied tree `render/camera/tests/chase_rush_check.gd:63-64` `if power: su["power"] = true`. `docs/camera/runs/6b7e0ca9/gw1a-pins/after.txt:6-7`: the two rows read the same, `step 0.035 jolt 0.007 off 2 flaps 1`.
- Fix: rename the five rows as the data's default and hold them to the model's limits, or drop them.
- Owner: Camera.

**S-31. Two records will be wrong on the day of landing.**
- Camera's gw1a-pins README still calls the 96-tick loss real and "the worst"; the park stacked right after it retracts that. That park calls itself GW1b's item 1 but lands in GW1a.
- Tools' regenerated check table is in a park but not in the stack, so the tree carries the old one.
- Evidence: `docs/camera/pending/gw1a-pins/README.md:28` `seed 2 losing the player for 96 ticks. That one is the worst`; `docs/camera/pending/gw1b-chase-measure/README.md:3` `The player wasn't lost for 96 ticks, and the view didn't flap`. The applied tree `docs/tools/check-scripts.md:3` `262 scripts ... 186 run in CI`; the park's copy `267 scripts ... 191 run in CI`.
- Fix: Camera corrects its README and says the second park lands with GW1a. The EP copies the park's table over in the landing commit.
- Owner: Camera, Tools, the EP.

**S-32. The new audio step's name promises more than it proves.** Parks: `docs/tools/pending/gw1a-retire` (`ci-sets-step.patch`), `docs/audio/pending/a1-sound-sets`.
- Two of the five things (a knock-out, a transformation) have no event in the seeded matches; the check notes it and passes.
- Evidence: the patch `:9` `the five things a player should hear are made into sounds on a seeded match`; `docs/audio/runs/51b840f5/gw1a-fix/s422-sets_check.txt:10` `a knock-out: not in these matches (0 events)`; `:13` the same for a transformation.
- Fix: add a seed or a staged event for those two, or reword the step.
- Owner: Audio, Tools.

**S-33. Two parks ride in GW1a that are not part of reproducing the build, and no record names them.** Parks: `docs/architecture/pending/a1-owed` (`never-cut.patch`), `docs/camera/pending/gw1b-chase-measure`.
- never-cut changes a sim rule to a Game Design ruling of 13 November. It cannot be reached with the shipped data, so the golden and the played game do not move. chase-measure is a check-only fix.
- Evidence: the applied tree `sim/core/hitstop.gd:32` `const NEVER_CUT: Array = ["decisive", "ko", "heavy", "launch", "launch_full"]   # Game Design 2026-11-13`; `:175` `not (anyNever if S.hsAny else NEVER_CUT).has(weight)`; `data/fight/hitstop.json:4` `"enabled": false`, `:22` `"budgetAny": {"enabled": true`.
- Fix: the EP moves both to GW1b, or adds one line each to the landing record saying why they ride now.
- Owner: Simulation, Camera, the EP.

**S-34. Eight new scripts land without their `.uid` files.**
- The engine made them in the applied tree and they sit untracked. One is shipped code. Two other parks in the stack do carry theirs.
- Evidence: the applied tree's status lists `?? ui/core/ui_modes.gd.uid`, `?? render/camera/tests/own_pane_check.gd.uid`, `?? sim/director/tools/match_end_check.gd.uid`, `?? sim/world/tools/cache_warm_check.gd.uid`, and four more under `audio/tools` and `ui/tools`.
- Fix: the EP adds the eight files to the landing commit.
- Owner: the EP.

**S-35. The set-up script keeps no record that all 59 patches applied.**
- It prints each exit code but does not stop on a failure. Its error file is overwritten by every patch. The tree's golden comes from outside the script. One park in the stack has no README.
- Evidence: `s422-setup.sh:6` `apply --3way "$@" >/dev/null 2>"$S/ap.err"`; the error file holds one line, `Applied patch to 'tools/fixtures/cases.json' cleanly.`; no patch in the stack names `sim/core/test/golden.json`; `docs/tools/pending/camera-swing-cases` holds the patch only.
- Fix: keep the 59 exit lines with the landing record; make the script stop on a non-zero code; write the golden step into the script or the record; Tools adds the README.
- Owner: the EP, Tools.

**S-36. The crater look is the one look default that differs from the 9 November build, and two records blur it.** Park: `docs/rendering/pending/look-recut`.
- The addresses handed to Orb carried no craterlook word, so that build drew the old scar fill. Main after GW1a draws the new look. That is recorded as accepted (`docs/ep/vision.md:1807` `the globe ground, the crater look without the black fill, and the meteor trail as defaults`). But the landing's stated purpose is that nothing looks different, and the build's switch list reads the word as ON.
- Evidence: the applied tree `render/core/main.gd:267` `RenderTileGround.crater_look = not args.has("nocraterlook")`; `docs/tools/shortcuts/Open - Monday afternoon build.cmd:6` has no craterlook word; `docs/tools/runs/6a30b4c9/switch-list.txt:83` `craterlook       ON       (page word)`.
- Fix: say so in the look-recut README and in the landing commit. Tools marks page-word rows as "offered" unless the handed-over address carries them.
- Owner: Rendering, Tools.

**S-37. Orb's page carried `go=1`, which main does not have.** Park: `docs/tools/pending/code-03`.
- On the page it set Player 1 to Controller and Intros off, and counted the How to play card as seen. Main keeps the game's own menu defaults, so a first match opens with the intro. No record lists this as a known difference.
- Evidence: `tools/preview/switches.mjs` at 6a30b4c9, line 94 `?go=1 on a local page sets, before the start menu loads, Player 1 = Controller and Intros off`; the applied tree's `render/core/main.gd` has no `"go"` option.
- Fix: record it in the landing notes as intended, or the EP says which defaults main should carry.
- Owner: the EP; UI & UX if a default changes.

**S-38. With the new menus on, the first screen no longer shows the flashing-effects notice.** Park: `docs/ui/pending/a1-start-flow`.
- The notice now sits on the setup page, before "I understand, start". No match can start without passing it. No Legal record covers the move.
- Evidence: the applied tree `docs/ui/menus-a1.md:8` `on the right Legal's notice word for word (not mid-match)` under the setup page; `ui/widgets/ui_menu.gd:3` `the first thing a visitor sees ... the flashing-effects notice at the top`; no file in `docs/legal/` mentions the mode list.
- Fix: route to Legal through the EP for a yes or a row before the flip (see S-03).
- Owner: UI & UX; Legal to confirm.

**S-39. The pause-menu fix has no picture of the real game.** Park: `docs/ui/pending/a1-pause-clock`.
- It changes what a player sees: the pause menu now slides in over 0.18 s where it stayed off screen. The proof is a probe's numbers and the demo's stills.
- Evidence: the park's README says the two stills of a real build cannot be made headless and will follow; the applied tree `ui/widgets/ui_rail.gd:10` `const SLIDE_SECS := 0.18`.
- Fix: one still of the pause menu in the real game on the final tree, beside the kept build paused at the same tick, through Tools' launcher.
- Owner: UI & UX.

**S-40. Safety readings exist for the look defaults, but not for the tree that lands.** (Existence only; no judgement of the numbers.)
- The readings in both modes were taken on main plus the look parks, before GW1a's fight data. On a tree with the whole stack, the record has the clash scene in the default mode only.
- Evidence: `docs/rendering/runs/fcd6706c/look-defaults-flash.txt`; `docs/vfx/runs/067baa03/clash-gw1a-stack-and-control.txt`; `docs/camera/runs/d55c612f/window/readings.txt:2`.
- Fix: if the EP wants readings of what lands, clash and collapse in both modes on the final tree, one capture at a time, with the tree's commit named.
- Owner: the EP routes it.

**S-41. A README calls Orb "his".** Park: `docs/rendering/pending/crater-look-default/README.md:26` `(his build, his window, his words ...)`. Orb is they/them. Fix: "their". Owner: Rendering.

**S-42. In the game, "Save this match" is written as a problem report.** Park: `docs/tools/pending/code-03` (`report-hook.patch`).
- The host's one caller passes the reason "report" for all three HUD paths. The check proves the "save" reason only by a direct call the game never makes. The file name always starts `solo-`.
- Evidence: the applied tree `render/core/main.gd:1835-1836` `return host.record_file("report", tags, note)`; `ui/hud/ui_hud.gd:3775` `lan_report_fn.call("", _fb_text.text)`; `render/tools/match_recorder_check.gd:85` `host.record_file("save")`; `render/core/match_recorder.gd:132` `"solo-%s-main-...`.
- Fix: the HUD's save reaches the recorder with the reason "save"; add a check case through the function the HUD calls. It can ride with S-05's re-cut.
- Owner: Tools, with UI.

**S-43. The default menu offers "Campaign: Coming".** Park: `docs/ui/pending/a1-start-flow` (`ui/data/modes.json`).
- "No campaign at Alpha" was settled on 13 November (`docs/ep/vision.md:1797` `7. No campaign at Alpha: "GO"`). The row is hidden only in the testers' package, which ships off. The data note still says the row waits for answers that were given that evening.
- Evidence: the applied tree `ui/data/modes.json:13` `{"id": "campaign", "label": "Campaign", ... "state": "coming", "testers": false}`; `ui/data/features.json:51` `"testers_package": false`.
- Fix: UI drops the row until a campaign is scheduled, or the EP puts "show Campaign as Coming?" to Orb with the open words page. Correct the note.
- Owner: UI & UX.

**S-44. The sprint's text for step 5 no longer matches what is landed.** Record: `docs/ep/sprints/A1-sprint.md`.
- Line 22 says the round planet's default is not in GW1a; line 24 still lists "round planet" in GW1a's order. Line 24 also says the groups land one owner at a time, each with its own gate run and side-by-side. The stack is one batch with one golden.
- Evidence: `:22` `A-WORLD-01, the round planet as the default, is NOT in it`; `:24` `one owner at a time, in this order: pad, computer opponent, match-ending rules, round planet, camera, look, sound sets, left-panel menus. Each comes with its own gate run and side-by-side`.
- Fix: the EP edits step 5 in the landing commit: "World's five data rows", and the one-batch method with the target's hash.
- Owner: the EP.

## Pins: the count

Counted from the applied tree's own diff (base to 3917885): 162 files changed, 142 edited and 20 new.

| Area | Check and tool scripts edited | New |
| :--- | ---: | :--- |
| World (`sim/world`) | 33 | the pin helper, `cache_warm_check` |
| Encounter (`sim/director`) | 9 | `match_end_check` |
| Simulation (`sim/core`) | 5 | |
| Controls (`sim/input`) | 6 | |
| Netcode (`net/tools`) | 2 | |
| Rendering (`render/tools`) | 14 | `match_recorder_check` (Tools') |
| Camera (`render/camera`) | 5 | `own_pane_check` |
| Animation, VFX | 3 | |
| Audio | 6 | `sets_check`, one probe |
| UI | 1 | two tools |
| **All** | **84** | 9 |

How they sort:

| Kind | Count | Which |
| :--- | :--- | :--- |
| Sim-side checks pinned | 55 | World 33, Encounter 9, Simulation 5, Controls 6, Netcode 2; plus one code line changed so a check passes (`net/session.gd`) |
| Honest as they stand | most | No pin re-baselines a regression against the 9 November build: the tree's sim, director and world code is the kept build's, and the golden is the target. |
| Row sites weakened or removed, sim side | 46 by the reviewer's count | Not re-counted for this page. The ones that matter are findings S-09, S-10, S-13, S-14, S-22, S-23. |
| Force a set-up the game does not use | 33 + 12 + about 10 | World's pin in 33 checks (S-09); the strip ground in 12 render checks (S-11); the dash, the model, the pad or the world forced in S-16, S-20, S-21, S-27, S-28 |
| Sit over a known fault, with a ceiling | 9 places | `repeat_check`, `wall_hold_check` (building memory); `arc_check` (the meteor's bowl); `beam_ai_check` (locked while charging); `chase_rush_check` (7 row ceilings); `own_pane_check` (signature rows); `dash_handover_test` (8.2 against 1.5); Camera's launch_shots fight 2 (earlier review); `b_no_beam_test` (rows not run, S-13) |

Markers in the tree's added lines: 34 calls to the World pin, 23 of them with the model left on; 12 `strip_ground = true`; 9 rows printed OFF-PATH; 3 printed KNOWN FAULT.

## Confirmed fine

**The merge**
- All 59 patches replay in the script's order with line offsets only: no fuzz, no reject, no conflict markers, no duplicated JSON keys. The resulting files are byte-identical to the applied tree.
- The order matches every README. The `--include` line and the three glob loops are safe today (each loop matches one file).
- `render/core/main.gd` takes six patches; replaying them in the order the look park states gives the same bytes.

**The target**
- The tree's golden was rewritten by its own tool and has the target's sha256 (a2b9ed1c...971d).
- All 368 JSON files in the kept pack were compared with the tree. Value differences are only: the two energy switches in `power.json`, two new camera keys, UI's new menu words and two feature keys, and Art's tundra values (S-02).
- No new hashed field, no clock read and no random draw in any sim diff. The tick order is untouched.
- The sim side of the world default is not flipped: World's patch changes five data rows only.
- Render, UI and audio code on main equals the 9 November commit's, so the stack is the whole change to what ships.

**Pins that are honest**
- Encounter's two ceilings; World's energy-model classing; World's wrecks row (staging, not a fault).
- Netcode's three pins. `net/session.gd`'s one line changes nothing with the right stick on.
- Controls' pad-group pins: old switches forced off only for rows of the older path, with on-path tests present.
- Parity's spawn-floor leak fix is a real fix. `power_check`'s close times are an honest re-read.
- Camera's chase-measure park only measures; `chase_rush_check` keeps its limits.
- VFX's water rows; the meteor default (the build ran `meteor=loud`); Audio's sound sets (on in the build).
- Rendering's after-image re-script keeps the cap of five. The determinism tool and VFX's hash check now start from the setup the host sends, on the default ground.
- The CI file gains four steps and loses none.

**The look and the rules**
- No dissolve, fade, slow wipe, full-screen blur or mark on, over or between fighters is added.
- Nothing new differs between reduced and full mode. Camera's reduced-mode parks are not in the stack.
- Every new player-facing word is plain, with no team nickname, ticket id or franchise name.
- The AI disclosure and the "all rights reserved" line are untouched.
- A saved match file holds no personal detail: the build stamp, the time, the player's own tag and note, and the replay.
- No added line calls Orb "he" (S-41 is an older README).
- The mode list starts only what works: two rows ready, six "coming".

## Refuted

No finding was refuted whole. These claims inside findings did not hold.

| Claim | From | Why it does not hold |
| :--- | :--- | :--- |
| The launch travel is a blocker | look lens | Its checker lowered it. The fix exists (parked for GW1b) and the choice is the EP's. Kept as major S-01 on the two other checkers' word. |
| No record mentions the travel word | look lens | `docs/architecture/pending/gw1b-energy/README.md:10` does. |
| The LAN copy played travel 2.0 | look lens | Kept LAN tree `net/lan.gd:30` `"travel": 1.5`. |
| own_pane_check's two ceilings are a weakened assertion | render-pins lens | The check is new in this landing; main has none today. Kept as minor S-15. |
| No saved match of the 9 November build exists | target lens | `docs/qa/runs/6a30b4c9/README.md:3` names two, one verified to its final hash. S-07's fix changes with it. |
| The globe default is new code | target lens | `setup_of` and its planet 7, touch 3 are on main already; only the default flipped. Kept as minor S-18. |
| The building-memory follow-up is a major against GW1a | sim-pins lens | Building memory is off in the kept build's data, so GW1a is unaffected. Kept as minor S-14. |
| split_sweep's dash pins are a major | render-pins lens | The as-shipped run shows no out-of-pane line. Kept as minor S-16. |
| The field-cache fix is a major | target lens | Its checker lowered it. Kept as minor S-17. |
| Twelve of b_no_beam_test's far-side rows can simply be kept | sim-pins lens | They passed before only because of the opening clinch, which the same patch now waits out. S-13's fix says to measure first. |

## How this was done

- Six reviewers, one per lens: the sim's pins, the render side's pins, the target, the merge, the look, and Orb's rules and the records.
- They raised 55 findings: 25 as blocker or major, 30 as minor.
- Each of the 25 went to a checker whose job was to refute it. 18 held as stated (one at a lower level). 7 were corrected: right in part, with a wrong fact or a lower level. None was refuted whole.
- After checking: 0 blockers, 18 majors, 7 lowered to minor. Merged across lenses: 12 majors.
- The 30 minors were each re-checked against the files for this page. All 30 hold; a few unverified details were dropped. Merged with the 6 lowered findings: 32 minors.
- 44 findings in all, S-01 to S-44.
- Limits. Nothing was run. Several checkers' corrections reached the report writer cut short; only the parts that could be read or confirmed in the files were used. Two checkers confirmed that the game's default start plays generation 3 once the globe ground is on, and one doubted it; the lines were read again for this page (S-07's evidence) and the two are right.

Cost: about 4.3M tokens (32 agents: 6 reviewers, 25 checkers, 1 writer). A first attempt earlier the same evening stopped on the weekly limit with nothing written and cost about 1.6M more.

## Delta re-check on the rebuilt tree (2026-11-20, about 20:50)

The review above read the applied tree as cut at 17:30 (s422, commit 3917885). The EP rebuilt it after the evening's re-cuts (s423: commit b986c0f is the stack, b66ba58 adds Tools' cases). This section covers only what changed between the two. Read by hand by one reviewer: a file-by-file compare of the two trees, a check-only reverse apply of each changed park on the new tree, and a read of every changed line outside `docs/`. Nothing was run, and the EP's gate on the new tree had written no result yet when this was read.

**Verdict: the rebuilt tree holds exactly what was meant to change, and nothing else. No new finding blocks the landing.**

### What differs between the two trees, outside `docs/`

17 files. 13 come from five parks; 4 come from main itself moving on and are not part of the stack.

| Files | From | Meant to change? |
| :--- | :--- | :--- |
| `data/art/biomes.json` | Art's `docs/art/pending/gw1a-biomes/biomes.patch` | Yes: S-02 |
| `render/core/match_recorder.gd`, `render/tools/match_recorder_check.gd` | Tools' re-cut `docs/tools/pending/code-03/report-hook.patch` | Yes: S-05 |
| `sim/world/tools/wrecks_check.gd`, `repeat_check.gd`, `wall_hold_check.gd` | World's current `docs/world/pending/checks-gw1a/pins-gw1a.diff` | Yes: S-19 |
| `sim/world/brunt.gd`, `sim/world/tools/memory_model_check.gd` and its `.uid`, `data/biomes/brunt.json`, `tools/schemas/biomes-brunt.schema.json`, `tools/world-checks.json` | World's `docs/world/pending/memory-under-model/memory-under-model.diff` | Yes: the EP's decision on M-04 of the memory review, to land it with GW1a |
| `tools/fixtures/cases.json` | Tools' `docs/tools/pending/memory-under-model-cases` | Yes: six cases for the new `heldMul` key |
| `.gitignore`, `tools/flash/signature-gate.json`, `tools/site-template-selftest.mjs`, `tools/site.json` | Main's own commits since d55c612f (`git diff --stat d55c612f HEAD` outside `docs/` lists exactly these four) | Not the stack's |

Each of the five parks reverse-applies cleanly on the new tree (`git apply --check -R`, nothing written), so the tree holds each park's current file in full.

### The named fixes

| Finding | State on the rebuilt tree | Evidence |
| :--- | :--- | :--- |
| S-02, Art's tundra colours | **In.** The tree's `data/art/biomes.json` is byte-equal to the kept 9 November build's file | `cmp` against the kept build's `tree/data/art/biomes.json` |
| S-05, the recorder's check wrote into and pruned the game's real reports folder | **Fixed.** The check now saves only into its own folder (`user://reports_check_main`, through `MatchRecorder.test_dir`), removes it at the end, and asserts that the game's own folder is "exactly as it was". A second change goes further than asked: a file the player chose to keep (its name ends `-save.json`) is never counted or pruned, with a row that proves it survives 25 newer automatic reports | `render/core/match_recorder.gd` (the new `test_dir`, the `where` line, the `-save.json` test in `_prune`); `render/tools/match_recorder_check.gd` (the `SCRATCH` folder and the last five rows) |
| S-19, the tree held World's older pins | **Fixed.** The three changed checks match the current pins: `wrecks_check` stages the thrower's tier and asserts growth on both paths with no KNOWN FAULT wording; `repeat_check`'s house row prints OFF-PATH; `wall_hold_check` counts towers that lost a floor and asserts more with the memory than without | the three files' compare, s422 to s423 |
| The memory park under the pins (memory review, R-3) | **In, and consistent.** `wall_hold_check` sets `heldMul` 2.0 inside its own rows and puts 1.0 back; the tree's `brunt.gd` has the key and the rule. Shipped values are inert: `heldMul` 1.0, `repeatMarks` 0, `lodgeHold` "world", `wallRebound` 0.25 | the tree's `data/biomes/brunt.json:5`, `:48`, `:51`, `:70` |
| Tools' review of the schema line (memory review, R-4) | **Done.** Tools approved the line and added six cases | `docs/tools/pending/memory-under-model-cases/README.md` |

### The golden

The tree's `sim/core/test/golden.json` still has the target's checksum (a2b9ed1c...971d), the same as before. Whether the rebuilt sim reproduces it is the gate's to show; that run had no result on file when this was read.

### Three notes, none blocking

| # | Note | What to do |
| :--- | :--- | :--- |
| D-1 | `data/biomes/brunt.json` now differs from the kept 9 November build's file by one line (`"heldMul": 1.0`), and its closed schema by one property. The value is inert, but "main's data is the 9 November build's" now has one more named exception beside the ones the READMEs already explain | A line in the landing note. The gate's golden result is the proof that it moves nothing |
| D-2 | `memory_model_check` joins the World check list in this landing. World ran it on main; its record on a tree with GW1a's data (the energy model on by default) is the gate's run on s423 | Read its line in the gate's result before landing |
| D-3 | Still to come, by the EP's note: UI's `a1-save-reason`, as a small delta after this. It was not in the tree and is not covered here | A look at that one patch when it is added |

Unchanged by the rebuild, as the EP ruled: launch distance stays 2.0 in this landing (S-01), the new start menu stays on (S-03), and the planet type in the golden is owed at the next re-record (S-07). The other majors remain dated follow-ups.

Cost of this re-check: about 0.2M tokens of the reviewer's own reading; no agents.
