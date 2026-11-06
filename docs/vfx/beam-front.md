# A beam's front (VFX, 2026-11-01)

Orb (through the EP, 2026-11-01): "beams should not be instant rays cast in a direction, they should appear to the player to have a velocity and project out from the fighter." Game Design's ruling is `docs/design/rule-of-cool-map.md` section 5, row 40: the front takes a set number of ticks from the hand to the target (at least, at most: snap 6 and 20; level 1 10 and 30; level 2 14 and 40; level 3 18 and 50; the signature 24 and 60), the hit is decided when it arrives, and two fronts that meet start a struggle. Legal's RL-227 governs the alerts. Encounter does the sim (`docs/director/pending/beam-front/`, a switch, off); this is how it looks.

## What is built (a look, first)

**The head of the front is the fighter's own energy.** While a beam is still travelling out (the sim's `Beam.p` below 1: the head is `p x len` from the hand) the tip of the body carries a head in the beam's language, `VfxBeamFront`, which feeds the energy-language heads (`VfxEnergyHeads`, `docs/vfx/energy-language.md`): the shape of his front (the Protagonist's thick wedge with bubble rings, the Anti-hero's needle with a crystal mosaic, a slim lens, a jagged slug, a capsule: never a ball, a disc or a hoop, Legal RL-225), in his two tints, in a halo of his lane colour. It leads the tip, most of it ahead of the body's end (so a needle, narrower than the body, is not lost over it), is as wide as the beam's body layer and a little more, and grows from nothing over its first stretch, so a front that has only just left the hand is not a whole shape in the hand. The body, its three layers and its rise are BeamView's and untouched: the body follows the front as the sim lays it, and the tail draws back after.

**It replaces the beam plays' crossing look** (`beamplay.gd`: a hard-edged wedge at the head, a thin ring across the beam and the rings it leaves behind) while the heads are on, since the front is that head in the beam's language and the rings were hoops. The plays' other cues (the muzzle, the defender's parting, the walk) stay.

**The heads are lit, not outlined** (Orb's, through the EP: the Protagonist's wedge read as a flat textured cone). The shape is brightest on its axis out to a bright rim line in the lane colour, as the press's pressed face is, where it was a darker outline, and a soft halo in the lane colour spreads past it, a share of the head's own brightness and never over it. This is the same shader for a blast's head and an impact's pieces, so they take it too.

**Switch:** the heads' (`VfxHub.energy_heads_enabled`; `?heads=1` on a local page). Off: nothing here draws, and the beam plays draw as they did.

## How fast

The speed is the sim's: the front's position is `Beam.p`, so a slower front is a slower head and the body behind it fills in as the sim lays it. The clips show 14, 36 and 60 ticks from the hand to the end of its reach (about 0.23, 0.6 and 1 second), the floor of the level 2 row, the middle of the signature's and its ceiling. The sim in the clips is a scratch change that only sets that time; Encounter's park is the real one.

## Not built (the alerts, row 41's defaults, and the rest)

- **The shooter's glint** (a small light at the hand as the front leaves).
- **Air and light ahead of the front** (RL-227): the ripple as a local band at the front, never over a fighter; the thin ground colour sweep in the lane colour at the front's speed; a light dust drift; the screen-edge line. Waiting on a look at this first pass and on the strength Game Design names.
- **Two fronts meeting, partly.** A struggle's meeting point is the press (`docs/vfx/clash-look.md`, "The press"). For the clash's first six ticks (Game Design's collision) each side's head is drawn at the meeting point, nose on it, facing the other, and shrinks into it as the press takes over, so the fronts meet in the press and the press does not appear from nowhere. Today the sim's clash starts with both beams already whole; the fronts travelling to the point and being cut there wait on Encounter's `Clash.mid` writer and its fronts.
- **Flash:** not run (RL-226); required before this goes public. The head is steady: no pulse, nothing rotates, and its pattern moves hue and a little shape, at most 0.9 Hz.

## Cost

One MultiMesh (the heads' pool of 96) and one draw call for every head in the view, a handful of noise samples a fragment, no screen read. The head's quad is 1.25 times as long and 1.7 times as wide as before for the halo. Arithmetic only: Performance benches it.
