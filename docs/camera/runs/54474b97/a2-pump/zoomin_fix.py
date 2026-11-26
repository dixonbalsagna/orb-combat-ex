# Camera, A2 issue c, park 2 (after a2-pump): the zoom-in eases after a split or a slam's join. Scratch builder.
# - A pane zooming in while the split opens or closes (not the slam's door, not a shot) takes the ordinary comfort rate, not the
#   transition's (4% a tick): the panes zoomed back in at the cap as the split opened (0.32 to 0.70 in 0.4 s, seed 3 at 79 s).
# - The shared view zooming in outside a transition (just after a slam's join, or a pair that comes together) takes the ordinary rate too.
# usage: python zoomin_fix.py <tree>   (on a tree with pump_fix.py applied)
import sys
t = sys.argv[1]


def edit(path, old, new):
    s = open(path, encoding='utf-8').read()
    assert s.count(old) == 1, (path, old[:80], s.count(old))
    s = s.replace(old, new)
    open(path, 'w', encoding='utf-8', newline=chr(10)).write(s)


p = t + '/render/camera/split_rig.gd'
edit(p, 'var split_look_ticks: int = 0 ',
     'var zoom_in_ordinary: bool = true                       # a pane zooming in while the split opens or closes, and the shared view zooming in outside a transition (after a slam\'s join), take the ordinary comfort rate (docs/camera/pending/a2-zoom-in). The slam\'s door and the shots keep theirs. Off: as before\n'
     'var split_look_ticks: int = 0 ')
edit(p, '''		var cap: float = (CamParams.SLAM_ZOOM_RATE if stiff else zrate) * DT
''', '''		var cap: float = (CamParams.SLAM_ZOOM_RATE if stiff else zrate) * DT
		var cap_in_z: float = cap
		if zoom_in_ordinary and not stiff and solo_kind == "" and solo_w < 0.001 and sep > 0.001 and sep < 0.999:
			cap_in_z = CamParams.ZOOM_RATE * DT   # (the split opening or closing: a pane zooms in at the ordinary rate)
''')
# the clamp right after it
s = open(p, encoding='utf-8').read()
old = '''		_zr_pane[i] = zrate
		dz = clampf(dz, -cap, cap)'''
assert s.count(old) == 1, s.count(old)
s = s.replace(old, '''		_zr_pane[i] = zrate
		dz = clampf(dz, -cap, cap_in_z)''')
open(p, 'w', encoding='utf-8', newline=chr(10)).write(s)
edit(p, '''		dzm = clampf(dzm, -capm_out, capm)''', '''		var capm_in: float = capm
		if zoom_in_ordinary and not transition and _pk_phase == "":
			capm_in = CamParams.ZOOM_RATE * DT   # (after a slam's join, or a pair coming together: the ordinary rate)
		dzm = clampf(dzm, -capm_out, capm_in)''')
# the drawn zoom: in an opening it is the blend from the shared camera to the pane's own, and the blend's zoom-in was clipped at the
# transition's cap; it takes the ordinary rate there too (wider for a moment, never tighter)
edit(p, '''			var cap_up: float = cap
			if merge_zoom_limit and not reduced_motion and _merging_now():''', '''			var cap_up: float = cap
			if zoom_in_ordinary and not slam_now and solo_kind == "" and sep > 0.001 and sep < 0.999:
				cap_up = minf(cap_up, CamParams.ZOOM_RATE * DT)   # (the split opening or closing: the drawn zoom comes in at the ordinary rate)
			if merge_zoom_limit and not reduced_motion and _merging_now():''')
print('zoom-in fix in')
