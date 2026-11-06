extends SceneTree
## Does AudioVoices.status_line() (the page's audio log, ?audiolog=1) say what the audio is doing, and change nothing?
##   godot --headless --path . --script res://audio/tools/status_check.gd
## Exit code 1 on any failure. No sound device is used.

var fails: int = 0


func _initialize() -> void:
	_run.call_deferred()


func ok(cond: bool, msg: String) -> void:
	print("  %s  %s" % ["ok  " if cond else "FAIL", msg])
	if not cond:
		fails += 1


func _run() -> void:
	var bank := AudioBank.new()
	var v := AudioVoices.new(bank)
	root.add_child(v)
	await process_frame
	var line: String = v.status_line()
	print("     " + line)
	for token in ["played 0 dropped 0 live 0", "lost 0 waiting 0", "warming false", "Hz", "master peak", "trim m 0 e 0 v 0 dB", "buses Master", "Sfx 0", "SfxMuffled", "Voice -2"]:
		ok(line.contains(token), "it says %s" % token)
	ok(not line.contains("ctx "), "and nothing of the browser off the web")
	var cue := AudioCues.Cue.new()
	cue.sound = "impact.light"
	cue.gain_db = -6.0
	cue.pitch = 1.0
	cue.bus = "Sfx"
	ok(v.play(cue, 0.0, 1.0), "a cue plays")
	var after: String = v.status_line()
	ok(after.contains("played 1 dropped 0 live 1"), "played and live count it (%s)" % after.substr(0, 60))
	var before_played: int = v.played
	var before_db: float = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Sfx"))
	for i in range(5):
		v.status_line()
	ok(v.played == before_played and is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Sfx")), before_db), "calling it again changes nothing")
	AudioVoices.set_user_volume("effects", 0.0)
	ok(v.status_line().contains("e -80 v"), "a muted effects trim shows as e -80")
	AudioVoices.set_user_volume("effects", 1.0)
	ok(v.status_line().contains("e 0 v"), "and back to e 0")
	v.queue_free()
	print("\nstatus check %s" % ["passed" if fails == 0 else "FAILED (%d)" % fails])
	quit(0 if fails == 0 else 1)
