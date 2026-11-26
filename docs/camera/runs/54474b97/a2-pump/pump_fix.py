# Camera, A2 issue c (Orb's "zoom jumps"), park 1: the pump. Scratch builder.
# 1. Split on the coming separation: a pair flying apart fast is judged on the size it will have SPLIT_LOOKAHEAD on, and splits
#    after the ordinary dwell, so the shared view no longer zooms two or three times wider just before it splits.
# 2. The shared view zooms out at the ordinary rate outside a transition (it always had the transition's cap, 4% a tick);
#    the scroll governor's zoom-out for speed keeps the faster rate.
# usage: python pump_fix.py <tree>
import sys
t = sys.argv[1]
NL = chr(10)


def edit(path, old, new):
    s = open(path, encoding='utf-8').read()
    assert s.count(old) == 1, (path, old[:80], s.count(old))
    s = s.replace(old, new)
    open(path, 'w', encoding='utf-8', newline=NL).write(s)


q = t + '/render/camera/camera_params.gd'
c = open(q, encoding='utf-8').read()
i = c.index('const CLOSING_LOOKAHEAD: float = 0.4')
j = c.index(NL, i) + 1
c = c[:j] + (
    'const SPLIT_LOOKAHEAD: float = 0.35    # a pair flying apart (SPLIT_LOOK_RATE) is judged on the size it will have this many seconds on: the split comes before the shared view has zoomed out for it\n'
    'const SPLIT_LOOK_RATE: float = 1500.0  # ... from this separation speed, units a second, smoothed (KNOCK_APART_RATE\'s)\n'
    'const SPLIT_LOOK_FROM: float = 3.0     # ... and neither this nor the shared view\'s ordinary zoom-out in a match\'s first seconds:the opening\'s framing is Orb\'s own question (split_sweep\'s OPENING_PLANET_CEIL), not this rule\'s\n'
) + c[j:]
open(q, 'w', encoding='utf-8', newline=NL).write(c)

p = t + '/render/camera/split_rig.gd'
edit(p, 'var merge_lookahead: bool = true ',
     'var split_lookahead: bool = true                        # a pair flying apart fast splits on the size it will have (CamParams.SPLIT_LOOKAHEAD), after the ordinary dwell: the shared view no longer zooms out two or three times just before it splits (the pump, Orb\'s "zoom jumps"; docs/camera/pending/a2-pump). Off: as before\n'
     'var merged_out_ordinary: bool = true                    # the shared view zooms out at the ordinary comfort rate outside a transition (it had the transition\'s, 4% a tick); the scroll governor\'s zoom-out for speed keeps the faster one. Off: as before\n'
     'var split_look_ticks: int = 0                           # (ticks the coming separation counted for the split, for the tests)\n'
     'var merge_lookahead: bool = true ')
# 1. the trigger
edit(p, '''	if not split_wanted:
		_below_t = _below_t + DT if r_now < rs else 0.0''', '''	if not split_wanted:
		# A pair flying apart fast: the size it will have SPLIT_LOOKAHEAD on. Below the line, the split waits the ordinary dwell only.
		var look_below: bool = false
		if split_lookahead and time >= CamParams.SPLIT_LOOK_FROM and _sep_rate > CamParams.SPLIT_LOOK_RATE and r_now >= rs:
			var ad_s: float = minf(SimConst.HALF, ad + _sep_rate * CamParams.SPLIT_LOOKAHEAD)
			look_below = CamParams.BODY_H * zoom_u(vw, vh, ad_s, _pair_dy(A, B), maxf(A.tier, B.tier)) / vh < rs
			if look_below:
				split_look_ticks += 1
		_below_t = _below_t + DT if (r_now < rs or look_below) else 0.0''')
edit(p, '''		var dwell: float = CamParams.SPLIT_DWELL + (CamParams.WIDE_HOLD if _sep_rate > 500.0 and r_now > floor_r else 0.0)''',
     '''		var dwell: float = CamParams.SPLIT_DWELL + (CamParams.WIDE_HOLD if _sep_rate > 500.0 and r_now > floor_r and not look_below else 0.0)''')
# 2. the shared view's zoom-out
edit(p, '''		var capm: float = (CamParams.SLAM_ZOOM_RATE if stiff else CamParams.ZOOM_RATE_TRANS) * DT
		dzm = clampf(dzm, -capm, capm)''', '''		var capm: float = (CamParams.SLAM_ZOOM_RATE if stiff else CamParams.ZOOM_RATE_TRANS) * DT
		var capm_out: float = capm
		if merged_out_ordinary and not transition and not _gov_bind_m and time >= CamParams.SPLIT_LOOK_FROM and _pk_phase == "":   # (not the peak launch's own framing)
			capm_out = CamParams.ZOOM_RATE * DT   # (zooming out for a pair that parts: the ordinary rate; a fighter who leaves the frame opens the split)
		dzm = clampf(dzm, -capm_out, capm)''')
print('pump fix in')
