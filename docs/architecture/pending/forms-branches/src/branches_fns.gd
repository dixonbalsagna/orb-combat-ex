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


