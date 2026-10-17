extends SceneTree
# Prints a planet's generated places as exact bit patterns (16 hex digits, high word first, as SimMathx.f64 reads them).
#   godot --headless --path . --script res://sim/world/tools/planet_store_dump.gd -- <seed> <out.json>
func hexd(x: float) -> String:
	var b := PackedByteArray()
	b.resize(8)
	b.encode_double(0, x)
	# encode_double is little endian: reverse to high word first
	var h: String = b.hex_encode()
	var out: String = ""
	for i in range(7, -1, -1):
		out += h.substr(i * 2, 2)
	return out
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var P := WorldPlanet.make(int(args[0]))
	var places: Array = []
	for i in range(P.n):
		places.append({"kind": int(P.kind[i]), "x": hexd(P.px[i]), "y": hexd(P.py[i]), "z": hexd(P.pz[i]), "r": P.rad[i]})
	var f := FileAccess.open(args[1], FileAccess.WRITE)
	f.store_string(JSON.stringify({"seed": P.seed, "places": places}))
	f.close()
	print("wrote %d places" % P.n)
	quit()
