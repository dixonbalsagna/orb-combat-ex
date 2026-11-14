# The hit-stop A/B clip: the same fight's inputs, hit-stop off and on (Controls, 2026-11-01)

For Tools' capture (the EP's order: "one side-by-side of the same fight on and off, with inputs drawn, so Orb plays both and picks"). Orb asked for chunkier hits; `data/fight/hitstop.json` holds a table (light 3, medium 5, heavy 8, launch 12 ticks, decisive 20, KO 24) that is built and tested but off. This is the same scripted fight twice, once with it off and once on, so the difference Orb sees is only the hit-stop.

## The fight

760 ticks (12.7 s), seed 5, the default pair, **P1 on the pad playing the script, P2 standing still** 80 units away. Nine segments, each a different kind of blow: X taps, a Y tap, a Y mash, two quick stick strikes, a stick charge to level 1, a stick charge to level 3, RB with a shot and a blast, a B hold (a launch), a B tap. The opponent plays nothing so that hit-stop is the **only** difference: the damage dealt is the same to the decimal on both sides (1,182 HP left of 1,600), and every segment lands.

Replayed headless (`sim/input/tools/hitstop_script_probe.gd`), the sim held **38 of 760 ticks (5%)** with hit-stop off and **69 (9%)** on. Per segment (held ticks, off then on): X taps 4 to 6, Y tap 2 to 5, Y mash 8 to 20, stick quick strikes 4 to 10, stick level 1 2 to 5, stick level 3 2 to 5, RB shot and blast 2 to 2, B held 7 to 8, B tap 7 to 8. A capture should show the same counts of held ticks per segment: a held tick is one the sim does not advance (the picture is the same frame), so a clip that steps one tick at a time sees them as repeated frames.

## Files

| File | What |
| :--- | :--- |
| `hitstop-ab.json` | The input script: the scene, the nine segments, and the timed events (tick, op, args). Ticks count from the first controllable tick of the scene (tick 0), one per sim tick the page steps. Ops: `b` a pad button (west X, north Y, east B, south A, lb, rb), `t` a trigger, `rs` the right stick (x, y; y is up), `ls` the left stick |
| `hitstop-ab.overlay.json` | What to draw at the frame's edge: per tick `held` (the controls down: X, Y, B, RB...), `press` (pressed on this tick), `rs` (the right stick, or null), `segment` (the name). Made by `node docs/controls/clips/make-overlay.mjs` from the script |
| `sim/input/tools/hitstop_script_probe.gd` | Replays the script through the real hub into the sim, hit-stop off and on, and prints the held ticks and the damage per segment: the check that a capture matches the sim |

## How to capture it (Tools' side)

1. **Two captures, one script.** The page needs the hit-stop switch as a page word (Tools is adding it; `su["hitstop"]` or `data/fight/hitstop.json` `enabled` is the setting in the sim) and a way to feed the script's events to the pad **through the real input path**, one script tick per `step()`: the recipe is the scripted gamepad over CDP in `render-web-test-recipe` (set the pad's button, trigger or stick state before the tick it is due, then `step()`). The right stick and the quick read need `switches.rightStick` on (the private page has it).
2. **The same match twice:** the same seed (5), slots, pairing and distance, only `hitstop` differing; `tools/flash/capture-web.mjs --seed 5` writes the match record and `side-by-side.mjs` refuses two different matches.
3. **Draw the inputs** at the frame's edge from `hitstop-ab.overlay.json` (the button names lit while held, the stick's direction, the segment name), as every clip Orb judges for moves or controls does. The overlay is the same for both sides; the picture differs only by repeated frames where the sim holds.
4. **Check** the capture's held ticks per segment against the table above (or against a run of `hitstop_script_probe.gd`).

## What I could not do

I did not capture it: it needs a browser (Tools' guarded launcher; I run no Chrome of my own) and the page word and the pad feed above. The script, the overlay and the sim replay are complete and checked.

## Table findings for the same review (from `hitstop_probe.gd`)

With the table on, a stick strike holds 5 ticks at every charge level (so charging buys no chunk), and the energy shots and blasts hold 1 tick on or off (they name no weight). Encounter has both.
