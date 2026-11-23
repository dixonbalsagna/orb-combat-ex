# The planet's sky tint (the EP's ruling for Orb, 2026-10-27, option (b); Art's sky_tint in data/art/biomes.json): at a
# match's start every sky key's horizon is mixed sky_tint.horizon (0.10) and its top sky_tint.top (0.04) in OKLab toward
# the orbit colour of the biome that holds most of the arena's columns; the two bands between take a third and two
# thirds of the way from one share to the other. Once a match: no per-frame or per-place change. SkyDrive.tint_on
# (main's --noskytint) turns it off; sky_check runs Art's key checks with it off and checks the tint on its own.
#   python h108_skytint.py <tree>   (main e0d6681e)
import sys
root = sys.argv[1]


def patch(rel, pairs):
    p = root + '/' + rel
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (rel, a[:70], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)
    print(rel, 'ok')


p = root + '/render/core/sky_drive.gd'
s = open(p, encoding='utf-8').read()
# The lap's table is built by its own function, so a tint can build it again from the tinted keys; the transitions it
# reads become a static (they were ensure()'s local).
assert s.count('\tvar trans: Array = [{}]\n') == 1 and s.count('\t\ttrans = d.blend.transitions\n') == 1
s = s.replace('\tvar trans: Array = [{}]\n', '\t_trans = [{}]\n').replace('\t\ttrans = d.blend.transitions\n', '\t\t_trans = d.blend.transitions\n')
i = s.index('\t_lab.resize(N * 12)\n')
j = s.index('\n\n## One key\'s world light from the data')
body = s[i:j].replace('trans[ki]', '_trans[ki]')
assert 'trans' not in body.replace('_trans[ki]', '')
s = s[:i] + '\t_cols0 = keys.map(func(k): return (k.cols as Array).duplicate())   # Art\'s keys, untinted\n\t_build()\n' + s[j:]
a = '\n\n## One key\'s world light from the data'
s = s.replace(a, '''


## The lap's table (N places: each band's OKLab and luminance, the stars, the key a place stands on, the world's light)
## from the keys as they are now: Art's, or tinted for this planet (set_tint).
static func _build() -> void:
''' + body + a, 1)
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('sky_drive _build ok')

patch('render/core/sky_drive.gd', [
    ("""static var _key := PackedInt32Array()      # N: the key a sample stands on exactly (inside a hold), or -1
""", """static var _key := PackedInt32Array()      # N: the key a sample stands on exactly (inside a hold), or -1
static var _trans: Array = [{}]            # the data's transitions: per key, the path each band takes to the next
static var tint_on: bool = true           # the planet's sky tint (set_tint); main's --noskytint turns it off
static var tint_biome: String = ""         # the biome the sky is tinted toward this match ("" for none)
static var tint_version: int = 0           # bumps when the keys change: a pane works its sky out again
static var _cols0: Array = []              # Art's keys' colours, untinted (per key, BANDS order)
static var _tint_key: Array = []           # the tint the keys have now: [orbit html, horizon share, top share]
"""),
    ("""	_make_towns(S)


## World's turn (window 3)""", """	_make_towns(S)
	_planet_tint(S)


## The planet's sky tint (Art's sky_tint, data/art/biomes.json; the EP's ruling of 2026-10-27): toward the orbit colour
## of the biome that holds most of the arena's columns (on gen 2 the fine biome; a town's or a city's ground counts as
## the biome under it), once a match, so it never moves while a camera flies. A turn keeps the planet's tint.
func _planet_tint(S: SimState) -> void:
	var st = RenderBiomeLook.data().get("sky_tint") if RenderBiomeLook.data() is Dictionary else null
	var kh: float = float(st.get("horizon", 0.0)) if st is Dictionary and tint_on else 0.0
	var kt: float = float(st.get("top", 0.0)) if st is Dictionary and tint_on else 0.0
	var nc: int = SimConst.NC
	var fine: bool = WorldBiomes.fineCols.size() == nc
	var count: Dictionary = {}
	for i in range(0, nc, 4):
		var name: String = WorldClimate.fineName(WorldBiomes.fineCols[i]) if fine else WorldBiomes.biomeAt((float(i) + 0.5) * SimConst.COL)
		if name != "city" and name != "village":
			count[name] = int(count.get(name, 0)) + 1
	var best: String = ""
	var names: Array = count.keys()
	names.sort()
	for name in names:
		if best == "" or int(count[name]) > int(count[best]):
			best = name
	var orbit = RenderBiomeLook.entry(best).get("orbit") if best != "" else null
	tint_biome = best if orbit != null and (kh > 0.0 or kt > 0.0) else ""
	set_tint(Color.html(str(orbit)) if orbit != null else Color.WHITE, kh if orbit != null else 0.0, kt if orbit != null else 0.0)


## The keys tinted toward orbit: each key's horizon mixed kh and its top kt in OKLab, the bands between a third and two
## thirds of the way from one share to the other; then the lap's table again (a few milliseconds, once a match). kh = kt
## = 0 gives Art's keys back exactly.
static func set_tint(orbit: Color, kh: float, kt: float) -> void:
	ensure()
	var want: Array = [orbit.to_html(false), kh, kt]
	if want == _tint_key or _cols0.size() != keys.size():
		return
	_tint_key = want
	var o: Vector3 = to_lab(orbit)
	for ki in range(keys.size()):
		var cols: Array = []
		for bi in range(4):
			var k: float = lerpf(kh, kt, float(bi) / 3.0)
			var c0: Color = _cols0[ki][bi]
			cols.append(c0 if k <= 0.0 else lin_to_color(lab_to_lin(to_lab(c0).lerp(o, k))))
		keys[ki].cols = cols
	_build()
	tint_version += 1


## World's turn (window 3)"""),
    ("""	var fresh: bool = st.is_empty() or is_nan(dt) or dt < 0.0 or dt > 0.5 or not is_nan(hold_phase) or not hold_mood.is_empty() or (dt == 0.0 and snap_still)
""", """	var fresh: bool = st.is_empty() or is_nan(dt) or dt < 0.0 or dt > 0.5 or not is_nan(hold_phase) or not hold_mood.is_empty() or (dt == 0.0 and snap_still) or int(st.get("tv", -1)) != tint_version
"""),
    ("""	st.cols = cols
	st.star_low""", """	st.cols = cols
	st.tv = tint_version
	st.star_low"""),
])

patch('render/core/main.gd', [
    ("""	GroundField.fine_on = not args.has("nofine")""", """	SkyDrive.tint_on = not args.has("noskytint")   # the planet's sky tint (Art's sky_tint): on; --noskytint for the A/B
	GroundField.fine_on = not args.has("nofine")"""),
    ('"noladder", "nofine"]', '"noladder", "nofine", "noskytint"]'),
])

patch('render/tools/sky_check.gd', [
    ("""const ASKED_HEADLESS: int = 32""", """const ASKED_HEADLESS: int = 35"""),
    ("""func _run() -> void:
	await process_frame
	main.started = true
	main.start_match(seed)""", """func _run() -> void:
	await process_frame
	main.started = true
	SkyDrive.tint_on = false   # Art's keys to the bit; the planet's tint is checked on its own (_tint)
	main.start_match(seed)"""),
    ("""	if asked < ASKED_HEADLESS:""", """	_tint()
	if asked < ASKED_HEADLESS:"""),
    ("""# ------------------------------------------------------------------ the dynamic sky
""", """# ------------------------------------------------------------------ the planet's sky tint

## Art's sky_tint (the EP's ruling of 2026-10-27): every key's horizon mixed its share and its top its share in OKLab
## toward the orbit colour of the arena's commonest biome, once a match; shares of 0 give Art's keys back exactly.
func _tint() -> void:
	SkyDrive.tint_on = true
	main.start_match(seed)
	var st: Dictionary = RenderBiomeLook.data().get("sky_tint", {})
	var kh: float = float(st.get("horizon", 0.0))
	var kt: float = float(st.get("top", 0.0))
	var o: Vector3 = SkyDrive.to_lab(Color.html(str(RenderBiomeLook.entry(SkyDrive.tint_biome).get("orbit", "#ffffff"))))
	var worst: float = 0.0
	for ki in range(SkyDrive.keys.size()):
		for bi in range(4):
			var want: Color = SkyDrive.lin_to_color(SkyDrive.lab_to_lin(SkyDrive.to_lab(SkyDrive._cols0[ki][bi]).lerp(o, lerpf(kh, kt, float(bi) / 3.0))))
			var got: Color = SkyDrive.keys[ki].cols[bi]
			worst = maxf(worst, maxf(absf(want.r - got.r), maxf(absf(want.g - got.g), absf(want.b - got.b))) * 255.0)
	_expect(SkyDrive.tint_biome != "" and kh > 0.0 and worst < 0.5, "the planet's tint: every key's horizon %.2f and its top %.2f toward %s's orbit colour, the bands between in steps (off by %.2f of 255 at most)" % [kh, kt, SkyDrive.tint_biome, worst])
	var v0: int = SkyDrive.tint_version
	var sky: SkyDrive = main.host.sky
	for f in range(60):
		var stp: Dictionary = {}
		sky.pane(stp, float(f) * 400.0, float(f) / 60.0)
	main.frame(1.0 / 60.0)
	_expect(SkyDrive.tint_version == v0, "it holds while the camera flies the arena (no change of the keys in 60 frames)")
	SkyDrive.set_tint(Color.WHITE, 0.0, 0.0)
	var same: bool = true
	for ki in range(SkyDrive.keys.size()):
		for bi in range(4):
			same = same and SkyDrive.keys[ki].cols[bi] == SkyDrive._cols0[ki][bi]
	_expect(same, "shares of 0 give Art's keys back to the bit")
	SkyDrive.tint_on = false


# ------------------------------------------------------------------ the dynamic sky
"""),
])
print('h108 ok')
