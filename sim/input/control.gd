class_name SimControl
## Per-fighter input step, run once per fighter per tick in the tick's random order: the twin of control.js.


## intent: the host's intent for a human fighter (keyboard, replay or network). AI fighters ignore it; null leaves f neutral.
static func control(S: SimState, f, intent) -> void:
	var i: SimIntent = f.input
	SimIntent.clearIntent(i)
	if S.game.ko != null and not (S.stage != null and SimCross.on(S) and not f.out):
		return   # (2v2: his fight is finished and he's standing: he goes on, to the other fight)
	if f.ai != null:
		DirAI.aiInput(S, f)
	elif intent != null:
		SimIntent.applyIntent(i, intent)
	if f.stunTicks > 0:
		SimDir.pressInStun(S, f, i)
	SimWounds.gateIntent(f, i)   # S3a: stagger, daze and broken legs
	if f.act.v2:
		# I2a: a v2 slot's stance follows its held states (SimAct); today's stance field is not read for it.
		SimAct.update(S, f, i)
		f.stance = SimAct.stance(S, f, i)
	elif i.stance >= 0.0:
		f.stance = i.stance
	if i.light or i.heavy:
		f.lastAtkT = S.T
	if i.light:
		DirExchange.requestAttack(S, f, "light")
	elif i.heavy:
		DirExchange.requestAttack(S, f, "heavy")
	elif i.sig:
		DirExchange.requestAttack(S, f, "sig")
