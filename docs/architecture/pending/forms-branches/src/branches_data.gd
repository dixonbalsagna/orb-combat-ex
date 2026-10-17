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


