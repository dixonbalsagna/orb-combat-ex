class_name NetBot
extends RefCounted
## A scripted player for the rollback harness: one seeded stream per slot, asked for its intent tick by tick in order, so
## the same (seed, slot) gives the same inputs to a peer, to the other peer's view of it and to a straight replay. It
## holds sticks, guard, sprint, power and the legacy dash and charge for runs of ticks (a prediction gets those right) and
## presses attacks, dodges, stances and specials on single ticks (a prediction gets each of those wrong), at about the
## rates of golden_recipes.gd's scripted human, with the v2 stance mask too. Not a fighter AI: it does not read the state.
## With switches.rightStick on, it also throws strikes and braces on a stream of its own, in `word` (SimIntent.pack2) after each next(): the
## first word's stream, and so every match with the switch off, is what it always was.
## With flyer set (a check's --setup=kick), it flies flat out and flips the stick on a stream of its own, and attacks far less: a plain bot's stream hardly ever kicks.

var r: SimRng
var mx: float = 0.0
var my: float = 0.0
var dash: bool = false
var charge: bool = false
var guard: bool = false
var sprint: bool = false
var power: bool = false
var mode: int = -1
var stanceMask: int = 0
var tick: int = 0   # the next tick it answers for
var word: int = 0   # the second word of the last next()
var r2: SimRng = null   # the second word's stream, with the switch on
var rsLeft: int = 0     # ticks of the strike being held
var rsDir: int = 0
var rsLevel: int = 0
var rsMask: int = 0
var rsAim: int = 0
var r3: SimRng = null   # the flyer's stream
var flyLeft: int = 0    # ticks before the next flip
var flyWay: float = 1.0
static var flyer: bool = false

const STEER: Array = [-1.0, 0.0, 1.0]
const MASKS: Array = [0, 1, 2, 4, 8]


func _init(seed: int, slot: int) -> void:
	r = SimRng.new(SimRng.deriveSeed(seed & 0xFFFFFFFF, "netbot%d" % slot))
	if SimInputData.right_stick_on():
		r2 = SimRng.new(SimRng.deriveSeed(seed & 0xFFFFFFFF, "netbotword%d" % slot))
	if flyer:
		r3 = SimRng.new(SimRng.deriveSeed(seed & 0xFFFFFFFF, "netbotfly%d" % slot))


## The right-hand switch in this process, in memory (a check's --right-stick; data/input/timing.json says off).
static func setRightStick(on: bool) -> void:
	SimInputData.ensure()
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["rightStick"] = on
	SimInputData.timing["switches"] = sw
	SimInputData.invalidate()


## --dodge-held (docs/controls/dodge-held.md): the bots also hold LT in runs (the word's bit 26), so a check carries it on the wire, in every hash and through every rollback. Needs the right stick on.
static func setDodgeHeld(on: bool) -> void:
	SimInputData.ensure()
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["dodgeHeld"] = on
	SimInputData.timing["switches"] = sw
	SimInputData.invalidate()


## The packed intent for the next tick.
func next() -> int:
	tick += 1
	if r.next() < 0.05:
		mx = STEER[int(floor(r.next() * 3.0))]
	if r.next() < 0.05:
		my = STEER[int(floor(r.next() * 3.0))]
	if r.next() < 0.02:
		dash = not dash
	if r.next() < 0.01:
		charge = not charge
	if r.next() < 0.02:
		guard = not guard
	if r.next() < 0.02:
		sprint = not sprint
	if r.next() < 0.015:
		power = not power
	if r.next() < 0.01:
		mode = int(floor(r.next() * 3.0)) - 1
	if r.next() < 0.004:
		stanceMask = MASKS[int(floor(r.next() * 5.0))]
	var i := SimIntent.new()
	i.mx = mx
	i.my = my
	i.dash = dash
	i.charge = charge
	i.guard = guard
	i.sprint = sprint
	i.power = power
	i.mode = mode
	i.stanceMask = stanceMask
	i.light = r.next() < 0.03
	i.heavy = r.next() < 0.015
	i.sig = r.next() < 0.008
	i.lightHeld = i.light or (r.next() < 0.02)
	i.stance = floor(r.next() * 4.0) if r.next() < 0.004 else -1.0
	i.guardPress = r.next() < 0.02
	i.dodge = r.next() < 0.02
	i.powerPress = r.next() < 0.01
	i.powerTap = r.next() < 0.01
	i.upgrade = (1 + int(floor(r.next() * 2.0))) if r.next() < 0.01 else 0
	i.special = (1 + int(floor(r.next() * 7.0))) if r.next() < 0.005 else 0
	i.context = r.next() < 0.01
	i.transform = r.next() < 0.002
	i.escape = r.next() < 0.003
	word = _word() if r2 != null else 0
	if r3 != null:
		_fly(i)
	return SimIntent.pack(i)


## Flat out with the stick flipped every run of ticks, and most of its presses dropped, since an exchange ends a flight.
func _fly(i: SimIntent) -> void:
	if flyLeft <= 0:
		flyLeft = 25 + int(floor(r3.next() * 50.0))
		flyWay = -flyWay
	flyLeft -= 1
	i.dash = true
	i.mx = flyWay
	i.guard = false
	i.charge = false
	i.power = false
	if r3.next() < 0.9:
		i.light = false
		i.lightHeld = false
		i.heavy = false
		i.sig = false
		i.special = 0
		i.context = false
		i.transform = false
		i.escape = false
		i.dodge = false
		i.guardPress = false
		i.powerPress = false
		i.powerTap = false
		i.upgrade = 0


## How many kicks and plants a straight match of two flyers has: a check's proof that its kick setup kicks.
static func flyerCount(seed: int, setup: Dictionary, ticks: int = 600) -> Array:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": false, "p2": false}, setup)
	var bots: Array = [NetBot.new(seed, 0), NetBot.new(seed, 1)]
	var out: Array = [0, 0]
	for t in range(ticks):
		SimCore.step(S, [NetSession.intentOf(bots[0].next(), bots[0].word), NetSession.intentOf(bots[1].next(), bots[1].word)])
		for e in S.out.fx:
			if e.type == "kick":
				out[0] += 1
			elif e.type == "coin_plant":
				out[1] += 1
		S.out.feed.clear()
		S.out.fx.clear()
	SimCore.dispose(S)
	return out


## What a field world keeps past a match, for a check about to count leaked objects: the fields and the store's indexes.
static func forgetField() -> void:
	SimField._F = null
	WorldField.forget()
	WorldStore._ix.clear()


## The next second word, in the shape the layout writes: a start, a held run with the level rising and the aim moving, then a throw or a cancel on
## a tick with rsHeld off; a brace now and then; 0 between.
func _word() -> int:
	var i := SimIntent.new()
	if rsLeft > 0:
		rsLeft -= 1
		if r2.next() < 0.15:
			rsAim = int(floor(r2.next() * 32.0))
		if r2.next() < 0.05:
			rsLevel = mini(rsLevel + 1, 3)
		i.rsDir = rsDir
		i.rsLevel = rsLevel
		i.rsMask = rsMask
		i.rsAim = rsAim
		if rsLeft > 0:
			i.rsHeld = true
		else:
			i.rsRelease = r2.next() < 0.85
			i.rsCancel = not i.rsRelease
			i.rsLag = int(floor(r2.next() * 3.0))
	elif r2.next() < 0.02:
		rsLeft = 4 + int(floor(r2.next() * 50.0))
		rsDir = 1 + int(floor(r2.next() * 4.0))
		rsLevel = 0
		rsMask = int(floor(r2.next() * 16.0))
		rsAim = int(floor(r2.next() * 32.0))
		i.rsHeld = true
		i.rsStart = true
		i.rsDir = rsDir
		i.rsMask = rsMask
		i.rsAim = rsAim
	if r2.next() < 0.004:
		i.brace = true
		i.braceDir = 1 + int(floor(r2.next() * 4.0))
	if SimInputData.dodge_held_on():
		i.dodgeHeld = (tick / 17) % 3 == 1   # LT held for 17 ticks in every 51, from the bot's own tick: no stream of its own, so the other words are as they were
	return SimIntent.pack2(i)
