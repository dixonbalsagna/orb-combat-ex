# Recoil exits and flips (Animation, 2026-10-22)

Owner: Animation. Parked as `docs/animation/pending/recoil-flips.patch` (render side only; apply after `fix-reach-gap-perf`, `finisher-styles` and `grip-layer`). Sources: Encounter's `DirRecoil` (`sim/director/recoil.gd`, off), Combat's `docs/combat/choreography-feel.md` sections 1 and 2, Game Design's `fight-feel.md` section 2.

## What is built

- **The cue.** `recoil` (actor the one who recoils; `source` the exit: skip, handspring, tuck, backflip; `dur` its ticks to the landing; `k` 1 on the ground). `RenderAnim` calls `AnimFighter.on_recoil(source, dur, t_cue)`.
- **The sequence.** Wave `recoil1`, prefix `rc`: 26 poses in 8 sequences. The Protagonist's layout backflip (arms wide, a long open arc) and two-handed handspring; the Anti-hero's compact tuck and one-handed handspring (the guard hand stays up); the shared skip, back tuck, wall plant and ground plant.
- **The turn.** `_recoil_layer` rotates the whole body once, backward (the head goes back first), about its middle (34 units above the feet), eased so take-off and landing are slow and the middle quick. The sim's bowed path (`arcBh` 0.8, 60 units) is the main lift; the layer adds 17 to 25 units of its own (the tuck and the Anti-hero's backflip need the most) so the lowest of the head and hands clears the ground at the middle of the flip whatever path is under it, and never moves a position (tested). The turn scales to the cue's `dur`: tested at 8, 12, 18 and 24 ticks for both fighters (an 8-tick backflip is Encounter's tapped heavy, GD 1a). The lead layer stands aside while it plays.
- **Ricochets** (wall and ground) are built to Combat's section 2 and idle until a cue sends the surface normal (`ux`, `uy`). The wall plant turns the feet to face the wall (test: 0.92 of a perfect fit).
- **Switches.** `RenderAnim.recoil_flips`, `--no-recoil-flips`. Reduced motion plays the sequence and drops the turn.

## For Encounter and Game Design

- A **handspring cannot put its hands on the ground** on the sim's path: the 12-tick flip bows 60 units, so at the top the hands are well above it. The pose is right (with no path under it the hands touch the ground at the top); if Combat wants the hands to touch, the handspring needs a bow of about 0.2 body heights. Nothing to do until Encounter says.
- The flip is **12 ticks** in `interrupts.json` and my sequences are cut for 16 to 24. They stretch to the cue's `dur` without breaking a limit (tested at 8 to 24), but a 360-degree turn in 12 ticks is fast: Camera should read the landing, not the turn.

## Hit-stop table (rulings-2026-10-22 5b)

Nothing in Animation is keyed to a stop length. The reactions read the live state: the shiver follows `S.dirS.stop > 0` (any length), the building face's stop is the event's own `stop` (World's), and `anim_fighter.gd`'s only tick tolerance (`_cue_windup`, 4 ticks) is for a different blow's stop landing between a wind-up cue and its blow, which the new table makes up to 8 for a heavy. That only falls back to the plain wind-up, so it can't mis-draw. Two options for Game Design: scale the struck body's shiver by weight (a mashed light 2 ticks should not shake like a launch 12; today every stop shakes at the profile's one amplitude), and widen the wind-up tolerance to 8. Both change what the player sees, so neither goes in without the look gate; I have not built either.
