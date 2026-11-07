// The clip kit's self-test (docs/tools/clips.md): the recipes are well formed, the event names and the build lookup behave, the encoder fits a GIF under its size limit, and one short recipe
// (`selftest` in clips.json) runs end to end on the kept build homework/Files/builds/orb-first-play-10d8b8cf-68ee07cc through the guarded launcher. Skips the end-to-end part, saying so,
// when that kept build is not on this PC (it is git-ignored) or with --no-e2e.   node tools/clips/clips-selftest.mjs [--no-e2e]
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { join, resolve, dirname } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { loadRecipes, resolveBuild, eventMatcher, make, stripStates, writeStrip } from './make.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(HERE, '..', '..');
let fails = 0;
const ok = (c, m) => { console.log(`${c ? 'ok  ' : 'FAIL'} ${m}`); if (!c) fails++; };

const R = loadRecipes();
const filled = Object.values(R.clips).filter((r) => !r.pending);
ok(filled.length >= 14 && R.clips.selftest, 'clips.json loads with the self-test recipe and Orb\'s eleven clips and more');
const scenesOk = filled.every((r) => (r.mockup ? existsSync(join(HERE, 'mockups', r.mockup)) : typeof r.scene === 'string') && r.fps > 0 && r.width > 0 && r.maxkb > 0 && (r.mockup || r.event || (r.frames > 0 && r.step > 0 && r.from >= 0)));
ok(scenesOk, 'every recipe has a scene or mockup, a window or an event, and an encoding');
const orb = ['charged-strike', 'chase', 'beam-and-shove', 'beam-struggle', 'top-power-towers', 'building-gives-way', 'planet-today-vs-plates', 'megastructures-pan', 'beam-clash-1-low-side-on', 'beam-clash-2-high-wide-over-town', 'beam-clash-3-tight-then-pull-back'];
ok(orb.every((n) => R.clips[n]), 'the recipes of Orb\'s eleven GIFs are there');
const slots = Object.entries(R.clips).filter(([, r]) => r.pending);
ok(slots.length >= 10 && ['flight-zip', 'flight-line', 'flight-arc', 'flight-parting-shot', 'beam-answer-fire-back', 'beam-answer-dodge', 'beam-answer-powerful-block', 'beam-answer-catch', 'beam-answer-swat', 'beam-answer-walk-in'].every((n) => R.clips[n] && R.clips[n].pending && R.clips[n].needs), `a slot waits for each flight strike and beam answer (${slots.length} pending, each says what it needs)`);
let pendErr = ''; try { await make({ names: ['flight-zip'], dry: false }); } catch (e) { pendErr = e.message; }
ok(/not filled yet/.test(pendErr), 'naming a pending slot says it is not filled yet');
{
  // the button strip: a pad log of a tap, a hold and a mash
  const row = (t, flags, mask = 0) => [t, 0, 0, 0, flags, 0, 0, mask];
  const X = 1 << 0, B = 1 << 2, BH = 1 << 7;
  const rows = [];
  for (let t = 1; t <= 90; t++) {
    let f = 0;
    if (t === 10) f |= X;                                   // a tap of X
    if (t >= 30 && t <= 60) f |= BH | (t === 30 ? B : 0);    // B held 31 ticks
    if ([70, 74, 78].includes(t)) f |= X;                   // three presses of X in 30 ticks
    rows.push(row(t, f, t >= 30 && t <= 60 ? 2 : 0));
  }
  const st = stripStates(rows, [12, 45, 80], 0, 3);
  ok(st[0].X === 'tap' && !st[0].B, 'the strip lights a tapped X with the word tap');
  ok(st[1].B === 'hold' && !st[1].X, 'a held B reads hold (12 ticks or more)');
  ok(st[2].X === 'mash', 'three presses in 30 ticks read mash');
  ok(st[1].RB === 'hold', 'the shoulders read from the stance mask (RB held)');
}
const m = eventMatcher('launch', R.events), m2 = eventMatcher('beam_clash_end', R.events), m3 = eventMatcher('exchange_end:catch', R.events);
ok(m([5, 'launch', '', 0]) && !m([5, 'crater', '', 0]) && m2([9, 'cue', 'beam_clash_end', 0]) && !m2([9, 'cue', 'launch', 0]) && m3([3, 'exchange_end', 'catch', 0]) && !m3([3, 'exchange_end', 'other', 0]), 'event names match the logged events (aliases, type, type:kind)');
let threw = false; try { resolveBuild('no-such-build-xyz'); } catch { threw = true; }
ok(threw, 'an unknown build name is refused');
ok(R.bookmarks.clip && R.bookmarks.launch && R.bookmarks.beam_clash_end && R.bookmarks.ko, 'the bookmark windows exist (launch, crater, building fall, beam clash end, KO, the clip button)');

// the encoder, on frames made here: a 30-frame moving gradient must come out as one looping GIF under the limit
const work = mkdtempSync(join(tmpdir(), 'meridian-clips-test-'));
try {
  const py = ['python', 'python3', 'py'].find((c) => spawnSync(c, ['--version']).status === 0);
  ok(!!py, 'python (Pillow, the encoder) is on this PC');
  if (py) {
    const mk = spawnSync(py, ['-c', `from PIL import Image, ImageDraw
import os
d=r'${join(work, 'in').replace(/\\/g, '/')}'
os.makedirs(d)
for i in range(30):
    im=Image.new('RGB',(960,540),(20,30,60)); g=ImageDraw.Draw(im)
    for k in range(40): g.rectangle((i*10+k*20, 100+k*8, i*10+k*20+60, 160+k*8), fill=(30+k*5, 200-k*4, 90+i*4))
    im.save(os.path.join(d,'t-%06d.jpg'%i), quality=85)`], { encoding: 'utf8' });
    ok(mk.status === 0, 'test frames written');
    const out = join(work, 'a.gif');
    const e = spawnSync(py, [join(HERE, 'encode.py'), '--in', join(work, 'in'), '--out', out, '--format', 'gif', '--width', '480', '--fps', '12', '--maxkb', '400'], { encoding: 'utf8' });
    let info = null; try { info = JSON.parse(e.stdout.trim().split('\n').pop()); } catch { /* none */ }
    const head = existsSync(out) ? readFileSync(out).subarray(0, 6).toString('latin1') : '';
    ok(info && head === 'GIF89a' && info.frames === 30 && statSync(out).size / 1024 <= 400, `the encoder makes a looping GIF89a of the 30 frames under the limit (${info ? info.kb + ' KB, ' + info.colors + ' colours' : e.stderr.slice(0, 120)})`);
    const frames = Array.from({ length: 30 }, (_, i) => ({ LS: [0, 0], X: i > 10 ? 'tap' : null, Y: i > 20 ? 'hold' : null, B: null, A: null, LT: null, LB: null, RB: null, RT: null, RS: { dir: i > 5 ? 3 : 0, level: 1, g: i > 5 ? 'tap' : null } }));
    writeFileSync(join(work, 'strip.json'), JSON.stringify({ frames }));
    const sp = spawnSync(py, [join(HERE, 'encode.py'), '--in', join(work, 'in'), '--out', join(work, 'strip'), '--format', 'png', '--width', '480', '--strip', join(work, 'strip.json')], { encoding: 'utf8' });
    let sinfo = null; try { sinfo = JSON.parse(sp.stdout.trim().split(String.fromCharCode(10)).pop()); } catch { /* none */ }
    ok(sinfo && sinfo.size[1] === 270 + 34 && existsSync(join(work, 'strip', 'f-00030.png')), `the encoder adds the button strip as a band under the picture (frame ${sinfo ? sinfo.size.join('x') : sp.stderr.slice(0, 100)}: 270 high picture + 34 strip)`);
    const bad = spawnSync(py, [join(HERE, 'encode.py'), '--in', join(work, 'in'), '--out', join(work, 'strip2'), '--format', 'png', '--strip', join(work, 'strip.json').replace('strip.json', 'nofile.json')], { encoding: 'utf8' });
    ok(bad.status !== 0, 'a strip file that is missing is an error, not a clip without one');
    const png = spawnSync(py, [join(HERE, 'encode.py'), '--in', join(work, 'in'), '--out', join(work, 'png'), '--format', 'png', '--width', '480'], { encoding: 'utf8' });
    ok(png.status === 0 && existsSync(join(work, 'png', 'f-00030.png')), 'the PNG sequence comes out numbered');
  }
  // end to end on the kept build
  const kept = join(ROOT, 'homework', 'Files', 'builds', 'orb-first-play-10d8b8cf-68ee07cc');
  if (process.argv.includes('--no-e2e')) console.log('skip the end-to-end clip (--no-e2e)');
  else if (!existsSync(join(kept, 'web', 'index.html'))) console.log(`skip the end-to-end clip: the kept build ${kept} is not on this PC`);
  else {
    const out = join(work, 'out');
    const res = await make({ names: ['selftest'], build: kept, out, limit: 900 });
    const r = res[0] || {};
    const file = join(out, 'selftest.gif');
    ok(!r.error && existsSync(file), `the self-test recipe made its clip on the kept build${r.error ? ': ' + r.error : ''}`);
    if (existsSync(file)) {
      ok(readFileSync(file).subarray(0, 6).toString('latin1') === 'GIF89a' && statSync(file).size / 1024 <= R.clips.selftest.maxkb, `it is a GIF under ${R.clips.selftest.maxkb} KB (${Math.round(statSync(file).size / 1024)} KB)`);
      ok(r.strip === (r.size && r.size[1] === 304), `the button strip is there when the build's hook logs the pad (${r.strip ? 'strip under the picture' : 'this build is older than the pad log: no strip'})`);
      ok(r.frames === R.clips.selftest.frames, `it has the ${R.clips.selftest.frames} frames the recipe asks for`);
      ok(/selftest \| selftest\.gif/.test(readFileSync(join(out, 'index.txt'), 'utf8')), 'index.txt has its one line');
    }
  }
} finally { rmSync(work, { recursive: true, force: true }); }
console.log(fails ? `clip kit self-test FAILED: ${fails} check(s)` : 'clip kit self-test ok');
process.exit(fails ? 1 : 0);
