extends SceneTree
## The friends' build sounds (docs/audio/friends-sound.md; audio/audio_scene.gd, AudioVoices.ui, data/scene_cues.json): the new
## sounds render and are not silent or clipped; the wind starts quiet, fades up, keeps moving and stands down when the biome beds
## are on; building events become one cue a kind a tick; a collapse waits for its ripple; the menu call plays; switched off, the
## cues are exactly what they were. Staged events and seeded matches; no sound device. From the repo root:
##   godot --headless --path . --script res://audio/tools/scene_check.gd
## Exit code 1 on a failure.

var bank: AudioBank
var fails: int = 0


class Ev:
	var type: String = ""
	var x: float = 0.0
	var y: float = 0.0
	var h: float = 0.0
	var depth: float = 0.0
	var delay: float = 0.0
	var n: float = 0.0
	var to: float = 0.0
	var outcome: String = ""
	var amount: float = 0.0


func _initialize() -> void:
	bank = AudioBank.new()
	_run.call_deferred()


func ok(cond: bool, msg: String) -> void:
	print("  %s  %s" % ["ok  " if cond else "FAIL", msg])
	if not cond:
		fails += 1


func ev(type: String, x: float, more: Dictionary = {}) -> Ev:
	var e := Ev.new()
	e.type = type
	e.x = x
	for k in more:
		e.set(k, more[k])
	return e


func scene_cues(M: SimState, cm: AudioCues, events: Array) -> Array:
	var out: Array = []
	cm.scene.consume(M, events, out)
	return out


func _run() -> void:
	print("1. the new sounds")
	var ids: Array = []
	for k in bank.scene.sounds:
		ids.append(String(k))
	ids.append("amb.wind")
	var bad: PackedStringArray = PackedStringArray()
	var ms: float = 0.0
	for id in ids:
		for v in range(bank.variants(id)):
			var b: PackedFloat32Array = bank.buffer(id, v)
			bank.stream(id, v)
			ms += float(bank.render_ms.get("%s#%d" % [id, v], 0.0))
			var peak: float = 0.0
			for s in b:
				peak = maxf(peak, absf(s))
			var secs: float = float(b.size()) / bank.rate_of(id)
			if peak < 0.05 or peak > 0.99 or secs <= 0.02 or secs > 12.0:
				bad.append("%s#%d peak %.2f %.2f s" % [id, v, peak, secs])
	ok(bad.is_empty(), "%d sounds render, none silent or clipped (%.0f ms to render) %s" % [ids.size(), ms, ", ".join(bad)])
	ok(bank.ids().has("build.fall") and bank.ids().has("ui.move") and bank.extra_ids().has("amb.wind"), "the warm-up renders them ahead of a match")

	var M := SimCore.createSim()
	SimCore.newMatch(M, 7, {}, {})
	var here: float = M.fighters[0].x

	print("2. the wind")
	var cm := AudioCues.new(bank)
	cm.reset(7)
	ok(cm.scene.wind_enabled(), "the wind is on in the data")
	var first: Array = scene_cues(M, cm, [])
	ok(first.size() == 2 and first[0].loop and first[0].ambient and first[0].gain_db <= -39.0 and first[1].update and first[1].gain_db > -20.0 and first[1].gain_db < 0.0,
		"one loop, started at %.0f dB and faded to %.0f dB" % [first[0].gain_db if first.size() > 0 else 0.0, first[1].gain_db if first.size() > 1 else 0.0])
	var ups: int = 0
	var starts: int = 0
	var quiet_db: float = 0.0
	var loud_db: float = 0.0
	for t in range(600):
		M.tick += 1
		var evs: Array = []
		if t >= 300 and t % 10 == 0:
			evs.append(ev("damage", here, {"amount": 60.0}))
		for c in scene_cues(M, cm, evs):
			if c.group != "wind":
				continue
			if c.update:
				ups += 1
				if t < 300:
					loud_db = c.gain_db
				else:
					quiet_db = c.gain_db
			else:
				starts += 1
	ok(starts == 0 and ups >= 20 and quiet_db < loud_db - 3.0, "it keeps one voice, moves %d times in 10 s, and drops from %.0f to %.0f dB while blows land" % [ups, loud_db, quiet_db])
	cm.world.cfg["enabled"] = true
	ok(not cm.scene.wind_enabled(), "with the biome beds on, the wind stands down")
	cm.world.cfg["enabled"] = false

	print("3. the buildings")
	cm.reset(7)
	cm.scene.cfg.wind["enabled"] = false
	M.tick = 1000
	var burst: Array = []
	for i in range(19):
		burst.append(ev("building_stage", here + 40.0 * i, {"to": 3.0, "h": 120.0}))
	for i in range(5):
		burst.append(ev("building_stage", here + 40.0 * i, {"to": 1.0, "h": 400.0}))
	var cs: Array = scene_cues(M, cm, burst)
	var names: Array = []
	for c in cs:
		names.append(c.sound)
	ok(cs.size() == 2 and names.has("build.crack") and names.has("build.glass"), "24 stage events in one tick make 2 cues: %s" % str(names))
	var again: Array = scene_cues(M, cm, burst)
	ok(again.is_empty(), "the same again the next tick makes none (a short wait for each kind)")
	M.tick += 60
	cs = scene_cues(M, cm, [ev("building_hit", here, {"h": 300.0, "outcome": "punch"}), ev("floor_hit", here, {"outcome": "dent"}), ev("floors_fall", here, {"n": 6.0})])
	names = []
	for c in cs:
		names.append(c.sound)
	ok(cs.size() == 2 and names.has("build.hit") and names.has("build.floors"), "a blow into a building and a stack falling: %s" % str(names))
	M.tick += 60
	var now: Array = scene_cues(M, cm, [ev("building_fall", here, {"depth": 900.0, "delay": 0.5, "n": 1.0})])
	var early: int = 0
	var landed: Array = []
	for t in range(40):
		M.tick += 1
		var got: Array = scene_cues(M, cm, [])
		if got.size() > 0 and t < 28:
			early += 1
		landed.append_array(got)
	ok(now.is_empty() and early == 0 and landed.size() == 1 and landed[0].sound == "build.fall" and landed[0].pitch < 0.95,
		"a tall collapse sounds after its half-second ripple, lower for its height (pitch %.2f)" % (landed[0].pitch if landed.size() > 0 else 0.0))

	print("4. the menu")
	var vo := AudioVoices.new(bank)
	root.add_child(vo)
	await process_frame
	var p0: int = vo.played
	var m_ok: bool = AudioVoices.ui("move") and AudioVoices.ui("confirm") and AudioVoices.ui("back")
	ok(m_ok and vo.played == p0 + 3, "move, confirm and back each take a voice")
	ok(not AudioVoices.ui("enabled") and not AudioVoices.ui("nothing"), "a name that is not a menu sound plays nothing")
	vo.bank.scene.menu["enabled"] = false
	ok(not AudioVoices.ui("move"), "switched off in the data, the call does nothing")
	vo.bank.scene.menu["enabled"] = true
	var lim: int = AudioVoices._effect_index(0, "AudioEffectHardLimiter")
	ok(lim >= 0 and AudioVoices._effect_index(0, "AudioEffectLimiter") == -1, "the master has the look-ahead limiter and not the old one")
	vo.queue_free()
	SimCore.dispose(M)

	print("5. seeded matches")
	var counts: Dictionary = {}
	var per_s_max: int = 0
	var changed: String = ""
	var total: int = 0
	for sd in [301, 303, 305]:
		var A := SimCore.createSim()
		SimCore.newMatch(A, sd, {}, {"power": true, "dash": true})
		var on := AudioCues.new(bank)
		on.reset(sd)
		var off := AudioCues.new(bank)
		off.reset(sd)
		off.scene.cfg.wind["enabled"] = false
		off.scene.cfg.buildings["enabled"] = false
		var window: Array = []
		for t in range(3600):
			SimCore.step(A)
			var a_out: Array = on.consume(A, A.out.fx)
			var b_out: Array = off.consume(A, A.out.fx)
			for c in a_out:
				if c.sound.begins_with("build."):
					counts[c.sound] = int(counts.get(c.sound, 0)) + 1
					window.append(t)
					total += 1
			while not window.is_empty() and window[0] <= t - 60:
				window.pop_front()
			per_s_max = maxi(per_s_max, window.size())
			for c in b_out:
				if c.sound.begins_with("build.") or c.sound == "amb.wind":
					changed = "a scene cue with the switches off"
			A.out.fx.clear()
			A.out.feed.clear()
		SimCore.dispose(A)
	ok(changed == "", "switched off, no wind and no building cue is made %s" % changed)
	ok(per_s_max <= 8, "at most %d building cues in any one second; over 3 minutes of matches: %s" % [per_s_max, str(counts) if total > 0 else "none (no building was touched)"])
	print("\nscene check %s" % ("FAILED (%d)" % fails if fails > 0 else "passed"))
	quit(1 if fails > 0 else 0)
