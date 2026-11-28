extends RefCounted
## A scripted clip scene (Tools, 2026-11-28; docs/tools/clips.md, "Trial clips"): two fighters set down at a stated distance, then pad events
## fed through the real input path at stated ticks, or a stated number of ticks after one of the sim's own cues. Read by the headless probe
## (script_probe.gd) and, in a trial web export's SCRATCH copy only, by the capture hook. Nothing here is part of the game.
##
## A script: { "seed": 11, "level": "easy", "computer": [false, false], "ticks": 300,
##   "place": { "gapBh": 8 | "gapUnits": 1500, "air": 600, "ki": 100, "pin": 40 },
##   "events": [ { "at": 40 | "after": "beam_meet", "d": 5, "repeat": 3, "gap": 30,  "pad": 0,
##                 "b": "east", "down": true  |  "trig": "lt", "v": 1  |  "ls": ["to", 0] | "rs": [0, 0]  |  "computer": 1 } ] }
## "to" and "away" as a stick's x mean toward and away from the other fighter at the tick the event fires. gapBh is measured past striking distance.

var sc: Dictionary = {}
var fired: Dictionary = {}     # "event index:repeat" -> true
var seen_at: Dictionary = {}   # cue or event name (also "name:text" and "name@actor") -> the tick it was first seen
var heard: Array = []          # [tick, name, text, actor, attacker, victim, amount], for the probe
var _air_y: Array = []


func load_text(txt: String) -> bool:
	var j = JSON.parse_string(txt)
	if not (j is Dictionary):
		return false
	sc = j
	fired = {}
	seen_at = {}
	heard = []
	_air_y = []
	return true


func seed_value() -> int:
	return int(sc.get("seed", 11))


## What the scene adds to the match setup.
func setup() -> Dictionary:
	return {"aiLevel": String(sc.level)} if sc.has("level") else {}


func computer_slots() -> Array:
	var c: Array = sc.get("computer", [false, false])
	return [bool(c[0]), bool(c[1])]


## The sim's events of the tick just run (the host's own drained signal). `tick` is the count of ticks run so far.
func seen(events: Array, tick: int) -> void:
	for e in events:
		var type: String = String(e.type)
		var name: String = String(e.kind) if type == "cue" else type
		var text: String = str(e.text) if "text" in e and e.text != null else ""
		if type != "cue" and "kind" in e and e.kind != null and String(e.kind) != "":
			text = String(e.kind)
		var actor: int = int(e.actor) if "actor" in e else -1
		for key in [name, name + ":" + text, name + "@" + str(actor), name + ":" + text + "@" + str(actor)]:
			if not seen_at.has(key):
				seen_at[key] = tick
		heard.append([tick, name, text, actor, int(e.attacker) if "attacker" in e else -1, int(e.victim) if "victim" in e else -1, float(e.amount) if "amount" in e else 0.0])


## Called before the tick that follows `t` ticks run.
func drive(main, t: int) -> void:
	var host = main.host
	var S = host.S
	if t == 0:
		_place(S)
	if t < int(sc.get("place", {}).get("pin", 0)):
		_pin(S)
	var evs: Array = sc.get("events", [])
	for i in range(evs.size()):
		var e: Dictionary = evs[i]
		var base: int = -1
		if e.has("at"):
			base = int(e.at)
		elif seen_at.has(String(e.get("after", ""))):
			base = int(seen_at[String(e.after)]) + int(e.get("d", 0))
		if base < 0:
			continue
		for k in range(int(e.get("repeat", 1))):
			var key: String = "%d:%d" % [i, k]
			if not fired.has(key) and t >= base + k * int(e.get("gap", 0)):
				fired[key] = true
				_apply(host, e)


func _place(S) -> void:
	var p: Dictionary = sc.get("place", {})
	if p.is_empty():
		return
	var a = S.fighters[0]
	var b = S.fighters[1]
	var dist: float = float(p.gapUnits) if p.has("gapUnits") else float(DirData.contact().offset) + float(p.get("gapBh", 0.0)) * DirInterrupt.BH
	if p.has("air"):
		a.y = WorldTerrain.groundY(S, a.x, a.z) + float(p.air)
	b.x = SimWrap.wrap(a.x + dist)
	b.y = a.y
	for f in S.fighters:
		f.vx = 0.0
		f.vy = 0.0
		if p.has("ki"):
			f.ki = float(p.ki)
	_air_y = [a.y, b.y]


## Holds the pair at their height while the picture settles (a fighter set down in the air would otherwise drift).
func _pin(S) -> void:
	if _air_y.size() == 2:
		for k in range(2):
			S.fighters[k].y = _air_y[k]
			S.fighters[k].vy = 0.0


func _side(S, pad: int, v) -> float:
	if v is String:
		var d: float = SimWrap.sdx(S.fighters[pad].x, S.fighters[1 - pad].x)
		var s: float = 1.0 if d >= 0.0 else -1.0
		return s if v == "to" else -s
	return float(v)


func _apply(host, e: Dictionary) -> void:
	var pad: int = int(e.get("pad", 0))
	if e.has("computer"):
		host.toggle_ai(int(e.computer))
	elif e.has("b"):
		host.hub.pad_button(pad, String(e.b), bool(e.down))
	elif e.has("trig"):
		host.hub.pad_trigger(pad, String(e.trig), float(e.v))
	elif e.has("ls"):
		host.hub.pad_stick(pad, _side(host.S, pad, e.ls[0]), float(e.ls[1]))
	elif e.has("rs"):
		host.hub.pad_stick_right(pad, _side(host.S, pad, e.rs[0]), float(e.rs[1]))
