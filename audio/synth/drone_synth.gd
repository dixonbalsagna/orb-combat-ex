class_name DroneSynth
extends RefCounted
## A drone that loops without a seam: a fundamental and a few harmonics whose every cycle count in the loop is a whole
## number, so the last sample runs straight into the first. No noise and no randomness: a drone is a pure function of its
## recipe. Used for the beam struggle's bed (docs/audio/launch-and-tug.md), played by AudioVoices as a looped voice whose
## gain and pitch are updated while it runs. Recipe (data/tug_cues.json "drones"):
##   rate        samples a second
##   seconds     the loop's length
##   f           the fundamental, Hz (snapped to a whole number of cycles in the loop)
##   partials    [[multiple, amplitude], ...] with whole multiples
##   peak_db     the peak after normalising


static func render(recipe: Dictionary) -> PackedFloat32Array:
	return AudioSlice.run_sync(Callable(DroneSynth, "render_a"), [recipe])


static func render_a(recipe: Dictionary) -> PackedFloat32Array:
	var rate: int = int(recipe.get("rate", 32000))
	var n: int = int(round(float(recipe.get("seconds", 2.0)) * float(rate)))
	var cycles: int = maxi(1, int(round(float(recipe.f) * float(n) / float(rate))))
	var w: float = TAU * float(cycles) / float(n)
	var out := PackedFloat32Array()
	out.resize(n)
	var _c31: int = 0
	var _e31: int = n
	while _c31 < _e31:
		for i in range(_c31, mini(_c31 + 1024, _e31)):
			var s: float = 0.0
			for p in recipe.partials:
				s += float(p[1]) * sin(w * float(int(p[0])) * float(i))
			out[i] = s
		_c31 += 1024
		if AudioSlice.due():
			await AudioSlice.next_frame()
	await AudioDspA.normalize(out, AudioDsp.db_to_lin(float(recipe.get("peak_db", -12.0))))
	return out
