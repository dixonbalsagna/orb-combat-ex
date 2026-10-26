"""Window 20 (World, 2026-10-26), step c: the plate pairs of _terms over the few plates that can pair.   python mk_p20c.py <root>   (after mk_p20a.py and mk_p20b.py)
 - sim/world/land.gd: _terms lists the plates within reach + the edge's cut + the wobble of the nearest (a margin of 1e-9 over: the tests below decide exactly) and runs both pair loops over that list, in the same order, so the sums add up the same terms in the same order
"""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def land(s):
    s = rep(s, '''static var _dk := PackedFloat64Array()
''', '''static var _dk := PackedFloat64Array()
static var _cand := PackedInt32Array()
''')
    s = rep(s, '''	var wob: float = 1.0e9
	var mc: float = K_R_MINCONV
	for i in range(n):
		var di: float = _dk[i]
		if di < b1 - reach:
			continue
		var gate: float = _bump(b1 - di, wg)   # 1 for the nearest plate itself
		for k in range(n):
			var dk: float = _dk[k]
			if k == i or dk > di or (dk == di and k < i):
				continue
''', '''	var wob: float = 1.0e9
	var mc: float = K_R_MINCONV
	# only a plate within reach + cut + wobble of the nearest can be either plate of a pair that passes the tests below: they are listed (a hair wider, the tests decide) in index order, and both loops run over the list
	var lo: float = b1 - reach - (cut + K_WOB_AMP) - 1.0e-9
	if _cand.size() != n:
		_cand.resize(n)
	var m: int = 0
	for i in range(n):
		if _dk[i] >= lo:
			_cand[m] = i
			m += 1
	for ii in range(m):
		var i: int = _cand[ii]
		var di: float = _dk[i]
		if di < b1 - reach:
			continue
		var gate: float = _bump(b1 - di, wg)   # 1 for the nearest plate itself
		for kk in range(m):
			var k: int = _cand[kk]
			var dk: float = _dk[k]
			if k == i or dk > di or (dk == di and k < i):
				continue
''')
    return s


rw(R, 'sim/world/land.gd', land)
print('p20 step c applied')
