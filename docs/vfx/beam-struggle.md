# The beam struggle, carried by the beams (2026-10-19)

Orb's minimal-UI rule (docs/ep/taste.md: nothing on, over or between the fighters), Game Design's docs/design/minimal-hud.md row "The beam struggle" and Research's readable-speed paper: no tug bar, no pulse marker. **The meeting point is the gauge, and the beams show everything else.** This replaces UI's bar (UI is removing it) and VFX's own thin rings.

## What the player sees (all in the two beams; render/vfx/beam_struggle.gd, the shader's waves in shaders/beam_core.gdshaderinc)

| Moment | What the beams do |
|---|---|
| **Who is pushing** | The beam of the one gaining ground is **a little thicker** (up to 1.3 times the width, eased over 0.35 s, so the sim's 10 to 15% jump of the point reads as a quick shift, never a pop). His rival's beam is **never thinner** than its own width (Orb, 2026-10-22: "instead of thinning out"): it buckles instead, see below. |
| **The beat** | A **swell** leaves each fighter's hand 14 ticks before every pulse and runs down his beam to reach the meeting point **on the pulse**: the player follows the beat as the two swells close on the point. No marker; the music and the pad carry the rest. |
| **A surge** (a press on the pulse) | A bigger swell runs down the **presser's own beam**, hand to point; the point swells a little more. A sharp surge's swell is 1.4 times bigger and wider. |
| **A stray** (a press off the pulse) | A **pinch** runs down his own beam (the beam narrows for an instant): shape only, nothing flickers. |
| **The meeting point** | Swells **slowly** over the first 1.8 s of the struggle, and each surge adds a little, which decays over 2.5 s. A swell, never a flash. |
| **The loser's beam buckles** (Orb, 2026-10-22) | As the point is pushed back toward him, his beam **bulges** where the push lands (up to +70% of its radius there, a third of the way in from the point), **bows** sideways between his hand and the point (up to a tenth of its length, 70 units at the most, anchored at both ends) and **quivers**: two slow travelling waves shake its axis (up to 3% of its length, 24 units). All of it grows with the ground he has lost (0 at an even struggle, full when he is nearly at his own hands, eased) and all of it is **geometry**: the beam's brightness does not move with it. |
| **The loser** | His standing aura **flares** in proportion to the ground he has lost (up to +30% size and +60% alpha as he digs in), and both fighters hold their aura up for the whole clash (aura.gd `is_active`). |

Everything but the buckling is a **change of width** (a smooth bulge on the beam's radius), with at most 8% of alpha on a swell; the beams' brightness stays steady (Legal fx03, and fx04 for the struggle's marks). The edges stay as crisp as the crisp beam's.

## Reduce flashing (the default) and Reduced motion

The buckling's rates: the bow breathes at 0.7 Hz and the quiver's waves travel at 1.6 Hz, so any point of the beam moves at **2 Hz or slower** (the schema's bound); under Reduce flashing or Reduced motion it is half the size and 0.6 of the rate (a quiver at about 1 Hz). It moves edges, not brightness, but the rates are kept inside Legal's fx03 anyway.

Same rates as the rings it replaces (RL-141 to RL-143): the beat's swell is shown for **every second pulse only** (a 40-tick beat, 1.5 Hz), swell amplitudes at 0.8, and a surge or stray swell is not made within 40 ticks of the last one (the point's own movement still shows each press).

## Where it lives

- render/vfx/beam_struggle.gd: the model (reads S.game.clash and the cues `beam_pulse`, `beam_surge`, `beam_stray`, `beam_end`; keeps its own clock; no random number; writes nothing of the sim). The numbers are the `struggle` block of data/vfx/energy.json.
- The hub owns it (`struggle`, `struggle_enabled`, on) and hands it the tick's events after reach.gd. While it is on, reach.gd's old rings (beat, surge, stray, opening) are not made (`struggle_marks`); the end marks are as they were.
- BeamView draws it (Rendering's file, a grant): the two clash beams' widths times `width_k`, and `VfxBeamStruggle.set_on` after each layer's look sets the waves on its material. A beam that is not a clash beam has them cleared.
- The standing aura's flare is one more grant, in transform_view.gd (VFX's, but the one file the charter keeps out of reach): see `grant-rendering-ui.patch`.

## Honest limits

- **Encounter's beam struggle is parked, so `Clash.mid` is -1 in the game today** and nothing here shows until it lands: with mid -1 the beams are as they were. The pictures were made with a scratch scenario that fakes the cues and the meeting point (scripted pulses, the first fighter surging on the beat, the second now and then, a stray), in the shipped clash scenario at tick 70 to 190.
- The rules it follows are Game Design's first values (pulse every 20 ticks, a surge 10 to 15%); if Encounter changes the cues, only `_pulse`, `_surge` and `_stray` change.
- Not a Legal clearance. Flash readings not re-run (reported, not chased).
