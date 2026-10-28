class_name AnimData
extends RefCounted
## Loads and bakes the animation data in data/anim/ (poses, key sets, timing profiles, the cue map) once. Render only:
## nothing here is read by the sim, and the files sit outside the sim's data hash (tools/validate.js guards that).
## Poses are baked from their sketch form (anim_pose.gd); the far-side (mirrored) variant of each is made on first use.

const DIR := "res://data/anim/"

static var loaded: bool = false
static var poses: Dictionary = {}       # id -> AnimPose (the near-side version)
static var mirrors: Dictionary = {}     # id -> AnimPose (the mirrored version), made lazily
static var keysets: Dictionary = {}
static var picks: Dictionary = {}
static var profiles: Dictionary = {}
static var default_profile: String = "snappy"
static var by_part: Dictionary = {}          # part kind (light, heavy, chain, rush, launch, power) -> profile name
static var zip: Dictionary = {}             # data/anim/zip.json: the body of the LT zip (phases, poses, the look of each reading; used only with RenderAnim.press_styles)
static var tips: Dictionary = {}            # data/anim/tips.json: the striking surface of a blow (the hand closes to a fist or opens to a blade), the re-aim table
static var medium_wind: Dictionary = {}    # data/anim/medium_wind.json: Combat's eight rules for a medium on a 12-tick wind-up, by key set (used only with RenderAnim.press_styles and RenderAnim.medium_wind)
static var press: Dictionary = {}           # data/anim/press_styles.json: how the three press styles move the body through a strike (used only with RenderAnim.press_styles)
static var bone_lag := PackedFloat32Array()
static var cue_poses: Dictionary = {}   # cue kind -> pose id
static var forms: Dictionary = {}       # transformation: version -> {gather, break, settle, hold} in ticks
static var quality_levels: Dictionary = {}   # level -> the overhaul layers it switches off
static var winner: Dictionary = {}          # data/anim/winner.json (the winner after a KO)
static var personality: Dictionary = {}
static var ragdoll_motion: Dictionary = {}
static var ragdoll: Dictionary = {}      # data/anim/ragdoll.json (read by AnimRagdoll.setup)
static var form_poses: Dictionary = {}  # beat -> pose id
static var load_waves: bool = false      # --waves: also bake the parked pose waves of data/anim/waves/ (tools only; no live match plays them)
static var raw: Dictionary = {}         # id -> the sketch each pose was baked from (poses.json, and the waves when loaded)
static var last_stand: Dictionary = {}   # data/anim/laststand.json: the ready sequence of each shape, the held resolve and the slump
static var fighters_cfg: Dictionary = {}   # data/anim/fighters.json: each fighter's shape, profile and waves (docs 9.25)
static var pair: Dictionary = {}           # data/anim/pair_live.json: how the launch pair's waves play live (docs/animation/pair-live.md)
static var pair_lists: Dictionary = {}     # fighter key -> {light, heavy, gated: [{id, weight, gate}], entries: {name: id}}: his own pick lists and entries, built when his waves are baked
static var pair_bake_usec: int = 0         # microseconds spent baking fighters' waves in this run (the match-start cost)
static var pair_bake_poses: int = 0
static var _waves_done: Dictionary = {}
static var lazy: bool = false             # the incremental bake (docs/animation/incremental-bake.md): load_all and ensure_fighter register every pose and queue its bake; the queue is drained a few milliseconds a tick, and a pose asked for first is baked on the spot. On in the game (no -s script), off in the tools; --lazy-bake and --eager-bake force it
static var _pend: Dictionary = {}          # id -> the sketch not yet baked
static var _pend_order: Array = []         # the ids in the order they are baked
static var _pend_head: int = 0
static var _work: Array = []               # the fighters' wave loads and pick-list builds not yet done, in order: {k: wave, wn} and {k: lists, key, names}
static var _queued: Dictionary = {}        # fighter key -> true once his work is queued
static var bake_drains: int = 0            # times something asked for a pose that was not there while waves were still queued, and the queue was run to the end
static var bake_slice_us: int = 4000       # data/anim/pair_live.json bake.slice_us: the most a drawn frame spends baking while the intro plays
static var bake_play_us: int = 1500        # bake.play_us: the same once the intro is over (the fight is on screen)
static var bake_over_ms: int = 20          # bake.over_ms: a frame longer than this (since the last slice) is over budget
static var bake_over_us: int = 500         # bake.over_us: the most a slice spends when the frame is over budget (one piece at least)
static var bake_deferred: int = 0          # poses the incremental bake queued in this run
static var bake_demand: int = 0            # of them baked on the spot because something asked first
static var bake_worst_us: int = 0          # the longest single slice or on-demand bake
static var flight: Dictionary = {}       # data/anim/flight.json: the flight lead, a launched body turned head first along its velocity (docs 9.23)
static var agency: Dictionary = {}       # data/anim/agency.json: how the agency slice's events (knockback, embed, taunt, charges) map to poses
static var intro: Dictionary = {}        # data/anim/intro.json: the opening's timings and each shape's staredown beat
static var brake: Dictionary = {}        # data/anim/brake.json: the mid-air skid (docs/animation/ragdoll-physics-paper.md section 3a)
static var clinch: Dictionary = {}       # data/anim/clinch.json: the clinch's grip layer (docs/animation/clinch-sizing.md slice C2)
static var throws: Dictionary = {}       # data/anim/throws.json: the thrower's sequence for each send, by fighter (played from the grapple's end cue)
static var grip_feed: Dictionary = {}    # data/anim/grip_feed.json: the grip fed from the sim as five stages (the grade steps, the pummel, the set and the cave)
static var struggle: Dictionary = {}     # data/anim/struggle.json: the beam struggle's dig-in (the loser's legs, pelvis and drag, the winner's lean)
static var reactions: Dictionary = {}      # data/anim/reactions.json: hit reactions with variety (variants by weight, direction and body part, and their recoveries)
static var pop: Dictionary = {}            # data/anim/pop.json: the phases of the pop (up, slam, burst, land) drawn from Encounter's cue
static var secondary: Dictionary = {}      # data/anim/secondary.json: follow-through of the head, upper back and forearms
static var ground_motion: Dictionary = {}  # data/anim/ground_motion.json: ground locomotion (the gait, the kick-off, the landing by surface)
static var locomotion: Dictionary = {}    # data/anim/locomotion.json: flight locomotion (the lean spring, the braking flare, the dash's coil, the bank, the hover's breath)
static var press_ack: Dictionary = {}    # data/anim/press_ack.json: the anticipation of a press that has to wait (Encounter's press_ack queued)
static var recoil: Dictionary = {}       # data/anim/recoil.json: recoil exits and ricochets (docs/combat/choreography-feel.md)
static var chain: Dictionary = {}        # data/anim/chain.json: the chain inside a tower (docs/animation/ragdoll-physics-paper.md section 4)
static var ground: Dictionary = {}       # data/anim/ground.json: how ground contact scales its poses (surface, speed, hold times)
static var cue_map: Dictionary = {}      # data/anim/waves/step3.cues.json: cue kind -> {actor, other, other_if_shoved} sequence ids (only with --step3-cues)
static var live: Dictionary = {}         # data/anim/waves/wave1.live.json: the go-live step 1 pick lists, gates and shapes (used only with --wave1-live)
static var entries: Dictionary = {}      # parked entry sequences (data/anim/waves/*.entries.json): id -> {phases: [{pose, ticks}]}; played by an `entry` beat
static var wave_of: Dictionary = {}     # pose id -> the wave file it came from
static var shapes: Dictionary = {}      # data/anim/shapes.json: shape key -> {idle, hit} tuning
static var sockets: Dictionary = {}     # data/anim/sockets.json (regions a blow lands on, limbs that land it)
static var target_fix: Dictionary = {}    # data/anim/targets.json: pose id -> the hand or foot targets that replace the authored ones (re-aimed after the joint limits)
static var effector_poses: Dictionary = {}   # data/anim/effectors.json: pose id -> authored clavicle hunch


static var read_usec: int = 0               # microseconds spent reading and parsing the animation data files in this run
static var read_n: int = 0
static var read_biggest: Dictionary = {}


static func _read(name: String) -> Dictionary:
	var t0: int = Time.get_ticks_usec()
	var txt: String = FileAccess.get_file_as_string(DIR + name)
	if txt == "":
		push_error("AnimData: cannot read " + DIR + name)
		return {}
	var j = JSON.parse_string(txt)
	var dt: int = Time.get_ticks_usec() - t0
	read_usec += dt
	read_n += 1
	read_biggest[name] = dt
	return j if typeof(j) == TYPE_DICTIONARY else {}


static func load_all() -> void:
	if loaded:
		return
	loaded = true
	var cla: PackedStringArray = OS.get_cmdline_args()
	var cua: PackedStringArray = OS.get_cmdline_user_args()
	lazy = not (cla.has("-s") or cla.has("--script")) and not cua.has("--eager-bake")
	if cua.has("--lazy-bake"):
		lazy = true
	AnimRig.setup()
	var ej: Dictionary = _read("effectors.json")
	var hj: Dictionary = ej.get("hunch", {})
	AnimPose.hunch_auto = bool(hj.get("auto", true)) and not OS.get_cmdline_user_args().has("--nohunch")
	AnimPose.hunch_fwd_max = float(hj.get("fwd_max", 2.5))
	AnimPose.hunch_up_max = float(hj.get("up_max", 2.0))
	effector_poses = ej.get("poses", {})
	sockets = _read("sockets.json")
	target_fix = _read("targets.json").get("poses", {})
	var tp: Dictionary = _read("target_poles.json").get("poses", {})
	for pid in tp:
		var row: Dictionary = target_fix.get(pid, {})
		for k in tp[pid]:
			row[k] = tp[pid][k]
		target_fix[pid] = row
	AnimJoints.setup(_read("joints.json"))
	shapes = _read("shapes.json").get("shapes", {})
	ground = _read("ground.json")
	intro = _read("intro.json")
	flight = _read("flight.json")
	agency = _read("agency.json")
	var ck: Array = ["taunt_start", "charge_light", "charge_heavy", "charge_feint"]   # the cues the agency layer listens to: these, and the ones that end a taunt or a charge
	ck.append_array(agency.get("taunt", {}).get("cut_kinds", []))
	ck.append_array(agency.get("charge", {}).get("end_kinds", []))
	agency["cue_kinds"] = ck
	last_stand = _read("laststand.json")
	if live_flag_early() and FileAccess.file_exists(DIR + "waves/wave1.live.json"):
		live = _read("waves/wave1.live.json")
	var pj: Dictionary = _read("poses.json")
	var src: Dictionary = pj.get("poses", {})
	for id in src:
		var sk: Dictionary = src[id]
		if effector_poses.has(id) and AnimPose.hunch_auto:
			sk = sk.duplicate()
			for sd in ["r", "l"]:
				if effector_poses[id].has(sd):
					sk["hunch_" + sd] = effector_poses[id][sd]
		sk = _fixed(id, sk)
		raw[id] = sk
		if lazy:
			_queue(id, sk)
		else:
			poses[id] = AnimPose.bake(id, sk)
	var kj: Dictionary = _read("keysets.json")
	keysets = kj.get("keysets", {})
	picks = kj.get("picks", {})
	var live_flag: bool = OS.get_cmdline_user_args().has("--wave1-live")
	var l_flag: bool = RenderAnim.last_stand_poses and not OS.get_cmdline_user_args().has("--no-last-stand-poses")
	var a_flag: bool = RenderAnim.agency_poses and not OS.get_cmdline_user_args().has("--no-agency-poses")
	var i_flag: bool = RenderAnim.intro_poses and not OS.get_cmdline_user_args().has("--no-intro-poses")
	var g_flag: bool = RenderAnim.ground_poses and not OS.get_cmdline_user_args().has("--no-ground-poses")
	var b_flag: bool = RenderAnim.air_brake and not OS.get_cmdline_user_args().has("--no-air-brake")
	var c_flag: bool = RenderAnim.chain_poses and not OS.get_cmdline_user_args().has("--no-chain-poses")
	var r_flag: bool = RenderAnim.recoil_flips and not OS.get_cmdline_user_args().has("--no-recoil-flips")
	var p_flag: bool = RenderAnim.press_ack and not OS.get_cmdline_user_args().has("--no-press-ack")
	var q_flag: bool = RenderAnim.grip_feed and not OS.get_cmdline_user_args().has("--no-grip-feed")
	var k_flag: bool = RenderAnim.grip_layer and not OS.get_cmdline_user_args().has("--no-grip-layer")
	var s3_flag: bool = (OS.get_cmdline_user_args().has("--step3-cues") or RenderAnim.step3_cues) and not OS.get_cmdline_user_args().has("--no-step3-cues")
	if load_waves or live_flag or s3_flag or g_flag or i_flag or l_flag or a_flag or b_flag or c_flag or k_flag or r_flag or p_flag or q_flag or OS.get_cmdline_user_args().has("--waves"):
		var da := DirAccess.open(DIR + "waves")
		if da != null:
			var names: Array = []
			for fn in da.get_files():
				if fn.ends_with(".poses.json"):
					var wn0: String = fn.trim_suffix(".poses.json")
					if load_waves or OS.get_cmdline_user_args().has("--waves") or (live_flag and wn0 == "wave1") or (s3_flag and wn0 == "step3") or (g_flag and wn0 == "ground1") or (i_flag and wn0 == "intro1") or (l_flag and wn0 == "laststand1") or (a_flag and wn0 == "agency1") or (b_flag and wn0 == "brake1") or (c_flag and (wn0 == "chain1" or wn0 == "lodge1")) or (k_flag and wn0 == "cl1") or (r_flag and wn0 == "recoil1") or (p_flag and wn0 == "ack1") or (q_flag and (wn0 == "cl2" or wn0 == "pair3")):   # the live flag loads wave 1 only, the step 3 flag its own cues
						names.append(wn0)
			names.sort()
			for wn in names:
				_load_wave(wn)
	var prj: Dictionary = _read("profiles.json")
	profiles = prj.get("profiles", {})
	default_profile = String(prj.get("default", "snappy"))
	by_part = prj.get("by_part", {})
	press = _read("press_styles.json")
	medium_wind = _read("medium_wind.json")
	tips = _read("tips.json")
	zip = _read("zip.json")
	bone_lag.resize(AnimRig.N)
	var bl: Dictionary = prj.get("bone_lag", {})
	for i in range(AnimRig.N):
		bone_lag[i] = float(bl.get(AnimRig.BONES[i][0], 0.0))
	cue_poses = _read("cues.json").get("cues", {})
	var fj: Dictionary = _read("forms.json")
	forms = fj.get("versions", {})
	form_poses = fj.get("poses", {})
	ragdoll = _read("ragdoll.json")
	ragdoll_motion = _read("ragdoll_motion.json")
	brake = _read("brake.json")
	chain = _read("chain.json")
	clinch = _read("clinch.json")
	recoil = _read("recoil.json")
	press_ack = _read("press_ack.json")
	locomotion = _read("locomotion.json")
	ground_motion = _read("ground_motion.json")
	secondary = _read("secondary.json")
	pop = _read("pop.json")
	reactions = _read("reactions.json")
	struggle = _read("struggle.json")
	grip_feed = _read("grip_feed.json")
	throws = _read("throws.json")
	personality = _read("personality.json")
	winner = _read("winner.json")
	quality_levels = _read("quality.json").get("levels", {})
	fighters_cfg = _read("fighters.json").get("fighters", {})
	pair = _read("pair_live.json")
	bake_slice_us = int(pair.get("bake", {}).get("slice_us", 4000))
	bake_play_us = int(pair.get("bake", {}).get("play_us", 1500))
	bake_over_ms = int(pair.get("bake", {}).get("over_ms", 20))
	bake_over_us = int(pair.get("bake", {}).get("over_us", 500))


## One parked wave's files (poses, key sets, sequences, cues, entries).
## A pose's sketch with its re-aimed targets (data/anim/targets.json) in place of the authored ones.
## Bakes one queued pose now (the same bake the eager path runs on the same sketch: the pose is identical, only later).
static func _bake_one(id: String) -> void:
	if not _pend.has(id):
		return
	var sk: Dictionary = _pend[id]
	_pend.erase(id)
	poses[id] = AnimPose.bake(id, sk)


## One queued piece of a fighter's waves: a wave loaded (its sketches queued for baking, its key sets, sequences and entries registered) or his pick lists built.
static func _work_one() -> void:
	var w: Dictionary = _work.pop_front()
	if String(w.k) == "wave":
		_wave_once(String(w.wn))
	else:
		_build_lists(String(w.key), w.names)


## Everything queued of the fighters' waves, run now (something asked for what is not loaded yet).
static func _drain_work() -> void:
	while not _work.is_empty():
		_work_one()


## Is this fighter's pick-list data ready? Runs the queued work to the end for him if it is not (a blow asked for it before the match-start queue got there).
static func pair_ready(key: String) -> bool:
	if key == "":
		return false
	while not pair_lists.has(key) and not _work.is_empty():
		_work_one()
	return pair_lists.has(key)


## Does the queue still hold anything (waves, lists or poses)?
static func bake_idle() -> bool:
	return _work.is_empty() and _pend.is_empty()


## The incremental bake's work, in order, until about `budget_us` microseconds are spent (at least one piece): the fighters' wave loads and list builds first, then the queued poses. Returns how many pieces are left.
## Called once a tick by RenderAnim.consume.
static func bake_pending(budget_us: int = -1) -> int:
	if _pend.is_empty() and _work.is_empty():
		return 0
	var budget: int = bake_slice_us if budget_us < 0 else budget_us
	var t0: int = Time.get_ticks_usec()
	var npose: int = poses.size()
	while true:
		var u0: int = Time.get_ticks_usec()
		if not _work.is_empty():
			_work_one()
		elif _pend_head < _pend_order.size():
			var id: String = _pend_order[_pend_head]
			_pend_head += 1
			if _pend.has(id):
				_bake_one(id)
		else:
			break
		bake_worst_us = maxi(bake_worst_us, Time.get_ticks_usec() - u0)
		if Time.get_ticks_usec() - t0 >= budget:
			break
	if _pend_head >= _pend_order.size():
		_pend_order.clear()
		_pend_head = 0
	pair_bake_usec += Time.get_ticks_usec() - t0
	pair_bake_poses += poses.size() - npose
	return _pend.size() + _work.size()


## Bakes everything still queued (the tools that read AnimData.poses directly, and load_every_wave, call this first).
static func bake_all() -> void:
	_drain_work()
	bake_pending(1 << 40)


static func _queue(id: String, sk: Dictionary) -> void:
	poses.erase(id)   # a later wave's pose of the same id replaces an earlier one, baked or not
	_pend[id] = sk
	_pend_order.append(id)
	bake_deferred += 1


static func _fixed(id: String, sk: Dictionary) -> Dictionary:
	if not target_fix.has(id):
		return sk
	var out: Dictionary = sk.duplicate()
	for k in target_fix[id]:
		out[k] = target_fix[id][k]
	return out


static func _load_wave(wn: String) -> void:
	_waves_done[wn] = true
	var wp: Dictionary = _read("waves/" + wn + ".poses.json").get("poses", {})
	for id in wp:
		var wsk: Dictionary = _fixed(id, wp[id])
		raw[id] = wsk
		wave_of[id] = wn
		if lazy:
			_queue(id, wsk)
		else:
			poses[id] = AnimPose.bake(id, wsk)
	if FileAccess.file_exists(DIR + "waves/" + wn + ".keysets.json"):
		var wk: Dictionary = _read("waves/" + wn + ".keysets.json").get("keysets", {})
		for kid in wk:
			keysets[kid] = wk[kid]
	if FileAccess.file_exists(DIR + "waves/" + wn + ".sequences.json"):
		var wsq: Dictionary = _read("waves/" + wn + ".sequences.json").get("sequences", {})
		for sid in wsq:
			entries[sid] = wsq[sid]
	if FileAccess.file_exists(DIR + "waves/" + wn + ".cues.json"):
		cue_map.merge(_read("waves/" + wn + ".cues.json").get("cues", {}), true)
	if FileAccess.file_exists(DIR + "waves/" + wn + ".entries.json"):
		var we: Dictionary = _read("waves/" + wn + ".entries.json").get("entries", {})
		for eid in we:
			entries[eid] = we[eid]


## Every parked wave not yet loaded (the joint-limit lint checks all the data, whichever flags a run switched on). Only tools call this: a live match
## would not play them, but the poses join the pool once loaded.
static func load_every_wave() -> void:
	load_all()
	var da := DirAccess.open(DIR + "waves")
	if da == null:
		return
	var names: Array = []
	for fn in da.get_files():
		if fn.ends_with(".poses.json"):
			var wn: String = fn.trim_suffix(".poses.json")
			var have := false
			for id in wave_of:
				if wave_of[id] == wn:
					have = true
					break
			if not have:
				names.append(wn)
	names.sort()
	for wn in names:
		_load_wave(wn)
	bake_all()


## The fighter of data/anim/fighters.json a roster id plays as: his key, or the id he replaces (PROTAGONIST and RIVAL; the old placeholder spellings no longer resolve). "" for none.
static func fighter_key(roster_id: String) -> String:
	var rid: String = roster_id.to_lower()
	for k in fighters_cfg:
		if String(k).to_lower() == rid or String(fighters_cfg[k].get("replaces", "")).to_lower() == rid:
			return String(k)
	var al: Dictionary = pair.get("aliases", {})   # (the neutral working ids of Combat's data: rival is the antihero)
	if al.has(rid) and fighters_cfg.has(String(al[rid])):
		return String(al[rid])
	return ""


## Bakes the waves of the fighter a roster id plays as (once): his strike, entry and energy waves, his `more`, and the waves both share. Builds his pick lists
## (every strike of his strike waves by weight, never the tail; the gated ones join while their gate is open) and his entries by name. Returns his key, or "" when the
## live pair is off or he is not one of the pair.
static func ensure_fighter(roster_id: String) -> String:
	load_all()
	if not RenderAnim.pair_live:
		return ""
	var key: String = fighter_key(roster_id)
	if key == "" or pair.is_empty():
		return ""
	if pair_lists.has(key):
		return key
	var names: Array = []
	var wv: Dictionary = fighters_cfg[key].get("waves", {})
	for k in wv:
		if wv[k] is Array:
			names.append_array(wv[k])
		else:
			names.append(String(wv[k]))
	names.append_array(pair.get("shared", []))
	if lazy:
		if _queued.has(key):
			return key
		_queued[key] = true
		for wn in names:
			_work.append({"k": "wave", "wn": String(wn)})
		_work.append({"k": "lists", "key": key, "names": names})
		return key
	var t0: int = Time.get_ticks_usec()
	var npose: int = poses.size()
	for wn in names:
		_wave_once(String(wn))
	_build_lists(key, names)
	pair_bake_usec += Time.get_ticks_usec() - t0
	pair_bake_poses += poses.size() - npose
	return key


static func _wave_once(wn: String) -> void:
	if not _waves_done.has(wn) and FileAccess.file_exists(DIR + "waves/" + wn + ".poses.json"):
		_load_wave(wn)


## A fighter's pick lists and entries by name, built from his waves' manifests and entries once they are loaded.
static func _build_lists(key: String, names: Array) -> void:
	var gated: Dictionary = {}
	for g in pair.get("gated", []):
		gated[String(g.strike)] = g
	var lst := {"light": [], "heavy": [], "gated": [], "entries": {}, "by_name": {}}
	for wn in names:
		var mp: String = DIR + "waves/" + String(wn) + ".manifest.json"
		if FileAccess.file_exists(mp):
			for st in _read("waves/" + String(wn) + ".manifest.json").get("strikes", []):
				var nm: String = String(st.name)
				if nm.begins_with("tail") or not keysets.has(String(st.id)):
					continue
				lst.by_name[nm] = String(st.id)
				var cid: String = String(st.get("combat", ""))
				if cid.begins_with("strike.") and cid.substr(7) != nm:
					lst.by_name[cid.substr(7)] = String(st.id)   # the piece's own Combat id when it differs from the set's name (one id a fighter in the pieces table: the rival's strike.bolt_flick_gut is rk.bolt_flick)
				if bool(st.get("named", false)):
					continue   # a piece Combat names (manifest `named`: the Protagonist's palm_turn, the Anti-hero's fist jabs): findable by the beat's `piece`, in no pick list until the pool is the hook
				if nm.begins_with("su_") or nm.begins_with("bolt_") or nm.begins_with("blast_"):
					continue   # the super-heavy tier and the energy-in-reach pieces are named by the director's beat (`piece`), never picked at random: they are findable by name and in no pick list
				if gated.has(nm):
					lst.gated.append({"id": String(st.id), "weight": String(gated[nm].weight), "gate": String(gated[nm].gate)})
				elif String(st.weight) == "heavy":
					lst.heavy.append(String(st.id))
				else:
					lst.light.append(String(st.id))
		var ep: String = DIR + "waves/" + String(wn) + ".entries.json"
		if FileAccess.file_exists(ep):
			for eid in _read("waves/" + String(wn) + ".entries.json").get("entries", {}):
				if not String(eid).contains("~"):
					lst.entries[String(eid).substr(String(eid).find(".") + 1)] = String(eid)
	pair_lists[key] = lst


## The key set of the strike a beat names (strike.jab, the planner's own pick once the alchemist's beats carry it) as the fighter's own; "" when he has none of that name.
static func resolve_strike(key: String, piece: String) -> String:
	if piece == "" or key == "" or not pair_ready(key):
		return ""
	return String(pair_lists[key].by_name.get(piece.substr(piece.find(".") + 1) if piece.begins_with("strike.") else piece, ""))


## An entry id a beat names (entry.dash, or an id already in the data) as the fighter's own entry sequence; "" when he has none of that name.
static func resolve_entry(key: String, id: String) -> String:
	if id == "":
		return ""
	if entries.has(id):
		return id
	if key == "" or not pair_ready(key):
		return ""
	var nm: String = id.substr(id.find(".") + 1) if id.begins_with("entry.") else id
	return String(pair_lists[key].entries.get(nm, ""))


static func pose_exists(id: String) -> bool:
	if poses.has(id) or _pend.has(id):
		return true
	if not _work.is_empty():
		bake_drains += 1   # it may be a pose of a wave not loaded yet: load them all, then ask again
		_drain_work()
		return poses.has(id) or _pend.has(id)
	return false


static func pose(id: String, mirror: bool = false) -> AnimPose:
	if _pend.has(id):
		bake_demand += 1
		_bake_one(id)
	elif not poses.has(id) and not _work.is_empty():
		_drain_work()
		if _pend.has(id):
			_bake_one(id)
	var p = poses.get(id)
	if p == null:
		push_error("AnimData: unknown pose " + id)
		if poses.is_empty():
			bake_pending(1)
		return poses.values()[0]
	if not mirror:
		return p
	var m = mirrors.get(id)
	if m == null:
		m = (p as AnimPose).mirrored()
		mirrors[id] = m
	return m


static func profile(name: String) -> Dictionary:
	return profiles.get(name, profiles.get(default_profile, {}))


static func live_flag_early() -> bool:
	return OS.get_cmdline_user_args().has("--wave1-live") or RenderAnim.wave1_live
