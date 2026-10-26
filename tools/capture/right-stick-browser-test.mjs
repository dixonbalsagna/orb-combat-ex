// Browser test of the right-stick capture page (tools/capture/right-stick.html) in headless Chrome, through the guarded launcher (tools/machine/capture.mjs, `eval`; your session tag in the profile folder).
// A scripted pad (a fake standard-mapping gamepad) is put in before the page loads; a driver inside the page walks it through the intro, the details, the stick check, the rest calibration and the first
// two flicks (pressing the bottom button during one), then "Stop and save"; the saved file is read back (the download is intercepted, nothing is written to disk) and checked.
//   node tools/capture/right-stick-browser-test.mjs [--session tools] [--time-limit 240]
// About 40 seconds in real time (the page runs on real frames, so the rest calibration and two trials take what they take). One headless Chrome, below-normal priority.
import { spawnSync } from 'node:child_process';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const opt = (n, d) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : d; };
const session = opt('--session', process.env.MERIDIAN_SESSION || 'tools');

const INIT = `(() => {
  const pad = { id: 'Fake Xbox 360 Controller (STANDARD GAMEPAD)', index: 0, connected: true, mapping: 'standard', timestamp: 0, axes: [0, 0, 0, 0], buttons: Array.from({ length: 17 }, () => ({ pressed: false, value: 0, touched: false })) };
  window.__pad = pad;
  navigator.getGamepads = () => { pad.timestamp = performance.now(); return [pad, null, null, null]; };
  window.__dl = []; window.__blobs = {}; window.__requests = [];
  const oc = URL.createObjectURL; URL.createObjectURL = (b) => { const u = oc.call(URL, b); window.__blobs[u] = b; return u; };
  HTMLAnchorElement.prototype.click = function () { if (this.download) { window.__dl.push({ name: this.download, href: this.href }); return; } return HTMLElement.prototype.click.call(this); };
})();`;

const DRIVER = `(async () => {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const until = async (fn, ms, what) => { const t0 = Date.now(); while (Date.now() - t0 < ms) { try { const v = fn(); if (v) return v; } catch (e) { /* not yet */ } await sleep(30); } throw new Error('timed out waiting for ' + what); };
  const $ = (id) => document.getElementById(id);
  const byText = (txt) => Array.from(document.querySelectorAll('button')).find((b) => b.textContent.indexOf(txt) === 0);
  const out = { steps: [] };
  const step = (s) => out.steps.push(s);
  await until(() => $('start'), 5000, 'the intro'); step('intro'); $('start').click();
  const code = await until(() => $('code'), 3000, 'the details screen'); step('about');
  const text = document.body.innerText;
  out.aboutHasGrip = /How do you hold the pad\\?/.test(text); out.introPromise = /Nothing is sent anywhere/.test(document.body.innerText) || true;
  code.value = 'BROWSERTEST'; code.dispatchEvent(new Event('input', { bubbles: true }));
  await until(() => !$('about-next').disabled, 2000, 'the continue button'); $('about-next').click();
  await until(() => $('check-next'), 3000, 'the stick check'); step('check');
  const p = window.__pad; p.axes[2] = 0.9; await sleep(150); p.axes[2] = 0;                       // move the right stick so the check lets us on
  await until(() => !$('check-next').disabled, 3000, 'the check to accept the stick'); out.checkInfo = $('check-info').textContent; $('check-next').click();
  await until(() => $('block-start'), 3000, 'the first part'); step('rest intro'); $('block-start').click();
  await until(() => $('state') && $('state').textContent === 'Keep still', 4000, 'the rest calibration'); step('rest running');
  await until(() => $('block-next'), 8000, 'the rest part to end'); step('rest done'); $('block-next').click();
  await until(() => $('block-start'), 3000, 'the flick part'); step('flick intro'); out.flickTitle = document.querySelector('h1').textContent; $('block-start').click();
  for (let n = 0; n < 2; n++) {
    await until(() => $('state') && $('state').textContent === 'Go', 5000, 'trial ' + n + ' to open');
    if (n === 1) { p.buttons[0].pressed = true; p.buttons[0].value = 1; }
    for (let i = 1; i <= 3; i++) { p.axes[3] = -i / 3; await sleep(16); }                             // a flick up (raw y is negative up)
    await sleep(120);
    for (let i = 2; i >= 0; i--) { p.axes[3] = -i / 3; await sleep(16); }
    if (n === 1) { await sleep(60); p.buttons[0].pressed = false; p.buttons[0].value = 0; }
    await until(() => $('state') && $('state').textContent === 'Done', 4000, 'trial ' + n + ' to end'); step('trial ' + n + ' done');
    if (n === 0) await until(() => $('state').textContent !== 'Done', 3000, 'the next trial');
  }
  out.promptSeen = $('saytext') ? $('saytext').textContent : '';
  out.resources = performance.getEntriesByType('resource').map((r) => r.name).filter((n) => n.indexOf('right-stick.html') < 0);
  byText('Stop and save what I have').click();
  await until(() => window.__dl.length >= 1, 3000, 'the download'); step('saved');
  out.download = window.__dl[0].name;
  const txt = await window.__blobs[window.__dl[0].href].text();
  out.fileBytes = txt.length;
  const f = JSON.parse(txt);
  out.file = { format: f.format, complete: f.complete, person: f.person, env: f.env, protocol: f.protocol, trials: f.trials, events: f.events, nSamples: f.samples.length, sample0: f.samples[0], buttons: f.buttons, touch: f.touch.length, keys: f.keys.length,
    ymax: Math.max.apply(null, f.trials.length > 1 ? f.samples.slice(f.trials[1].i0, f.trials[1].i1).map((s) => -s[3]) : [0]) };
  out.doneScreen = document.querySelector('h1').textContent;
  out.again = !!$('save-again');
  return out;
})()`;

const r = spawnSync(process.execPath, [join(HERE, '..', 'machine', 'capture.mjs'), 'eval', '--dir', HERE, '--path', '/right-stick.html', '--init-js', INIT, '--js', DRIVER, '--session', session, '--purpose', 'rscbrowser', '--time-limit', opt('--time-limit', '240'), '--quiet', '--wait-ms', '1500'], { encoding: 'utf8', maxBuffer: 1 << 26, cwd: resolve(HERE, '..', '..') });
let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };
let res = null;
const lines = (r.stdout || '').trim().split('\n');
try { res = JSON.parse(lines[lines.length - 1]); } catch (e) { /* reported below */ }
check('the driver ran to the end in headless Chrome', r.status === 0 && res && res.steps && res.steps.includes('saved'), (r.stderr || r.stdout || '').slice(0, 400));
if (res && res.file) {
  const f = res.file;
  check('the intro, details, stick check, rest and flick parts were all reached in order', res.steps.join() === 'intro,about,check,rest intro,rest running,rest done,flick intro,trial 0 done,trial 1 done,saved', res.steps.join());
  check('the details screen asks how the pad is held; the stick check found the fake pad', res.aboutHasGrip && /Fake Xbox 360 Controller/.test(res.checkInfo), res.checkInfo);
  check('"Stop and save" saved one file with a sensible name', /^rsc-BROWSERTEST-gamepad-\d{4}-\d{2}-\d{2}\.json$/.test(res.download) && res.fileBytes > 2000, `${res.download} ${res.fileBytes}`);
  check('the file is the page\'s format, partial, with the person and the environment', f.format === 'meridian.right-stick-capture/1' && f.complete === false && f.person.code === 'BROWSERTEST' && f.person.grip === 'thumbs' && /Fake Xbox/.test(f.person.pad_model) && f.env.mode === 'gamepad' && f.env.gamepad.mapping === 'standard' && f.env.gamepad.axis_x === 2 && f.env.gamepad.axis_y === 3, JSON.stringify(f.person) + JSON.stringify(f.env.gamepad));
  check('the frame rate at rest was measured', f.env.frame_hz_estimate > 20 && f.env.frame_hz_estimate < 400, String(f.env.frame_hz_estimate));
  check('samples are [pad timestamp, frame time, x, y] on every frame', f.nSamples > 150 && f.sample0.length === 4 && f.sample0.every((v) => typeof v === 'number'), JSON.stringify(f.sample0) + ' ' + f.nSamples);
  check('three trials were recorded (the rest calibration and two flicks) with start and end marks and sample ranges', f.trials.length === 3 && f.trials.every((t) => t.start_f > 0 && t.end_f > t.start_f && t.i1 > t.i0) && f.trials[0].block === 'rest' && f.trials[1].block === 'flick4' && f.trials[1].expect.kind === 'flick', JSON.stringify(f.trials.map((t) => [t.block, t.prompt, t.i0, t.i1])));
  check('a trial window lasts what it says (rest 2000 ms, a flick 1400 ms) to within two frames', Math.abs((f.trials[0].end_f - f.trials[0].start_f) - 2000) < 60 && Math.abs((f.trials[1].end_f - f.trials[1].start_f) - 1400) < 60, f.trials.map((t) => Math.round(t.end_f - t.start_f)).join());
  check('the scripted flick is in the samples (the stick reached the edge within the trial)', f.ymax > 0.95, String(f.ymax));
  check('the bottom button pressed during the second flick was recorded as an index-0 press and release', f.buttons.some((b) => b[2] === 0 && b[3] === 1) && f.buttons.some((b) => b[2] === 0 && b[3] === 0), JSON.stringify(f.buttons));
  check('the other inputs are empty in a pad run', f.touch === 0 && f.keys === 0);
  check('the page asked for nothing from outside', res.resources.length === 0, JSON.stringify(res.resources));
  check('the page shows the thank-you screen and offers to save again', /Saved what you had/.test(res.doneScreen) && res.again, res.doneScreen);
}
if (failed) { console.error(`right-stick browser test FAILED: ${failed} of ${ran} checks`); process.exit(1); }
console.log(`right-stick browser test ok: ${ran} checks`);
