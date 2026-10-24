# VFX's biome impact plumes: flash and look screen

Owner: Legal and IP Compliance. 2026-10-23. Screens `docs/vfx/pending/biome-fx/README.md` (the patch's `docs/vfx/biome-fx.md` is inside `apply.patch`; not read) and the stills in `homework/biome-fx/` (the two sheets seen; the three GIFs not played). Parked, not applied. A screen, not legal advice or a medical opinion. RL-176; new row fx07.

## Verdict: **Pass with conditions**
The look is ours: faceted puffs rising in a column, ejecta by biome, a skirt of low puffs, steady orange ember chips on volcanic ground. No flame tongues, lightning or banned marks in the stills. The one "burst star" is a small flat pale effect on one frame; it has nothing to do with the rule against star markings on characters.

**VFX's luminance rule** (a puff counts in the drawn-area budget by its luminance step from the ground, 0.3 to 1) **sits right with my conditions, with one rider:** the standard counts a change of 10% or more of relative luminance (the darker state below 0.80) as a full change over its whole area, not a proportional one. So **a puff whose step is 10% or more counts at weight 1.0**, never 0.3 to 0.9; a puff under 10% may count at the low end. If the formula scales smoothly, floor it at 1.0 above 10%.

## Conditions (fx07)
1. **The star.** One pale frame (0.025 s) per impact, a low-priority source refused under Reduce flashing (so the page, which locks that mode on, never draws it). Its counted area is the disc as **drawn at the framing in use** (a close framing is much larger than a far one) and it joins any beam, explosion or crater in the register's cap of 3 a second. It never repeats within a second.
2. **A clip with plumes in it, both modes, before any public pin.** VFX has not run one (only the register's own count and the staged city collapse). Stage a desert crater, an ice impact and a volcanic impact at a close framing, read both modes, and apply the margin rule. Since the next pin move needs a nightly on the new commit anyway, the nightly's AI matches (which land in several biomes) count if they contain plumes; add one fixed clip for each of the three.
3. **Embers stay steady and amber-orange;** the analyzer reads red flashes 0 with them in (fx05: use the linear test, not the colour code).
4. **Debris and chips** (white and black chips on green in the ice and volcanic stills, high contrast at a small size): never a regular, moving pattern over a large area; the pool's cap holds; chips follow the same luminance weight. The column stays at about five to eight puffs at a close framing, as VFX says.
5. **Not in any public trailer, page or screenshot** until Orb approves the look and the published build is read.

Nothing here changes the demo: it is parked, and the page shows the calm mode with no star.
