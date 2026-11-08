extends SceneTree
## The stick's quick strike at range as a light lunge (stick.json lungeLight, off; docs/director/pending/stick-lunge/).
##   godot --headless --path . --script res://sim/director/tools/stick_lunge_check.gd
## - from the middle band a quick flick asks for the light lunge (lunge_light) and lands sooner than the heavy one did, as a light: the light's
##   worth, with the stick's own cues (stick_start, stick_hit) and its stun
## - up close it's the stick's own medium blow, as before; off, the middle band's flick is the heavy lunge as before
## - a flick held through the arrival is the stick's charge, and lands on its release
## Ends on the verdict line.

var failed: int = 0


func _init() -> void:
	DirStick.setForce(1)
	var fs0: bool = bool(DirStick.cfg().get("fullSend", {}).get("enabled", false))
	if DirStick.cfg().has("fullSend"):
		DirStick.cfg().fullSend.enabled = false   # with it on a top-stage hold sends (full_send_check has that): here the stick's blow, as built
	var cfg: Dictionary = DirStick.cfg().get("lungeLight", {})
	cfg["enabled"] = false
	var off6: Dictionary = _flick(6.0)
	var off1: Dictionary = _flick(1.0)
	cfg["enabled"] = true
	var on6: Dictionary = _flick(6.0)
	var on9: Dictionary = _flick(9.0)
	var on1: Dictionary = _flick(1.0)
	var held: Dictionary = _flick(6.0, 30)
	cfg["enabled"] = false
	DirStick.setForce(-1)
	for r in [off6, on6, on9, off1, on1, held]:
		print("      %.1f bh, %s: lands in %d ticks, %.2f of damage, stunned %d; %s" % [r.d, "on" if r.on else "off", r.land, r.dmg, r.stun, str(r.cues)])
	var unit: float = float(DirBrawl.cfg().light.damage) * float(DirBrawl.cfg().damageMul)
	_expect(off6.cues.has("lunge_heavy") and on6.cues.has("lunge_light") and on9.cues.has("lunge_light"), "from the middle band the flick asks for the light lunge (off, the heavy one)")
	_expect(on6.land > 0 and on6.land <= off6.land - 4 and on9.land > 0, "it lands sooner: %d ticks against %d at 6 bh" % [on6.land, off6.land])
	_expect(on6.cues.has("stick_start") and on6.cues.has("stick_hit") and on6.stun > 0, "it's still the stick's strike: its cues and its stun")
	_expect(on6.dmg > 0.0 and on6.dmg < off6.dmg, "it lands as a light: %.2f against the medium's %.2f (a light unit is %.2f)" % [on6.dmg, off6.dmg, unit])
	_expect(on1.land == off1.land and absf(on1.dmg - off1.dmg) < 0.001 and not on1.cues.has("lunge_light"), "up close it's the stick's own blow, as before")
	_expect(held.land > on6.land and held.dmg > on6.dmg and held.cues.has("stick_hit"), "held through the arrival it's the stick's charge, and it lands on the release (%d ticks, %.2f)" % [held.land, held.dmg])
	print("STICK LUNGE: %d check(s) failed" % failed)
	if DirStick.cfg().has("fullSend"):
		DirStick.cfg().fullSend.enabled = fs0
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


## A quick flick toward the rival dBh away, in the air: {d, on, land (ticks to the blow, -1 none), dmg, stun, cues}.
func _flick(dBh: float, holdTo: int = 1) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 31, {"p1": false, "p2": false}, {"v2": [true, true], "intro": false})
	for _k in range(5):
		SimCore.step(S, [null, null])
	var A = S.fighters[0]
	var D = S.fighters[1]
	var x1: float = SimWrap.wrap(A.x + dBh * 75.0)
	A.y = maxf(WorldTerrain.groundY(S, A.x), WorldTerrain.groundY(S, x1)) + 500.0
	D.y = A.y
	D.x = x1
	for f in [A, D]:
		f.ki = 100.0
		f.hp = 100000.0
		f.vx = 0.0
		f.vy = 0.0
	S.out.fx.clear()
	var t0: int = S.tick
	var hp0: float = D.hp
	var land: int = -1
	var cues: Array = []
	var stun: int = 0
	for k in range(90):
		var i := SimIntent.new()
		if k == 0:
			i.rsStart = true
			i.rsDir = SimStrikeRead.RIGHT
			i.rsHeld = true
		elif k < holdTo:
			i.rsHeld = true
			i.rsDir = SimStrikeRead.RIGHT
			i.rsLevel = mini(3, k / 12)
		elif k == holdTo:
			i.rsRelease = true
			i.rsDir = SimStrikeRead.RIGHT
			i.rsLevel = mini(3, k / 12)
		SimCore.step(S, [i, SimIntent.new()])
		for e in S.out.fx:
			if String(e.type) == "cue" and int(e.actor) == 0 and not cues.has(String(e.kind)):
				cues.append(String(e.kind))
		S.out.fx.clear()
		if land < 0 and D.hp < hp0:
			land = S.tick - t0
		if land >= 0:
			stun = maxi(stun, D.stunTicks)
			if S.tick - t0 > land + 3:
				break
	var r := {"d": dBh, "on": bool(DirStick.cfg().get("lungeLight", {}).get("enabled", false)), "land": land, "dmg": hp0 - D.hp, "stun": stun, "cues": cues}
	SimCore.dispose(S)
	return r
