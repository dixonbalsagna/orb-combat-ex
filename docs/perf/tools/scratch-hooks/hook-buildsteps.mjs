// SCRATCH HOOK (a scratch stage-timer tree only; after hook-stages.mjs): where the calm turn's render rebuild spends its time. Times each step of PlanetView.build_steps
// (b_step0 free the old copies and re-table the far rows, b_step3 share: b_ground, b_makeprops, b_cover, b_step4 setup, b_step5 make the new copies' nodes, b_step6 force refresh) as columns of the swap frame
// (d_arenaturn > 0 in hook-turn2.mjs's runs). Also gives hook-ringcost.mjs's probe windows of the props query round the first fighter (x_match512 to x_match4096 and their prop counts).
//   node hook-buildsteps.mjs <tree>
import { readFileSync, writeFileSync } from 'node:fs';

const root = process.argv[2];
if (!root) throw new Error('usage: node hook-buildsteps.mjs <tree>');
const sub = (s, a, b) => { if (s.split(a).length !== 2) throw new Error(`anchor not found once: ${JSON.stringify(a.slice(0, 70))}`); return s.replace(a, () => b); };

const f = `${root}/render/core/planet_view.gd`;
let s = readFileSync(f, 'utf8');
s = sub(s, '\tfor st in build_steps(S):\n\t\twhile not st.call():\n\t\t\tpass\n',
  '\tvar _bi: int = 0\n\tfor st in build_steps(S):\n\t\tvar _bt: int = Time.get_ticks_usec()\n\t\twhile not st.call():\n\t\t\tpass\n\t\tPerfT.t("b_step%d" % _bi, _bt)\n\t\t_bi += 1\n');
s = sub(s, '\t\tground.rebuild(S)\n\t\t_make_props(S)\n',
  '\t\tvar _bg: int = Time.get_ticks_usec()\n\t\tground.rebuild(S)\n\t\tPerfT.t("b_ground", _bg)\n\t\t_bg = Time.get_ticks_usec()\n\t\t_make_props(S)\n\t\tPerfT.t("b_makeprops", _bg)\n');
s = sub(s, '\t\tif cover_on:\n\t\t\tcover.build(S, ground,', '\t\tvar _bc: int = Time.get_ticks_usec()\n\t\tif cover_on:\n\t\t\tcover.build(S, ground,');
s = sub(s, '\t\t\tcover = CoverView.new()\n\telse:\n\t\tcover = source.cover', '\t\t\tcover = CoverView.new()\n\t\tPerfT.t("b_cover", _bc)\n\telse:\n\t\tcover = source.cover');
writeFileSync(f, s);

// the props query on windows round the first fighter, before the whole-ring call (hook-ringcost.mjs must have been applied)
const g = `${root}/render/core/main.gd`;
let m = readFileSync(g, 'utf8');
m = sub(m, '\t\tvar t0: int = Time.get_ticks_usec()\n\t\tWorldGround.matchProps(rs, 0.0, SimConst.W, PackedInt32Array())\n',
  `		var wx: float = rs.fighters[0].x
		for wn in [512.0, 1024.0, 2048.0, 4096.0]:
			var tw0: int = Time.get_ticks_usec()
			var nprops: int = WorldGround.matchProps(rs, wx - wn * 0.5, wx + wn * 0.5, PackedInt32Array()).size()
			PerfT.t("x_match%d" % int(wn), tw0)
			PerfT.g("n_match%d" % int(wn), nprops)
		var t0: int = Time.get_ticks_usec()
		WorldGround.matchProps(rs, 0.0, SimConst.W, PackedInt32Array())
`);
writeFileSync(g, m);
console.log('build-step timers and props windows applied to', root);
