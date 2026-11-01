// A no-browser check of page.html's script (Performance and Platform): runs it in a vm with a stub DOM, a fake game that publishes window.__preview, a fake frame clock and a fake XMLHttpRequest,
// and checks that the page walks load -> wait for the click -> measure -> report -> send. It proves the logic, not the browser. Node 24 built-ins only.
//   node docs/perf/oldpc/page-selftest.mjs
import { readFileSync } from 'node:fs';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';
const html = readFileSync(fileURLToPath(new URL('./page.html', import.meta.url)), 'utf8');
const code = /<script>([\s\S]*)<\/script>/.exec(html)[1];
let now = 0; const timers = []; const raf = [];
const els = {}; const el = (id) => (els[id] ||= { id, style: {}, className: '', textContent: '', innerHTML: '', value: '', addEventListener(ev, fn) { (this.handlers ||= {})[ev] = fn; }, select() {}, contentWindow: null });
const game = el('game'); game.contentWindow = { __preview: undefined };
const sent = [];
class XHR { open(m, u) { this.m = m; this.u = u; } setRequestHeader() {} send(b) { sent.push([this.m, this.u, JSON.parse(b)]); setTimeout(() => { this.status = 200; this.onload && this.onload(); }, 0); } }
const ctx = {
  document: { getElementById: el, createElement: () => ({ getContext: () => ({ getExtension: () => ({ UNMASKED_RENDERER_WEBGL: 1, UNMASKED_VENDOR_WEBGL: 2 }), getParameter: (k) => (k === 1 ? 'NVIDIA GeForce GTX 1080' : k === 2 ? 'NVIDIA' : 16384), MAX_TEXTURE_SIZE: 3 }) }), addEventListener() {}, hidden: false, createRange: () => ({ selectNodeContents() {} }), execCommand() {} },
  navigator: { userAgent: 'selftest', hardwareConcurrency: 4, deviceMemory: 8, getGamepads() {} }, screen: { width: 1920, height: 1080 }, devicePixelRatio: 1, innerWidth: 1920, innerHeight: 1000,
  location: { search: '?m=12', href: 'http://x/oldpc/?m=12', host: 'x', hostname: '10.0.0.135', reload() {} }, isSecureContext: false, crossOriginIsolated: false,
  performance: { now: () => now }, setInterval: (f, ms) => { timers.push({ f, ms, next: ms }); return timers.length; }, setTimeout: (f, ms) => { timers.push({ f, ms, next: now + ms, once: true }); return timers.length; }, clearInterval() {},
  requestAnimationFrame: (f) => { raf.push(f); }, PerformanceObserver: class { observe() {} }, XMLHttpRequest: XHR, getSelection: () => ({ removeAllRanges() {}, addRange() {} }),
  Math, Date, JSON, Float64Array, parseInt, Object, Array, String, Number, RegExp, console,
};
ctx.window = ctx; vm.createContext(ctx);
vm.runInContext(code, ctx);
if (!els.begin || !els.begin.handlers || !els.begin.handlers.click) { console.error('FAIL: the page did not offer the notes and a Start button first'); process.exit(1); }
if (game.src) { console.error('FAIL: the game was loaded before the person pressed Start'); process.exit(1); }
els.begin.handlers.click();
// drive: 60 fps frames for a game that starts ticking at 20 s (the click), a 25 ms hitch at 40 s
let tick = 0, lastTimer = 0;
for (let step = 0; step < 90000 && sent.length === 0; step++) {
  now += 5;
  for (const t of timers.slice()) { if (t.once) { if (t.next <= now) { t.next = Infinity; t.f(); } } else if (now >= t.next) { t.next += t.ms; t.f(); } }
  if (now > 3000 && !game.contentWindow.__preview) game.contentWindow.__preview = { tick: 0, meteor: false, swings: 0, planetGen: 3 };
  if (now > 20000 && game.contentWindow.__preview) { game.contentWindow.__preview.tick = Math.floor((now - 20000) / 16.67); }
  if (step % 3 === 0 && raf.length) { const fs = raf.splice(0); const t = now + (now > 40000 && now < 40040 ? 25 : 0); fs.forEach((f) => f(t)); }
}
const r = sent[0];
if (!r) { console.error('FAIL: no report was sent; message: ' + els.msg.textContent); process.exit(1); }
const rep = r[2];
console.log(rep.text);
const ok = r[0] === 'POST' && r[1] === '/oldpc/report' && rep.frames.frames > 500 && rep.frames.fps > 50 && rep.verdict.some((v) => /^WARN: this address is not "local"/.test(v)) && rep.machine.renderer.includes('1080');
console.log(ok ? '\nselftest OK' : '\nselftest FAILED'); process.exit(ok ? 0 : 1);
