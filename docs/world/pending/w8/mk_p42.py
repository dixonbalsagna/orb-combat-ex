"""World, 2026-10-30 (second half): who owns a world's jobs and preparation, and SimCore.dispose's flag.   python mk_p42.py <root>   (root: mk_p41 applied)
 - sim/world/epoch.gd: _owners (world id -> the sim's instance id) is noted where a preparation or a job is made; release(S) drops every world the sim owns
 - sim/core/sim.gd (a grant, Simulation's): dispose(S, keepWorld = false) releases World's data for the sim unless the state lives on
 - net/snapshot.gd (a grant, Netcode's): restore() disposes with keepWorld true (the restored state goes on playing, and a rollback that runs a swap again wants the kept jobs)"""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def epoch(s):
    s = rep(s, '''static var _retired: Array =''', '''static var _owners: Dictionary = {}   # worldId -> the instance id of the sim that made the entries (release drops what a disposed sim made, whichever world id it has by then)
static var _retired: Array =''')
    s = rep(s, '''		pl = {"wt": wt, "wtN": 0, "e": {}}
		_plans[S.worldId] = pl
''', '''		pl = {"wt": wt, "wtN": 0, "e": {}}
		_plans[S.worldId] = pl
		_owners[S.worldId] = S.get_instance_id()
''')
    s = rep(s, '''		_jobs[key] = job
	return job
''', '''		_jobs[key] = job
		_owners[S.worldId] = S.get_instance_id()
	return job
''')
    s = rep(s, '''static func _dropWorld(wid: int) -> void:
	_plans.erase(wid)
''', '''static func _dropWorld(wid: int) -> void:
	_owners.erase(wid)
	_plans.erase(wid)
''')
    s = rep(s, '''	_retired = keep
	_dropWorld(S.worldId)
''', '''	_retired = keep
	for wid in _owners.keys():
		if int(_owners[wid]) == me:
			_dropWorld(int(wid))
	_dropWorld(S.worldId)
''')
    return s


def sim(s):
    s = rep(s, '''static func dispose(S: SimState) -> void:
''', '''static func dispose(S: SimState, keepWorld: bool = false) -> void:
''')
    return rep(s, '''	S.dirS.ex = null
	S.beams.clear()
''', '''	S.dirS.ex = null
	S.beams.clear()
	if not keepWorld:
		WorldEpoch.release(S)   # World's derived data for this sim (the calm turn's ring jobs and preparations, and the worlds it left) lives in static dictionaries; a restored state keeps its own (NetSnapshot.restore)
''')


def snapshot(s):
    return rep(s, '''static func restore(S: SimState, snap: NetSnapshot, pool: Pool = null) -> void:
	SimCore.dispose(S)
''', '''static func restore(S: SimState, snap: NetSnapshot, pool: Pool = null) -> void:
	SimCore.dispose(S, true)   # the state plays on: World's kept jobs and preparation stay (a rollback that runs a swap again finds them)
''')


rw(R, 'sim/world/epoch.gd', epoch)
rw(R, 'sim/core/sim.gd', sim)
rw(R, 'net/snapshot.gd', snapshot)
print('p42 applied')
