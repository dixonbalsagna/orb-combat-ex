extends SceneTree
## Does biome sound behave? Stages the events the sim sends (damage, land, bounce, slide_dust, skim, splash, crater) and the
## fighters' places, feeds them to AudioCues, and checks: the bed (its start, its crossfade and the hold before it, the fight's duck,
## altitude), the surface (by biome, water, rubble; the layer under a blow near the ground, a landing, a bounce, a slide, a skim, a
## splash, a crater, a step), that the set is parked and silent when `enabled` is false, that the beds loop without a seam, that the
## heard spectrum of every new sound is low (the same measure as tone_check), that the ambient voice plays at the listener and
## crossfades through AudioVoices, and that three real seeded matches with the set on leave the sim's hash unchanged and give the
## same cue log twice. The set is parked behind data/world_cues.json "enabled"; the test switches it on in memory only. From the repo root:
##   godot --headless --path . --script res://audio/tools/world_check.gd [-- --ticks=3600]
## Exit code 1 on any failure. No sound device is used (the dummy audio driver).

const TC = preload("res://audio/tools/tone_check.gd")
const N: int = 2048
const BANDS: Array = [250.0, 1000.0, 2000.0, 4000.0]
## id: [max heard centroid Hz, max heard share over 2 kHz (0-1)]; set from the sounds as built, with room. A bed is measured over eight
## windows of the loop, a one-shot at its loudest 128 ms.
const LIMITS: Dictionary = {
	"amb.surf": [520.0, 0.03], "amb.village": [450.0, 0.03], "amb.plains": [480.0, 0.03], "amb.city": [320.0, 0.03], "amb.forest": [500.0, 0.03],
	"amb.desert": [550.0, 0.03], "amb.mountains": [380.0, 0.03], "amb.tundra": [360.0, 0.03], "amb.marsh": [400.0, 0.03], "amb.jungle": [520.0, 0.03],
	"surf.sand.hit": [680.0, 0.04], "surf.sand.slide": [780.0, 0.04], "surf.snow.hit": [480.0, 0.04], "surf.snow.slide": [650.0, 0.04],
	"surf.mud.hit": [480.0, 0.04], "surf.mud.slide": [480.0, 0.04], "surf.water.hit": [720.0, 0.04], "surf.water.slide": [750.0, 0.04],
	"surf.rock.hit": [430.0, 0.04], "surf.rock.slide": [760.0, 0.04], "surf.grass.hit": [680.0, 0.04], "surf.grass.slide": [780.0, 0.04],
	"surf.rubble.hit": [340.0, 0.04], "surf.rubble.slide": [460.0, 0.04], "surf.paving.hit": [700.0, 0.04], "surf.paving.slide": [880.0, 0.04],
}

var bank: AudioBank
var cues: AudioCues
var S: SimState
var fails: int = 0
var max_ticks: int = 3600
var _xs: Dictionary = {}          # biome id -> an x in it (the scratch match's world)


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ticks="):
			max_ticks = int(a.substr(8))
	bank = AudioBank.new()
	cues = AudioCues.new(bank)
	_run.call_deferred()


func ok(cond: bool, msg: String) -> void:
	print("  %s  %s" % ["ok  " if cond else "FAIL", msg])
	if not cond:
		fails += 1


func ev(type: String, extra: Dictionary = {}) -> SimState.FxEvent:
	var e := SimState.FxEvent.new()
	e.type = type
	for k in extra:
		e.set(k, extra[k])
	return e


## Set the sim's tick and time, feed the events, return the cues.
func tick(t: int, events: Array) -> Array:
	S.tick = t
	S.T = float(t) / 60.0
	return cues.consume(S, events)


func world_cues(list: Array) -> Array:
	return list.filter(func(c): return c.sound.begins_with("amb.") or c.sound.begins_with("surf.") or c.stop_group.begins_with("amb."))


func with_sound(list: Array, prefix: String) -> Array:
	return list.filter(func(c): return c.sound.begins_with(prefix))


## Put both fighters at x, on the ground (or `up` units above it), still.
func place(x: float, up: float = 5.0, vx: float = 0.0) -> void:
	for i in range(2):
		var f = S.fighters[i]
		f.x = x + 40.0 * float(i)
		f.y = WorldTerrain.groundY(S, f.x) + up
		f.vx = vx
		f.vy = 0.0
		f.state = "free"


func _run() -> void:
	S = SimCore.createSim()
	SimCore.newMatch(S, 4)
	for x in range(0, int(SimConst.NC * SimConst.COL), int(SimConst.COL) * 8):
		var b: String = WorldBiomes.biomeAt(float(x))
		if not _xs.has(b):
			_xs[b] = float(x)
	print("the scratch world has: %s" % ", ".join(PackedStringArray(_xs.keys())))
	_parked()
	cues.world.cfg["enabled"] = true
	_bed()
	_surface()
	_events()
	_steps()
	_sounds()
	await _voices()
	_matches()
	SimCore.dispose(S)
	print("\nworld check %s" % ("FAILED (%d)" % fails if fails > 0 else "passed"))
	quit(1 if fails > 0 else 0)


func _parked() -> void:
	print("1. parked: with `enabled` false nothing is made")
	cues.reset(5)
	place(float(_xs.values()[0]), 5.0, 300.0)
	var t: int = 300000
	var n: int = 0
	for e in [ev("damage", {"x": S.fighters[0].x, "y": S.fighters[0].y, "amount": 60.0}), ev("land", {"x": S.fighters[0].x, "y": S.fighters[0].y, "spd": 1500.0, "surface": "sand"}), ev("crater", {"x": S.fighters[0].x, "y": S.fighters[0].y, "energy": 3.0})]:
		n += world_cues(tick(t, [e])).size()
		t += 60
	for i in range(400):
		n += world_cues(tick(t + i, [])).size()
	ok(n == 0 and not cues.world.enabled(), "no bed, no surface, no step (%d), and the switch is off in the data" % n)


func _bed() -> void:
	print("2. the bed: start, level, crossfade, the hold, the fight's duck, height")
	cues.reset(6)
	var biomes: Array = _xs.keys()
	var a: String = "desert" if _xs.has("desert") else String(biomes[0])
	var b: String = "mountains" if _xs.has("mountains") and a != "mountains" else String(biomes[1])
	place(float(_xs[a]) + 100.0, 400.0)
	var t: int = 310000
	var r: Array = tick(t, [])
	var start: Array = r.filter(func(c): return c.sound.begins_with("amb.") and not c.update)
	var upd: Array = r.filter(func(c): return c.update)
	var bed_a: String = String(cues.world.cfg.biomes[a].bed)
	ok(start.size() == 1 and start[0].sound == "amb." + bed_a and start[0].loop and start[0].ambient and start[0].group == "amb.a" and start[0].bus == "Ambience", "the first tick starts the bed of the biome (%s): looped, ambient, in group amb.a, on the Ambience bus" % a)
	ok(absf(start[0].gain_db - float(cues.world.cfg.bed.start_db)) < 0.001 and upd.size() == 1 and upd[0].ramp_ms == int(cues.world.cfg.bed.fade_ms) and upd[0].gain_db > start[0].gain_db + 20.0, "it starts low and the same tick's update brings it up over the fade (%d ms, to %.1f dB)" % [upd[0].ramp_ms, upd[0].gain_db])
	var base_db: float = upd[0].gain_db
	# updates every update_every ticks, nothing else
	var ups: int = 0
	var restarts: int = 0
	for i in range(1, 91):
		for c in world_cues(tick(t + i, [])):
			if c.update:
				ups += 1
			else:
				restarts += 1
	ok(ups == 0 and restarts == 0, "then nothing while nothing changes (%d updates, %d restarts in 90 ticks)" % [ups, restarts])
	# the duck: a fight's blows lower it, silence lets it back
	t += 100
	var duck: float = 0.0
	for i in range(40):
		var hits: Array = [ev("damage", {"x": S.fighters[0].x, "y": S.fighters[0].y + 900.0, "amount": 80.0})] if i < 10 else []
		for c in tick(t + i, hits):
			if c.update:
				duck = c.gain_db
	ok(duck < base_db - 4.0 and duck >= base_db + float(cues.world.cfg.intensity.duck_db) - 0.01, "ten hard blows duck the bed (%.1f dB against %.1f, never more than %.0f dB down)" % [duck, base_db, -float(cues.world.cfg.intensity.duck_db)])
	t += 40
	var back: float = duck
	for i in range(0, 700):
		for c in tick(t + i, []):
			if c.update:
				back = c.gain_db
	ok(absf(back - base_db) < 1.0, "ten quiet seconds later it is back (%.1f dB against %.1f; an update goes only when the level has moved half a dB)" % [back, base_db])
	t += 700
	# height: up in the air the wind is louder (or the sea quieter), by the biome's own number
	place(float(_xs[a]) + 100.0, 2000.0)
	var hi: float = 0.0
	for i in range(0, 20):
		for c in tick(t + i, []):
			if c.update:
				hi = c.gain_db
	var want: float = float(cues.world.cfg.biomes[a].gain_db) + float(cues.world.cfg.biomes[a].alt_db)
	ok(absf(hi - want) < 0.5, "high above the ground (a full %.0f units) the %s bed is %+.0f dB over its level (%.1f, wanted %.1f)" % [float(cues.world.cfg.bed.alt_ref), a, float(cues.world.cfg.biomes[a].alt_db), hi, want])
	t += 20
	# crossing a border: held for hold_ticks before it changes, and not at all if they come back
	place(float(_xs[b]) + 100.0, 400.0)
	var hold: int = int(cues.world.cfg.bed.hold_ticks)
	var changed: int = -1
	var stop_seen: bool = false
	for i in range(0, hold + 30):
		var made: Array = tick(t + i, [])
		if not made.filter(func(c): return c.sound.begins_with("amb.") and not c.update).is_empty() and changed < 0:
			changed = i
			stop_seen = not made.filter(func(c): return c.stop_group == "amb.a" and c.fade_ms == int(cues.world.cfg.bed.fade_ms)).is_empty()
	ok(changed == hold - 1, "they stay in %s: the bed changes after %d ticks (tick %d)" % [b, hold, changed + 1])
	ok(stop_seen, "the old bed is stopped with the fade in the same tick, and the new one is in the other group")
	t += hold + 30
	# a short visit changes nothing
	cues.reset(6)
	place(float(_xs[a]) + 100.0, 400.0)
	t = 330000
	tick(t, [])
	place(float(_xs[b]) + 100.0, 400.0)
	var flips: int = 0
	for i in range(1, hold - 20):
		flips += with_sound(tick(t + i, []), "amb.").filter(func(c): return not c.update).size()
	place(float(_xs[a]) + 100.0, 400.0)
	for i in range(hold - 20, hold * 3):
		flips += with_sound(tick(t + i, []), "amb.").filter(func(c): return not c.update).size()
	ok(flips == 0, "a short visit to the next biome (%d ticks) does not change the bed" % (hold - 20))


func _surface() -> void:
	print("3. the surface at a place")
	cues.reset(7)
	var want: Dictionary = {"desert": "sand", "mountains": "rock", "plains": "grass", "forest": "mud", "city": "paving"}
	for b in want:
		if not _xs.has(b):
			continue
		var x: float = float(_xs[b]) + 40.0
		var got: String = cues.world.surface_at(S, x, WorldTerrain.groundY(S, x) + 5.0)
		ok(got == want[b], "%s: %s (wanted %s)" % [b, got, want[b]])
	# standing water wins, and a rubble heap beats the biome
	var xs: float = float(_xs.get("ocean", 100.0))
	var ws: float = WorldWater.surfaceAt(S, xs)
	if ws > WorldWater.DRY:
		ok(cues.world.surface_at(S, xs, ws - 10.0) == "water", "in the ocean, at the water: water")
		ok(cues.world.surface_at(S, xs, ws + 400.0) != "water", "and well above it: not water")
	else:
		print("  (no standing water in this world at x %.0f: the water case is not run)" % xs)
	var xr: float = float(_xs.get("plains", _xs.values()[0])) + 80.0
	var col: int = int(floor(SimWrap.wrap(xr) / SimConst.COL))
	var keep: float = S.rubble[col]
	S.rubble[col] = 500.0
	ok(cues.world.surface_at(S, xr, WorldTerrain.groundY(S, xr) + 5.0) == "rubble", "a rubble heap on the ground: rubble")
	S.rubble[col] = keep


func _events() -> void:
	print("4. blows, landings, slides, skims, splashes and craters")
	cues.reset(8)
	var b: String = "desert" if _xs.has("desert") else String(_xs.keys()[0])
	var x: float = float(_xs[b]) + 60.0
	var g: float = WorldTerrain.groundY(S, x)
	var t: int = 340000
	var surf_of_b: String = cues.world.surface_at(S, x, g + 5.0)
	var hit_id: String = String(cues.world.cfg.surfaces[surf_of_b].hit)
	# a blow near the ground has a scuff of the ground under it; high up, or small, none
	var r: Array = tick(t, [ev("damage", {"x": x, "y": g + 30.0, "amount": 60.0})])
	var sc: Array = with_sound(r, "surf.")
	ok(sc.size() == 1 and sc[0].sound == hit_id and sc[0].bus == "Sfx" and sc[0].cls == "surf.hit", "a blow 30 units off the %s ground has its scuff, %s" % [surf_of_b, hit_id])
	r = tick(t + 10, [ev("damage", {"x": x, "y": g + 600.0, "amount": 60.0})])
	ok(with_sound(r, "surf.").is_empty(), "a blow 600 units up has none")
	r = tick(t + 20, [ev("damage", {"x": x, "y": g + 30.0, "amount": 3.0})])
	ok(with_sound(r, "surf.").is_empty(), "a tap too small has none")
	var small: Array = with_sound(tick(t + 30, [ev("damage", {"x": x, "y": g + 30.0, "amount": 10.0})]), "surf.")
	var big: Array = with_sound(tick(t + 40, [ev("damage", {"x": x, "y": g + 30.0, "amount": 120.0})]), "surf.")
	ok(small.size() == 1 and big.size() == 1 and big[0].gain_db > small[0].gain_db + 2.0 and big[0].pitch < small[0].pitch, "a big blow's scuff is louder and lower than a small one's (%.1f dB x%.2f against %.1f dB x%.2f)" % [big[0].gain_db, big[0].pitch, small[0].gain_db, small[0].pitch])
	# a landing: the sim's own surface class, sized by speed
	r = tick(t + 50, [ev("land", {"x": x, "y": g, "spd": 1500.0, "surface": "rock", "kind": "slam"})])
	var l1: Array = with_sound(r, "surf.")
	ok(l1.size() == 1 and l1[0].sound == "surf.rock.hit" and l1[0].cls == "surf.land", "a landing on rock plays the rock's hit")
	r = tick(t + 60, [ev("land", {"x": x, "y": g, "spd": 600.0, "surface": "rock", "kind": "skid"})])
	var l2: Array = with_sound(r, "surf.")
	ok(l2.size() == 1 and l2[0].gain_db < l1[0].gain_db - 3.0 and l2[0].pitch > l1[0].pitch, "a slow one is quieter and higher (%.1f dB x%.2f against %.1f dB x%.2f)" % [l2[0].gain_db, l2[0].pitch, l1[0].gain_db, l1[0].pitch])
	ok(with_sound(tick(t + 70, [ev("land", {"x": x, "y": g, "spd": 100.0, "surface": "rock"})]), "surf.").is_empty(), "a touch (100 a second) is silent")
	for pair in [["plains", "surf.grass.hit"], ["forest", "surf.mud.hit"]]:
		if _xs.has(pair[0]):
			var xs: float = float(_xs[pair[0]]) + 40.0
			r = tick(t + 80, [ev("land", {"x": xs, "y": WorldTerrain.groundY(S, xs), "spd": 1500.0, "surface": "soil"})])
			ok(with_sound(r, "surf.").size() == 1 and with_sound(r, "surf.")[0].sound == pair[1], "soil in %s is made of its own ground (%s)" % [pair[0], pair[1]])
		t += 5
	r = tick(t + 90, [ev("bounce", {"x": x, "y": g, "spd": 1500.0, "surface": "sand"})])
	var bn: Array = with_sound(r, "surf.")
	ok(bn.size() == 1 and bn[0].sound == "surf.sand.hit" and bn[0].gain_db < l1[0].gain_db, "a bounce on sand is a softer sand hit")
	# a slide: every third sample, the surface's drag
	var slides: int = 0
	for i in range(9):
		slides += with_sound(tick(t + 100 + i, [ev("slide_dust", {"x": x, "y": g, "spd": 0.8, "variant": "soil", "n": i})]), "surf.").size()
	ok(slides == 3, "nine samples along a slide give three drags (%d)" % slides)
	var sl: Array = with_sound(tick(t + 120, [ev("slide_dust", {"x": x, "y": g, "spd": 0.8, "variant": "soil", "n": 0})]), "surf.")
	ok(sl.size() == 1 and sl[0].sound.ends_with(".slide"), "a drag is the surface's slide sound (%s)" % sl[0].sound)
	# water: a skim and a splash
	r = tick(t + 130, [ev("skim", {"x": x, "y": 0.0, "spd": 1500.0, "n": 1})])
	ok(with_sound(r, "surf.").size() == 1 and with_sound(r, "surf.")[0].sound == "surf.water.hit", "a skip off the water is the water's hit")
	var sp1: Array = with_sound(tick(t + 140, [ev("splash", {"x": x, "y": 0.0, "n": 6})]), "surf.")
	var sp2: Array = with_sound(tick(t + 150, [ev("splash", {"x": x, "y": 0.0, "n": 40})]), "surf.")
	ok(sp1.size() == 1 and sp2.size() == 1 and sp2[0].gain_db > sp1[0].gain_db + 3.0, "a big splash is louder than a small one (%.1f dB against %.1f dB)" % [sp2[0].gain_db, sp1[0].gain_db])
	# a crater: a layer of the ground under the impact's crash, sized by energy
	var c1: Array = with_sound(tick(t + 160, [ev("crater", {"x": x, "y": g, "energy": 2.6, "cause": "impact"})]), "surf.")
	var c2: Array = with_sound(tick(t + 170, [ev("crater", {"x": x, "y": g, "energy": 9.0, "cause": "impact"})]), "surf.")
	ok(c1.size() == 1 and c2.size() == 1 and c2[0].gain_db > c1[0].gain_db + 2.0 and c2[0].pitch < c1[0].pitch, "a bigger crater's layer is louder and lower (%.1f dB x%.2f against %.1f dB x%.2f)" % [c2[0].gain_db, c2[0].pitch, c1[0].gain_db, c1[0].pitch])
	ok(with_sound(tick(t + 180, [ev("crater", {"x": x, "y": g, "energy": 0.1, "cause": "impact"})]), "surf.").is_empty(), "a scratch of a crater (0.1) has none")
	# determinism
	var d1: String = _digest()
	var d2: String = _digest()
	ok(d1 == d2, "the same seed gives the same layers twice")


func _digest() -> String:
	cues.reset(21)
	var x: float = float(_xs.values()[0]) + 60.0
	var g: float = WorldTerrain.groundY(S, x)
	var lines := PackedStringArray()
	for i in range(30):
		var e = [ev("damage", {"x": x, "y": g + 20.0, "amount": 20.0 + 3.0 * float(i)}), ev("land", {"x": x, "y": g, "spd": 400.0 + 40.0 * float(i), "surface": "soil"}), ev("crater", {"x": x, "y": g, "energy": 1.0 + float(i)})]
		for c in tick(350000 + i * 7, [e[i % 3]]):
			lines.append("%d|%s|%d|%.3f|%.4f" % [i, c.sound, c.variant, c.gain_db, c.pitch])
	return "\n".join(lines).sha256_text().substr(0, 16)


func _steps() -> void:
	print("5. footfall")
	cues.reset(9)
	var b: String = "desert" if _xs.has("desert") else String(_xs.keys()[0])
	place(float(_xs[b]) + 60.0, 5.0, 300.0)
	var t: int = 360000
	var n_slow: int = 0
	for i in range(240):
		S.fighters[0].vx = 120.0
		S.fighters[1].vx = 0.0
		n_slow += with_sound(tick(t + i, []), "surf.").filter(func(c): return c.cls == "surf.step").size()
	var n_fast: int = 0
	cues.reset(9)
	for i in range(240):
		S.fighters[0].vx = 600.0
		S.fighters[1].vx = 0.0
		n_fast += with_sound(tick(t + 1000 + i, []), "surf.").filter(func(c): return c.cls == "surf.step").size()
	ok(n_slow >= 6 and n_fast > n_slow + 3, "a fighter walking on the ground steps: %d steps in 4 s slowly, %d fast; the one standing still makes none" % [n_slow, n_fast])
	place(float(_xs[b]) + 60.0, 400.0, 600.0)
	var n_air: int = 0
	for i in range(120):
		S.fighters[0].vx = 600.0
		n_air += with_sound(tick(t + 2000 + i, []), "surf.").filter(func(c): return c.cls == "surf.step").size()
	ok(n_air == 0, "in the air there are none (%d)" % n_air)
	place(float(_xs[b]) + 60.0, 5.0, 600.0)
	var steps: Array = []
	for i in range(120):
		S.fighters[0].vx = 600.0
		S.fighters[1].vx = 0.0
		steps.append_array(with_sound(tick(t + 3000 + i, []), "surf."))
	ok(steps.size() >= 2 and steps[0].gain_db < -8.0 and steps[0].pitch > 1.1 and not (steps[0].pitch == steps[1].pitch), "a step is quiet and high, and the feet alternate (x%.2f, x%.2f)" % [steps[0].pitch, steps[1].pitch])


func _sounds() -> void:
	print("6. the sounds: render, loop, and how they are heard")
	var ids: Array = []
	for k in bank.world.beds:
		ids.append("amb." + k)
	for k in bank.world.sounds:
		ids.append(k)
	var worst: float = 0.0
	for id in ids:
		var buf: PackedFloat32Array = bank.buffer(id, 0)
		var finite: bool = true
		for v in buf:
			if is_nan(v) or is_inf(v):
				finite = false
				break
		ok(finite and AudioDsp.peak(buf) < 0.99 and buf.size() > 100, "%s renders clean (%.2f s, peak %.2f)" % [id, float(buf.size()) / bank.rate_of(id), AudioDsp.peak(buf)])
		if id.begins_with("amb."):
			var step: float = 0.0
			for i in range(1, buf.size()):
				step += absf(buf[i] - buf[i - 1])
			step /= float(buf.size() - 1)
			ok(absf(buf[0] - buf[buf.size() - 1]) <= 5.0 * step + 1e-5, "%s loops without a seam (jump %.5f, mean step %.5f)" % [id, absf(buf[0] - buf[buf.size() - 1]), step])
		var r: Array = _spec(id)
		var s: Array = r[1]
		print("%-18s %6.0f Hz heard   %5.1f | %5.1f | %5.1f | %5.1f | %5.1f   (under 250 | 250-1k | 1-2k | 2-4k | over 4k)" % [id, r[0], s[0] * 100, s[1] * 100, s[2] * 100, s[3] * 100, s[4] * 100])
		if LIMITS.has(id):
			var lim: Array = LIMITS[id]
			var over2k: float = s[3] + s[4]
			ok(r[0] <= float(lim[0]) and over2k <= float(lim[1]), "%s is low: centroid %.0f Hz (limit %.0f), %.1f%% over 2 kHz (limit %.0f%%)" % [id, r[0], float(lim[0]), over2k * 100.0, float(lim[1]) * 100.0])
		else:
			ok(false, "%s has no limit in LIMITS" % id)
		worst = maxf(worst, bank.render_ms.get("%s#0" % id, 0.0))
	# what warming costs
	var t0: int = Time.get_ticks_usec()
	var fresh := AudioBank.new()
	fresh.world["enabled"] = true
	var extras: Array = fresh.extra_ids().filter(func(i): return String(i).begins_with("surf."))
	for id in extras:
		for v in range(fresh.variants(id)):
			fresh.stream(id, v)
	var ms: float = (Time.get_ticks_usec() - t0) / 1000.0
	ok(extras.size() == bank.world.sounds.size(), "with the set on, the bank's extras include every surface sound (%d); warming them takes %.0f ms" % [extras.size(), ms])
	var beds: Array = cues.world.warm_beds(S)
	ok(not beds.is_empty() and beds.all(func(i): return bank.has_sound(i)), "warm_beds names the beds this world needs: %s" % ", ".join(PackedStringArray(beds)))
	var t1: int = Time.get_ticks_usec()
	for id in beds:
		fresh.stream(id, 0)
	print("  (rendering those beds: %.0f ms)" % ((Time.get_ticks_usec() - t1) / 1000.0))


func _spec(id: String) -> Array:
	var rate: int = bank.rate_of(id)
	var cen: float = 0.0
	var share: Array = [0.0, 0.0, 0.0, 0.0, 0.0]
	var cnt: int = 0
	for v in range(bank.variants(id)):
		var buf: PackedFloat32Array = bank.buffer(id, v)
		var starts: Array = []
		if id.begins_with("amb."):
			for j in range(8):
				starts.append(int(float(j) * float(buf.size() - N) / 8.0))
		else:
			var pk: int = 0
			var pv: float = 0.0
			for i in range(buf.size()):
				if absf(buf[i]) > pv:
					pv = absf(buf[i])
					pk = i
			starts.append(maxi(0, mini(pk - N / 8, buf.size() - N)))
		for st in starts:
			var re := PackedFloat32Array()
			var im := PackedFloat32Array()
			re.resize(N)
			im.resize(N)
			for i in range(N):
				re[i] = buf[st + i] * (0.5 - 0.5 * cos(TAU * float(i) / float(N - 1))) if st + i < buf.size() else 0.0
			TC.fft(re, im)
			var tot: float = 0.0
			var wsum: float = 0.0
			var b: Array = [0.0, 0.0, 0.0, 0.0, 0.0]
			for k in range(1, N >> 1):
				var f: float = float(k) * float(rate) / float(N)
				var p: float = (re[k] * re[k] + im[k] * im[k]) * TC.heard(f)
				tot += p
				wsum += p * f
				var bi: int = 0
				while bi < BANDS.size() and f >= BANDS[bi]:
					bi += 1
				b[bi] += p
			cen += wsum / maxf(tot, 1e-12)
			for i in range(5):
				share[i] += b[i] / maxf(tot, 1e-12)
			cnt += 1
	for i in range(5):
		share[i] /= float(cnt)
	return [cen / float(cnt), share]


func _voices() -> void:
	print("7. the ambient voice through AudioVoices")
	var v := AudioVoices.new(bank)
	root.add_child(v)
	await process_frame
	cues.reset(12)
	place(float(_xs.values()[0]) + 60.0, 400.0)
	var t: int = 370000
	var made: Array = tick(t, [])
	for c in made:
		v.play(c, 90000.0 - 5000.0, 1.0)         # a camera far across the world from the bed: it is at the listener all the same
	var found: int = 0
	var pos: float = 99.0
	for i in range(v._pool.size()):
		if v._pool[i].playing and v._meta[i].group == "amb.a":
			found += 1
			pos = v._pool[i].position.x
			ok(v._pool[i].stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and v._pool[i].bus == "Ambience", "the bed loops, on the Ambience bus")
	ok(found == 1 and absf(pos) < 0.001, "one bed voice, in the middle of the picture whatever the camera (x %.1f)" % pos)
	await create_timer(0.3).timeout
	var vol: float = -99.0
	for i in range(v._pool.size()):
		if v._pool[i].playing and v._meta[i].group == "amb.a":
			vol = v._pool[i].volume_db
	ok(vol > float(cues.world.cfg.bed.start_db) + 3.0, "it is fading up (%.1f dB after 0.3 s)" % vol)
	await create_timer(2.4).timeout
	for i in range(v._pool.size()):
		if v._pool[i].playing and v._meta[i].group == "amb.a":
			vol = v._pool[i].volume_db
	var target: float = float(cues.world.cfg.biomes[WorldBiomes.biomeAt(S.fighters[0].x)].gain_db)
	ok(vol > target - 6.0 and vol < target + 6.0, "and has reached its level (%.1f dB, the biome's is %.1f)" % [vol, target])
	# class cap: two beds at most
	var live: int = 0
	for i in range(v._pool.size()):
		if v._pool[i].playing and v._meta[i].cls == "amb":
			live += 1
	ok(live <= int(cues.world.cfg.bed.cap), "at most %d bed voices (%d)" % [int(cues.world.cfg.bed.cap), live])
	# a blow's layer does not take the bed's voice
	for c in tick(t + 20, [ev("damage", {"x": S.fighters[0].x, "y": S.fighters[0].y, "amount": 70.0})]):
		v.play(c, S.fighters[0].x, 1.0)
	var still: int = 0
	for i in range(v._pool.size()):
		if v._pool[i].playing and v._meta[i].group == "amb.a":
			still += 1
	ok(still == 1, "a surface layer leaves the bed alone")
	# stop with the fade
	var stop = cues.Cue.new()
	stop.stop_group = "amb.a"
	stop.fade_ms = 300
	v.play(stop, 0.0, 1.0)
	await create_timer(0.45).timeout
	var gone: int = 0
	for i in range(v._pool.size()):
		if v._pool[i].playing and v._meta[i].group == "amb.a":
			gone += 1
	ok(gone == 0, "a stop request fades it out")
	v.queue_free()


## Three real seeded matches with the set on: the sim is unchanged by it, the cue log is the same twice, and what it sounds like.
func _matches() -> void:
	print("8. real matches with the set on")
	for sd in [4, 12345, 777]:
		var plain: Array = _run_match(sd, false)
		var a: Array = _run_match(sd, true)
		var b: Array = _run_match(sd, true)
		var by: Dictionary = {}
		var amb: int = 0
		var surf: int = 0
		for c in a[2]:
			if String(c).begins_with("amb."):
				amb += 1
			elif String(c).begins_with("surf."):
				surf += 1
		ok(str(plain[0]) == str(a[0]), "seed %d: the sim hash is unchanged by the set (%s)" % [sd, str(a[0][-1])])
		ok(a[1] == b[1], "seed %d: the cue log is the same twice (%s)" % [sd, a[1].substr(0, 12)])
		ok(amb >= 2, "seed %d: %d bed cues in %d ticks, %d surface layers (%.1f a minute)" % [sd, amb, a[3], surf, surf * 3600.0 / maxf(a[3], 1.0)])
		ok(float(a[4]) < 600.0, "seed %d: all the audio takes %.0f microseconds a tick on average, the set on (a tick is 16,667)" % [sd, float(a[4])])


func _run_match(sd: int, with_world: bool) -> Array:
	var M := SimCore.createSim()
	SimCore.newMatch(M, sd)
	var c := AudioCues.new(bank)
	c.world.cfg["enabled"] = with_world
	c.reset(sd)
	var spent: int = 0
	var hashes: Array = []
	var lines := PackedStringArray()
	var sounds: Array = []
	var t: int = 0
	while t < max_ticks and not (M.game.ko != null and M.game.koT > 3.0):
		SimCore.step(M)
		if with_world:
			var t0: int = Time.get_ticks_usec()
			var made: Array = c.consume(M, M.out.fx)
			spent += Time.get_ticks_usec() - t0
			for cue in made:
				sounds.append(cue.sound)
				lines.append("%d|%s|%d|%.3f|%.3f|%.3f|%.4f|%s" % [t, cue.sound, cue.variant, cue.x, cue.y, cue.gain_db, cue.pitch, cue.group])
		M.out.fx.clear()
		M.out.feed.clear()
		t += 1
		if t % 60 == 0:
			hashes.append(SimHash.stateHash(M).gameplay)
	hashes.append(SimHash.stateHash(M).gameplay)
	SimCore.dispose(M)
	return [hashes, "\n".join(lines).sha256_text(), sounds, t, float(spent) / maxf(float(t), 1.0)]
