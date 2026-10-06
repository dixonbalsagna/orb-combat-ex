extends SceneTree
## Does the audio hook behave? Runs seeded AI-vs-AI matches on the real sim and feeds each tick's fx events to
## AudioCues, as a render host would. From the repo root:
##   godot --headless --path . --script res://audio/tools/host_check.gd [-- --seeds=4,12345,777 --ticks=5400]
## For every seed it checks:
##   1. the sim is unchanged: the gameplay hash every 60 ticks and at the end is identical with and without audio
##      (audio reads the sim and draws nothing from its RNG);
##   2. the cues are reproducible: a second audio run gives the same cue log (same variants, pitches, levels);
##   3. every cue names a sound the bank can render, and every cue's numbers are finite and inside the data's limits;
##   4. what a fight sounds like: cues per sound, grunts, the busiest tick.
## Exit code 1 on any failure. No sound device is used.

var seeds: Array = [4, 12345, 777]
var max_ticks: int = 5400


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = Array(a.substr(8).split(",")).map(func(s): return int(s))
		elif a.begins_with("--ticks="):
			max_ticks = int(a.substr(8))
	var bank := AudioBank.new()
	var ok: bool = true
	for sd in seeds:
		var plain: Array = _run(sd, null)
		var cues := AudioCues.new(bank)
		var with_audio: Array = _run(sd, cues)
		var again_cues := AudioCues.new(bank)
		var again: Array = _run(sd, again_cues)
		var same_sim: bool = str(plain[0]) == str(with_audio[0])
		var same_cues: bool = with_audio[2] == again[2]
		var bad: String = _validate(with_audio[3], bank, cues.cfg)
		ok = ok and same_sim and same_cues and bad == ""
		print("seed %-6d ticks %d  sim hash %s  %s" % [sd, plain[1], str(plain[0][-1]), "unchanged by audio" if same_sim else "CHANGED BY AUDIO"])
		print("            cue log %s  %s   %d cues (%.1f a minute), busiest tick %d" % [with_audio[2].substr(0, 16), "reproducible" if same_cues else "NOT REPRODUCIBLE", with_audio[3].size(), with_audio[3].size() * 3600.0 / with_audio[1], with_audio[4]])
		var by: Dictionary = {}
		for c in with_audio[3]:
			by[c.sound] = by.get(c.sound, 0) + 1
		var parts: Array = []
		for k in by:
			parts.append("%s %d" % [k, by[k]])
		parts.sort()
		print("            " + ", ".join(parts))
		if bad != "":
			print("            FAIL: " + bad)
	# every flash has a cue for every fighter, renders, and stays within its flash time
	var fs := SimCore.createSim()
	SimCore.newMatch(fs, 4)
	var cue_maker := AudioCues.new(bank)
	var flash_ok: bool = true
	var n_flash: int = 0
	for actor in range(fs.fighters.size()):
		for fl in cue_maker.cfg.flash.rank:
			var c = cue_maker.flash(fs, actor, fl)
			if c == null or not bank.has_sound(c.sound):
				flash_ok = false
				print("no flash cue for actor %d, flash %s" % [actor, fl])
				continue
			var len_s: float = bank.duration(c.sound, 0)
			if len_s > float(bank.flashes.flashes[fl].max_s) + 0.02:
				flash_ok = false
				print("flash cue %s is %.2f s, longer than its flash (%.2f s)" % [c.sound, len_s, float(bank.flashes.flashes[fl].max_s)])
			n_flash += 1
	# the voice and the sound family are found by roster id (f.id), not by the display name: a renamed label changes nothing
	var base_ids: Array = []
	for actor in range(fs.fighters.size()):
		base_ids.append(cue_maker.flash(fs, actor, "found").sound)
	var grunts_a: String = _grunt_run(cue_maker, fs)
	fs.fighters[0].name = "PROTAGONIST-A"
	fs.fighters[1].name = "RIVAL-B"
	var same_ids: bool = true
	for actor in range(fs.fighters.size()):
		var c2 = cue_maker.flash(fs, actor, "found")
		same_ids = same_ids and c2 != null and c2.sound == base_ids[actor]
	var grunts_b: String = _grunt_run(cue_maker, fs)
	same_ids = same_ids and grunts_a == grunts_b and grunts_a != "" and fs.fighters[0].id == "PROTAGONIST" and fs.fighters[1].id == "RIVAL"
	flash_ok = flash_ok and same_ids
	print("roster ids PROTAGONIST and RIVAL: the flash cues and the grunt cues are the same whatever the display label: %s" % ("yes" if same_ids else "NO"))
	SimCore.dispose(fs)
	# the pulse numbers must match Art's data/art/flashes.json (copied into flash_cues.json)
	if FileAccess.file_exists("res://data/art/flashes.json"):
		var art: Dictionary = AudioBank.load_json("res://data/art/flashes.json").get("flashes", {})
		for fl in bank.flashes.flashes:
			if bool(bank.flashes.flashes[fl].get("held", false)) or not art.has(fl) or not bank.flashes.flashes[fl].has("pulse"):
				continue
			var mine: Dictionary = bank.flashes.flashes[fl].pulse
			var theirs: Dictionary = art[fl].pulse
			for key in ["count", "on", "off", "fade"]:
				if absf(float(mine[key]) - float(theirs[key])) > 0.0005:
					flash_ok = false
					print("flash %s: pulse %s is %s here but %s in data/art/flashes.json" % [fl, key, str(mine[key]), str(theirs[key])])
	print("\nflash cues: %d checked (every fighter x every active flash), %s" % [n_flash,"all present and within their flash time" if flash_ok else "FAILED"])
	ok = ok and flash_ok
	print("\naudio host check passed" if ok else "\naudio host check FAILED")
	quit(0 if ok else 1)


## [gameplay hashes every 60 ticks + last, ticks run, cue-log sha256, all cues, busiest tick]
func _run(sd: int, cues) -> Array:
	var S := SimCore.createSim()
	SimCore.newMatch(S, sd)
	if cues != null:
		cues.reset(sd)
	var hashes: Array = []
	var all: Array = []
	var lines := PackedStringArray()
	var busiest: int = 0
	var t: int = 0
	while t < max_ticks and not (S.game.ko != null and S.game.koT > 3.0):
		SimCore.step(S)
		if cues != null:
			var made: Array = cues.consume(S, S.out.fx)
			busiest = maxi(busiest, made.size())
			for c in made:
				all.append(c)
				lines.append("%d|%s|%d|%.3f|%.3f|%.3f|%.4f|%s|%s" % [t, c.sound, c.variant, c.x, c.y, c.gain_db, c.pitch, c.group, str(c.muffled)])
		S.out.fx.clear()
		S.out.feed.clear()
		t += 1
		if t % 60 == 0:
			hashes.append(SimHash.stateHash(S).gameplay)
	hashes.append(SimHash.stateHash(S).gameplay)
	SimCore.dispose(S)
	return [hashes, t, "\n".join(lines).sha256_text(), all, busiest]


func _validate(all: Array, bank: AudioBank, cfg: Dictionary) -> String:
	for c in all:
		if not bank.has_sound(c.sound):
			return "cue for a sound the bank does not have: " + c.sound
		if c.variant < 0 or c.variant >= bank.variants(c.sound):
			return "variant out of range for " + c.sound
		if not (is_finite(c.gain_db) and is_finite(c.pitch) and is_finite(c.x) and is_finite(c.y)):
			return "a cue has a non-finite number: " + c.sound
		if c.pitch < 0.4 or c.pitch > 2.0:
			return "pitch %.2f outside 0.4 to 2.0 for %s" % [c.pitch, c.sound]
		if c.gain_db < -20.0 or c.gain_db > 8.0:
			return "gain %.1f dB outside -20 to +8 for %s" % [c.gain_db, c.sound]
		if c.x < 0.0 or c.x >= SimConst.W:
			return "x %.1f is outside the planet for %s" % [c.x, c.sound]
	return ""


## Feed 60 damage events through the cue mapper (a fresh audio stream, sim time stepped by hand) and return a digest of
## the voice cues it makes: the same under either spelling of the fighter ids.
func _grunt_run(cue_maker, S) -> String:
	cue_maker.reset(9)
	var lines := PackedStringArray()
	for i in range(60):
		S.T = 5.0 + 2.0 * float(i)
		var e := SimState.FxEvent.new()
		e.type = "damage"
		e.amount = 80.0
		e.x = S.fighters[1 if i % 2 == 0 else 0].x
		e.y = S.fighters[1 if i % 2 == 0 else 0].y
		for c in cue_maker.consume(S, [e]):
			if c.kind == "voice":
				lines.append("%d|%s|%d|%.3f" % [i, c.sound, c.variant, c.pitch])
	return "
".join(lines).sha256_text() if lines.size() > 0 else ""
