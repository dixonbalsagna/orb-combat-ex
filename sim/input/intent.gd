class_name SimIntent
extends RefCounted
## Player intent, the per-tick input record a fighter acts on: the twin of intent.js (the prototype's f.in), growing into
## intent v2 (ADR 0008; docs/architecture/intent-v2.md).
##
## I1 (transport): the v2 fields sit next to today's stance, dash and charge, a superset for one slice. Nothing reads the
## new fields yet; I2 consumes them and I3 removes the three old ones. An intent is the resolved, device-independent action
## record: layouts resolve gestures before they build one, and the sim never sees a device.
## Held fields are true on every tick the action is held; edge fields on one tick.
## stance is a float like every JS number: -1, or a pressed stance 0 to 3.

## The intent schema version (the replay header's `intent`). 3 since `waited` (a press is graded at its own tick); 4 since the
## stance mask, `contextHeld` and `sigHeld` (the stances, docs/controls/lunge-control.md): replays recorded before it are refused
## rather than played back differently. 5 when stance, dash and charge leave (I3, its own later slice).
const VERSION: int = 4
## pack(): bit widths, least significant first.
const BITS: int = 53

var mx: float = 0.0          # the stick, -1 to 1; canonical values are k / 127 (canon())
var my: float = 0.0
var guard: bool = false      # held: guarding
var guardPress: bool = false # edge: a fresh guard press (the perfect block is judged from it)
var dodge: bool = false      # edge: the dodge; inside an exchange, the cancel
var sprint: bool = false     # held: sprinting (moving away it is Escape)
var power: bool = false      # held: the power layer, and channelling
var powerPress: bool = false # edge: the power control went down
var powerTap: bool = false   # edge: a power tap completed (released before the hold threshold)
var mode: int = -1           # -1 auto, 0 physical, 1 energy: the piece family, sent every tick
var light: bool = false      # edge: an attack request
var heavy: bool = false
var sig: bool = false
var upgrade: int = 0         # edge: 1 heavy, 2 signature, replacing this button's last request
var special: int = 0         # edge: 0 none, 1 to 3 the loadout, 4 reserved, 7 the layout's auto pick
var context: bool = false    # edge: the context action
var transform: bool = false  # edge: the layout's transform chord completed
## Agency pass (docs/controls/agency-input.md), additive: bits 40 to 42, so every older packed intent is still valid.
var lightHeld: bool = false  # held: a light attack button is down (a hold gesture reads as light until holdStart, then heavy)
var heavyHeld: bool = false  # held: a heavy attack button is down
var escape: bool = false     # edge: the Escape control (provisional: R3, a key, a swipe up on Guard)
## Ticks (0 to 15) the oldest edge in this record waited, because the sim was frozen (hit-stop, a pausing set piece) when it was
## pressed: the layout counts its own ticks. A press is graded at S.tick - waited, its own tick, so only the first ticks of a
## freeze count as on the beat. 0 on every ordinary tick. Bits 43 to 46.
var waited: int = 0
## The stances (version 4): one bit per shoulder button, resolved by the layout (SimStance): LB 1 defensive, RB 2 energy, RT 4
## charging, LT 8 manoeuvre, 0 martial. Bits 47 to 50. A stance is exclusive until hybrids exist (LT+RB 10, LB+RB 3, LT+LB 9 are the
## reserved ones), RT dominates, and a pending transform chord changes no stance. Distinct from the legacy `stance` float below.
var stanceMask: int = 0
var contextHeld: bool = false   # held: a Context button is down (A's hold: the martial channel, the zip tackle). Bit 51
var sigHeld: bool = false       # held: a Signature button is down, on any layer (B's held reading). Bit 52
# Today's fields, until I3:
var dash: bool = false
var charge: bool = false
var stance: float = -1.0


## Neutral input, exactly as control() cleared it every tick.
static func clearIntent(i: SimIntent) -> void:
	i.mx = 0.0
	i.my = 0.0
	i.guard = false
	i.guardPress = false
	i.dodge = false
	i.sprint = false
	i.power = false
	i.powerPress = false
	i.powerTap = false
	i.mode = -1
	i.light = false
	i.heavy = false
	i.sig = false
	i.upgrade = 0
	i.special = 0
	i.context = false
	i.transform = false
	i.lightHeld = false
	i.heavyHeld = false
	i.escape = false
	i.waited = 0
	i.stanceMask = 0
	i.contextHeld = false
	i.sigHeld = false
	i.dash = false
	i.charge = false
	i.stance = -1.0


## Overwrite every field of dst from src, as humanInput overwrote f.in for a human fighter.
static func applyIntent(dst: SimIntent, src: SimIntent) -> void:
	dst.mx = src.mx
	dst.my = src.my
	dst.guard = src.guard
	dst.guardPress = src.guardPress
	dst.dodge = src.dodge
	dst.sprint = src.sprint
	dst.power = src.power
	dst.powerPress = src.powerPress
	dst.powerTap = src.powerTap
	dst.mode = src.mode
	dst.light = src.light
	dst.heavy = src.heavy
	dst.sig = src.sig
	dst.upgrade = src.upgrade
	dst.special = src.special
	dst.context = src.context
	dst.transform = src.transform
	dst.lightHeld = src.lightHeld
	dst.heavyHeld = src.heavyHeld
	dst.escape = src.escape
	dst.waited = src.waited
	dst.stanceMask = src.stanceMask
	dst.contextHeld = src.contextHeld
	dst.sigHeld = src.sigHeld
	dst.dash = src.dash
	dst.charge = src.charge
	dst.stance = src.stance


## The whole record as one integer (53 bits; the sim keeps it as one integer and only the replay's JSON splits it): mx and my as 8 bits each (k + 127 for k / 127), mode + 1 in
## 2 bits, upgrade in 2, special in 3, twelve single bits, then today's stance + 1 in 3 bits, dash and charge, then the
## agency fields lightHeld, heavyHeld and escape in bits 40 to 42, waited in 43 to 46, then stanceMask in 47 to 50, contextHeld in 51
## and sigHeld in 52. Replays
## and, later, rollback carry this integer; equal canonical intents are equal integers.
static func pack(i: SimIntent) -> int:
	var p: int = _q(i.mx) | (_q(i.my) << 8) | ((clampi(i.mode, -1, 1) + 1) << 16) | (clampi(i.upgrade, 0, 2) << 18) | (clampi(i.special, 0, 7) << 20)
	var b: int = 23
	for on in [i.guard, i.guardPress, i.dodge, i.sprint, i.power, i.powerPress, i.powerTap, i.light, i.heavy, i.sig, i.context, i.transform]:
		if on:
			p |= 1 << b
		b += 1
	p |= (clampi(int(i.stance), -1, 3) + 1) << 35
	if i.dash:
		p |= 1 << 38
	if i.charge:
		p |= 1 << 39
	if i.lightHeld:
		p |= 1 << 40
	if i.heavyHeld:
		p |= 1 << 41
	if i.escape:
		p |= 1 << 42
	p |= clampi(i.waited, 0, 15) << 43
	p |= (i.stanceMask & 15) << 47
	if i.contextHeld:
		p |= 1 << 51
	if i.sigHeld:
		p |= 1 << 52
	return p


## The stick as 0 to 254: the nearest k / 127, k from -127 to 127.
static func _q(v: float) -> int:
	return clampi(int(floor(v * 127.0 + 0.5)), -127, 127) + 127


## The record a packed integer stands for, or null if p is not a valid packed intent (a field out of its range, or bits
## above the record).
static func unpack(p: int) -> SimIntent:
	if p < 0 or (p >> BITS) != 0:
		return null
	var qx: int = p & 0xFF
	var qy: int = (p >> 8) & 0xFF
	var md: int = (p >> 16) & 3
	var up: int = (p >> 18) & 3
	var st: int = (p >> 35) & 7
	if qx > 254 or qy > 254 or md > 2 or up > 2 or st > 4:
		return null
	var i := SimIntent.new()
	i.mx = float(qx - 127) / 127.0
	i.my = float(qy - 127) / 127.0
	i.mode = md - 1
	i.upgrade = up
	i.special = (p >> 20) & 7
	i.guard = ((p >> 23) & 1) == 1
	i.guardPress = ((p >> 24) & 1) == 1
	i.dodge = ((p >> 25) & 1) == 1
	i.sprint = ((p >> 26) & 1) == 1
	i.power = ((p >> 27) & 1) == 1
	i.powerPress = ((p >> 28) & 1) == 1
	i.powerTap = ((p >> 29) & 1) == 1
	i.light = ((p >> 30) & 1) == 1
	i.heavy = ((p >> 31) & 1) == 1
	i.sig = ((p >> 32) & 1) == 1
	i.context = ((p >> 33) & 1) == 1
	i.transform = ((p >> 34) & 1) == 1
	i.stance = float(st - 1)
	i.dash = ((p >> 38) & 1) == 1
	i.charge = ((p >> 39) & 1) == 1
	i.lightHeld = ((p >> 40) & 1) == 1
	i.heavyHeld = ((p >> 41) & 1) == 1
	i.escape = ((p >> 42) & 1) == 1
	i.waited = (p >> 43) & 15
	i.stanceMask = (p >> 47) & 15
	i.contextHeld = ((p >> 51) & 1) == 1
	i.sigHeld = ((p >> 52) & 1) == 1
	return i


## The canonical form of an intent: what a replay or a peer would reproduce (the stick on its 1 / 127 grid). The host or
## the recorder passes this to the sim, so a recorded match and a live one read the same bits.
static func canon(i: SimIntent) -> SimIntent:
	return unpack(pack(i))
