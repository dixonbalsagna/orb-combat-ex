"""World, 2026-10-30: epoch_check reads the process counters and checks the retention.   python mk_p43.py <root>   (root: mk_p41 and mk_p42 applied)"""
import sys, re
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def check(s):
    s = re.sub(r'\b[A-Za-z_]+(\[[0-9]\])?\.epoch\.cold\b', 'WorldEpoch.coldCount', s)
    s = re.sub(r'\b[A-Za-z_]+\.epoch\.unprep\b', 'WorldEpoch.unprepCount', s)
    s = rep(s, '''func ready(cols: int, seed: int = 1) -> SimState:
	var S := SimCore.createSim()
''', '''func ready(cols: int, seed: int = 1) -> SimState:
	WorldEpoch.coldCount = 0   # the counters are the process's: each run counts from its own start
	WorldEpoch.unprepCount = 0
	var S := SimCore.createSim()
''')
    s = rep(s, '''	print("EPOCH: %d check(s) failed" % fails)
	quit()''', '''	# --- the swap leaves the world it turned away from its ring jobs and preparation for KEEP_TICKS ticks (a rollback that runs the swap again finds them); a disposed sim leaves none
	for variant in range(2):
		var Sk := ready(2400)
		WorldEpoch.ask(Sk, "keep", mid(Sk), 1, 0)
		WorldEpoch.choose(Sk, 2, 64, 2.5)
		var oldWid: int = Sk.worldId
		var g3: int = 0
		while Sk.epoch.n == 0 and g3 < 1800:
			g3 += 1
			SimCore.step(Sk)
		var jobsLeft: int = _jobsOf(oldWid)
		var kept: bool = Sk.epoch.n == 1 and Sk.worldId != oldWid and WorldEpoch._plans.has(oldWid) and jobsLeft > 0 and _retiredOf(Sk) == 1
		if variant == 0:
			ok(kept, "after the swap the world it left keeps its ring job(s) and preparation (%d job(s), the retirement noted)" % jobsLeft)
			for t in range(WorldEpoch.KEEP_TICKS - 2):
				SimCore.step(Sk)
			var stillThere: bool = WorldEpoch._plans.has(oldWid) and _jobsOf(oldWid) > 0
			for t in range(4):
				SimCore.step(Sk)
			ok(stillThere and not WorldEpoch._plans.has(oldWid) and _jobsOf(oldWid) == 0 and _retiredOf(Sk) == 0, "... and drops them %d ticks after the swap, not before" % WorldEpoch.KEEP_TICKS)
		else:
			SimCore.dispose(Sk)
			ok(kept and not WorldEpoch._plans.has(oldWid) and _jobsOf(oldWid) == 0 and _retiredOf(Sk) == 0 and not WorldEpoch._owners.has(oldWid), "a sim disposed inside the term leaves no job, preparation, retirement or owner behind")
	print("EPOCH: %d check(s) failed" % fails)
	quit()


## The retirements World still holds for sim S.
func _retiredOf(S: SimState) -> int:
	var n: int = 0
	for r in WorldEpoch._retired:
		if int(r[1]) == S.get_instance_id():
			n += 1
	return n


## The ring jobs World still holds for world `wid`.
func _jobsOf(wid: int) -> int:
	var n: int = 0
	var pre: String = "%d/" % wid
	for k in WorldEpoch._jobs.keys():
		if String(k).begins_with(pre):
			n += 1
	return n''')
    return s


rw(R, 'sim/world/tools/epoch_check.gd', check)
print('p43 applied')
