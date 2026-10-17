class_name VfxTremor
extends RefCounted
## The tremor's dust (docs/vfx/catastrophe-plan.md section 5; run-mode section 3.1; Legal c01 to c06): a live quake with no pause, shown as low curtains of dust along the whole visible slice and a
## patter of small rubble. A quake, never glowing fissures, never a ring, never a rhythm: the audio's 2.5 Hz wobble is NOT mirrored here.
## It is not a catastrophe light event: dust is dark and slow, so it asks nothing of the `cat` class (flash_registry.gd). Its brightness never changes faster than its envelope does (a smootherstep
## over the onset, one over the settling), and the envelope's steepest step is checked (effects_check) to be a small fraction of a luminance step.
## The cue is `tremor` (Audio's list: `n` is the tick it ends). The state is a start tick and an end tick; the curtains are a function of age, so a pause, a seek and a replay are right by construction.
## Presentation only: no sim write, no `S.rng`; every pseudo-random choice is a hash of the sprite's index and the tremor's start tick.

const DEFAULTS: Dictionary = {
	"sprites": [60, 110, 160], "alpha_max": 0.5, "onset_s": 1.0, "settle_s": 4.0, "calm_onset_s": 1.5, "calm_settle_s": 5.0, "shiver": 0.06, "wander": 0.35, "colour": "#8a8277",
	"height_k": [0.16, 0.46], "width_k": [2.4, 4.4], "z": [-20.0, -6.0], "rubble_per_s": 40.0, "rubble_size": [4.0, 9.0], "rubble_life_s": [0.8, 1.6], "max_overlap": 2,
}

static var _data: Dictionary = {}
static var _loaded: bool = false

## The tremors in flight (at most `max_overlap`): {start, end, seed}, in the hub's clock (ticks).
var runs: Array = []
var now: int = 0
var rubble_made: int = 0            # for the tests
var _rubble_acc: float = 0.0


static func warm() -> void:
	if _loaded:
		return
	_loaded = true
	var path := "res://data/vfx/catastrophe.json"
	if FileAccess.file_exists(path):
		var v = JSON.parse_string(FileAccess.get_file_as_string(path))
		if v is Dictionary and v.get("tremor") is Dictionary:
			_data = v["tremor"]


static func p(key: String):
	warm()
	var v = _data.get(key)
	return v if v != null else DEFAULTS[key]


func reset() -> void:
	runs.clear()
	now = 0
	rubble_made = 0
	_rubble_acc = 0.0


## A hash of two integers to 0..1: no random stream is drawn.
static func hash01(a: int, b: int) -> float:
	var h: int = ((a * 73856093) ^ (b * 19349663) ^ 0x5bd1e995) & 0x7fffffff
	h = ((h >> 13) ^ h) & 0x7fffffff
	h = (h * 1274126177) & 0x7fffffff
	return float((h >> 8) & 0xffff) / 65536.0


## The envelope at `age` ticks after the tremor's start, 0 to 1: a smootherstep up over the onset, held until the tremor's end (`dur` ticks), a smootherstep down over the settling.
static func level(age: float, dur: float, onset: float, settle: float) -> float:
	if age <= 0.0:
		return 0.0
	if age < dur:
		return _sm(minf(age / maxf(onset, 1.0), 1.0))
	var top: float = _sm(minf(dur / maxf(onset, 1.0), 1.0))
	var d: float = (age - dur) / maxf(settle, 1.0)
	if d >= 1.0:
		return 0.0
	return top * (1.0 - _sm(d))


static func _sm(u: float) -> float:
	return u * u * u * (u * (u * 6.0 - 15.0) + 10.0)


## The onset and settling in ticks for this mode: the calm form (Reduce flashing, or Reduced motion) is slower.
static func onset_ticks(calm: bool) -> float:
	return (float(p("calm_onset_s")) if calm else float(p("onset_s"))) * 60.0


static func settle_ticks(calm: bool) -> float:
	return (float(p("calm_settle_s")) if calm else float(p("settle_s"))) * 60.0


## Once a tick, from the hub: the clock, and the finished tremors dropped.
func step(calm: bool) -> void:
	now += 1
	var i: int = 0
	while i < runs.size():
		var r: Dictionary = runs[i]
		if float(now - int(r["start"])) >= float(int(r["end"]) - int(r["start"])) + settle_ticks(calm) + 1.0:
			runs.remove_at(i)
		else:
			i += 1


## The `tremor` cue: `n` is the tick it ends (the sim's tick). A second cue while one runs adds a run (at most max_overlap; the oldest goes).
func on_events(S: SimState, events: Array) -> void:
	for e in events:
		if e.type != "cue" or String(e.kind) != "tremor":
			continue
		var dur: int = maxi(int(float(e.n)) - S.tick, 1)
		runs.append({"start": now, "end": now + dur, "seed": S.tick})
		while runs.size() > int(p("max_overlap")):
			runs.pop_front()


## The strongest envelope of the runs in flight at the clock's tick (plus `frac` of a tick), 0 to 1.
func strength(calm: bool, frac: float = 0.0) -> float:
	var best: float = 0.0
	for r in runs:
		best = maxf(best, level(float(now - int(r["start"])) + frac, float(int(r["end"]) - int(r["start"])), onset_ticks(calm), settle_ticks(calm)))
	return best


func active() -> bool:
	return not runs.is_empty()


## A patter of small rubble through the debris pool while a tremor runs (not while it settles): up to `rubble_per_s` a second (half in the calm form), from the ground round the fighters, at hashed
## places and times. `debris` is the shared pool; the pool's own caps hold.
func rubble(S: SimState, debris: VfxDebris, calm: bool) -> void:
	if runs.is_empty() or S.fighters.size() < 2:
		return
	var r: Dictionary = runs[runs.size() - 1]
	if now >= int(r["end"]):
		return
	_rubble_acc += float(p("rubble_per_s")) * (0.5 if calm else 1.0) * strength(calm) / 60.0
	var cx: float = S.fighters[0].x + SimWrap.sdx(S.fighters[0].x, S.fighters[1].x) * 0.5
	var sz: Array = p("rubble_size")
	var lf: Array = p("rubble_life_s")
	while _rubble_acc >= 1.0:
		_rubble_acc -= 1.0
		var k: int = rubble_made
		rubble_made += 1
		var sd: int = int(r["seed"])
		var x: float = SimWrap.wrap(cx + (hash01(k, sd) - 0.5) * 2400.0)
		var y: float = WorldTerrain.groundY(S, x) + 6.0
		var vx: float = (hash01(k, sd + 1) - 0.5) * 120.0
		var vy: float = 60.0 + hash01(k, sd + 2) * 140.0
		var size: float = lerpf(float(sz[0]), float(sz[1]), hash01(k, sd + 3))
		var life: float = lerpf(float(lf[0]), float(lf[1]), hash01(k, sd + 4))
		debris.chunk(x, y, -60.0, vx, vy, size, life, VfxEarth.tones_for_surface("rubble", x), 0, 6.0)
