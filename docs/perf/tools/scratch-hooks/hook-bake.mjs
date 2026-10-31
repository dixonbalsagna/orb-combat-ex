// SCRATCH HOOK (a scratch stage-timer tree only; after hook-relay.mjs): the whole-planet bake at 512 units of research.md T1 (Simulation's option A), as a cost: at tick 200 of a --ringcost run
// it reads planet 7 on a cube-sphere grid, 6 faces of 76 x 76 nodes (75 cells a face, 34,656 nodes; the distinct 33,752 of Simulation's count are those without the faces' shared edges), through
// WorldPlanet.surfAt (height and biome, the far map's own read) on the already made planet. Gauges (microseconds unless said):
//   y_bake_us        the whole read          y_bake_n          nodes read
//   y_bake_slice_us  the worst slice of 500   y_bake_slice_mean mean slice of 500 (a frame's slice, if it is cut by node count)
//   y_bake_h_us      heights only: WorldPlanet.ground over the same nodes (a LOWER bound for a height-only bake; the poles use surfAt's own ice rules)
//   y_make_us        a cold WorldPlanet.make(31): the planet make that comes before any bake
//   y_bake_bytes / y_bake_gz  the baked heights (float32) and biomes (bytes) in bytes, and as GZIP
// Not the Simulation director's own bake code (there is none in the repo): the same read, the same node count, so the same cost per node.
//   node hook-bake.mjs <tree>
import { readFileSync, writeFileSync } from 'node:fs';

const root = process.argv[2];
if (!root) throw new Error('usage: node hook-bake.mjs <tree>');
const sub = (s, a, b) => { if (s.split(a).length !== 2) throw new Error(`anchor not found once: ${JSON.stringify(a.slice(0, 70))}`); return s.replace(a, () => b); };
const f = `${root}/render/core/main.gd`;
let m = readFileSync(f, 'utf8');
m = sub(m, '\t\tvar rn: int = 512\n', `		var bp: WorldPlanet.Planet = WorldPlanet.make(7)
		var NB: int = 76
		var bh := PackedFloat32Array()
		bh.resize(6 * NB * NB)
		var bb := PackedByteArray()
		bb.resize(6 * NB * NB)
		var bdir := PackedFloat64Array()
		bdir.resize(6 * NB * NB * 3)
		var bk: int = 0
		for face in range(6):
			for j in range(NB):
				var tv: float = tan((float(j) / 75.0 - 0.5) * (PI / 2.0))
				for i in range(NB):
					var tu: float = tan((float(i) / 75.0 - 0.5) * (PI / 2.0))
					var dx: float = 1.0
					var dy: float = tu
					var dz: float = tv
					match face:
						1:
							dx = -1.0
						2:
							dx = tu
							dy = 1.0
						3:
							dx = tu
							dy = -1.0
						4:
							dx = tu
							dy = tv
							dz = 1.0
						5:
							dx = tu
							dy = tv
							dz = -1.0
					var dl: float = 1.0 / sqrt(dx * dx + dy * dy + dz * dz)
					bdir[bk * 3] = dx * dl
					bdir[bk * 3 + 1] = dy * dl
					bdir[bk * 3 + 2] = dz * dl
					bk += 1
		var tb0: int = Time.get_ticks_usec()
		var ts0: int = tb0
		var worst: int = 0
		var nsl: int = 0
		for k in range(bk):
			WorldPlanet.surfAt(bp, bdir[k * 3], bdir[k * 3 + 1], bdir[k * 3 + 2])
			bh[k] = bp.outH
			bb[k] = bp.outB
			if (k + 1) % 500 == 0:
				var tn: int = Time.get_ticks_usec()
				worst = maxi(worst, tn - ts0)
				nsl += 1
				ts0 = tn
		var tb1: int = Time.get_ticks_usec()
		PerfT.g("y_bake_us", tb1 - tb0)
		PerfT.g("y_bake_n", bk)
		PerfT.g("y_bake_slice_us", worst)
		PerfT.g("y_bake_slice_mean", float(tb1 - tb0) / float(nsl))
		var hsum: float = 0.0
		var th0: int = Time.get_ticks_usec()
		for k in range(bk):
			hsum += WorldPlanet.ground(bp, bdir[k * 3], bdir[k * 3 + 1], bdir[k * 3 + 2])
		PerfT.g("y_bake_h_us", Time.get_ticks_usec() - th0)
		PerfT.g("y_bake_hsum", hsum)
		var raw: PackedByteArray = bh.to_byte_array()
		raw.append_array(bb)
		PerfT.g("y_bake_bytes", raw.size())
		PerfT.g("y_bake_gz", raw.compress(FileAccess.COMPRESSION_GZIP).size())
		var tm0: int = Time.get_ticks_usec()
		WorldPlanet.make(31)
		PerfT.g("y_make_us", Time.get_ticks_usec() - tm0)
		var rn: int = 512
`);
writeFileSync(f, m);
console.log('bake bench applied to', root);
