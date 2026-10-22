# Parked: the render follows the arena's length (Rendering, 2026-10-22)

**Base:** HEAD c538c681 **plus World's windows 0 and 1** (`docs/world/scratch-build/arena-plane/planet-window2-recut.diff`, then `arena-window1.diff`). It reads `SimConst.PLANET_NC`, which window 1 adds, so it must come after them. All checked on copies of the commit, never on the tree.

**Apply order** (each from the project root, with `git -c core.autocrlf=false apply`):
1. World's window 0, then window 1 (waiting on Simulation's yes).
2. This park: `docs/rendering/pending/2026-10-22b/batch.diff`.

The camera roll (`../2026-10-22/`) applies before or after it. All three orders were checked: windows then this; windows, roll, this; and windows, this, roll.

Then delete this folder.

## What it changes

On World's shifting arena a match's ring may be 4,800, 2,400 or 1,200 columns. Until now the render made its ground once, for 4,800, at startup, so a shorter ring drew the wrong ground. Each match on a short ring logged the height texture's size error, and stale heights and biomes showed, as in the before/after still.

- **The ground is made again when the length changes.** `PlanetView.build` (`_built_nc`) makes a new `GroundField`, the ground and water meshes, and the materials that read them. A second pane takes the first's.
- **The copies keep their reach in world units.** `copies_each_side()` for the ground and water is 2, 4 and 8; `prop_copies_each_side()` for the props is 1, 2 and 4. Camera's zoom floor is untouched (the EP's call).
- **The ground chunks take a partial last chunk** (`CHUNK_COLS` 320 does not divide 2,400 or 1,200), and `near_chunks()` rounds up.
- **`ImpactFx.reset` resizes the heat** to the arena.

| File | Change |
| :--- | :--- |
| `render/core/planet_view.gd` | the rebuild on a new length, the copies, the partial chunk, `near_chunks` |
| `render/core/impact_fx.gd` | the heat's size on reset |
| `docs/rendering/arena.md` (new), `docs/rendering/README.md` | what follows the arena's length |

## Checked

- **The probe** (`render/core` state after each match of one game on rings of 1,200, 4,800, 2,400, 1,200 and 4,800): the heat (1,200 / 4,800 / 2,400), the materials' `nc` and `world_w`, the near chunks (4 / 15 / 8), the ground's reach (exactly W) and the copies (17 / 5 / 9) follow the ring, with no image errors.
- **On the default arena:** `gates9` (17 checks), `cue_check` and World's `arena_check` pass, 0 script errors.
- **Stills** (seed 4, Reduce flashing on as the demo has it), all uncommitted:
  - `docs/rendering/img/arena-1200-before-after.png`: the 1,200 ring without and with this;
  - `docs/rendering/img/arena-1200-d3f1ca0e.png` and `docs/rendering/img/arena-2400-d3f1ca0e.png`: against d3f1ca0e.
