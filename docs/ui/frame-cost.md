# The HUD's frame cost

UI's answer to the EP's phone frame-time brief of 2026-10-27: Rendering profiled the gen 2 coast at x4 and found UI at 2.75 ms a frame, `UiHud.advance` 1.54 ms and `UiSimBridge.patch` 1.22 ms, both every frame. This is what was cut, with no change to anything the player sees or hears, and how that is shown.

## The switch

`UiFast.on` (ui/core/ui_fast.gd) is true in the game. With it false every saving below goes back to the work the HUD did before, so a bench can run the same build both ways: `ui/tools/hud_frame_bench.gd --fast=0|1` natively, and in Rendering's frame bench a scratch line `UiFast.on = false` at the scene's start (the web page flag `nofast=1` in the park's bench build). Nothing else reads it.

## What was cut (microseconds a frame, native headless, the real main on a 1280 by 720 viewport, the switch alternated in blocks of fifteen frames within one run so both sides see the same machine load; two seeds, 870 frames a side)

| piece | before | after | how |
| --- | --- | --- | --- |
| `UiSimBridge.patch` | 265 | 135 | The launcher's constant lookup (`get_script_constant_map()` builds a whole dictionary, 25 us, and was called five times a frame) is asked once; the brawl's state is read once per patch, not once per fighter; the armed share is read only for an armed stance and an unarmed badge that already says so is not patched; the world's counters go to `set_toll` instead of through a built event; a launcher that is ready and still ready is not patched again; `display_text` (two regex scans) answers from a memo. |
| `hub.consume_all` (the drain, once a tick) | 62 | 25 | The sixteen effect events the HUD does not draw (sparks, debris, dust, rings, fire and the rest, most of what a tick emits) are counted and dropped before `norm()` copies fifty fields of the event object into a dictionary. |
| `UiHud.advance` | 245 to 265 | 215 to 225 | One camera projection per fighter per advance instead of up to four (`_anchor`); the form chip's options dictionary is built only when a chip is wanted; `UiMany` builds the touch buttons' boxes only when a fighter is outside the frame; the card scheduler does not build its lists when nothing shows and nothing waits; `UiData.feature()` answers from a memo (about thirty asks a frame); the planet strip's fallen-building list and its biome segments are kept (below). |

Together: patch, advance and the drain 572 to 375 us on the first seed, 593 to 386 on the second (-34%). On a planet of hundreds of buildings the strip's list is the larger share: `strip_data` walked every building each frame (16 us for 118; it grows with the planet).

The web numbers on Rendering's gen 2 coast are below (section "The web bench").

## What the player could notice, and does not

- Every saving returns the value the old code computed; none skips a change. The strip's fallen-building marks are looked at again when the sim's count of buildings lost moves, when the building count moves, and in any case every quarter second (`STRIP_DEAD_MS`): a building brought down without that count moving (the campaign's wear applied at a planet turn) shows its mark within a quarter second, not on the next frame. That is the one place the old and the new differ in time, and only for that rare case.
- The anchor memo lives only inside `advance()`; the painters still ask the host themselves.
- `display_text` and `feature()` memos are cleared when their tables are rebuilt or an override is set (`set_feature`, `reload`).

## How it is shown

`ui/tools/frame_cost_check.gd` (headless): the same seeded match is played twice through the real sim host, savings off and on, gen 1 and a gen 2 coast, with and without the touch buttons, and after every frame a digest is taken of what the HUD would draw (every layer's signature, visibility, position and size, every fighter model's fields, the toll, the strip's data, the cards, barks, banner, hint, telegraph, caption and tug, the HUD clock). The two runs' digests are equal on every frame. Negative controls: a changed fighter field and a changed toll are seen on the frame they change. `--dump=<file>` appends the savings-on digests, so the same check on a tree without the patch (HEAD) can be compared line for line: 9,600 frames, identical. Also: a building that falls without a counted loss reaches the strip within a quarter second, a counted loss at once, and `display_text` answers the same from the memo.

## What is left, and whose it is

At 1280 by 720 about 215 us of `advance` remains, spread over many small things (the plates' signatures 16, the hub's own timers 17, the YOU marker and legend 14, the pointers 11). The two largest single costs are not UI's: the host's anchor projection (`main._hud_anchor`: `split_frame.hud_anchor` with `fighter_pose`, about 10 us a fighter, twice a frame) and Camera's `split_record()` (about 7 us a frame, built fresh each call). A per-frame answer for `fighter_pose` in `_hud_anchor` would save part of the first; that is Rendering's.

## The web bench: Rendering's gen 2 coast, the switch on and off in one build

Rendering's prof-hook (docs/rendering/tools/prof-hook.mjs) on Performance's pb scene (`pgen=2&pbiome=coast&pplanet=7`, `--igpu --reduced --ticks 600`), HEAD with this patch, one scratch export. The switch is a page flag in that export (`nofast=1`: one scratch line at the top of `_pb_place(S)` in `render/tools/flash_capture.gd`, `if _page_kv("nofast") != "": UiFast.on = false`). Two rounds, on and off interleaved, x1 and x4 (Chrome's CPU throttle), every run in the table valid by frame-bench's own load rule (earlier attempts, at 68 to 82 percent load, were invalid and are not reported; some runs in the table needed a second or third attempt for the same reason). Milliseconds a frame, the part's mean (`pt_ms`):

| | x1 off | x1 on | x4 off | x4 on |
| --- | --- | --- | --- | --- |
| `UiHud.advance` (hud_advance) | 0.306, 0.191 | 0.176, 0.170 | 3.499, 0.914 | 2.049, 0.803 |
| `UiSimBridge.patch` (mv_ui_bridge) | 0.199, 0.131 | 0.077, 0.068 | 2.283, 0.636 | 0.787, 0.342 |
| the drain's `consume_all` (dr_ui_consume) | 0.035, 0.019 | 0.004, 0.003 | 0.392, 0.096 | 0.046, 0.016 |

Each cell is round 0 then round 1. Round 0 of x4 ran with the machine at 50 to 53 percent load (the capture's cores at 44 to 56) and moved about three times as slow as round 1, which ran at 30 percent: read round 1 as the clean x4 pair and round 0 as the same ratios on a busier machine. The two rounds together, x1: advance 0.248 to 0.173 (-30%), patch 0.165 to 0.073 (-56%), drain 0.027 to 0.004; the three together 0.44 to 0.25 ms (-43%). x4, round 1: advance 0.914 to 0.803 (-12%), patch 0.636 to 0.342 (-46%), drain 0.096 to 0.016; the three together 1.65 to 1.16 ms (-29%). Frame time itself did not move beyond noise (x1 mean 15.7 to 16.5 ms off, 15.8 ms on): this scene is bound by the browser's draw, not by UI.

To rerun: a scratch tree of HEAD, `git apply docs/ui/pending/frame-cost/frame-cost-ui.patch`, Performance's `hook-perf.mjs`, `hook-slice.mjs` (with its library) and `hook-pbiome.mjs`, `node docs/rendering/tools/prof-hook.mjs <tree>`, the one `nofast` line, import, export, then `docs/perf/tools/frame-bench.mjs --scene pb --page-args "pgen=2&pbiome=coast&pplanet=7[&nofast=1]" --igpu --reduced --ticks 600 --throttle 1|4` in a quiet window.

## Stills

The same scene, savings on and off, at the same sim ticks (the flashcap hook runs a tick a frame to a tick, then holds): 1280 by 720 at ticks 150 and 420 and 915 by 412 at tick 420. The HUD (both plates, both legends, the charge bars) is pixel for pixel the same; the only differing pixels are on the crowd (the people in the street move with the wall clock, not the sim), 332 to 719 pixels, none in a HUD box. In the park: `still-on-1280x720.png`, `still-off-1280x720.png` and the difference of the two.
