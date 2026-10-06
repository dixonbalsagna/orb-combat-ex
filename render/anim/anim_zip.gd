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
	# an entry of his own played at the zip's speed over the way in or out (Combat's rows name them: spiral in, pivot out), and a far-side pass by name (over, round)
	z["entry_in"] = String(spec.get("entry_in", row.get("entry_in", "")))
	z["entry_out"] = String(spec.get("entry_out", row.get("entry_out", "")))
	var pas: String = String(spec.get("pass", ""))
	if pas != "" and z.entry_out == "":
		z["entry_out"] = String(AnimData.zip.get("pass", {}).get(pas, ""))
	z["T1"] = float(z.tell)
	z["T2"] = float(z.tell + z.inn)
	z["T3"] = float(z.T2 + z.ho + z.hits * z.hd)
	z["T4"] = float(z.T3 + z.out)
	af._zip = z
	af._zip_tilt = 0.0


## The zip ends early (caught in reach, countered on arrival, cancelled, outrun): the body leaves it to the hit reaction or the stance.
static func end(af: AnimFighter, reason: String, T: float) -> void:
	af._zip_last_end = reason
	af._zip_end = {"reason": reason, "T": T}   # the live zip (the read is its truth) takes its end look from this when the read goes empty
	if af._zip.is_empty() or bool(af._zip.get("live", false)):
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


## The fighter's own entry sequence for a name ("spiral" or "entry.spiral"), "" when he has none (the zip then plays its run and back-step poses).
static func _entry_id(af: AnimFighter, name: String) -> String:
	if name == "":
		return ""
	return AnimData.resolve_entry(af.pair_key, name if name.begins_with("entry.") else "entry." + name)


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


## The zip's phase from the director's own read (DirZip.read: the truth; zip.md sections 9 and 12): the plan, the live tick the phase has run, the exit and the pass once the blow has landed. `tk` is the
## zip's own tick (the tell, the way in, the ticks in reach and the way out counted in the sim's live ticks, so a hit-stop does not move it), `t0` the sim time it would have begun at.
static func _from_read(af: AnimFighter, r: Dictionary, T: float) -> Dictionary:
	var z: Dictionary = af._zip if bool(af._zip.get("live", false)) else {}
	var tell: int = int(r.tell)
	var inn: int = int(r["in"])
	var hd: int = int(r.hd)
	var out: int = int(r.out)
	var n: int = int(r.n)
	var ph: String = String(r.phase)
	var tk: float = float(n)
	if ph == "in":
		tk += float(tell)
	elif ph == "reach":
		tk += float(tell + inn)
	elif ph == "out":
		tk += float(tell + inn + hd)
	var sim_rd: String = String(r.reading)   # the sim's reading: speed, tech or heavy (the held one)
	var rd: String = "heavy" if String(r.btn) == "y" else ("tech" if sim_rd == "tech" else "speed")   # the body's look: a zip heavy (Y) is the coil, the stretched lunge and the smear; a zip strike is the run, or the clean dash when timed
	var row: Dictionary = AnimData.zip.readings.get(rd, {})
	z["live"] = true
	z["reading"] = rd
	z["sim_reading"] = sim_rd
	z["btn"] = String(r.btn)
	z["tell"] = tell
	z["inn"] = inn
	z["hits"] = 1
	z["hd"] = hd
	z["ho"] = 0
	z["out"] = out
	z["T1"] = tell
	z["T2"] = tell + inn
	z["T3"] = tell + inn + hd
	z["T4"] = tell + inn + hd + out
	z["tk"] = tk
	z["t0"] = T - tk * DT
	z["blow"] = int(r.blow)
	z["exit"] = String(r.exit)
	var pas: String = String(r.get("pass", ""))
	z["pass"] = pas
	z["entry_in"] = String(r.get("entry_in", "")) if String(r.get("entry_in", "")) != "" else String(row.get("entry_in", ""))
	var eo: String = String(r.get("entry_out", ""))
	if eo == "" and pas != "":
		eo = String(AnimData.zip.get("pass", {}).get(pas, ""))
	z["entry_out"] = eo if eo != "" else String(row.get("entry_out", ""))
	z["via"] = String(r.via) if String(r.via) != "" else "auto"
	z["dist_bh"] = float(r.get("dist_bh", 0.0))
	af._zip = z
	af._zblend = {}
	return z


## The read went empty: the zip is over (the way out ran out, or the cue zip_end named another end). The body does not jump to its stance: the last zip pose is blended away over the reason's ticks
## (data/anim/zip.json `ends`), and an outrun zipper is carried past off balance (the whiff he already has).
static func _finish(af: AnimFighter, T: float) -> void:
	var reason: String = String(af._zip_end.get("reason", "done"))
	var E: Dictionary = AnimData.zip.get("ends", {}).get(reason, AnimData.zip.get("ends", {}).get("done", {}))
	var n: int = int(E.get("blend", 4))
	af._zip = {}
	af._zip_end = {}
	af._zip_last_end = reason
	if n > 0 and af._zq.size() == AnimRig.N:
		af._zblend = {"t0": T, "n": n, "q": af._zq, "hips": af._zh0, "curl": af._zc0}
	if bool(E.get("overcommit", false)):
		af._over_commit(T, af._rd_amp())


## The carry from the last zip pose into whatever the body does next (a stance, a reaction): a smoothed mix over the ticks `_finish` set.
static func _blend_end(af: AnimFighter, T: float) -> void:
	var b: Dictionary = af._zblend
	if b.is_empty():
		return
	var k: float = (T - float(b.t0)) / (float(b.n) * DT)
	if k >= 1.0:
		af._zblend = {}
		return
	var w: float = 1.0 - smoothstep(0.0, 1.0, maxf(k, 0.0))
	AnimPose.mix(af.q, b.q, w)
	af.hips = af.hips.lerp(b.hips, w)
	af.curl = af.curl.lerp(b.curl, w)


## The zip's layers for this solve, under the exchange's strike block (which goes over them in the reach phase).
static func layers(af: AnimFighter, S: SimState, f, T: float, dt: float) -> void:
	af.zip = {}
	af._zip_dy = 0.0
	af._zip_depth = 0.0
	if not on():
		af._zip = {}
		af._zh = {}
		af._zblend = {}
		af._zip_end = {}
		return
	if not af._zh.is_empty():
		_held_layer(af, T)
	# the read only once the zip module has sized his state (DirZip._g would size it itself: a read must not write the sim, or a rendered run would differ from the sim alone)
	var r: Dictionary = DirZip.read(S, f) if (S != null and f != null and f.act.dirI.size() >= DirZip.END) else {}
	var z: Dictionary
	var tk: float
	var ph: String
	if not r.is_empty():
		z = _from_read(af, r, T)
		tk = float(z.tk)
		ph = String(r.phase)
	elif not af._zip.is_empty() and bool(af._zip.get("live", false)):
		_finish(af, T)
		_blend_end(af, T)
		return
	else:
		_blend_end(af, T)
		z = af._zip
		if z.is_empty():
			return
		tk = (T - float(z.t0)) / DT
		ph = phase_of(z, tk)
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
			var eid_in: String = _entry_id(af, String(z.entry_in))
			if eid_in != "":
				var t_in: float = float(z.t0) + float(z.T1) * DT
				af._entry_layer(t_in, float(z.inn) * DT, eid_in, T, DT, 1.0, true)
			else:
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
			elif bool(z.get("live", false)) and int(z.get("blow", 0)) == 0:
				# the blow lands 4 (a strike) or 12 (a heavy) ticks after he arrives, and the strike block's own wind-up is cut to 2 or 3: until it starts he stands in his arrival (the travel pose settled toward the tell, the stretch released)
				var sl: float = float(AnimData.zip.get("arrival", {}).get("settle", 0.4))
				_mix(af, String(row.tell_pose), sl * 0.9)
				_mix(af, String(row.travel_pose), 1.0 - sl)
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
			var eid_out: String = _entry_id(af, String(z.entry_out))
			if eid_out != "":
				var t_out: float = float(z.t0) + float(z.T3) * DT
				af._entry_layer(t_out, float(z.out) * DT, eid_out, T, DT, 1.0, true)
			elif via == "back":
				_mix(af, "back", w2 * 0.9)
				_mix(af, "back_travel", w2 * smoothstep(0.1, 0.5, v) * 0.7)
			else:
				travelling = true
				_mix(af, "run_clean" if rd == "tech" else String(AnimData.zip.readings.speed.travel_pose), w2)
			# a pass (over, round, under the rival): the body is drawn in front of him, a render-only offset toward the camera, in and out over the data's ticks
			if String(z.get("pass", "")) != "":
				var PD: Dictionary = AnimData.zip.get("pass_depth", {})
				if not PD.is_empty():
					var tt: float = maxf(float(PD.get("ticks", 3)), 1.0)
					var nn: float = tk - float(z.T3)
					af._zip_depth = float(PD.get("z", 0.0)) * minf(smoothstep(0.0, tt, nn), smoothstep(0.0, tt, float(z.out) - nn))
		"settle":
			pass
	af.zip = {"reading": rd, "style": rd if rd == "speed" or rd == "tech" or rd == "heavy" else ("heavy" if rd == "hold" else "speed"), "btn": String(z.btn), "phase": ph, "tick": roundi(tk), "via": String(z.get("via_now", z.via)), "ghosts": int(row.get("ghosts", 0)),
		"smear": smear, "travelling": travelling, "ticks_to_arrival": roundi(float(z.T2) - tk), "reach_ticks": int(z.ho + z.hits * z.hd), "hits": int(z.hits), "tilt": af._zip_tilt, "bone": "hand_r",
		"live": bool(z.get("live", false)), "sim_reading": String(z.get("sim_reading", rd)), "blow": int(z.get("blow", 0)), "exit": String(z.get("exit", "")), "pass": String(z.get("pass", "")), "depth": af._zip_depth}
	af._zip_phase = ph
	if bool(z.get("live", false)):
		af._zq = af.q.duplicate()
		af._zh0 = af.hips
		af._zc0 = af.curl


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
	af.root_off.z += af._zip_depth
	var bowed: bool = f != null and f.rush != null and float(f.rush.arc) != 0.0
	if bowed or (not af.zip.is_empty() and bool(af.zip.get("travelling", false))):
		var vm: Vector2 = af._lead_measure(S, f)
		if bowed:
			vm = _tangent_v(S, f)
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


## The direction and speed of a bowed rush, from the sim's own step (SimFighter.rushU and rushAt: the render cannot disagree with the bow's shape or its sign): the path's tangent at where he is, units a second.
static func _tangent_v(S: SimState, f) -> Vector2:
	var u: float = SimFighter.rushU(S, f)
	var u0: float = maxf(u - 0.05, 0.0) if u > 0.94 else u
	var u1: float = minf(u0 + 0.05, 1.0)
	var a: PackedFloat64Array = SimFighter.rushAt(S, f, u0)
	var b: PackedFloat64Array = SimFighter.rushAt(S, f, u1)
	var d := Vector2(SimWrap.sdx(a[0], b[0]), b[1] - a[1])
	var secs: float = maxf(float(f.rush.dur) * (u1 - u0), 0.001)
	return d / secs
