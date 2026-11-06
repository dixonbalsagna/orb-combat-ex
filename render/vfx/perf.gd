class_name VfxPerf
extends RefCounted
## The Performance level's caps on the debris pool (docs/vfx/perf-level.md; Performance's order of 2026-10-31, docs/perf/quality-range.md 2.2: VFX is 0.41 ms mean and 1.4 p95, and `Q_LOW` saves only 0.1 to 0.3 of it).
## Four things, all off unless the hub's `perf_level` is on, all numbers in data/vfx/perf.json:
##   - a lower pool and lower per-tick spawn budgets than `Q_LOW` has;
##   - a burst's overflow is BATCHED: bits past the tick's budget wait in a short queue and are let in a few a tick, with their flight advanced by the time they waited, so a collapse's 460 bits no longer land on one frame;
##   - a spawn on the FAR SIDE is not made: dust and debris farther from both fighters than the view can reach, and dust well behind the fighter plane, are skipped before they are built;
##   - at most a few of the pool's timed jobs (the ripples, the floors' waves) run in one tick; the rest run on the next.
## Presentation only: it reads the pool and the fighters, writes nothing of the sim, and with the switch off it is not read at all.

const DEFAULTS: Dictionary = {
	"debris": {"cap": 80, "spawn_per_tick": 50, "shard_per_tick": 40, "spill_cap": 60, "spill_per_tick": 20, "spill_wait_ticks": 8},
	"jobs": {"per_tick": 2},
	"far": {"reach_k": 1.4, "margin": 1200.0, "puff_z_back": 900.0},
}

static var _data: Dictionary = {}
static var _loaded: bool = false


static func warm() -> void:
	if _loaded:
		return
	_loaded = true
	var path := "res://data/vfx/perf.json"
	if FileAccess.file_exists(path):
		var v = JSON.parse_string(FileAccess.get_file_as_string(path))
		if v is Dictionary:
			_data = v


static func p(group: String, key: String) -> float:
	warm()
	var g = _data.get(group)
	if g is Dictionary and g.has(key):
		return float(g[key])
	return float(DEFAULTS[group][key])
