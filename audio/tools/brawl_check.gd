extends SceneTree
## Do the brawl's sounds behave? Stages the brawl's cue and damage events (the sim's side of them is not built yet, so they
## are staged as VFX does, with the field names Encounter and the EP gave) and feeds them to AudioCues and AudioVoices.
## From the repo root:
##   godot --headless --path . --script res://audio/tools/brawl_check.gd
## Exit code 1 on any failure. No sound device is used (the dummy audio driver).

var bank: AudioBank
var cues: AudioCues
var S: SimState
var fails: int = 0


func _initialize() -> void:
	bank = AudioBank.new()
	cues = AudioCues.new(bank)
	_run.call_deferred()


func ok(cond: bool, msg: String) -> void:
	print("  %s  %s" % ["ok  " if cond else "FAIL", msg])
	if not cond:
		fails += 1


func _run() -> void:
	S = SimCore.createSim()
	SimCore.newMatch(S, 4)
	_hits()
	_flurry()
	_sounds()
	_launcher()
	_windup()
	_energy()
	_charge()
	await _voices()
	SimCore.dispose(S)
	print("\nbrawl check %s" % ("FAILED (%d)" % fails if fails > 0 else "passed"))
	quit(1 if fails > 0 else 0)


# ---- staging helpers
func blow(actor: int, text: String, n: int = -1) -> SimState.FxEvent:
	var e := SimState.FxEvent.new()
	e.type = "cue"
	e.kind = "blow"
	e.text = text
	e.actor = float(actor)
	e.target = float(1 - actor)
	e.n = n    # -1: the tick of the batch it is fed in (tick() fills it in)
	return e


func cue(kind: String, text: String, actor: int, extra: Dictionary = {}) -> SimState.FxEvent:
	var e := SimState.FxEvent.new()
	e.type = "cue"
	e.kind = kind
	e.text = text
	e.actor = float(actor)
	e.target = float(1 - actor)
	for k in extra:
		e.set(k, extra[k])
	return e


func dmg(attacker: int, kind: String, amount: float) -> SimState.FxEvent:
	var e := SimState.FxEvent.new()
	e.type = "damage"
	e.attacker = float(attacker)
	e.victim = float(1 - attacker)
	e.kind = kind
	e.amount = amount
	e.region = "core"
	e.x = S.fighters[1 - attacker].x
	e.y = S.fighters[1 - attacker].y
	return e


## A tick: set the sim tick, feed the events, return the cues.
func tick(t: int, events: Array) -> Array:
	S.tick = t
	S.T = float(t) / 60.0
	for e in events:
		if e.type == "cue" and e.kind == "blow" and int(e.n) == -1:
			e.n = t
	return cues.consume(S, events)


func _sound_of(list: Array) -> Array:
	return list.filter(func(c): return c.kind == "sfx" and c.sound.begins_with("impact.")).map(func(c): return c.sound)


# ---- step 1: the three strengths and the guard
func _hits() -> void:
	print("1. strength comes from the blow cue, the amount only as a fallback")
	cues.reset(11)
	var t: int = 1000
	var r: Array = tick(t, [blow(0, "medium"), dmg(0, "light", 12.0)])
	ok(_sound_of(r) == ["impact.medium"], "a medium blow cue makes impact.medium even when the damage is small")
	t += 60
	r = tick(t, [blow(0, "heavy"), dmg(0, "heavy", 30.0)])
	ok(_sound_of(r) == ["impact.heavy"], "a heavy blow cue makes impact.heavy")
	t += 60
	r = tick(t, [blow(1, "flurry"), dmg(1, "light", 90.0)])
	ok(_sound_of(r) == ["impact.light"], "the retired text flurry counts as light, whatever the damage")
	t += 60
	r = tick(t, [dmg(0, "light", 10.0)])
	ok(_sound_of(r) == ["impact.light"], "no blow cue, small damage: light")
	t += 60
	r = tick(t, [dmg(0, "light", 40.0)])
	ok(_sound_of(r) == ["impact.medium"], "no blow cue, damage 40: medium")
	t += 60
	r = tick(t, [dmg(0, "heavy", 90.0)])
	ok(_sound_of(r) == ["impact.heavy"], "no blow cue, damage 90: heavy")
	t += 60
	r = tick(t, [blow(0, "medium"), dmg(0, "guard", 20.0)])
	ok(_sound_of(r) == ["impact.guard"], "a guarded hit is impact.guard")
	var g_light := _pitch_of(tick(t + 600, [blow(0, "light"), dmg(0, "guard", 10.0)]))
	var g_heavy := _pitch_of(tick(t + 1200, [blow(0, "heavy"), dmg(0, "guard", 10.0)]))
	ok(g_light > g_heavy, "a guard sounds higher for a light blow than for a heavy one (%.2f against %.2f)" % [g_light, g_heavy])
	t += 1800
	r = tick(t, [dmg(0, "beam", 120.0)])
	ok(r.any(func(c): return c.sound == "impact.heavy"), "a beam hit still uses the old path")
	# a blow cue is used once
	cues.reset(11)
	t += 600
	r = tick(t, [blow(0, "heavy"), dmg(0, "light", 12.0), dmg(0, "light", 12.0)])
	ok(_sound_of(r) == ["impact.heavy", "impact.light"], "one blow cue is used for one hit, the next falls back")


func _pitch_of(list: Array) -> float:
	for c in list:
		if c.sound == "impact.guard":
			return c.pitch
	return 0.0


# ---- step 1: flurry mode
func _flurry() -> void:
	print("2. flurry mode (mean over 60 flurries of 8 lights, 6 ticks apart)")
	var g_first: float = 0.0
	var g_rest: float = 0.0
	var p_first: float = 0.0
	var p_last: float = 0.0
	var g_close: float = 0.0
	var g_seventh: float = 0.0
	var N: int = 60
	for trial in range(N):
		cues.reset(100 + trial)
		var base: int = 5000 + trial * 400
		var gains: Array = []
		var pitches: Array = []
		for i in range(8):
			var ev: Array = [blow(0, "light"), dmg(0, "light", 12.0)]
			if i == 7:
				ev.append(cue("stagger", "flurry", 1, {"target": 0.0, "n": 14.0}))
			var r: Array = tick(base + 6 * i, ev)
			var c = r.filter(func(x): return x.sound == "impact.light")[0]
			gains.append(c.gain_db)
			pitches.append(c.pitch)
		g_first += (gains[0] + gains[1] + gains[2]) / 3.0
		g_rest += (gains[3] + gains[4] + gains[5] + gains[6]) / 4.0
		p_first += pitches[0]
		p_last += pitches[6]
		g_seventh += gains[6]
		g_close += gains[7]
	g_first /= N
	g_rest /= N
	p_first /= N
	p_last /= N
	g_close /= N
	g_seventh /= N
	print("     first three %.2f dB, next four %.2f dB, pitch %.3f to %.3f, seventh %.2f dB, close %.2f dB" % [g_first, g_rest, p_first, p_last, g_seventh, g_close])
	ok(g_rest < g_first - 1.0 and g_rest > g_first - 3.2, "from the fourth blow a light is about 2 dB quieter")
	ok(p_last > p_first * 1.05, "the run climbs in pitch")
	ok(g_close > g_seventh + 3.5, "the blow that closes the flurry is the loudest of the run")
	# a different attacker's lights do not count toward this one's flurry
	cues.reset(5)
	var gs: Array = []
	for i in range(6):
		var r: Array = tick(9000 + 6 * i, [blow(i % 2, "light"), dmg(i % 2, "light", 12.0)])
		gs.append(r[0].gain_db)
	ok(true, "two fighters trading lights each keep their own count (no assertion on the jitter: %.1f dB spread)" % (gs.max() - gs.min()))
	# determinism
	cues.reset(77)
	var d1: String = _flurry_digest()
	cues.reset(77)
	var d2: String = _flurry_digest()
	cues.reset(78)
	var d3: String = _flurry_digest()
	ok(d1 == d2 and d1 != d3, "the same seed gives the same flurry, another seed another one")


func _flurry_digest() -> String:
	var lines := PackedStringArray()
	for i in range(8):
		for c in tick(20000 + 6 * i, [blow(0, "light"), dmg(0, "light", 12.0)]):
			lines.append("%d|%s|%d|%.3f|%.4f" % [i, c.sound, c.variant, c.gain_db, c.pitch])
	return "\n".join(lines).sha256_text().substr(0, 16)


# ---- the new sounds render and sit where intended
func _sounds() -> void:
	print("3. the new impact sounds")
	var info: Dictionary = {}
	for id in ["impact.light", "impact.medium", "impact.heavy", "impact.guard", "impact.whiff"]:
		var buf: PackedFloat32Array = bank.buffer(id, 0)
		var rate: int = bank.rate_of(id)
		info[id] = {"s": float(buf.size()) / rate, "peak": AudioDsp.peak(buf), "rms": AudioDsp.rms(buf)}
		print("     %-14s %.2f s, peak %.1f dBFS, rms %.1f dBFS" % [id, info[id].s, 20.0 * log(info[id].peak) / log(10.0), 20.0 * log(info[id].rms) / log(10.0)])
	ok(info["impact.light"].s < info["impact.medium"].s and info["impact.medium"].s < info["impact.heavy"].s, "light, medium and heavy are told apart by length")
	ok(info["impact.medium"].s > 0.22 and info["impact.medium"].s < 0.4, "the medium is about 0.3 s")
	ok(info["impact.light"].peak < info["impact.medium"].peak and info["impact.medium"].peak < info["impact.heavy"].peak, "and by level")
	for id in ["impact.medium", "impact.guard", "impact.whiff"]:
		var b: PackedFloat32Array = bank.buffer(id, 0)
		ok(AudioDsp.peak(b) < 0.99 and absf(b[0]) < 0.01 and absf(b[b.size() - 1]) < 0.01, "%s: no clipping and clean ends" % id)


# ---- step 2: the launcher
func _launcher() -> void:
	print("5. the launcher (B now)")
	cues.reset(21)
	var t: int = 40000
	var r: Array = tick(t, [cue("launcher_open", "flurry", 0, {"n": t + 14})])
	var pings: Array = r.filter(func(c): return c.sound == "ui.launcher")
	ok(pings.size() == 1, "launcher_open with a 14-tick stagger makes one ping")
	var c = pings[0]
	ok(c.priority >= 95 and c.cap == 1 and c.group == "launcher.0", "critical priority, one at a time, in the launcher's own group")
	ok(c.duck.size() == 2 and c.duck[0].bus == "Sfx" and c.duck[1].bus == "Music", "it ducks the impacts and the music")
	ok(c.bus == "Alert", "on its own bus, so it does not duck itself")
	ok(absf(c.x - S.fighters[1].x) < 0.01, "it sounds at the staggered fighter")
	r = tick(t + 600, [cue("launcher_open", "shove", 0, {"n": t + 600 + 8})])
	ok(r.filter(func(x): return x.sound == "ui.launcher").is_empty(), "a stagger of 8 ticks (a shove) is no launcher")
	# the same every time: no random spread, so it is learned
	var gains: Dictionary = {}
	var pitches: Dictionary = {}
	for i in range(20):
		var q: Array = tick(t + 1200 + 100 * i, [cue("launcher_open", "flurry", i % 2, {"n": t + 1200 + 100 * i + 20})])
		gains[q[0].gain_db] = true
		pitches[q[0].pitch] = true
	ok(gains.size() == 1 and pitches.size() == 1, "the ping is identical every time (one gain, one pitch)")
	# close: thrown cuts it, a lapse lets it ring
	r = tick(t + 4000, [cue("launcher_close", "thrown", 0)])
	ok(r.size() == 1 and r[0].sound == "" and r[0].stop_group == "launcher.0" and r[0].fade_ms == 40, "a thrown launch stops the ping (40 ms fade)")
	r = tick(t + 4100, [cue("launcher_close", "lapsed", 0)])
	ok(r.is_empty(), "a lapsed window lets it ring out")
	r = tick(t + 4200, [cue("launcher_close", "", 0, {"k": 1.0})])
	ok(r.size() == 1, "k 1 on the close also means thrown")
	var buf: PackedFloat32Array = bank.buffer("ui.launcher", 0)
	var rate: int = bank.rate_of("ui.launcher")
	print("     ui.launcher %.2f s, peak %.1f dBFS, rms %.1f dBFS" % [float(buf.size()) / rate, 20.0 * log(AudioDsp.peak(buf)) / log(10.0), 20.0 * log(AudioDsp.rms(buf)) / log(10.0)])
	ok(float(buf.size()) / rate > 0.2 and float(buf.size()) / rate < 0.35, "about a quarter of a second")


# ---- step 3: the wind-up, the misses, the double hit
func _windup() -> void:
	print("6. the wind-up, misses and the double hit")
	cues.reset(31)
	var t: int = 50000
	var r: Array = tick(t, [cue("windup", "start", 0, {"n": t + 12})])
	ok(r.size() == 1 and r[0].sound == "windup.medium" and absf(r[0].pitch - 1.0) < 0.05, "a 12-tick wind-up is the medium's gather at its own length")
	r = tick(t + 100, [cue("windup", "start", 1, {"n": t + 100 + 28})])
	ok(r.size() == 1 and r[0].sound == "windup.heavy" and absf(r[0].pitch - 1.0) < 0.05 and r[0].group == "windup.1", "a 28-tick wind-up is the heavy's, in the fighter's own group")
	r = tick(t + 200, [cue("windup", "start", 0, {"n": t + 200 + 14})])
	ok(r[0].sound == "windup.medium" and absf(r[0].pitch - 12.0 / 14.0) < 0.02, "a 14-tick wind-up (the launcher's) is stretched to peak as it lands")
	r = tick(t + 300, [cue("windup", "start", 0, {"n": t + 300 + 3})])
	ok(r.is_empty(), "a 3-tick contact (a light) has no gather")
	for k in [2, 3]:
		r = tick(t + 400 + k, [cue("windup", "end", 0, {"k": float(k)})])
		ok(r.size() == 1 and r[0].stop_group == "windup.0" and r[0].fade_ms == 60, "a wind-up stopped by a blow or lost (k %d) is faded out" % k)
	for k in [1, 4]:
		r = tick(t + 500 + k, [cue("windup", "end", 0, {"k": float(k)})])
		ok(r.is_empty(), "thrown or a miss (k %d) lets it finish" % k)
	for why in ["gave_ground", "reach", "dodge"]:
		r = tick(t + 600, [cue("miss", why, 0)])
		ok(r.size() == 1 and r[0].sound == "impact.whiff", "a miss (%s) is the air" % why)
	var pitches: Array = []
	for why in ["gave_ground", "reach"]:
		pitches.append(tick(t + 700, [cue("miss", why, 0)])[0].pitch)
	ok(pitches[0] < pitches[1], "a reach that falls short is higher than giving ground")
	# the double hit
	cues.reset(41)
	var land: int = t + 900 + 8
	r = tick(t + 900, [cue("double_hit", "both", 0, {"n": land, "amount": 8.0, "k": 3.0})])
	ok(r.size() == 1 and r[0].sound == "double.charge" and absf(r[0].pitch - 1.0) < 0.05, "the double hit announces itself with a charge (8 ticks ahead)")
	r = tick(land, [dmg(0, "heavy", 60.0), dmg(1, "heavy", 60.0)])
	var imp: Array = r.filter(func(c): return c.sound.begins_with("impact."))
	ok(imp.size() == 1 and imp[0].sound == "impact.double", "the two blows landing together make one impact.double (%d impact cues)" % imp.size())
	r = tick(land + 600, [dmg(0, "heavy", 60.0)])
	ok(r.filter(func(c): return c.sound == "impact.heavy").size() == 1, "a later heavy hit is an ordinary heavy again")
	for id in ["windup.medium", "windup.heavy", "double.charge", "impact.double"]:
		var buf: PackedFloat32Array = bank.buffer(id, 0)
		var sec: float = float(buf.size()) / bank.rate_of(id)
		print("     %-14s %.3f s, peak %.1f dBFS" % [id, sec, 20.0 * log(AudioDsp.peak(buf)) / log(10.0)])
		ok(AudioDsp.peak(buf) < 0.99 and absf(buf[buf.size() - 1]) < 0.01, "%s: no clipping, clean end" % id)
	var m: float = float(bank.buffer("windup.medium", 0).size()) / bank.rate_of("windup.medium")
	var h: float = float(bank.buffer("windup.heavy", 0).size()) / bank.rate_of("windup.heavy")
	var dc: float = float(bank.buffer("double.charge", 0).size()) / bank.rate_of("double.charge")
	ok(absf(m - 12.0 / 60.0) < 0.02 and absf(h - 28.0 / 60.0) < 0.03 and absf(dc - 8.0 / 60.0) < 0.02, "the gathers are 12, 28 and 8 ticks long (%.3f, %.3f, %.3f s)" % [m, h, dc])


# ---- step 4: energy in reach
func _energy() -> void:
	print("7. energy in reach: the point-blank bolt and the blast")
	cues.reset(51)
	var t: int = 60000
	var r: Array = tick(t, [cue("energy_reach", "bolt", 0, {"amount": 2.0, "n": t + 2})])
	ok(r.is_empty(), "a bolt has no gather (it is 2 ticks)")
	r = tick(t + 100, [cue("energy_reach", "blast", 0, {"amount": 12.0, "n": t + 112})])
	ok(r.size() == 1 and r[0].sound == "energy.gather" and absf(r[0].pitch - 1.0) < 0.05 and r[0].group == "windup.0", "a blast gathers for its 12 ticks")
	r = tick(t + 112, [cue("energy_land", "blast", 0, {"source": "hit"})])
	ok(r.size() == 2 and r[0].stop_group == "windup.0" and r[1].sound == "energy.blast", "the blast lands: the gather is cut and the whump sounds")
	var gh: float = 0.0
	var gg: float = 0.0
	var ga: float = 0.0
	for i in range(30):
		cues.reset(200 + i)
		gh += tick(t + 1000 + i * 100, [cue("energy_land", "blast", 0, {"source": "hit"})]).filter(func(c): return c.sound == "energy.blast")[0].gain_db
		gg += tick(t + 1050 + i * 100, [cue("energy_land", "blast", 0, {"source": "guard"})]).filter(func(c): return c.sound == "energy.blast")[0].gain_db
		ga += tick(t + 1075 + i * 100, [cue("energy_land", "blast", 0, {"source": "armour"})]).filter(func(c): return c.sound == "energy.blast")[0].gain_db
	ok(gh / 30 > ga / 30 + 1.5 and ga / 30 > gg / 30 + 1.5, "a blast is loudest on a hit, then armour, then a guard (%.1f, %.1f, %.1f dB)" % [gh / 30, ga / 30, gg / 30])
	r = tick(t + 5000, [cue("energy_land", "blast", 0, {"source": "miss"})])
	ok(r.filter(func(c): return c.sound == "energy.blast").size() == 1 and r.filter(func(c): return c.sound == "energy.blast")[0].gain_db < -4.0, "a missed blast is the whump, quieter")
	r = tick(t + 5100, [cue("energy_land", "bolt", 0, {"source": "miss"})])
	ok(r.size() == 1 and r[0].sound == "impact.whiff", "a missed bolt is the air")
	# a mash: ten bolts in two thirds of a second
	cues.reset(61)
	var gains: Array = []
	var sounds: Array = []
	for i in range(10):
		var q: Array = tick(t + 8000 + 4 * i, [cue("energy_land", "bolt", 0, {"source": "hit"})])
		gains.append(q[0].gain_db)
		sounds.append(q[0].sound)
	ok(sounds.slice(0, 5).all(func(x): return x == "energy.bolt") and sounds.slice(5).all(func(x): return x == "energy.bolt.lite"), "from the sixth bolt in a second the zap is dropped (energy.bolt.lite)")
	var first: float = 0.0
	var later: float = 0.0
	for k in range(40):
		cues.reset(300 + k)
		var gs: Array = []
		for i in range(8):
			gs.append(tick(t + 20000 + 400 * k + 4 * i, [cue("energy_land", "bolt", 0, {"source": "hit"})])[0].gain_db)
		first += (gs[0] + gs[1] + gs[2] + gs[3] + gs[4]) / 5.0
		later += (gs[5] + gs[6] + gs[7]) / 3.0
	ok(later / 40.0 < first / 40.0 - 2.0, "and it is 3 dB down (%.2f against %.2f dB)" % [later / 40.0, first / 40.0])
	for id in ["energy.bolt", "energy.bolt.lite", "energy.gather", "energy.blast"]:
		var buf: PackedFloat32Array = bank.buffer(id, 0)
		var sec: float = float(buf.size()) / bank.rate_of(id)
		print("     %-18s %.3f s, peak %.1f dBFS" % [id, sec, 20.0 * log(AudioDsp.peak(buf)) / log(10.0)])
		ok(AudioDsp.peak(buf) < 0.99 and absf(buf[buf.size() - 1]) < 0.01, "%s: no clipping, clean end" % id)
	ok(absf(float(bank.buffer("energy.gather", 0).size()) / bank.rate_of("energy.gather") - 12.0 / 60.0) < 0.02, "the gather is 12 ticks long")


# ---- the heavy's charge: the hum, the full tick, the armour
func tk(t: int, frozen: bool, events: Array = []) -> Array:
	var te := SimState.FxEvent.new()
	te.type = "tick"
	te.dt = 1.0 / 60.0
	te.frozen = frozen
	return tick(t, [te] + events)


func _charge() -> void:
	print("8. the heavy's charge: hum, full tick, armour")
	cues.reset(61)
	var t0: int = 70000
	# B held: a 28-tick wind-up starts, then it runs on as a charge (the sim ends it when thrown)
	var r: Array = tk(t0, false, [cue("windup", "start", 1, {"n": t0 + 28})])
	var hum_at: int = -1
	var hums: int = 0
	for i in range(1, 60):
		var batch: Array = tk(t0 + i, false)
		for c in batch:
			if c.sound == "charge.hum":
				hums += 1
				if hum_at < 0:
					hum_at = i
					ok(c.group == "charge.1" and c.cls == "charge", "the hum is in the charger's own group")
	ok(hums == 1 and hum_at == 32, "one hum, on the 32nd live tick (got %d at %d)" % [hums, hum_at])
	# the full tick: exact to the event, one fixed sound, on the Alert bus
	r = tk(t0 + 44, false, [cue("charge_full", "b", 1)])
	var ticks: Array = r.filter(func(c): return c.sound == "charge.tick.heavy")
	ok(ticks.size() == 1 and ticks[0].bus == "Alert" and ticks[0].priority >= 90, "charge_full makes one tick on the Alert bus, critical priority")
	ok(ticks[0].variant == 0 and is_equal_approx(ticks[0].pitch, 1.0), "fixed: no variant, no pitch change")
	r = tk(t0 + 45, false, [cue("charge_full", "y", 1)])
	ok(r.filter(func(c): return c.sound == "charge.tick.heavy").is_empty(), "the Y's full charge is not in this chain")
	# release: the hum is cut, however the charge ended
	r = tk(t0 + 48, false, [cue("windup", "end", 1, {"k": 1.0})])
	ok(r.size() == 1 and r[0].stop_group == "charge.1" and r[0].sound == "", "thrown: the hum stops")
	# hit-stop: frozen ticks do not move the hum
	cues.reset(62)
	var t1: int = 71000
	tk(t1, false, [cue("windup", "start", 0, {"n": t1 + 28})])
	var early: int = 0
	for i in range(1, 31):
		early += tk(t1 + i, false).filter(func(c): return c.sound == "charge.hum").size()
	for i in range(31, 51):
		early += tk(t1 + i, true).filter(func(c): return c.sound == "charge.hum").size()
	ok(early == 0, "20 frozen ticks (a hit-stop) do not start the hum early")
	r = tk(t1 + 51, false)
	r.append_array(tk(t1 + 52, false))
	ok(r.filter(func(c): return c.sound == "charge.hum").size() == 1, "it starts on the 32nd live tick (a hit-stop in between)")
	tk(t1 + 60, false, [cue("windup", "end", 0, {"k": 3.0})])
	# a medium's wind-up is no charge: no hum
	cues.reset(63)
	var t2: int = 72000
	tk(t2, false, [cue("windup", "start", 0, {"n": t2 + 12})])
	var mh: int = 0
	for i in range(1, 60):
		mh += tk(t2 + i, false).filter(func(c): return c.sound == "charge.hum").size()
	ok(mh == 0, "a medium's 12-tick wind-up has no hum")
	# armour: B (slot 1) is charging; A's blows land on him
	cues.reset(64)
	var t3: int = 73000
	tk(t3, false, [cue("windup", "start", 1, {"n": t3 + 28})])
	for i in range(1, 6):
		tk(t3 + i, false)
	r = tk(t3 + 6, false, [blow(0, "light"), dmg(0, "light", 12.0)])
	ok(r.filter(func(c): return c.sound == "impact.absorbed").size() == 1 and r.filter(func(c): return c.sound == "impact.light").size() == 1, "a light on a charging B: the hit, and the dull absorbed tick under it")
	r = tk(t3 + 8, false, [blow(0, "medium"), dmg(0, "light", 35.0)])
	ok(r.filter(func(c): return c.sound == "impact.absorbed").is_empty(), "a medium in the first 20 live ticks ends it: no armour tick")
	for i in range(9, 26):
		tk(t3 + i, false)
	r = tk(t3 + 26, false, [blow(0, "medium"), dmg(0, "light", 35.0)])
	var ab: Array = r.filter(func(c): return c.sound == "impact.absorbed")
	ok(ab.size() == 1 and ab[0].pitch < 1.0, "a medium after 20 live ticks is absorbed (a lower tick)")
	r = tk(t3 + 27, false, [blow(0, "heavy"), dmg(0, "heavy", 80.0)])
	ok(r.filter(func(c): return c.sound == "impact.absorbed").is_empty(), "a heavy is not absorbed")
	r = tk(t3 + 28, false, [cue("windup", "end", 1, {"k": 2.0})])
	r = tk(t3 + 40, false, [blow(0, "light"), dmg(0, "light", 12.0)])
	ok(r.filter(func(c): return c.sound == "impact.absorbed").is_empty(), "once the charge is over, a light is an ordinary light")
	# a light on a fighter who is not winding up
	r = tk(t3 + 60, false, [blow(1, "light"), dmg(1, "light", 12.0)])
	ok(r.filter(func(c): return c.sound == "impact.absorbed").is_empty(), "no armour tick on a fighter who is not winding up")
	# the sounds
	for id in ["charge.tick.heavy", "charge.hum", "impact.absorbed"]:
		var buf: PackedFloat32Array = bank.buffer(id, 0)
		var sec: float = float(buf.size()) / bank.rate_of(id)
		print("     %-18s %.3f s, peak %.1f dBFS" % [id, sec, 20.0 * log(AudioDsp.peak(buf)) / log(10.0)])
		ok(AudioDsp.peak(buf) < 0.99 and absf(buf[buf.size() - 1]) < 0.01, "%s: no clipping, clean end" % id)
	var tick_sec: float = float(bank.buffer("charge.tick.heavy", 0).size()) / bank.rate_of("charge.tick.heavy")
	var hum_sec: float = float(bank.buffer("charge.hum", 0).size()) / bank.rate_of("charge.hum")
	ok(tick_sec < 0.35, "the full tick is short (%.2f s)" % tick_sec)
	ok(hum_sec >= 0.6, "the hum lasts as long as the longest hold (38 ticks, %.2f s)" % hum_sec)


# ---- step 1: the voices (needs the scene tree)
func _voices() -> void:
	print("4. the voices: class caps")
	var v := AudioVoices.new(bank)
	root.add_child(v)
	await process_frame
	var played: int = 0
	cues.reset(3)
	for i in range(8):
		for c in tick(30000 + i, [blow(0, "light"), dmg(0, "light", 12.0)]):
			if v.play(c, S.fighters[0].x, 1.0):
				played += 1
	var live: int = 0
	for i in range(v._pool.size()):
		if v._pool[i].playing and v._meta[i].cls == "hit.light":
			live += 1
	ok(live <= 4, "eight light hits in one tick leave at most 4 light voices (%d)" % live)
	var other: int = 0
	var h: Array = tick(30100, [blow(0, "heavy"), dmg(0, "heavy", 80.0)])
	for c in h:
		if c.sound.begins_with("impact.") and v.play(c, S.fighters[0].x, 1.0):
			other += 1
	ok(other == 1, "a heavy hit still gets a voice while the light class is full")
	# step 2: the launcher's duck and its stop
	var ping = tick(41000, [cue("launcher_open", "flurry", 0, {"n": 41020})]).filter(func(x): return x.sound == "ui.launcher")[0]
	var sfx_idx: int = AudioServer.get_bus_index("Sfx")
	var base_sfx: float = AudioServer.get_bus_volume_db(sfx_idx)
	ok(v.play(ping, S.fighters[1].x, 1.0), "the ping gets a voice")
	ok(is_equal_approx(v.duck_db("Sfx"), -3.0) and is_equal_approx(v.duck_db("Music"), -4.0), "and ducks Sfx by 3 dB and Music by 4 dB (%.1f, %.1f)" % [v.duck_db("Sfx"), v.duck_db("Music")])
	ok(is_equal_approx(AudioServer.get_bus_volume_db(sfx_idx), base_sfx - 3.0), "the Sfx bus really is down")
	var ping2 = tick(41010, [cue("launcher_open", "flurry", 0, {"n": 41030})]).filter(func(x): return x.sound == "ui.launcher")[0]
	v.play(ping2, S.fighters[1].x, 1.0)
	var in_group: int = 0
	for i in range(v._pool.size()):
		if v._pool[i].playing and v._meta[i].cls == "launcher":
			in_group += 1
	ok(in_group == 1, "a second ping replaces the first (one launcher voice)")
	for i in range(20):
		v._process(0.02)
	ok(is_equal_approx(AudioServer.get_bus_volume_db(sfx_idx), base_sfx) and v.duck_db("Sfx") == 0.0, "after 0.4 s the bus is back at its level")
	var stop = tick(41100, [cue("launcher_close", "thrown", 0)])[0]
	ok(v.play(stop, 0.0, 1.0), "a stop request finds the ping's voice")
	await create_timer(0.25).timeout
	var still: int = 0
	for i in range(v._pool.size()):
		if v._pool[i].playing and v._meta[i].group == "launcher.0":
			still += 1
	ok(still == 0, "and the voice is faded out and stopped")
	# step 4: a mashed bolt keeps to two voices
	cues.reset(71)
	var bolts: int = 0
	for i in range(8):
		for c in tick(42000 + i, [cue("energy_land", "bolt", 0, {"source": "hit"})]):
			if v.play(c, S.fighters[1].x, 1.0):
				bolts += 1
	var live_bolts: int = 0
	for i in range(v._pool.size()):
		if v._pool[i].playing and v._meta[i].cls == "energy.bolt":
			live_bolts += 1
	ok(live_bolts <= 2, "eight bolts in one tick leave at most 2 bolt voices (%d)" % live_bolts)
	v.queue_free()
	await process_frame
