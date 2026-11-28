# Changelog (A-TOOLS-07)

One entry for every build handed to a person (a kept build, a desktop build, a test build), newest on top. `node tools/version.mjs --next` adds the entry and raises the build counter in `tools/version.json` together, in the commit that is built. Each entry has two parts: **For players** in plain words, which Orb reads before it is used anywhere (no team nicknames, what a player presses and sees), and **For the team**, the commit subjects since the last entry. Build 0 means no build has been numbered yet.

## 0.1.2 (2026-11-28, 0afd8f05)

For players
- You can choose a small or big planet as well as medium: "Planet size" in "Set up the match".
- The menus now make quiet sounds.
- Craters no longer show doubled rims and bowls after the first match.
- Pressing Play again no longer makes the ground jump for a moment.
- When a camera jump would add to flashing, the camera now moves smoothly to the new view instead. Reduce flashing counts this from the first moment of a match.
- On your first visit to the list of modes, with no controller plugged in, one line says a controller feels best. The start menu's hints follow a controller once you use one.
- A long session uses less memory.

For the team
- EP: record Orb's restart and customization lead for the stand-in (2026-11-28)
- Energy toy pass 2: float-above becomes a beam crest and blast crown; new shapes, behaviours, materials, colours, sliders, presets
- EP: keep Orb's first energy-toy find and record Orb's reaction (2026-11-27)
- EP: Orb's answers on the combat overhaul directive (beam trial first, struggle taught in play, city swing)
- Stand-in: combat overhaul directive (beams, ballistic hybrid, anti-flee, grab, angle and camera) from Orb's 0.1.1 notes
- EP: record Orb's 0.1.1 play notes and beam/dodge/flee ask (2026-11-27)
- QA: GB-011, lakes end in standing walls of water over towns (Orb's report)
- Energy toy: one-page look builder for Orb (aura, beam, blast from one recipe; tiers in data)
- EP: record Orb's energy toy ask (2026-11-27)
- EP: record Orb's energy customization ask (2026-11-27)
- EP: record Orb's energy overhaul ask (2026-11-27)
- EP: record Orb's halt of 2026-11-27 morning
- QA: two-hour soaks on 5dbd89ca, the memory growth is gone (Windows 15.5 MiB/h against 130, Linux 0.8 against 142)
- VFX: the flash register knows Reduce flashing from reset, so cuts asked before the first tick are judged on the reduced budget; hard_cut listed as a counted source (Tools' grant). Fixes CI red on 5dbd89ca
- Tools: remove two landed park folders
- Tools: CI runs Camera's cut_register_check
- EP: the render gates run the feet check at medium, small and big
- Rendering: small-and-big window, building-swiftshader (gates s443/s443b/s443c: render 24/24 with feet at three sizes, golden unchanged, camera checks, world 97/97, smoke, data job 0; Camera's readings pass at small and big)
- Tools: small-and-big window, first-run-sizes (gates s443/s443b/s443c: render 24/24 with feet at three sizes, golden unchanged, camera checks, world 97/97, smoke, data job 0; Camera's readings pass at small and big)
- World: small-and-big window, planet-sizes (gates s443/s443b/s443c: render 24/24 with feet at three sizes, golden unchanged, camera checks, world 97/97, smoke, data job 0; Camera's readings pass at small and big)
- World: small-and-big window, planet-sizes (gates s443/s443b/s443c: render 24/24 with feet at three sizes, golden unchanged, camera checks, world 97/97, smoke, data job 0; Camera's readings pass at small and big)
- Tools: small-and-big window, ci-size-host (gates s443/s443b/s443c: render 24/24 with feet at three sizes, golden unchanged, camera checks, world 97/97, smoke, data job 0; Camera's readings pass at small and big)
- Simulation: small-and-big window, size-host (gates s443/s443b/s443c: render 24/24 with feet at three sizes, golden unchanged, camera checks, world 97/97, smoke, data job 0; Camera's readings pass at small and big)
- Simulation: small-and-big window, size-host (gates s443/s443b/s443c: render 24/24 with feet at three sizes, golden unchanged, camera checks, world 97/97, smoke, data job 0; Camera's readings pass at small and big)
- Rendering: small-and-big window, mats-tracked (gates s443/s443b/s443c: render 24/24 with feet at three sizes, golden unchanged, camera checks, world 97/97, smoke, data job 0; Camera's readings pass at small and big)
- Rendering: small-and-big window, fore-clamp (gates s443/s443b/s443c: render 24/24 with feet at three sizes, golden unchanged, camera checks, world 97/97, smoke, data job 0; Camera's readings pass at small and big)
- Rendering: small-and-big window, rows-interp (gates s443/s443b/s443c: render 24/24 with feet at three sizes, golden unchanged, camera checks, world 97/97, smoke, data job 0; Camera's readings pass at small and big)
- Rendering: small-and-big window, marks-baked (gates s443/s443b/s443c: render 24/24 with feet at three sizes, golden unchanged, camera checks, world 97/97, smoke, data job 0; Camera's readings pass at small and big)
- Rendering: small-and-big window, feet-ground (gates s443/s443b/s443c: render 24/24 with feet at three sizes, golden unchanged, camera checks, world 97/97, smoke, data job 0; Camera's readings pass at small and big)
- Rendering: small-and-big window, sky-handover (gates s443/s443b/s443c: render 24/24 with feet at three sizes, golden unchanged, camera checks, world 97/97, smoke, data job 0; Camera's readings pass at small and big)
- Camera: small-and-big window, cd04 (gates s443/s443b/s443c: render 24/24 with feet at three sizes, golden unchanged, camera checks, world 97/97, smoke, data job 0; Camera's readings pass at small and big)
- Camera: small-and-big window, gw1c-door-holds (gates s443/s443b/s443c: render 24/24 with feet at three sizes, golden unchanged, camera checks, world 97/97, smoke, data job 0; Camera's readings pass at small and big)
- Camera: big passes collapse in both modes with its buildings drawn (building-swiftshader in the window)
- Rendering: big's frame-bench on the window's tree with buildings drawn (p50 24.5 ms, p95 48.1; medium 20.0 / 34.3)
- Rendering: park building-swiftshader (per-instance textures wrap at 4,096 texels, so software rendering and smaller-limit cards draw the city; pixel-identical on the card)
- Tools: park first-run-sizes (small and big picked with the Planet size row; lands with the flip)
- Tools: the nightly page's software-readings section; remove two landed park folders
- Tools: the nightly warns that software readings of clips with buildings are invalid until Rendering's shader fix
- Rendering: the nightly's collapse-reduced 4 is software rendering drawing no buildings (building.gdshader under SwiftShader); the card reads 1
- Camera: a2-pump marked held until collapse at small and big has headroom
- ...and 64 more

## 0.1.1 (2026-11-25, 558270b2)

For players
- Every match is on a medium-sized planet. A choice of planet size is built in; you will not see it until the small and big planets are ready.
- Craters slump where they run into older ones, and slamming someone into an old crater still buries them.
- The camera keeps a falling fighter in view.
- If a controller drops out in the middle of a match, the game pauses and says so. Press a button on that controller to carry on.
- When you save a report, or start the game after it did not close properly, the game puts copies of its log files in the report folder, with folder paths and your PC's names taken out.
- You will hear a quiet wind and sounds from buildings being hit and falling. The menus do not make sounds yet.

For the team
- EP: the render gates run Rendering's drawn_check with --tiles (GW1c's drawn-at check)
- Simulation: GW1c's golden (target 2, sha256 2e8cdeaa: the store fold, the groove storage and the bury fix)
- VFX: GW1c crater-refused (apply.patch, c6931f4793e9)
- World: GW1c globe-step2 (grant-tools-bury-check.patch, f410cc78fe3c)
- World: GW1c globe-step2 (bury-refused.diff, 57e8b15dfffe)
- World: GW1c globe-step2 (grant-simulation-crater-refused.patch, d64450fcd60e)
- Camera: GW1c gw1c-keep-human-vertical (gw1c-keep-human-vertical.patch, 5bf38d00d929)
- Tools: GW1c world-schema-cases (world-schema-cases.patch, eac8673e0b71)
- UI: GW1c a1-world-menu (schema-feedback-world.patch, a77846046b75)
- Rendering: GW1c world-menu-merge (world_menu_merged.diff, 78abe08eb55f)
- UI: GW1c a1-world-menu (world-menu.patch, 5e2ebc8ecfdf)
- Rendering: GW1c drawn-at (drawn_at.diff, 984e12f9ccc9)
- Rendering: GW1c planet-sizes (sizes_tiles.diff, d22786b98118)
- World: GW1c globe-step2 (swap-blocks-gw1c.diff, 07c6f92a24b3)
- World: GW1c globe-step2 (globe-check-pin.diff, c37fdf9fd6f4)
- World: GW1c relief-cap-gw1c (grant-tools-relief-cap.patch, 3e065214a63d)
- World: GW1c relief-cap-gw1c (relief-cap.diff, 774bb7524a6b)
- World: GW1c crater-tiers (grant-tools-crater-tiers.patch, 38170d770c80)
- World: GW1c crater-tiers (crater-tiers.diff, 7ddc7e1e883f)
- World: GW1c box-key-20bit (box-key-20bit.diff, 8bead9f958b7)
- World: GW1c store-parts (store-parts.diff, 5fcbe87355b2)
- World: GW1c gw1c-world (gw1c-world-fix.diff, 621c7f345cb4)
- World: GW1c gw1c-world (gw1c-world.diff, b7c42e20eb17)
- VFX: GW1c planet-sizes-meteor (apply.patch, 9c9f808723d2)
- Rendering: GW1c planet-sizes (grant-world-field-size-key.patch, c48936a36ccd)
- Simulation: GW1c replay-sizes (replay-sizes.patch, 13143eb17184)
- World: GW1c planet-sizes (planet-sizes.diff, 57d6e4be75a5)
- World: GW1c planet-sizes (grant-simulation-sizes.patch, 182ca239eb57)
- World: GW1c globe-step2 (grant-simulation-field.patch, 2cb76b47cb20)
- World: GW1c globe-step2 (globe-step2.diff, 7f3c7aabde4a)
- World: GW1c globe-step2 (grant-tools-lint.patch, f79d5cf8cc7b)
- Audio: record the sound proof on both exported programs
- Tools: the sound proof passes on the exported Linux and Windows programs (desktop build 45767037480)
- Rendering: rushcity at medium fails the same on GW1c and main (3.5); not a GW1c change
- Tools: routes fails unless --audio-proof stays the first thing boot_entry does and reads nothing of the game; remove the landed audio-scene-cases park
- UI: menu-sounds points at docs/audio/friends-sound.md
- Audio: friends-sound page (from the landed park); remove the landed park folder
- Audio: the friends'-build sound set (a quiet wind bed, building sounds from the sim's building events, menu sounds ready for UI's calls, a look-ahead limiter in place of the overdriving one, and a sound proof the shipped program can run); Tools' schema and CI grants, Rendering's boot_entry grant
- Tools: remove the landed RL-281 park folder
- QA: soak needs several match starts in a long run (new seventh check), and reads each output stream separately so the worst frame is always computed
