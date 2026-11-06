# The stick's pre-read, drawn (Animation, 2026-11-01)

Controls built `hub.strike_pre(slot)` (`docs/controls/responsiveness.md` section 3 row 2): while the right stick leans in past `preAt` and the request has not started, the layout publishes `{dir, depth}`, 2 to 3 ticks before the start. It is render-only, never in the intent or the hash, rollback-safe. This reads it so a stick press shows sooner. Parked behind Controls' `switches.quickRead` (off): with it off nothing is published, and the layer draws nothing.

## What it does

- **Host:** `render/core/main.gd` fills `RenderAnim.strike_pre = {slot: {dir, depth}}` each frame from `host.hub.strike_pre(slot)` (the one flag, `RenderAnim.stick_pre`, and the one field).
- **Layer:** `AnimFighter._pre_layer`, after the press-tick's. It maps the direction to the fighter's own quick piece's chamber (`data/anim/stick_pre.json` `dirs`: up, down, toward, away; left and right by the fighter's facing) and eases it in at `w` 0.5 of the pose over 6 ticks, scaled 0.6 to 1 by depth. The quick lane has one piece a direction a fighter (Combat's `data/combat/stick.json`), so the pre-read is exactly the piece that will be thrown.
- **Hand-off:** it lets go over 6 ticks as the blow's own 7-tick wind-up takes over (the request starting, a blow taken, a state change, a rush), a crossfade. A pre-read that never becomes a request is let go after 10 ticks and not drawn again until the stick lets go. A wrong pre-read costs a frame of pose; nothing is written to the sim.
- **Reduced motion** scales it by 0.6. `--no-stick-pre` is the before.

## What it buys

The pre-read leads the start by 2 to 3 ticks. The snappy profile solves on twos, so a ramp under 6 ticks reads as a snap: at the start tick it has reached about half of its `w` (a quarter of the chamber), then the 7-tick wind-up carries on from it. Measured through `_test_stick_pre` on the first 5 ticks of a pre-read: the body moves 1.5 to 13 units (the down pieces most: the leg cocks and the body sinks; the up and toward pieces least). It is local only: the opponent sees the blow at its start.

## The wind-up re-timed to 7

Game Design's ruling (`data/director/stick.json` `windTicks` 7): the stick class's quick pieces (`pz.` and `rz.` flick_rise, scythe_sweep, heel_thrust, wheel_blade; lift_fist, skid_kick, short_ram, swing_plate; the air spikes) have `load` 7 on the manifest rows (was 10): they land on tick 9 from the request. The charged pieces' 4-tick release is unchanged. The sketches did not change; the profile fits them to the shorter load, so the first 7 ticks are quicker. `_test_stick_class` now reads 7.

## Checks

`_test_stick_pre`: both fighters, four directions: it shows at least 1 unit, nothing past a limit, no NaN, gone 60 ticks after the pre-read, the sim's position unmoved; a request starting lets go inside 12 ticks; a stale one lets go; an empty one draws nothing. Not yet seen live: no stick strike plays on main until Encounter's hook lands, and `quickRead` is not in `timing.json`. Clips with the stick drawn follow when both are in.
