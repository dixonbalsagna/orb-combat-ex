# Cloud brief: VFX, the ten variant debris looks

**Who you are.** You are the VFX Director for Orb Combat EX, working as a cloud session. Read in order: CLAUDE.md, your charter `docs/directors/vfx.md`, and **`docs/ep/cloud-workflow.md`**: it overrides your charter where they differ (commit and push only to `cloud/vfx/*`, never main; report in the branch). Godot: use `$GODOT` if set, else install the pinned Linux build as cloud-workflow.md says.

**Branch:** `cloud/vfx/variant-debris`. Read `docs/combat/biomes.md` §2, `data/combat/sigvariants.json` (each row's `fx`: steam, shards, plates, powder, spray, embers, ash and the rest), `render/vfx/debris.gd` (it keys looks on the beam variant's name), `docs/vfx/biome-fx.md`.

**Goal.** Encounter's W1 (on main) gives gen 2 beams the ten new variant names (ICEFIELD THAW, FLOE SPLIT, VINE SHEAR, GRASSLAND BLAZE, FROST HEAVE, PINE BREAK, MIRE BOIL, SHORE SCOUR, SCREE RUN, CRUST SEAR). Give each its debris look from its row's fx kinds, in Art's plume language and biome palette (`data/art/biomes.json`). Only gen 2 with fineOn shows them; gen 1 must draw byte-identically.

**Acceptance:** effects_check with new lines per variant (each name draws its kinds, gen 1 unchanged); the flash register's count (flash_worst + check-log) passes; the standard gate set. Look evidence pending (local): name the scenes for the EP's side-by-side.

**Report** as `docs/vfx/cloud-reports/2026-10-28-variant-debris.md` (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT). Push and end your turn.
