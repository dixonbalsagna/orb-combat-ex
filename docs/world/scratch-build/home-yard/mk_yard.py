"""Scratch: the Cyborg's breaking yard as a home set piece (World, 2026-10-23; docs/world/home-set-pieces.md).   python mk_yard.py <root>"""
import sys, json, collections
from mk_wbc_lib import rw, rep
OD = collections.OrderedDict
R = sys.argv[1].rstrip('/') + '/'

yard = {
  "schema": "biomes.homes/1",
  "_about": "Home set pieces (scratch): each class is an archetype in the settlement generator's own form (settlements.json's districts), laid on a place the planet generator gives it. people 0: no one lives in a breaking yard.",
  "classes": {
    "yard": {
      "name": "Slagholt", "people": 0, "wreck": 0.4,
      "archetype": {
        "id": "home_yard", "archetype": "yard", "span": [0, 1], "pop_share": 0.0,
        "districts": [
          {"name": "bays", "look": "industrial", "share": 0.18, "rows": [1, 2],
           "kinds": [{"kind": "house", "shape": "warehouse", "weight": 0.5}, {"kind": "house", "shape": "sawtooth", "weight": 0.3}, {"kind": "house", "shape": "shed", "weight": 0.2}],
           "height_bh": {"median": 6, "spread": 0.3, "min": 4, "max": 10, "centre_bump": 0.0}, "width_bh": [10, 18], "depth_fill": [0.7, 0.95], "gap_bh": [1.5, 4], "block_bh": [30, 50], "avenue_bh": [6, 9],
           "row_h": [0.6, 1.0, 1.0, 1.0], "pop_density": 0.0, "landmarks": [{"key": "chimney_stack", "count": 1, "place": "start", "row": 2}], "row_pop": [1.0, 0.25, 1.0, 1.0]},
          {"name": "gantries_west", "look": "industrial", "share": 0.17, "rows": [1, 2],
           "kinds": [{"kind": "tower", "shape": "crane", "weight": 0.55, "height_bh": {"median": 24, "spread": 0.25, "min": 16, "max": 34}, "width_bh": [2.5, 4.0]}, {"kind": "house", "shape": "shed", "weight": 0.25}, {"kind": "house", "shape": "warehouse", "weight": 0.2}],
           "height_bh": {"median": 4, "spread": 0.3, "min": 3, "max": 7, "centre_bump": 0.0}, "width_bh": [6, 11], "depth_fill": [0.6, 0.9], "gap_bh": [3, 8], "block_bh": [24, 36], "avenue_bh": [6, 9],
           "row_h": [0.6, 1.0, 1.0, 1.0], "pop_density": 0.0, "landmarks": [], "row_pop": [1.0, 0.25, 1.0, 1.0]},
          {"name": "hulk_field", "look": "industrial", "share": 0.30, "rows": [0, 1, 2, 3],
           "kinds": [{"kind": "house", "shape": "warehouse", "weight": 0.5}, {"kind": "house", "shape": "shed", "weight": 0.2}, {"kind": "house", "shape": "sawtooth", "weight": 0.15}, {"kind": "tower", "shape": "crane", "weight": 0.15, "height_bh": {"median": 20, "spread": 0.25, "min": 14, "max": 30}, "width_bh": [2.5, 4.0]}],
           "height_bh": {"median": 2.6, "spread": 0.25, "min": 1.8, "max": 4, "centre_bump": 0.0}, "width_bh": [12, 24], "depth_fill": [0.6, 0.95], "gap_bh": [0.5, 2.5], "block_bh": [40, 70], "avenue_bh": [5, 8],
           "row_h": [0.6, 1.0, 1.0, 1.0], "pop_density": 0.0, "landmarks": [], "row_pop": [1.0, 0.25, 1.0, 1.0]},
          {"name": "gantries_east", "look": "industrial", "share": 0.20, "rows": [1, 2],
           "kinds": [{"kind": "tower", "shape": "crane", "weight": 0.55, "height_bh": {"median": 24, "spread": 0.25, "min": 16, "max": 34}, "width_bh": [2.5, 4.0]}, {"kind": "house", "shape": "shed", "weight": 0.25}, {"kind": "house", "shape": "warehouse", "weight": 0.2}],
           "height_bh": {"median": 4, "spread": 0.3, "min": 3, "max": 7, "centre_bump": 0.0}, "width_bh": [6, 11], "depth_fill": [0.6, 0.9], "gap_bh": [3, 8], "block_bh": [24, 36], "avenue_bh": [6, 9],
           "row_h": [0.6, 1.0, 1.0, 1.0], "pop_density": 0.0, "landmarks": [], "row_pop": [1.0, 0.25, 1.0, 1.0]},
          {"name": "slag_end", "look": "industrial", "share": 0.15, "rows": [1, 2],
           "kinds": [{"kind": "tower", "shape": "chimney", "weight": 0.3, "height_bh": {"median": 28, "spread": 0.2, "min": 20, "max": 36}, "width_bh": [3, 4.5]}, {"kind": "house", "shape": "warehouse", "weight": 0.7}],
           "height_bh": {"median": 5, "spread": 0.3, "min": 3, "max": 8, "centre_bump": 0.0}, "width_bh": [8, 14], "depth_fill": [0.6, 0.9], "gap_bh": [2, 5], "block_bh": [24, 40], "avenue_bh": [6, 9],
           "row_h": [0.6, 1.0, 1.0, 1.0], "pop_density": 0.0, "landmarks": [{"key": "chimney_stack", "count": 1, "place": "end", "row": 1}], "row_pop": [1.0, 0.25, 1.0, 1.0]}
        ]
      }
    }
  }
}
# sizes in body heights (BH 75 units): a yard's buildings are bays and hulks a few BH across, crowded, with the cranes standing among them
_dims = {"bays": ([4, 7], [0.5, 2], (4, 3, 7)), "gantries_west": ([3, 5], [1, 3], (3, 2.5, 5)), "hulk_field": ([3, 6], [0.3, 1.5], (1.6, 1.1, 2.6)), "gantries_east": ([3, 5], [1, 3], (3, 2.5, 5)), "slag_end": ([4, 7], [0.5, 2], (4, 3, 7))}
for dd in yard["classes"]["yard"]["archetype"]["districts"]:
    w, g, (med, lo, hi) = _dims[dd["name"]]
    dd["width_bh"] = w
    dd["gap_bh"] = g
    dd["height_bh"] = {"median": med, "spread": 0.25, "min": lo, "max": hi, "centre_bump": 0.0}
    for k in dd["kinds"]:
        if k["shape"] == "crane":
            k["width_bh"] = [1.6, 2.6]
            k["height_bh"] = {"median": 22, "spread": 0.25, "min": 15, "max": 30}
        if k["shape"] == "chimney":
            k["width_bh"] = [2.5, 3.5]
            k["height_bh"] = {"median": 26, "spread": 0.2, "min": 20, "max": 32}
open(R + 'data/biomes/homes.json', 'w', encoding='utf-8', newline='').write(json.dumps(yard, indent=2) + '\n')


def planet_world(s):
    s = rep(s, '''static func settle(S: SimState, P: WorldPlanet.Planet, chords: Array, wsum: float, planTag: int, distOffset: int, setOffset: int) -> Dictionary:''',
        '''static var homeOf: Dictionary = {}   # scratch: place id -> home class key (the planet generator will set it from the home rule)
static var _homes: Dictionary = {}


static func homes() -> Dictionary:
	if _homes.is_empty():
		_homes = JSON.parse_string(FileAccess.get_file_as_string("res://data/biomes/homes.json"))
	return _homes


static func settle(S: SimState, P: WorldPlanet.Planet, chords: Array, wsum: float, planTag: int, distOffset: int, setOffset: int) -> Dictionary:''')
    s = rep(s, '''		sd.id = "p%d" % ch[0]
		sd.span = [float(ch[2]) * COL / PS, float(ch[3]) * COL / PS]
		sd.pop_share = float(P.people[ch[0]]) / maxf(wsum, 1.0)''', '''		var hc = homes().classes.get(homeOf.get(ch[0], ""), null)
		if hc != null:
			sd = hc.archetype.duplicate(true)
		sd.id = "p%d" % ch[0]
		sd.span = [float(ch[2]) * COL / PS, float(ch[3]) * COL / PS]
		sd.pop_share = float(P.people[ch[0]]) / maxf(wsum, 1.0) if (hc == null or float(hc.people) > 0.0) else 0.0''')
    return s


def planet_world2(s):
    return rep(s, '''	settleBiomes(cols, S.base, chords)''', '''	settleBiomes(cols, S.base, chords.filter(func(c): return not homeOf.has(c[0])))   # a home keeps its own ground's biome (a yard stays sand)''')


rw(R, 'sim/world/planet_world.gd', planet_world)
rw(R, 'sim/world/planet_world.gd', planet_world2)
print('yard applied')
