# The input gates: what a sim/input or data/input window must run

Controls, 2026-10-22. Nothing in CI or a runner lists the input tests, so this is the list. Run on a clean export of HEAD (the shared tree is often mid-apply), `--headless`, at most 3 Godot processes at once.

## 1. Every input test

`for t in sim/input/test/*_test.gd` : `godot --headless --path . --script res://sim/input/test/<name>.gd`, each exits 0 on pass. `mash_probe.gd` is a probe, not a test. On main there are 19; with the hold-toggle window, 20; with the right-hand-attacks window, 24 (`left_hand_test`, `strike_gate_test`, `strike_hub_test`, `strike_read_test`). `remap_test` shares `user://input.json` with other tests: run in parallel it can fail once (rerun alone):

| Test | Checks | Covers |
| :--- | ---: | :--- |
| `agency_input_test.gd` | 105 | the agency fields of the intent |
| `aim_test.gd` | 233 | aim and the stick |
| `brake_grapple_test.gd` | 66 | the air brake bit, `a_only`, `catch_read`, `brace_read`, the switches |
| `brake_ready_test.gd` | 15 | the brake-ready tick on the sim's real event |
| `charge_test.gd` | 97 | charges and the latch |
| `haptics_test.gd` | 80 | the eight rumble kinds, scale, gaps, the cue mapper |
| `hub_test.gd` | 60 | devices, slots, rumble targets |
| `join_test.gd` | 53 | joining and leaving |
| `layout_test.gd` | 131 | the layouts |
| `left_hand_test.gd` | 27 | the left hand's brace (a flick from rest with LB, not a lean, not without a rest, a keyboard tap) and vanish (LB and LT within 6, either order, still down; 7 apart and early release are not) |
| `mode_test.gd` | 55 | the manoeuvre mode |
| `hold_toggle_test.gd` | 88 | the hold or toggle styles of Guard, Dodge, Power and Transform: held and toggled sequences give the same packed intent tick by tick and the same state hash (keyboard and Arena pad), two negative controls, auto-repeat, player 2's own style, the style going back to hold, a new match, the cancel, the ring, `let_go_toggles`, and the KO rule (`on_events`: a KO puts both players' toggles away, a launch keeps them, with a negative control) |
| `params_cache_test.gd` | 36 | the kept `params()` of the press reader and the aim helper: one read-only copy, equal to a fresh build, and never outliving a data load, a replaced section or `invalidate()` |
| `press_read_test.gd` | 439 | wind-ups, bursts, pairs, struggle and grapple reads |
| `remap_test.gd` | 147 | rebinding |
| `stance_test.gd` | 186 | stance masks |
| `strike_gate_test.gd` | 262 | **the claw-bot gate for the right-hand attacks** (`right-hand-attacks.md` section 6.1) on the real layout with `switches.rightStick` on, **the pad battery run on `arena` and on `arena-swapped`** and the keyboard battery on `kb-solo`, the shared half and `kb-solo-swapped`: rows J to S (strike then face and face then strike at every gap, the charge, the direction lock, the same tick, the layer at the crossing, defence purity, the three mirrors, the vanish chord, R3 freed, the swap), the inert layers, the struggle, the strike / brace / vanish buttons, cancel, toggle, pause; with it off: the intents equal the layout without the strike bindings and the second word is 0 |
| `strike_hub_test.gd` | 57 | the intent's second word (pack2, canon), the hub's strike style, D-pad mirror (auto, on, off) and swap settings, the remap rows (incl. the optional pad rows) and rebinding of the strike controls, the derived swapped presets, the checks on the shipped presets |
| `strike_read_test.gd` | 59 | the strike reader: dead zone and quantising, quadrants and sectors, the settle, the quick strike, the ladder in live ticks, the direction lock, beam rungs, toggle, cancel, the law's floor, a freeze keeping an edge, a strike key |
| `struggle_test.gd` | 105 | the struggle's presses |
| **`t1_latency_test.gd`** | **62** | **T1: a real press (keyboard and Arena pad) STARTS something on the press tick (an exchange, a rush, or a state, velocity or position change; a press_ack alone does not count), at three distances, held and tapped (24 START rows), is acknowledged by a press_ack on that tick (24 ACK rows), and dodge and guard react from the act record (14 rows). Tightened 2026-10-22 with Encounter's 7a (74ee6b04); it read 38 of 38 before while the start was still 5 ticks late, and 24 of 62 failed until 7a. A BODY row (the body moves, or the crouch shows, within the band's wind-up) follows when Animation's crouch lands**|
| `touch_full_test.gd` | 848 | Full touch |
| `touch_glue_test.gd` | 16 | the touch bridge |
| `touch_test.gd` | 181 | touch Simple |

**T1 history:** the first T1 (38 checks) counted any event but the tick mark as a reaction, so Encounter's `press_ack` ("queued") passed for a start. The tightened test (62 checks) separates the start from the acknowledgement and is on main with 7a.

Counts are as of the date above; a window that adds checks updates its own line. A failure of `t1_latency_test.gd` means a layout, the hub or the director has put a delay between a press and its first visible reaction: fix the cause, never the threshold (the budget is 0 ticks, `input-scheme.md` T1).

## 2. The rest of the gate

1. `npm test --prefix sim` : 5 of 5 stages.
2. `node tools/validate.js` : 0 errors; `node tools/validate.js --self-test` : all checks pass.
3. Render determinism, plain and with intro: `godot --headless --path . --script res://render/tools/determinism.gd` and the same with `-- --intro --seeds=2 --ticks=900` : each "same as the sim alone", ending "determinism passed".

A window that changes `data/input/*.json`'s shape also ships its schema patch (`tools/schemas/input-timing.schema.json` and the others), which Tools applies.
