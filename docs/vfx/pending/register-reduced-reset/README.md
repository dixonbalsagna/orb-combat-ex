# register-reduced-reset (VFX, 2026-11-26): the flash register is on the reduced budget from tick 0

**READY.** Base de5c50dd. `apply.patch` sha1 07c06536f287364b63b58d9ecff57c451ac8a800; `grant-tools-hard-cut-source.patch` (Tools' file) sha1 0604f75488a94a5c3abe69734751ad66e68d6a54. Land both together. Gate record: `docs/vfx/runs/de5c50dd/register-reduced-reset.txt` (effects check 1,196 ok, VFX hash passed, Camera's cut_register_check 73 passed, data job 0 errors, content screen 0; the nine scenes CI failed pass at full length in both modes, `flash count passed`, 20 runs).

## The fault
CI on 5dbd89ca failed the flash count under Reduce flashing (run 45922943927): "2.00 of weight in the 60 ticks from 0 (budget 1), 2 flashes of weight 0.5+ (cap 1)" in every scene that places the fighters at tick 0. Camera's hard cuts (CD-04) ask the register at sim tick 1, before its first `begin_tick()`. `begin_tick()` was the only place the reduced setting was set and `reset()` left it off, so those asks were judged on the normal budget.

## The fix (`apply.patch`, VFX files only)
- `render/vfx/flash_registry.gd`: `reset(p_reduced := false)` takes the setting.
- `render/vfx/vfx_hub.gd`: `reset()` passes it, and the two setting setters (`reduced_motion`, `reduced_flashing`) put it on the register the moment they change. A feeder hub (an other fight's) never touches the screen's register.
- `render/vfx/tools/effects_check.gd`: rows for an ask before the first `begin_tick` (register alone; hub with the setting set before and after reset; motion forced; setting off; a feeder hub).

No budget, cap or count is changed.

## The second line CI needs (`grant-tools-hard-cut-source.patch`, Tools' file)
The same run has 62 problem lines "flash source(s) not in tools/flash/sources.json: hard_cut". `hard_cut` has to be added to `counted` in `tools/flash/sources.json`. CI stays red without it.

## One thing for Camera
In the posed scenes the two asks are both `far_catch_up` at tick 1, one per fighter anchor (the scene teleports the fighters, so each anchor is far from its fighter). With the second now refused, the second anchor whips to its fighter over about 11 ticks in place of cutting, which is the gate's eased form. A normal match start does not do this (the `ai` scenes never went over budget). If a mode ever places fighters on the first tick, Camera could treat the first tick after a reset as a placement and not ask at all. Not needed for CI; listed so it is not a surprise.
