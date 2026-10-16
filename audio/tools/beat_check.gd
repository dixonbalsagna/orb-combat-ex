extends SceneTree
## The numbers behind docs/audio/brawl-beat.md: how long each hit rings against the perfect follow-up's window, and whether
## the spark and notes can be heard on top of a hit (and do not hide it). From the repo root:
##   godot --headless --path . --script res://audio/tools/beat_check.gd
## Exit code 1 if a note cannot be heard against the hit it rides on, or hides it. No sound device is used.

var bank: AudioBank
var fails: int = 0


func _initialize() -> void:
	bank = AudioBank.new()
	_run.call_deferred()


func ok(cond: bool, msg: String) -> void:
	print("  %s  %s" % ["ok  " if cond else "FAIL", msg])
	if not cond:
		fails += 1


func _db(x: float) -> float:
	return 20.0 * log(maxf(x, 1e-9)) / log(10.0)


## RMS of buf over [t0, t0 + len] ms (zero past the end).
func _rms_at(buf: PackedFloat32Array, rate: int, t0_ms: float, len_ms: float) -> float:
	var a: int = int(t0_ms * 0.001 * rate)
	var b: int = mini(int((t0_ms + len_ms) * 0.001 * rate), buf.size())
	if a >= b:
		return 0.0
	var sum: float = 0.0
	for i in range(a, b):
		sum += buf[i] * buf[i]
	return sqrt(sum / float(b - a))


## The same, through a band-pass at f (q) first.
func _band_rms(buf: PackedFloat32Array, rate: int, f: float, q: float, t0_ms: float, len_ms: float) -> float:
	var c: PackedFloat32Array = buf.duplicate()
	AudioDsp.filter(c, "bp", f, f, 0.0, q, rate)
	return _rms_at(c, rate, t0_ms, len_ms)


func _loudest_frame(buf: PackedFloat32Array, rate: int) -> float:
	var best: float = 0.0
	var t: float = 0.0
	while t < float(buf.size()) / rate * 1000.0:
		best = maxf(best, _rms_at(buf, rate, t, 10.0))
		t += 5.0
	return best


func _run() -> void:
	print("1. how much of a hit is still sounding when its window closes")
	print("   (window ends 5, 6 and 8 ticks after the hit for a light, a medium and a heavy: 83, 100 and 133 ms)")
	var rows: Array = [["impact.light", 83.0], ["impact.light.lite", 83.0], ["impact.medium", 100.0], ["impact.medium.grind", 100.0], ["impact.heavy", 133.0], ["impact.guard", 100.0]]
	for r in rows:
		var id: String = r[0]
		var end_ms: float = r[1]
		var at_end: float = 0.0
		var at_peak: float = 0.0
		var t20: float = 0.0
		var n: int = bank.variants(id)
		for v in range(n):
			var buf: PackedFloat32Array = bank.buffer(id, v)
			var rate: int = bank.rate_of(id)
			var peak: float = _loudest_frame(buf, rate)
			at_peak += peak
			at_end += _rms_at(buf, rate, end_ms, 10.0)
			var t: float = 0.0
			while t < float(buf.size()) / rate * 1000.0 and _rms_at(buf, rate, t, 10.0) > peak * 0.1:
				t += 5.0
			t20 += t
		print("   %-20s at the window's end: %6.1f dB under its loudest 10 ms; down 20 dB by %4.0f ms" % [id, _db(at_end / at_peak), t20 / float(n)])
	var light_end: float = _db(_rms_at(bank.buffer("impact.light", 0), bank.rate_of("impact.light"), 83.0, 10.0) / _loudest_frame(bank.buffer("impact.light", 0), bank.rate_of("impact.light")))
	ok(light_end < -10.0, "a light is mostly gone when its window closes (%.1f dB)" % light_end)

	print("2. can the tok be heard on top of the hit it follows, and does it hide the hit")
	var cfgj: Dictionary = AudioBank.load_json("res://audio/data/beat_cues.json")
	var ratios: Array = cfgj.perfect.spark.ratios
	var tok: PackedFloat32Array = bank.buffer("perfect.tok", 0)
	var hit_buf: PackedFloat32Array = bank.buffer("impact.light", 0)
	print("   offset = how long after the hit's start the tok plays; SNR = the tok's band over the hit's own energy in that band, over the tok's first 60 ms")
	var worst: float = 99.0
	var line: String = ""
	for off in [0.0, 17.0, 33.0, 50.0, 100.0]:
		var w: float = 99.0
		for ratio in ratios:
			var fnote: float = 330.0 * ratio       # the tok glides 420 to 300 Hz: its middle
			var n_rms: float = _band_rms(tok, bank.rate_of("perfect.tok"), fnote, 1.5, 0.0, 60.0)
			var i_rms: float = _band_rms(hit_buf, bank.rate_of("impact.light"), fnote, 1.5, off, 60.0)
			w = minf(w, _db(n_rms / maxf(i_rms, 1e-9)))
		line += "  +%3.0f ms: %5.1f dB" % [off, w]
		if off >= 33.0:
			worst = minf(worst, w)
	print("   tok on impact.light (worst over the three steps)%s" % line)
	ok(worst > 3.0, "from 33 ms into a hit (where the tok is made to start) the tok is over the hit in its own band (worst %.1f dB)" % worst)
	var n_all: float = _rms_at(tok, bank.rate_of("perfect.tok"), 0.0, 60.0)
	var i_all: float = _rms_at(hit_buf, bank.rate_of("impact.light"), 0.0, 60.0)
	var d: float = _db(i_all / maxf(n_all, 1e-9))
	print("   impact.light over perfect.tok: the hit's first 60 ms is %.1f dB above the tok's" % d)
	ok(d > 6.0, "a hit leads a tok in its first 60 ms, so a tok never hides it")
	print("3. is the launcher's ping findable over the music (the stand-in 180 BPM loop, its band 400 to 3000 Hz)")
	var bj: Dictionary = AudioBank.load_json("res://audio/data/brawl_cues.json")
	var ping_gain: float = float(bj.launcher.gain_db)
	var duck_db: float = 0.0
	for dk in bj.launcher.duck:
		if String(dk.bus) == "Music":
			duck_db = -float(dk.db)
	var mus: PackedFloat32Array = _wav_samples("res://audio/preview/suno-reference/suno-ref-riff-180bpm-E.wav")
	if mus.is_empty():
		print("   (the reference loop is not here: skipped)")
	else:
		var mg: float = AudioDsp.db_to_lin(-8.0 - 1.3)       # the Music bus level the demos use
		for k in range(mus.size()):
			mus[k] *= mg
		AudioDsp.filter(mus, "hp", 400.0, 400.0, 0.0, 0.7, 22050)
		AudioDsp.filter(mus, "lp", 3000.0, 3000.0, 0.0, 0.7, 22050)
		var m_rms: float = AudioDsp.rms(mus)
		var pb: PackedFloat32Array = bank.buffer("ui.launcher", 0).duplicate()
		var prate: int = bank.rate_of("ui.launcher")
		AudioDsp.filter(pb, "hp", 400.0, 400.0, 0.0, 0.7, prate)
		AudioDsp.filter(pb, "lp", 3000.0, 3000.0, 0.0, 0.7, prate)
		var p_rms: float = _rms_at(pb, prate, 0.0, 150.0) * AudioDsp.db_to_lin(ping_gain)
		var over: float = _db(p_rms / m_rms)
		print("   ping at %+.1f dB: its first 150 ms is %.1f dB over the music, %.1f dB with the music's %.0f dB duck" % [ping_gain, over, over + duck_db, duck_db])
		ok(over + duck_db >= 9.0, "the ping is at least 9 dB over the music in its band with the duck (the old ring was 9.9)")

	print("\nbeat check %s" % ("FAILED (%d)" % fails if fails > 0 else "passed"))
	quit(1 if fails > 0 else 0)


## The samples of a 16-bit mono WAV, as -1 to 1.
func _wav_samples(path: String) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	var bytes: PackedByteArray = f.get_buffer(f.get_length())
	var pos: int = 12
	while pos + 8 <= bytes.size():
		var id: String = bytes.slice(pos, pos + 4).get_string_from_ascii()
		var size: int = bytes.decode_u32(pos + 4)
		if id == "data":
			out.resize(size / 2)
			for i in range(size / 2):
				out[i] = float(bytes.decode_s16(pos + 8 + i * 2)) / 32768.0
			return out
		pos += 8 + size + (size & 1)
	return out
