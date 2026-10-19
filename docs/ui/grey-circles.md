# The two grey circles, cut behind switches (UI, 2026-10-18)

Owner: UI & UX. Orb played the live demo (pin 5c46feca, Reduce flashing locked on) and said the UI is very strange and that "the weird gray circle visible between the two fighters has got to be cut." **Parked behind `features.json` `tug_rings` and `ring_map`, both off:** `docs/ui/pending/grey-circles/grey-circles.patch` (applies on HEAD and before or after the four older parks, dry runs clean).

## What was found (stills of a live AI match, d3f1ca0e against 5c46feca, both through `tools/machine/browser.mjs`)

1. **The circle between the fighters is the beam struggle's tug of war** (`ui/widgets/ui_tug.gd`, new since d3f1ca0e). Under Reduce flashing or Reduced motion its closing ring is replaced by **two steady rings** (radius up to 40 and 68 px at 1x) around the diamond at the meeting point, drawn for the whole struggle. Locking Reduce flashing on made that the only way the tug is ever seen. It reads as a large grey circle in the middle of the fight.
2. **A second grey circle: the planet ring map** (`UiSplit.draw_ring_base`, `draw_ring_marks`) at the bottom centre. It is in both builds, repeats what the planet strip just below it already shows, sits on the demo's own help text and, in the split view, straddles the divider between the fighters.
3. **Not UI:** the soft translucent rings round the bodies in a brawl (the guard and aura shells, 3D, Rendering's); the red diamonds over the heads (Rendering's stance badge); the greybox's key-help paragraphs over the strip, and the hazier look under Reduce flashing (the calm look), both Rendering's.
4. Everything else that differs in `ui/` between the two builds sits away from the middle of the fight: the toll chip as a bar (Orb's homework 5), the start menu, chip arrows in the rival's ring colour, the incoming chip, the many-body markers (inactive), the launch marks (a human only), and Legal's help line (Settings and the menu only).

## The change

- **`tug_rings` off:** the steady tug keeps its track, the hands' small rings, the diamond and the beat bar (filled for 0.12 s after each pulse, three a second at most); the two big rings are not drawn, and the bar sits just above the diamond (1.45 radii, not 2.5). The moving ring of the normal mode is untouched. With the switch on, the old picture returns.
- **`ring_map` off:** the ring map's two layers draw nothing; the planet strip stays. The layout still reserves the rectangle (Camera's clear zone reads it), so nothing else moves. With the switch on, the map returns.
- `hud_check` runs its older ring-map rules with the switch on, and `_cut_rules` (4 checks) runs the shipped default.
