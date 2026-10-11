class_name AudioBrawl
extends RefCounted
## The brawl's sounds (docs/audio/brawl-cues.md; Encounter's cue names in docs/director/brawl-c1.md and the EP's list). It
## reads the cue and damage events of a tick and returns the sound cues for them. Created and called by AudioCues, which
## owns the audio stream (its only randomness) and the cue class. Pure logic: it reads the sim and never writes it, and
## it needs no sound device.
##
## What it maps:
##   * hits: the strength (light, medium, heavy) comes from the attacker's `blow` cue (text light, medium, heavy; bolt and
##     blast; the old text `flurry` counts as light), matched to the damage event by attacker and contact tick, and falls
##     back to the damage amount when no blow cue is found. A guarded hit is its own sound. FLURRY MODE: from the third
##     light in a second a light is 2 dB quieter and its pitch climbs a third of a semitone a blow (a run that "builds"),
##     and the blow that closes a flurry (the tick of a `stagger` cue with text flurry) is 3 dB louder and not thinned.
##   * every number and name is in data/brawl_cues.json.

const BRAWL_PATH := "res://audio/data/brawl_cues.json"

var cfg: Dictionary = {}
var cues                                  # AudioCues
var _blows: Dictionary = {}               # attacker slot -> Array of {text, n, tick, used}
var _lights: Dictionary = {}              # attacker slot -> Array of the ticks of its recent light hits
var _close: Dictionary = {}               # attacker slot -> the tick its flurry closed on
var _winding: Dictionary = {}              # winder slot -> {heavy, live, hum, cut, full}: a wind-up or charge in progress
var _pending: Array = []                  # gathers that wait for the gap to close: {actor, wait (live ticks), cue}
var _bolts: Dictionary = {}               # firing slot -> the ticks of its recent bolts
var _landed: Dictionary = {}              # victim slot -> the tick an energy_land cue named it (the shot's own sound plays)
var _double_n: int = -1                   # the tick a double hit's two blows land on (-1 for none)
var _double_done: bool = false            # the one sound for the pair has been made
var _double_x: float = 0.0                # the double hit's centre (the cue's x and y)
var _double_y: float = 0.0


func _init(p_cues) -> void:
	cues = p_cues
	cfg = AudioBank.load_json(BRAWL_PATH)


func reset() -> void:
	_blows.clear()
	_lights.clear()
	_close.clear()
	_bolts.clear()
	_winding.clear()
	_pending.clear()
	_landed.clear()
	_double_n = -1
	_double_done = false


## Read the batch's blow and stagger cues first, so a damage event later in the same batch can find its strength, and count
## the live ticks of the heavies that are winding or charging and of the gathers that wait for the gap to close. Returns the
## cues that fall due on this tick (a gather whose wait is over) and the hum's cut at a release.
func begin(S: SimState, events: Array) -> Array:
	var due: Array = []
	var keep: int = int(cfg.strength.blow_window_ticks) * 6
	var live_tick: bool = false
	for e in events:
		if e.type == "tick" and not e.frozen:
			live_tick = true
		if e.type != "cue":
			continue
		match e.kind:
			"blow":
				var a: int = int(e.actor)
				if not _blows.has(a):
					_blows[a] = []
				_blows[a].append({"text": String(e.text), "n": int(e.n), "tick": S.tick, "used": false})
				if String(e.text) == "release":
					_cut_hum(a, due)
			"stagger":
				if e.text == "flurry":
					_close[int(e.target)] = S.tick
			"energy_land":
				_landed[int(e.target)] = S.tick
	for a in _blows.keys():
		_blows[a] = _blows[a].filter(func(b): return S.tick - int(b.tick) <= keep and not b.used)
	if live_tick:
		for a in _winding.keys():
			_winding[a]["live"] = int(_winding[a].live) + 1
		var left: Array = []
		for p in _pending:
			p["wait"] = int(p.wait) - 1
			if int(p.wait) <= 0:
				due.append(p.cue)
			else:
				left.append(p)
		_pending = left
	return due


## The brawl's own cues (type "cue"): the launcher's open and close. More follow (wind-up, double hit, miss, energy).
func on_cue(S: SimState, e, out: Array) -> void:
	match String(e.kind):
		"launcher_open":
			_launcher_open(S, e, out)
		"launcher_close":
			_launcher_close(S, e, out)
		"windup":
			_windup(S, e, out)
		"charge_full":
			_charge_full(S, e, out)
		"miss":
			_miss(S, e, out)
		"double_hit":
			_double_hit(S, e, out)
		"energy_reach":
			_energy_reach(S, e, out)
		"energy_land":
			_energy_land(S, e, out)


## "B now": the rival is staggered for `n - tick` more ticks and `actor` may launch. A stagger shorter than min_ticks (a
## shove's 8) is no launcher. One fixed sound, no random spread, at the staggered fighter, heard by both players.
func _launcher_open(S: SimState, e, out: Array) -> void:
	var L: Dictionary = cfg.launcher
	if int(e.n) - S.tick < int(L.min_ticks):
		return
	var victim: int = int(e.target)
	if victim < 0 or victim >= S.fighters.size():
		return
	var f = S.fighters[victim]
	var c = cues.Cue.new()
	c.sound = String(L.sound)
	c.variant = 0
	c.x = f.x
	c.y = f.y
	c.gain_db = float(L.gain_db)
	c.pitch = 1.0
	c.priority = int(L.priority)
	c.bus = String(L.get("bus", "Sfx"))
	c.cls = String(L.cls)
	c.cap = int(L.cap)
	c.caption = String(L.caption)
	c.group = "launcher.%d" % int(e.actor)
	c.duck = L.duck
	out.append(c)


## The window ended. If the launch was thrown (the close says so by text or by k) the ring is cut, because the launch's own
## whoosh and impact are the confirmation; if it lapsed the ping rings out.
func _launcher_close(S: SimState, e, out: Array) -> void:
	var C: Dictionary = cfg.launcher.close
	var ks: Array = C.stop_k.map(func(v): return int(v))      # JSON numbers are floats
	if not (String(e.text) in C.stop_texts or int(e.k) in ks):
		return
	var c = cues.Cue.new()
	c.stop_group = "launcher.%d" % int(e.actor)
	c.fade_ms = int(C.stop_ms)
	out.append(c)


## The wind-up of a medium or heavy: a rising gather sized to the cue's `dur` (the wind-up alone, in live ticks), cut if a blow
## stops it. `n` is the landing tick, which also counts the ticks a press spends closing the gap, so the gather waits those.
## The text `charge` is a held B going on to charge (the hum); `end` is the wind-up's last word (k 1 thrown, 2 stopped by a
## blow, 3 lost to a stagger or the brawl's end, 4 a miss).
func _windup(S: SimState, e, out: Array) -> void:
	var W: Dictionary = cfg.windup
	var a: int = int(e.actor)
	if a < 0 or a >= S.fighters.size():
		return
	var text: String = String(e.text)
	if text == "end":
		var ks: Array = W.end.stop_k.map(func(v): return int(v))
		if int(e.k) in ks:
			var c = cues.Cue.new()
			c.stop_group = "windup.%d" % a
			c.fade_ms = int(W.end.stop_ms)
			out.append(c)
		_cut_hum(a, out)      # the wind-up or charge is over, however it ended: the hum goes with it
		_winding.erase(a)
		_drop_pending(a)
		return
	if text == "charge":
		_charge_hum(S, a, out)
		return
	if text != "start":
		return
	var dur: int = int(e.dur) if int(e.dur) > 0 else int(e.n) - S.tick
	if dur < int(W.min_ticks):
		return
	var lead: int = maxi(int(e.n) - S.tick - dur, 0)
	_drop_pending(a)
	_winding[a] = {"heavy": dur > int(cfg.charge.heavy_over_ticks), "live": -lead, "hum": false, "cut": false, "full": false}
	var cls: Dictionary = {}
	for k in W.classes:
		if dur <= int(k.max_ticks):
			cls = k
			break
	var f = S.fighters[a]
	var c2 = cues.make_cue(String(cls.sound), f.x, f.y, float(W.gain_db), clampf(float(cls.nominal_ticks) / float(dur), float(W.pitch_min), float(W.pitch_max)), int(W.priority), "Sfx", String(W.cls), int(W.cap), "", S)
	c2.group = "windup.%d" % a
	if lead > 0:
		_pending.append({"actor": a, "wait": lead, "cue": c2})
	else:
		out.append(c2)


func _drop_pending(a: int) -> void:
	_pending = _pending.filter(func(p): return int(p.actor) != a)


## The held B goes on to charge (tick 32): the hum, until the release.
func _charge_hum(S: SimState, a: int, out: Array) -> void:
	var H: Dictionary = cfg.charge.hum
	var w: Dictionary = _winding.get(a, {"heavy": true, "live": 0, "hum": false, "cut": false, "full": false})
	w["hum"] = true
	w["cut"] = false
	_winding[a] = w
	var f = S.fighters[a]
	var c = cues.make_cue(String(H.sound), f.x, f.y, float(H.gain_db), 1.0, int(H.priority), "Sfx", String(H.cls), int(H.cap), "", S)
	c.group = "charge.%d" % a
	out.append(c)


## The hum ends with the release (the blow cue text `release`), 4 ticks before the landing, or with the wind-up's end.
func _cut_hum(a: int, out: Array) -> void:
	if _winding.has(a) and bool(_winding[a].hum) and not bool(_winding[a].cut):
		_winding[a]["cut"] = true
		var h = cues.Cue.new()
		h.stop_group = "charge.%d" % a
		h.fade_ms = int(cfg.charge.hum.stop_ms)
		out.append(h)


## A heavy is full (44 live ticks of a held B): one fixed tick with a ring, exact to the event, so a release can be timed by ear.
## Only B's (source b); the Y's full charge is C2b's.
func _charge_full(S: SimState, e, out: Array) -> void:
	var F: Dictionary = cfg.charge.full
	if String(e.source) == "y" or String(e.text) == "y":
		return
	var a: int = int(e.actor)
	if a < 0 or a >= S.fighters.size():
		return
	if _winding.has(a):
		_winding[a]["full"] = true
	var f = S.fighters[a]
	var c = cues.Cue.new()
	c.sound = String(F.sound)
	c.x = f.x
	c.y = f.y
	c.gain_db = float(F.gain_db)
	c.priority = int(F.priority)
	c.bus = String(F.bus)
	c.cls = String(F.cls)
	c.cap = int(F.cap)
	c.caption = String(F.caption)
	c.group = "chargetick.%d" % a
	out.append(c)


## A blow that missed: the air. `text` says why (gave_ground, reach, dodge); `actor` is the one who swung.
func _miss(S: SimState, e, out: Array) -> void:
	var M: Dictionary = cfg.miss
	var a: int = int(e.actor)
	if a < 0 or a >= S.fighters.size() or not M.has(String(e.text)):
		return
	var f = S.fighters[a]
	var t: Dictionary = M[String(e.text)]
	out.append(cues.make_cue(String(M.sound), f.x, f.y, float(t.gain_db), float(t.pitch), int(M.priority), "Sfx", String(M.cls), int(M.cap), String(M.caption), S))


## A blast gathers for its wind-up (amount ticks; n is the contact tick); a bolt has no gather worth a sound.
func _energy_reach(S: SimState, e, out: Array) -> void:
	if String(e.text) != "blast":
		return
	var G: Dictionary = cfg.energy.gather
	var a: int = int(e.actor)
	if a < 0 or a >= S.fighters.size():
		return
	var ticks: int = int(e.amount) if int(e.amount) > 0 else int(e.n) - S.tick
	if ticks < 4:
		return
	var f = S.fighters[a]
	var c = cues.make_cue(String(G.sound), f.x, f.y, float(G.gain_db), clampf(float(G.nominal_ticks) / float(ticks), float(G.pitch_min), float(G.pitch_max)), int(G.priority), "Sfx", String(G.cls), int(G.cap), "", S)
	c.group = "windup.%d" % a
	out.append(c)


## The shot has landed (source hit, guard, armour or miss). A blast ends its gather; a mashed bolt thins itself.
func _energy_land(S: SimState, e, out: Array) -> void:
	var kind: String = String(e.text)
	if not (kind in ["bolt", "blast"]):
		return
	var E: Dictionary = cfg.energy[kind]
	var src: String = String(e.source) if E.land.has(String(e.source)) else "hit"
	var L: Dictionary = E.land[src]
	var a: int = int(e.actor)
	var tgt: int = int(e.target)
	if a < 0 or a >= S.fighters.size() or tgt < 0 or tgt >= S.fighters.size():
		return
	var f = S.fighters[tgt if src != "miss" else a]
	var sound: String = String(L.get("sound", E.sound))
	var gain: float = float(L.gain_db)
	if kind == "bolt" and src != "miss":
		var recent: Array = _bolts.get(a, []).filter(func(t): return S.tick - int(t) <= int(E.window_ticks))
		if recent.size() >= int(E.after):
			gain += float(E.step_db)
			sound = String(E.lite)
		recent.append(S.tick)
		_bolts[a] = recent
	if kind == "blast":
		var stop = cues.Cue.new()
		stop.stop_group = "windup.%d" % a
		stop.fade_ms = 20
		out.append(stop)
	var cls: String = String(E.cls) if sound != "impact.whiff" else String(cfg.miss.cls)
	var cap: int = int(E.cap) if sound != "impact.whiff" else int(cfg.miss.cap)
	out.append(cues.make_cue(sound, f.x, f.y, gain, float(L.pitch), int(E.priority), "Sfx", cls, cap, String(E.caption), S))


## An even trade ends in a double hit: both blows are thrown now and land `amount` ticks later (n is the landing tick). A
## rising charge now, and one big sound at the landing for the pair (see hit()).
func _double_hit(S: SimState, e, out: Array) -> void:
	var D: Dictionary = cfg.double
	_double_n = int(e.n)
	_double_done = false
	var ahead: int = maxi(int(e.amount), 1)
	var x: float = float(e.x) if float(e.x) != 0.0 else (S.fighters[0].x + S.fighters[1].x) * 0.5
	var y: float = float(e.y) if float(e.x) != 0.0 else (S.fighters[0].y + S.fighters[1].y) * 0.5
	_double_x = x
	_double_y = y
	var c = cues.make_cue(String(D.charge.sound), x, y, float(D.charge.gain_db), clampf(float(D.charge.nominal_ticks) / float(ahead), 0.7, 1.4), int(D.charge.priority), "Sfx", String(D.charge.cls), int(D.charge.cap), "", S)
	out.append(c)


## Is this damage event one of the brawl's melee hits?
func handles(e) -> bool:
	return String(e.kind) in ["light", "medium", "heavy", "guard"]


## Is this the damage of an energy shot whose own cue (energy_land) plays this tick? Then the threshold stand-in is not
## added on top of the bolt's crack or the blast's whump.
func covers(S: SimState, e) -> bool:
	return String(e.kind) == "blast" and int(_landed.get(int(e.victim), -99)) == S.tick


## The strength of a hit: light, medium or heavy.
func strength(S: SimState, e) -> String:
	# Once Simulation puts the strength on the damage event itself, `kind_is_strength` turns this on and the blow cue is
	# no longer needed. Today `kind` is only light, heavy or guard, and a light can be any of the three strengths.
	if bool(cfg.strength.kind_is_strength) and String(e.kind) in ["light", "medium", "heavy"]:
		return String(e.kind)
	var a: int = int(e.attacker)
	var best: Dictionary = {}
	var bd: int = 1 << 30
	for b in _blows.get(a, []):
		if b.used:
			continue
		var d: int = absi(int(b.n) - S.tick) if int(b.n) > 0 else absi(int(b.tick) - S.tick)
		if d <= int(cfg.strength.blow_window_ticks) and d < bd and String(cfg.strength.from_blow.get(b.text, "")) != "":
			bd = d
			best = b
	if not best.is_empty():
		best["used"] = true
		return String(cfg.strength.from_blow[best.text])
	var fb: Dictionary = cfg.strength.fallback_amounts
	if e.amount >= float(fb.heavy_from):
		return "heavy"
	return "medium" if e.amount >= float(fb.medium_from) else "light"


## The cues for a melee hit: the hit itself (none for the second blow of a double hit: the pair has one sound, made for
## the first), and a dull absorbed tick under it when the victim is armoured by a heavy that is winding or charging.
func hit(S: SimState, e) -> Array:
	var out: Array = []
	if _double_n >= 0 and S.tick >= _double_n and S.tick <= _double_n + int(cfg.double.hit.landing_ticks):
		if _double_done:
			return out
		_double_done = true
		var D: Dictionary = cfg.double.hit
		out.append(cues.make_cue(String(D.sound), _double_x, _double_y, float(D.gain_db), 1.0, int(D.priority), "Sfx", String(D.cls), int(D.cap), String(D.caption), S))
		return out
	var st: String = strength(S, e)
	var H: Dictionary = cfg.hit
	var guarded: bool = String(e.kind) == "guard"
	var meta: Dictionary = H.guard if guarded else H[st]
	var s: float = maxf(float(e.amount), 1.0) / float(H.size_ref)
	var pitch: float = clampf(pow(s, float(H.pitch_exp)), float(H.pitch_min), float(H.pitch_max))
	var gain: float = float(meta.gain_db) + clampf(20.0 * float(H.gain_exp) * log(s) / log(10.0), float(H.gain_db_min), float(H.gain_db_max))
	if guarded:
		pitch *= float(H.guard.pitch.get(st, 1.0))
	var a: int = int(e.attacker)
	var closing: bool = _close.get(a, -1) == S.tick
	var sound: String = String(meta.sound)
	if st == "light" and not guarded:
		var F: Dictionary = cfg.flurry
		var recent: Array = _lights.get(a, []).filter(func(t): return S.tick - int(t) <= int(F.window_ticks))
		var n: int = recent.size()
		if closing:
			gain += float(F.close_db)
		elif n >= int(F.after):
			gain += float(F.step_db)
			pitch *= pow(2.0, minf(float(F.climb_max_st), float(F.climb_st_per_blow) * float(n - int(F.after) + 1)) / 12.0)
			if F.has("lite") and n >= int(F.lite.after):
				sound = String(F.lite.sound)
		recent.append(S.tick)
		_lights[a] = recent
	elif closing:
		gain += float(cfg.flurry.close_db)
	out.append(cues.make_cue(sound, float(e.x), float(e.y), gain, pitch, int(meta.priority), "Sfx", String(meta.cls), int(meta.cap), String(meta.caption), S))
	var v: int = int(e.victim)
	if not guarded and _winding.has(v) and bool(_winding[v].heavy) and (st == "light" or st == "medium"):
		var A: Dictionary = cfg.charge.armour
		var armoured: bool = st == "light" or int(_winding[v].live) > int(A.medium_after_live)
		if armoured:
			out.append(cues.make_cue(String(A.sound), float(e.x), float(e.y), float(A.gain_db), float(A.medium_pitch) if st == "medium" else 1.0, int(A.priority), "Sfx", String(A.cls), int(A.cap), "", S))
	return out
