// Scratch (Performance and Platform, 2026-11-06): the timers one level below hook-viewtimers.mjs, inside the planet view's own update: PlanetView.update, PlanetView.refresh and GroundField.update.
// Every plain call statement in those three functions is wrapped in `_q = Time.get_ticks_usec()` / `PaneWorld.pv_add("<where>.<call>", _q)` (the same per-frame dictionary hook-viewtimers.mjs publishes as `pv`, so
// apply that hook FIRST: it defines PaneWorld.pv and pv_add). A call inside a loop adds up over the loop. Scratch export only; reads the clock, changes nothing the sim sees.
//   node hook-planettimers.mjs <scratch tree>
import { readFileSync, writeFileSync } from 'node:fs';
const root = process.argv[2];
const wrap = (path, fnStart, prefix) => {
  const L = readFileSync(path, 'utf8').split('\n');
  const i0 = L.findIndex((l) => l.startsWith(fnStart));
  if (i0 < 0) throw new Error(`anchor: ${fnStart} in ${path}`);
  let i1 = L.findIndex((l, i) => i > i0 && (l.startsWith('func ') || l.startsWith('static func ') || l.startsWith('## ')));
  if (i1 < 0) i1 = L.length;
  const out = L.slice(0, i0 + 1); out.push('\tvar _q: int = 0');
  let n = 0;
  const re = /^((?:[A-Za-z_][A-Za-z_0-9]*\.)*[A-Za-z_][A-Za-z_0-9]*)\(.*\)\s*(#.*)?$/;
  for (const l of L.slice(i0 + 1, i1)) {
    const st = l.replace(/^\t+/, ''), ind = l.slice(0, l.length - st.length);
    const m = re.exec(st);
    if (m && !/^(if |elif |else|for |while |var |return|match |pass)/.test(st) && (st.match(/\(/g) || []).length === (st.match(/\)/g) || []).length && !/[\[{]\s*$/.test(st)) {
      out.push(`${ind}_q = Time.get_ticks_usec()`, l, `${ind}PaneWorld.pv_add("${prefix}${m[1]}", _q)`); n++;
    } else out.push(l);
  }
  out.push(...L.slice(i1));
  writeFileSync(path, out.join('\n'));
  return n;
};
const pvf = `${root}/render/core/planet_view.gd`, gff = `${root}/render/core/ground_field.gd`;
const a = wrap(pvf, 'func update(S: SimState, cam_x: float', 'pu.');
const b = wrap(pvf, 'func refresh(S: SimState, force: bool)', 'pr.');
const c = wrap(gff, 'func update(S: SimState, heat: PackedFloat32Array', 'gf.');
console.log(`planet timers: ${a} in PlanetView.update, ${b} in PlanetView.refresh, ${c} in GroundField.update`);
