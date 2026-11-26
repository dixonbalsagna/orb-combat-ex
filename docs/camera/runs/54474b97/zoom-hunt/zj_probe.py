# Camera, A2 issue c (Orb: "zoom jumps"): a scratch probe from split_sweep.gd that plays long AI matches with the rig as the game
# ships it (its own defaults: no travel budget, the flash bundle; Reduce flashing on unless --normal) and logs every zoom change
# a player could feel: a step (|d ln z| per tick over ZJ_DZ) or a sudden change of zoom speed (|dd ln z| over ZJ_DDZ), per pane
# with a real share of the screen, with the sweep's cause classes. usage: python zj_probe.py <tree>
import sys
t = sys.argv[1]
src = t + '/render/camera/tests/split_sweep.gd'
s = open(src, encoding='utf-8').read()

def rep(old, new):
    global s
    assert s.count(old) == 1, old[:70]
    s = s.replace(old, new, 1)

# the rig as the game ships it
rep('''	_rig = SplitRig.new()
	_rig.flash_bundle = false   # the rows set the pieces they test; the shipped default (the bundle under reduced flashing) has its own row
	_rig.travel_budget = budget_on
	_rig.launch_hold = launch_hold_on
	_rig.merge_lookahead = merge_look_on
''', '''	_rig = SplitRig.new()
	_rig.flash_reduced = zj_reduced   # ZJ: the game's defaults otherwise (no travel budget, the flash bundle)
''')
# arguments
rep('''		elif a == "--budget=off":''', '''		elif a == "--normal":
			zj_reduced = false
		elif a.begins_with("--split-line="):
			SplitRig.split_line_default = a.substr(13)
		elif a.begins_with("--zj-seeds="):
			zj_seeds = Array(a.substr(11).split(",")).map(func(x): return int(x))
		elif a.begins_with("--zj-ticks="):
			zj_ticks = int(a.substr(11))
		elif a == "--budget=off":''')
rep('var budget_on: bool = true ', '''var zj_reduced: bool = true
var zj_seeds: Array = [3, 10, 17]
var zj_ticks: int = 10800
var zj_vel: Array = [0.0, 0.0]
var zj_n: int = 0
const ZJ_DZ: float = 0.02    # ZJ: a zoom step over 2% in a tick
const ZJ_DDZ: float = 0.008  # ZJ: or the zoom's speed changing by 0.8% a tick in one tick (a zoom that starts or stops hard)
var budget_on: bool = true ''')
# the run: only the long matches, Orb's slot human (rig sees slot 0 as the human), and each seed again with two AIs
rep('''func _run() -> void:
''', '''func _run() -> void:
	for sd in zj_seeds:
		_real_match(int(sd), -1, 0.0, zj_ticks, 0)
		print("ZJSUM seed %d human0 %s" % [int(sd), str(stats.get("jolts " + _label, ""))])
	print("ZJ-DONE events %d" % zj_n)
	quit(0)
	return
''')
# the zoom log, inside the per-pane scan
rep('''			var dz: float = absf(log(cur.cam_z[i]) - log(prev.cam_z[i]))
''', '''			var dz: float = absf(log(cur.cam_z[i]) - log(prev.cam_z[i]))
			var zv: float = log(cur.cam_z[i]) - log(prev.cam_z[i])
			var ddz: float = absf(zv - float(zj_vel[i])) if _scan_ok[i] else 0.0
			zj_vel[i] = zv
			if (dz > ZJ_DZ or ddz > ZJ_DDZ) and _rig._ov_kind == "":
				var zc: String = "other"
				if float(_tick) / 60.0 < _scan_zip_until:
					zc = "zip"
				elif rushing or float(_tick) / 60.0 - _scan_rush_t < 0.25:
					zc = "rush/slam"
				elif sig["solo"] != _scan_sig.get("solo", "") or sig["slot"] != _scan_sig.get("slot", -1):
					zc = "shot start/end/handover"
				elif sig["mode"] != _scan_sig.get("mode", ""):
					zc = "layout %s>%s" % [_scan_sig.get("mode", ""), sig["mode"]]
				elif sig["chase"] != _scan_sig.get("chase", -1) or sig["e"] != _scan_sig.get("e", -1):
					zc = "chase/expanded changed hands"
				elif launched:
					zc = "launch in progress"
				zj_n += 1
				print("ZJ %s t=%.3f pane %d dz %.4f ddz %.4f z %.3f mode %s solo %s sep %.2f e %.2f cause %s" % [_label, float(_tick) / 60.0, i, zv, ddz, cur.cam_z[i], cur.mode, _rig.solo_kind, cur.sep, cur.e, zc])
''')
open(t + '/render/camera/tests/zj_probe.gd', 'w', encoding='utf-8', newline='\n').write(s)
print('zj probe written')
