extends SceneTree
## The signature's variants by biome (biomes W1; docs/combat/biomes.md sections 2 and 6): the director reads
## data/combat/sigvariants.json in place of templates.json beam.variants, crater.gd SCORCH_VARIANT and sampleBeam's
## variant branches. Five parts, each a PASS or FAIL line:
##   built    the seven built rows carry the retired tables' names, groove factors and looks exactly (World's condition)
##   gen 1    on the hand-made world every column picks the same row with fineOn off and on, the retired table's
##   gen 2    gen 2 planets: off, every column picks biomeAt's row; on, fineNameAt's, and all 17 rows are picked
##   beam     a beam over each row's ground: its scorch events carry the row's name and width, its dust, sparks and
##            fire are the row's, and its structure bite is the ladder's times structMul
##   play     gen 2 AI matches with fineOn off and on: the variants the beams carved by, and the signatures' tags
##   godot --headless --path . --script res://sim/director/tools/sigvariants_check.gd -- [--matches=6] [--ticks=7200]
## Exit code 1 on any FAIL.

## The retired tables as they were at e1521ef5: templates.json beam.variants, crater.gd SCORCH_VARIANT, and sampleBeam's
## branches (GLASS TRENCH's sand dust and sparks, FIRESTORM's fire within 140 above the ground, grey dust elsewhere).
const OLD_NAMES: Dictionary = {"ocean": "HORIZON CLEAVE", "city": "BOULEVARD RAZE", "village": "BOULEVARD RAZE", "forest": "FIRESTORM", "mountains": "RIDGE BORE", "desert": "GLASS TRENCH", "plains": "FIELD SCAR"}
const OLD_SCORCH: Dictionary = {"RIDGE BORE": [1.6, 0.8], "GLASS TRENCH": [0.8, 1.3], "FIRESTORM": [1.0, 1.1], "BOULEVARD RAZE": [0.8, 1.0], "FIELD SCAR": [1.0, 1.0], "HORIZON CLEAVE": [1.0, 1.0]}
const GEN2_SEEDS: Array = [7, 3, 11, 25, 1, 2, 5, 13, 17, 19, 23, 29, 31, 37, 41, 43]

var fails: int = 0


func ok(cond: bool, what: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + what)
	if not cond:
		fails += 1


func _init() -> void:
	var matches: int = 6
	var ticks: int = 7200
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--matches="):
			matches = int(a.substr(10))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
	var sig = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat/sigvariants.json"))
	var rows: Dictionary = sig.variants
	print("sigvariants.json: %d rows, fineOn %s" % [rows.size(), str(sig.fineOn)])
	_built(rows)
	_gen1(rows)
	var at: Dictionary = _gen2(rows)
	_beams(rows, at)
	_play(matches, ticks)
	DirData.sigFine = -1
	print("sigvariants check " + ("passed" if fails == 0 else "FAILED (%d)" % fails))
	quit(0 if fails == 0 else 1)


# ---------------------------------------------------------------- built: the retired tables, exactly

func _built(rows: Dictionary) -> void:
	var built: Array = []
	for k in rows:
		if bool(rows[k].get("asBuilt", false)):
			built.append(k)
	built.sort()
	var want: Array = OLD_NAMES.keys()
	want.sort()
	ok(built == want, "built: the rows marked asBuilt are the retired table's seven biomes (%s)" % ", ".join(built))
	for k in want:
		var r: Dictionary = rows[k]
		var nm: String = String(r.name)
		var fx: Dictionary = r.fx
		var sc: Array = r.scorch
		var old: Array = OLD_SCORCH[OLD_NAMES[k]]
		var exact: bool = sc.size() == 2 and float(sc[0]) == float(old[0]) and float(sc[1]) == float(old[1])
		var dust: String = "#e6c47a" if nm == "GLASS TRENCH" else "#9b8f7e"
		var sparks: bool = fx.has("sparks") == (nm == "GLASS TRENCH")
		if fx.has("sparks"):
			sparks = sparks and int(fx.sparks.n) == 2 and String(fx.sparks.col) == "#ffd98a" and float(fx.sparks.speed) == 300.0
		var fire: bool = fx.has("fire") == (nm == "FIRESTORM")
		if fx.has("fire"):
			fire = fire and float(fx.fire.withinAbove) == 140.0
		var bite: bool = float(r.structMul) == 1.0 and float(r.get("areaMul", 1.0)) == 1.0 and String(r.trees) == "area"
		ok(nm == OLD_NAMES[k] and exact and String(fx.dust) == dust and sparks and fire and bite,
			"built: %s is %s, groove [%s, %s] (crater.gd had [%s, %s], equal to the bit), dust %s, sparks %s, fire %s, structMul %s, trees %s" % [
				k, nm, str(sc[0]), str(sc[1]), str(old[0]), str(old[1]), String(fx.dust), str(fx.has("sparks")), str(fx.has("fire")), str(r.structMul), String(r.trees)])


# ---------------------------------------------------------------- gen 1: the hand-made world

func _gen1(rows: Dictionary) -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1)
	var bad: int = 0
	var seen: Dictionary = {}
	for c in range(SimConst.NC):
		var x: float = (float(c) + 0.5) * SimConst.COL
		DirData.sigFine = 0
		var k0: String = DirData.sigKeyAt(x)
		DirData.sigFine = 1
		var k1: String = DirData.sigKeyAt(x)
		var b: String = WorldBiomes.biomeAt(x)
		if k0 != b or k1 != b or String(DirData.sigRow(k0).name) != OLD_NAMES[b]:
			bad += 1
		seen[k0] = int(seen.get(k0, 0)) + 1
	SimCore.dispose(S)
	ok(bad == 0, "gen 1: all %d columns pick the same row off and on, biomeAt's, named as the retired table (%s); %d differ" % [SimConst.NC, _counts(seen), bad])


# ---------------------------------------------------------------- gen 2: all 17 rows

func _setup(sd: int, touch: int) -> Dictionary:
	return {"planet": sd, "touch": touch, "arena": {"cols": 2400}, "planetGen": 2, "intro": false}


func _gen2(rows: Dictionary) -> Dictionary:
	var at: Dictionary = {}   # key -> [seed, touch, x], the first column found
	var seenOn: Dictionary = {}
	var seenOff: Dictionary = {}
	var badOff: int = 0
	var badOn: int = 0
	var cols: int = 0
	var planets: int = 0
	for sd in GEN2_SEEDS:
		for touch in [0, 1, 2]:
			var S := SimCore.createSim()
			SimCore.newMatch(S, 1, {}, _setup(sd, touch))
			planets += 1
			for c in range(SimConst.NC):
				var x: float = (float(c) + 0.5) * SimConst.COL
				DirData.sigFine = 0
				var k0: String = DirData.sigKeyAt(x)
				DirData.sigFine = 1
				var k1: String = DirData.sigKeyAt(x)
				var b: String = WorldBiomes.biomeAt(x)
				if k0 != b or String(DirData.sigRow(k0).name) != OLD_NAMES[b]:
					badOff += 1
				if k1 != WorldBiomes.fineNameAt(x):
					badOn += 1
				seenOff[k0] = int(seenOff.get(k0, 0)) + 1
				seenOn[k1] = int(seenOn.get(k1, 0)) + 1
				if not at.has(k1):
					at[k1] = [sd, touch, x]
				cols += 1
			SimCore.dispose(S)
			if at.size() == rows.size():
				break
		if at.size() == rows.size():
			break
	DirData.sigFine = -1
	ok(badOff == 0, "gen 2 off: %d columns on %d planets pick biomeAt's row, named as the retired table (%s); %d differ" % [cols, planets, _counts(seenOff), badOff])
	ok(badOn == 0, "gen 2 on: every column picks fineNameAt's row; %d differ" % badOn)
	var missing: Array = rows.keys().filter(func(k): return not at.has(k))
	ok(missing.is_empty(), "gen 2 on: %d of %d rows picked (%s)%s" % [at.size(), rows.size(), _counts(seenOn), ("" if missing.is_empty() else "; never: " + ", ".join(missing))])
	return at


# ---------------------------------------------------------------- beam: a beam over each row's ground

func _beams(rows: Dictionary, at: Dictionary) -> void:
	for k in rows:
		if not at.has(k):
			ok(false, "beam: %s has no column on the planets read" % k)
			continue
		var r: Dictionary = rows[k]
		var nm: String = String(r.name)
		var fx: Dictionary = r.fx
		var p: Array = at[k]
		var S := SimCore.createSim()
		SimCore.newMatch(S, 1, {}, _setup(int(p[0]), int(p[1])))
		DirData.sigFine = 1
		var x: float = float(p[2])
		var A = S.fighters[0]
		var D = S.fighters[1]
		D.x = x
		var key: String = DirData.sigKeyAt(D.x)
		var g: float = WorldTerrain.groundY(S, x)
		var L: float = 320.0
		DirBeam.fireBeam(S, A, x - L * 0.5, g + 4.0, 1.0, 0.0, L, String(DirData.sigRow(key).name))
		var b = S.beams.pop_back()
		var sfWant: float = float(A.ld.beamStructure[DirBeam._tierIx(A)]) * float(r.structMul)
		var n: int = 0
		var wBad: int = 0
		var vBad: int = 0
		var hw: float = (WorldCrater.SCORCH_HW0 + WorldCrater.SCORCH_HW_P * b.pw) * float(r.scorch[1])
		var dusts: int = 0
		var dustBad: int = 0
		var sparks: int = 0
		var sparksBad: int = 0
		var fires: int = 0
		var s: float = 0.0
		while s <= L:
			# Only the events this sample emits at its own place count (a struck building throws dust, sparks and fire too).
			var xs: float = SimWrap.wrap(b.ox + b.ux * s)
			var gs: float = WorldTerrain.groundY(S, xs)
			S.out.fx.clear()
			DirBeam.sampleBeam(S, b, s)
			s += 4.0
			for e in S.out.fx:
				if float(e.get("x")) != xs:
					continue
				match str(e.type):
					"scorch":
						n += 1
						if String(e.variant) != nm:
							vBad += 1
						if float(e.w) != hw * 2.0:
							wBad += 1
					"dust":
						if float(e.y) == gs + 8.0:
							dusts += 1
							if String(e.col) != String(fx.dust):
								dustBad += 1
					"spark":
						if float(e.y) == gs + 6.0:
							sparks += 1
							if not fx.has("sparks") or int(e.n) != int(fx.sparks.n) or String(e.col) != String(fx.sparks.col) or float(e.spd) != float(fx.sparks.speed):
								sparksBad += 1
					"fire":
						if float(e.y) == gs:
							fires += 1
		var oldOk: bool = true
		if bool(r.get("asBuilt", false)):
			var old: Array = OLD_SCORCH[nm]
			oldOk = hw == (WorldCrater.SCORCH_HW0 + WorldCrater.SCORCH_HW_P * b.pw) * float(old[1])
		var good: bool = key == k and b.variant == nm and n > 0 and vBad == 0 and wBad == 0 and oldOk and dusts == n and dustBad == 0 \
			and sparksBad == 0 and (sparks > 0) == fx.has("sparks") and (fires > 0) == fx.has("fire") and b.sf == sfWant
		ok(good, "beam: %s (seed %d touch %d, x %.0f) fires %s: %d scorch samples at width %.2f%s, %d dust %s, %d sparks, %d fires, bite %s; trees %s (World's treeMode: sigafter_probe)" % [
			k, int(p[0]), int(p[1]), x, nm, n, hw * 2.0, (" (the retired factor's, to the bit)" if bool(r.get("asBuilt", false)) and oldOk else ""),
			dusts, String(fx.dust), sparks, fires, str(b.sf), String(r.trees)])
		SimCore.dispose(S)
	DirData.sigFine = -1


# ---------------------------------------------------------------- play: gen 2 AI matches, off and on

func _play(matches: int, ticks: int) -> void:
	for fine in [0, 1]:
		DirData.sigFine = fine
		var names: Dictionary = {}
		var tags: Dictionary = {}
		var bad: int = 0
		for m in range(matches):
			var S := SimCore.createSim()
			SimCore.newMatch(S, 100 + m, {}, _setup(int(GEN2_SEEDS[m % GEN2_SEEDS.size()]), m % 3))
			for t in range(ticks):
				SimCore.step(S)
				for e in S.out.fx:
					if str(e.type) == "scorch":
						names[String(e.variant)] = int(names.get(String(e.variant), 0)) + 1
				for l in S.out.feed:
					var sub: String = String(l.sub)
					var i: int = sub.find(" over ")
					if i < 0 or sub.find("(", i) < 0:
						continue
					var key: String = sub.substr(i + 6, sub.find(" (", i) - i - 6)
					if not DirData._sig.variants.has(key):
						continue   # another line with " over " in it, not a signature's tag
					var nm: String = sub.substr(sub.find("(", i) + 1, sub.find(")", i) - sub.find("(", i) - 1)
					tags[key + " " + nm] = int(tags.get(key + " " + nm, 0)) + 1
					if (fine == 0 and not OLD_NAMES.has(key)) or String(DirData.sigRow(key).name) != nm:
						bad += 1
				S.out.fx.clear()
				S.out.feed.clear()
				if S.game.ko != null and S.game.koT > 3.0:
					break
			SimCore.dispose(S)
		ok(bad == 0, "play %s: %d gen 2 matches, signatures planned over %s; scorched by %s" % [
			("on" if fine == 1 else "off"), matches, _counts(tags), _counts(names)])
	DirData.sigFine = -1


func _counts(d: Dictionary) -> String:
	var ks: Array = d.keys()
	ks.sort()
	var out: Array = []
	for k in ks:
		out.append("%s %d" % [k, int(d[k])])
	return ", ".join(out) if not out.is_empty() else "none"
