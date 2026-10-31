class_name SimSwap
extends RefCounted
## The left-handed swap (Orb, 2026-10-30: "left-handed folks who may want to swap their controller around"). The left and right roles are swapped as a
## WHOLE: the sticks, the four shoulders and the face buttons with the D-pad, so the hand that holds the stick that moves is the other one, and the hand that
## strikes is the one with the left stick. It works on the preset, never on the sim: a swapped preset binds the same actions to the mirrored controls, so
## everything downstream (the stance mask, the strike reader, the law, the left-hand reads, the intent) is the same code and the same numbers.
##
## The no-claw law is written on actions, not on controls, so it holds under a swap by construction. The one number that depends on the hand is how fast
## a thumb crosses between its stick and its face buttons, which the capture tool measures for each side: `strike.swapLockout` and
## `strike.swapReverseLockout` (default: the unswapped values, so a swapped pad is never faster). SimStrikeLaw takes them when it is made for a swapped slot.
##
## The result is a PRESET (`hand_layout` "swapped", Accessibility's rule 3): SimInputData derives `<pad preset>-swapped` for every pad preset from the shipped one, and
## the keyboard's `kb-solo-swapped` is shipped data (a keyboard has no symmetric key layout to mirror by rule). Remap, glyphs and the gate treat them like any other preset.
## Touch is parked (ADR 0011); the shared keyboard's halves are remapped, not swapped.

## Pad control to its mirror. The sticks, the shoulders and the clicks swap sides; the face buttons trade places with the D-pad positionally (south
## with down, east with right, west with left, north with up); start, back and the rest stay.
const PAD: Dictionary = {
	"pad:ls": "pad:rs", "pad:rs": "pad:ls",
	"pad:lb": "pad:rb", "pad:rb": "pad:lb",
	"pad:lt": "pad:rt", "pad:rt": "pad:lt",
	"pad:l3": "pad:r3", "pad:r3": "pad:l3",
	"pad:south": "pad:dpad_down", "pad:dpad_down": "pad:south",
	"pad:east": "pad:dpad_right", "pad:dpad_right": "pad:east",
	"pad:west": "pad:dpad_left", "pad:dpad_left": "pad:west",
	"pad:north": "pad:dpad_up", "pad:dpad_up": "pad:north",
}


## A pad control id as the swapped layout sees it.
static func control(c: String) -> String:
	return str(PAD.get(c, c))


## A pad position name ("lb", "dpad_up", "ls", ...) as the swapped layout sees it.
static func name(n: String) -> String:
	var c: String = control("pad:" + n)
	return c.substr(4)


## The swapped form of a pad preset: every control renamed, the bindings otherwise unchanged. A keyboard or touch preset comes back as a copy.
## Applying it twice gives the shipped preset again.
static func mirror_preset(p: Dictionary) -> Dictionary:
	var out: Dictionary = p.duplicate(true)
	if str(out.get("device", "")) != "pad":
		return out
	for key in ["bindings", "strikeBindings"]:
		for b in out.get(key, []):
			var cs: Array = []
			for c in b["controls"]:
				cs.append(control(str(c)))
			b["controls"] = cs
	return out


## The shipped preset id of the swapped layout of a preset: `<id>-swapped`.
static func swapped_id(id: String) -> String:
	return id + "-swapped"


## Whether an id is a swapped preset's.
static func is_swapped_id(id: String) -> bool:
	return id.ends_with("-swapped")
