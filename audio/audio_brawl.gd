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
const BEAT_PATH := "res://audio/data/beat_cues.json"       # the perfect follow-up, the held X, the grind, the Y's charge, the rest

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
var _held: Dictionary = {}                # attacker slot -> {q: the gaps (ticks) of its held burst's blows not yet heard}
var _perfects: Dictionary = {}            # attacker slot -> the perfect follow-up in flight {n, k, text, link, foe}
var _meds: Dictionary = {}                # attacker slot -> the ticks of its recent medium hits (the grind)
var _last_hit: Dictionary = {}            # attacker slot -> the tick of its last melee hit (a spark waits for the hit's transient to pass)
var _double_x: float = 0.0                # the double hit's centre (the cue's x and y)
var _double_y: float = 0.0


func _init(p_cues) -> void:
	cues = p_cues
	cfg = AudioBank.load_json(BRAWL_PATH)
	var beat: Dictionary = AudioBank.load_json(BEAT_PATH)
	for k in ["perfect", "held", "grind", "rest"]:
		cfg[k] = beat[k]
	cfg.charge["hum_y"] = beat.charge_y.hum
	cfg.charge["full_y"] = beat.charge_y.full


func reset() -> void:
	_blows.clear()
	_lights.clear()
	_close.clear()
	_bolts.clear()
	_winding.clear()
	_pending.clear()
	_landed.clear()
	_held.clear()
	_perfects.clear()
	_meds.clear()
	_last_hit.clear()
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
				if _held.has(a) and String(e.text) == "light":
					var h: Dictionary = _held[a]
					var gap: int = maxi(int(e.n) - int(h.last), 0)
					if gap > int(cfg.held.after_gap_ticks):
						_held.erase(a)      # a pause: whatever comes next is a new run
					else:
						h["last"] = int(e.n)
						h.q.append(gap)
			"burst":
				var ba: int = int(e.actor)
				if String(e.text) == "start":
					_held[ba] = {"q": [], "last": int(e.n)}      # n: the landing tick of the burst's first blow
				elif String(e.text) == "end" and int(e.k) < int(cfg.held.complete_blows):
					_held.erase(ba)      # let go, replaced by another press or staggered: it was not held through
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
		"window_open":
			_window_open(S, e, out)
		"perfect":
			_perfect(S, e, out)
		"chain_broken":
			_chain_broken(S, e, out)
		"launcher_rest":
			_launcher_rest(S, e, out)


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
		_charge_hum(S, a, out, String(e.source))
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
	_pending = _pending.filter(func(p): return int(p.actor) != a or String(p.get("what", "gather")) != "gather")


## The held B goes on to charge (tick 32): the hum, until the release.
func _charge_hum(S: SimState, a: int, out: Array, src: String = "b") -> void:
	var H: Dictionary = cfg.charge.hum_y if src == "y" else cfg.charge.hum
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


## A charge is full: one fixed tick, exact to the event, so a release can be timed by ear. B's is lower with a ring; the Y's
## (source y, the charged medium) is higher and brighter, with no ring.
func _charge_full(S: SimState, e, out: Array) -> void:
	var is_y: bool = String(e.source) == "y" or String(e.text) == "y"
	var F: Dictionary = cfg.charge.full_y if is_y else cfg.charge.full
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
	var held_gap: int = -1
	if st == "light" and not guarded and _held.has(a) and not (_held[a].q as Array).is_empty():
		held_gap = int((_held[a].q as Array).pop_front())
	if st == "light" and not guarded:
		var F: Dictionary = cfg.flurry
		var recent: Array = _lights.get(a, []).filter(func(t): return S.tick - int(t) <= int(F.window_ticks))
		var n: int = recent.size()
		if closing:
			gain += float(F.close_db)
		elif held_gap >= 0:
			var Hd: Dictionary = cfg.held
			gain += float(Hd.gain_db)
			pitch *= pow(2.0, maxf(float(Hd.pitch_min_st), float(Hd.pitch_st_per_tick) * float(maxi(held_gap - int(Hd.pitch_from_gap), 0))) / 12.0)
			if held_gap <= int(Hd.lite_gap_max) and F.has("lite"):
				sound = String(F.lite.sound)
		elif n >= int(F.after):
			gain += float(F.step_db)
			pitch *= pow(2.0, minf(float(F.climb_max_st), float(F.climb_st_per_blow) * float(n - int(F.after) + 1)) / 12.0)
			if F.has("lite") and n >= int(F.lite.after):
				sound = String(F.lite.sound)
		recent.append(S.tick)
		_lights[a] = recent
	elif st == "medium" and not guarded:
		var Gd: Dictionary = cfg.grind
		var rm: Array = _meds.get(a, []).filter(func(t): return S.tick - int(t) <= int(Gd.window_ticks))
		var nm: int = rm.size()
		if closing:
			gain += float(cfg.flurry.close_db)
		elif nm >= int(Gd.after):
			gain += float(Gd.step_db)
			pitch *= pow(2.0, -minf(float(Gd.max_drop_st), float(Gd.drop_st_per_blow) * float(nm - int(Gd.after) + 1)) / 12.0)
			sound = String(Gd.sound)
		rm.append(S.tick)
		_meds[a] = rm
	elif closing:
		gain += float(cfg.flurry.close_db)
	out.append(cues.make_cue(sound, float(e.x), float(e.y), gain, pitch, int(meta.priority), "Sfx", String(meta.cls), int(meta.cap), String(meta.caption), S))
	_last_hit[a] = S.tick
	var pf = _perfects.get(a)
	if pf != null:
		if S.tick > int(pf.n) + int(cfg.perfect.land.after):
			_perfects.erase(a)
		elif S.tick >= int(pf.n) - int(cfg.perfect.land.before):
			out.append_array(_perfect_note(S, pf, e))
			_perfects.erase(a)
	var v: int = int(e.victim)
	if not guarded and _winding.has(v) and bool(_winding[v].heavy) and (st == "light" or st == "medium"):
		var A: Dictionary = cfg.charge.armour
		var armoured: bool = st == "light" or int(_winding[v].live) > int(A.medium_after_live)
		if armoured:
			out.append(cues.make_cue(String(A.sound), float(e.x), float(e.y), float(A.gain_db), float(A.medium_pitch) if st == "medium" else 1.0, int(A.priority), "Sfx", String(A.cls), int(A.cap), "", S))
	return out


## A cue with no random spread in pitch or level, for the sounds that carry information (a note's pitch is its meaning).
func _fixed(sound: String, x: float, y: float, gain_db: float, pitch: float, priority: int, bus: String, cls: String, cap: int, caption: String = ""):
	var c = cues.Cue.new()
	c.sound = sound
	c.variant = 0
	c.x = x
	c.y = y
	c.gain_db = gain_db
	c.pitch = pitch
	c.priority = priority
	c.bus = bus
	c.cls = cls
	c.cap = cap
	c.caption = caption
	return c


## The AI's chain, heard by a human it is made against: its colour is the opponent's. (Two humans, or two AIs, share one.)
func _is_foe(S: SimState, a: int) -> bool:
	if a < 0 or S.fighters.size() < 2 or a >= S.fighters.size():
		return false
	return S.fighters[a].ai != null and S.fighters[1 - a].ai == null


func _family(S: SimState, a: int) -> Dictionary:
	return cfg.perfect.foe if _is_foe(S, a) else cfg.perfect.own


## A plain light's pose lets go and its window opens (k 1): a dry tick for the attacker, who has no hit to tap on. Every other
## window opens on the hit itself, which is the cue.
func _window_open(S: SimState, e, out: Array) -> void:
	if int(e.k) != 1:
		return
	var a: int = int(e.actor)
	if a < 0 or a >= S.fighters.size() or _is_foe(S, a):
		return
	var P: Dictionary = cfg.perfect
	var f = S.fighters[a]
	out.append(_fixed(String(P.tick.sound), f.x, f.y, float(P.tick.gain_db), 1.0, int(P.priority.tick), String(P.bus), String(P.cls.tick), int(P.cap.tick), String(P.tick.caption)))


## A tap inside the window: the follow-up is thrown. A spark at the tap, at the chain's note (the confirmation, and the
## defender's tell), and the note itself waits for the follow-up's hit. `k` is the chain's count with this perfect in it, `text`
## the follow-up's strength, `n` its landing tick, `source` "link" for a follow-up of another strength than the blow that landed.
func _perfect(S: SimState, e, out: Array) -> void:
	var a: int = int(e.actor)
	if a < 0 or a >= S.fighters.size():
		return
	var P: Dictionary = cfg.perfect
	var fam: Dictionary = _family(S, a)
	var k: int = maxi(int(e.k), 1)
	var ratio: float = float(fam.ratios[mini(k, fam.ratios.size()) - 1])
	var f = S.fighters[a]
	var spark = _fixed(String(fam.spark), f.x, f.y, float(P.gain_db.spark), ratio, int(P.priority.spark), String(P.bus), String(P.cls.spark), int(P.cap.spark))
	# a spark that lands on a hit's first 30 ms is buried by its transient (measured, beat_check): it waits until the hit's
	# transient is clear, which is `clear_ticks` after the hit (the last hit landed, or the one due in the next 3 ticks)
	var hit_at: int = int(_last_hit.get(a, -99))
	for b in _blows.get(a, []):
		if int(b.n) >= S.tick and int(b.n) <= S.tick + int(P.spark_clear.look_ahead):
			hit_at = maxi(hit_at, int(b.n))
	var wait: int = mini(hit_at + int(P.spark_clear.ticks) - S.tick, int(P.spark_clear.max_wait))
	if wait > 0:
		_pending.append({"actor": a, "wait": wait, "cue": spark, "what": "spark"})
	else:
		out.append(spark)
	_perfects[a] = {"n": int(e.n), "k": k, "text": String(e.text), "link": String(e.source) == "link", "foe": _is_foe(S, a)}


## The follow-up's own hit lands: the chain's note rides on it. The third (and a link that closes it) is the resolving chord.
func _perfect_note(S: SimState, pf: Dictionary, e) -> Array:
	var out: Array = []
	var P: Dictionary = cfg.perfect
	var fam: Dictionary = P.foe if bool(pf.foe) else P.own
	var k: int = int(pf.k)
	var closing: bool = k >= fam.ratios.size()
	var x: float = float(e.x)
	var y: float = float(e.y)
	if closing:
		out.append(_fixed(String(fam.close), x, y, float(P.gain_db.close), 1.0, int(P.priority.close), String(P.bus), String(P.cls.close), int(P.cap.close)))
	else:
		var sound: String = String(fam.note) if bool(pf.foe) else String(fam.by_strength.get(String(pf.text), fam.by_strength.light))
		out.append(_fixed(sound, x, y, float(P.gain_db.note), float(fam.ratios[k - 1]), int(P.priority.note), String(P.bus), String(P.cls.note), int(P.cap.note)))
	if bool(pf.link) and not bool(pf.foe):
		out.append(_fixed(String(P.link.sound), x, y, float(P.link.gain_db), 1.0 if closing else float(fam.ratios[k - 1]), int(P.priority.note), String(P.bus), String(P.cls.link), int(P.cap.link)))
	return out


## The string goes on, the chain does not: a quiet downward droop from the last note. Silent for a lapse (90 ticks) and for a
## count of nothing; there is no buzzer.
func _chain_broken(S: SimState, e, out: Array) -> void:
	var a: int = int(e.actor)
	if a < 0 or a >= S.fighters.size():
		return
	var text: String = String(e.text)
	if text == "stopped" or text == "staggered":
		_perfects.erase(a)      # its follow-up is not going to land
	var B: Dictionary = cfg.perfect.broken
	var k: int = int(e.k)
	if k < 1 or not (text in B.texts):
		return
	var fam: Dictionary = _family(S, a)
	var ratio: float = float(fam.ratios[mini(k, fam.ratios.size()) - 1])
	var f = S.fighters[a]
	var P: Dictionary = cfg.perfect
	out.append(_fixed(String(B.sound), f.x, f.y, float(B.gain_db), ratio, int(P.priority.break), String(P.bus), String(P.cls.break), int(P.cap.break)))


## An opening that will not launch (the launcher rests): a dull knock where the ping would have been, so a player learns
## that the missing ping means "not now" and not "I missed it".
func _launcher_rest(S: SimState, e, out: Array) -> void:
	var R: Dictionary = cfg.rest
	var t: int = int(e.target)
	if t < 0 or t >= S.fighters.size():
		t = int(e.actor)
	if t < 0 or t >= S.fighters.size():
		return
	var f = S.fighters[t]
	out.append(cues.make_cue(String(R.sound), f.x, f.y, float(R.gain_db), 1.0, int(R.priority), "Sfx", String(R.cls), int(R.cap), String(R.caption), S))
