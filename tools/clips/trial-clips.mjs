// Clips of trial moves with the inputs on screen (Tools, 2026-11-28; docs/tools/clips.md, "Trial clips"): short seeded scenes with scripted pads, played on a trial web export (trial-web.mjs) through the
// guarded browser launcher, with a button strip under the picture (never over it) for each pad that matters: which button, and tap, hold or mash.
//
//   node tools/clips/trial-clips.mjs probe  --build <trial folder> [clip ...]                    headless, no browser: plays every segment and checks what its "expect" and "never" say
//   node tools/clips/trial-clips.mjs record --build <trial folder> --out <folder> [clip ...]     the clips (GIF and WebM), Reduce flashing ON (--normal for off), one browser, below normal
//
// A clip is a file of tools/clips/trial/: { "name", "title", "switches": [rows of tools/trial-switches.json], "labels": { "0": "YOU", "1": "RIVAL" }, "segments": [ { "caption", "from", "to", "scene": {a
// script, see script_driver.gd}, "expect": ["name or name:text or name@actor"], "never": [...] } ] }. Segments are cut together (a hard cut, the last picture of each held for half a second).
import { copyFileSync, existsSync, mkdirSync, mkdtempSync, readdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { engine, godotExe } from './trial-web.mjs';
import { openPage, runScene, stripStates } from './make.mjs';
import { analyseGif } from '../flash/analyse-gif.mjs';
import { createRequire } from 'node:module';
const FLASH_V = createRequire(import.meta.url)('../flash/verdict.js');

const HERE = fileURLToPath(new URL('.', import.meta.url));
export const CLIP_DIR = join(HERE, 'trial');
const W = 960, H = 540, STEP = 3, FPS = 20, HOLD_PICTURES = 10;
const WORDS = 'planet=7&blackbox=off';
const log = (m) => console.log(`[trial-clips] ${m}`);

export function loadClips(dir = CLIP_DIR, names = []) {
  const all = readdirSync(dir).filter((n) => n.endsWith('.json')).sort().map((n) => JSON.parse(readFileSync(join(dir, n), 'utf8')));
  for (const n of names) if (!all.some((c) => c.name === n)) throw new Error(`no clip "${n}" in tools/clips/trial (${all.map((c) => c.name).join(', ')})`);
  return names.length ? all.filter((c) => names.includes(c.name)) : all;
}

/** What is wrong with a clip definition; [] when it is fit to play. Pure. */
export function problemsOf(c) {
  const out = [], at = c && c.name ? c.name : '(no name)';
  if (!c || typeof c.name !== 'string' || !/^[a-z0-9-]+$/.test(c.name)) out.push(`${at}: needs a name of a-z, 0-9 and -`);
  if (!Array.isArray(c.switches)) out.push(`${at}: needs "switches"`);
  if (!Array.isArray(c.segments) || !c.segments.length) return [...out, `${at}: needs segments`];
  c.segments.forEach((s, i) => {
    const w = `${at} segment ${i + 1}`;
    if (typeof s.caption !== 'string' || !s.caption.trim()) out.push(`${w}: needs a caption`);
    if (!Number.isInteger(s.from) || !Number.isInteger(s.to) || s.to <= s.from) out.push(`${w}: needs from and to ticks`);
    const sc = s.scene;
    if (!sc || !Array.isArray(sc.events)) { out.push(`${w}: needs a scene with events`); return; }
    if (!(sc.ticks >= s.to)) out.push(`${w}: scene.ticks must reach "to"`);
    sc.events.forEach((e, k) => {
      if (!('at' in e) && !('after' in e)) out.push(`${w} event ${k}: needs "at" or "after"`);
      if (!['b', 'trig', 'ls', 'rs', 'computer'].some((op) => op in e)) out.push(`${w} event ${k}: no b, trig, ls, rs or computer`);
    });
    if (!(s.expect || []).length) out.push(`${w}: needs "expect" (what the probe must see, or the clip may show something else than its caption)`);
  });
  return out;
}

/** The names a probe's output saw, as the driver keys them. Pure. */
export function seenIn(text) {
  const seen = new Set();
  for (const l of text.split(/\r?\n/)) {
    const m = /^ev +(\d+) (\S+) '([^']*)' a(-?\d+) att(-?\d+) vic(-?\d+)/.exec(l);
    if (!m) continue;
    const [, , name, t, actor] = m;
    for (const k of [name, `${name}:${t}`, `${name}@${actor}`, `${name}:${t}@${actor}`]) seen.add(k);
  }
  return seen;
}

async function probe(build, clips) {
  const tree = join(build, 'tree'), userdata = join(build, 'userdata'), exe = godotExe();
  for (const f of ['script_driver.gd', 'script_probe.gd']) copyFileSync(join(HERE, f), join(tree, 'tools', 'clips', f));
  const work = join(build, 'probe');
  mkdirSync(work, { recursive: true });
  let bad = 0;
  for (const c of clips) {
    for (let i = 0; i < c.segments.length; i++) {
      const s = c.segments[i], scene = join(work, `${c.name}-${i + 1}.json`), out = join(work, `${c.name}-${i + 1}.txt`);
      writeFileSync(scene, JSON.stringify(s.scene));
      const code = await engine(exe, ['--path', tree, '--script', 'res://tools/clips/script_probe.gd', '--', `--scene=${scene}`], userdata, out, 10 * 60 * 1000);
      const text = readFileSync(out, 'utf8'), seen = seenIn(text);
      const missing = (s.expect || []).filter((k) => !seen.has(k)), present = (s.never || []).filter((k) => seen.has(k));
      const err = /SCRIPT ERROR|Parse Error/.test(text) || code !== 0 || !text.includes('PROBE done');
      const ok = !err && !missing.length && !present.length;
      if (!ok) bad++;
      log(`${ok ? 'ok  ' : 'FAIL'} ${c.name} ${i + 1} (${s.caption})${missing.length ? `: never saw ${missing.join(', ')}` : ''}${present.length ? `: saw ${present.join(', ')}` : ''}${err ? `: the probe did not finish (exit ${code})` : ''} -> ${out}`);
    }
  }
  return bad;
}

function python(args) {
  for (const c of [['python'], ['python3'], ['py', '-3']]) {
    const r = spawnSync(c[0], [...c.slice(1), ...args], { encoding: 'utf8', timeout: 600000 });
    if (r.error && r.error.code === 'ENOENT') continue;
    if (r.status !== 0) throw new Error(`encode.py failed: ${(r.stdout || '') + (r.stderr || '')}`.slice(0, 500));
    return r.stdout;
  }
  throw new Error('no python on this PC (Pillow is the clip encoder)');
}

const encode = (frames, out, format, strip, maxkb) => JSON.parse(python([join(HERE, 'encode.py'), '--in', frames, '--out', out, '--format', format, '--width', '640', '--fps', String(FPS), '--maxkb', String(maxkb), '--strip', strip]).trim().split('\n').pop());

const LINGER = 8;   // pictures (0.4 s): a quick tap is down for two or three ticks, one picture of the clip, too short to read

/** The strip states with each tap (and mash) left lit for LINGER pictures after the button is up; a new press or a hold takes over at once. Pure. */
export function linger(states, n = LINGER) {
  const last = {};
  return states.map((st, i) => {
    const out = { ...st };
    for (const [k, v] of Object.entries(st)) {
      if (k === 'LS') continue;
      const word = k === 'RS' ? v.g : v;
      if (word) { last[k] = { i, word, v }; continue; }
      const was = last[k];
      if (was && was.word !== 'hold' && i - was.i < n) out[k] = k === 'RS' ? { ...was.v } : was.word;
    }
    return out;
  });
}

/** The pictures and strip states of every segment, cut together into `dir`; the pad rows are the capture hook's. */
function join_(clip, parts, dir) {
  mkdirSync(dir, { recursive: true });
  const slots = Object.keys(clip.labels || { 0: 'YOU' }).map(Number).sort();
  const frames = [], rows = slots.map((s) => ({ label: (clip.labels || {})[s] || 'YOU', frames: [] })), captions = [];
  let n = 0;
  parts.forEach((p, i) => {
    const names = readdirSync(p.dir).filter((x) => x.endsWith('.jpg')).sort();
    const ticks = names.map((x) => Number(/^t-(\d+)/.exec(x)[1]));
    const states = slots.map((s) => linger(stripStates(p.pad, ticks, s, STEP)));
    for (let k = 0; k < names.length + HOLD_PICTURES; k++) {
      const j = Math.min(k, names.length - 1);
      copyFileSync(join(p.dir, names[j]), join(dir, `t-${String(++n).padStart(6, '0')}.jpg`));
      slots.forEach((_s, r) => rows[r].frames.push(states[r][j]));
      captions.push(clip.segments[i].caption);
    }
    frames.push(names.length);
  });
  const strip = join(dir, 'strip.json');
  writeFileSync(strip, JSON.stringify({ rows, captions }));
  return { strip, pictures: n };
}

async function record(build, clips, out, { normal = false } = {}) {
  const web = join(build, 'web');
  mkdirSync(out, { recursive: true });
  const work = mkdtempSync(join(tmpdir(), 'meridian-trial-'));
  const op = await openPage(web, WORDS, W, H, 3600);
  const made = [], webm = [];
  try {
    // a throwaway start first: the page's first match shows the "joined" note for the second scripted pad, which is no part of any clip
    await op.page.eval(`window.__clipScript = ${JSON.stringify(JSON.stringify(clips[0].segments[0].scene))}`);
    await runScene(op.page, { scene: 'script', seed: 11, W, H, requests: [{ name: 'warmup', dir: join(work, 'warmup'), from: 150, frames: 1, step: STEP, event: null }], aliases: {}, maxTicks: 160, reduced: !normal });
    for (const c of clips) {
      const parts = [];
      for (let i = 0; i < c.segments.length; i++) {
        const s = c.segments[i], dir = join(work, `${c.name}-${i + 1}`);
        await op.page.eval(`window.__clipScript = ${JSON.stringify(JSON.stringify(s.scene))}`);
        const req = { name: c.name, dir, from: s.from, frames: Math.floor((s.to - s.from) / STEP) + 1, step: STEP, event: null };
        const seen = await runScene(op.page, { scene: 'script', seed: s.scene.seed || 11, W, H, requests: [req], aliases: {}, maxTicks: s.scene.ticks + 5, reduced: !normal });
        if (req.error) throw new Error(`${c.name} segment ${i + 1}: ${req.error}`);
        const modeOk = await op.page.eval('window.__flashcap.mode ? window.__flashcap.mode.reduce_flashing : null');
        if (modeOk !== !normal) throw new Error(`${c.name}: Reduce flashing is ${modeOk} in the page, asked ${!normal}`);
        parts.push({ dir, pad: seen.pad });
        log(`${c.name} segment ${i + 1}: ${req.taken.length} pictures`);
      }
      const dir = join(work, c.name);
      const j = join_(c, parts, dir);
      const gif = join(out, `${c.name}.gif`);
      const info = encode(dir, gif, 'gif', j.strip, 6000);
      let flash = 'CHECK';
      try { const a = analyseGif(gif); const m = /(PASS|OVER GATE|FAIL)/.exec(FLASH_V.columns(a.result)); flash = m ? m[1] : (a.result.pass ? 'PASS' : 'FAIL'); } catch (e) { flash = `CHECK (${e.message.slice(0, 80)})`; }
      const prep = join(work, `${c.name}-webm`);
      encode(dir, prep, 'frames', j.strip, 6000);
      webm.push({ name: c.name, prep, seconds: Math.round(j.pictures / FPS * 10) / 10 });
      made.push({ name: c.name, gif, kb: info.kb, seconds: Math.round(j.pictures / FPS * 10) / 10, flash });
    }
    // the browser's own recorder makes the WebM (real time, nothing to install): after the last scene, since it takes the page
    for (const w of webm) {
      const names = readdirSync(w.prep).filter((x) => x.endsWith('.jpg')).sort();
      writeFileSync(join(w.prep, 'frames.json'), JSON.stringify({ fps: FPS, frames: names }));
      copyFileSync(join(HERE, 'webm.html'), join(w.prep, 'webm.html'));
      const { serve } = await import('../machine/browser.mjs');
      const server = await serve(w.prep);
      try {
        await op.page.send('Page.navigate', { url: `http://127.0.0.1:${server.address().port}/webm.html` });
        const deadline = Date.now() + (w.seconds + 90) * 1000;
        let done = false;
        while (Date.now() < deadline && !done) { await new Promise((r) => setTimeout(r, 500)); done = await op.page.eval('Boolean(window.__webmDone)').catch(() => false); }
        if (!done) throw new Error(`${w.name}: the browser's recorder did not finish`);
        writeFileSync(join(out, `${w.name}.webm`), Buffer.from(await op.page.eval('window.__webm'), 'base64'));
      } finally { server.close(); }
    }
  } finally {
    try { op.page.close(); } catch { /* gone */ }
    try { await op.browser.close(); } catch { /* gone */ }
    op.server.close();
    rmSync(work, { recursive: true, force: true });
  }
  const trial = existsSync(join(build, 'trial.json')) ? JSON.parse(readFileSync(join(build, 'trial.json'), 'utf8')) : {};
  const lines = [`commit ${String(trial.commit || '?').slice(0, 8)}, switches ${(trial.switches || []).join(', ')}, parks: ${[...new Set((trial.parks || []).map((p) => p.file.split('/').slice(0, -1).join('/')))].join(', ') || 'none'}; Reduce flashing ${normal ? 'OFF' : 'ON'}`,
    ...made.map((m) => `${m.name} | ${m.seconds} s | gif ${m.kb} KB | flash check of the GIF: ${m.flash}`)];
  writeFileSync(join(out, normal ? 'index-normal.txt' : 'index.txt'), `${lines.join('\n')}\n`);
  for (const l of lines) log(l);
  return made;
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  const argv = process.argv.slice(2);
  const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
  const mode = argv[0];
  const names = []; for (let i = 1; i < argv.length; i++) { if (argv[i].startsWith('--')) { if (argv[i] !== '--normal') i++; } else names.push(argv[i]); }
  try {
    const build = opt('--build');
    if (!['probe', 'record'].includes(mode) || !build) { console.error('usage: node tools/clips/trial-clips.mjs probe|record --build <trial folder> [--out <folder>] [clip ...] [--normal]'); process.exit(2); }
    const clips = loadClips(CLIP_DIR, names);
    const problems = clips.flatMap(problemsOf);
    if (problems.length) throw new Error(problems.join('; '));
    const trial = JSON.parse(readFileSync(join(resolve(build), 'trial.json'), 'utf8'));
    for (const c of clips) for (const sw of c.switches) if (!(trial.switches || []).includes(sw)) throw new Error(`${c.name} needs the switch ${sw}, which this build has not on`);
    if (mode === 'probe') process.exit((await probe(resolve(build), clips)) ? 1 : 0);
    if (!opt('--out')) throw new Error('record needs --out <folder>');
    const made = await record(resolve(build), clips, resolve(opt('--out')), { normal: argv.includes('--normal') });
    const notPass = made.filter((m) => m.flash !== 'PASS');
    for (const m of notPass) console.error(`[trial-clips] NOT PASS: ${m.name} reads "${m.flash}": do not hand it over`);
    process.exit(notPass.length ? 1 : 0);
  } catch (e) { console.error(`[trial-clips] FAILED: ${e.message}`); process.exit(1); }
}
