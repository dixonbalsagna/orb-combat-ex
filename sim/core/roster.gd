class_name SimRoster
## Fighter construction: the twin of roster.js (mkF and opp). D1a: the definitions are data (data/fighters/, loaded by
## FighterData); a def is FighterData.def(id).

## roster.js createFighter: mkF's fields and initial values (the class defaults in state.gd hold the constants). def is a
## FighterData def: its scalars are copied, and f.wd points at its WoundsDef.
static func createFighter(def: Dictionary, x: float, keys: String, ai: bool) -> SimState.Fighter:
	var f := SimState.Fighter.new()
	f.id = def.id
	f.name = def.name
	f.role = def.role
	f.col = def.col
	f.aura = def.aura
	f.hair = def.hair
	f.care = def.care
	f.dmgMul = def.dmgMul
	f.spd = def.spd
	f.maxhp = def.maxhp
	f.sigName = def.sigName
	f.canHide = def.get("canHide", false)
	f.hasAnguish = def.get("anguish", false)
	f.hasMenace = def.get("menace", false)
	f.rally = def.get("rally", "")
	f.wd = def.wd
	f.md = def.md
	f.ld = def.ld
	f.finisher = def.get("finisher", "")
	f.sigCooldown = float(def.get("sigCooldown", 0.0))
	f.hp = def.maxhp
	f.x = x
	f.keys = keys
	f.ai = SimState.AiState.new() if ai else null
	return f


## One versus many (docs/director/one-v-many.md, stage 1): a match holds 2 to MAX_BODIES fighters. Slots 0 and 1 are
## the pair as in a 1v1, and they are the principals: the two the match is between. A body past them (a guard) stands
## GUARD_SPACING units beyond the second, and the next as far again, on the side away from the first. The director places
## the ring from stage 2 on; until then they stand.
const MAX_BODIES: int = 5
const GUARD_SPACING: float = 150.0   # 2 bh: "her guards stand 2 bh behind her, along the street" (empress-guards.md)


## True when f is one of the two principals (slots 0 and 1), the fighters the match is between; false for a guard.
## Game Design's rulings for more than two bodies read it: only a principal's KO ends a match, a guard has no brink, a
## guard's stance does not set the mood and his blow feeds it at half, and the acts count the principals only.
static func isPrincipal(S: SimState, f) -> bool:
	return S.fighters.find(f) < 2


## True when slots names 2 to MAX_BODIES fighters the data has (the roster's or the bench's). The same id may come more
## than once (a mirror, or two guards of one kind); a setup's names tell them apart in the feed.
static func slotsOk(slots) -> bool:
	if not (slots is Array) or slots.size() < 2 or slots.size() > MAX_BODIES:
		return false
	for id in slots:
		if not (id is String) or not FighterData.has(id):
			return false
	return true


## The other fighter: anything that is not fighters[0] gets fighters[0], as in the prototype. With more than two bodies
## that makes the first the opponent of every other, and the second his: the one versus many.
static func opp(S: SimState, f) -> SimState.Fighter:
	return S.fighters[1] if S.fighters[0] == f else S.fighters[0]
