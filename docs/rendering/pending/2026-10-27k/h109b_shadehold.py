# h109b (the shade face only; h109 held the lit face too and made the clip worse). The signature clip's normal FAIL (Tools' bisect, docs/tools/signature-bisect-2026-10-27.md: first on c9bd20d1, 22n):
# the ground's lit and shade faces differ from its mid by up to 0.29 of relative luminance on the screen (the desert's
# shade, 0.33 against 0.62 at the front), so a dune's face panned or cut across in the split view flips tens of
# thousands of pixels. The palette now holds each biome's lit and shade ground faces within RenderLook.PATTERN_BUDGET of
# its mid face, where the band is drawn lightest (its front depth step), scaled along their own colour so they keep
# Art's hue: the facets stay, tone on tone. Once, in the palette (no shader cost). main's --nofacethold draws Art's
# tones as written (the A/B).   python h109_facethold.py <tree>   (main f8b8af7f)
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


patch('render/core/biome_look.gd', [
    ("""	var out: Array = []
	for h in g + r:
		out.append(RenderLook.col(h))
""", """	var out: Array = []
	for h in g + r:
		out.append(RenderLook.col(h))
	if hold_faces and not HOLD_SKIP.has(name):
		out[2] = held(out[2], out[1])   # the ground's shade face (the lit face stays Art's: see held)
"""),
    ("""## Biome k's far land:""", """## The ground's shade face held to the contrast budget (RenderLook.PATTERN_BUDGET; the signature clip's bisect,
## docs/tools/signature-bisect-2026-10-27.md): open ground fills most of a frame, so a face that turns as the camera pans
## or cuts flips every pixel it covers, and Art's desert shade sat 0.29 of relative luminance under its mid on the
## screen. The shade is drawn at most the budget under the mid where the band is lightest (its front depth step,
## DEPTH_STEP.x, as terrain.gdshaderinc multiplies it), scaled along its own colour so it keeps Art's hue: the facets
## stay, tone on tone. The lit face stays Art's: held, the desert's lit sand fell under 0.8 of luminance, where a bright
## effect over it counts as a flash (the clip got worse in both modes). Off (main's --nofacethold), Art's tones. HOLD_SKIP: the ices' ground is two
## materials by Art's design (white over slate, 0.72 apart), which scaling would turn a bright blue; it stays as Art
## wrote it until Art rules on it.
static var hold_faces: bool = true
const HOLD_SKIP: Array = ["ice_sheet", "sea_ice"]


## Colour c (a face of the ground) held within the budget of mid on the screen; c itself if it is already within it.
static func held(c: Color, mid: Color) -> Color:
	var k: float = RenderLook.DEPTH_STEP.x
	var lm: float = _screen_l(mid, 1.0, k)
	var lc: float = _screen_l(c, 1.0, k)
	var b: float = RenderLook.PATTERN_BUDGET
	if absf(lc - lm) <= b:
		return c
	var want: float = lm + (b if lc > lm else -b)
	var lo: float = 0.0
	var hi: float = 1.0 / maxf(maxf(c.r, c.g), maxf(c.b, 0.001))   # as far as the colour goes before a channel is full
	for i in range(40):
		var s: float = (lo + hi) * 0.5
		if _screen_l(c, s, k) < want:
			lo = s
		else:
			hi = s
	var f: float = (lo + hi) * 0.5
	return Color(c.r * f, c.g * f, c.b * f, c.a)


## The relative luminance colour c scaled by s draws at on the band's step k (an sRGB colour times k, as the shader does).
static func _screen_l(c: Color, s: float, k: float) -> float:
	return Color(minf(c.r * s * k, 1.0), minf(c.g * s * k, 1.0), minf(c.b * s * k, 1.0)).srgb_to_linear().get_luminance()


## Biome k's far land:"""),
])

patch('render/core/main.gd', [
    ("""	GroundField.fine_on = not args.has("nofine")   # gen 2's fine palettes in the band: on; --nofine for the A/B
""", """	GroundField.fine_on = not args.has("nofine")   # gen 2's fine palettes in the band: on; --nofine for the A/B
	RenderBiomeLook.hold_faces = not args.has("nofacethold")   # the ground's faces within the contrast budget: on; --nofacethold for the A/B
"""),
    ('"noladder", "nofine"]', '"noladder", "nofine", "nofacethold"]'),
])
print('h109 ok')
