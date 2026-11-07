class_name AudioCoop
extends RefCounted
## The sounds the co-op 2v2 and the controller plan asked for (docs/audio/coop-sound.md; the EP's brief of 2026-11-07, A2 of
## docs/ep/proposals/co-op-2v2.md): the brink's call (read from every fight's events, so a human hears either fight reach its
## brink), a good push in a beam clash, the pad's refusal knock (`stick_refused`, `press_refused`) and the charge stages rising
## (`stick_stage`). Created and called by AudioCues. It reads the sim's events and returns sound cues; it never writes the sim and needs
## no sound device.
##
## EXISTING SOUNDS ONLY (no new recipe), each at its own pitch and level in data/coop_cues.json. PARKED behind that file's
## "enabled" (false): off, nothing here runs, no draw from the audio stream, and audio is byte-for-byte what it was.
##
## Two entry points: `on_cue` for the fight in S (AudioCues.consume calls it for every cue) and `consume_others` for the other
## fights' events (the host hands each list it keeps, `SimHost.other_events()`; AudioCues.consume_others calls it). A cue is
## never read twice: the fight in S is never in the other lists.

const PATH := "res://audio/data/coop_cues.json"

var cfg: Dictionary = {}
var cues                                  # AudioCues
var _last: Dictionary = {}                # "kind.tag" -> the tick it last sounded (the rate limits)
var _stage: Dictionary = {}               # "tag" -> [the last stage heard, the tick]


func _init(p_cues) -> void:
	cues = p_cues
	cfg = AudioBank.load_json(PATH)


func reset() -> void:
	_last.clear()
	_stage.clear()


func enabled() -> bool:
	return bool(cfg.get("enabled", false))


## One cue of the fight in S.
func on_cue(S: SimState, e, out: Array) -> void:
	if not enabled():
		return
	_cue(S, e, S.fighters, true, out)


## The other fights' events of the last tick: lists[j] belongs to the j-th fight that is not the one in S, in fight order (the
## order SimHost.other_events() gives). Only the brink's call is read there (a partner's fight is otherwise silent on this PC; the
## distant mix is a proposal, docs/audio/coop-sound.md section 5).
func consume_others(S: SimState, lists: Array, out: Array) -> void:
	if not enabled() or S.stage == null:
		return
	var ks: Array = []
	for k in range(S.stage.fights.size()):
		if k != S.stage.cur:
			ks.append(k)
	for j in range(mini(lists.size(), ks.size())):
		var fighters: Array = S.stage.fights[ks[j]].fighters
		for e in lists[j]:
			if e.type == "cue" and String(e.kind) == "brink_call":
				_cue(S, e, fighters, false, out)


func _cue(S: SimState, e, fighters: Array, own: bool, out: Array) -> void:
	match String(e.kind):
		"brink_call":
			_brink(S, e, fighters, own, out)
		"stick_refused", "press_refused":
			_refuse(S, e, fighters, out)
		"stick_stage":
			_stage_up(S, e, fighters, out)
		"beam_surge":
			_push(S, e, fighters, out)


func _body(fighters: Array, actor: float):
	var a: int = int(actor)
	if a < 0 or a >= fighters.size():
		return null
	return fighters[a]


## True (and the time kept) if `key` has not sounded within `gap` ticks.
func _free(S: SimState, key: String, gap: int) -> bool:
	if S.tick - int(_last.get(key, -999999)) < gap:
		return false
	_last[key] = S.tick
	return true


## The brink's call: a sting at the listener (an alert, however far the fight is) and the fighter's own cry. In the fight in S the cry
## is at the fighter; in another fight it is far away, so it comes muffled and quiet at the listener.
func _brink(S: SimState, e, fighters: Array, own: bool, out: Array) -> void:
	var f = _body(fighters, e.actor)
	if f == null:
		return
	var B: Dictionary = cfg.brink
	var tag: String = String(e.text) if String(e.text) != "" else "%d" % int(e.actor)
	if not _free(S, "brink." + tag, int(B.gap_ticks)):
		return
	var T: Dictionary = B.sting
	var st = cues.make_cue(String(T.sound), f.x, f.y, float(T.gain_db), float(T.pitch), int(T.priority), String(T.bus), String(T.cls), int(T.cap), String(T.caption) % tag.to_upper(), S)
	st.ambient = true
	st.muffled = false
	out.append(st)
	var V: Dictionary = B.voice
	var voice: String = String(cues.cfg.fighters.get(f.id, ""))
	var id: String = "voice.%s.%s" % [voice, String(V.gesture)]
	if voice == "" or not cues.bank.has_sound(id):
		return
	var c = cues.make_cue(id, f.x, f.y, float(V.gain_db), 1.0, int(V.priority), "Voice", String(V.cls), int(V.cap), "", S)
	c.kind = "voice"
	c.group = "coop.voice." + tag
	if not own:
		c.ambient = true
		c.muffled = true
		c.gain_db += float(V.far_db)
	out.append(c)


## The pad's knock for a press that went nowhere: a dull low knock at the presser, the same whatever the reason (the reason is the
## screen's word). At most one every gap_ticks a fighter; the internal take-overs ("replaced", "answered") are quieter.
func _refuse(S: SimState, e, fighters: Array, out: Array) -> void:
	var f = _body(fighters, e.actor)
	if f == null:
		return
	var R: Dictionary = cfg.refuse
	if not _free(S, "refuse.%d" % int(e.actor), int(R.gap_ticks)):
		return
	var g: float = float(R.gain_db)
	if R.quiet_texts.has(String(e.source)):
		g += float(R.quiet_db)
	out.append(cues.make_cue(String(R.sound), f.x, f.y, g, float(R.pitch), int(R.priority), "Sfx", String(R.cls), int(R.cap), "", S))


## A charge's stage rising: a tick that climbs a ladder of semitones, a low thud on the top stage, a step down a little duller. The
## cue's `k` is the stage, `n` the count; source "capped" is the knock for a stage the energy will not pay for.
func _stage_up(S: SimState, e, fighters: Array, out: Array) -> void:
	var f = _body(fighters, e.actor)
	if f == null:
		return
	var G: Dictionary = cfg.stage
	var k: int = int(float(e.k))
	var n: int = int(float(e.n))
	if k < 1:
		return
	var tag: String = "%d.%d" % [S.stage.cur if S.stage != null else 0, int(e.actor)]
	var prev: Array = _stage.get(tag, [0, -999999])
	var falling: bool = k < int(prev[0]) and S.tick - int(prev[1]) < int(G.restart_ticks)
	var changed: bool = k != int(prev[0]) or S.tick - int(prev[1]) >= int(G.restart_ticks)
	_stage[tag] = [k, S.tick]
	var capped: bool = String(e.source) == "capped"
	if changed or not capped:
		var ladder: Array = G.semitones
		var st: float = float(ladder[mini(k - 1, ladder.size() - 1)])
		var gain: float = float(G.gain_db)
		if falling:
			st += float(G.down_semitones)
			gain += float(G.down_db)
		out.append(cues.make_cue(String(G.sound), f.x, f.y, gain, pow(2.0, st / 12.0), int(G.priority), "Sfx", String(G.cls), int(G.cap), "", S))
		if not falling and n > 0 and k >= n:
			var T: Dictionary = G.top
			out.append(cues.make_cue(String(T.sound), f.x, f.y, float(T.gain_db), float(T.pitch), int(G.priority), "Sfx", String(G.cls), int(G.cap), "", S))
	if capped:
		var C: Dictionary = G.capped
		out.append(cues.make_cue(String(C.sound), f.x, f.y, float(C.gain_db), float(C.pitch), int(G.priority), "Sfx", String(G.cls), int(G.cap), "", S))


## A good push in a beam clash: the struggle's whump already sounds on every surge (AudioTug), and its sharp token on a sharp one; this
## adds the token's plain form to the other good pushes, so every push on the beat has a sharp sound.
func _push(S: SimState, e, fighters: Array, out: Array) -> void:
	var f = _body(fighters, e.actor)
	if f == null or String(e.text) == "sharp":
		return
	var P: Dictionary = cfg.clash.push
	out.append(cues.make_cue(String(P.sound), f.x, f.y, float(P.gain_db), float(P.pitch), int(P.priority), "Sfx", String(P.cls), int(P.cap), "", S))
