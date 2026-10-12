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
	_perfect()
	_held_and_grind()
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
	print("1. strength: from the blow cue and the amount (kind_is_strength off), then from the damage kind (on)")
	cues.brawl.cfg.strength.kind_is_strength = false
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
	# C2: the damage kind is the strength
	cues.brawl.cfg.strength.kind_is_strength = true
	cues.reset(12)
	t += 600
	r = tick(t, [blow(0, "light"), dmg(0, "medium", 12.0)])
	ok(_sound_of(r) == ["impact.medium"], "with the strength on the damage event, the kind is the strength (a medium kind, a light blow cue)")
	r = tick(t + 60, [dmg(0, "heavy", 5.0)])
	ok(_sound_of(r) == ["impact.heavy"], "a heavy kind is a heavy whatever the amount")
	r = tick(t + 120, [blow(0, "heavy"), dmg(0, "guard", 10.0)])
	ok(_sound_of(r) == ["impact.guard"] and _pitch_of(r) < 1.0, "a guarded heavy blow is a lower guard")
	r = tick(t + 180, [cue("energy_land", "bolt", 0, {"source": "hit"}), dmg(0, "blast", 20.0)])
	ok(_sound_of(r).is_empty() and r.any(func(c): return c.sound == "energy.bolt"), "the energy blow's own damage (kind blast) is left to energy_land: no impact on top")
	r = tick(t + 240, [dmg(0, "blast", 20.0)])
	ok(not _sound_of(r).is_empty(), "a blast with no energy_land (a shot from afar) keeps the old stand-in")


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
	var lite_run: Array = []
	var N: int = 60
	for trial in range(N):
		cues.reset(100 + trial)
		var base: int = 5000 + trial * 400
		var gains: Array = []
		var pitches: Array = []
		var snd: Array = []
		for i in range(8):
			var ev: Array = [blow(0, "light"), dmg(0, "light", 12.0)]
			if i == 7:
				ev.append(cue("stagger", "flurry", 1, {"target": 0.0, "n": 14.0}))
			var r: Array = tick(base + 6 * i, ev)
			var c = r.filter(func(x): return x.sound.begins_with("impact.light"))[0]
			gains.append(c.gain_db)
			pitches.append(c.pitch)
			snd.append(c.sound)
		g_first += (gains[0] + gains[1] + gains[2]) / 3.0
		g_rest += (gains[3] + gains[4] + gains[5] + gains[6]) / 4.0
		p_first += pitches[0]
		p_last += pitches[6]
		g_seventh += gains[6]
		g_close += gains[7]
		if trial == 0:
			lite_run = snd
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
	ok(lite_run.slice(0, 5) == ["impact.light", "impact.light", "impact.light", "impact.light", "impact.light.lite"] and lite_run[6] == "impact.light.lite" and lite_run[7] == "impact.light", "from the fifth blow in a second the knock is the lite one; the closing blow is the full light again (%s)" % str(lite_run))
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
	for id in ["impact.light", "impact.light.lite", "impact.medium", "impact.heavy", "impact.guard", "impact.whiff"]:
		var buf: PackedFloat32Array = bank.buffer(id, 0)
		var rate: int = bank.rate_of(id)
		info[id] = {"s": float(buf.size()) / rate, "peak": AudioDsp.peak(buf), "rms": AudioDsp.rms(buf)}
		print("     %-14s %.2f s, peak %.1f dBFS, rms %.1f dBFS" % [id, info[id].s, 20.0 * log(info[id].peak) / log(10.0), 20.0 * log(info[id].rms) / log(10.0)])
	ok(info["impact.light"].s < info["impact.medium"].s and info["impact.medium"].s < info["impact.heavy"].s, "light, medium and heavy are told apart by length")
	ok(info["impact.medium"].s > 0.22 and info["impact.medium"].s < 0.4, "the medium is about 0.3 s")
	ok(info["impact.light"].peak < info["impact.medium"].peak and info["impact.medium"].peak < info["impact.heavy"].peak, "and by level")
	ok(info["impact.light.lite"].s < info["impact.light"].s * 0.8 and info["impact.light.lite"].rms < info["impact.light"].rms, "the lite knock is shorter and quieter than the light")
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
	# close (Encounter's C2): used cuts it, lapsed lets it ring
	r = tick(t + 4000, [cue("launcher_close", "used", 0)])
	ok(r.size() == 1 and r[0].sound == "" and r[0].stop_group == "launcher.0" and r[0].fade_ms == 40, "a used launcher (his B thrown) stops the ping (40 ms fade)")
	r = tick(t + 4100, [cue("launcher_close", "lapsed", 0)])
	ok(r.is_empty(), "a lapsed window lets it ring out")
	r = tick(t + 4200, [cue("launcher_close", "", 0, {"k": 1.0})])
	ok(r.is_empty(), "the close says used or lapsed by text only (k means nothing here)")
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
	# the real shape: dur is the wind-up alone, n the landing tick, closing ticks included; the gather waits for the gap
	cues.reset(32)
	r = tk(t + 1000, false, [cue("windup", "start", 0, {"n": t + 1000 + 14, "dur": 12.0, "source": "y"})])
	ok(r.is_empty(), "a Y whose gap needs 2 ticks to close has no gather yet")
	r = tk(t + 1001, false)
	r.append_array(tk(t + 1002, true))
	ok(r.is_empty(), "and a frozen tick (a hit-stop) does not count toward it")
	r = tk(t + 1003, false)
	ok(r.size() == 1 and r[0].sound == "windup.medium" and absf(r[0].pitch - 1.0) < 0.05 and r[0].group == "windup.0", "the gather starts with the wind-up itself, at its own 12 ticks")
	r = tk(t + 1100, false, [cue("windup", "start", 0, {"n": t + 1100 + 16, "dur": 12.0, "source": "y"})])
	r = tk(t + 1101, false, [cue("windup", "end", 0, {"k": 2.0})])
	var late: Array = []
	for i in range(2, 8):
		late.append_array(tk(t + 1100 + i, false))
	ok(late.is_empty(), "a wind-up stopped by a blow before its gap closes never gathers")
	r = tk(t + 1200, false, [cue("windup", "start", 1, {"n": t + 1200 + 14, "dur": 14.0, "source": "b", "k": 1.0})])
	ok(r.size() == 1 and r[0].sound == "windup.medium" and absf(r[0].pitch - 12.0 / 14.0) < 0.02, "a launcher's B (dur 14, thrown in an opening) gathers at once, stretched")
	cues.reset(31)
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


# ---- the heavy's charge: the hum, the full tick, the armour (Encounter's C2 shapes)
func tk(t: int, frozen: bool, events: Array = []) -> Array:
	var te := SimState.FxEvent.new()
	te.type = "tick"
	te.dt = 1.0 / 60.0
	te.frozen = frozen
	return tick(t, [te] + events)


func _charge() -> void:
	print("8. the heavy's charge: hum, full tick, armour (Encounter's C2 shapes)")
	cues.reset(61)
	var t0: int = 70000
	# a held B: start (b, dur 28), a `charge` windup at tick 32, charge_full at 44, the release blow (4 ticks to land), the end
	var r: Array = tk(t0, false, [cue("windup", "start", 1, {"n": t0 + 28, "dur": 28.0, "source": "b"})])
	ok(r.filter(func(c): return c.sound == "windup.heavy").size() == 1 and absf(r[0].pitch - 1.0) < 0.05, "a B's wind-up (dur 28) gathers at once")
	var early: int = 0
	for i in range(1, 32):
		early += tk(t0 + i, false).filter(func(c): return c.sound == "charge.hum").size()
	ok(early == 0, "no hum while it is only winding")
	r = tk(t0 + 32, false, [cue("windup", "charge", 1, {"n": t0 + 44, "source": "b"})])
	var hum: Array = r.filter(func(c): return c.sound == "charge.hum")
	ok(hum.size() == 1 and hum[0].group == "charge.1" and hum[0].cls == "charge", "the `charge` windup starts the hum, in the charger's own group")
	for i in range(33, 44):
		tk(t0 + i, false)
	r = tk(t0 + 44, false, [cue("charge_full", "", 1, {"source": "b"})])
	var ticks: Array = r.filter(func(c): return c.sound == "charge.tick.heavy")
	ok(ticks.size() == 1 and ticks[0].bus == "Alert" and ticks[0].priority >= 90, "charge_full makes one tick on the Alert bus, critical priority")
	ok(ticks[0].variant == 0 and is_equal_approx(ticks[0].pitch, 1.0), "fixed: no variant, no pitch change")
	r = tk(t0 + 45, false, [cue("charge_full", "", 1, {"source": "y"})])
	ok(r.filter(func(c): return c.sound == "charge.tick.heavy").is_empty(), "the Y's full charge (source y) is not in this chain")
	r = tk(t0 + 60, false, [blow(1, "release", t0 + 64)])
	ok(r.size() == 1 and r[0].stop_group == "charge.1" and r[0].sound == "", "the release (a blow cue text release) cuts the hum, 4 ticks before the landing")
	for i in range(61, 64):
		tk(t0 + i, false)
	r = tk(t0 + 64, false, [cue("windup", "end", 1, {"k": 1.0})])
	ok(r.is_empty(), "the landing (end k 1) has nothing left to stop")
	# stopped by a blow while charging: the gather and the hum both go
	cues.reset(62)
	var t1: int = 71000
	tk(t1, false, [cue("windup", "start", 0, {"n": t1 + 28, "dur": 28.0, "source": "b"})])
	tk(t1 + 32, false, [cue("windup", "charge", 0, {"n": t1 + 44, "source": "b"})])
	r = tk(t1 + 36, false, [cue("windup", "end", 0, {"k": 2.0})])
	var stops: Array = r.filter(func(c): return c.sound == "")
	ok(stops.size() == 2 and (stops[0].stop_group == "windup.0" or stops[1].stop_group == "windup.0") and (stops[0].stop_group == "charge.0" or stops[1].stop_group == "charge.0"), "a charge stopped by a blow cuts the gather and the hum")
	# a medium's wind-up is no charge: no hum
	cues.reset(63)
	var t2: int = 72000
	tk(t2, false, [cue("windup", "start", 0, {"n": t2 + 12, "dur": 12.0, "source": "y"})])
	var mh: int = 0
	for i in range(1, 60):
		mh += tk(t2 + i, false).filter(func(c): return c.sound == "charge.hum").size()
	ok(mh == 0, "a medium's 12-tick wind-up has no hum")
	# armour: B (slot 1) is charging; A's blows land on him
	cues.reset(64)
	var t3: int = 73000
	tk(t3, false, [cue("windup", "start", 1, {"n": t3 + 28, "dur": 28.0, "source": "b"})])
	for i in range(1, 6):
		tk(t3 + i, false)
	r = tk(t3 + 6, false, [blow(0, "light"), dmg(0, "light", 12.0)])
	ok(r.filter(func(c): return c.sound == "impact.absorbed").size() == 1 and r.filter(func(c): return c.sound == "impact.light").size() == 1, "a light on a charging B: the hit, and the dull absorbed tick under it")
	r = tk(t3 + 8, false, [blow(0, "medium"), dmg(0, "medium", 35.0)])
	ok(r.filter(func(c): return c.sound == "impact.absorbed").is_empty(), "a medium in the first 20 live ticks ends it: no armour tick")
	for i in range(9, 26):
		tk(t3 + i, false)
	r = tk(t3 + 26, false, [blow(0, "medium"), dmg(0, "medium", 35.0)])
	var ab: Array = r.filter(func(c): return c.sound == "impact.absorbed")
	ok(ab.size() == 1 and ab[0].pitch < 1.0, "a medium after 20 live ticks is absorbed (a lower tick)")
	r = tk(t3 + 27, false, [blow(0, "heavy"), dmg(0, "heavy", 80.0)])
	ok(r.filter(func(c): return c.sound == "impact.absorbed").is_empty(), "a heavy is not absorbed")
	r = tk(t3 + 28, false, [cue("windup", "end", 1, {"k": 2.0})])
	r = tk(t3 + 40, false, [blow(0, "light"), dmg(0, "light", 12.0)])
	ok(r.filter(func(c): return c.sound == "impact.absorbed").is_empty(), "once the charge is over, a light is an ordinary light")
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


# ---- the beat: the perfect follow-up (staged: Encounter's pass 3 names are proposals), the held X, the grind, the Y's charge
func _notes(r: Array, prefix: String) -> Array:
	return r.filter(func(c): return c.sound.begins_with(prefix))


func _perfect() -> void:
	print("9. the perfect follow-up: tick, spark, notes stepping up, the close, a broken chain, the opponent's colour")
	cues.reset(81)
	S.fighters[0].ai = null
	S.fighters[1].ai = null
	var t0: int = 80000
	var r: Array = tick(t0, [cue("window_open", "light", 0, {"k": 1.0, "n": t0 + 12})])
	ok(r.size() == 1 and r[0].sound == "perfect.tick" and r[0].bus == "Alert", "a plain light's pose lets go (k 1): a dry tick")
	r = tick(t0 + 1, [cue("window_open", "medium", 0, {"k": 0.0, "n": t0 + 9})])
	ok(r.is_empty(), "a window that opens on the hit has no sound of its own: the hit is the cue")
	# a chain of three lights: the tap (spark), the follow-up's hit (the note), step by step
	var ratios: Array = [1.0, 1.12246, 1.33484]
	var hit_tick: int = t0 + 20
	for k in range(1, 4):
		var tap: int = t0 + 10 * k + (0 if k == 1 else 0)
		r = tk(tap, false, [cue("perfect", "light", 0, {"k": float(k), "n": hit_tick})])
		r.append_array(tk(tap + 1, false))
		r.append_array(tk(tap + 2, false))
		var sp: Array = _notes(r, "perfect.spark")
		ok(r.size() == 1 and sp.size() == 1 and absf(sp[0].pitch - ratios[k - 1]) < 0.0001 and sp[0].variant == 0, "perfect %d: one spark at the tap, at the chain's note (x%.3f)" % [k, ratios[k - 1]])
		var ev: Array = [blow(0, "light"), dmg(0, "light", 12.0)]
		if k == 3:
			ev.append(cue("launcher_open", "chain", 0, {"n": hit_tick + 12}))
		r = tick(hit_tick, ev)
		if k < 3:
			var nt: Array = _notes(r, "perfect.light")
			ok(nt.size() == 1 and absf(nt[0].pitch - ratios[k - 1]) < 0.0001 and nt[0].priority >= 80 and _sound_of(r) == ["impact.light"], "the follow-up's hit carries note %d on top of its impact" % k)
		else:
			var cl: Array = _notes(r, "perfect.close")
			ok(cl.size() == 1 and absf(cl[0].pitch - 1.0) < 0.0001 and cl[0].priority >= 90 and _notes(r, "perfect.light").is_empty(), "the third resolves: the close, not a third note")
			ok(r.any(func(c): return c.sound == "ui.launcher") and cl[0].bus == "Alert", "with the opening's ping in the same tick, neither ducked by the other (both on Alert)")
		hit_tick += 10
	# a spark never starts on a hit's transient: a tap on the hit waits 2 ticks (30 ms), a tap 6 ticks after does not
	cues.reset(87)
	var t4: int = 84000
	tk(t4, false, [blow(0, "light", t4), dmg(0, "light", 12.0)])
	r = tk(t4, false, [cue("perfect", "light", 0, {"k": 1.0, "n": t4 + 10})])
	ok(_notes(r, "perfect.spark").is_empty(), "a tap on the hit's own tick: no spark yet")
	r = tk(t4 + 1, false)
	ok(_notes(r, "perfect.spark").is_empty(), "...nor a tick later")
	r = tk(t4 + 2, false)
	ok(_notes(r, "perfect.spark").size() == 1, "...it sounds 2 live ticks after the hit, when the transient has passed")
	r = tk(t4 + 8, false, [cue("perfect", "light", 0, {"k": 2.0, "n": t4 + 18})])
	ok(_notes(r, "perfect.spark").size() == 1, "a tap 8 ticks after the hit sounds at once")
	# a link: a perfect medium after a light (the chain jumps two), then a heavy that closes
	cues.reset(82)
	var t1: int = 81000
	r = tick(t1, [cue("perfect", "medium", 0, {"k": 2.0, "n": t1 + 6, "source": "link"})])
	ok(r.size() == 1 and absf(r[0].pitch - 1.12246) < 0.0001, "a link steps two: the spark is already note 2")
	r = tick(t1 + 6, [blow(0, "medium"), dmg(0, "medium", 35.0)])
	ok(_notes(r, "perfect.medium").size() == 1 and _notes(r, "perfect.link").size() == 1, "a medium's colour plus the link's shimmer")
	r = tick(t1 + 12, [cue("perfect", "heavy", 0, {"k": 4.0, "n": t1 + 26, "source": "link"})])
	r = tick(t1 + 26, [blow(0, "heavy"), dmg(0, "heavy", 80.0)])
	var close_link: Array = _notes(r, "perfect.close")
	ok(close_link.size() == 1 and _notes(r, "perfect.link").size() == 1 and _notes(r, "perfect.heavy").is_empty(), "a heavy link that closes the chain is the close with the shimmer (count 4)")
	# a blocked follow-up counts: the guard's sound and the note
	cues.reset(83)
	r = tick(t1 + 100, [cue("perfect", "light", 0, {"k": 1.0, "n": t1 + 110})])
	r = tick(t1 + 110, [blow(0, "light"), dmg(0, "guard", 10.0)])
	ok(_notes(r, "perfect.light").size() == 1 and _sound_of(r) == ["impact.guard"], "a perfect on a blocked hit still has its note")
	# the hit-stop moves the landing a little: the note still finds its hit; a hit long after finds nothing
	cues.reset(84)
	tick(t1 + 200, [cue("perfect", "light", 0, {"k": 1.0, "n": t1 + 210})])
	r = tick(t1 + 216, [blow(0, "light"), dmg(0, "light", 12.0)])
	ok(_notes(r, "perfect.light").size() == 1, "a landing 6 ticks late (a hit-stop between) still carries the note")
	tick(t1 + 300, [cue("perfect", "light", 0, {"k": 1.0, "n": t1 + 310})])
	r = tick(t1 + 340, [blow(0, "light"), dmg(0, "light", 12.0)])
	ok(_notes(r, "perfect.").is_empty(), "an unrelated hit 30 ticks after the follow-up's time gets no note (it never landed)")
	# broken: quiet, not a buzzer; the string goes on
	cues.reset(85)
	var t2: int = 82000
	tick(t2, [cue("perfect", "light", 0, {"k": 1.0, "n": t2 + 10})])
	tick(t2 + 10, [blow(0, "light"), dmg(0, "light", 12.0)])
	r = tick(t2 + 25, [cue("chain_broken", "missed", 0, {"k": 1.0})])
	ok(r.size() == 1 and r[0].sound == "perfect.break" and absf(r[0].pitch - 1.0) < 0.0001, "a missed window: one quiet droop from the last note")
	var br: float = AudioDsp.peak(bank.buffer("perfect.break", 0))
	var lt: float = AudioDsp.peak(bank.buffer("impact.light", 0))
	ok(20.0 * log(br / lt) / log(10.0) < -12.0, "and it is at least 12 dB under a light hit (%.1f dB)" % (20.0 * log(br / lt) / log(10.0)))
	r = tick(t2 + 40, [cue("chain_broken", "lapsed", 0, {"k": 2.0})])
	ok(r.is_empty(), "a chain that lapsed after 90 ticks is silent")
	r = tick(t2 + 41, [cue("chain_broken", "missed", 0, {"k": 0.0})])
	ok(r.is_empty(), "a break with nothing in the chain is silent")
	tick(t2 + 50, [cue("perfect", "light", 0, {"k": 1.0, "n": t2 + 60})])
	tick(t2 + 54, [cue("chain_broken", "stopped", 0, {"k": 1.0})])
	r = tick(t2 + 60, [blow(0, "light"), dmg(0, "light", 12.0)])
	ok(_notes(r, "perfect.").filter(func(c): return c.sound != "perfect.break").is_empty(), "a follow-up stopped in its wind-up never sounds its note")
	# the opponent: the AI's chain against a human has its own colour and an unresolved close
	cues.reset(86)
	S.fighters[0].ai = SimState.AiState.new()
	S.fighters[1].ai = null
	var t3: int = 83000
	r = tick(t3, [cue("window_open", "light", 0, {"k": 1.0, "n": t3 + 12})])
	ok(r.is_empty(), "the opponent's window has no tick (it is not the player's to use)")
	r = tick(t3 + 10, [cue("perfect", "light", 0, {"k": 2.0, "n": t3 + 20})])
	ok(r.size() == 1 and absf(r[0].pitch - 1.18921) < 0.0001, "the opponent's spark steps a minor third, not a major second (an unresolved set)")
	r = tick(t3 + 20, [blow(0, "light"), dmg(0, "light", 12.0)])
	ok(_notes(r, "perfect.foe").size() == 1 and _notes(r, "perfect.light").is_empty(), "its note is the reedy colour")
	tick(t3 + 30, [cue("perfect", "light", 0, {"k": 3.0, "n": t3 + 40})])
	r = tick(t3 + 40, [blow(0, "light"), dmg(0, "light", 12.0)])
	ok(_notes(r, "perfect.foe.close").size() == 1 and _notes(r, "perfect.close").is_empty(), "and its close is the unresolved stack")
	S.fighters[0].ai = null
	# two AIs (a demo) and two humans share the player's colour
	S.fighters[1].ai = SimState.AiState.new()
	S.fighters[0].ai = SimState.AiState.new()
	r = tick(t3 + 100, [cue("perfect", "light", 0, {"k": 1.0, "n": t3 + 110})])
	r = tick(t3 + 110, [blow(0, "light"), dmg(0, "light", 12.0)])
	ok(_notes(r, "perfect.foe").is_empty() and _notes(r, "perfect.light").size() == 1, "two AIs (a demo) use one colour")
	S.fighters[0].ai = null
	S.fighters[1].ai = null
	# levels: no note masks the hit it rides on
	var imp: Dictionary = {"light": "impact.light", "medium": "impact.medium", "heavy": "impact.heavy"}
	for st in ["light", "medium", "heavy"]:
		var pk: float = AudioDsp.peak(bank.buffer("perfect." + st, 0))
		var ik: float = AudioDsp.peak(bank.buffer(imp[st], 0))
		var diff: float = 20.0 * log(ik / pk) / log(10.0)
		print("     perfect.%-7s %.1f dB under %s" % [st, diff, imp[st]])
		ok(diff >= 5.0, "the %s note sits at least 5 dB under a %s hit" % [st, st])
	var cl_pk: float = AudioDsp.peak(bank.buffer("perfect.close", 0))
	ok(20.0 * log(AudioDsp.peak(bank.buffer("impact.light", 0)) / cl_pk) / log(10.0) >= 2.0, "the close is under a light hit even with its +3 dB close")
	for id in ["perfect.spark", "perfect.light", "perfect.medium", "perfect.heavy", "perfect.link", "perfect.close", "perfect.break", "perfect.tick", "perfect.foe", "perfect.foe.close"]:
		var b: PackedFloat32Array = bank.buffer(id, 0)
		ok(AudioDsp.peak(b) < 0.99 and absf(b[b.size() - 1]) < 0.01 and float(b.size()) / bank.rate_of(id) < 0.35, "%s: no clipping, clean end, under 0.35 s (%.3f s)" % [id, float(b.size()) / bank.rate_of(id)])


func _held_and_grind() -> void:
	print("10. the held X settles; the mashed Y grinds; the charged medium; the launcher's rest")
	var t: int = 90000
	var lands: Array = [18, 22, 26, 31, 37, 45, 56]
	var mean_p: Array = []
	var sounds: Array = []
	var SEEDS: int = 24
	for sd in range(SEEDS):
		cues.reset(1000 + sd)
		var tb: int = t + sd * 1000
		var run_p: Array = []
		var run_s: Array = []
		# a held X: the press's own light, burst start (n the first burst blow's landing), then the blows at the burst's gaps
		tick(tb, [blow(0, "light"), dmg(0, "light", 12.0)])
		tick(tb + 16, [cue("burst", "start", 0, {"source": "x", "n": tb + 18})])
		for i in range(lands.size()):
			var at: int = tb + lands[i]
			var r: Array = tick(at, [blow(0, "light", at), dmg(0, "light", 12.0)])
			var c = r.filter(func(x): return x.sound.begins_with("impact.light"))[0]
			run_p.append(c.pitch)
			run_s.append(c.sound)
		# the floor pace: one blow every 10 ticks after the burst's end
		tick(tb + 57, [cue("burst", "end", 0, {"source": "x", "k": 8.0})])
		for i in range(1, 4):
			var at2: int = tb + 56 + 10 * i
			var r2: Array = tick(at2, [blow(0, "light", at2), dmg(0, "light", 12.0)])
			var c2 = r2.filter(func(x): return x.sound.begins_with("impact.light"))[0]
			run_p.append(c2.pitch)
			run_s.append(c2.sound)
		if mean_p.is_empty():
			mean_p = run_p.map(func(_x): return 0.0)
			sounds = run_s
		for i in range(run_p.size()):
			mean_p[i] += run_p[i] / float(SEEDS)
	var pitches: Array = mean_p
	print("     held X, mean pitch by blow over %d seeds: %s" % [SEEDS, str(pitches.map(func(p): return snappedf(p, 0.001)))])
	print("     held X, sound by blow: %s" % str(sounds))
	ok(sounds[0] == "impact.light.lite" and sounds[5] == "impact.light" and sounds[-1] == "impact.light", "the burst starts as the lite rattle and relaxes into the full light as the gap grows")
	ok(pitches[0] > pitches[3] and pitches[3] > pitches[6] and absf(pitches[-1] - pitches[6]) < 0.03, "the pitch falls as it slows and then holds at its floor pace (one move settling)")
	ok(pitches[0] / pitches[6] > 1.10 and pitches[0] / pitches[6] < 1.25, "by about three semitones (%.3f)" % (pitches[0] / pitches[6]))
	# a mash replaces the burst: no settle for the mash's blows
	cues.reset(92)
	tick(t + 500, [cue("burst", "start", 0, {"source": "x", "n": t + 518})])
	tick(t + 510, [cue("burst", "end", 0, {"source": "x", "k": 2.0})])
	var mp: Array = []
	for i in range(8):
		var at3: int = t + 520 + 6 * i
		var r3: Array = tick(at3, [blow(0, "light", at3), dmg(0, "light", 12.0)])
		mp.append(r3.filter(func(x): return x.sound.begins_with("impact.light"))[0].pitch)
	ok(mp[6] > mp[0], "a burst cut short by another press is a mash: it climbs, it does not settle")
	# the mashed Y's grind
	cues.reset(93)
	var base: float = 0.0
	var seq: Array = []
	for i in range(5):
		var at4: int = t + 1000 + 12 * i
		var r4: Array = tick(at4, [blow(0, "medium", at4), dmg(0, "medium", 35.0)])
		var m = r4.filter(func(x): return x.sound.begins_with("impact.medium"))[0]
		seq.append(m)
	ok(seq[0].sound == "impact.medium" and seq[1].sound == "impact.medium.grind" and seq[4].sound == "impact.medium.grind", "from the second medium in 48 ticks each has the grind's churn under it")
	ok(seq[4].pitch < seq[1].pitch and seq[4].gain_db < seq[1].gain_db + 2.0, "it gets heavier, not louder (pitch %.3f to %.3f)" % [seq[1].pitch, seq[4].pitch])
	var rest: Array = tick(t + 2000, [blow(0, "medium", t + 2000), dmg(0, "medium", 35.0)])
	ok(rest.any(func(x): return x.sound == "impact.medium"), "after a pause a medium is a plain medium again")
	# the charged medium: the Y's hum and its brighter tick; the B's are unchanged
	cues.reset(94)
	var t5: int = 95000
	tick(t5, [cue("windup", "start", 0, {"n": t5 + 16, "dur": 16.0, "source": "y"})])
	var r5: Array = tick(t5 + 16, [cue("windup", "charge", 0, {"n": t5 + 24, "source": "y"})])
	var hy: Array = r5.filter(func(c): return c.sound == "charge.hum.y")
	ok(hy.size() == 1 and r5.filter(func(c): return c.sound == "charge.hum").is_empty() and hy[0].group == "charge.0", "the Y's charge is its own, higher hum")
	r5 = tick(t5 + 24, [cue("charge_full", "", 0, {"source": "y"})])
	var ty: Array = r5.filter(func(c): return c.sound == "charge.tick.light")
	ok(ty.size() == 1 and ty[0].bus == "Alert" and ty[0].variant == 0 and is_equal_approx(ty[0].pitch, 1.0), "full: a brighter tick with no ring, fixed")
	var by: Array = tk(t5 + 400, false, [cue("charge_full", "", 1, {"source": "b"})]).filter(func(c): return c.sound == "charge.tick.heavy")
	ok(by.size() == 1, "and the B's tick is still the lower one with the ring")
	r5 = tick(t5 + 30, [blow(0, "release", t5 + 34)])
	ok(r5.size() == 1 and r5[0].stop_group == "charge.0", "the release cuts the Y's hum like the B's")
	var tl: float = AudioDsp.peak(bank.buffer("charge.tick.light", 0))
	print("     charge.tick.light %.3f s, charge.hum.y %.3f s" % [float(bank.buffer("charge.tick.light", 0).size()) / bank.rate_of("charge.tick.light"), float(bank.buffer("charge.hum.y", 0).size()) / bank.rate_of("charge.hum.y")])
	ok(tl < 0.99, "the Y's tick does not clip")
	# the launcher's rest
	cues.reset(95)
	var rr: Array = tick(t5 + 500, [cue("launcher_rest", "flurry", 0, {"target": 1.0})])
	ok(rr.size() == 1 and rr[0].sound == "launcher.rest" and rr[0].bus == "Sfx" and rr[0].duck.is_empty(), "an opening while the launcher rests: a dull knock, no ping, no duck")


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
	var stop = tick(41100, [cue("launcher_close", "used", 0)])[0]
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
	# the beat: a chain of three (a hit every 10 ticks) keeps every spark, note and the close
	cues.reset(96)
	S.fighters[0].ai = null
	S.fighters[1].ai = null
	var chain_cues: Array = []
	var tt: int = 43000
	for k in range(1, 4):
		var tap: int = tt + 10 * (k - 1)
		var hit_at: int = tap + 10
		chain_cues.append_array(tk(tap, false, [cue("perfect", "light", 0, {"k": float(k), "n": hit_at})]))
		chain_cues.append_array(tk(tap + 1, false))
		chain_cues.append_array(tk(tap + 2, false))
		var ev: Array = [blow(0, "light", hit_at), dmg(0, "light", 12.0)]
		if k == 3:
			ev.append(cue("launcher_open", "chain", 0, {"n": hit_at + 12}))
		chain_cues.append_array(tick(hit_at, ev))
	var wanted: int = 0
	var played_c: int = 0
	for c in chain_cues:
		if c.sound.begins_with("perfect.") or c.sound == "ui.launcher":
			wanted += 1
			if v.play(c, S.fighters[0].x, 1.0):
				played_c += 1
		else:
			v.play(c, S.fighters[0].x, 1.0)
	ok(wanted >= 7 and played_c == wanted, "a chain of three: every spark, note, the close and the ping gets a voice (%d of %d)" % [played_c, wanted])
	v.queue_free()
	await process_frame
