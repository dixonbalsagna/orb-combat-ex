# The tier cap: no fighter goes past the ladder's last tier (1 plus its thresholds, four today). In a match the core
# readies a form only when the power's tier is above the fighter's, so the cap never acts there; it holds the line for
# whatever sets act.formReady by hand (the flash and hash tools' staging raised a fifth tier, and the collateral
# ceiling's table has four entries). No new state, nothing hashed changes. Usage: python tier_cap.py <repo root>
import os, sys
os.chdir(sys.argv[1])
def edit(p, pairs):
    s=open(p,encoding='utf-8').read()
    for a,b in pairs:
        assert s.count(a)==1,(p,a[:70],s.count(a))
        s=s.replace(a,b)
    open(p,'w',encoding='utf-8',newline='\n').write(s)

edit('sim/core/fighter.gd', [
('''## I2a: take a ready form (ladder.json manualTierUp): the tier rises one step with today's power-up. The director's
## placeholder transform calls it between exchanges (I2b). Returns false if nothing was ready.
static func transform(S: SimState, f) -> bool:
	if not f.act.formReady:
		return false
	f.act.formReady = false
''','''## The ladder's last tier: 1 plus its thresholds (four tiers today). No fighter goes past it. In a match the core readies
## a form only when his power's tier is above his own, so the three guards that read this (transform, formBreak and
## stepFighter) never act there. They hold the line for whatever sets act.formReady by hand, such as a test's staging.
static func topTier(f) -> float:
	return 1.0 + float(f.ld.thresholds.size())


## I2a: take a ready form (ladder.json manualTierUp): the tier rises one step with today's power-up. The director's
## placeholder transform calls it between exchanges (I2b). Returns false if nothing was ready, or if he is on the
## ladder's last tier: the form is dropped, with any gather asked for it.
static func transform(S: SimState, f) -> bool:
	if not f.act.formReady:
		return false
	f.act.formReady = false
	if f.tier >= topTier(f):
		f.act.breakIn = -1
		return false
'''),
('''static func formBreak(S: SimState, f) -> void:
	f.act.breakIn = -1
	f.tier += 1.0
''','''static func formBreak(S: SimState, f) -> void:
	f.act.breakIn = -1
	if f.tier >= topTier(f):   # the one line that raises a tier by a step never passes the ladder's last
		return
	f.tier += 1.0
'''),
('''	var nt: float = tierByPower(f)
	if f.act.breakIn > 0 and S.game.ko == null:   # a live transformation's gather: the break lands here
''','''	var nt: float = tierByPower(f)
	if f.act.formReady and f.tier >= topTier(f):   # a form readied with no tier above it is dropped, before the director can take it
		f.act.formReady = false
	if f.act.breakIn > 0 and S.game.ko == null:   # a live transformation's gather: the break lands here
'''),
])
edit('sim/core/tools/parity.gd', [
('''	check("a blow that names its region", _namedRegion())
''','''	check("a blow that names its region", _namedRegion())
	check("no tier past the ladder's last", _tierCap())
'''),
('''## The third weight (brawl-second-pass.md section 2): what the core decides for a medium blow, beside a light and a''','''## The tier cap (SimFighter.topTier): 1 plus the ladder's thresholds. The last real step is still taken. On the last tier
## a form set ready by hand is refused by transform, a break asked for raises nothing, and through the sim's own step the
## flag is dropped before the director can start the set piece: no transform or tier_up event, no pause, and the world's
## highest tier stays inside the collateral ceiling's table.
func _tierCap() -> String:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"intro": false})
	var f = S.fighters[0]
	var top: float = SimFighter.topTier(f)
	if top != 1.0 + float(f.ld.thresholds.size()) or top != 4.0:
		return "the ladder's last tier reads %s" % str(top)
	f.y = WorldTerrain.groundY(S, f.x) + 900.0
	# the last real step is taken
	f.tier = top - 1.0
	f.act.breakIn = -1
	f.act.formReady = true
	if not SimFighter.transform(S, f) or f.tier != top or f.act.formReady:
		return "the step to the last tier was not taken (tier %s)" % str(f.tier)
	# on the last tier a ready form is refused, and its gather with it
	f.act.formReady = true
	f.act.breakIn = 30
	if SimFighter.transform(S, f) or f.tier != top or f.act.formReady or f.act.breakIn != -1:
		return "a form on the last tier was taken (tier %s, gather %d)" % [str(f.tier), f.act.breakIn]
	# a break asked for on the last tier raises nothing
	f.act.breakIn = 1
	S.out.fx.clear()
	SimFighter.formBreak(S, f)
	for e in S.out.fx:
		if e.type == "tier_up":
			return "a break on the last tier sent tier_up"
	if f.tier != top or f.act.breakIn != -1:
		return "a break on the last tier raised it to %s" % str(f.tier)
	# through the step, with the form set ready by hand on every tick and the transform asked for
	var press := SimIntent.new()
	press.transform = true
	var quiet := SimIntent.new()
	for t in range(240):
		f.act.formReady = true
		S.out.fx.clear()
		SimCore.step(S, [press, quiet])
		for e in S.out.fx:
			if e.type == "transform" or e.type == "tier_up" or e.type == "transform_ready":
				return "tick %d on the last tier: the sim sent %s" % [t, e.type]
		if f.tier != top or f.act.formReady or f.act.breakIn > 0 or S.world.maxTier > top or S.pause.left != 0:
			return "tick %d on the last tier: tier %s, ready %s, gather %d, the world's highest %s, pause %d" % [t, str(f.tier), str(f.act.formReady), f.act.breakIn, str(S.world.maxTier), S.pause.left]
		if WorldCollateral.ceilingLeft(S) < 0.0:
			return "the collateral ceiling read below 0"
	SimCore.dispose(S)
	return ""


## The third weight (brawl-second-pass.md section 2): what the core decides for a medium blow, beside a light and a'''),
])
print("the tier cap is in")
