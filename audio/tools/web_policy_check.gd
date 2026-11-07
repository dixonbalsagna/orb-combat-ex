extends SceneTree
## AudioVoices with the browser-direct one-shots (audio/audio_web.gd, docs/audio/crackle.md): the voice policy is the same whichever sink a cue goes to. A stand-in for the page's
## player (the real one is checked in a browser by audio/tools/web_voices_check.mjs) records what it is asked; the voices' own rules (slots, groups, class caps, priority, ducks,
## the player's trims) are checked against it. No sound device is used.
##   godot --headless --path . --script res://audio/tools/web_policy_check.gd

class StubWeb extends AudioWeb:
	var is_running: bool = true
	var plays: Array = []      # {slot, key, gain, pan, rate, bus, lp, group}
	var stops: Array = []      # slot
	var group_stops: Array = []
	var buses: Dictionary = {}
	var master: float = -1.0
	var sent: Dictionary = {}
	var mono_on: bool = false

	func running() -> bool:
		return is_running

	func ensure(key: String, _stream: AudioStreamWAV) -> void:
		sent[key] = true

	func play(slot: int, key: String, gain: float, pan: float, rate: float, bus: String, lowpass_hz: float, group: String) -> bool:
		plays.append({"slot": slot, "key": key, "gain": gain, "pan": pan, "rate": rate, "bus": bus, "lp": lowpass_hz, "group": group})
		return true

	func stop_slot(slot: int, _fade_ms: int = 4) -> void:
		stops.append(slot)

	func stop_group(group: String, _fade_ms: int) -> void:
		group_stops.append(group)

	func set_bus(name: String, linear: float) -> void:
		buses[name] = linear

	func set_master(linear: float) -> void:
		master = linear

	func set_mono(on: bool) -> void:
		mono_on = on


var fails: int = 0


func _initialize() -> void:
	_run.call_deferred()


func ok(cond: bool, msg: String) -> void:
	print("  %s  %s" % ["ok  " if cond else "FAIL", msg])
	if not cond:
		fails += 1


func cue(sound: String, gain_db: float = -6.0, cls: String = "", cap: int = 0, prio: int = 50, group: String = "", bus: String = "Sfx") -> AudioCues.Cue:
	var c := AudioCues.Cue.new()
	c.sound = sound
	c.gain_db = gain_db
	c.pitch = 1.0
	c.bus = bus
	c.cls = cls
	c.cap = cap
	c.priority = prio
	c.group = group
	return c


func _run() -> void:
	var v := AudioVoices.new(AudioBank.new())
	root.add_child(v)
	await process_frame
	ok(v.web == null, "off the web there is no page player (the voices play as before)")
	var w := StubWeb.new()
	v.web = w
	v._sync_web(true)

	print("1. a one-shot goes to the page")
	ok(v.play(cue("impact.light"), 0.0, 1.0), "a light hit is taken")
	ok(w.plays.size() == 1 and String(w.plays[0].key).begins_with("impact.light#") and w.sent.size() == 1, "the page is asked to play it, and was given its samples once")
	ok(not v._pool[w.plays[0].slot].playing, "its Godot player is not used")
	ok(v.active() == 1 and v.played == 1, "the voice counts as sounding (active %d, played %d)" % [v.active(), v.played])
	var g0: float = float(w.plays[0].gain)
	ok(absf(g0 - db_to_linear(-6.0 + AudioVoices.WEB_TRIM_DB)) < 0.001, "its level is the cue's, the distance's and the trim (%.3f)" % g0)
	ok(w.plays[0].bus == "Sfx" and float(w.plays[0].lp) == 0.0, "on the Sfx bus, no low-pass")
	var far := cue("impact.light", -6.0)
	far.x = 1200.0
	v.play(far, 0.0, 1.0)
	ok(float(w.plays[1].gain) < g0 and float(w.plays[1].pan) > 0.0, "a cue far to the right is quieter and panned right (%.2f, pan %.2f)" % [float(w.plays[1].gain), float(w.plays[1].pan)])
	var m := cue("impact.guard")
	m.muffled = true
	v.play(m, 0.0, 1.0)
	ok(w.plays[2].bus == "SfxMuffled" and float(w.plays[2].lp) > 0.0, "a muffled cue goes to the muffled bus with its low-pass from mix.json (%.0f Hz)" % float(w.plays[2].lp))
	var vm := cue("impact.guard", -6.0, "", 0, 50, "", "Voice")
	vm.muffled = true
	v.play(vm, 0.0, 1.0)
	ok(w.plays[3].bus == "VoiceMuffled", "a muffled voice goes to the muffled voice bus")

	print("2. what the page does not play stays on Godot's players")
	var before: int = w.plays.size()
	var lp := cue("impact.light")
	lp.loop = true
	ok(v.play(lp, 0.0, 1.0) and w.plays.size() == before, "a looped cue is a Godot player's")
	w.is_running = false
	var nr := cue("impact.medium")
	ok(v.play(nr, 0.0, 1.0) and w.plays.size() == before, "while the page's context is not running the Godot player takes it (nothing is queued for a click)")
	w.is_running = true

	print("3. the voices' rules hold for page voices")
	var v2 := AudioVoices.new(AudioBank.new())
	root.add_child(v2)
	await process_frame
	var w2 := StubWeb.new()
	v2.web = w2
	v2.play(cue("impact.light", -6.0, "t.cap", 2, 40), 0.0, 1.0)
	v2.play(cue("impact.light", -6.0, "t.cap", 2, 40), 0.0, 1.0)
	var first_slots: Array = [w2.plays[0].slot, w2.plays[1].slot]
	v2.play(cue("impact.light", -6.0, "t.cap", 2, 60), 0.0, 1.0)
	ok(w2.plays.size() == 3 and w2.plays[2].slot == first_slots[0] and w2.stops.has(first_slots[0]), "a third voice of a class capped at two replaces the oldest page voice (its sound is stopped in the page first)")
	ok(not v2.play(cue("impact.light", -6.0, "t.cap", 2, 10), 0.0, 1.0) and v2.dropped >= 1, "a weaker cue of a full class is dropped")
	v2.play(cue("impact.heavy", -4.0, "", 0, 50, "g.pair"), 0.0, 1.0)
	var gs: int = int(w2.plays[w2.plays.size() - 1].slot)
	v2.play(cue("impact.heavy", -4.0, "", 0, 50, "g.pair"), 0.0, 1.0)
	ok(int(w2.plays[w2.plays.size() - 1].slot) == gs, "a cue with a group takes its group's slot (one mouth)")
	ok(v2.stop_group("g.pair", 40) and w2.stops.has(gs), "stopping the group stops the page voice")
	ok(not v2.stop_group("g.nothing", 40), "a group with no voice finds none")
	var n_before: int = v2.active()
	v2._process(5.0)
	ok(v2.active() < n_before and v2.active() == 0, "a page voice ends when its sound's own length has passed (%d to %d)" % [n_before, v2.active()])

	print("4. the page's buses follow the mixer")
	ok(w.buses.has("Sfx") and w.buses.has("Voice") and w.buses.has("SfxMuffled") and w.master > 0.0, "every bus and the Master were sent at the start")
	AudioVoices.set_user_volume("effects", 0.5)
	v._process(0.016)
	ok(absf(float(w.buses["Sfx"]) - db_to_linear(linear_to_db(0.5))) < 0.01, "a player's effects trim reaches the page (%.3f)" % float(w.buses["Sfx"]))
	AudioVoices.set_user_volume("master", 0.0)
	v._process(0.016)
	ok(w.master < 0.001, "and the Master's mute (%.5f)" % w.master)
	AudioVoices.set_user_volume("master", 1.0)
	AudioVoices.set_user_volume("effects", 1.0)
	var ducking := cue("impact.light", -6.0)
	ducking.duck = [{"bus": "Sfx", "db": -6.0, "ms": 150}]
	v.play(ducking, 0.0, 1.0)
	v._process(0.016)
	ok(float(w.buses["Sfx"]) < 0.6, "a duck reaches the page (%.2f)" % float(w.buses["Sfx"]))
	AudioVoices.set_mono(true)
	ok(AudioVoices._inst != null, "the mono option is known to the static setter")
	AudioVoices.set_mono(false)

	print("5. the status line")
	ok(v.status_line().contains("master peak"), "the status line reads with a page player in place")
	v.queue_free()
	v2.queue_free()
	print("\nweb policy check %s" % ["passed" if fails == 0 else "FAILED (%d)" % fails])
	quit(0 if fails == 0 else 1)
