class_name UiSimBridge
## The read-only bridge from the live sim to the HUD: copies what the greybox sim exposes today (stance, tier, charge,
## momentum, the prototype's ego meters, hiding) into the HUD's view models, and builds the planet strip's data.
## It only READS the sim state S. Wear regions, brink and the other spec-wounds events do not exist in the sim yet:
## they reach the HUD through hud.consume_all(events) when Simulation's wear slice lands (docs/architecture/wounds-plan.md S1).
##
## The prototype's "ki" is the HUD's Charge, and its unlabelled "power" bar is Momentum, drawn as the partial next tier pip.

const ROLE_EGO: Dictionary = {"hero": "anguish", "villain": "menace"}

## Roster ids (lower case) whose readout profile is a stand-in's alias rather than the real profile of the same id. The real Protagonist has a Respect
## meter, a portrait pack and a rally card the sim does not drive; the stand-in's meter is the sim's anguish. So the stand-in keeps reading as it does
## today, and the rename changes words only. Drop the row when the real fighter replaces the stand-in (docs/ui/hud-spec.md section 46).
const STAND_IN_PROFILES: Dictionary = {"protagonist": "stand_in_protagonist"}


## The readout profile id for a fighter's roster id.
static func profile_id(roster_id) -> String:
	var k: String = str(roster_id).to_lower()
	return str(STAND_IN_PROFILES.get(k, k))


## Readout profile ids and names for the current fighters, by roster id (f.id: the sim's name may be a mirror arm's label and, from the rename on,
## is the id too). The name is the roster id; the HUD looks up the words a player reads (UiData.display_name).
static func fighters(S) -> Array:
	var ids: Array = []
	var names: Array = []
	for f in S.fighters:
		ids.append(profile_id(f.id))
		names.append(str(f.id))
	return [ids, names]


## The live ticks for which the brawl's launcher still rests on fighter f (0: a launch is ready on him), or -1 when the brawl is off or the sim has no such slot. A READ ONLY copy
## of DirBrawl.launcherRest: that one sizes the fighter's director slots on the way (`_g` calls `_size`, which resizes f.act.dirI, a field the gameplay hash includes), so calling it
## from here changed the hash when an intro played (determinism.gd --intro, tick 60). This reads the slot only if it is already there, from the sim's own constant and config.
## The launcher's rest in seconds, from the director's data (launcher.restS), 0 when the brawl is off.
static func _launcher_rest_total() -> float:
	var cmap: Dictionary = (DirBrawl as GDScript).get_script_constant_map()
	if not cmap.has("LAUNCH_AT") or not DirBrawl.on():
		return 0.0
	return float((DirBrawl.cfg().get("launcher", {}) as Dictionary).get("restS", 0.0))


static func _launcher_rest_ticks(S, f) -> int:
	var cmap: Dictionary = (DirBrawl as GDScript).get_script_constant_map()
	if not cmap.has("LAUNCH_AT") or not DirBrawl.on():
		return -1
	if not ("act" in f) or not ("dirI" in f.act):
		return -1
	var slot: int = int(cmap["LAUNCH_AT"])
	var at: int = int(f.act.dirI[slot]) if f.act.dirI.size() > slot else 0
	if at <= 0:
		return 0
	var rest_s: float = float((DirBrawl.cfg().get("launcher", {}) as Dictionary).get("restS", 0.0))
	return maxi(0, int(round(rest_s * 60.0)) - (int(round(float(S.T) * 60.0)) - at))


## Copy per-fighter state into the HUD. Call once per tick or per frame; it writes only to the HUD's models.
static func patch(hud: UiHud, S, input_hub = null) -> void:
	var move_names: Array = []
	for i in range(S.fighters.size()):
		var f = S.fighters[i]
		if "sigName" in f:
			move_names.append(UiData.display_text(str(f.sigName)))   # today the move's name; from the rename on its key (PROTAGONIST.SIG), read as the name
		var tier: int = int(f.tier)
		var into: float = 0.0
		if tier < 4:
			into = clampf((float(f.power) - 25.0 * float(tier - 1)) / 25.0, 0.0, 1.0) * 100.0
		var ego_name: String = ROLE_EGO.get(str(f.role), "respect")
		var ego: float = float(f.menace) if ego_name == "menace" else float(f.anguish)
		var wear: Dictionary = {}
		if "wear" in f:
			# S1's fixed-point wear (units of 1/6000 of a wear point per region): the crown thins smoothly from it.
			for r in range(mini(4, f.wear.size())):
				wear[["head", "core", "arms", "legs"][r]] = float(f.wear[r]) / 6000.0
		var lp: Dictionary = {}
		var rest_ticks: int = _launcher_rest_ticks(S, f)
		if rest_ticks >= 0:
			lp["launcher_ready"] = rest_ticks == 0
			lp["launcher_rest_left"] = float(rest_ticks) / 60.0
			var rest_total: float = _launcher_rest_total()
			if rest_total > 0.0:
				lp["launcher_rest_total"] = rest_total
		if not lp.is_empty():
			hud.hub.patch(i, lp)
		hud.hub.patch(i, {
			"name": str(f.id), "ai": f.ai != null, "stance": int(f.stance), "tier": tier, "momentum": into,
			"charge": float(f.ki), "hidden": bool(f.hidden), "charging": str(f.state) == "charging",
			"ego": ego, "aura": str(f.aura), "wear": wear,
			# A form is ready while the sim says so (f.act.formReady, I2a): the prompt does not wait for, or depend on, the transform_ready event.
			"avail_transform": bool(f.act.formReady) if "act" in f else false,
			# ... and it can be taken only between exchanges, on the ground or charging, with nobody out (SimExchange._transforms' own condition).
			"last_stand_left": float(f.lastStandLeft) / 60.0 if "lastStandLeft" in f else 0.0,   # the sim's own count of live ticks left (SimFighter.sigFree), 60 to the second
			"stance_mask": int(f.input.stanceMask) if (f.input != null and "stanceMask" in f.input) else 0,   # the held stance buttons (the layout's resolved mask; the AI's is 0 until its stance slice)
			"energy": int(f.act.mode) == 1 if "act" in f else false,   # the intent's mode: 1 while the mode control is held (or latched on a toggle)
			"form_free": S.dirS.ex == null and S.game.ko == null and (str(f.state) == "free" or str(f.state) == "charging"),
		})
	var windows: Array = beat_windows(S)
	for i in range(mini(2, windows.size())):
		hud.hub.patch(i, {"beats": windows[i]})
	hud.hub.set_move_names(move_names)
	hud.hub.set_clash_mid(clash_mid(S))   # the beam struggle's meeting point (-1 until Encounter's park is applied)
	var w = S.world
	hud.hub.consume({"type": "world", "civilians": int(round(float(w.casualties))), "pop0": int(w.pop0), "structures": int(w.structuresLost), "craters": int(w.craters)})
	patch_input(hud, input_hub)   # the arming, when the host passes its input hub (SimHost.hub)


## The arming, from Controls' input hub (read-only: `armed_stance`, `armed_share`, `energy_latched` per slot): an armed stance (Full touch: a tap arms it for the
## next blow, 90 ticks) is in the intent's mask but is not held, so the badge says NEXT BLOW with a ring that runs down. `stance_armed` is the share left, and
## stays a little above 0 for as long as a stance is armed: the share reaches exactly 0.0 on the last tick before the lapse while the arming still counts, so
## the test is `armed_stance != 0`, never `share > 0`. Energy's latch is not an arming (the stance is simply energy); nothing is patched for it here.
## `hub` is the host's SimInputHub (SimHost.hub); null does nothing.
static func patch_input(hud: UiHud, hub) -> void:
	if hub == null:
		return
	for slot in range(mini(2, hud.hub.models.size())):
		var armed: int = int(hub.armed_stance(slot))
		var share: float = float(hub.armed_share(slot))
		hud.hub.patch(slot, {"stance_armed": maxf(share, 0.02) if armed != 0 else 0.0})


## Seconds to contact of every pending blow in the running exchange, per fighter struck (the beat ring): the director's `strike` and `chainStrike` beats
## not yet done and within UiBeatRing.LEAD of landing. A strike by the attacker (role A) or the defender (role D) lands on the other fighter. Reads only.
static func beat_windows(S) -> Array:
	var out: Array = [[], []]
	var ex = S.dirS.ex
	if ex == null:
		return out
	for b in ex.beats:
		if b.done or (b.op != "strike" and b.op != "chainStrike"):
			continue
		var attacker_a: bool = true if b.op == "chainStrike" else (str(b.args.a) == "A")
		var target = ex.D if attacker_a else ex.A
		var slot: int = S.fighters.find(target)
		var to_go: float = float(b.t) - float(ex.t)
		if slot >= 0 and slot < 2 and to_go >= -0.02 and to_go <= UiBeatRing.LEAD:
			out[slot].append(to_go)
	return out


## The mix of a fighter's last presses for the Show recipe option (the host's `hud.recipe_fn`): SimPressRead.classify's mix_long, or {} while the
## sim has no press log for him (it has not been added to the fighter yet). A stub until the alchemist exists.
static func recipe(S, slot: int) -> Dictionary:
	if slot < 0 or slot >= S.fighters.size():
		return {}
	var f = S.fighters[slot]
	if "pressLog" in f and f.pressLog is Array:
		return SimPressRead.classify(f.pressLog, int(S.tick)).get("mix_long", {})
	return {}


## Feed lines drained from S.out.feed by the host. Pass each line as the host appends it to its own list.
static func feed(hud: UiHud, lines: Array) -> void:
	for l in lines:
		hud.hub.feed_line(float(l.t), str(l.tag), str(l.sub))


## The planet strip's data. cam_x and cam_w are the reference camera's centre and its view width in world units.
## The beam struggle's meeting point (Clash.mid: 0 at the first fighter's hands, 1 at the second's; -1 when there is no struggle or the field is not there yet). Read only.
static func clash_mid(S) -> float:
	if S == null or S.game == null:
		return -1.0
	var c = S.game.clash if "clash" in S.game else null
	if c == null:
		return -1.0
	var v = c.get("mid") if c is Object or c is Dictionary else null
	return float(v) if v != null else -1.0


static func strip_data(S, cam_x: float, cam_w: float) -> Dictionary:
	var dead: Array = []
	for b in S.buildings:
		if not b.alive:
			dead.append(float(b.x))
	var fs: Array = []
	for i in range(S.fighters.size()):
		var f = S.fighters[i]
		var o = S.fighters[1 - i] if S.fighters.size() == 2 else null
		var seen: float = float(f.x)
		if o != null and o.lastSeen != null:
			seen = float(o.lastSeen.x)
		fs.append({"x": float(f.x), "slot": i, "hidden": bool(f.hidden), "aura": Color.html(str(f.aura)), "seen_x": seen})
	var segs: Array = []
	for s in WorldBiomes.SEG:
		segs.append([float(s[0]), float(s[1]), str(s[2])])
	return {"W": SimConst.W, "segs": segs, "cam_x": cam_x, "cam_w": cam_w, "dead": dead, "fighters": fs}
