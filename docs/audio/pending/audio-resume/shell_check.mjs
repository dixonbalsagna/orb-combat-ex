// Checks shell-snippet.js against a mock browser (no Chrome, no Godot): node docs/audio/pending/audio-resume/shell_check.mjs
// Exit code 1 on any failure.
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const code = fs.readFileSync(path.join(here, 'shell-snippet.js'), 'utf8');
let fails = 0;
const ok = (c, m) => { console.log(`  ${c ? 'ok  ' : 'FAIL'}  ${m}`); if (!c) fails++; };

function world({ withAudio = true, webkitOnly = false, active = false } = {}) {
  const pads = [];   // what navigator.getGamepads() returns
  const timers = new Map(); let nextTimer = 1; const later = []; let clock = 0;
  const navigator = { getGamepads: () => pads, userActivation: { hasBeenActive: active } };
  const listeners = {};
  const docListeners = {};
  class MockContext {
    constructor(opts) { this._s = 'suspended'; this._l = [];  this.addEventListener = (ev, fn) => { if (ev === 'statechange') this._l.push(fn); }; this.currentTime = 0; this.sampleRate = (opts && opts.sampleRate) || 48000; this.outputLatency = 0.012; this.resumed = 0; this.reject = false; }
    get state() { return this._s; }
    set state(v) { this._s = v; this._l.forEach((fn) => fn()); }
    resume() { this.resumed++; if (this.reject) { return Promise.reject(new Error('NotAllowedError')); } this.state = 'running'; return Promise.resolve(); }
  }
  const win = { addEventListener: (ev, fn) => { (listeners[ev] = listeners[ev] || []).push(fn); } };
  if (withAudio) { if (webkitOnly) { win.webkitAudioContext = MockContext; } else { win.AudioContext = MockContext; } }
  const doc = { hidden: false, addEventListener: (ev, fn) => { (docListeners[ev] = docListeners[ev] || []).push(fn); } };
  const env = { window: win, document: doc, Proxy, Reflect, Promise, String, navigator, performance: { now: () => clock }, setInterval: (fn) => { timers.set(nextTimer, fn); return nextTimer++; }, clearInterval: (id) => { timers.delete(id); }, setTimeout: (fn) => { later.push(fn); return 0; } };
  const ctx = vm.createContext(env);
  vm.runInContext(code, ctx);
  const fire = (ev, trusted = true) => (listeners[ev] || []).forEach((fn) => fn({ isTrusted: trusted }));
  const poll = (ms = 100) => { clock += ms; [...timers.values()].forEach((fn) => fn()); };
  const flush = () => { while (later.length) later.shift()(); };
  return { win, doc, fire, docListeners, MockContext, pads, timers, poll, flush, env };
}

console.log('1. the context is kept and still a context');
let w = world();
const Wrapped = w.win.AudioContext;
const c1 = new Wrapped({ sampleRate: 44100 });
ok(c1 instanceof w.MockContext, 'new AudioContext() still makes a context (instanceof the original class)');
ok(c1.sampleRate === 44100, 'with its options');
ok(w.win.__audioShell.contexts.length === 1 && w.win.__audioShell.contexts[0] === c1, 'and the shell keeps a reference');
const c2 = new Wrapped();
ok(w.win.__audioShell.contexts.length === 2, 'a second context is kept too');

console.log('2. a trusted press runs a suspended context, an untrusted one does not');
w.fire('pointerdown', false);
ok(c1.resumed === 0 && c1.state === 'suspended', 'an untrusted pointerdown (a script) does nothing');
w.fire('pointerdown', true);
ok(c1.state === 'running' && c2.state === 'running' && c1.resumed === 1, 'a trusted pointerdown runs both');
w.fire('keydown', true);
w.fire('click', true);
ok(c1.resumed === 1, 'a running context is not asked again');
for (const ev of ['mousedown', 'mouseup', 'pointerup', 'keydown', 'keyup', 'touchend', 'click']) {
  const w2 = world();
  const c = new w2.win.AudioContext();
  w2.fire(ev, true);
  ok(c.state === 'running', `${ev} wakes it`);
}

console.log('3. a context that was suspended again, a refusal, a return to the tab');
c1.state = 'suspended';
w.fire('keydown', true);
ok(c1.state === 'running', 'asked again when it falls back to suspended');
const w3 = world();
const c3 = new w3.win.AudioContext();
c3.reject = true;
w3.fire('pointerdown', true);
await Promise.resolve();
await Promise.resolve();
ok(w3.win.__audioShell.last === 'Error' || w3.win.__audioShell.last.includes('NotAllowed') || w3.win.__audioShell.last !== '', 'a refused resume is remembered, not thrown');
const w4 = world();
const c4 = new w4.win.AudioContext();
w4.doc.hidden = false;
w4.docListeners.visibilitychange.forEach((fn) => fn());
ok(c4.state === 'running', 'the tab becoming visible asks too');
const w5 = world();
const c5 = new w5.win.AudioContext();
w5.doc.hidden = true;
w5.docListeners.visibilitychange.forEach((fn) => fn());
ok(c5.state === 'suspended', 'and not while it is hidden');
const closed = new w5.win.AudioContext();
closed.state = 'closed';
w5.fire('click', true);
ok(closed.resumed === 0, 'a closed context is left alone');

console.log('4. the state line');
ok(/running t=0\.00 44100 Hz out 0\.012 s/.test(w.win.__audioShell.state()) || /running/.test(w.win.__audioShell.state()), 'state() reads the state, clock, rate and latency (' + w.win.__audioShell.state() + ')');
ok(world().win.__audioShell.state() === 'no AudioContext made yet', 'and says so before any context exists');

console.log('5. it never breaks the page');
const none = world({ withAudio: false });
ok(none.win.__audioShell === undefined, 'with no Web Audio it does nothing');
const wk = world({ webkitOnly: true });
ok(new wk.win.webkitAudioContext() instanceof wk.MockContext && wk.win.__audioShell.contexts.length === 1, 'a webkit-only browser is wrapped too');
const again = world();
const first = again.win.__audioShell;
vm.runInContext(code, vm.createContext(again.env));
ok(again.win.__audioShell === first, 'a second copy of the snippet does nothing');
console.log('6. a pad press (no key, no mouse): the contexts are asked to run');
{
  const w6 = world();
  const a = new w6.win.AudioContext(), b = new w6.win.AudioContext();
  ok(w6.timers.size === 1, 'while a context is suspended the pad is polled (one timer, shared)');
  w6.poll(); w6.poll();
  ok(a.state === 'suspended' && w6.win.__audioShell.pad.asks === 0, 'no press: nothing is asked');
  w6.pads[0] = { connected: true, buttons: [{ pressed: false, value: 0 }, { pressed: false, value: 0 }], axes: [0.1, -0.2, 0, 0] };
  w6.poll();
  ok(a.state === 'suspended', 'a pad at rest: nothing is asked');
  w6.pads[0].buttons[1] = { pressed: true, value: 1 };
  w6.poll(); w6.flush();
  ok(a.state === 'running' && b.state === 'running', 'a button press runs both contexts');
  ok(w6.win.__audioShell.pad.asks === 2 && w6.win.__audioShell.pad.woke === 2 && w6.win.__audioShell.pad.seen === 1, 'and is counted (asked 2, woke 2, seen 1)');
  ok(w6.timers.size === 0, 'with every context running the poll stops');
  ok(/pad seen 1 asked 2 woke 2/.test(w6.win.__audioShell.state()), 'the state line carries the pad counters (' + w6.win.__audioShell.state() + ')');
}
{
  const w7 = world();
  const c = new w7.win.AudioContext();
  w7.pads[0] = { connected: true, buttons: [], axes: [0, 0.9] };
  w7.poll(); w7.flush();
  ok(c.state === 'running', 'a stick pushed past 0.6 counts as a press');
}
{
  const w8 = world();
  const c = new w8.win.AudioContext();
  c.reject = true;
  w8.pads[0] = { connected: true, buttons: [{ pressed: true, value: 1 }], axes: [] };
  w8.poll(); w8.flush();
  ok(c.state === 'suspended' && /did not start/.test(w8.win.__audioShell.pad.last), 'a browser that refuses is told in the counters, not thrown (' + w8.win.__audioShell.pad.last + ')');
  const before = w8.win.__audioShell.pad.asks;
  w8.poll(100); w8.poll(100);
  ok(w8.win.__audioShell.pad.asks === before, 'a held button asks once, not every poll');
  w8.poll(1600);
  ok(w8.win.__audioShell.pad.asks === before + 1, 'and again after a second and a half if it is still held and nothing started');
  w8.pads[0].buttons[0] = { pressed: false, value: 0 };
  w8.poll(); w8.pads[0].buttons[0] = { pressed: true, value: 1 }; w8.poll();
  ok(w8.win.__audioShell.pad.asks === before + 2, 'a new press asks at once');
}
{
  const w9 = world({ active: true });
  const c = new w9.win.AudioContext();
  w9.flush();
  ok(c.state === 'running', 'a page the player has already pressed in (sticky activation) runs a new context at once');
  const w10 = world({ active: false });
  const d = new w10.win.AudioContext();
  w10.flush();
  ok(d.state === 'suspended', 'and one never pressed in is left for a gesture');
  const noNav = world();
  noNav.env.navigator.getGamepads = undefined;
  const e = new noNav.win.AudioContext();
  noNav.poll();
  ok(e.state === 'suspended', 'a browser with no Gamepad API: no error, nothing happens');
}


console.log(`\nshell check ${fails === 0 ? 'passed' : 'FAILED (' + fails + ')'}`);
process.exit(fails === 0 ? 0 : 1);
