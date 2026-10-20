class_name SimFighter
## Fighter simulation: the twin of fighter.js (tierUp, impact, stepLaunched, stepRush, stepFighter).

## D1b: the meters' numbers (regen, decay) are f.md and the power ladder's are f.ld (data/fighters/<id>/meters.json and
## ladder.json).
## Water holds a launched fighter up (S3a gap fix): under water the launch's gravity is cancelled (neutral buoyancy), so
## the drag brings it below the free speed within about a second instead of holding it at a 430 u/s sink to the seabed.
const WATER_BUOY: float = 1000.0
const DROP_GRAV: float = 1000.0   # a dropped fighter's fall, units a second squared (a flight's own gravity)


static func tierUp(S: SimState, f) -> void:
	S.world.maxTier = maxf(S.world.maxTier, f.tier)
	SimMood.onForm(S, f)   # a form step may raise the act, and it adds the mood's form impulse
	SimFx.banner(S, f.name + " POWERS UP  TIER " + SimMathx.jstr(f.tier), f.aura, 1.4)
	var g: float = WorldTerrain.groundY(S, f.x, f.z)   # at his depth (the plane's when depth is off)
	SimFx.ring(S, f.x, f.y + 34.0, 1300.0, f.aura, 0.8, 20.0, f.z)
	SimFx.spark(S, f.x, f.y + 34.0, 20, f.aura, 700.0, f.z)
	SimFx.shake(S, 14.0, f.x, f.z)
	if f.y < g + 140.0:
		WorldCrater.dig(S, f.x, WorldCrater.powerupEnergy(f.tier), f, "powerup")
		WorldStructures.damageArea(S, f.x, f.y, (f.ld.areaR + f.tier * f.ld.areaRPerTier) * SimConst.WS, f.ld.areaDmg + f.tier * f.ld.areaDmgPerTier, f)
		SimFx.debris(S, f.x, g + 10.0, 10, "#6d6a66", 600.0, f.z)
		SimFx.dust(S, f.x, g, 5, "", f.z)
	SimFx.tierUp(S, f, f.y < g + 140.0)
	SimEvents.feed(S, f.name + " reaches tier " + SimMathx.jstr(f.tier), "Ground-level power-up scarred the terrain." if f.y < g + 140.0 else "Airborne power-up, no ground damage.")


## A launched fighter meets the ground. sp is the actual speed; the damage and the energy use the unboosted speed (the
## horizontal traversal factor of the launch is divided out). A near-vertical slam digs one crater and stays down; anything
## shallower is a knockback slide (world/slide.gd), with at most one small hop first at very high energy. Nothing bounces
## more than once on ground, so a launch leaves at most one crater.
static func impact(S: SimState, f, g: float, sp: float) -> void:
	var by = f.launchBy if f.launchBy != null else SimRoster.opp(S, f)
	var tier: float = by.tier
	var WS: float = SimConst.WS
	var spN: float = SimDetMath.hypot(f.vx / f.launchT, f.vy)
	var vert: float = absf(f.vy) / SimMathx.jmax(sp, 0.000001)
	var sea: bool = WorldTerrain.seaAt(S, f.x)
	f.y = g
	if spN > WorldSlide.MIN_IMPACT:
		var r: float = (28.0 + spN * 0.05 + tier * 12.0) * WS
		var E: float = WorldCrater.impactEnergy(spN, tier)
		var slam: bool = sea or vert >= WorldSlide.SLAM_VERT
		# A very hard slam makes its mark on the first contact and then hops once; the hop's landing digs nothing more (the
		# hard hit makes the crater, never the lighter one after it). A slide never hops: it starts at the first contact.
		var hop: bool = slam and not sea and spN >= WorldSlide.HOP_SPEED and not f.hopped
		if slam and not f.hopped:
			WorldCrater.dig(S, f.x, E, by, "impact", f.vx / f.launchT / SimMathx.jmax(spN, 0.000001), vert, f.launchSpecial)
		if sea:
			SimFx.splash(S, f.x, g + 10.0, 14, f.z)
		else:
			SimFx.debris(S, f.x, g + 8.0, 12, "#6d6a66", 500.0, f.z)
			SimFx.dust(S, f.x, g, 4, "", f.z)
		SimFx.ring(S, f.x, g + 10.0, 700.0 + spN * 0.2, "#ffffff", 0.45, 10.0, f.z)
		var slideStart: bool = not slam
		var touch: float = WorldSlide.TOUCH_AREA if slideStart else 1.0
		WorldStructures.damageArea(S, f.x, g + 5.0, r * 1.7, spN * (0.22 + 0.12 * tier) * touch, by)
		SimFx.shake(S, SimMathx.jmin(30.0, spN * 0.01), f.x, f.z)
		S.dirS.stop = SimMathx.jmax(S.dirS.stop, 0.06)
		SimDamage.hurt(S, f, spN * 0.018 * (WorldSlide.TOUCH_DMG if slideStart else 1.0), by)
		if hop:
			f.hopped = true
			f.vy = absf(f.vy) * WorldSlide.HOP_LIFT
			return
		if slideStart:
			WorldSlide.begin(S, f, by, spN, E)
			return
	f.state = "down"
	f.stateT = 0.0
	f.vx = 0.0
	f.vy = 0.0
	f.bounces = 0.0
	f.launchBy = null
	f.launchT = 1.0
	f.launchSpecial = false
	f.launchPower = 1.0
	f.hopped = false
	WorldBrunt.endFlight(S, f)


## Launched flight: gravity, air drag, water (with the skip), the aimed building (B2), the ground (slam or slide) and the
## ceiling. A fighter that is sliding is handled by WorldSlide.step.
static func stepLaunched(S: SimState, f, dt: float) -> void:
	if S.flightOn:
		dt = SimFlight.pace(S, f, dt)   # the launch's curve: his first leg is paced along its path (sim/core/flight.gd)
	f.stateT += dt
	WorldBrunt.stepZ(S, f, dt)
	if S.contactOn:   # ground contact (world/contact.gd): leave, land, bounce, skid, tumble
		WorldContact.stepFighter(S, f, dt)
		return
	if f.slide > 0.0:
		WorldSlide.step(S, f, dt)
		return
	f.vy -= 1000.0 * dt
	f.vx *= SimDetMath.pow(0.55, dt)
	var ox: float = f.x
	var oy: float = f.y
	f.x = SimWrap.wrap(f.x + f.vx * dt)
	f.y += f.vy * dt
	spin(S, f, dt, SPIN_AIR)
	var wsurf: float = WorldWater.surfaceAt(S, f.x)
	var inW: bool = f.y < wsurf
	if inW and not f.wet:
		f.wet = true
		SimFx.splash(S, f.x, wsurf, 12, f.z)
		SimFx.ring(S, f.x, wsurf, 500.0, "#bfe6ff", 0.5, 10.0, f.z)
		var wsp: float = SimDetMath.hypot(f.vx, f.vy)
		# A fast, shallow entry skips off the surface like a stone; a steep or slow one goes in and is slowed as before.
		if f.vy < 0.0 and wsp > WorldWater.SKIM_MIN_SPEED and -f.vy < absf(f.vx) * WorldWater.SKIM_MAX_TAN and f.bounces < WorldWater.SKIM_MAX:
			f.bounces += 1.0
			f.y = wsurf
			f.vy = -f.vy * WorldWater.SKIM_LIFT
			f.vx *= WorldWater.SKIM_KEEP
			f.wet = false
			inW = false
			SimFx.splash(S, f.x, wsurf, 8, f.z)
			SimFx.skim(S, f.x, wsurf, wsp, int(f.bounces), f.z)
	if not inW and f.wet and f.y > wsurf:
		f.wet = false
	if inW:
		f.vy += WATER_BUOY * dt
		f.vx *= SimDetMath.pow(0.05, dt)
		f.vy *= SimDetMath.pow(0.1, dt)
		if SimDetMath.hypot(f.vx, f.vy) < 200.0 and f.stateT > SimForms.recoverAfter(S, f, 0.3):   # (forms: sooner by his steps)
			f.state = "free"
			spin(S, f, dt, SPIN_STOP)
			f.launchT = 1.0
			WorldBrunt.endFlight(S, f)
			return
	var hitNow: bool = WorldBrunt.checkHit(S, f, ox, oy)   # B2: only the building the launch is aimed at can be hit
	var g: float = WorldTerrain.groundY(S, f.x)
	if f.y <= g and not (hitNow and f.aimB >= 0):   # a chain link gets its next tick first (chainPlan's order)
		impact(S, f, g, SimDetMath.hypot(f.vx, f.vy))
	if f.y > SimConst.CEILING:
		f.y = SimConst.CEILING
		f.vy = SimMathx.jmin(f.vy, 0.0)


## A drop (melee-press-feel.md section 2c, the zip's knock-down): f falls from where he is and is out of control for
## ticks live ticks, as in a tumble. It is not a launch: he has no launcher and no ground-contact journey, and reaching the
## ground hurts nothing, wears nothing, digs nothing and scores nothing. His rush, if he has one, ends here. vx and vy are
## the speed he starts with (none: he falls straight down). When the ticks run out he is free where he is, in the air or
## on the ground. The director may end it sooner (a tech): dropEnd. Returns false, and does nothing, for a fighter who is
## launched, down or already dropped, or after a KO. For the view he is airborne as a launched fighter is: stateT counts
## up from 0, vx and vy are his speed, and his spin is 0 (his rot eases out as a free fighter's does).
static func drop(S: SimState, f, ticks: int, vx: float = 0.0, vy: float = 0.0, vz: float = 0.0) -> bool:
	if ticks <= 0 or S.game.ko != null or f.state == "launched" or f.state == "down" or f.state == "dropped":
		return false
	f.rush = null
	f.state = "dropped"
	f.dropT = ticks
	f.stateT = 0.0
	f.spin = 0.0
	f.vx = vx
	f.vy = vy
	if S.depthOn:   # a drop's depth part is one motion: the cap does not hold it
		f.vz = 0.0
		f.vzX = vz
	SimFx.dropStart(S, f, ticks)
	return true


## End f's drop now. how is the word on the drop_end event: "end" when its ticks ran out, or the caller's (a tech).
static func dropEnd(S: SimState, f, how: String = "end") -> void:
	if f.state != "dropped":
		return
	f.state = "free"
	f.dropT = 0
	f.vx = 0.0
	f.vy = 0.0
	f.vz = 0.0
	f.vzX = 0.0
	SimFx.dropEnd(S, f, how)


## Where f's rush puts him at u, from 0 (where it began) to 1 (its target): [x, y]. It is the straight line to the target
## as the target is now, plus the bow: Rush.arc x 4u(1 - u), square to that line, on the mover's left for an arc above 0
## (up when he travels toward +x, down toward -x). A bowed path is held by the ground and the ceiling. The step of a bowed
## rush is this function, so a view that wants the path's direction takes rushAt(u + a little) - rushAt(u) and cannot
## disagree with the sim. A straight rush steps as it always did (toward its target by the time left); that is the same
## line while the target stands still. Before the rush's first step it begins where he is. With no rush it is where he
## is. Read-only. (An array of two float64, not a Vector2: Godot's Vector2 is 32-bit.)
static func rushAt(S: SimState, f, u: float) -> PackedFloat64Array:
	var r = f.rush
	if r == null:
		return PackedFloat64Array([f.x, f.y])
	var tx: float = r.tgt.x + r.off if r.tgt != null else r.px
	var ty: float = r.tgt.y if r.tgt != null else r.py
	var sx: float = r.x0 if r.dur > 0.0 else f.x
	var sy: float = r.y0 if r.dur > 0.0 else f.y
	var uu: float = SimMathx.jclamp(u, 0.0, 1.0)
	var bx: float = SimWrap.sdx(sx, tx)
	var by: float = ty - sy
	var x: float = sx + bx * uu
	var y: float = sy + by * uu
	if r.arc != 0.0:
		var bl: float = SimDetMath.hypot(bx, by)
		var bow: float = r.arc * 4.0 * uu * (1.0 - uu)
		if bl > 0.0:
			x += -by / bl * bow
			y += bx / bl * bow
		else:
			y += bow
		x = SimWrap.wrap(x)
		y = SimMathx.jclamp(y, WorldTerrain.groundY(S, x, f.z), SimConst.CEILING)
	return PackedFloat64Array([SimWrap.wrap(x), y])


## How far along his rush f is now, from 0 to 1: after a tick's step it is where that step put him, so rushAt(S, f,
## rushU(S, f)) is his place on a bowed rush. 0 for a rush that has not taken a step; 1 with no rush.
static func rushU(S: SimState, f) -> float:
	var r = f.rush
	if r == null:
		return 1.0
	if r.dur <= 0.0:
		return 0.0
	return SimMathx.jclamp(1.0 - (r.end - S.T - SimConst.DT) / r.dur, 0.0, 1.0)


static func stepRush(S: SimState, f, dt: float) -> void:
	var r = f.rush
	if r == null:
		return
	var tx: float = r.tgt.x + r.off if r.tgt != null else r.px
	var ty: float = r.tgt.y if r.tgt != null else r.py
	var rem: float = r.end - S.T
	var tz: float = (r.tgt.z + r.offZ) if r.tgt != null else r.pz   # L2: the rush's depth (used only when S.depthOn); offZ puts him a little to one side of his target
	if rem <= dt:
		f.x = SimWrap.wrap(tx)
		f.y = SimMathx.jmax(ty, WorldTerrain.groundY(S, tx))
		if S.depthOn:
			f.z = clampf(tz, SimDepth.zBack, SimDepth.zFront)
			f.zT = f.z   # he stays where the rush took him
			f.vz = 0.0
			f.vzX = 0.0
			f.y = SimMathx.jmax(ty, WorldTerrain.groundY(S, tx, f.z))   # on the ground at his depth
		f.rush = null
		f.vx = 0.0
		f.vy = 0.0
		return
	var k: float = dt / rem
	SimFx.afterimage(S, f, 0.16)
	if r.dur <= 0.0:   # the rush's first step: where it began and how long it had (rushAt reads them)
		r.x0 = f.x
		r.y0 = f.y
		r.dur = rem
	if r.arc != 0.0:
		# A bowed rush (Rush.arc): each step is worked out from the rush's start (rushAt), so nothing drifts, and it
		# arrives with the straight rush, on the same tick.
		var at: PackedFloat64Array = rushAt(S, f, 1.0 - (rem - dt) / r.dur)
		f.x = at[0]
		f.y = at[1]
	else:
		f.x = SimWrap.wrap(f.x + SimWrap.sdx(f.x, tx) * k)
		f.y += (ty - f.y) * k
	if S.depthOn:
		f.z = clampf(f.z + (tz - f.z) * k, SimDepth.zBack, SimDepth.zFront)


## A fighter's depth, only when S.depthOn (docs/architecture/depth-core.md). No stick steers it.
##   a flight      World's waypoint moves z (WorldBrunt.stepZ), and he stays where it leaves him
##   a rush        homes in depth (stepRush), and he stays where it takes him
##   otherwise     the director's velocity moves him: vz, held to the cap (depth.json maxBhPerSec), and vzX, which the cap
##                 does not hold. The branches of stepFighter damp both as they damp vx.
##   a free fighter also eases to his home depth zT, at the cap at most. The director moves the home; a velocity carries
##                 it along, so a shove leaves him where it sent him. A locked fighter has no home of his own.
## The band (World's lane table: SimDepth.zBack to zFront) holds him and his home. The buildings are contact()'s.
static func stepDepth(S: SimState, f, dt: float) -> void:
	if f.state == "launched":
		f.z = clampf(f.z, SimDepth.zBack, SimDepth.zFront)
		f.zT = f.z
		f.vz = 0.0
		f.vzX = 0.0
		return
	if f.rush != null:
		f.zT = f.z
		return
	if f.state == "down":
		f.vz = 0.0
		f.vzX = 0.0
	var step: float = (clampf(f.vz, -SimDepth.cap, SimDepth.cap) + f.vzX) * dt
	f.z += step
	if f.state == "locked":
		f.zT = f.z
	else:
		f.zT = clampf(f.zT + step, SimDepth.zBack, SimDepth.zFront)
		var d: float = f.zT - f.z
		if d != 0.0:
			var m: float = SimDepth.cap * dt
			f.z += clampf(d, -m, m)
	if f.z > SimDepth.zFront:
		f.z = SimDepth.zFront
		f.vz = minf(f.vz, 0.0)
		f.vzX = minf(f.vzX, 0.0)
	elif f.z < SimDepth.zBack:
		f.z = SimDepth.zBack
		f.vz = maxf(f.vz, 0.0)
		f.vzX = maxf(f.vzX, 0.0)
	if f.state == "locked":
		f.zT = f.z


## The contact rule for a fighter outside a flight, only when S.depthOn (Game Design, docs/design/depth.md section 2: a
## face stops the part of the motion that runs into it, and the rest slides on). His step this tick, from (x0, y0, z0)
## to where he now is, is swept against the standing buildings along it (World's sweep). At a face he is put there, the
## part of his velocity into it ends, and the rest of the step is swept again: three times at most, once an axis, so a
## corner stops him. In a street the depth part stops at a block's face and the part along the street goes on; at a
## crossing nothing is met; in an avenue the part along the street stops at a block's end and he slides down the avenue;
## on a roof he stands. A wreck is not a standing building. A body that starts inside one is put out by its nearest face.
## His centre keeps SimDepth.rx and rz (the body's half extents, and the data's margin at least) from a face. In a street
## lane, where World builds nothing, no sweep is made.
static func contact(S: SimState, f, x0: float, y0: float, z0: float) -> void:
	if SimDepth.clearStreet(z0, f.z):
		return
	var rx: float = SimDepth.rx
	var ry: float = SimDepth.ry
	var rz: float = SimDepth.rz
	var list: Array = WorldStructures.along(S, x0, f.x, rx)
	if list.is_empty():
		return
	var px: float = x0
	var py: float = y0
	var pz: float = z0
	var tx: float = f.x
	var ty: float = f.y
	var tz: float = f.z
	var clear: bool = false
	var hitZ: bool = false
	for pass_ in range(3):
		var h: Dictionary = WorldStructures.sweep(S, list, px, py, pz, tx, ty, tz, rx, ry, rz)   # the sweep's point is his feet, as f.y is
		if not h.hit:
			clear = true
			break
		var b = S.buildings[h.b]
		px = h.x
		py = h.y
		pz = h.z
		if h.face == "end":
			px = SimWrap.wrap(b.x + h.nx * (b.w * 0.5 + rx + SimDepth.SKIN))
			tx = px
			if f.vx * h.nx < 0.0:
				f.vx = 0.0
		elif h.face == "front" or h.face == "back":
			pz = b.z + h.nz * (b.d * 0.5 + rz + SimDepth.SKIN)
			tz = pz
			hitZ = true
			if f.vz * h.nz < 0.0:
				f.vz = 0.0
			if f.vzX * h.nz < 0.0:
				f.vzX = 0.0
		elif h.face == "top":
			py = WorldStructures.baseY(S, b) + WorldStructures.curH(b) + SimDepth.SKIN
			ty = py
			if f.vy < 0.0:
				f.vy = 0.0
		else:   # the underside: a building stands on the ground, so nothing comes up into it; he stays where they met
			tx = px
			ty = py
			tz = pz
	if not clear:
		tx = px
		ty = py
		tz = pz
	f.x = tx
	f.y = ty
	f.z = tz
	if hitZ or f.state == "locked":
		f.zT = f.z   # a face stopped him in depth: his home is where he is until the director moves it


## The director's own step for a fighter this tick: a blow's closing step, a placement. He is moved from where he is to
## (x, y, z) through the contact rule, with no cap: it is an attack closing, as a rush is. He stays where it puts him.
## Returns true when no face stopped him short. With depth off it is the plain assignment the director made before
## (x wrapped, y as given), and z is left alone.
static func stepTo(S: SimState, f, x: float, y: float, z: float) -> bool:
	if not S.depthOn:
		f.x = SimWrap.wrap(x)
		f.y = y
		return true
	var x0: float = f.x
	var y0: float = f.y
	var z0: float = f.z
	var wx: float = SimWrap.wrap(x)
	var wz: float = clampf(z, SimDepth.zBack, SimDepth.zFront)
	f.x = wx
	f.z = wz
	f.y = SimMathx.jmax(y, WorldTerrain.groundY(S, wx, wz))
	contact(S, f, x0, y0, z0)
	f.zT = f.z
	return f.x == wx and f.z == wz


## One cause's velocity in depth for f, units a second, added to the velocity the cap holds (vz) or, when the data lists
## the cause under capExempt, to the one it does not (vzX). The causes are SimDepth.CAUSES. The director may also write
## the two fields itself, where it writes vx and vy.
static func addDepth(f, cause: String, v: float) -> void:
	if not SimDepth.CAUSES.has(cause):
		push_error("SimFighter.addDepth: unknown cause " + cause)
	if SimDepth.isExempt(cause):
		f.vzX += v
	else:
		f.vz += v


## Body rotation, in one place (rot and spin are for Animation; nothing in gameplay reads them). how: SPIN_AIR, a launched
## body turns by its spin; SPIN_FREE, a free body eases upright; SPIN_STOP, a body that stops in water or gets up is
## upright at once. World's ground-contact model (G2) replaces these rules through this one function, so that rot is only
## integrated or eased and never jumps.
const SPIN_AIR: int = 0
const SPIN_FREE: int = 1
const SPIN_STOP: int = 2
static func spin(S: SimState, f, dt: float, how: int) -> void:
	if S.contactOn:   # the journey's own rolling (world/contact.gd): rot only integrated or eased
		WorldContact.spinFighter(f, dt, how)
		return
	if how == SPIN_AIR:
		f.rot += f.spin * dt
	elif how == SPIN_FREE:
		f.rot *= SimDetMath.pow(0.001, dt)
	else:
		f.rot = 0.0


## The last stand (spec-wounds.md section 1b, point 7; docs/architecture/last-stand.md). The first time a fighter reaches
## the brink in a match, one signature is free and off cooldown for his window (wounds.json lastStand.windowS). The window
## counts live ticks in which he is free or charging and not stunned, so it starts when he is next free; it closes when he
## fires (lastStandUse) or runs out. A second brink gives nothing. The director's signature gates read sigFree().
static func lastStandOpen(S: SimState, f) -> void:
	if f.lastStandUsed or f.wd.lastStandTicks <= 0:
		return
	f.lastStandUsed = true
	f.lastStandLeft = f.wd.lastStandTicks
	SimFx.lastStandReady(S, f, float(f.wd.lastStandTicks) / 60.0)


static func sigFree(f) -> bool:
	return f.lastStandLeft > 0


static func lastStandUse(S: SimState, f) -> void:
	if f.lastStandLeft > 0:
		f.lastStandLeft = 0
		SimFx.lastStandEnd(S, f, "used")


## The tier a fighter's power has earned: 1, plus one per threshold reached.
static func tierByPower(f) -> float:
	var nt: float = 1.0
	for th in f.ld.thresholds:
		if f.power >= th:
			nt += 1.0
	return nt


## The ladder's last tier: 1 plus its thresholds (four tiers today). No fighter goes past it. In a match the core readies
## a form only when his power's tier is above his own, so the three guards that read this (transform, formBreak and
## stepFighter) never act there. They hold the line for whatever sets act.formReady by hand, such as a test's staging.
static func topTier(f) -> float:
	return 1.0 + float(f.ld.thresholds.size())


## I2a: take a ready form (ladder.json manualTierUp): the tier rises one step with today's power-up. The director's
## placeholder transform calls it between exchanges (I2b). Returns false if nothing was ready, or if he is on the
## ladder's last tier: the form is dropped, with any gather asked for it.
static func transform(S: SimState, f) -> bool:
	if SimForms.has(S, f):   # forms: the release takes every banked step (sim/core/forms.gd)
		return SimForms.take(S, f)
	if not f.act.formReady:
		return false
	f.act.formReady = false
	if f.tier >= topTier(f):
		f.act.breakIn = -1
		return false
	if S.formsOn:   # forms: a one-step take is told too, for the waiting game
		SimForms.released(S, f, 1, 0.0, 0, f.tier + 1.0)
	if f.act.breakIn <= 0:   # no gather was asked for (SimPause.request sets it), or it is 0: the break is now
		formBreak(S, f)
	return true


## The break of a transformation (moveset-rules.md section 10.8): the tier rises with today's power-up (the burst, the
## crater and area damage near the ground, tier_up). It comes at the end of the version's gather: on a frozen tick inside
## a full or short pause (SimPause.frozenTick), on a live tick otherwise (stepFighter). A further step already earned is
## ready at once.
static func formBreak(S: SimState, f) -> void:
	f.act.breakIn = -1
	if SimForms.has(S, f):   # forms: his taken steps rise, with the coil's release
		SimForms.rise(S, f)
		return
	if f.tier >= topTier(f):   # the one line that raises a tier by a step never passes the ladder's last
		return
	f.tier += 1.0
	tierUp(S, f)
	if tierByPower(f) > f.tier:
		f.act.formReady = true
		SimFx.transformReady(S, f, f.tier + 1.0, DirExchange.transformSource(f))
	DirExchange.formBreak(S, f)   # the rival in reach is pushed back at the break


## The speed f flies at in free flight now, in units a second: his own speed and tier, his legs, his stance, the dash
## (dash: he holds it; far from the rival it is the traversal dash) and the sea. The free branch of stepFighter steers his
## velocity toward the stick times this (the vertical toward 0.85 of it). One read for the director and the view.
static func flightSpeed(S: SimState, f, dash: bool) -> float:
	var sp: float = 430.0 * f.spd * SimForms.speedMul(S, f)   # the tier's step (with forms: his own steps, by the coil's factor on his form)
	if SimWounds.battered(f, SimWounds.LEGS):
		sp *= f.wd.legsSpeed
	if f.stance == 2.0:
		sp *= 1.25
	if f.stance == 3.0:
		sp *= 1.35
	if f.stance == 1.0:
		sp *= 0.8
	if dash:
		sp *= 2.4
		# Traversal: flat out and far from the opponent, the dash is TRAV_FREE times faster (a lap of the planet in about
		# 15 s); close in, it is the melee dash it always was.
		var sep: float = absf(SimWrap.sdx(f.x, SimRoster.opp(S, f).x))
		sp *= 1.0 + (SimConst.TRAV_FREE - 1.0) * SimMathx.jclamp((sep - SimConst.BOOST_NEAR) / (SimConst.BOOST_FAR - SimConst.BOOST_NEAR), 0.0, 1.0)
	if f.y < 0.0 and WorldTerrain.seaAt(S, f.x):
		sp *= 0.55
	return sp


## A locked fighter's speed dies away: over a second he keeps LOCKED_DAMP of it.
const LOCKED_DAMP: float = 0.03


## The share of his speed a locked fighter keeps over one step of dt seconds: about 0.943 a tick. The locked step damps
## first and moves after, and the director's update runs after the fighters' step. So a velocity the director sets on a
## locked fighter on one tick moves him on the next, by this share of it. Divide by it for the full step.
static func lockedKeep(dt: float) -> float:
	return SimDetMath.pow(LOCKED_DAMP, dt)


static func stepFighter(S: SimState, f, dt: float) -> void:
	var o = SimRoster.opp(S, f)
	var x0: float = f.x   # where the tick found him: with depth on, the contact rule sweeps his step from here
	var y0: float = f.y
	var z0: float = f.z
	var rushed: bool = f.rush != null
	if f.state != "launched":
		f.flightHits = 0
	var i: SimIntent = f.input
	if S.brakeOn:
		SimBrake.tick(S, f, dt)   # the air brake: a sent fighter who holds it slows, and has control back under a third of the send's speed
	f.power = SimMathx.jmin(100.0, f.power + f.ld.fill * dt)
	var nt: float = tierByPower(f)
	var steps: bool = SimForms.has(S, f)   # forms: his own steps (sim/core/forms.gd) in place of the ladder's thresholds
	if f.act.formReady and not steps and f.tier >= topTier(f):   # a form readied with no tier above it is dropped, before the director can take it
		f.act.formReady = false
	if f.act.breakIn > 0 and S.game.ko == null:   # a live transformation's gather: the break lands here
		f.act.breakIn -= 1
		if f.act.breakIn == 0:
			formBreak(S, f)
	if steps:
		SimForms.readyTick(S, f, dt)   # his ready steps, banked while he waits; the coil
	elif nt > f.tier and f.act.breakIn < 0:   # (not while a taken step waits for its break)
		if f.ld.manualTierUp:
			if not f.act.formReady: SimFx.transformReady(S, f, f.tier + 1.0, DirExchange.transformSource(f))   # I2b: the rising edge
			f.act.formReady = true   # I2a: the tier waits for the transform (transform())
		else:
			f.tier = nt
			tierUp(S, f)
	if S.formsOn:
		SimForms.holdTick(S, f)   # forms: how long a ready form is held, told for the waiting game (every fighter's)
	if f.lastStandLeft > 0 and (f.state == "free" or f.state == "charging") and f.stunTicks == 0 and S.game.ko == null:
		f.lastStandLeft -= 1   # the last stand's window
		if f.lastStandLeft == 0:
			SimFx.lastStandEnd(S, f, "expired")
	var regen: float = 5.0 + (25.0 if f.hidden and f.canHide else 0.0)
	if f.hasMenace:
		var bonus: float = f.menace * f.md.menaceRegen
		if f.md.menaceRegenCap >= 0.0:
			bonus = SimMathx.jmin(f.md.menaceRegenCap, bonus)
		regen += bonus
	else:
		var pen: float = f.anguish * f.md.anguishRegen
		if f.md.anguishRegenCap >= 0.0:
			pen = SimMathx.jmin(f.md.anguishRegenCap, pen)
		regen = SimMathx.jmax(1.0, regen - pen)
	if f.hasAnguish:
		f.anguish = SimMathx.jmax(0.0, f.anguish - f.md.anguishDecay * dt)
	# Menace decays when it is not fed (balance-targets.md section 9, S0): after f.md.menaceDelay ticks without a rise it
	# falls by f.md.menaceDecay per second. At the cap a casualty cannot raise it, so there a rise in world casualties also
	# counts as fed. (sim/world stays untouched: menace only ever rises through a casualty.)
	var fed: bool = f.menace > f.menaceSeen or (f.menace >= 100.0 and S.world.casualties > f.casSeen)
	f.menaceQuiet = 0 if fed else f.menaceQuiet + 1
	if f.menaceQuiet > f.md.menaceDelay:
		f.menace = SimMathx.jmax(0.0, f.menace - f.md.menaceDecay * dt)
	f.menaceSeen = f.menace
	f.casSeen = S.world.casualties
	if SimWounds.battered(f, SimWounds.CORE):
		regen *= f.wd.coreKiRegen
	if steps:
		regen *= SimForms.regenMul(f)   # forms: his steps' regen gain
	if f.state == "free" or f.state == "locked" or f.state == "down":
		f.ki = SimMathx.jmin(100.0, f.ki + regen * dt)
	if f.hidden and f.canHide:
		f.hp = SimMathx.jmin(f.maxhp, f.hp + 40.0 * dt)
	SimWounds.step(S, f)   # wound recovery (wounds.gd)
	if f.state != "launched":
		spin(S, f, dt, SPIN_FREE)

	if f.rush != null:
		stepRush(S, f, dt)
	elif f.state == "free":
		var dxo: float = SimWrap.sdx(f.x, o.x)
		if absf(dxo) > 20.0:
			f.face = 1.0 if dxo > 0.0 else -1.0
		if i.charge:
			f.state = "charging"
			if f.hidden:
				SimHiding.regainLock(S, f)   # charging gives him away: the lock comes back announced (found, and no new break for a while)
		else:
			var sp: float = flightSpeed(S, f, i.dash)
			var k: float = 1.0 - SimDetMath.pow(0.0008, dt)
			f.vx += (i.mx * sp - f.vx) * k
			f.vy += (i.my * sp * 0.85 - f.vy) * k
			if S.depthOn:   # no stick steers depth: a velocity in depth dies away as his own does with the stick at rest
				f.vz += (0.0 - f.vz) * k
				f.vzX += (0.0 - f.vzX) * k
			f.x = SimWrap.wrap(f.x + f.vx * dt)
			f.y += f.vy * dt
			var g: float = WorldTerrain.groundY(S, f.x, f.z)   # at his depth (the plane's when depth is off)
			if f.y < g:
				f.y = g
				if f.vy < 0.0:
					f.vy = 0.0
			if f.y > SimConst.CEILING:
				f.y = SimConst.CEILING
				f.vy = 0.0
	elif f.state == "charging":
		if not i.charge:
			f.state = "free"
		else:
			f.vx *= 0.85
			f.vy *= 0.85
			if S.depthOn:
				f.vz *= 0.85
				f.vzX *= 0.85
			f.ki = SimMathx.jmin(100.0, f.ki + 30.0 * dt)
			f.power = SimMathx.jmin(100.0, f.power + f.ld.charge * dt)   # Q10: ladder.json chargePerSec
			SimFx.chargeFx(S, f, WorldTerrain.groundY(S, f.x, f.z))   # the aura's sparks and dust are cosmetic: the consumer rolls them
	elif f.state == "down":
		if f.embedT > 0:   # embedded (World, ground-contact.md section 19): held down for these ticks; the guard from tick 20 and the burst out belong to the director
			f.embedT -= 1
			f.stateT = 0.4 if f.embedT == 0 else 0.0   # then the usual short get-up
		else:
			f.stateT += dt
		if S.depthOn:   # the surface under him at his depth: the ground there, or the roof he lies on
			f.y = WorldStructures.standingAt(S, f.x, f.y, f.z).y
		else:
			f.y = WorldTerrain.groundY(S, f.x)
		if f.stateT > 0.75:
			f.state = "free"
			spin(S, f, dt, SPIN_STOP)
	elif f.state == "launched":
		stepLaunched(S, f, dt)
		if S.flightOn:
			SimFlight.settle(S, f)   # a contact this tick ends the curve's leg, told now
	elif f.state == "dropped":
		# a drop (SimFighter.drop): he reads no stick and falls; the ground only stops him
		var gd0: float = WorldTerrain.groundY(S, f.x, f.z)
		var above: bool = f.y > gd0
		f.stateT += dt
		f.vy -= DROP_GRAV * dt
		f.vx *= SimDetMath.pow(0.55, dt)
		if S.depthOn:
			var dk: float = SimDetMath.pow(0.55, dt)
			f.vz *= dk
			f.vzX *= dk
		f.x = SimWrap.wrap(f.x + f.vx * dt)
		f.y = SimMathx.jmin(f.y + f.vy * dt, SimConst.CEILING)
		var gd: float = WorldTerrain.groundY(S, f.x, f.z)
		if f.y <= gd:
			f.y = gd
			f.vx = 0.0
			f.vy = 0.0
			f.vz = 0.0
			f.vzX = 0.0
			if above:
				SimFx.dropLand(S, f)
		f.dropT -= 1
		if f.dropT <= 0:
			dropEnd(S, f, "end")
	elif f.state == "locked":
		var keep: float = lockedKeep(dt)
		f.vx *= keep
		f.vy *= keep
		if S.depthOn:   # the director's velocity in depth, damped as the other two are: a push along the line keeps its angle
			f.vz *= keep
			f.vzX *= keep
		f.x = SimWrap.wrap(f.x + f.vx * dt)
		f.y = SimMathx.jmax(WorldTerrain.groundY(S, f.x, f.z), f.y + f.vy * dt)
	if S.depthOn:
		stepDepth(S, f, dt)   # his depth: the director's velocity, his home, the band
		if not rushed and f.state != "launched" and f.state != "down":
			contact(S, f, x0, y0, z0)   # and the buildings: he stops at a face, and the rest of his step slides
			var gz: float = WorldTerrain.groundY(S, f.x, f.z)   # the ground at the depth he has come to
			if f.y < gz:
				f.y = gz
	if S.game.ko == null:
		SimHiding.updateHidden(S, f, dt)
