"""Window 12: planet_map.gd's --b flag (land.json's b switch on for the run; the files carry a 'b' after the generation).   python mk_w12_map.py <root>"""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def pm(s):
    s = rep(s, '''	var places: bool = false
''', '''	var places: bool = false
	var useB: bool = false
''')
    s = rep(s, '''		if a == "--places":
			places = true
''', '''		if a == "--places":
			places = true
		if a == "--b":
			useB = true
''')
    s = rep(s, '''	var h: int = w / 2
''', '''	if useB:
		WorldLand.setB(true)   # Research's B plates for this run (window 12)
	var tag: String = "b" if useB else ""
	var h: int = w / 2
''')
    s = rep(s, '''"%s/planet-%d-gen%d-stored.png" % [out, sd, g]''', '''"%s/planet-%d-gen%d%s-stored.png" % [out, sd, g, tag if g >= 2 else ""]''')
    s = rep(s, '''"%s/planet-%d-gen%d-height.png" % [out, sd, g]''', '''"%s/planet-%d-gen%d%s-height.png" % [out, sd, g, tag if g >= 2 else ""]''')
    s = rep(s, '''"%s/planet-%d-gen%d-fine.png" % [out, sd, g]''', '''"%s/planet-%d-gen%d%s-fine.png" % [out, sd, g, tag if g >= 2 else ""]''')
    s = rep(s, '''# --edges draws''', '''# --b turns land.json's b switch on for the run (Research's B plates, window 12; the files are planet-<seed>-gen2b-*.png).
# --edges draws''')
    return s


def soak(s):
    s = rep(s, '''#   godot --headless --path . --script res://sim/world/tools/gen2_soak.gd -- --ticks=900''', '''#   godot --headless --path . --script res://sim/world/tools/gen2_soak.gd -- --ticks=900     (--b: with land.json's b switch on for the run, window 12)''')
    return rep(s, '''		if a.begins_with("--ticks="):
			ticks = int(a.substr(8))''', '''		if a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		if a == "--b":
			WorldLand.setB(true)''')


rw(R, 'sim/world/tools/gen2_soak.gd', soak)
rw(R, 'sim/world/tools/planet_map.gd', pm)
print('map and soak tools patched')
