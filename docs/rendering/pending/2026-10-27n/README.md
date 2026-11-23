# 2026-10-27n: the planet's sky tint, built but not yet run (Rendering)

**Not a park to land yet.** `h108_skytint.py` is the change, and it applies to main 9c9251cc. It has not been run on main, nor look-gated, nor clipped. It is kept here through the cloud move. The EP ordered it after the coast items.

**What it builds** (Art's ruling, option b; Art's `sky_tint` in data/art/biomes.json, on main: horizon 0.10, top 0.04):
- **The tint.** At a match's start, every sky key's horizon is mixed 10% and its top 4% in OKLab toward the `orbit` colour of the biome holding most of the arena's columns. The two middle bands take a third and two thirds of the way between those shares.
  - On gen 2 that biome is the fine biome.
  - A town's or city's ground counts as the biome under it.
- **When.** Once a match: no change per frame or per place.
  - `SkyDrive.set_tint` remakes the lap's table (`_build`, split out of `ensure`).
  - A pane works its sky out again when the tint's version changes.
- **Switch.** `--noskytint` turns it off (main's argument and URL argument), for the A/B.
- **sky_check** runs Art's key checks with the tint off (the keys to the bit). It adds three tint checks (`ASKED_HEADLESS` 35):
  - the shares as asked;
  - no change while the camera flies the arena;
  - shares of 0 give Art's keys back exactly.

**The trap fixed on the way.** The table's build reads the data's transitions, which were a local of `ensure()`. They are now a static, `_trans`. The first run failed to parse on this.

**To finish it:**
1. Apply on a scratch tree; import; run `sky_check`, the 19 gates and `split_sweep`.
2. Side-by-side on a green, a desert and an ice planet, with the tint on and off in the same build (`--noskytint`).
3. The signature and collapse clips in both modes (Legal's RL-195).
4. Park.

**Watch point.** The ocean holds most columns on many gen 2 rings. Those planets take the ocean's orbit colour, so check what the commonest biome is on the planets picked for the side-by-side.
