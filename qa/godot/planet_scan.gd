extends SceneTree
## QA's scan of a planet list (qa_planet.gd): builds every planet at every touch of QA_PLANET (the same setup a match gets) and names each pair whose slice fails,
## the matches of which would fall back to the hand-made world. Exit code 3 when any does.
##   QA_PLANET="gen=2;planets=...;touches=...;cols=2400" godot --headless --path <root> -s qa/godot/planet_scan.gd


const QaPlanet = preload("res://qa/godot/qa_planet.gd")


func _init() -> void:
	var spec: String = OS.get_environment("QA_PLANET")
	if spec == "":
		printerr("planet_scan: QA_PLANET is not set")
		quit(2)
		return
	var P: int = 1
	var T: int = 1
	for part in spec.split(";", false):
		var kv: PackedStringArray = part.split("=")
		if kv.size() == 2 and kv[0].strip_edges() == "planets":
			P = kv[1].split(",", false).size()
		elif kv.size() == 2 and kv[0].strip_edges() == "touches":
			T = kv[1].split(",", false).size()
	var bad: Array = []
	for seed in range(1, P * T + 1):   # seed s plays planet (s-1) % P at touch ((s-1) / P) % T: the first P * T seeds meet every pair once
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed, {}, QaPlanet.setup(seed))
		var su: Dictionary = QaPlanet.setup(seed)
		var ok: bool = not S.planetCols.is_empty()
		print("planet %d touch %d: %s (%d structures)" % [int(su.planet), int(su.touch), "ring" if ok else "FELL BACK", S.buildings.size()])
		if not ok:
			bad.append("planet %d touch %d" % [int(su.planet), int(su.touch)])
	print("planet_scan: %d of %d pairs fall back: %s" % [bad.size(), P * T, ", ".join(bad)])
	quit(3 if not bad.is_empty() else 0)
