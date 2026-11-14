# stall-keep: no input lost in a stall (Controls, 2026-11-06; job 2 of the controller-vision brief, row 4)

When the page hitches, several game steps run one after another on the one pad snapshot the browser's events left. A button was never at risk (the layout keeps a press's edge until a step takes it, checked below), but a stick flick that rose and fell between two steps was never seen: the reader found the stick at rest. This keeps it.

## What it does (`switches.stallKeep`, off; needs `rightStick`; off is byte-identical)
- The layout notes the strike stick's furthest point from each event (the pad stick, the D-pad mirror, the arrow keys, a strike key) since its last build. At the next build, **if that furthest point was past the request line and the stick is back under the release line now, the build reads the furthest point once** (a flick that came and went); the peak is then spent. A stick still out, held, or only wobbling is read exactly as it was (checked: the whole intent stream is equal with the switch on and off for a held charge, a half push, a face press, and a wobbling held stick with two events a build).
- **Only events count**, so a stick held across builds with no event in between has no peak and is read as it always was; a pause (`drop_edges`) clears it.
- Not done on purpose: the left stick's brace and vanish flicks. Their reader needs the stick out for a tick or two by its own rules, so a one-build flick is lost by the rule, not the stall; keeping the left peak did not make it seen (tried, and removed).

## Buttons (checked, nothing to change)
`stall_probe.gd` (sim/input/tools, a press and release both made before the build): A, X, Y, B, LB (guard press), LT (dodge), RT (power press and tap), R3 (escape) all show in the intent; RB and L3 are stance holds with no action of their own. The press edge is kept until `consumed()`.

## Files
`stall-keep.patch`: `sim/input/layout.gd` (+55: the peak, the wrappers `press`/`release` that note it, `_take_peak` at the strike step), `input_data.gd` (`stall_keep_on()`), `data/input/timing.json` (`switches.stallKeep` false), `tools/schemas/input-timing.schema.json`, `sim/input/test/stall_keep_test.gd` (29 checks) with its `.uid`. `sim/input/tools/stall_probe.gd` (the button probe) is in the working tree: add it to HEAD with this park if wanted.

A found-late fix is in it: a peak made under the D-pad mirror is dropped when the mirror setting changes (the hub applies the setting at the build, after the press), so a flick the mirror made does not outlive the mirror being turned off (`strike_hub_test` caught it with every switch on). stall_keep_test now has 29 checks.

Apply **after the landing set** (`../landing/controls-landing.patch`): it is cut on that tree. `git apply docs/controls/pending/stall-keep/stall-keep.patch`. To turn it on, set `"stallKeep": true` in `data/input/timing.json` (add it to the switches-on set).

## Checked (on the landing tree, headless, below normal priority)
stall_keep_test 29 of 29 (a flick in all four directions kept; two flicks in one stall are one strike, the first of equal reach; a half push is not a request; the kept point is spent once; a key tap kept; the hub path; a pause clears it; the old loss still happens with the switch off); all 30 input tests; `parity.gd` golden passed; `word_check` 620 checks; `rollback_check --right-stick` PASS (1,200 hash comparisons); lint and validate clean.

## Not covered
Real hitches: this is scripted events on the layout and the hub, as the brief asks. On the page, the same events arrive in the browser's queue and reach the hub in order, so the same path runs; `render/core/main.gd` needs no change.
