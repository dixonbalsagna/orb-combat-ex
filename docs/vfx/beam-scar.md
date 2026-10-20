# The scar a beam leaves in the air (2026-10-19)

Orb, on the slow tail (homework 6): "it should look like it's burned a trail into the very space it passed through, some kind of lingering effect."

## What it is

As a beam's tail draws back along its line (from 0.4 s, reaching the far end as the beam's life ends: BeamView.tail_at), the line the tail has left is **branded into the air**: a thin dark cut with a bright rim in the firer's lane colour.
- **Born as a wedge** at the tail (a fresh point takes 0.14 s to reach its full width), so the scar seems to be cut by the beam's passing.
- **The rim is hot, then cools:** the lane colour lightened by a third, cooling to its own half shade in 1.2 s. Slow, one-way, never a pulse.
- **Anchored in the world** (a moving camera slides past it), straight (one quad along the beam's line, across the seam too), and **behind the fighters' plane**: it never covers a fighter (Orb, nothing obscures the fighters).
- **It heals slowly, by geometry, not by fading** (Orb's rule of 2026-10-18: no dissolves). Over 3.6 s a point thins to 45% of its width, and the scar's pieces (110 units long, cut on a slant) drop out one by one, each with hard edges; the oldest point (the firer's end) goes first and the far end last. The alpha of a piece never moves.
- Crisp by construction: the shader draws an analytic strip with a one-pixel antialiased edge, a slightly ragged edge (two octaves of value noise along the length), no blur or soft falloff anywhere. The strip is never thinner than 3 pixels at the pane's zoom.

## Where it lives

render/vfx/beam_scar.gd (the model: one record per beam, pure and deterministic, no random number), scar_view.gd (one MultiMesh, 12 quads at most, a child of the trail view), shaders/beam_scar.gdshader, the numbers in `scar` of data/vfx/energy.json (schema: tools/schemas/vfx-energy.schema.json). The hub has `scars` and `scar_enabled` (on). One line in render/core/warmup.gd (Rendering's) warms the shader at boot. Presentation only: it reads S.beams and S.T, writes nothing.

## Not a Legal clearance

The scar is dark with a lane-coloured rim (azure or orchid, never gold, white or red); nothing in it moves faster than the 1.2 s cooling and the 3.6 s healing; nothing pulses; it is not a flame shape or an aura. fx03's beam rules are untouched (the beam itself is as it was). Under Reduce flashing it is identical (it has no flashing part). Legal has not seen it. Flash readings not re-run (reported, not chased).

## Open

A clash's two beams (S.game.clash) are not scarred yet: they have no tail; the struggle work (next) will decide what the meeting point leaves. A beam that is cut short (beam_late) leaves a scar as far as its head got.
