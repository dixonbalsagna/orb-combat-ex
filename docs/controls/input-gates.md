# The input gates: what a sim/input or data/input window must run

Controls, 2026-10-22. Nothing in CI or a runner lists the input tests, so this is the list. Run on a clean export of HEAD (the shared tree is often mid-apply), `--headless`, at most 3 Godot processes at once.

## 1. Every input test

`for t in sim/input/test/*_test.gd` : `godot --headless --path . --script res://sim/input/test/<name>.gd`, each exits 0 on pass. `mash_probe.gd` is a probe, not a test. On main (aa927bb5) there are 18:

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
| `layout_test.gd` | 128 | the layouts |
| `mode_test.gd` | 55 | the manoeuvre mode |
| `press_read_test.gd` | 439 | wind-ups, bursts, pairs, struggle and grapple reads |
| `remap_test.gd` | 138 | rebinding |
| `stance_test.gd` | 186 | stance masks |
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
