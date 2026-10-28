class_name UiFast
## The switch for the HUD's per-frame savings (docs/ui/frame-cost.md): on in the game, off only for the bench (ui/tools/hud_frame_bench.gd --fast=0), which then plays the cost the HUD had before.
## Nothing the player sees depends on it: every saving is a result the old code recomputed each frame, kept until its inputs change.

static var on: bool = true
