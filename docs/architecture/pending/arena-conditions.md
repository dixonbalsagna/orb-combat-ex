# The shifting arena: Simulation's conditions on World's windows 0 and 1

Owner: Simulation and Engine. 2026-10-22. My grant review of World's park (`docs/world/scratch-build/arena-plane/`).

**Update, the same day: World re-cut window 1 to all three conditions (03adedd9), and the grant is YES for windows 0 and 1.**
- **(a)** `SimCore._arenaCols` takes only a whole number of columns from 600 to 4,800 that is a multiple of 8, with a planet. Anything else plays the planet's own 4,800, with an error.
- **(b)** The match keeps `S.arenaCols`, `S.planetCols` and `S.worldId` (not hashed). The top of `step` sets the statics again when the arena's length or `WorldBiomes.worldId` isn't its own. This is the same as my `bind` below, keyed on the world's id in place of the sim's.
- **(c)** The same four values, handled.

The rest of this page is the review of the first cut (2bc1c0c3), kept as the record.

| Condition | The first cut (2bc1c0c3) |
| :--- | :--- |
| **(a)** `arena.cols` is checked in `newMatch` | **Not met.** `int(arena.cols)` takes any value, and an arena with no `cols` is a script error |
| **(b)** the arena's length is kept in the match and set again at every step | **Not met.** `setArena` runs only in `newMatch`. The statics are process-wide, so a second sim on another ring (a replay checked during play, a ghost, a rollback copy, a test) leaves the first reading the wrong length. Window 0's biome table (`WorldBiomes.planetCols`) has the same shape and needs the same rule |
| **(c)** every load-time value derived from the length follows it | **Met.** The four are in the patch: `DirLocation.STEP`, `WorldCollateral.HIST_STEP`, `WorldPlanet.TOUCH_COL` (now `touchCol()`) and `WorldStructures.BUCKET_W`. A scan of `sim/`, `render/`, `ui/` and `audio/` finds no other. The frozen JS core keeps 9,600 (it plays the default arena only) |

## (a) The guard, in `sim.gd` `newMatch` (in place of World's two lines)

```gdscript
	S.arenaNC = SimConst.PLANET_NC   # the arena's length in columns: a ring of the planet's (World; it needs a planet), else the planet's own
	var arena = setup.get("arena", null)
	if arena is Dictionary and setup.has("planet"):
		var c = arena.get("cols")
		if (c is int or c is float) and float(c) == floor(float(c)) and int(c) >= SimConst.ARENA_MIN_NC and int(c) <= SimConst.PLANET_NC:
			S.arenaNC = int(c)
		else:
			push_error("SimCore.newMatch: arena.cols %s is not a ring (a whole number of columns from %d to %d): the planet's own is played" % [str(c), SimConst.ARENA_MIN_NC, SimConst.PLANET_NC])
	SimCore.bind(S)
```

In `constants.gd`, beside `PLANET_NC`: `const ARENA_MIN_NC: int = 600   # the smallest ring World builds (arena_check: 600 to 4,800)`. World names the number.

## (b) One sim's world statics, set again at every step

In `state.gd`: `var arenaNC: int = 4800   # the arena's length in columns (SimConst.setArena): set at newMatch, bound again at each step`. Window 0 adds `var planetCols := PackedByteArray()` (the slice's biomes, which `WorldBiomes` reads).

In `sim.gd`, a function that binds the process-wide statics to one sim, called at the end of the arena's lines in `newMatch` (after World's slice has filled `S.planetCols`) and first thing in `step`:

```gdscript
static var _bound: int = 0   # the sim the world's process-wide statics belong to (its instance id)


## The world's process-wide statics (the arena's length, window 0's biome table) belong to one sim at a time: a step
## of another sim (a replay checked during play, a ghost, a test) takes them back first.
static func bind(S: SimState) -> void:
	_bound = S.get_instance_id()
	SimConst.setArena(S.arenaNC)
	WorldBiomes.planetCols = S.planetCols   # window 0
```

At the top of `step`: `if _bound != S.get_instance_id(): bind(S)`. One integer compare a tick when nothing changes. `dispose` sets `_bound` to 0.

**Not hashed:** the length comes from the setup, and the setup is in the replay. A ring changes the world, so the tick-0 gameplay hash already differs.

## Window 0's golden keys

**Yes.** In the window, I add World's recipes to `golden.gd`:
- the slice hashes 7/3, 7/9 and 11/2;
- the tick-0 gameplay hashes 7/3 and 11/2;
- one AI match on 7/3, seed 1, of 3,600 ticks.

Then I regenerate once. The existing keys must stay byte-identical, which is the proof.
