// SCRATCH HOOK (a scratch stage-timer tree only; after hook-ringcost.mjs): two measures for the turntable question (docs/world/ring-any-angle/performance.md, section 5).
//   1. At tick 200 of a --ringcost run: what re-laying the sim's strip from a resident 2D field costs per tick, in GDScript on float64: a 512 x 512 field, the strip's columns sampled
//      along a line that turns 0.5 degrees a tick, a hand bilinear each (y_relay256_us, y_relay512_us: microseconds a tick, best of 5 batches of 60 ticks; y_relay256x21_us: 21 depth
//      rows a column, the ground field's data rows if each were its own sample).
//   2. A gauge of the primitives drawn in the frame (prims), next to the draws gauge, for the vertex count of what the camera actually sees.
//   node hook-relay.mjs <tree>
import { readFileSync, writeFileSync } from 'node:fs';

const root = process.argv[2];
if (!root) throw new Error('usage: node hook-relay.mjs <tree>');
const sub = (s, a, b) => { if (s.split(a).length !== 2) throw new Error(`anchor not found once: ${JSON.stringify(a.slice(0, 70))}`); return s.replace(a, () => b); };
const f = `${root}/render/core/main.gd`;
let m = readFileSync(f, 'utf8');
m = sub(m, '\tPerfT.g("draws", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))\n',
  '\tPerfT.g("draws", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))\n\tPerfT.g("prims", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))\n');
m = sub(m, '\t\tGroundField.far_rows()\n\t\tPerfT.t("x_farrows", t0)\n', `		GroundField.far_rows()
		PerfT.t("x_farrows", t0)
		var rn: int = 512
		var fld: PackedFloat64Array = PackedFloat64Array()
		fld.resize(rn * rn)
		for fi in range(rn * rn):
			fld[fi] = sin(float(fi % rn) * 0.05) * 40.0 + cos(float(fi / rn) * 0.031) * 25.0 + float((fi * 7919) % 101) * 0.05
		for cfg in [[256, 1], [512, 1], [256, 21]]:
			var rc: int = cfg[0]
			var rows: int = cfg[1]
			var outh: PackedFloat64Array = PackedFloat64Array()
			outh.resize(rc * rows)
			var best: float = 1.0e30
			for batch in range(5):
				var tb: int = Time.get_ticks_usec()
				for tk in range(60):
					var ang: float = float(tk) * 0.0087
					var ca: float = cos(ang)
					var sa: float = sin(ang)
					var px0: float = 256.0 - ca * float(rc) * 0.5
					var py0: float = 256.0 - sa * float(rc) * 0.5
					for c in range(rc):
						for r in range(rows):
							var fx: float = px0 + ca * float(c) - sa * float(r) * 0.5
							var fy: float = py0 + sa * float(c) + ca * float(r) * 0.5
							var ix: int = clampi(int(fx), 0, rn - 2)
							var iy: int = clampi(int(fy), 0, rn - 2)
							var tx: float = fx - float(ix)
							var ty: float = fy - float(iy)
							var b0: int = iy * rn + ix
							var h0: float = fld[b0] + (fld[b0 + 1] - fld[b0]) * tx
							var h1: float = fld[b0 + rn] + (fld[b0 + rn + 1] - fld[b0 + rn]) * tx
							outh[c * rows + r] = h0 + (h1 - h0) * ty
				best = minf(best, float(Time.get_ticks_usec() - tb) / 60.0)
			PerfT.g("y_relay%d%s_us" % [rc, "" if rows == 1 else "x%d" % rows], best)
`);
writeFileSync(f, m);
console.log('relay bench and prims gauge applied to', root);
