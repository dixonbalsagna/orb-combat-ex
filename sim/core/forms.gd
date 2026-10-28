class_name SimForms
extends RefCounted
## The Protagonist's five steps and the slingshot (Game Design, docs/design/hero-forms.md sections 4 and 4b; the core's
## side: docs/architecture/forms-core.md). A fighter whose data/fighters/<id>/forms.json names steps takes them at its
## powers: five modest all-round steps, his tier for the world stepping at three of them as everyone's does. A step that
## comes ready while he waits is banked, and the coil fills while he holds. A release takes the next step only, and the
## coil makes that one form stronger (Game Design's working rule, 2026-10-18). The hold and the release are told for
## every fighter (form_hold,
## form_release), for the waiting game's lines (docs/narrative/waiting-game-lines.md).
##
## The switch is data/fight/forms.json "enabled" (off), which SimCore.newMatch copies into S.formsOn unless the setup has
## its own "forms". Off, nothing here runs: every gain below returns today's number, no form state is hashed, no event is
## sent, and neither file is in a replay's data hash. No draw from S.rng anywhere here.

const FILE: String = "forms.json"
const KINDS: Array = ["live", "pausing"]
## The form state the gameplay hash reads, only while S.formsOn (hash.gd).
const HASHED: Array = ["step", "ready", "coil", "coiling", "holdT", "held", "pend", "pendCoil", "formMul", "witness", "trial", "branch", "crossed"]


## One fighter's steps and slingshot (his forms.json). Read-only after load.
class FormsDef:
	var steps: Array = []          # [{power, tier, kind, id}], in order of power
	var gSpeed: float = 0.0        # each step taken: free-flight speed, damage and launch force x (1 + g x steps)
	var gDamage: float = 0.0
	var gLaunch: float = 0.0
	var gChip: float = 0.0         # ... a guarded hit's damage that reaches him x (1 - g x steps)
	var gRegen: float = 0.0        # ... ki regen x (1 + g x steps)
	var gRecover: float = 0.0      # ... a launch's recovery after x (1 - g x steps)
	var coilPerSec: float = 0.0    # the coil: per second of fight time while it fills
	var coilPerDamage: float = 0.0 # ... per point of damage traded, dealt or taken
	var coilBehind: float = 1.0    # ... both times this while the opponent's tier is above his
	var coilMax: float = 100.0
	var patiencePerTier: float = 0.0   # less damage taken a tier below, while he holds banked steps
	var patienceMax: float = 0.0
	var minCoil: float = 0.0       # the coil a release needs to make its form stronger (a step taken at once has a sliver)
	var perPoint: float = 0.0      # the form's step gains x (1 + coil x perPoint) ...
	var maxMul: float = 1.0        # ... at most this, for as long as he is in it
	# The branches (hero-forms.md section 3): the steps that pick one, the fills' sources and each branch's extras
	var branchAt: Array = []      # the steps (1-based) at which a release picks a branch: II and IV
	var wRange: float = 0.0       # Witness: an opponent's kill this near him (shortest arc) fills it ...
	var wPerPerson: float = 0.0   # ... by this a person, times 425 / pop0 as every gain a person
	var wOwnKill: float = 0.0     # ... and each person he kills takes this off it
	var wDamage: float = 0.0      # in a Witness form: damage and launch force x (1 + these), his care + wCare
	var wLaunch: float = 0.0
	var wCare: float = 0.0
	var tForm: float = 0.0        # Trial: the opponent takes a form while his tier is no higher ...
	var tFormHeld: float = 0.0    # ... this instead when his own form was ready and he held it
	var tPerSec: float = 0.0      # ... a second of fight time while the opponent's tier is above his
	var tBlow: float = 0.0        # ... a blow of a medium or more he lands while it is
	var tCommit: float = 0.0      # ... the opponent commits fully: a finisher, a beam clash, fighting on at the brink
	var tSpeed: float = 0.0       # in a Trial form: speed x (1 + this); the perfect-block window wider by tBlock[level - 1]
	var tBlock: Array = [0, 0]    # ticks; perfect follow-ups worth tFollow more (the director reads both)
	var tFollow: int = 0
	var firstTie: String = "trial"   # the pick's first tie (he is on no branch yet)


static var _defs = null          # id -> FormsDef, for the fighters whose folder has a forms.json
static var _from: String = ""    # the folders the defs were read from (FighterData's: a test may point them elsewhere)
static var _on: bool = false     # data/fight/forms.json enabled
static var _signalTicks: int = 0 # data/fight/forms.json hold.signalTicks
static var _hash: String = ""
static var _errors: Array = []


static func _ensure() -> void:
	var from: String = FighterData.root + "|" + FighterData.shared
	if _defs != null and _from == from:
		return
	_defs = {}
	_from = from
	_errors = []
	_on = false
	_signalTicks = 0
	var h := SimHash.Hasher.new()
	var sp: String = FighterData.shared + FILE
	if FighterData.shared != "" and FileAccess.file_exists(sp):
		var j = FighterData._load(sp, "fight/forms.json")
		if j is Dictionary:
			h.text("fight/forms.json")
			FighterData._canon(h, j)
			if not (j.get("enabled") is bool):
				_err("fight/forms.json: enabled must be true or false")
			_on = j.get("enabled") == true
			var hd = j.get("hold", {})
			_signalTicks = _int("fight/forms.json: hold.signalTicks", hd.get("signalTicks") if hd is Dictionary else null, 1)
		else:
			_err("fight/forms.json: expected an object")
	var ids: Array = FighterData.order().duplicate()
	ids.append_array(FighterData.bench())
	for id in ids:
		var p: String = FighterData.root + id + "/" + FILE
		if not FileAccess.file_exists(p):
			continue
		var fj = FighterData._load(p, id + "/" + FILE)
		if not (fj is Dictionary):
			_err(id + "/forms.json: expected an object")
			continue
		h.text(id + "/forms.json")
		FighterData._canon(h, fj)
		var d = _def(id, fj)
		if d != null:
			_defs[id] = d
	_hash = h.hex()


## Tests only: read the files again on the next call (after a fixture is written or FighterData.loadFrom moves).
static func reload() -> void:
	_defs = null


static func enabled() -> bool:
	_ensure()
	return _on


static func dataHash() -> String:
	_ensure()
	return _hash


static func errors() -> Array:
	_ensure()
	return _errors


static func def(id: String):
	_ensure()
	return _defs.get(id)


## Each fighter's form state for a new match (SimCore.newMatch): a FormState for everyone while forms are on, and his
## steps when his data has them.
static func setup(S: SimState) -> void:
	for f in S.fighters:
		f.form = SimState.FormState.new() if S.formsOn else null
		f.fd = def(f.id) if S.formsOn else null


## True when f takes his own steps in this match.
static func has(S: SimState, f) -> bool:
	return S.formsOn and f.fd != null


## The steps his power has reached.
static func byPower(f) -> int:
	var n: int = 0
	for s in f.fd.steps:
		if f.power >= float(s.power):
			n += 1
	return n


## The tier for the world he stands at once his ready steps are taken (the transform's events read it). Without steps,
## the tier above, as today.
static func nextTier(S: SimState, f) -> float:
	if not has(S, f):
		return f.tier + 1.0
	var k: int = mini(f.fd.steps.size(), f.form.step + 1)   # one step a transformation
	return float(f.fd.steps[k - 1].tier)


# ------------------------------------------------------------------------------------------------- the steps and the coil

## Each live tick, for a fighter with steps, in place of the ladder's thresholds (SimFighter.stepFighter). The steps his
## power has reached and he has not taken are ready, and banked while he waits. The coil starts at the first break in
## the fight after a step came ready (canTake: the first moment it could have been taken and wasn't), so a step that
## comes ready mid-brawl coils nothing until then; from there it fills at coilPerSec a second, coilBehind times that
## while the opponent's tier is above his. Nothing comes ready while a taken release waits for its break, as today.
static func readyTick(S: SimState, f, dt: float) -> void:
	var fs = f.form
	if SimRoster.opp(S, f).tier > f.tier:   # Trial: a second of fight time fought a tier down
		fs.trial += f.fd.tPerSec * dt
	if f.act.breakIn >= 0:
		return
	var n: int = byPower(f) - fs.step
	if n > 0:
		fs.ready = n
		if not f.act.formReady:
			SimFx.transformReady(S, f, nextTier(S, f), SimDir.transformSource(f))   # the rising edge, as today
		f.act.formReady = true
		if not fs.coiling and canTake(S, f):
			fs.coiling = true
	if fs.coiling:
		var c0: float = fs.coil
		fs.coil = SimMathx.jmin(f.fd.coilMax, fs.coil + f.fd.coilPerSec * _behind(S, f) * dt)
		fs.trial += fs.coil - c0   # each coil point is a Trial point (the coil is Trial's road: hero-forms.md section 4b)


## Damage traded (SimDamage.hurt, after what reaches him): every coil that is filling takes coilPerDamage a point, its
## victim's and its dealer's.
static func traded(S: SimState, f, by, amt: float) -> void:
	if amt <= 0.0:
		return
	for x in [f, by]:
		if x != null and has(S, x) and x.form.coiling:
			var c0: float = x.form.coil
			x.form.coil = SimMathx.jmin(x.fd.coilMax, x.form.coil + amt * x.fd.coilPerDamage * _behind(S, x))
			x.form.trial += x.form.coil - c0


## True when a ready form could be taken now: between exchanges, before a KO, with no approach running, and he is free
## or charging. It is the director's own rule for taking a transform (DirExchange._transforms), and must stay so.
static func canTake(S: SimState, f) -> bool:
	return S.dirS.ex == null and S.game.ko == null and SimDir.bandsWho(S) < 0 and (f.state == "free" or f.state == "charging")


static func _behind(S: SimState, f) -> float:
	return f.fd.coilBehind if SimRoster.opp(S, f).tier > f.tier else 1.0


## What reaches him of a hit (SimDamage.hurt): patience, while he holds banked steps and the opponent's tier is above his
## (patiencePerTier a tier between them, at most patienceMax); and on a guarded hit, his guard's step gain.
static func taken(S: SimState, f, amt: float, fam: String) -> float:
	if not has(S, f):
		return amt
	var m: float = 1.0
	var o = SimRoster.opp(S, f)
	if f.form.ready > 0 and o.tier > f.tier:
		m -= SimMathx.jmin(f.fd.patienceMax, f.fd.patiencePerTier * (o.tier - f.tier))
	if fam == "guard":
		m *= 1.0 - f.fd.gChip * float(f.form.step) * f.form.formMul
	return amt * m


# ------------------------------------------------------------------------------------------------------------- the release

## The release (SimFighter.transform, for a fighter with steps): one step a transformation. He takes the next step only,
## and the steps still ready stay ready. It rises at the break (rise), on this tick or at the end of the version's
## gather, with the coil he held. False if nothing was ready.
static func take(S: SimState, f) -> bool:
	if not f.act.formReady:
		return false
	var fs = f.form
	f.act.formReady = false
	if fs.ready <= 0 or fs.step >= f.fd.steps.size():
		f.act.breakIn = -1
		fs.ready = 0
		return false
	fs.pend = 1
	fs.pendCoil = fs.coil
	var k: int = fs.step + 1
	released(S, f, 1, fs.coil, k, float(f.fd.steps[k - 1].tier))
	fs.ready -= 1
	if f.act.breakIn <= 0:
		SimFighter.formBreak(S, f)
	return true


## A taken form, told (every fighter while forms are on): n steps, the coil spent, how long the ready step was held, the
## step it reaches (0 for a fighter without steps) and the tier for the world it brings.
static func released(S: SimState, f, n: int, coil: float, k: int, tier: float) -> void:
	SimFx.formRelease(S, f, n, coil, float(f.form.holdT) * SimConst.DT, k, tier)
	f.form.holdT = 0
	f.form.held = 0


## The break of a release (SimFighter.formBreak, for a fighter with steps): the taken step rises. His tier for the
## world follows it (with today's power-up when it rises). The coil makes this one form stronger: its step gains x
## (1 + c x perPoint), at most maxMul, for as long as he is in it; under minCoil (a step taken at once) the form is plain.
## The coil is spent. The steps still ready stay ready.
static func rise(S: SimState, f) -> void:
	var fs = f.form
	var n: int = fs.pend
	var c: float = fs.pendCoil
	fs.pend = 0
	fs.pendCoil = 0.0
	if n <= 0:
		return
	var from: int = fs.step
	fs.step = mini(f.fd.steps.size(), fs.step + n)
	var cross: bool = _pick(S, f, from)
	var s: Dictionary = f.fd.steps[fs.step - 1]
	var t: float = float(s.tier)
	if t > f.tier:
		f.tier = t
		SimFighter.tierUp(S, f)
	fs.formMul = SimMathx.jmin(f.fd.maxMul, 1.0 + c * f.fd.perPoint) if (c >= f.fd.minCoil and c > 0.0) else 1.0
	SimFx.formStep(S, f, fs.step, String(s.kind), f.tier, c, fs.branch, cross)
	fs.coil = 0.0
	fs.coiling = false
	var more: int = byPower(f) - fs.step
	if more > 0:
		fs.ready = more
		f.act.formReady = true
		SimFx.transformReady(S, f, nextTier(S, f), SimDir.transformSource(f))
	SimDir.formBreak(S, f)   # the rival in reach is pushed back at the break, as at every step


## True when the next step is a live one (SimPause.request: a live release never pauses the fight).
static func releaseLive(f) -> bool:
	var fs = f.form
	if fs.ready <= 0:
		return false
	for k in range(fs.step, mini(f.fd.steps.size(), fs.step + 1)):   # one step a transformation: the next one
		if String(f.fd.steps[k].kind) != "live":
			return false
	return true


# --------------------------------------------------------------------------------------------------------- the hold signal

## Each live tick, every fighter while forms are on (SimFighter.stepFighter): how long a ready form has been held. Once
## it has lasted the signal's ticks (data/fight/forms.json), form_hold tells it, and again for each step banked since.
static func holdTick(S: SimState, f) -> void:
	_ensure()
	var fs = f.form
	if not f.act.formReady:
		fs.holdT = 0
		fs.held = 0
		return
	fs.holdT += 1
	var n: int = fs.ready if f.fd != null else maxi(1, int(SimFighter.tierByPower(f) - f.tier))
	if fs.holdT >= _signalTicks and n > fs.held:
		fs.held = n
		SimFx.formHold(S, f, n, float(fs.holdT) * SimConst.DT, fs.coil)


# ---------------------------------------------------------------------------------------------------------------- the gains

## The step gains, with the coil's factor on the form he is in: 1 + g x steps x formMul.
static func _g(f, g: float) -> float:
	return 1.0 + g * float(f.form.step) * f.form.formMul


## Free-flight speed's tier factor (SimFighter.flightSpeed; the director's estimate of it). Without steps, today's.
static func speedMul(S: SimState, f) -> float:
	if not has(S, f):
		return 1.0 + f.ld.speed * (f.tier - 1.0)
	return _g(f, f.fd.gSpeed) * (1.0 + (f.fd.tSpeed if f.form.branch == "trial" else 0.0))


## Damage's tier factor (SimDamage.hit). Without steps, today's.
static func damageMul(S: SimState, f) -> float:
	if not has(S, f):
		return 1.0 + f.ld.damage * (f.tier - 1.0)
	return _g(f, f.fd.gDamage) * (1.0 + (f.fd.wDamage if f.form.branch == "witness" else 0.0))


## Launch force's tier factor (the director's launch planner and doLaunch). Without steps, today's.
static func launchMul(S: SimState, f) -> float:
	if not has(S, f):
		return 1.0 + f.ld.launch * (f.tier - 1.0)
	return _g(f, f.fd.gLaunch) * (1.0 + (f.fd.wLaunch if f.form.branch == "witness" else 0.0))


## His ki regen's step gain (SimFighter.stepFighter reads it only for a fighter with steps).
static func regenMul(f) -> float:
	return _g(f, f.fd.gRegen)


## A launch's recovery after t seconds: sooner by his steps. Without steps, t.
static func recoverAfter(S: SimState, f, t: float) -> float:
	if not has(S, f):
		return t
	return t * SimMathx.jmax(0.0, 1.0 - f.fd.gRecover * float(f.form.step) * f.form.formMul)


# ----------------------------------------------------------------------------------------------------------- the branches

## The pick (hero-forms.md section 4): a release whose steps pass a branch step (II, IV) takes the branch with the higher
## fill; a tie goes to the branch he is on, and the first tie (no branch yet) to firstTie. A release is one transformation,
## so it picks once, however many branch steps it passes. Taking the form empties its branch's fill, and the other keeps
## its own. A Witness form adds wCare to his care, so his launches lean further from people. True when the branch changed
## from one he was on: a cross.
static func _pick(S: SimState, f, from: int) -> bool:
	var fs = f.form
	var at: bool = false
	for k in f.fd.branchAt:
		if int(k) > from and int(k) <= fs.step:
			at = true
	if not at:
		fs.crossed = false
		return false
	var b: String = fs.branch
	if fs.witness > fs.trial:
		b = "witness"
	elif fs.trial > fs.witness:
		b = "trial"
	elif b == "":
		b = f.fd.firstTie
	var cross: bool = fs.branch != "" and b != fs.branch
	fs.crossed = cross
	fs.branch = b
	if b == "witness":
		fs.witness = 0.0
	else:
		fs.trial = 0.0
	f.care = float(FighterData.def(f.id).care) + (f.fd.wCare if b == "witness" else 0.0)
	return cross


## A casualty (WorldCollateral.kill, World's line; only while forms are on): n people died at x, and cause did it (a
## fighter, or none). A fighter with branches fills Witness by his opponent's kills within wRange of him, shortest arc
## (a guard's kills are his principal's), at wPerPerson a person times 425 / the meters' norm (pop0), as every gain a person; each person he
## kills himself takes wOwnKill off it. Nothing he does to the world fills it.
static func casualty(S: SimState, n: float, cause, x: float) -> void:
	if n <= 0.0 or cause == null or WorldCollateral.normPeople(S) <= 0.0:
		return
	var c = cause if SimRoster.isPrincipal(S, cause) else S.fighters[1]
	var norm: float = WorldCollateral.POP_REF / WorldCollateral.normPeople(S)   # as the meters' gains a person (data/biomes/collateral.json meterNorm)
	for h in S.fighters:
		if not has(S, h) or h.fd.wPerPerson <= 0.0:
			continue
		if c == h:
			h.form.witness = SimMathx.jmax(0.0, h.form.witness - n * h.fd.wOwnKill * norm)
		elif c == SimRoster.opp(S, h) and absf(SimWrap.sdx(h.x, x)) <= h.fd.wRange:
			h.form.witness += n * h.fd.wPerPerson * norm


## What a casualty someone else caused feeds his anguish (WorldCollateral._feed, World's line). For a fighter with
## branches, nothing: only his own kills cost him now, and his opponent's go to Witness (hero-forms.md section 7). For
## anyone else, as today.
static func anguishOther(S: SimState, f) -> float:
	if has(S, f) and f.fd.wPerPerson > 0.0:
		return 0.0
	return f.md.anguishCasOther


## This tick's events, for the Trial fill (SimCore.step, after the mood; only while forms are on):
##   tier_up        the opponent takes a form while his own tier is no higher: tForm, or tFormHeld when his own form was
##                  ready and he held it
##   damage         a blow of his, a medium or more, lands on the opponent while the opponent's tier is above his: tBlow
##   finisher_start, beam_outcome CLASH, brink_enter   the opponent commits fully: a finisher, a beam clash, fighting on at
##                  the brink: tCommit each
static func events(S: SimState) -> void:
	for h in S.fighters:
		if not has(S, h):
			continue
		var o = SimRoster.opp(S, h)
		var hi: float = float(S.fighters.find(h))
		var oi: float = float(S.fighters.find(o))
		for e in S.out.fx:
			match e.type:
				"tier_up":
					if e.actor == oi and h.tier <= e.tier - 1.0:
						h.form.trial += h.fd.tFormHeld if h.act.formReady else h.fd.tForm
				"damage":
					if e.attacker == hi and e.victim == oi and e.kind != "guard" and (e.weight == "medium" or e.weight == "heavy") and o.tier > h.tier:
						h.form.trial += h.fd.tBlow
				"finisher_start", "brink_enter":
					if e.actor == oi:
						h.form.trial += h.fd.tCommit
				"beam_outcome":
					if e.kind == "CLASH" and (e.actor == oi or e.target == oi):
						h.form.trial += h.fd.tCommit


## His form's level for the branch extras: 0 before the first branch step, 1 from it (II, and III on it), 2 from the
## second (IV, and V, which wears the branch he came by).
static func level(f) -> int:
	var n: int = 0
	for k in f.fd.branchAt:
		if f.form.step >= int(k):
			n += 1
	return n


## The perfect-block window's extra ticks in a Trial form (the director's perfect block reads it): tBlock by level. 0
## without steps or out of a Trial form.
static func blockWiden(S: SimState, f) -> int:
	if not has(S, f) or f.form.branch != "trial":
		return 0
	var lv: int = level(f)
	return int(f.fd.tBlock[mini(lv, f.fd.tBlock.size()) - 1]) if lv > 0 else 0


## What a perfect follow-up of his is worth more in a Trial form (the director's follow-up reads it). 0 otherwise.
static func followBonus(S: SimState, f) -> int:
	if not has(S, f) or f.form.branch != "trial":
		return 0
	return f.fd.tFollow


# --------------------------------------------------------------------------------------------------------------- the data

static func _def(id: String, j: Dictionary):
	var w: String = id + "/forms.json"
	var d := FormsDef.new()
	var st = j.get("steps")
	if not (st is Array) or st.size() < 1 or st.size() > 8:
		_err(w + ": steps needs 1 to 8 steps")
		return null
	var lastP: float = 0.0
	var lastT: float = 1.0
	for i in range(st.size()):
		var s = st[i]
		var at: String = w + ": steps[%d]" % i
		if not (s is Dictionary):
			_err(at + ": expected an object")
			return null
		var p: float = _num(at + ".power", s.get("power"), 0.0, 100.0)
		if p <= lastP:
			_err(at + ".power: steps must rise in power, above 0")
		var t: int = _int(at + ".tier", s.get("tier"), 1)
		if float(t) < lastT or t > 4:
			_err(at + ".tier: tiers for the world never fall, and stop at 4")
		if not KINDS.has(s.get("kind")):
			_err(at + ".kind: live or pausing")
		if not (s.get("id") is String):
			_err(at + ".id: a string")
		lastP = p
		lastT = float(t)
		d.steps.append({"power": p, "tier": t, "kind": String(s.get("kind", "live")), "id": String(s.get("id", ""))})
		if s.has("branch") and not (s.branch is bool):
			_err(at + ".branch: true or false")
		if s.get("branch") == true:
			d.branchAt.append(i + 1)
	var g = j.get("gains", {})
	var c = j.get("coil", {})
	var pa = j.get("patience", {})
	var r = j.get("release", {})
	for part in [["gains", g], ["coil", c], ["patience", pa], ["release", r]]:
		if not (part[1] is Dictionary):
			_err(w + ": " + part[0] + " must be an object")
			return null
	d.gSpeed = _num(w + ": gains.speed", g.get("speed"), 0.0, 1.0)
	d.gDamage = _num(w + ": gains.damage", g.get("damage"), 0.0, 1.0)
	d.gLaunch = _num(w + ": gains.launch", g.get("launch"), 0.0, 1.0)
	d.gChip = _num(w + ": gains.chip", g.get("chip"), 0.0, 0.2)
	d.gRegen = _num(w + ": gains.regen", g.get("regen"), 0.0, 1.0)
	d.gRecover = _num(w + ": gains.recover", g.get("recover"), 0.0, 0.2)
	d.coilPerSec = _num(w + ": coil.perSec", c.get("perSec"), 0.0, 100.0)
	d.coilPerDamage = _num(w + ": coil.perDamage", c.get("perDamage"), 0.0, 100.0)
	d.coilBehind = _num(w + ": coil.behindMul", c.get("behindMul"), 1.0, 10.0)
	d.coilMax = _num(w + ": coil.max", c.get("max"), 1.0, 100.0)
	d.patiencePerTier = _num(w + ": patience.perTier", pa.get("perTier"), 0.0, 1.0)
	d.patienceMax = _num(w + ": patience.max", pa.get("max"), 0.0, 0.9)
	d.minCoil = _num(w + ": release.minCoil", r.get("minCoil"), 0.0, 100.0)
	d.perPoint = _num(w + ": release.perPoint", r.get("perPoint"), 0.0, 0.1)
	d.maxMul = _num(w + ": release.maxMul", r.get("maxMul"), 1.0, 4.0)
	if not _branches(w, d, j.get("branches")):
		return null
	return d


## forms.json's branches (hero-forms.md section 3): the two fills' sources and the extras. False when it does not parse.
static func _branches(w: String, d: FormsDef, b) -> bool:
	if not (b is Dictionary):
		_err(w + ": branches must be an object")
		return false
	var wi = b.get("witness", {})
	var tr = b.get("trial", {})
	if not (wi is Dictionary) or not (tr is Dictionary):
		_err(w + ": branches.witness and branches.trial must be objects")
		return false
	if d.branchAt.size() != 2:
		_err(w + ": two steps are branch steps (II and IV)")
	d.wRange = _num(w + ": branches.witness.range", wi.get("range"), 0.0, 100000.0)
	d.wPerPerson = _num(w + ": branches.witness.perPerson", wi.get("perPerson"), 0.0, 100.0)
	d.wOwnKill = _num(w + ": branches.witness.ownKill", wi.get("ownKill"), 0.0, 100.0)
	d.wDamage = _num(w + ": branches.witness.damage", wi.get("damage"), 0.0, 1.0)
	d.wLaunch = _num(w + ": branches.witness.launch", wi.get("launch"), 0.0, 1.0)
	d.wCare = _num(w + ": branches.witness.care", wi.get("care"), 0.0, 2.0)
	d.tForm = _num(w + ": branches.trial.opponentForm", tr.get("opponentForm"), 0.0, 100.0)
	d.tFormHeld = _num(w + ": branches.trial.opponentFormHeld", tr.get("opponentFormHeld"), 0.0, 100.0)
	d.tPerSec = _num(w + ": branches.trial.deficitPerSec", tr.get("deficitPerSec"), 0.0, 100.0)
	d.tBlow = _num(w + ": branches.trial.blowUp", tr.get("blowUp"), 0.0, 100.0)
	d.tCommit = _num(w + ": branches.trial.commit", tr.get("commit"), 0.0, 100.0)
	d.tSpeed = _num(w + ": branches.trial.speed", tr.get("speed"), 0.0, 1.0)
	var bl = tr.get("block")
	if not (bl is Array) or bl.size() != 2:
		_err(w + ": branches.trial.block needs two values (at II and at IV)")
		bl = [0, 0]
	d.tBlock = [_int(w + ": branches.trial.block[0]", bl[0], 0), _int(w + ": branches.trial.block[1]", bl[1], 0)]
	d.tFollow = _int(w + ": branches.trial.followUp", tr.get("followUp"), 0)
	var ft = b.get("firstTie")
	if ft != "witness" and ft != "trial":
		_err(w + ": branches.firstTie is witness or trial")
		ft = "trial"
	d.firstTie = String(ft)
	return true


static func _num(where: String, x, lo: float, hi: float) -> float:
	if not (x is float or x is int) or float(x) < lo or float(x) > hi:
		_err(where + ": a number from %s to %s" % [str(lo), str(hi)])
		return lo
	return float(x)


static func _int(where: String, x, lo: int) -> int:
	if not (x is float or x is int) or float(x) != floor(float(x)) or float(x) < float(lo):
		_err(where + ": a whole number, %d or more" % lo)
		return lo
	return int(x)


static func _err(msg: String) -> void:
	_errors.append(msg)
	if not FighterData.quiet:
		push_error("SimForms: " + msg)
