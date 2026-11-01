# PROPOSAL (Performance and Platform, 2026-11-01), a scratch-tree patch for Simulation's sim/core/field.gd and sim/core/sim.gd. Bit-identical by construction: it only fills memos (SimField._coarse, the record-water memo,
# SimField.buildingGround) earlier than a read would, with the values that read computes in the same state.
#   python fix-ring-warm.py <tree>
# Why: a launch tick's DirLaunch.chooseLaunch spends most of its 15 to 35 ms on FIRST reads since the last rebind of those memos (a crater or a swing rebinds them):
#   - predictFlight's SimField.groundCeilAt reads ~110 to 180 coarse ground columns of the ring (600 at stride 8), ~50 us each: 8 to 22 ms;
#   - WorldBrunt.candidates reads WorldStructures.baseY (SimField.buildingGround) of every building within reach, ~0.1 ms each: 1 to 5 ms with 11 to 48 buildings near (and it grows with the buildings).
# The fix: once the memos have been quiet warmQuiet ticks, fill warmN coarse columns a tick (ring order), then warmB buildings a tick, until warm; a rebind starts it over.
# SimField.warmN = 0 and warmB = 0 turn it off (the default here, so a bench can pair on and off in one tree); a shipped version reads them from data/fight/swing.json next to ceilCols.
import sys
root = sys.argv[1]


def edit(path, pairs):
    s = open(path, encoding='utf8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (path, a[:70], s.count(a))
        s = s.replace(a, b)
    open(path, 'w', encoding='utf8').write(s)


FIELD_VARS = '''static var _nc: int = 0
static var warmN: int = 0        # coarse columns filled a tick once the memos have been quiet; 0 off
static var warmB: int = 0        # buildings' ground filled a tick once the ring is warm; 0 off
static var warmQuiet: int = 6    # ticks since the memos were last laid again before it starts
static var _wCur: int = 0
static var _wB: int = 0
static var _wSer: int = -1
static var _wQ: int = 0
'''

WARM_FUNC = '''## Fills the memos that groundCeilAt and WorldBrunt.candidates would read cold, a few a tick, after the memos have been quiet warmQuiet ticks: the coarse ground (and the record water at those columns), then the buildings' ground. Pure: the values are the ones a read computes in the same state.
static func warmStep(S: SimState) -> void:
	if (warmN <= 0 and warmB <= 0) or S.frame == null or S.depthOn:
		return
	_fresh(S)
	if _serial != _wSer:
		_wSer = _serial
		_wCur = 0
		_wB = 0
		_wQ = 0
		return
	_wQ += 1
	if _wQ < warmQuiet:
		return
	var total: int = _nc / _st
	_far += 1
	var k: int = 0
	while k < warmN and _wCur < total:
		var cw: int = _wCur * _st
		_wCur += 1
		var hc: float = _coarse(S, cw)
		if not S.fieldRecs.is_empty() and _t0[cw] != _serial:
			pointIn(S.frame, float(cw) * SimConst.COL)
			_w0[cw] = WorldField.recordWater(S, ox, oy, oz, hc)
			_t0[cw] = _serial
		k += 1
	if (_wCur >= total or warmN <= 0) and warmB > 0 and S.bDir.size() == S.buildings.size() * 3:
		k = 0
		while k < warmB and _wB < S.buildings.size():
			buildingGround(S, _wB)
			_wB += 1
			k += 1
	_far -= 1


## The highest a far read's ground,'''

edit(f'{root}/sim/core/field.gd', [
    ('static var _nc: int = 0\n', FIELD_VARS),
    ("## The highest a far read's ground,", WARM_FUNC),
])
edit(f'{root}/sim/core/sim.gd', [
    ('\t\tSimFx.shake(S, 7.0, sx, sz)\n\treturn true\n', '\t\tSimFx.shake(S, 7.0, sx, sz)\n\tSimField.warmStep(S)\n\treturn true\n'),
])
print('fix-ring-warm applied')
