# The 3D auras (VFX's silhouette rework): screen

Owner: Legal and IP Compliance. 2026-10-22. Screens `docs/vfx/pending/aura3d/` (63c078a5; README read, patches not read line by line) and Orb's pictures in `homework/auras-silhouette/` (two stills seen; I could not play the two GIFs, so the motion is judged from the data and VFX's reads). Concept and flash side only: VFX is still fixing strokes that cross the body. Paper only; off by default. A screen, not legal advice or a medical opinion. RL-170; new row fx06.

## Verdict: **Pass, with conditions**
What it is: energy drawn on each fighter's own outline (a second outline pass on the mesh), the Protagonist's boiling and frothing in cyan to azure, the Anti-hero's glinting crystal facets in violet, lane colours only, alpha at most 0.5, rates under 1 Hz, off by default.

**Why it passes.**
- **Colour and shape:** lane colours (cyan to azure; violet), no white, gold or red in the aura, no flame tongues, no lightning, no upward spikes in the stills. A glow hugging a body is the genre's best-known power-up mark, but a thin, lane-coloured, non-flame, non-spiking outline was already cleared as one mark of the seven (k01), and the Anti-hero's angular facets and the Protagonist's froth do not copy any signature aura.
- **Flash side:** rates are under 1 Hz (my rule allows up to 2 Hz and a step under 10%), alpha is capped at 0.5, it is alpha-blended and never additive, it is a small area (a fighter's outline, far under the area threshold), and there is a calm form. VFX's reads: both auras at full level, both modes, 0 flashes, red 0. A bounded, slow, small-area pattern is not a flash or a regular-pattern risk.

**Conditions (fx06).**
1. **One mark, kept transient.** The aura is one of the seven marks; with it on, at most one other mark at a time (k01: ground cracking, a shout, shining hair, lightning or the rest). Orb's earlier direction, that the aura "conveys emotion briefly and then disappears", is also the safer form: not a constant standing glow, and not growing into a flame silhouette as the tier rises.
2. **No flame, no lightning, no spikes:** the outline may stand off the body by a small constant distance; no tongues rising above the head or shoulders, no jagged crackle between the fighter and the ground, no white, gold or red core, no pulse of the whole aura.
3. **Rates and alpha asserted:** `pulse_hz`, shimmer and froth stay at or under 2 Hz (VFX holds them under 1 Hz), `alpha_max` at 0.5, the closed schema keeps rejecting 2.5 Hz and 0.6 alpha, and the fixtures VFX asked Tools for prove it.
4. **Over a bright background** (desert, sky) the aura's luminance change against the background stays under 10% per second at any rate; read it in the flash set when flash work restarts, and in any clip Orb is sent.
5. **Reduce flashing:** the calm form stays (steady or slower, lower alpha); it is the mode the page locks on.
6. **Glasses and faces:** the outline pass never covers the Anti-hero's glasses or either face, so the approved looks (and the glasses rules) read unchanged; strokes that cross the body (VFX's open fix) are a look problem, not a legal one.
7. **Not in a public trailer, page or screenshot** until Orb has approved the look and the flash set has read it on the published build (WIP character art rule).

## What I did not check
The GIFs (motion), the patch code, the Rendering grant, and a live flash read. The conclusions on rate and alpha rest on VFX's README, the data schema and their reported reads; flash work is paused at Orb's request, so no new reading was taken. If the aura is ever turned on in a public build, it goes through the release set first.

## Still waiting
The finisher h10 clips from Art (RL-167 stays open for them).
