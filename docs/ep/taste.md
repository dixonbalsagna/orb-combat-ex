# Orb's taste: what the game must look and feel like

The checklist every visible change is held to (ADR 0010). Orb's words are in `docs/ep/vision.md`. This page is the short form. Update it only on Orb's word.

## Reference build

- **d3f1ca0e** (the demo of 2026-10-15): the camera movement and split screen Orb liked. Compare camera and split-screen changes against it until Orb names a newer one.

## What Orb wants

- **A minimalist UI. Nothing on, over or between the fighters, ever** (Orb, 2026-10-18, circling the beam-struggle bar: "the UI should not be obscuring the fighters in any way... without cluttering useless pieces of icons and garbage over the fighters"). The fight itself carries the information: animation, camera, VFX, sound and rumble. The HUD lives at the screen edges, small and sparse.

- **Camera:** smooth movement that keeps high-speed combat in frame and dynamically tracks the fight, focused on the coolest parts. It captures speed elegantly. The split screen is clean and readable.
- **Beams and energy:** distinct, visually appealing, robust shader effects. Each fighter's beam is unmistakable.
- **Auras:** pulsating, three-dimensional, shimmering, frothing, undulating, unique to each fighter's power. The Protagonist's and the rival's are similar but inverted in theme, not just colour.
- **Combos:** spectacular and choreographed-looking, but in the player's hands and in real time.
- **Destruction:** big and lasting. Repeated sends wreck more.
- **Faces:** distinct, recognisable, cool, not try-hard; not goofy, not puppet-like.
- **Rewards:** generous, many kinds, always something new.

## What Orb has rejected (never ship these)

- Screen dissolves or cross-fades between shots, and any "fading in and out".
- Slow, slide-style wipes for panels or strips.
- Full-screen blur, haze or a washed-out "calm" look as the default.
- Soft, blurry blocks where a crisp beam should be.
- Any UI drawn on, over or between the fighters during play: rings, circles, bars, tracks, diamonds, badges, markers, icons or labels.
- Debug or key-help text on screen in the public build.
- Any presentation effect that drops the frame rate.

## How a change is checked

1. Side-by-side with the reference build, at the same ticks (`node tools/flash/side-by-side.mjs`).
2. The EP looks at it against this page.
3. Frame-rate cost on the web build for anything heavy (Performance).
4. Only then, the gates and the commit.
