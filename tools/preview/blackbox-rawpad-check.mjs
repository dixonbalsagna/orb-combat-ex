// The black box's raw pad recording (Controls, 2026-11-06): runs the page script in a stub page with a scripted gamepad, no browser, and checks what the saved match file would carry.
//   node tools/preview/blackbox-rawpad-check.mjs        exit 0 if every check passes
// The scripted pad holds X from frame 10 to the end (a stuck button), pulls RT, pushes the left stick and returns it, with a second, phantom pad beside it that does nothing. The record must show the stuck
// button (a bit set and never cleared), the trigger ramp, the sticks, both pads, and only the changes (not a row a frame); a clean pad's record must show a button coming back; and nothing may be
// sent anywhere. Exported for preview-selftest as rawPadProblems().
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';
import { PAGE_SCRIPT } from './blackbox.mjs';

function pad(id, buttons, axes) {
  const b = Array.from({ length: 17 }, (_, i) => ({ pressed: !!buttons[i], value: typeof buttons[i] === 'number' ? buttons[i] : (buttons[i] ? 1 : 0) }));
  return { connected: true, id, mapping: 'standard', buttons: b, axes: axes.slice() };
}

/** Plays `frames` through the page script. `script(frame)` returns the array of pads the browser would hand over on that frame. Returns { snap, file } (file: the saved match file, parsed). */
export function run(frames, script) {
  const timers = [], raf = [], blobs = [], buttons = [], store = {};
  let now = 1000, sent = 0;
  const el = () => {
    const o = { style: {}, children: [], textContent: '', value: '', appendChild(c) { this.children.push(c); }, remove() {}, addEventListener() {}, click() { o.clicked = true; } };
    return o;
  };
  const win = { addEventListener() {}, __bb_t: 0 };
  const sandbox = {
    window: win, navigator: { getGamepads: () => script(win.__bb_t) }, performance: { now: () => now },
    requestAnimationFrame: (f) => { raf.push(f); }, setInterval: (f) => { timers.push(f); return timers.length; }, setTimeout: () => 0, clearTimeout: () => {},
    localStorage: { getItem: (k) => (k in store ? store[k] : null), setItem: (k, v) => { store[k] = String(v); } },
    document: { hidden: false, body: { appendChild(c) { if (c && c.tagName) buttons.push(c); } }, createElement: (t) => { const o = el(); o.tagName = t; if (t === 'button') buttons.push(o); return o; } },
    location: { search: '' }, Blob: function (parts) { blobs.push(parts.join('')); }, URL: { createObjectURL: () => 'blob:x', revokeObjectURL() {} }, Date, JSON, Math, Object, String, Array,
    fetch: () => { sent++; }, XMLHttpRequest: function () { sent++; },
  };
  win.window = win;
  Object.assign(win, sandbox, { window: win });
  vm.createContext(win);
  vm.runInContext(PAGE_SCRIPT, win);
  for (let t = 0; t < frames; t++) {
    win.__bb_t = t; now += 16.7;
    const cbs = raf.splice(0);
    for (const f of cbs) f(now);
  }
  const snap = win.__bbf_snap();
  // the save path: queue the ended match, let the page's timer open the card, click Save
  win.__bb_q = [{ over: true, ended: true, ticks: frames, seed: 1, at: 0, frames: snap, replay: '{"format":"meridian-replay"}' }];
  for (const f of timers) f();
  const save = buttons.find((b) => b.textContent === 'Save my match file');
  if (save && save.onclick) save.onclick();
  const file = blobs.length ? JSON.parse(blobs[blobs.length - 1]) : null;
  return { snap, file, sent };
}

export function rawPadProblems() {
  const bad = [];
  const need = (c, what) => { if (!c) bad.push(what); };
  const XBOX = 'Xbox 360 Controller (XInput STANDARD GAMEPAD)';
  // 1. a stuck X, a trigger ramp, the left stick out and back, the right stick out and back, a phantom second pad
  const r = run(600, (t) => {
    const btn = {}; if (t >= 10) btn[2] = true;
    const rt = t >= 24 ? 0.8 : t >= 20 ? (t - 19) * 0.2 : 0; if (rt) btn[7] = rt;
    const ax = [t >= 30 && t <= 40 ? 0.9 : 0, 0, t >= 50 && t <= 55 ? -1 : 0, 0.03];
    return [pad('Virtual Pad', {}, [0, 0, 0, 0]), pad(XBOX, btn, ax)];
  });
  const f = r.file;
  need(f && f.rawPad, 'the saved file has rawPad');
  if (f && f.rawPad) {
    const rp = f.rawPad, bt = (rp.buttons || []).filter((x) => x[2] === 1), tr = (rp.triggers || []).filter((x) => x[2] === 1), ls = (rp.leftStick || []).filter((x) => x[2] === 1);
    need(bt.length >= 2 && bt[0][3] === 0, 'buttons: the real pad' + String.fromCharCode(39) + 's first frame is recorded (nothing down)');
    need(bt.length >= 2 && (bt[bt.length - 1][3] & 4) === 4, 'a stuck X: the pad' + String.fromCharCode(39) + 's last buttons row still has bit 2 (X) set');
    need(bt.some((x) => (x[3] & 4) === 4 && x[0] === 10), 'the X press is on frame 10');
    need(bt.length < 8, 'only changes are recorded, not a row a frame (' + bt.length + ' rows for 600 frames)');
    need(tr.length >= 3 && tr[0][3] === 0 && tr[tr.length - 1][4] === 0.8, 'triggers: a first frame and the ramp to 0.8 on RT');
    need(tr.length < 12, 'triggers: only changes (' + tr.length + ' rows)');
    need(ls.length >= 10 && ls.some((x) => x[3] >= 0.9) && ls[ls.length - 1][3] === 0, 'left stick: out to 0.9 and the frame it came back');
    need(ls.length < 30, 'left stick: only while off centre (' + ls.length + ' rows)');
    need((rp.buttons || []).filter((x) => x[2] === 0).length === 1 && (rp.leftStick || []).filter((x) => x[2] === 0).length === 0, 'the quiet phantom pad leaves one first-frame row and no stick rows');
    need(Object.keys(rp.pads || {}).length === 2 && rp.pads[0].id === 'Virtual Pad' && rp.pads[1].id === XBOX, 'pads: both pads are listed, the phantom too');
  }
  // the right stick is still the first pad with a right stick, as before (with a phantom first it reads the phantom: rawPad is the record that lists every pad)
  const one = run(100, (t) => [pad(XBOX, {}, [0, 0, t >= 50 && t <= 55 ? -1 : 0, 0])]);
  need(one.file && one.file.rawRightStick && one.file.rawRightStick.samples.length >= 6, 'rawRightStick is unchanged and still recorded');
  need(f && f.frames && f.frames.rb === undefined && f.frames.pads === undefined, 'the frames summary stays small (the arrays are not in it)');
  need(r.sent === 0, 'nothing is sent');
  // 1b. the right stick of every pad: the phantom is listed first, so rawRightStick (the first pad with a right stick) stays empty while the real pad's right stick moves; rawPad.rightStick has it, under the real pad's index
  const rr = run(120, (t) => [pad('Virtual Pad', {}, [0, 0, 0, 0]), pad(XBOX, {}, [0, 0, t >= 40 && t <= 50 ? 0.8 : 0, t >= 40 && t <= 50 ? -0.6 : 0])]);
  const rs = rr.file && rr.file.rawPad ? rr.file.rawPad.rightStick : null;
  need(Array.isArray(rs) && rs.length >= 11 && rs.every((x) => x[2] === 1), 'the right stick of the second pad is in rawPad.rightStick under pad 1 (' + (rs ? rs.length : 'none') + ' rows)');
  need(rs && rs.some((x) => x[3] === 0.8 && x[4] === -0.6) && rs[rs.length - 1][3] === 0, 'it carries the push and the frame it came back');
  need(rs && rs.length < 20, 'only while off centre (' + (rs ? rs.length : 0) + ' rows for 120 frames)');
  need(rr.file && rr.file.rawRightStick && rr.file.rawRightStick.samples.length === 0, 'the old rawRightStick, reading the phantom first, is empty: the case this record exists for');
  need(rr.file && rr.file.frames && rr.file.frames.rsa === undefined, 'the frames summary stays small');
  // 2. a clean pad: a button goes down and comes back; the record shows both
  const c = run(120, (t) => [pad(XBOX, t >= 10 && t < 20 ? { 0: true } : {}, [0, 0, 0, 0])]);
  const cb = c.file && c.file.rawPad ? c.file.rawPad.buttons : [];
  need(cb.length === 3 && cb[1][3] === 1 && cb[2][3] === 0, 'a clean pad shows A down and A back (rows: ' + JSON.stringify(cb) + ')');
  // 3. no pad at all: nothing recorded, no error, the file still saves
  const n = run(60, () => []);
  need(n.file && n.file.rawPad && n.file.rawPad.buttons.length === 0, 'no pad: an empty record, the file still saves');
  return bad;
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const p = rawPadProblems();
  if (p.length) { for (const x of p) console.log('  FAIL ' + x); console.log('blackbox-rawpad-check: ' + p.length + ' failed'); process.exit(1); }
  console.log('blackbox-rawpad-check: ok');
}
