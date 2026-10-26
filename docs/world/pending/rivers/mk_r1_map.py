"""Window 14: planet_map.gd's --rivers overlay (the river cells of the flow field as blue marks on the height and fine pictures).   python mk_r1_map.py <root>"""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def pm(s):
    s = rep(s, '''	var useB: bool = false
''', '''	var useB: bool = false
	var showRivers: bool = false
''')
    s = rep(s, '''		if a == "--b":
			useB = true
''', '''		if a == "--b":
			useB = true
		if a == "--rivers":
			showRivers = true
''')
    s = rep(s, '''			imgL.save_png("%s/planet-%d-gen%d%s-stored.png"''', '''			if showRivers and g >= 2:   # the drainage of the climate grid (window 14): its river cells, blue
				var F: WorldRivers.Flow = WorldRivers.flowOf(P)
				var nr: int = 0
				for i in range(F.w * F.h):
					if P.grid.ht[i] >= 0.0 and F.flow[i] >= WorldRivers.K_RIVER:
						var rx: int = int(fposmod(atan2(F.pz[i], F.px[i]), SimMathx.TAU) / SimMathx.TAU * float(w)) % w
						var ry: int = clampi(int((0.5 - asin(F.py[i]) / SimMathx.PI) * float(h)), 0, h - 1)
						var big: int = 1 if F.flow[i] > 4.0 * WorldRivers.K_RIVER else 0
						for dy in range(-big, big + 1):
							for dx in range(-big, big + 1):
								imgF.set_pixel((rx + dx + w) % w, clampi(ry + dy, 0, h - 1), Color(0.1, 0.35, 1.0))
								imgH.set_pixel((rx + dx + w) % w, clampi(ry + dy, 0, h - 1), Color(0.1, 0.35, 1.0))
						nr += 1
				print("   rivers: %d river cells of %d land cells (%.1f%%)" % [nr, F.landCells, 100.0 * float(nr) / float(maxi(F.landCells, 1))])
			imgL.save_png("%s/planet-%d-gen%d%s-stored.png"''')
    s = rep(s, '''# --b turns''', '''# --rivers draws the flow field's river cells on the height and fine pictures (window 14).
# --b turns''')
    return s


def soak(s):
    s = rep(s, '''		if a == "--b":
			WorldLand.setB(true)''', '''		if a == "--b":
			WorldLand.setB(true)
		if a == "--rivers":
			WorldRivers.setOn(true)   # the rivers on for this run (window 14; the data stays off)''')
    return rep(s, '''(--b: with land.json's b switch on for the run, window 12)''', '''(--b: with land.json's b switch on for the run, window 12; --rivers: with rivers.json on, window 14)''')


rw(R, 'sim/world/tools/gen2_soak.gd', soak)
rw(R, 'sim/world/tools/planet_map.gd', pm)
print('map rivers overlay patched')
