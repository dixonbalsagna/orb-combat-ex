// Runs the built page under a stub DOM: every world, watched and played, keys and a stub pad. Not a real browser.
//   node research/ring-any-angle/smoke.cjs
const fs = require('fs'), vm = require('vm');
const html = fs.readFileSync('research/ring-any-angle/proto.html', 'utf8'), js = html.slice(html.indexOf('<script>') + 8, html.lastIndexOf('</script>'));
const noop = () => {}, ctx = new Proxy({}, { get: (t, k) => (k in t ? t[k] : noop), set: (t, k, v) => { t[k] = v; return true; } }), els = {}; let polys = 0;
ctx.fill = () => { polys++; };
function el(id) { if (!els[id]) els[id] = { id, children: [], style: {}, _ls: {}, getContext: () => ctx, addEventListener(k, f) { this._ls[k] = f; }, appendChild(c) { this.children.push(c); }, blur: noop, set innerHTML(v) { this.children = []; }, get innerHTML() { return ''; } }; return els[id]; }
const win = {}, raf = []; let padOn = null, n = 0;
const sb = { document: { getElementById: el, createElement: () => el('x' + n++) }, window: { addEventListener: (k, f) => { win[k] = f; } }, navigator: { getGamepads: () => [padOn] }, requestAnimationFrame: (f) => raf.push(f), Math, String, Array, Object, JSON, Error, console, Map, Set, Float64Array, Float32Array, Int32Array, Uint8Array };
vm.createContext(sb); vm.runInContext(js, sb);
let ts = 0, frames = 0; const tick = (k) => { for (let i = 0; i < k; i++) { const f = raf.shift(); ts += 16.667; f(ts); frames++; } };
const key = (code, d) => win[d ? 'keydown' : 'keyup']({ code, preventDefault: noop }), press = (c, h) => { key(c, true); tick(h); key(c, false); };
const worlds = els.rowA.children; if (worlds.length < 8) throw new Error('worlds ' + worlds.length);
for (const b of worlds) {
  b._ls.click(); tick(60);                                                     // watch
  press('KeyX', 2); press('KeyE', 2); key('ShiftLeft', true); press('KeyD', 80); key('ShiftLeft', false); press('KeyG', 2); key('ShiftLeft', true); key('KeyD', true); tick(120); key('KeyD', false); key('ShiftLeft', false);
  press('Space', 2); tick(100); press('KeyQ', 2); press('KeyA', 30); press('KeyR', 2); tick(10);
}
const B = (on) => Array.from({ length: 17 }, (_, i) => ({ pressed: on.includes(i), value: on.includes(i) ? 1 : 0 }));
padOn = { connected: true, id: 'stub', axes: [1, 0, 0, 0], buttons: B([7]) }; tick(60); padOn.buttons = B([5]); tick(5); padOn.buttons = B([0]); tick(5); padOn.buttons = B([3]); tick(5); padOn.buttons = B([2]); tick(100);
console.log('ok: ' + frames + ' frames on ' + worlds.length + ' worlds, ' + polys + ' polygons');
