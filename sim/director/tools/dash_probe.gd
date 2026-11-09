extends SceneTree
## Encounter's measure of LT's high speed against distance (the EP's overnight brief item 1; Game Design overnight-2026-11-08.md (c)):
##   godot --headless --path . --script res://sim/director/tools/dash_probe.gd [-- --power=1 --level=0|max]
## LT pressed and held on tick 0 with the stick toward the rival, as the layout reads it (the dodge edge, the lunge's dash for lungeTicks,
## the sprint from holdStart), the rival standing still (no computer). For each start gap: the speed on tick 1, the peak and its tick,
## and the ticks to striking distance (1.5 bh between them) and to the first exchange. Prints one row a gap; no verdict (a measure).

const GAPS: Array = [1000.0, 3000.0, 6000.0, 12000.0]
const STRIKE: float = 112.5   # 1.5 bh: striking distance (Game Design's arrival band)


func _init() -> void:
	var power: bool = true
	var lvl: String = "0"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--power="):
			power = a.substr(8) == "1"
		elif a.begins_with("--level="):
			lvl = a.substr(8)
	print("dash probe: power %s, level %s" % [str(power), lvl])
	for gap in GAPS:
		_row(gap, power, lvl)
	quit(0)


func _row(gap: float, power: bool, lvl: String) -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"intro": false, "power": power, "travel": 1.5, "flatOut": 5000.0, "planet": 7})   # build 2's page setup
	var A = S.fighters[0]
	var D = S.fighters[1]
	for f in S.fighters:
		f.ai = null
		f.hp = 100000.0
		f.ki = 100.0
	if lvl == "max":
		for f in S.fighters:
			f.tier = 4.0
			if "power" in f:
				f.power = 100.0
	for _k in range(3):
		SimCore.step(S, [SimIntent.new(), SimIntent.new()])
	A.y = WorldTerrain.groundY(S, A.x, A.z) + 600.0
	D.x = SimWrap.wrap(A.x + gap)
	D.y = A.y
	A.vx = 0.0
	A.vy = 0.0
	D.vx = 0.0
	D.vy = 0.0
	var lunge: int = SimInputData.ti(["dodge", "lungeTicks"], 12)
	var hold: int = SimInputData.ti(["tapHold", "holdStart"], 12)
	var v1: float = -1.0
	var peak: float = 0.0
	var peakT: int = 0
	var strikeT: int = -1
	var exT: int = -1
	var at12: float = 0.0
	var trace: PackedStringArray = []
	for t in range(0, 600):
		var i := SimIntent.new()
		var dir: float = SimMathx.jsign(SimWrap.sdx(A.x, D.x))
		i.mx = dir
		i.dodge = t == 0
		i.sprint = t >= hold
		i.dash = i.sprint or t <= lunge
		SimCore.step(S, [i, SimIntent.new()])
		var sp: float = absf(A.vx)
		var dist: float = absf(SimWrap.sdx(A.x, D.x))
		if t == 1:
			v1 = sp
		if t == 12:
			at12 = sp
		if sp > peak:
			peak = sp
			peakT = t
		if t % 6 == 0 and t <= 90:
			trace.append("%d:%.0f@%.0f" % [t, sp, dist])
		if strikeT < 0 and dist <= STRIKE:
			strikeT = t
		if exT < 0 and S.dirS.ex != null:
			exT = t
		if strikeT >= 0 and exT >= 0:
			break
		S.out.fx.clear()
		S.out.feed.clear()
	print("  gap %5.0f: tick 1 %4.0f/s, tick 12 %4.0f/s, peak %5.0f/s at tick %3d, striking distance at tick %3d (%.2f s), first exchange at tick %3d" % [gap, v1, at12, peak, peakT, strikeT, float(strikeT) / 60.0, exT])
	print("    speed@dist every 6 ticks: " + " ".join(trace))
	SimCore.dispose(S)
