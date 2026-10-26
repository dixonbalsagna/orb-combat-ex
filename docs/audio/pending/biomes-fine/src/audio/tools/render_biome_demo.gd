extends SceneTree
## Render dry listening clips (no music underneath) of biome sound, made by the real mappers (AudioCues with AudioWorld, and the
## brawl's own hit sounds) from STAGED events. From the repo root:
##   godot --headless --path . --script res://audio/tools/render_biome_demo.gd [-- --out=DIR]
## Writes, into DIR (default audio/preview/biomes), mono 16-bit at 16 kHz (everything here is under about 2 kHz, and the folder stays small):
##   bed-<biome>-dry.wav        each biome's bed alone (8 s), at the level it has in the game relative to the others
##   surface-<ground>-dry.wav   each ground: steps, a scuff under a blow, a landing slow and hard, a slide, a crater (about 6 s)
##   fight-<biome>-dry.wav      a staged fight in a biome with the set on (the bed under it, ducked by the blows; the ground under each blow near it)
##   fight-<biome>-without-dry.wav   the same fight with the set off, to hear what it adds
## A looped voice (the bed) is rendered by following its updates and stop. The stereo place a cue would have in the game is not
## heard in a mono file. Not a game recording.

const RATE := 16000
var bank: AudioBank
var S: SimState
var cues: AudioCues
var _xs: Dictionary = {}


func _init() -> void:
	var out_dir: String = ProjectSettings.globalize_path("res://audio/preview/biomes")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	bank = AudioBank.new()
	bank.world["enabled"] = true
	S = SimCore.createSim()
	SimCore.newMatch(S, 4)
	for x in range(0, int(SimConst.NC * SimConst.COL), int(SimConst.COL) * 4):
		var b: String = WorldBiomes.biomeAt(float(x))
		if not _xs.has(b):
			_xs[b] = float(x) + 120.0
	_beds(out_dir)
	_surfaces(out_dir)
	for b in ["desert", "ocean", "city", "ice_sheet", "volcanic"]:
		if _xs.has(b) or b in _fine_ids():
			_fight(out_dir, b)
	SimCore.dispose(S)
	quit(0)


func _ev(type: String, extra: Dictionary = {}) -> SimState.FxEvent:
	var e := SimState.FxEvent.new()
	e.type = type
	for k in extra:
		e.set(k, extra[k])
	return e


func _blow(text: String, actor: int, n: int) -> SimState.FxEvent:
	return _ev("cue", {"kind": "blow", "text": text, "actor": float(actor), "target": float(1 - actor), "n": n})


func _dmg(attacker: int, kind: String, amount: float, x: float, y: float) -> SimState.FxEvent:
	return _ev("damage", {"attacker": float(attacker), "victim": float(1 - attacker), "kind": kind, "amount": amount, "region": "core", "x": x, "y": y})


func _place(x: float, up: float) -> void:
	for i in range(2):
		var f = S.fighters[i]
		f.x = x + 90.0 * float(i)
		f.y = WorldTerrain.groundY(S, f.x) + up
		f.vx = 0.0
		f.vy = 0.0
		f.state = "free"


# ---- the beds: one loop each, at the level they have in the game
func _beds(out_dir: String) -> void:
	var made: Dictionary = {}
	var peak: float = 0.0
	var order: Array = ["ocean", "village", "plains", "city", "forest", "desert", "mountains", "ice_sheet", "sea_ice", "jungle", "savanna", "tundra", "taiga", "wetland", "beach", "highland", "volcanic"]
	for b in order:
		if not bank.world.biomes.has(b):
			continue
		var R: Dictionary = bank.world.biomes[b]
		var buf := PackedFloat32Array()
		var n: int = 8 * RATE
		buf.resize(n)
		var src: PackedFloat32Array = bank.buffer("amb." + String(R.bed), 0)
		var rate: int = bank.rate_of("amb." + String(R.bed))
		var g: float = AudioDsp.db_to_lin(float(R.gain_db))
		for i in range(n):
			var p: float = float(i) * float(rate) / float(RATE)
			var k: int = int(p)
			var f: float = p - float(k)
			var a: float = src[k % src.size()]
			var c: float = src[(k + 1) % src.size()]
			buf[i] = (a + (c - a) * f) * g
		peak = maxf(peak, AudioDsp.peak(buf))
		made[b] = buf
	var k: float = AudioDsp.db_to_lin(-6.0) / maxf(peak, 1e-6)
	for b in made:
		var buf: PackedFloat32Array = made[b]
		for i in range(buf.size()):
			buf[i] *= k
		var path: String = "%s/bed-%s-dry.wav" % [out_dir, b]
		print("%s: %.1f s, error %d" % [path, float(buf.size()) / RATE, AudioDsp.to_wav(buf, RATE).save_to_wav(path)])


# ---- the grounds: steps, a scuff, a landing slow and hard, a slide, a crater
func _surfaces(out_dir: String) -> void:
	var made: Dictionary = {}
	var peak: float = 0.0
	for name in ["grass", "sand", "snow", "mud", "water", "rock", "rubble", "paving"]:
		var sf: Dictionary = bank.world.surfaces[name]
		var n: int = int(6.4 * RATE)
		var mix := PackedFloat32Array()
		mix.resize(n)
		# [time s, sound, gain dB, pitch]
		var seq: Array = []
		for i in range(4):                                         # steps
			seq.append([0.2 + 0.42 * float(i), sf.hit, -10.0 + float(sf.gain_db), 1.35 * (1.07 if i % 2 == 0 else 0.93)])
		seq.append([2.1, sf.hit, -6.0 + float(sf.gain_db), 1.0])        # a scuff under a blow
		seq.append([2.8, sf.hit, -9.0 + float(sf.gain_db), 1.1])        # a slow landing
		seq.append([3.4, sf.hit, -2.0 + float(sf.gain_db), 0.82])       # a hard one
		for i in range(3):                                         # a slide
			seq.append([4.1 + 0.1 * float(i), sf.slide, -9.0 + float(sf.gain_db) + 2.0 * float(i), 1.0])
		seq.append([5.1, sf.hit, -4.0 + float(sf.gain_db), 0.72])       # a crater
		for s in seq:
			_mix_one(mix, bank.buffer(String(s[1]), 0), bank.rate_of(String(s[1])), float(s[0]), float(s[3]), float(s[2]))
		peak = maxf(peak, AudioDsp.peak(mix))
		made[name] = mix
	var k: float = AudioDsp.db_to_lin(-3.0) / maxf(peak, 1e-6)
	for name in made:
		var mix: PackedFloat32Array = made[name]
		for i in range(mix.size()):
			mix[i] *= k
		AudioDsp.fade(mix, 0.003, 0.2, RATE)
		var path: String = "%s/surface-%s-dry.wav" % [out_dir, name]
		print("%s: %.1f s, error %d" % [path, float(mix.size()) / RATE, AudioDsp.to_wav(mix, RATE).save_to_wav(path)])


# ---- a staged fight in a biome, with the set on and off
func _fight(out_dir: String, biome: String) -> void:
	var x: float = float(_xs.get(biome, 0.0))
	var on: Array = _fight_mix(x, biome, true)
	var off: Array = _fight_mix(x, biome, false)
	var k: float = AudioDsp.db_to_lin(-3.0) / maxf(maxf(AudioDsp.peak(on[0]), AudioDsp.peak(off[0])), 1e-6)
	for pair in [["fight-%s-dry.wav" % biome, on], ["fight-%s-without-dry.wav" % biome, off]]:
		var mix: PackedFloat32Array = pair[1][0]
		for i in range(mix.size()):
			mix[i] *= k
		AudioDsp.fade(mix, 0.003, 0.4, RATE)
		var path: String = "%s/%s" % [out_dir, pair[0]]
		print("%s: %.1f s, %d cues, error %d" % [path, float(mix.size()) / RATE, pair[1][1], AudioDsp.to_wav(mix, RATE).save_to_wav(path)])


## The fine biomes of planet generation 2 by name (climate.json); a fight in one is staged on the plains of the hand-made world with the fine
## columns set to that biome (WorldBiomes.fineCols, which World's generation 2 planets set) so the clip shows what the set does there.
func _fine_ids() -> Array:
	var out: Array = []
	for f in AudioBank.load_json("res://data/biomes/climate.json").get("fine", []):
		out.append(String(f.name))
	return out


var _keep_cols := PackedByteArray()
var _keep_fine := PackedByteArray()


func _mock_fine(biome: String) -> void:
	var k: int = _fine_ids().find(biome)
	var nc: int = int(SimConst.NC)
	var fc := PackedByteArray()
	fc.resize(nc)
	fc.fill(k)
	var stored := PackedByteArray()
	stored.resize(nc)
	stored.fill(1)
	_keep_cols = WorldBiomes.planetCols
	_keep_fine = WorldBiomes.fineCols
	WorldBiomes.planetCols = stored
	WorldBiomes.fineCols = fc


func _unmock() -> void:
	WorldBiomes.planetCols = _keep_cols
	WorldBiomes.fineCols = _keep_fine


func _fight_mix(x: float, biome: String, with_world: bool) -> Array:
	cues = AudioCues.new(bank)
	cues.world.cfg["enabled"] = with_world
	cues.reset(4)
	var fine: bool = not _xs.has(biome)
	if fine:
		x = float(_xs["plains"]) + 120.0
		_mock_fine(biome)
	var sea: bool = biome == "ocean"
	var g: float = WorldTerrain.groundY(S, x)
	var ws: float = WorldWater.surfaceAt(S, x)
	var low: float = (ws if ws > WorldWater.DRY else g) + 30.0
	var surf: String = cues.world.surface_at(S, x, low)
	var ev_at: Dictionary = {}
	var add := func(t: int, e) -> void:
		if not ev_at.has(t):
			ev_at[t] = []
		ev_at[t].append(e)
	# 12 s: a short walk, three light blows, a medium and a heavy, a landing and a crater, a slide, a flurry up in the air, two heavies down low
	for t in [150, 162, 174]:
		add.call(t, _blow("light", 0, t))
		add.call(t, _dmg(0, "light", 12.0, x, low))
	add.call(240, _blow("medium", 1, 240))
	add.call(240, _dmg(1, "light", 30.0, x, low))
	add.call(280, _blow("heavy", 0, 280))
	add.call(280, _dmg(0, "heavy", 70.0, x, low))
	add.call(284, _ev("land", {"actor": 1.0, "x": x, "y": low, "spd": 1600.0, "surface": "water" if sea else ("soil" if surf in ["grass", "mud", "snow"] else surf), "kind": "slam"}))
	add.call(284, _ev("crater", {"x": x, "y": g, "energy": 4.0, "cause": "impact"}))
	if sea:
		add.call(286, _ev("splash", {"x": x, "y": ws, "n": 30}))
		add.call(330, _ev("skim", {"x": x, "y": ws, "spd": 1500.0, "n": 1}))
		add.call(350, _ev("skim", {"x": x, "y": ws, "spd": 1200.0, "n": 2}))
	else:
		for i in range(8):
			add.call(330 + 2 * i, _ev("slide_dust", {"x": x + 20.0 * float(i), "y": g, "spd": 0.9 - 0.08 * float(i), "variant": "soil", "n": i}))
	for i in range(8):
		var tt: int = 420 + 7 * i
		add.call(tt, _blow("light", 0, tt))
		add.call(tt, _dmg(0, "light", 12.0, x, g + 700.0))
	for t in [600, 640]:
		add.call(t, _blow("heavy", 1, t))
		add.call(t, _dmg(1, "heavy", 80.0, x, low))
	var timeline: Array = []
	var last: int = 780
	_place(x, 30.0 if not sea else 400.0)
	for t in range(0, last + 1):
		S.tick = t
		S.T = float(t) / 60.0
		# a short walk in the first 2 s on land
		for i in range(2):
			S.fighters[i].vx = 300.0 if (not sea and t < 130 and i == 0) else 0.0
			S.fighters[i].y = g + 5.0 if (not sea and t < 130) else (low if not sea else g + 400.0)
		for c in cues.consume(S, ev_at.get(t, [])):
			timeline.append([t, c])
	var total: float = float(last) / 60.0 + 1.2
	var mix := PackedFloat32Array()
	mix.resize(int(total * RATE))
	_mix_timeline(mix, timeline, total)
	if fine:
		_unmock()
	return [mix, timeline.size()]


func _mix_timeline(mix: PackedFloat32Array, timeline: Array, total: float) -> void:
	var loops: Dictionary = {}           # group -> {start, buf, rate, keys: [[t, gain, pitch]], end}
	for entry in timeline:
		var at: float = float(int(entry[0])) / 60.0
		var c = entry[1]
		if c.sound == "" and c.stop_group != "":
			if loops.has(c.stop_group) and loops[c.stop_group].end < 0.0:
				loops[c.stop_group]["end"] = at
				loops[c.stop_group]["fade"] = float(c.fade_ms) * 0.001
			continue
		if c.loop and c.update:
			if loops.has(c.group) and loops[c.group].end < 0.0:
				var L = loops[c.group]
				var cur: Array = _at(L.keys, at)
				L.keys.append([at, cur[0], cur[1]])
				L.keys.append([at + float(c.ramp_ms) * 0.001, c.gain_db, c.pitch])
			continue
		if c.loop:
			loops[c.group] = {"start": at, "buf": bank.buffer(c.sound, c.variant), "rate": bank.rate_of(c.sound), "keys": [[at, c.gain_db, c.pitch]], "end": -1.0, "fade": 0.04}
			continue
		_mix_one(mix, bank.buffer(c.sound, c.variant), bank.rate_of(c.sound), at, c.pitch, c.gain_db)
	for g in loops:
		_mix_loop(mix, loops[g], total)


func _at(keys: Array, t: float) -> Array:
	if t <= float(keys[0][0]):
		return [keys[0][1], keys[0][2]]
	for i in range(1, keys.size()):
		if t <= float(keys[i][0]):
			var a = keys[i - 1]
			var b = keys[i]
			var u: float = (t - float(a[0])) / maxf(float(b[0]) - float(a[0]), 1e-6)
			return [lerpf(float(a[1]), float(b[1]), u), lerpf(float(a[2]), float(b[2]), u)]
	var l = keys[keys.size() - 1]
	return [l[1], l[2]]


func _mix_loop(mix: PackedFloat32Array, L: Dictionary, total: float) -> void:
	var src: PackedFloat32Array = L.buf
	var i0: int = int(float(L.start) * RATE)
	var t_end: float = float(L.end) + float(L.fade) if float(L.end) >= 0.0 else total
	var i1: int = mini(int(t_end * RATE), mix.size())
	var pos: float = 0.0
	for i in range(i0, i1):
		var t: float = float(i) / RATE
		var gp: Array = _at(L.keys, t)
		var g: float = AudioDsp.db_to_lin(float(gp[0]))
		if float(L.end) >= 0.0 and t > float(L.end):
			g *= clampf(1.0 - (t - float(L.end)) / maxf(float(L.fade), 1e-6), 0.0, 1.0)
		pos += float(gp[1]) * float(L.rate) / RATE
		var k: int = int(pos) % src.size()
		var f: float = pos - floorf(pos)
		var a: float = src[k]
		var b: float = src[(k + 1) % src.size()]
		mix[i] += (a + (b - a) * f) * g


func _mix_one(mix: PackedFloat32Array, src: PackedFloat32Array, rate: int, at: float, pitch: float, gain: float) -> void:
	var step: float = pitch * float(rate) / float(RATE)
	var g: float = AudioDsp.db_to_lin(gain)
	var a0: int = int(at * RATE)
	var len: int = int(float(src.size()) / step)
	for j in range(len):
		if a0 + j >= mix.size():
			break
		var p: float = float(j) * step
		var i0: int = int(p)
		var f: float = p - float(i0)
		var a: float = src[i0]
		var b: float = src[i0 + 1] if i0 + 1 < src.size() else 0.0
		mix[a0 + j] += (a + (b - a) * f) * g
