class_name VfxBeamFront
extends Node3D
## The front of a beam that travels (docs/vfx/beam-front.md; Orb 2026-11-01: "beams should not be instant rays cast in a direction, they should appear to the player to have a velocity and project out from the fighter";
## Game Design row 40, rule-of-cool-map.md section 5). While a beam's head is still on its way out (the sim's `Beam.p` below 1: the head is `p x len` from the hand) its head is drawn as the fighter's own energy head
## in the beam's language (VfxEnergyHeads: his front's shape, his two tints, his texture, in a halo of his lane colour), riding on the tip of the body, which follows it as the sim lays it. The body, its three layers and its
## rise are BeamView's and untouched. View only: it reads the beam and writes nothing; no random number (the seed is the beam's origin); nothing rotates; nothing here is white.
## Fed by BeamView between `begin()` and `finish()`; holds no state.

const MEET_S := 0.1          # Game Design row 40: two fronts that meet start a struggle, about 6 ticks of collision

var heads := VfxEnergyHeads.new()
var count: int = 0              # fronts drawn this frame (the tests)


func _ready() -> void:
	heads.name = "Heads"
	add_child(heads)


func begin() -> void:
	heads.begin()
	count = 0


## One beam's front. b: the sim's Beam. a, e: its drawn tail and head in this view's x and the world's y. z: the pane's zoom. k: the beam's strength. ze: the depth at the head. The head leads the tip: most of it is ahead of the body's end.
func add(b, a: Vector2, e: Vector2, z: float, k: float, ze: float) -> void:
	var d: Vector2 = e - a
	var l: float = d.length()
	if l < 1.0 or b.p >= 1.0:
		return
	var dir: Vector2 = d / l
	var th: float = VfxBeamLook.thickness(b.A, b.w, 1, z, VfxBeamLook.is_short(b), l)       # the body layer's width in world units
	var side: Dictionary = VfxClashLook.side(b.A, String(b.col))
	var sz: Vector2 = VfxEnergyHeads.size_of(int(side["front"]), th * 0.58, 1.0)
	# a front that has only just left the hand is not yet a whole shape: it grows over its first stretch
	var grow: float = smoothstep(0.0, sz.x * 1.2, l)
	var c: Vector2 = e + dir * sz.x * 0.1 * grow
	heads.add(c, dir, sz.x * grow, sz.y * grow, RenderLook.Z_BEAMS + 0.8 + ze, side, k, b.ox * 0.0137)
	count += 1


## Two fronts meeting (row 40): for the first `MEET_S` of a clash each side's head is at the meeting point m, facing the other, its nose on it, pressing into the point as the press (clash_view.gd) takes over: the head shrinks to a sixth of itself over the six ticks.
## c: the clash (A and D the two fighters). a, d: the two hands in this view. mz: the depth at m. age: seconds since the clash began. z: the pane's zoom. k: the clash's strength.
func meet(c, a: Vector2, d: Vector2, m: Vector2, mz: float, age: float, z: float, k: float) -> void:
	var u: float = clampf(age / MEET_S, 0.0, 1.0)
	if u >= 1.0:
		return
	for side in range(2):
		var from: Vector2 = a if side == 0 else d
		var who = c.A if side == 0 else c.D
		var dv: Vector2 = m - from
		var l: float = dv.length()
		if l < 1.0:
			continue
		var dir: Vector2 = dv / l
		var th: float = VfxBeamLook.thickness(who, 26.0 + float(who.tier) * 8.0, 1, z, false, l)
		var sd: Dictionary = VfxClashLook.side(who, String(who.aura))
		var sz: Vector2 = VfxEnergyHeads.size_of(int(sd["front"]), th * 0.58, 1.0)
		var g: float = 1.0 - 0.85 * smoothstep(0.0, 1.0, u)
		heads.add(m - dir * sz.x * g * 0.5, dir, sz.x * g, sz.y * g, RenderLook.Z_BEAMS + 0.8 + mz, sd, k, from.x * 0.0137 + float(side))
		count += 1


func finish(t: float) -> void:
	heads.finish(t)
