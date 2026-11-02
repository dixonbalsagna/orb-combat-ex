// Scratch (Performance and Platform, 2026-11-01): millisecond timers around every step of the per-frame view update, published with hook-perf.mjs's per-frame record as `pv` (window.__flashcap.perf.pv, ms summed over the panes).
// Wraps each plain call statement of PaneWorld.render and main.render_view in `_q = Time.get_ticks_usec()` / `PaneWorld.pv_add("pane.<call>", _q)`, and main's per-frame _sync_players, render_view, HUD advance and audio cues ("m.sync", "m.render_view", "m.hud", "m.audio").
// Apply AFTER hook-perf.mjs (it adds the "pv" key next to "rgpu"): node hook-viewtimers.mjs <scratch tree>. Scratch export only; reads nothing from the sim and writes nothing to it.
import { readFileSync, writeFileSync } from 'node:fs';
const root = process.argv[2];
const wrap = (path, fnStart, re, prefix) => {
  const L = readFileSync(path, 'utf8').split('\n');
  const i0 = L.findIndex((l) => l.startsWith(fnStart));
  if (i0 < 0) throw new Error(`anchor: ${fnStart}`);
  let i1 = L.findIndex((l, i) => i > i0 && (l.startsWith('func ') || l.startsWith('static func ')));
  if (i1 < 0) i1 = L.length;
  const out = L.slice(0, i0 + 1); out.push('\tvar _q: int = 0');
  let n = 0;
  for (const l of L.slice(i0 + 1, i1)) {
    const st = l.replace(/^\t+/, ''), ind = l.slice(0, l.length - st.length);
    const m = re.exec(st);
    if (m && !/^(if |elif |else|for |while |var |return)/.test(st) && (st.match(/\(/g) || []).length === (st.match(/\)/g) || []).length) {
      out.push(`${ind}_q = Time.get_ticks_usec()`, l, `${ind}PaneWorld.pv_add("${prefix}${m[1]}", _q)`); n++;
    } else out.push(l);
  }
  out.push(...L.slice(i1));
  writeFileSync(path, out.join('\n'));
  return n;
};
const pw = `${root}/render/core/pane_world.gd`;
let s = readFileSync(pw, 'utf8');
if (!s.includes('\nfunc render(host: SimHost,')) throw new Error('anchor: PaneWorld.render');
s = s.replace('\nfunc render(host: SimHost,', '\nstatic var pv: Dictionary = {}\n\n\nstatic func pv_add(name: String, a: int) -> void:\n\tpv[name] = float(pv.get(name, 0.0)) + float(Time.get_ticks_usec() - a) / 1000.0\n\n\nfunc render(host: SimHost,');
writeFileSync(pw, s);
const n1 = wrap(pw, 'func render(host: SimHost', /^((?:_?[a-z_]+\.)?[A-Za-z_]+)\(.*\)\s*(#.*)?$/, 'pane.');
const mg = `${root}/render/core/main.gd`;
const n2 = wrap(mg, 'func render_view(', /^((?:[a-z_]+\.)?[A-Za-z_]+)\(.*\)\s*(#.*)?$/, 'rv.');
let t = readFileSync(mg, 'utf8');
const a = '\t_sync_players()\n\trender_view(host.alpha())\n\tui_hud.advance(0.0 if host.paused else delta)\n';
if (!t.includes(a)) throw new Error('anchor: main._process view calls');
t = t.replace(a, '\tPaneWorld.pv = {}\n\tvar _q0: int = Time.get_ticks_usec()\n\t_sync_players()\n\tPaneWorld.pv_add("m.sync", _q0)\n\t_q0 = Time.get_ticks_usec()\n\trender_view(host.alpha())\n\tPaneWorld.pv_add("m.render_view", _q0)\n\t_q0 = Time.get_ticks_usec()\n\tui_hud.advance(0.0 if host.paused else delta)\n\tPaneWorld.pv_add("m.hud", _q0)\n');
const b = '\tfor c in host.pending_cues:\n\t\taudio.play(c, view_cam_x, cam_rig.zoom)\n';
if (!t.includes(b)) throw new Error('anchor: main audio cues');
t = t.replace(b, '\t_q0 = Time.get_ticks_usec()\n' + b);
const c = '\thost.pending_cues.clear()\n\tvar t2: int = Time.get_ticks_usec()\n';
if (!t.includes(c)) throw new Error('anchor: main t2');
t = t.replace(c, '\thost.pending_cues.clear()\n\tPaneWorld.pv_add("m.audio", _q0)\n\tvar t2: int = Time.get_ticks_usec()\n');
writeFileSync(mg, t);
const fc = `${root}/render/tools/flash_capture.gd`;
let u = readFileSync(fc, 'utf8');
const d = '"rgpu": RenderingServer.viewport_get_measured_render_time_gpu(rid), "tick": main.host.ticks,';
if (!u.includes(d)) throw new Error('anchor: hook-perf json (apply hook-perf.mjs first)');
u = u.replace(d, d + ' "pv": PaneWorld.pv,');
writeFileSync(fc, u);
console.log(`view timers applied: ${n1} steps in PaneWorld.render, ${n2} in main.render_view`);
