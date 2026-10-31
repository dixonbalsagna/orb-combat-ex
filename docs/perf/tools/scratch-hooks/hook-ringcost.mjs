// SCRATCH HOOK (a scratch stage-timer tree only; after hook-turn2.mjs): what a TOTAL change of the ground costs once, for the "ring at any angle" question. At tick 200 of a --ringcost run it times, one after the other on the live match (the
// sim state is not changed): WorldGround.matchProps over the whole ring (x_matchall), the ground field's full rebuild (x_grebuild), PlanetView.refresh with force (every building and the crowd set again: x_refresh) and the far land's
// tables (x_farrows), all as columns of that frame.
//   node hook-ringcost.mjs <tree>
import { readFileSync, writeFileSync } from 'node:fs';

const root = process.argv[2];
if (!root) throw new Error('usage: node hook-ringcost.mjs <tree>');
const f = `${root}/render/core/main.gd`;
let m = readFileSync(f, 'utf8');
const head = 'func _perf_keys() -> void:\n';
if (m.split(head).length !== 2) throw new Error('main.gd: _perf_keys not found once');
m = m.replace(head, () => `${head}	if args.has("ringcost") and host.ticks == 200 and not _rc_done:
		_rc_done = true
		var rs: SimState = host.S
		var t0: int = Time.get_ticks_usec()
		WorldGround.matchProps(rs, 0.0, SimConst.W, PackedInt32Array())
		PerfT.t("x_matchall", t0)
		t0 = Time.get_ticks_usec()
		pane.planet.ground.rebuild(rs)
		PerfT.t("x_grebuild", t0)
		t0 = Time.get_ticks_usec()
		pane.planet.refresh(rs, true)
		PerfT.t("x_refresh", t0)
		t0 = Time.get_ticks_usec()
		GroundField.far_rows()
		PerfT.t("x_farrows", t0)
`);
m = m.replace(/\s*$/, '') + '\n\n\nvar _rc_done: bool = false\n';
writeFileSync(f, m);
console.log('ringcost hook applied to', root);
