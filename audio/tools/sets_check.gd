extends SceneTree
## A-AUDIO-01: are the five things a player should hear (a beam, a knock-out, a launch, a struggle, a transformation) made into sounds on a seeded
## match with the audio data AS IT SHIPS (the beam struggle, moments and carry sets are on in audio/data since 2026-11-14, as in the build Orb
## played on 9 November)? For each match it counts the sim's events and the cues made from them, and checks that every cue names a bank sound
## at an audible level. The sets are NOT switched on here: this reads the data as it is. From the repo root:
##   godot --headless --path . --script res://audio/tools/sets_check.gd [-- --seeds=301,302,303,304 --ticks=3600 --setup=power,dash]
## Exit code 1 if a set is off in the data, a cue names no bank sound or has numbers out of range, or an event that happened made no cue.
## A knock-out is rare in the AI's matches (the sim's KO comes from the wounds, not hit points), so it is usually reported as not in these
## matches; its cue is checked on a staged event in moments_check.
## An event that did not happen in the sampled matches is reported as such, not failed (a longer or different match may have it).
## Run it on a tree with the sim data of the build under test; the same script gives the same lines on any tree whose data matches.

var bank: AudioBank
var fails: int = 0
var lines: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	bank = AudioBank.new()
	_run.call_deferred()


func ok(cond: bool, msg: String) -> void:
	print("  %s  %s" % ["ok  " if cond else "FAIL", msg])
	if not cond:
		fails += 1


func _run() -> void:
	var seeds: Array = [301, 302, 303, 304]
	var ticks: int = 3600
	var setup: Dictionary = {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = []
			for s in a.substr(8).split(","):
				seeds.append(int(s))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a.begins_with("--setup="):
			for w in a.substr(8).split(","):
				if w != "":
					setup[w] = true
	var probe := AudioCues.new(bank)
	print("1. the data as shipped")
	ok(probe.tug.enabled(), "the beam struggle set is on (audio/data/tug_cues.json)")
	ok(probe.moments.enabled(), "the moments set is on (audio/data/moment_cues.json)")
	ok(probe.carry.enabled(), "the carry set is on (audio/data/carry_cues.json)")
	info("world %s, coop %s (both stay as they were in the build Orb played)" % ["on" if probe.world.enabled() else "off", "on" if probe.coop.enabled() else "off"])
	print("2. seeded matches %s, up to %d ticks, setup %s" % [str(seeds), ticks, str(setup)])
	var ev_n: Dictionary = {"beam": 0, "ko": 0, "launch": 0, "struggle": 0, "transform": 0}
	var cue_n: Dictionary = {"beam": 0, "ko": 0, "launch": 0, "struggle": 0, "transform": 0}
	var bad: String = ""
	var total_cues: int = 0
	for sd in seeds:
		var M := SimCore.createSim()
		SimCore.newMatch(M, int(sd), {}, setup)
		var cm := AudioCues.new(bank)
		cm.reset(int(sd))
		var t: int = 0
		while t < ticks and not (M.game.ko != null and M.game.koT > 3.0):
			SimCore.step(M)
			for e in M.out.fx:
				var k: String = String(e.kind) if e.type == "cue" else ""
				if e.type == "cue" and (k == "beam_charge" and String(e.text) == "start" or k == "beam_fire"):
					ev_n.beam += 1
				elif e.type == "ko":
					ev_n.ko += 1
				elif e.type == "launch":
					ev_n.launch += 1
				elif e.type == "cue" and k == "beam_struggle" and String(e.text) == "start":
					ev_n.struggle += 1
				elif e.type == "transform_ready" or e.type == "form_release":
					ev_n.transform += 1
			for c in cm.consume(M, M.out.fx):
				total_cues += 1
				if c.sound == "":
					continue
				if not bank.has_sound(c.sound):
					bad = "no such sound " + c.sound
				elif not (is_finite(c.gain_db) and is_finite(c.pitch)) or c.pitch < 0.3 or c.pitch > 2.5 or c.gain_db < -40.0 or c.gain_db > 8.0:
					bad = "number out of range for %s: gain %.1f pitch %.2f" % [c.sound, c.gain_db, c.pitch]
				match String(c.cls):
					"moment.charge", "moment.fire":
						cue_n.beam += 1
					"moment.ko":
						cue_n.ko += 1
					"moment.launch":
						cue_n.launch += 1
					"tug.bed", "tug.lock":
						cue_n.struggle += 1
					"form.ready", "coil":
						cue_n.transform += 1
			M.out.fx.clear()
			M.out.feed.clear()
			t += 1
		SimCore.dispose(M)
	ok(bad == "" and total_cues > 0, "every cue names a bank sound with finite, in-range numbers (%d cues) %s" % [total_cues, bad])
	for k in ["beam", "ko", "launch", "struggle", "transform"]:
		var label: String = {"beam": "a beam charging or firing", "ko": "a knock-out", "launch": "a launch", "struggle": "a beam struggle starting", "transform": "a transformation"}[k]
		if ev_n[k] == 0:
			info("%s: not in these matches (0 events)" % label)
		else:
			ok(cue_n[k] > 0, "%s: %d events, %d cues" % [label, ev_n[k], cue_n[k]])
	print("\nsets check %s" % ("FAILED (%d)" % fails if fails > 0 else "passed"))
	quit(1 if fails > 0 else 0)


func info(msg: String) -> void:
	print("  --    " + msg)
