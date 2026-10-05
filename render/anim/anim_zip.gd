class_name AnimZip
extends RefCounted
## The body of the LT zip (docs/animation/zip.md; data/anim/zip.json; Orb's prototype docs/ep/prototypes/lt-zip-v4.html). Render only, behind RenderAnim.press_styles.
## The sim moves the fighter along the zip (the way in, the way out); this plays what the body does on the way: the tell (a crouch along the line; the heavy's wind-up
## squash), the travel pose of the reading (speed: a low run; tech: a fast, upright, clean dash; heavy: a stretched lunge with a smear frame), every one drawn travelling on every tick (Legal RL-076), the strike (the fighter's own
## key sets, played by the exchange's strike block with its press-style reading and a wind-up cut to nothing, since the tell was the wind-up), the way out (a back-step, or
## a run through, up or down: the body turns along its path), the A button's tackle carry and its lift and throw, and the held fighter's own pose. A zip is told to the body by
## AnimFighter.on_zip(spec, T) where the spec has: reading (speed, tech, heavy, press = the tackle, hold = the lift and throw), btn (x, y, b, a), and optionally tell, inn, hits,
## hd, out (ticks, else the reading's defaults in data/anim/zip.json), via (back, through, up, down, away: the way out), t0 (sim seconds; else now). What it exposes for VFX is
## AnimFighter.zip (the phase and the look) beside the press hand-off (press_pose(k): the pose k solves back with the fighter's world position; zip_path: where he was).
const DT := 1.0 / 60.0


static func on() -> bool:
	return RenderAnim.press_styles and not AnimData.zip.is_empty() and bool(AnimData.zip.get("enabled", true))


## The spec with the reading's defaults filled in, and the phase boundaries in ticks from the zip's start.
static func start(af: AnimFighter, spec: Dictionary, T: float) -> void:
	if not on():
		return
	var rd: String = String(spec.get("reading", "speed"))
	var row: Dictionary = AnimData.zip.get("readings", {}).get(rd, {})
	if row.is_empty():
		return
	var z: Dictionary = spec.duplicate()
	z["reading"] = rd
	for k in ["tell", "in", "hits", "hd", "out"]:
		var key: String = "inn" if k == "in" else k
		z[key] = int(spec.get(key, spec.get(k, row.get(k, 0))))
	z["ho"] = int(spec.get("ho", row.get("lift", 0)))
	z["t0"] = float(spec.get("t0", T))
	z["via"] = String(spec.get("via", "auto"))   # auto: a back-step if the sim moves him away from the rival on the way out, a run otherwise (up, down, through, around)
	z["btn"] = String(spec.get("btn", "x"))
	z["T1"] = float(z.tell)
	z["T2"] = float(z.tell + z.inn)
	z["T3"] = float(z.T2 + z.ho + z.hits * z.hd)
	z["T4"] = float(z.T3 + z.out)
	af._zip = z
	af._zip_tilt = 0.0


## The zip ends early (caught in reach, countered on arrival, cancelled, outrun): the body leaves it to the hit reaction or the stance.
static func end(af: AnimFighter, reason: String, T: float) -> void:
	if af._zip.is_empty():
		return
	af._zip["ended"] = reason
	af._zip["T_end"] = T


## The fighter is held by a zip: carried by a tackle or lifted by a held A (`kind` carried or lifted) for `dur` seconds from T.
static func held(af: AnimFighter, kind: String, T: float, dur: float) -> void:
	if not on():
		return
	af._zh = {"kind": kind, "t0": T, "dur": dur}


static func _pose_id(af: AnimFighter, name: String) -> String:
	if name == "":
		return ""
	var P: Dictionary = AnimData.zip.get("poses", {})
	var id: String = String(P.get("shared", {}).get(name, ""))
	if id == "":
		id = String(P.get(af.pair_key, P.get("default", {})).get(name, ""))
	if id == "" or not AnimData.pose_exists(id):
		id = String(P.get("default", {}).get(name, ""))
	return id if AnimData.pose_exists(id) else ""


static func _mix(af: AnimFighter, name: String, w: float) -> void:
	if w <= 0.001:
		return
	var id: String = _pose_id(af, name)
	if id != "":
		af._mix_pose(AnimData.pose(id), w)


## The heavy's squash and the way in's stretch, with the press styles' joint-safe means (legs, pelvis and spine toward a crouch pose; the spine and the head a few hundredths of a radian).
static func _squash(af: AnimFighter, row: Dictionary, s: float) -> void:
	if s <= 0.001:
		return
	var ix: Dictionary = AnimRig.index
	var sp: Dictionary = AnimData.press.get("squash_pose", {})
	var pid: String = String(sp.get("by_fighter", {}).get(af.pair_key, sp.get("default", "brace")))
	if AnimData.pose_exists(pid):
		var spp: AnimPose = AnimData.pose(pid)
		for bn in sp.get("bones", []):
			var bi: int = ix[String(bn)]
			af._press_slerp(bi, spp.q[bi], s)
		af.hips.y = minf(af.hips.y, lerpf(af.hips.y, spp.hips.y, s))
	var lean: float = float(row.get("lean", 0.0)) * s
	af.q[ix["spine_1"]] = af.q[ix["spine_1"]] * Quaternion(Vector3(0, 0, 1), lean * 0.5)
	af.q[ix["spine_2"]] = af.q[ix["spine_2"]] * Quaternion(Vector3(0, 0, 1), lean * 0.5)
	af.q[ix["head"]] = af.q[ix["head"]] * Quaternion(Vector3(0, 0, 1), -lean * 0.5)
	af._pr_dx -= 2.4 * s


static func _stretch(af: AnimFighter, st: Dictionary, e: float) -> void:
	if e <= 0.001:
		return
	var ix: Dictionary = AnimRig.index
	var ext: float = float(st.get("spine", 0.0)) * e
	af.q[ix["spine_1"]] = af.q[ix["spine_1"]] * Quaternion(Vector3(0, 0, 1), -ext * 0.5)
	af.q[ix["spine_2"]] = af.q[ix["spine_2"]] * Quaternion(Vector3(0, 0, 1), -ext * 0.5)
	af.q[ix["head"]] = af.q[ix["head"]] * Quaternion(Vector3(0, 0, 1), ext * 0.4)
	af.hips.y += float(st.get("rise", 0.0)) * e
	af._pr_dx += float(st.get("lead", 0.0)) * e


static func phase_of(z: Dictionary, tk: float) -> String:
	if tk < 0.0:
		return ""
	if tk < float(z.T1):
		return "tell"
	if tk < float(z.T2):
		return "in"
	if tk < float(z.T3):
		return "reach"
	if tk < float(z.T4):
		return "out"
	if tk < float(z.T4) + 8.0:
		return "settle"
	return ""


## The zip's layers for this solve, under the exchange's strike block (which goes over them in the reach phase).
static func layers(af: AnimFighter, S: SimState, f, T: float, dt: float) -> void:
	af.zip = {}
	af._zip_dy = 0.0
	if not on():
		af._zip = {}
		af._zh = {}
		return
	if not af._zh.is_empty():
		_held_layer(af, T)
	var z: Dictionary = af._zip
	if z.is_empty():
		return
	var tk: float = (T - float(z.t0)) / DT
	var ph: String = phase_of(z, tk)
	if z.has("ended") and T >= float(z.T_end):
		ph = ""
	if ph == "":
		if tk > float(z.T4) + 8.0 or z.has("ended"):
			af._zip = {}
		return
	var rd: String = String(z.reading)
	var row: Dictionary = AnimData.zip.readings[rd]
	var heavy: bool = rd == "heavy" or rd == "hold"
	var smear: bool = false
	var travelling: bool = false
	var pstyles: Dictionary = AnimData.press.get("styles", {})
	match ph:
		"tell":
			var k: float = smoothstep(0.0, 1.0, tk / maxf(float(z.tell), 1.0))
			if heavy:
				_mix(af, String(row.tell_pose), k * 0.9)
				_squash(af, row, k * float(row.get("squash", 0.0)))
			else:
				_mix(af, String(row.tell_pose), k * 0.9)
		"in":
			var u: float = clampf((tk - float(z.T1)) / maxf(float(z.inn), 1.0), 0.0, 1.0)
			af._skip_inertia = true
			travelling = true
			var w: float = smoothstep(0.0, 0.3, u) * (1.0 - 0.4 * smoothstep(0.8, 1.0, u))
			_mix(af, String(row.tell_pose), (1.0 - w) * 0.9)
			_mix(af, String(row.travel_pose), w)
			if rd == "heavy":
				var st: Dictionary = row.get("stretch", {})
				_stretch(af, st, 1.0)
				smear = u >= 1.0 - 1.5 / maxf(float(z.inn), 1.0)
		"reach":
			var st2: float = tk - float(z.T2)
			if rd == "press":
				_mix(af, String(row.hold_pose), smoothstep(0.0, 4.0, st2))
			elif rd == "hold":
				if st2 < float(z.ho):
					_mix(af, String(row.hold_pose), smoothstep(0.0, float(z.ho) * 0.6, st2))
				else:
					_mix(af, String(row.throw_pose), smoothstep(0.0, 3.0, st2 - float(z.ho)))
		"out":
			var v: float = clampf((tk - float(z.T3)) / maxf(float(z.out), 1.0), 0.0, 1.0)
			af._skip_inertia = true
			var via: String = String(z.via)
			if via == "auto":
				via = String(z.get("via_now", "back"))
				if not z.has("via_now"):
					var vm: Vector2 = af._lead_measure(S, f)
					if vm.length() > 200.0:
						z["via_now"] = "back" if vm.x * af.vface < -0.5 * vm.length() else "run"
			var w2: float = 1.0 - smoothstep(0.6, 1.0, v)
			if via == "back":
				_mix(af, "back", w2 * 0.9)
				_mix(af, "back_travel", w2 * smoothstep(0.1, 0.5, v) * 0.7)
			else:
				travelling = true
				_mix(af, "run_clean" if rd == "tech" else String(AnimData.zip.readings.speed.travel_pose), w2)
		"settle":
			pass
	af.zip = {"reading": rd, "style": rd if rd == "speed" or rd == "tech" or rd == "heavy" else ("heavy" if rd == "hold" else "speed"), "btn": String(z.btn), "phase": ph, "tick": roundi(tk), "via": String(z.get("via_now", z.via)), "ghosts": int(row.get("ghosts", 0)),
		"smear": smear, "travelling": travelling, "ticks_to_arrival": roundi(float(z.T2) - tk), "reach_ticks": int(z.ho + z.hits * z.hd), "hits": int(z.hits), "tilt": af._zip_tilt, "bone": "hand_r"}
	af._zip_phase = ph


## A pose held for the fighter a zip holds, and the lift's cosmetic rise.
static func _held_layer(af: AnimFighter, T: float) -> void:
	var h: Dictionary = af._zh
	var t: float = T - float(h.t0)
	if t < 0.0:
		return
	if t > float(h.dur) + 0.2:
		af._zh = {}
		return
	var rd: Dictionary = AnimData.zip.readings.get("press" if String(h.kind) == "carried" else "hold", {})
	var w: float = smoothstep(0.0, 0.08, t) * (1.0 - smoothstep(float(h.dur), float(h.dur) + 0.2, t))
	_mix(af, String(rd.get("held_pose", "carried")), w)
	if String(h.kind) == "lifted":
		af._zip_dy = float(AnimData.zip.get("carry", 26.0)) * smoothstep(0.0, 0.3, t) * (1.0 - smoothstep(float(h.dur) - 0.1, float(h.dur) + 0.1, t))


## The body turns along its path, up or down as well as along: after the lead layer, so the lead does not stand it back up. Only while a zip's way in or out is the fast part.
static func orient(af: AnimFighter, S: SimState, f, dt: float) -> void:
	var want: float = 0.0
	var O: Dictionary = AnimData.zip.get("orient", {})
	if not af.zip.is_empty() and bool(af.zip.get("travelling", false)):
		var vm: Vector2 = af._lead_measure(S, f)
		if vm.length() > float(O.get("speed", 700.0)):
			var al: float = atan2(vm.y, maxf(absf(vm.x), 1.0))
			if vm.x * af.vface < 0.0:
				al = atan2(vm.y, -vm.x * af.vface)   # backing out: the angle from the facing direction, not from the travel
			want = clampf(al, -float(O.get("max", 1.2)), float(O.get("max", 1.2))) * float(O.get("gain", 0.85))
	af._zip_tilt += (want - af._zip_tilt) * (1.0 - exp(-dt * float(O.get("rate", 18.0))))
	if absf(af._zip_tilt) < 0.002:
		return
	var phi: float = af._zip_tilt
	af.q[0] = Quaternion(Vector3(0, 0, 1), phi) * af.q[0]
	var py: float = float(AnimData.flight.get("pivot_y", 34.0))
	af.root_off += Vector3(py * sin(phi), py * (1.0 - cos(phi)), 0.0)
