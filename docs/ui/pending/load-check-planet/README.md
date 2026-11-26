# load-check-planet (UI & UX, 2026-11-26): the load check's "no planet" row follows today's rule

Parked, not landed. Joins the small-and-big window (the EP).

`ui/tools/load_check.gd` said a setup with no planet starts at once. Since GW1b the default world (`data/biomes/world.json`) is a planet, so `{"intro": false}` gets planet 7, which is cold, and the match waits. Simulation found it (`docs/architecture/pending/size-host/README.md`).

The one row is now two:

- a setup naming no planet: the match waits while the default world is a planet, and starts at once if the data says arena (the row reads the data, so it won't go stale again);
- the hand-made arena (`world: "arena"`): the match starts at once.

`load-check-planet.patch` (sha1 134cf837e256): `ui/tools/load_check.gd` only. Test only; nothing in the game changes.

## Proof (data folder pointed away from Orb's; `runs/`)

- Before, on HEAD f232770f: 28 checks, 1 failed (that row).
- After, on HEAD: 29 checks, 0 failed.
- After, with World's `unhide-small-big.diff`, my `grant-ui-unhide-sizes.patch` and Rendering's `grant-rendering-size-host.patch`: 29 checks, 0 failed.
