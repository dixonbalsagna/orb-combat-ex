// SCRATCH HOOK (scratch export only): times the two big parts of PlanetView.build (the ground field's rebuild and the props: buildings, trees, crowd) every time a pane builds its own
// copy, into window.__bprof as [ground_us, props_us] per call; the last call before the end of a turn scene is the turn's. Apply after hook-turn.mjs.
import { readFileSync, writeFileSync } from 'node:fs';
const p = process.argv[2] + '/render/core/planet_view.gd';
let s = readFileSync(p, 'utf8');
const a = '\tif source == null:\n\t\tground.rebuild(S)\n\t\t_make_props(S)\n';
if (!s.includes(a)) throw new Error('anchor build');
s = s.replace(a, '\tif source == null:\n\t\tvar _tg0: int = Time.get_ticks_usec()\n\t\tground.rebuild(S)\n\t\tvar _tg1: int = Time.get_ticks_usec()\n\t\t_make_props(S)\n\t\tvar _tg2: int = Time.get_ticks_usec()\n\t\tJavaScriptBridge.eval("(window.__bprof = window.__bprof || []).push([%d, %d]);" % [_tg1 - _tg0, _tg2 - _tg1], true)\n');
writeFileSync(p, s); console.log('turnprof hook applied');

// also: main.gd, the whole of _arena_turn and every render_view call over 8 ms, into window.__tprof as [kind, tick, us]
const mp = process.argv[2] + '/render/core/main.gd';
let m = readFileSync(mp, 'utf8');
const b1 = 'func _arena_turn(e) -> void:\n\tfor p in all_panes():\n\t\tp.planet.build(host.S)\n';
if (!m.includes(b1)) throw new Error('anchor _arena_turn');
m = m.replace(b1, 'func _arena_turn(e) -> void:\n\tvar _ta0: int = Time.get_ticks_usec()\n\tvar _ta1: int = 0\n\tfor p in all_panes():\n\t\tp.planet.build(host.S)\n\t_ta1 = Time.get_ticks_usec()\n');
const b2 = '\thost.sky.towns_again(host.S)\n';
if (!m.includes(b2)) throw new Error('anchor towns_again');
m = m.replace(b2, b2 + '\tJavaScriptBridge.eval("(window.__tprof = window.__tprof || []).push([\'turn\', %d, %d, %d]);" % [host.ticks, _ta1 - _ta0, Time.get_ticks_usec() - _ta1], true)\n');
const b3 = '\trender_view(host.alpha())\n\tui_hud.advance(0.0 if host.paused else delta)\n';
if (!m.includes(b3)) throw new Error('anchor render_view');
m = m.replace(b3, '\tvar _tr0: int = Time.get_ticks_usec()\n\trender_view(host.alpha())\n\tvar _tr1: int = Time.get_ticks_usec() - _tr0\n\tif _tr1 > 8000:\n\t\tJavaScriptBridge.eval("(window.__tprof = window.__tprof || []).push([\'view\', %d, %d]);" % [host.ticks, _tr1], true)\n\tui_hud.advance(0.0 if host.paused else delta)\n');
writeFileSync(mp, m); console.log('turnprof main.gd applied');

// and inside PlanetView.build: the freeing of the old copies, the data between the props and the copies (stub textures, lanes, crowd materials), the new copies' nodes, and refresh(S, true),
// as window.__bprof2 = [free_us, middle_us, copies_us, refresh_us] per call of a pane that builds its own copy
let q = readFileSync(p, 'utf8');
const c1 = 'func build(S: SimState) -> void:\n\tfor c in _copies:\n\t\tremove_child(c)\n\t\tc.free()\n\t_copies.clear()\n';
if (!q.includes(c1)) throw new Error('anchor build head');
q = q.replace(c1, 'func build(S: SimState) -> void:\n\tvar _tf0: int = Time.get_ticks_usec()\n\tfor c in _copies:\n\t\tremove_child(c)\n\t\tc.free()\n\t_copies.clear()\n\tvar _tf1: int = Time.get_ticks_usec() - _tf0\n');
const c2 = '\t_stub.resize(S.buildings.size())\n\t_stub.fill(0.0)\n';
if (!q.includes(c2)) throw new Error('anchor stub');
q = q.replace(c2, '\tvar _tm0: int = Time.get_ticks_usec()\n' + c2);
const c3 = '\tvar nk: int = copies_each_side()\n\tvar np: int = prop_copies_each_side()\n';
if (!q.includes(c3)) throw new Error('anchor copies');
q = q.replace(c3, '\tvar _tm1: int = Time.get_ticks_usec() - _tm0\n\tvar _tc0: int = Time.get_ticks_usec()\n' + c3);
const c4 = '\tif source == null:\n\t\trefresh(S, true)\n';
if (!q.includes(c4)) throw new Error('anchor refresh');
q = q.replace(c4, '\tvar _tc1: int = Time.get_ticks_usec() - _tc0\n\tvar _tr0: int = Time.get_ticks_usec()\n\tif source == null:\n\t\trefresh(S, true)\n\tJavaScriptBridge.eval("(window.__bprof2 = window.__bprof2 || []).push([%d, %d, %d, %d, %d]);" % [_tf1, _tm1, _tc1, Time.get_ticks_usec() - _tr0, copies_each_side()], true)\n');
writeFileSync(p, q); console.log('turnprof planet_view parts applied');
