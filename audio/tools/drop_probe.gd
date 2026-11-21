extends SceneTree
## Which cues does the voice pool drop, and which does it evict? (docs/audio/drops.md.) A model of AudioVoices.play's decision, run on seeded AI
## matches with the audio data as shipped: the same distance rule (a cue at or beyond mix.space.max_distance from the camera is dropped), the same
## `_take` (a cue's own group, then the class cap, then a free voice, then the weakest voice it outranks), 16 voices (mix.voices), and each voice
## busy for its stream's length over its pitch (a looped voice until its group is stopped), as the web path counts a one-shot. The camera is the
## midpoint of the two fighters. Nothing is played: no sound device is used. From the repo root:
##   godot --headless --path . --script res://audio/tools/drop_probe.gd [-- --seeds=301,302 --ticks=7200 --setup=power,dash --voices=16 --suspend=SECONDS [--hold] --csv=PATH]
## --suspend=60 models the browser holding the sound back for the first 60 s of each match (Orb's 2026-11-07 play): a one-shot started in that time
## stays 'playing' on a frozen context until the second it is released, so the pool fills.
## Prints, per class: cues asked, played, dropped for distance, dropped for no slot, evicted while still sounding (and by whom). Exit 0.

var bank: AudioBank
var mix: Dictionary = {}

var n_voices: int = 16
var meta: Array = []                  # per voice: {priority, group, cls, t, until, loop, sound}
var stat: Dictionary = {}             # cls -> {ask, played, far, slot, evicted, left_sum}
var evict_by: Dictionary = {}         # "victim_cls <- by_cls" -> count
var drop_by_sound: Dictionary = {}    # sound -> count of slot drops
var far_by_sound: Dictionary = {}
var maxd: float = 2600.0
var clock: float = 0.0
var suspend_s: float = 0.0           # >0: the Godot path with a suspended browser context: a one-shot that starts before this second never ends until it
var released: bool = true
var hold: bool = false               # the proposed fix: while the sound is held back, a cue is not taken at all (held), so the pool stays free
var held: int = 0


func _initialize() -> void:
	bank = AudioBank.new()
	mix = AudioBank.load_json("res://audio/data/mix.json")
	_run.call_deferred()


func _row(cls: String) -> Dictionary:
	if not stat.has(cls):
		stat[cls] = {"ask": 0, "played": 0, "far": 0, "slot": 0, "evicted": 0}
	return stat[cls]


func _busy(i: int) -> bool:
	return float(meta[i].until) > clock or (bool(meta[i].loop) and bool(meta[i].alive))


func _take(c) -> int:
	if c.group != "":
		for i in range(n_voices):
			if meta[i].group == c.group and _busy(i):
				return i
	if c.cap > 0 and c.cls != "":
		var oldest: int = -1
		var count: int = 0
		for i in range(n_voices):
			if _busy(i) and meta[i].cls == c.cls:
				count += 1
				if oldest == -1 or float(meta[i].t) < float(meta[oldest].t):
					oldest = i
		if count >= c.cap:
			return oldest if c.priority >= int(meta[oldest].priority) else -1
	var weakest: int = -1
	for i in range(n_voices):
		if not _busy(i):
			return i
		if weakest == -1 or int(meta[i].priority) < int(meta[weakest].priority) or (int(meta[i].priority) == int(meta[weakest].priority) and float(meta[i].t) < float(meta[weakest].t)):
			weakest = i
	if weakest != -1 and c.priority >= int(meta[weakest].priority):
		return weakest
	return -1


func _play(c, cam_x: float) -> void:
	if c.sound == "" and c.stop_group != "":
		for i in range(n_voices):
			if meta[i].group == c.stop_group:
				meta[i].alive = false
				meta[i].until = 0.0
		return
	if c.update:
		return
	if hold and clock < suspend_s and not c.loop:
		held += 1
		return
	var r: Dictionary = _row(String(c.cls) if c.cls != "" else "(none) " + String(c.sound).get_slice(".", 0))
	r.ask += 1
	var dx: float = 0.0 if c.ambient else SimWrap.sdx(cam_x, c.x)
	if absf(dx) >= maxd:
		r.far += 1
		far_by_sound[c.sound] = int(far_by_sound.get(c.sound, 0)) + 1
		return
	var slot: int = _take(c)
	if slot < 0:
		r.slot += 1
		drop_by_sound[c.sound] = int(drop_by_sound.get(c.sound, 0)) + 1
		return
	if _busy(slot) and meta[slot].group != c.group:
		var vr: Dictionary = _row(String(meta[slot].cls) if meta[slot].cls != "" else "(none) " + String(meta[slot].sound).get_slice(".", 0))
		vr.evicted += 1
		var key: String = "%s (prio %d) <- %s (prio %d)" % [meta[slot].cls if meta[slot].cls != "" else meta[slot].sound, int(meta[slot].priority), c.cls if c.cls != "" else c.sound, c.priority]
		evict_by[key] = int(evict_by.get(key, 0)) + 1
	var len: float = 0.0
	var meta_len: float = 0.0
	if c.loop:
		len = 1.0e9
	else:
		len = bank.stream(c.sound, c.variant).get_length() / maxf(c.pitch, 0.1)
		if clock < suspend_s:
			meta_len = len
			len = 1.0e9
	meta[slot] = {"priority": c.priority, "group": c.group, "cls": c.cls, "t": clock, "until": clock + len, "loop": c.loop, "alive": true, "sound": c.sound, "len": meta_len}
	r.played += 1


func _run() -> void:
	var seeds: Array = [301, 302, 303, 304, 305, 306]
	var ticks: int = 7200
	var setup: Dictionary = {}
	var csv: String = ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = []
			for s in a.substr(8).split(","):
				seeds.append(int(s))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a.begins_with("--voices="):
			n_voices = int(a.substr(9))
		elif a == "--hold":
			hold = true
		elif a.begins_with("--suspend="):
			suspend_s = float(a.substr(10))
		elif a.begins_with("--csv="):
			csv = a.substr(6)
		elif a.begins_with("--setup="):
			for w in a.substr(8).split(","):
				if w != "":
					setup[w] = true
	maxd = float(mix.space.max_distance)
	var total_ticks: int = 0
	for sd in seeds:
		meta.clear()
		released = suspend_s <= 0.0
		for i in range(n_voices):
			meta.append({"priority": -1, "group": "", "cls": "", "t": -1.0, "until": 0.0, "loop": false, "alive": false, "sound": "", "len": 0.0})
		var M := SimCore.createSim()
		SimCore.newMatch(M, int(sd), {}, setup)
		var cm := AudioCues.new(bank)
		cm.reset(int(sd))
		var t: int = 0
		while t < ticks and not (M.game.ko != null and M.game.koT > 3.0):
			SimCore.step(M)
			clock = float(t) / 60.0
			if suspend_s > 0.0 and clock >= suspend_s and not released:
				released = true
				for i in range(n_voices):
					if float(meta[i].until) >= 1.0e8 and not bool(meta[i].loop):
						meta[i].until = clock + float(meta[i].len)
			var f0 = M.fighters[0]
			var f1 = M.fighters[1]
			var cam_x: float = f0.x + SimWrap.sdx(f0.x, f1.x) * 0.5
			for c in cm.consume(M, M.out.fx):
				_play(c, cam_x)
			M.out.fx.clear()
			M.out.feed.clear()
			t += 1
		total_ticks += t
		SimCore.dispose(M)
	print("drop probe: seeds %s, %d ticks (%.0f s), %d voices, setup %s" % [str(seeds), total_ticks, total_ticks / 60.0, n_voices, str(setup)])
	var ask: int = 0
	var played: int = 0
	var far: int = 0
	var slot: int = 0
	var rows: Array = []
	for k in stat:
		var r: Dictionary = stat[k]
		ask += r.ask
		played += r.played
		far += r.far
		slot += r.slot
		rows.append([k, r])
	rows.sort_custom(func(a, b): return int(a[1].far) + int(a[1].slot) > int(b[1].far) + int(b[1].slot))
	if hold:
		print("held while the sound was blocked (not taken, not counted as dropped): %d" % held)
	print("TOTAL asked %d played %d dropped for distance %d, dropped for no slot %d (%.1f%% dropped)" % [ask, played, far, slot, 100.0 * float(far + slot) / maxf(float(ask), 1.0)])
	print("%-26s %6s %6s %6s %6s %8s" % ["class", "asked", "played", "far", "noslot", "evicted"])
	for row in rows:
		var r: Dictionary = row[1]
		print("%-26s %6d %6d %6d %6d %8d" % [row[0], r.ask, r.played, r.far, r.slot, r.evicted])
	print("-- evictions of a voice still sounding (victim <- taker):")
	var ek: Array = evict_by.keys()
	ek.sort_custom(func(a, b): return int(evict_by[a]) > int(evict_by[b]))
	for k in ek.slice(0, 14):
		print("  %5d  %s" % [int(evict_by[k]), k])
	print("-- no-slot drops by sound:")
	var dk: Array = drop_by_sound.keys()
	dk.sort_custom(func(a, b): return int(drop_by_sound[a]) > int(drop_by_sound[b]))
	for k in dk.slice(0, 14):
		print("  %5d  %s" % [int(drop_by_sound[k]), k])
	print("-- distance drops by sound:")
	var fk: Array = far_by_sound.keys()
	fk.sort_custom(func(a, b): return int(far_by_sound[a]) > int(far_by_sound[b]))
	for k in fk.slice(0, 10):
		print("  %5d  %s" % [int(far_by_sound[k]), k])
	quit(0)
