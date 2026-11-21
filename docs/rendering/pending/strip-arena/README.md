# Strip-ground checks keep the hand-made arena under GW1b's world flip (checks-only, for GW1b)

Rendering, 2026-11-20, on World's B-13 via the EP (`docs/world/pending/a-world-01/README.md`). GW1b flips `data/biomes/world.json` to mode `planet`. Every match that names no planet then plays planet 7, touch 3, generation 3 (`WorldDefault`, applied by the sim and, with World's host grant, by `SimHost.new_match`).

Twelve of my checks pin the old strip ground (`main.strip_ground`, from `look-recut/` and `gw1a-checks/props_strip.diff`), because their rules are the hand-made arena's:
- after, cover water, depth, ground, lake water, open, patch, props;
- seam sweep, shape, sky, sweep.

Under the flip they would play planet 7 on the strip ground.

## The change

`strip_arena.diff` (sha1 9c60c1a1, `render/core/main.gd`, three lines in `start_match`): a tool that pins the strip ground, with a setup that names neither a planet nor a world, asks for `world: "arena"`. `WorldDefault.apply` leaves a setup with that key alone.
- It's one place instead of twelve checks, and it covers any check pinned later.
- Normal play never sets `strip_ground`, so nothing a player sees changes.
- **Order:** it uses look-recut's `strip_ground`, so it lands after GW1a. It applies textually on HEAD 2267a101, but the property isn't there until look-recut lands. It goes with World's `a-world-01` and its host grant in GW1b.

## Proof (`docs/rendering/runs/809e93e5/strip-arena.txt`)

The tree: my copy of the GW1a stack, plus World's `a-world-01`, its sim and host grants, `default-gate` and `data-switches-gw1b` (mode `planet`). No import errors.

| | the flip, no pin | the flip + this |
|---|---|---|
| the twelve checks | **9 fail** (cover water, depth, lake water, open, patch, props, shape, sky, sweep); 3 pass | **12 of 12 pass** |
