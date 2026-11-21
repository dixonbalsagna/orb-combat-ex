import sys
t=sys.argv[1]
p=t+'/sim/director/launch.gd'; s=open(p,'rb').read().decode('utf-8')
a='''static func _propFlight(S: SimState, A, D, ux: float, uy: float, F: float, props: Array, rec = null) -> int:
'''
assert s.count(a)==1
s=s.replace(a,'''static var dbgMode: int = 0
static var dbgBudget: int = 0
static var dbgTicks: int = 0
static var dbgFlights: int = 0
static var dbgHitT: int = 0
'''+a+'''	dbgFlights += 1
''')
a='''		if hit >= 0 or b.done:
			return hit
		ev.clear()
	return -1
'''
assert s.count(a)==1
s=s.replace(a,'''		dbgTicks += 1
		if hit >= 0:
			dbgHitT = t + 1
		if hit >= 0 or b.done:
			return hit
		if dbgMode >= 1 and SimWrap.sdx(b.x, float(props[props.size() - 1].x)) * (1.0 if ux >= 0.0 else -1.0) < 0.0:
			return -1
		if dbgBudget > 0 and dbgTicks >= dbgBudget:
			return -1
		ev.clear()
	return -1
''')
open(p,'wb').write(s.encode('utf-8'))
