# Fires that linger: alternate numbers for forest fire (parked, data and a measuring tool)

World and Environment, 2026-10-26, for the EP's note: a dense stand burning out in 6 s is too fast for the rule of cool; fires should linger as a backdrop through an exchange or two. `fire.linger.json` holds the alternate `burn` blocks to swap into `data/biomes/fire.json` (a data edit, no code); `fire-curve.diff` (sha1 6035020c9f53, 2 files, a new tool, applies on main) is `sim/world/tools/fire_curve.gd`, which printed the table below. I cannot make the GIF (that is VFX's with Rendering's states): the numbers say what it would show.

A stand of 40 trees on flammable ground, lit at its middle tree (the 6 s was one tree's burn: a dense stand took 21 s on the data's numbers, so the stand did not burn out in 6 s, but it burned as one fast wave):

| Set | Burn a tree | Spread a second | Dense stand (a tree every 50 units) | Sparse stand (every 110 units) |
| :--- | :--- | :--- | :--- | :--- |
| now (on main) | 6 s | 0.15 | 40 of 40 lit, peak 26 at once, all out after 21 s | 1 of 40: out after 5 s |
| **linger** (the EP's suggestion) | 11 s | 0.06 | 29 of 40 lit, peak 12 at once, all out after 60 s | 3 of 40: out after 21 s |
| **wide** | 12 s | 0.09 | 39 of 40 lit, peak 25 at once, all out after 44 s | 3 of 40: out after 22 s |

**linger** is a slow creeping fire that burns a few trees at a time for a minute: a backdrop through several exchanges, but it does not light the whole stand. **wide** is the bigger picture (nearly the whole stand burning, 25 trees at once) for most of a minute. In a sparse forest, the usual one, either burns 3 trees for 20 s: the stand's density sets how much of a fire there is, and `ignite.chance` (0.6) sets how many trees a blast lights. My pick: **wide** for a GIF, **linger** if the look should stay quiet.
