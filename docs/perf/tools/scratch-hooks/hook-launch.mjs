// SCRATCH HOOK (a scratch stage-timer tree only; after hook-stages.mjs): times the launch planner's pieces, inclusive, as l_* columns: chooseLaunch, _biomeCands, predictFlight (with a call count), doLaunch, _cliff, _skimAshore, _propTargets.
//   node hook-launch.mjs <tree>
import { readFileSync, writeFileSync } from 'node:fs';

const root = process.argv[2];
if (!root) throw new Error('usage: node hook-launch.mjs <tree>');
const f = `${root}/sim/director/launch.gd`;
let s = readFileSync(f, 'utf8');
const names = { chooseLaunch: 'l_choose', _biomeCands: 'l_biomecands', predictFlight: 'l_predict', doLaunch: 'l_do', _cliff: 'l_cliff', _skimAshore: 'l_skim', _propTargets: 'l_proptargets' };
const splitTop = (p) => { const out = []; let d = 0, cur = ''; for (const ch of p) { if ('([{'.includes(ch)) d++; if (')]}'.includes(ch)) d--; if (ch === ',' && d === 0) { out.push(cur); cur = ''; } else cur += ch; } if (cur.trim()) out.push(cur); return out; };
for (const [name, key] of Object.entries(names)) {
  const re = new RegExp(`^static func ${name}\\((.*)\\)( -> ([A-Za-z0-9_.]+))?:$`, 'm');
  const m = s.match(re);
  if (!m) throw new Error(`launch.gd: no single-line definition of ${name}`);
  const params = m[1], ret = m[3];
  const call = splitTop(params).map((p) => p.trim().split(':')[0].split('=')[0].trim()).join(', ');
  const isVoid = ret === 'void';
  const line = m[0];
  const wrapper = `${line}\n\tvar _pt: int = Time.get_ticks_usec()\n\t${isVoid ? '' : 'var _r = '}${name}_i(${call})\n\tPerfT.t("${key}", _pt)\n\tPerfT.n("n_${key}")\n${isVoid ? '' : '\treturn _r\n'}\n\n`;
  s = s.replace(line, () => wrapper + line.replace(`static func ${name}(`, `static func ${name}_i(`));
}
writeFileSync(f, s);
console.log('launch hook applied to', root);
