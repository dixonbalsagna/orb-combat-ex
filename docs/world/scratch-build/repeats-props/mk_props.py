"""The throwable objects' hold points (World, scratch, parked): data/biomes/props.json, its schema and sim/world/props.gd.
python mk_props.py <root> <props.gd>      (root: an export of main's HEAD; the vehicles' boxes are read from data/art/vehicles.json)"""
import sys, json, collections, shutil
OD = collections.OrderedDict
R = sys.argv[1].rstrip('/') + '/'
shutil.copyfile(sys.argv[2], R + 'sim/world/props.gd')
veh = json.load(open(R + 'data/art/vehicles.json', encoding='utf-8'))['vehicles']
depth = {"bike": 20, "sedan": 72, "van": 76, "bus": 90}
slots = ["frame", "underside_l", "underside_r", "top", "end_a", "end_b"]
cls = OD()
for k in ["bike", "sedan", "van", "bus"]:
    v = veh[k]; L = float(v['length']); H = float(v['height']); wr = float(v['wheel_radius'])
    clear = round(wr * 0.9, 1)   # the chassis underside above the ground
    cls[k] = OD([("length", int(L)), ("height", int(H)), ("depth", depth[k]), ("mass", int(v['mass_class'])), ("throwTier", int(v['throw_tier'])),
                 ("holds", OD([
                     ("frame", [0, round(H * 0.5, 1), 0]),
                     ("underside_l", [round(-0.28 * L, 1), clear, 0]),
                     ("underside_r", [round(0.28 * L, 1), clear, 0]),
                     ("top", [0, int(H), 0]),
                     ("end_a", [round(-0.5 * L, 1), round(H * 0.45, 1), 0]),
                     ("end_b", [round(0.5 * L, 1), round(H * 0.45, 1), 0])]))])
d = OD([("schema", "biomes.props/1"),
        ("_about", "The throwable objects' hold points (docs/world/prop-hold-points.md; WorldProps): where a hand grips an object, for Animation's grip on a prop (docs/animation/throwables-sizing.md T1). Each class has its box (length along x, height, depth across z, in world units; a fighter is 75), its mass class and the first tier that can lift it (Art's docs/art/cars.md, data/art/vehicles.json), and six hold points: frame (the middle of the body), underside_l and underside_r (under the chassis, each side of the middle, a hand's reach apart for a two-handed lift), top (the roof), end_a (the rear) and end_b (the front). A point is [x, y, z] in the prop's own frame: the origin on the ground under its centre, x along its length with the front at +x, y up, z across (positive toward the camera). WorldProps.holdPoint turns one into a world point from the prop's place, turn and facing. First values from the box; Animation measures them against the poses."),
        ("slots", slots), ("classes", cls)])
open(R + 'data/biomes/props.json', 'w', encoding='utf-8', newline='').write(json.dumps(d, indent=2, ensure_ascii=False) + '\n')
pt = OD([("type", "array"), ("minItems", 3), ("maxItems", 3), ("items", OD([("type", "number"), ("minimum", -2000), ("maximum", 2000)])), ("description", "[x, y, z] in the prop's own frame (world units)")])
c = OD([("type", "object"), ("required", ["length", "height", "depth", "mass", "throwTier", "holds"]), ("additionalProperties", False), ("properties", OD([
    ("length", OD([("type", "number"), ("minimum", 1), ("maximum", 2000), ("description", "Along x, front at +x (world units).")])),
    ("height", OD([("type", "number"), ("minimum", 1), ("maximum", 2000), ("description", "Up from the ground under the centre.")])),
    ("depth", OD([("type", "number"), ("minimum", 1), ("maximum", 2000), ("description", "Across z.")])),
    ("mass", OD([("type", "integer"), ("minimum", 1), ("maximum", 64), ("description", "Art's mass class (bike 1, sedan 3, van 4, bus 8).")])),
    ("throwTier", OD([("type", "integer"), ("minimum", 1), ("maximum", 4), ("description", "The first power tier that can lift it.")])),
    ("holds", OD([("type", "object"), ("required", slots), ("additionalProperties", False), ("properties", OD([(k, pt) for k in slots]))]))]))])
sch = OD([
    ("$schema", "https://json-schema.org/draft/2020-12/schema"),
    ("$id", "meridian/biomes-props"),
    ("title", "biomes.props/1"),
    ("description", "data/biomes/props.json: the throwable objects' hold points (docs/world/prop-hold-points.md; WorldProps). Per class: its box, mass class, first tier that lifts it, and the six hold points (frame, underside_l, underside_r, top, end_a, end_b) as [x, y, z] in the prop's own frame. Every key required. Version field: schema. Policy: closed except keys starting with an underscore."),
    ("type", "object"),
    ("required", ["schema", "slots", "classes"]),
    ("properties", OD([
        ("schema", OD([("const", "biomes.props/1")])),
        ("_about", OD([("type", "string")])),
        ("slots", OD([("const", slots), ("description", "The hold-point names, in order.")])),
        ("classes", OD([("type", "object"), ("minProperties", 1), ("propertyNames", OD([("pattern", "^[a-z][a-z_]*$")])), ("additionalProperties", c)]))])),
    ("additionalProperties", False)])
open(R + 'tools/schemas/biomes-props.schema.json', 'w', encoding='utf-8', newline='').write(json.dumps(sch, indent=2, ensure_ascii=False) + '\n')
print('props applied')
