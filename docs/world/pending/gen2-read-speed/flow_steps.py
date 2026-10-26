"""The stepped flow field (window 20): WorldRivers.Flow made a few cells at a time. Shared by the makers."""
NEW_FLOW = '''	var _G: WorldClimate.Grid
	var _ph: int = 0        # the phase: 0 setup (a row a time), 1 the flood's seeds, 2 the flood, 3 the drainage down the steepest way, 4 the runoff added up, 5 the count, 6 made
	var _pos: int = 0
	var done: bool = false
	var spent: int = 0      # ticks of work done so far (the job's budget is told in these: PlanetJob.FLOW_CELLS to a unit)
	var _cs := PackedFloat64Array()
	var _sn := PackedFloat64Array()
	var _seen := PackedByteArray()
	var _heapP := PackedFloat64Array()
	var _heapI := PackedInt32Array()
	var _fill := PackedFloat64Array()
	var _out := PackedInt32Array()

	## `run` true (the default): the whole field now. False: only the start; `step` does the rest a few cells at a time (the planet job's).
	func _init(G: WorldClimate.Grid, run: bool = true) -> void:
		_G = G
		w = G.w
		h = G.h
		var n: int = w * h
		recv.resize(n)
		recv.fill(-1)
		flow.resize(n)
		flow.fill(0.0)
		px.resize(n)
		py.resize(n)
		pz.resize(n)
		_cs.resize(w)
		_sn.resize(w)
		for k in range(w):
			var th: float = SimMathx.TAU * (float(k) + 0.5) / float(w)
			_cs[k] = SimDetMath.cos(th)
			_sn[k] = SimDetMath.sin(th)
		if run:
			step(1 << 40)

	## Does up to `cells` ticks of the work (a tick is about 0.4 us: a cell of the setup, a seed or the runoff one, a cell drained two, a cell popped from the flood fifteen; a phase may run a little over); true when the field is made. The same loops as a
	## whole make, resumed, so the same arrays.
	func step(cells: int) -> bool:
		if done:
			return true
		var G: WorldClimate.Grid = _G
		var n: int = w * h
		var left: int = cells
		while left > 0 and _ph < 6:
			if _ph == 0:
				var d: Dictionary = WorldClimate.data()
				var mp: Dictionary = d.moist
				var tp: Dictionary = d.temp
				while _pos < h and left > 0:
					var r: int = _pos
					var y: float = -1.0 + (float(r) + 0.5) * 2.0 / float(h)
					var c: float = sqrt(maxf(0.0, 1.0 - y * y))
					var band: float = float(mp.wBand) * WorldClimate.bandWet(y) + float(mp.bias)
					var tEq: float = float(tp.eq) * SimDetMath.pow(c, float(tp.pow))
					for k in range(w):
						var i: int = r * w + k
						px[i] = c * _cs[k]
						py[i] = y
						pz[i] = c * _sn[k]
						var ht: float = G.ht[i]
						if ht < 0.0:
							continue
						landCells += 1
						var T: float = tEq - float(tp.lapse) * ht / float(tp.hScale)
						if T < WorldRivers.K_FROZEN:
							continue
						var M: float = clampf(band + float(mp.wAdv) * G.adv[i], 0.0, 1.0)
						flow[i] = maxf(0.0, M - WorldRivers.K_DRY) * WorldRivers.K_GAIN
					_pos += 1
					left -= w
					spent += w
				if _pos >= h:
					_ph = 1
					_pos = 0
					_seen.resize(n)
			elif _ph == 1:
				# the priority flood from the sea inward: the lowest unvisited cell next (ties to the lower index), each neighbour reached takes it as its receiver
				while _pos < n and left > 0:
					if G.ht[_pos] < 0.0:
						_seen[_pos] = 1
						_push(_heapP, _heapI, G.ht[_pos], _pos)
					_pos += 1
					left -= 1
					spent += 1
				if _pos >= n:
					_fill.resize(n)
					for i in range(n):
						_fill[i] = G.ht[i]
					_ph = 2
					_pos = 0
			elif _ph == 2:
				while _heapI.size() > 0 and left > 0:
					var cur: int = _heapI[0]
					_pop(_heapP, _heapI)
					_out.append(cur)
					var r0: int = cur / w
					var k0: int = cur - r0 * w
					for dr in range(-1, 2):
						var rr: int = r0 + dr
						if rr < 0 or rr >= h:
							continue
						for dk in range(-1, 2):
							if dr == 0 and dk == 0:
								continue
							var nb: int = rr * w + posmod(k0 + dk, w)
							if _seen[nb] != 0:
								continue
							_seen[nb] = 1
							recv[nb] = cur
							_fill[nb] = maxf(G.ht[nb], _fill[cur])
							_push(_heapP, _heapI, _fill[nb], nb)
					left -= 15
					spent += 15
				if _heapI.size() == 0:
					order = _out
					_ph = 3
					_pos = 0
			elif _ph == 3:
				# a cell the flood did not raise (not in a filled pit) drains down its steepest way: the lowest neighbour by slope over the cell's own arc (a lat-lon cell is wide at the equator and narrow toward the
				# poles), so the rivers follow the land and not the flood's front. A strictly lower filled height is acyclic, and the flood's pop order (nondecreasing in filled height) still has every receiver first.
				var dlon: float = SimMathx.TAU / float(w)
				while _pos < n and left > 0:
					var i: int = _pos
					_pos += 1
					left -= 2
					spent += 2
					if G.ht[i] < 0.0 or _fill[i] > G.ht[i] + 1.0e-9:
						continue
					var r1: int = i / w
					var k1: int = i - r1 * w
					var cl: float = sqrt(maxf(1.0e-9, 1.0 - py[i] * py[i]))
					var bs: float = 0.0
					var bn: int = -1
					for dr in range(-1, 2):
						var rr: int = r1 + dr
						if rr < 0 or rr >= h:
							continue
						for dk in range(-1, 2):
							if dr == 0 and dk == 0:
								continue
							var nb: int = rr * w + posmod(k1 + dk, w)
							if _fill[nb] >= _fill[i]:
								continue
							var ax: float = dlon * cl * float(dk)
							var ay: float = (2.0 / float(h)) / cl * float(dr)
							var sl: float = (_fill[i] - _fill[nb]) / sqrt(ax * ax + ay * ay)
							if sl > bs or (sl == bs and bn >= 0 and nb < bn):
								bs = sl
								bn = nb
					if bn >= 0:
						recv[i] = bn
				if _pos >= n:
					_ph = 4
					_pos = _out.size() - 1
			elif _ph == 4:
				# runoff added up downstream: a cell is reached after its receiver, so the reverse order visits every cell before its receiver
				while _pos >= 0 and left > 0:
					var i2: int = _out[_pos]
					var rc: int = recv[i2]
					if rc >= 0 and G.ht[i2] >= 0.0:
						flow[rc] += flow[i2]
					_pos -= 1
					left -= 1
					spent += 1
				if _pos < 0:
					_ph = 5
			else:
				for i in range(n):
					if G.ht[i] >= 0.0 and flow[i] >= WorldRivers.K_RIVER:
						rivers += 1
				_ph = 6
				done = true
				_seen = PackedByteArray()
				_heapP = PackedFloat64Array()
				_heapI = PackedInt32Array()
				_fill = PackedFloat64Array()
				_out = PackedInt32Array()
				_G = null
		return done
'''


def rivers(s):
    a = s.index("\tfunc _init(G: WorldClimate.Grid) -> void:\n\t\tw = G.w")
    b = s.index("\n\tstatic func _less(")
    return s[:a] + NEW_FLOW + s[b:]




_rv = rivers
def rivers(s):
    s = _rv(s)
    a = "const FLOW_COST: int = 5000   # a planet job's budget units the flow field costs (about 100 ms: a unit is about 20 microseconds)"
    assert s.count(a) == 1
    return s.replace(a, "const FLOW_COST: int = 7400   # a planet job's budget units the flow field costs (about 147 ms made in steps: a unit is about 20 microseconds)")
