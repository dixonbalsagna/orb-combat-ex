class_name RenderAnim
extends RefCounted
## The mannequin runtime's hub (slice A1 of docs/animation/pose-pipeline.md): one AnimFighter per fighter, fed by the
## per-tick fx events and solved once a frame however many panes draw it. FighterView asks for its pose here. Render only:
## it reads S and the events, never writes them.
##   --noanim              keep the placeholder box figures (A/B runs, tools)
##   --noragdoll           switch the active ragdoll and the overhaul layers off (A/B runs)
##   --anim-style=NAME     a timing profile from data/anim/profiles.json (snappy or fluid)
## Tools set `enabled` and `style_override` directly.

static var enabled: bool = true
static var style_override: String = ""
static var _args_read: bool = false
static var _style_arg: String = ""
static var _quality_arg: String = ""
static var _fighters: Dictionary = {}
static var _sid: int = 0
static var _last_tick: int = -1
## Cost counters for tools: microseconds spent in AnimFighter.solve, and how many solves.
## Tools set this to scan every bone for NaN each solve (the game checks two).
static var debug_checks: bool = false
static var joint_audit: bool = false   # the joint-limit lint: every fighter notes which stage first took a joint past its limits (AnimFighter.audit)
## The active ragdoll (docs/animation/overhaul-plan.md): tools turn it off for the A/B; the host sets reduced_motion from the
## player's setting (it scales the ragdoll to 35% and turns the contact smear off).
static var ragdoll_enabled: bool = true
static var blow_join: bool = false        # --blowjoin: the blow's own snap is smoothed as a join (how it played before 2026-10-01 unit T), for an A/B
static var last_stand_poses: bool = true   # the last stand's body cue (docs 9.20); --no-last-stand-poses switches it off
static var pair_live: bool = true           # the launch pair play their own waves live (strikes, entries, blast presses, taunts: docs/animation/pair-live.md); --no-pair-live switches it off (the before)
static var hand_tips: bool = true             # a blow shows the hand state of its tip (data/anim/tips.json: the rival's heavies close to a fist); --no-hand-tips switches it off
static var intro_gestures: bool = true         # the sim's intro_gesture events play the fighter's own motion for the intent (docs/animation/intro-gestures.md); inert until the composer sends them; --no-intro-gestures switches it off
static var strength_styles: bool = false      # force a brawl beat's strength and burst number over the beat's own explicit `style` (`speed` for a light, `heavy` for a wound blow): the nine cells' looks (Y the medium row, B the super row, a held X's blows the burst row, the wind-ups whole, the held charge, the armour read) on a sim that still stamps the style. false (the shipped default) is today's picture.
static var fighter_ease: bool = true          # each fighter's own ease rows (data fighters.json `ease`): fluid arcs for one, snappy lines for the other, inside the one clock; false is the before
static var free_arm_slew: bool = true         # the free arm of a blow turns at a bounded rate (data joints.json slew); false is the before
static var source_limits: bool = true          # the contact solve and the join smoothing keep their limbs inside the joint limits themselves (no hard correction left for the last pass); false is the before
static var hand_retreat: bool = true          # a hand blow whose target is behind the shoulder gives ground the same way (its own switch: Combat rules on it, and the answer is data too, limbs.hand.min_fwd 0); false is the before
static var rd_variety: bool = true           # RG0 (docs/animation/ragdoll-physics-paper.md): each launch flails its own way (a hash of the slot and the launch number) and a bounce folds or arches by the side that hit; false is the before
static var rd_weight: bool = true            # RG1: the ragdoll has weight: impulses by the opponent's tier over the body's mass, and a blow travels down the body (head first, legs last); false is the before
static var rd_oop: bool = true             # RG3: six more degrees of freedom out of the plane (spine twist and side bend, head roll, each upper arm's twist, the pelvis's twist): a flailing body turns about its long axis as a rag does. On by default (Orb, 2026-10-25); --no-rd-oop is the before
static var air_brake: bool = true            # RG2: the sim's air brake braces a launched fighter against his velocity (an `air_brake` event; inert without one); --no-air-brake is the before
static var chain_poses: bool = true          # RG4: World's interior contacts and its lodge play the ceiling's slam and rebound and the climb out (data/anim/chain.json); inert without those events; --no-chain-poses is the before
static var grip_layer: bool = true            # the clinch's grip layer (docs/animation/clinch-sizing.md slice C2): the sim's hold read mixes the clinch poses in and puts each gripping hand on its region of the partner; inert without a read; --no-grip-layer is the before
static var recoil_flips: bool = true          # recoil exits and ricochets (docs/combat/choreography-feel.md): Encounter's cue `recoil` turns the struck body over in an arc (back flip, handspring, back tuck, skip, ricochet); inert without the cue; --no-recoil-flips is the before
static var press_ack: bool = true            # the anticipation of a press that has to wait (Encounter's cue press_ack, text queued): the first frames of the wind-up on the press tick, handed over to the real one; --no-press-ack is the before
static var flight_loco: bool = true           # flight locomotion (data/anim/locomotion.json): the lean spring, the braking flare, the dash's coil, the bank and the hover's breath, read from the sim's velocity; --no-flight-loco is the before
static var ground_loco: bool = true           # ground locomotion (data/anim/ground_motion.json): the gait, the kick-off and the landing by surface, read from the sim's velocity and ground; --no-ground-loco is the before
static var secondary_motion: bool = true      # follow-through of the head, upper back and forearms on every change of velocity and every blow (data/anim/secondary.json); --no-secondary is the before
static var pop_juggle: bool = true            # the popped fighter's rise, hang, fall, slam, burst and landing drawn from Encounter's cue `pop` (data/anim/pop.json); --no-pop is the before
static var air_recover: bool = true         # a launched body that gets control back in the air at speed catches itself (data/anim/locomotion.json `recover`); --no-air-recover is the before
static var hit_variants: bool = true          # hit reactions with variety (data/anim/reactions.json): a variant by the blow's weight, direction and body part, never the last one twice, and a recovery; --no-hit-variants is the before
static var struggle_dig: bool = true         # the beam struggle's dig-in (S.game.clash.mid): the pushed-back fighter sinks, trembles and is dragged back along the ground, the winner leans in; --no-struggle-dig is the before
static var grip_feed: bool = true            # the grip fed from the sim's grapple (DirGrapple.now and its cues) as five stages: the reach, the tie-up by grade, the pummel, the leader's set and the cave; inert with the grapple off; --no-grip-feed is the before
static var shiver_by_weight: bool = true       # the struck body's shake follows the hit-stop's weight (2 ticks a little over half, 8 as before, 24 at 1.6) and a blow with no stop of its own (a mash's later blows) still shakes, small; --no-shiver-weight is the before
static var kick_retreat: bool = true          # a kick whose hips are past its target gives ground instead of swinging the thigh back through its limit (data sockets.json limbs.foot.min_fwd); false is the before
static var mash_press: bool = true            # a run of mashed blows leans in (data styles.<style>.press_run); false is the before
static var march: bool = true                  # a mashed heavy takes a footfall (data styles.super.march); false is the before
static var dig_in: bool = true               # the held X digs in: the legs keep the set pose through a burst's stream (data styles.burst.dig); false is the before
static var plain_pin: bool = true              # a plain light (one light, no flurry, no chain) keeps its hand set on the target for the data's `beat.plain_light.pin_ticks` while the body goes on (the perfect follow-up's window opens as it lets go); a beat's own `plain: true` does the same. false is today's picture
static var hook_seen: bool = false            # set by the first brawl beat that carries a strength and no style row of its own: Encounter's hook (the brawl asks by cell and no longer names a style) has landed, so the nine cells' looks are the picture with no switch to flip
static func second_pass() -> bool:
	return strength_styles or hook_seen
static var medium_wind: bool = true          # Combat's eight rules for a medium on Y's 12-tick wind-up (data/anim/medium_wind.json): a flatter chamber, a half step; false is the before (tools)
static var press_styles: bool = true         # the three press styles (tech, speed, heavy) move the body through a strike (docs/animation/press-styles.md); ON by default since 2026-10-08 (brawl B1 stamps every blow's beat); --no-press-styles switches it off (the before), Shift+F7 flips it with VFX's looks
static var flight_lead: bool = true         # a fast launched body flies head first (docs 9.23); --no-flight-lead switches it off (the before)
static var agency_poses: bool = true       # the agency slice's events (knockback, embed, the far taunt, the charges) play their poses (docs 9.22); --no-agency-poses switches them off
static var intro_poses: bool = true        # the opening's fall, landing and staredown (docs 9.19); --no-intro-poses switches them off
static var ground_poses: bool = true       # World's ground-contact events play their poses and sequences (docs 9.18); --no-ground-poses switches them off
static var step3_cues: bool = true         # Encounter's step 3 cue events (perfect_block, reversal, dodge_cancel, burst, burst_absorbed) play their pose sequences: ON (they are the only feedback for live mechanics); --no-step3-cues switches them off
static var wave1_live: bool = false        # --wave1-live: wave 1's key sets are in the pick lists (go-live step 1, docs/combat/pending/golive-step1.md); OFF by default
static var force_target: String = ""      # a lab switch (--target=arm_r): every blow aims at this socket instead of its key set's own
static var force_keyset: String = ""      # a lab switch (--keyset=strike.elbow): every blow plays this key set, to test a limb that no pick uses yet
static var reduced_motion: bool = false
## Feet planted on the slope under a standing fighter, and a skid pitched to the ground (overhaul unit D); tools turn it off for the A/B.
static var ground_feet: bool = true
## The quality switch (overhaul unit H): a level from data/anim/quality.json switches whole layers off for the web's low setting and
## old laptops. Tools switch single layers off with `layers_off` to measure what each costs (solve_bench).
static var quality: String = "high"
static var layers_off: Dictionary = {}
static var _quality_off: Dictionary = {}


static func set_quality(level: String) -> void:
	AnimData.load_all()
	quality = level
	_quality_off.clear()
	for nm in AnimData.quality_levels.get(level, []):
		_quality_off[String(nm)] = true


## Whether an overhaul layer runs: the master switch (--noragdoll), the quality level and the tools' own switches.
static func layer(name: String) -> bool:
	if not ragdoll_enabled:
		return false
	if name == "feet" and not ground_feet:
		return false
	return not _quality_off.has(name) and not layers_off.has(name)
static var solve_usec: int = 0
static var solve_count: int = 0
static var consume_usec: int = 0   # the bench: wall time inside consume, and how many calls
static var consume_count: int = 0
static var tick_fast: bool = true   # the per-tick work (the ragdoll step, the cloth and follow-through springs) worked out once a tick; --no-tick-fast is the version before (docs/animation/tick-cost.md)


static func _read_args() -> void:
	if _args_read:
		return
	_args_read = true
	for a in OS.get_cmdline_user_args():
		if a == "--noanim":
			enabled = false
		elif a == "--noragdoll":
			ragdoll_enabled = false
		elif a == "--no-last-stand-poses":
			last_stand_poses = false
		elif a == "--no-agency-poses":
			agency_poses = false
		elif a == "--no-pair-live":
			pair_live = false
		elif a == "--press-styles":
			press_styles = true
		elif a == "--no-intro-gestures":
			intro_gestures = false
		elif a == "--no-press-styles":
			press_styles = false
		elif a == "--no-hand-tips":
			hand_tips = false
		elif a == "--no-flight-lead":
			flight_lead = false
		elif a == "--no-intro-poses":
			intro_poses = false
		elif a == "--no-ground-poses":
			ground_poses = false
		elif a == "--rd-oop":
			rd_oop = true
		elif a == "--no-rd-oop":
			rd_oop = false
		elif a == "--no-air-brake":
			air_brake = false
		elif a == "--no-chain-poses":
			chain_poses = false
		elif a == "--no-grip-layer":
			grip_layer = false
		elif a == "--no-recoil-flips":
			recoil_flips = false
		elif a == "--no-press-ack":
			press_ack = false
		elif a == "--no-flight-loco":
			flight_loco = false
		elif a == "--no-ground-loco":
			ground_loco = false
		elif a == "--no-secondary":
			secondary_motion = false
		elif a == "--no-tick-fast":
			tick_fast = false
		elif a == "--no-bake-frame":
			bake_frame = false
		elif a == "--no-pop":
			pop_juggle = false
		elif a == "--no-air-recover":
			air_recover = false
		elif a == "--no-hit-variants":
			hit_variants = false
		elif a == "--no-struggle-dig":
			struggle_dig = false
		elif a == "--no-grip-feed":
			grip_feed = false
		elif a == "--no-shiver-weight":
			shiver_by_weight = false
		elif a == "--step3-cues":
			step3_cues = true
		elif a == "--no-step3-cues":
			step3_cues = false
		elif a == "--wave1-live":
			wave1_live = true
		elif a.begins_with("--target="):
			force_target = a.substr(9)
		elif a == "--blowjoin":
			blow_join = true
		elif a.begins_with("--keyset="):
			force_keyset = a.substr(9)
		elif a.begins_with("--anim-quality="):
			_quality_arg = a.substr(15)
		elif a.begins_with("--anim-style="):
			_style_arg = a.substr(13)


## The LT zip (docs/animation/zip.md): the sim's zip tells the body of the zipper what it is (AnimZip.start: reading, btn, via and the phase ticks), that it ended early
## (caught, countered, cancelled) and that the fighter it strikes is held (carried by a tackle, lifted by a held A). A no-op unless press_styles is on.
static func zip_start(S: SimState, f, spec: Dictionary) -> void:
	AnimZip.start(fighter(S, f), spec, S.T)


static func zip_end(S: SimState, f, reason: String) -> void:
	AnimZip.end(fighter(S, f), reason, S.T)


static func zip_held(S: SimState, f, kind: String, dur: float) -> void:
	AnimZip.held(fighter(S, f), kind, S.T, dur)


static func is_enabled() -> bool:
	_read_args()
	if _quality_arg != "" and quality != _quality_arg:
		set_quality(_quality_arg)
	return enabled


static func style() -> String:
	_read_args()
	if style_override != "":
		return style_override
	return _style_arg if _style_arg != "" else AnimData.default_profile


## True when a style was forced (--anim-style or a tool): then every part uses that profile instead of Orb's per-part mix.
static func style_forced() -> bool:
	_read_args()
	return style_override != "" or _style_arg != ""


## The facing a view should draw this fighter with: the opponent's side in an exchange, the travel direction on the run
## (the sim's own `face` when the mannequin is off).
static func face_for(S: SimState, f) -> float:
	if not is_enabled():
		return f.face
	return fighter(S, f).update_face(S, f)


static func profile() -> Dictionary:
	return AnimData.profile(style())


static func _sync(S: SimState) -> void:
	if S.get_instance_id() != _sid or S.tick < _last_tick:
		_fighters.clear()
		_sid = S.get_instance_id()
	_last_tick = S.tick


static func fighter(S: SimState, f) -> AnimFighter:
	_sync(S)
	var id: int = f.get_instance_id()
	var af = _fighters.get(id)
	if af == null:
		AnimData.load_all()
		af = AnimFighter.new(S.fighters.find(f))
		af.pair_key = AnimData.ensure_fighter(String(f.id))   # his own waves, baked when his first body is built (the match-start cost)
		_log_pair_bake(S)
		_fighters[id] = af
	return af


## The fighter's pose for this frame, solved on the first ask (the other panes reuse it).
static func solve(S: SimState, f) -> AnimFighter:
	var af: AnimFighter = fighter(S, f)
	if af.frame != _frame_key(S):
		var t0: int = Time.get_ticks_usec()
		af.solve(S, f, profile())
		solve_usec += Time.get_ticks_usec() - t0
		solve_count += 1
	return af


## Each tick's events, from the host (main.gd's drained handler): ticks step the springs, cues start poses, hits start
## reactions.
static func consume(S: SimState, events: Array) -> void:
	if not is_enabled():
		return
	var c0: int = Time.get_ticks_usec()
	_sync(S)
	AnimData.load_all()
	for e in events:
		match e.type:
			"tick":
				if _bake_tick(S):   # the incremental bake: a slice of the queue once a drawn frame (docs/animation/incremental-bake.md, tick-cost.md)
					_log_pair_bake(S)
				for f in S.fighters:
					fighter(S, f).on_tick(float(e.dt), bool(e.frozen), S, f)
			"crater":
				# a crater was dug: a fighter near it feels it (the energy and the distance set how much)
				for f in S.fighters:
					var dxc: float = absf(SimWrap.sdx(f.x, float(e.x)))
					if dxc < 700.0:
						fighter(S, f).on_shock(S.T, clampf(float(_ev(e, "energy", 1.0)) / 8.0, 0.2, 1.0) * (1.0 - dxc / 700.0))
			"interior_contact":
				# World's contact inside a building (kind the surface: face, floor, ceiling or wall; the normal nx, ny; vn, vt; punch: the slab broke; stop the ticks held): docs/animation/ragdoll-physics-paper.md section 5
				var ic: int = int(_ev(e, "actor", -1))
				if ic >= 0 and ic < S.fighters.size():
					fighter(S, S.fighters[ic]).on_interior_contact({"surface": String(_ev(e, "kind", "floor")), "nx": float(_ev(e, "nx", 0.0)), "ny": float(_ev(e, "ny", 1.0)), "vn": float(_ev(e, "vn", 0.0)), "vt": float(_ev(e, "vt", 0.0)), "punch": bool(_ev(e, "punch", false)), "stop": int(_ev(e, "stop", 0))}, S.T)
			"lodge":
				# the last building of a chain holds him (hold seconds): the slump, the climb out and the stand
				var lg: int = int(_ev(e, "actor", -1))
				if lg >= 0 and lg < S.fighters.size():
					fighter(S, S.fighters[lg]).on_lodge(float(_ev(e, "hold", 0.6)), S.T)
			"air_brake":
				# the sim's brake in the air (text start or end, kind the reason, amount the speed at the start)
				var ba: int = int(_ev(e, "actor", -1))
				if ba >= 0 and ba < S.fighters.size():
					fighter(S, S.fighters[ba]).on_air_brake(String(_ev(e, "text", "")), String(_ev(e, "kind", "")), float(_ev(e, "amount", 0.0)), S.T)
			"skim":
				# a launched fighter skipped off water: the event carries no actor, so it is the launched one at that x
				for f in S.fighters:
					if f.state == "launched" and absf(SimWrap.sdx(f.x, float(e.x))) < 120.0:
						fighter(S, f).on_skim(S.T, float(e.spd))
			"left_ground", "bounce", "land", "tumble_end", "journey_end":
				# World's ground-contact events (docs/world/ground-contact.md section 4); none exist until its G3 lands
				var ga: int = int(_ev(e, "actor", -1))
				if ga >= 0 and ga < S.fighters.size():
					var gd: Dictionary = {}
					for key in ["actor", "n", "k", "vn", "vt", "keep", "surface", "kind", "sina", "cause", "contacts", "dur", "spd", "vx", "vy", "slope", "lips", "nb", "z"]:
						var gv = e.get(key)
						if gv != null:
							gd[key] = gv
					var t_ev: float = S.T - float(S.tick - int(e.tick)) * (1.0 / 60.0)   # the event's own time
					fighter(S, S.fighters[ga]).on_ground_event(String(e.type), gd, t_ev)
			"drop_start", "drop_land", "drop_end":
				# a zipper shot down on his way out (SimFighter.drop): the sim's events for the fall and the recovery
				var dr: int = int(_ev(e, "actor", -1))
				if dr >= 0 and dr < S.fighters.size():
					var t_dr: float = S.T - float(S.tick - int(e.tick)) * (1.0 / 60.0)
					var dfa: AnimFighter = fighter(S, S.fighters[dr])
					match String(e.type):
						"drop_start":
							dfa.on_drop_start(t_dr)
						"drop_land":
							dfa.on_drop_land(t_dr)
						"drop_end":
							dfa.on_drop_end(String(e.kind), t_dr)
			"intro_gesture":
				# Narrative's gesture beat (docs/narrative/dynamic-intros.md section 11): kind is the intent, text the point it is at (land_first, look_start ...), actor the fighter's slot
				var gi: int = int(_ev(e, "actor", -1))
				if gi >= 0 and gi < S.fighters.size():
					var tb: bool = String(S.fighters[gi].state) == "intro"
					var tg: float = float(int(e.tick)) / 60.0 if tb else S.T - float(S.tick - int(e.tick)) * (1.0 / 60.0)
					fighter(S, S.fighters[gi]).on_gesture(String(_ev(e, "intent", String(e.kind))), tg, tb)
			"last_stand_ready", "last_stand_end":
				var gl: int = int(_ev(e, "actor", -1))
				if gl >= 0 and gl < S.fighters.size():
					var t_ls: float = S.T - float(S.tick - int(e.tick)) * (1.0 / 60.0)
					fighter(S, S.fighters[gl]).on_last_stand(String(e.type), t_ls, float(_ev(e, "dur", 0.0)), String(e.kind))
			"intro_start", "entrance_fall", "entrance_land", "staredown_start", "clock_start":
				# the opening, on the sim's tick (the match clock is frozen until clock_start)
				var te: float = float(int(e.tick)) / 60.0
				var ga2: int = int(_ev(e, "actor", -1))
				if String(e.type) == "intro_start" or String(e.type) == "staredown_start" or String(e.type) == "clock_start":
					for f2 in S.fighters:
						fighter(S, f2).on_intro(String(e.type), te, float(_ev(e, "dur", 0.0)), String(e.kind))
				elif ga2 >= 0 and ga2 < S.fighters.size():
					fighter(S, S.fighters[ga2]).on_intro(String(e.type), te, float(_ev(e, "dur", 0.0)), "")
			"transform":
				var who2: int = int(e.actor)
				if who2 >= 0 and who2 < S.fighters.size():
					fighter(S, S.fighters[who2]).on_transform(S.T, String(e.version))
			"knockback":
				var kv: int = int(_ev(e, "victim", -1))
				if kv >= 0 and kv < S.fighters.size():
					var t_kb: float = S.T - float(S.tick - int(e.tick)) * (1.0 / 60.0)
					fighter(S, S.fighters[kv]).on_agency("knockback", t_kb, {"kind": String(e.kind), "dur": float(_ev(e, "dur", 0.5))})
			"shot_fire":
				var sa: int = int(_ev(e, "actor", -1))
				if sa >= 0 and sa < S.fighters.size():
					var t_sf: float = S.T - float(S.tick - int(e.tick)) * (1.0 / 60.0)
					fighter(S, S.fighters[sa]).on_shot(String(e.kind), t_sf, S, S.fighters[sa], int(e.tick), int(_ev(e, "link", -1)))
			"shot_deflect":
				var sd: int = int(_ev(e, "actor", -1))
				if sd >= 0 and sd < S.fighters.size():
					var t_sd: float = S.T - float(S.tick - int(e.tick)) * (1.0 / 60.0)
					fighter(S, S.fighters[sd]).on_deflect(t_sd, S, S.fighters[sd])
			"embed":
				var ke: int = int(_ev(e, "actor", -1))
				if ke >= 0 and ke < S.fighters.size():
					var t_em: float = S.T - float(S.tick - int(e.tick)) * (1.0 / 60.0)
					fighter(S, S.fighters[ke]).on_agency("embed", t_em, {"dur": float(_ev(e, "dur", 60.0)) / 60.0})
			"cue":
				var who: int = int(e.actor)
				if AnimData.agency.get("cue_kinds", []).has(String(e.kind)):
					var t_ag: float = S.T - float(S.tick - int(e.tick)) * (1.0 / 60.0)
					for ia in range(S.fighters.size()):
						if who < 0 or ia == who:
							fighter(S, S.fighters[ia]).on_agency(String(e.kind), t_ag, _taunt_ctx(S, S.fighters[ia]) if String(e.kind) == "taunt_start" else {})
				if AnimData.pair.get("cues", {}).has(String(e.kind)) and who >= 0 and who < S.fighters.size():
					var t_bc: float = S.T - float(S.tick - int(e.tick)) * (1.0 / 60.0)
					fighter(S, S.fighters[who]).on_blast_cue(String(e.kind), t_bc, S, S.fighters[who])
				var t_cue: float = S.T - float(S.tick - int(e.tick)) * (1.0 / 60.0)   # the event's own time, not the end of the frame's
				if who >= 0 and who < S.fighters.size():
					# the brawl's perfect block and reversal (press-styles.md section 12): the staggered fighter (the cue's actor) reels in place for n ticks; the blocker's riposte is announced
					var kd: String = String(e.kind)
					if kd == "stagger" and (String(e.text) == "perfect_block" or String(e.text) == "reversal" or String(e.text) == "zip" or String(e.text) == "counter"):
						fighter(S, S.fighters[who]).on_stagger(String(e.text), int(_ev(e, "n", 0)), t_cue)
					elif kd == "zip_light" or kd == "zip_heavy":
						fighter(S, S.fighters[who]).on_zip_cue(kd, int(roundf(float(_ev(e, "amount", 0.0)))), int(_ev(e, "n", 0)), float(_ev(e, "dur", 0.0)), int(roundf(float(_ev(e, "x", 0.0)))), int(roundf(float(_ev(e, "y", 0.0)))), t_cue)
					elif kd == "zip_out":
						fighter(S, S.fighters[who]).on_zip_out(String(e.text), float(_ev(e, "x", 0.0)), float(_ev(e, "y", 0.0)), int(_ev(e, "n", 0)), int(roundf(float(_ev(e, "k", 0.0)))), t_cue)
					elif kd == "zip_end":
						zip_end(S, S.fighters[who], String(e.text))
					elif kd == "launcher_open":
						var lt: int = int(_ev(e, "target", -1))   # the staggered fighter shows the stagger; the fighter who may launch (the actor) carries the cue
						fighter(S, S.fighters[who]).on_launcher_open("actor", String(e.text), int(_ev(e, "n", 0)), S.tick, t_cue)
						if lt >= 0 and lt < S.fighters.size():
							fighter(S, S.fighters[lt]).on_launcher_open("target", String(e.text), int(_ev(e, "n", 0)), S.tick, t_cue)
					elif kd == "launcher_close":
						for ic in range(S.fighters.size()):
							fighter(S, S.fighters[ic]).on_launcher_close(String(e.text))
					elif kd == "recoil":
						# Encounter's recoil flip (DirRecoil): source the exit (skip, handspring, tuck, backflip) and dur its ticks to the landing; the sim's own bowed path carries him, the body only turns
						fighter(S, S.fighters[who]).on_recoil(String(_ev(e, "source", "")), int(roundf(float(_ev(e, "dur", 0.0)))), t_cue, float(_ev(e, "ux", 0.0)), float(_ev(e, "uy", 1.0)))
					elif kd == "lunge_light" or kd == "lunge_heavy" or kd == "return" or ((kd == "charge_light" or kd == "charge_heavy") and float(_ev(e, "amount", 0.0)) > 0.0):
						# the mid-band lunge's authored wind-up crouch (bands.lunge.windupTicks: light 6, heavy 10) and the return's: the cue comes on the press tick with `amount` the crouch's ticks, then the body moves
						fighter(S, S.fighters[who]).on_lunge_crouch("heavy" if kd.ends_with("heavy") else ("return" if kd == "return" else "light"), int(roundf(float(_ev(e, "amount", 0.0)))), t_cue)
					elif kd == "press_ack" and String(e.text) == "queued":
						# a press that has to wait, on its press tick: source its button cell (x, y, b), n the tick it is due to start (-1 when the wait is not a cooldown), amount the ticks to it
						fighter(S, S.fighters[who]).on_press_ack(String(_ev(e, "source", "")), int(roundf(float(_ev(e, "n", -1.0)))), int(roundf(float(_ev(e, "amount", -1.0)))), t_cue)
					elif kd == "grapple_end":
						# the grapple's end: a throw (text throw_across, thrown_up, thrown_down or reversal, the actor the thrower) plays his own side of it; a send past him is the one he did not face
						var gt: int = int(_ev(e, "target", -1))
						var past: bool = false
						if gt >= 0 and gt < S.fighters.size():
							past = absf(S.fighters[gt].vx) > 1.0 and signf(S.fighters[gt].vx) != signf(SimWrap.sdx(S.fighters[who].x, S.fighters[gt].x))
						fighter(S, S.fighters[who]).on_grip_throw(String(e.text), past, t_cue)
					elif kd == "grapple_pummel":
						# a pummel for the better grip (text step or sharp): the free hand swims in
						fighter(S, S.fighters[who]).on_grip_pummel(String(e.text), t_cue)
					elif kd == "pop":
						# Encounter's pop (launch anywhere): the popped fighter is the actor; text up, slam, tech, burst or land, n the landing tick (on land 1 set, 0 reeling), dur the ticks up, amount the height in body heights
						fighter(S, S.fighters[who]).on_pop(String(e.text), int(roundf(float(_ev(e, "n", 0)))), float(_ev(e, "dur", 0.0)), float(_ev(e, "amount", 0.0)), t_cue)
					elif kd == "charge_full":
						fighter(S, S.fighters[who]).on_charge_full(t_cue)
					elif kd == "tech":
						fighter(S, S.fighters[who]).on_tech(t_cue)   # the rival's tech in the air (the chase's answer): a guard press timed to the chaser's arrival
					elif kd == "chase":
						fighter(S, S.fighters[who]).on_chase(String(e.text), int(roundf(float(_ev(e, "k", 0.0)))), int(_ev(e, "n", 0)), t_cue, S.tick)
					elif kd == "windup":
						fighter(S, S.fighters[who]).on_windup(String(e.text), String(_ev(e, "source", "")), float(_ev(e, "dur", 0.0)), int(_ev(e, "n", 0)), int(roundf(float(_ev(e, "k", 0.0)))), t_cue, S.tick)
					elif kd == "miss":
						fighter(S, S.fighters[who]).on_miss(String(e.text), int(_ev(e, "n", 0)), t_cue)
					elif kd == "double_hit":
						for idh in range(S.fighters.size()):
							fighter(S, S.fighters[idh]).on_double_hit(int(_ev(e, "n", 0)), int(roundf(float(_ev(e, "k", 0.0)))), t_cue)
					elif kd == "energy_reach" or kd == "energy_land":
						fighter(S, S.fighters[who]).on_energy(kd, String(e.text), float(_ev(e, "x", 0.0)), float(_ev(e, "y", 0.0)), int(roundf(float(_ev(e, "k", 0.0)))), t_cue)
					elif String(e.kind) == "riposte":
						fighter(S, S.fighters[who]).on_riposte(String(e.text), int(_ev(e, "n", 0)), S.tick)
				for i in range(S.fighters.size()):
					if who < 0 or i == who:
						fighter(S, S.fighters[i]).on_cue(String(e.kind), S.T, t_cue)
					elif who >= 0 and step3_cues:
						fighter(S, S.fighters[i]).on_cue_other(String(e.kind), t_cue)
			"damage":
				var v: int = int(e.victim)
				if v >= 0 and v < S.fighters.size() and String(e.kind) != "impact":
					var vf = S.fighters[v]
					var a: int = int(e.attacker)
					var front: bool = true
					if a >= 0 and a < S.fighters.size():
						front = SimWrap.sdx(vf.x, S.fighters[a].x) * fighter(S, vf).vface > 0.0
					var dm := Vector2.ZERO
					if a >= 0 and a < S.fighters.size():
						var atk = S.fighters[a]
						var dw := Vector2(SimWrap.sdx(atk.x, vf.x), vf.y - atk.y)
						if dw.length() > 1.0:
							dm = Vector2(dw.x * fighter(S, vf).vface, dw.y).normalized()
					var vfa: AnimFighter = fighter(S, vf)
					vfa.armoured = RenderAnim.second_pass() and bool(DirBrawl.winding(S, vf).get("armoured", false))   # a heavy winding or charging: a light does not shift him (the nine cells)
					# the tenth round: a plain light's hit is held (the attacker's hand stays on him for its pin: the flinch hangs that long); a duel of perfects' amplified send carries its level (`duel`, absent today)
					var hang: float = 0.0
					if a >= 0 and a < S.fighters.size() and String(e.kind) == "light":
						hang = clampf(fighter(S, S.fighters[a])._pin_until - S.T, 0.0, 0.2)
					vfa.on_hit(S.T, String(e.region), front, float(e.amount) / 70.0, String(e.kind), dm, float(e.amount) / 60.0, S.tick, hang, int(_ev(e, "duel", 0)), int(roundf(float(_ev(e, "stop", -1.0)))))
					if String(e.kind) == "guard" and a >= 0 and a < S.fighters.size():
						fighter(S, S.fighters[a]).on_blocked(S.T)
	consume_usec += Time.get_ticks_usec() - c0
	consume_count += 1


static var bake_frame: bool = true   # one slice per drawn frame, sized by the frame's time; --no-bake-frame is the version before (a slice every tick)
static var _bk_frame: int = -1
static var _bk_wall: int = 0
static var bake_slices: int = 0
static var bake_over_slices: int = 0
static var bake_done_tick: int = -1


## The tick's share of the incremental bake; true when the queue is empty. A frame can run several ticks (a slow device catches up), and each used to take its own slice, so a phone spent the slice's 4 ms on every tick of
## a drain that lasts a thousand. Now the first tick of a drawn frame bakes and the others do not; the slice is `bake.slice_us` while the intro plays (the bake has to be done before the fight), `bake.play_us` after it,
## and `bake.over_us` when the frame since the last slice took longer than `bake.over_ms` (the device is already behind). One piece is baked at least, so the queue always drains; what is asked for before it is baked is
## baked on the spot, so the poses are the same whichever tick bakes them (the render's wall clock never reaches the sim).
static func _bake_tick(S: SimState) -> bool:
	if AnimData.bake_idle():
		return true
	if not bake_frame:
		return AnimData.bake_pending() == 0
	var fr: int = Engine.get_process_frames()
	if fr == _bk_frame:
		return false
	_bk_frame = fr
	var now: int = Time.get_ticks_usec()
	var over: bool = _bk_wall > 0 and (now - _bk_wall) > AnimData.bake_over_ms * 1000
	_bk_wall = now
	var intro: bool = false
	for f in S.fighters:
		if f.state == "intro":
			intro = true
			break
	var budget: int = AnimData.bake_slice_us if intro else AnimData.bake_play_us
	if over:
		budget = mini(budget, AnimData.bake_over_us)
		bake_over_slices += 1
	bake_slices += 1
	return AnimData.bake_pending(budget) == 0


## One console line per run, once every fighter of the match that plays as the pair has baked his waves: how long the live loader took and how many poses it baked
## (docs/animation/split-bake-plan.md: the web build's number decides whether the incremental bake is built).
static var _bake_logged: bool = false
static func _log_pair_bake(S: SimState) -> void:
	if _bake_logged:
		return
	var keys: Dictionary = {}
	for fo in S.fighters:
		var k: String = AnimData.fighter_key(String(fo.id))
		if k != "":
			keys[k] = true
	if keys.is_empty() or AnimData.pair_lists.size() < keys.size() or not AnimData.bake_idle():
		return
	_bake_logged = true
	bake_done_tick = S.tick
	print("pair bake: %d ms, %d poses" % [int(round(float(AnimData.pair_bake_usec) / 1000.0)), AnimData.pair_bake_poses])
	if AnimData.lazy:
		print("pair bake incremental: %d poses queued, %d baked on demand, %d waves loaded early for a pose, %d queue runs, longest piece %.1f ms, %d slices (%d over budget), drained at tick %d" % [AnimData.bake_deferred, AnimData.bake_demand, AnimData.bake_early, AnimData.bake_drains, float(AnimData.bake_worst_us) / 1000.0, bake_slices, bake_over_slices, S.tick])


## What a far taunt's pick needs to know of the moment: whether he is in the air (the bounce is ground only) and whether any blow has landed yet this match (the nod opens a stand-off).
static func _taunt_ctx(S: SimState, f) -> Dictionary:
	var traded: bool = false
	for fo in S.fighters:
		if fighter(S, fo)._hit_n > 0:
			traded = true
	return {"air": f.y - WorldTerrain.groundY(S, f.x, f.z) > 20.0, "traded": traded}


## A field of an event that may not exist yet (World's ground-contact events arrive with their fields; until then the event is not sent).
static func _ev(e, key: String, default):
	var v = e.get(key)
	return default if v == null else v


## Which frame a solve belongs to: the engine frame and the sim tick (tools step several ticks in one engine frame).
static func _frame_key(S: SimState) -> int:
	return Engine.get_process_frames() * 1000003 + S.tick
