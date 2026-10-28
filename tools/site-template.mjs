// Which Web export template the SITE is built with: tools/site.json "template": "standard" (Godot's own 4.7.2 template, the default and what the key means when it is absent) or "custom" (our patched
// build, tools/engine/patches/, built by .github/workflows/web-template.yml). Nothing changes until the key says "custom" AND tools/web-template.json holds a complete pin. Design and the choice
// between the three ways of getting the zip: docs/tools/site-template.md.
//
//   node tools/site-template.mjs --check [--config <site.json>] [--record <web-template.json>] [--site <built site dir>] [--root <repo root: where the workflow and the engine patches are read>]
//        standard: says so and passes (the record is not read). custom: fails unless the record is complete (a github.com release asset URL, its SHA-512, the SHA-512 of the godot.wasm inside it,
//        and the readings measured on the CUSTOM export: parity, the signature clip in both modes with reduced within 2.5 / 3 / 2, the collapse clip in both modes, and a nightly on the pinned
//        commit with nothing over the limit). With --site it also reads the built site's play/index.wasm: custom, it must be the pinned wasm; standard, it must not be.
//   node tools/site-template.mjs --fetch <dir> [--config ...] [--record ...]
//        custom: downloads the pinned zip into <dir> (curl, as .github/actions/setup-godot does), checks its size and SHA-512 and prints its path; standard: prints nothing.
//   node tools/site-template.mjs --download <dir> [--record ...]
//        the same download and the same checks (release URL, size, SHA-512 of the zip, SHA-512 of the godot.wasm inside it), whatever tools/site.json says and whether or not the readings are in: the way to
//        get the pinned zip to take those readings on it (parity, the clips, the nightly, the frames). Prints the path; the file is removed on a mismatch.
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { inflateRawSync } from 'node:zlib';

const HERE = import.meta.dirname;
export const TEMPLATE_FILE = 'web_nothreads_release.zip';
export const RECORD_FILE = join(HERE, 'web-template.json');
const SHA512 = /^[0-9a-f]{128}$/;
const RELEASE_URL = /^https:\/\/github\.com\/[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+\/releases\/download\/[^/\s]+\/[^/\s]+\.zip$/;
export const REDUCED_MAX = { primary: 2.5, area15: 3, twoSec: 2 };   // the signature clip's pin limit, reduced (Legal RL-195)

const sha512 = (buf) => createHash('sha512').update(buf).digest('hex');

/** 'standard' or 'custom' from a site.json object; anything else is an error. An absent key is standard. */
export function templateOf(config) {
  const t = config && config.template === undefined ? 'standard' : config && config.template;
  if (t !== 'standard' && t !== 'custom') throw new Error(`tools/site.json "template" is ${JSON.stringify(config && config.template)}: it must be "standard" or "custom"`);
  return t;
}

const reading = (r) => r && typeof r.primary === 'number' && typeof r.area15 === 'number' && typeof r.twoSec === 'number';

/** Why a custom template may not be used yet (an array; empty when the pin and its measurements are complete). Pure. */
export function recordProblems(rec, config, ctx = null) {
  const out = [];
  if (!rec || typeof rec !== 'object') return ['tools/web-template.json is missing or unreadable'];
  if (!RELEASE_URL.test(String(rec.url))) out.push('the record has no release asset URL (https://github.com/<owner>/<repo>/releases/download/<tag>/<file>.zip): the template is not published');
  if (!SHA512.test(String(rec.sha512))) out.push('the record has no SHA-512 of the zip (128 lower-case hex digits)');
  if (!SHA512.test(String(rec.wasmSha512))) out.push('the record has no SHA-512 of the godot.wasm inside the zip (it is what the built site\'s index.wasm is checked against)');
  if (!(Number.isInteger(rec.bytes) && rec.bytes > 0)) out.push('the record has no byte size of the zip');
  const m = rec.measured || {};
  if (!(m.parity && m.parity.keys > 0 && m.parity.match === m.parity.keys)) out.push('measured.parity is not complete: the web parity check (same sim bits as the standard template) must match every key on the custom template');
  const sig = m.signature || {};
  if (!reading(sig.reduced) || !reading(sig.normal)) out.push('measured.signature has no reading in both modes (primary, area15, twoSec) on the custom export');
  else if (sig.reduced.primary > REDUCED_MAX.primary || sig.reduced.area15 > REDUCED_MAX.area15 || sig.reduced.twoSec > REDUCED_MAX.twoSec) out.push(`measured.signature.reduced reads worse than ${REDUCED_MAX.primary} / ${REDUCED_MAX.area15} / ${REDUCED_MAX.twoSec} (Legal RL-195 condition (a)): the pin cannot move to it`);
  const col = m.collapse || {};
  if (!reading(col.reduced) || !reading(col.normal)) out.push('measured.collapse has no reading in both modes on the custom export');
  const n = m.nightly;
  if (!n || typeof n !== 'object') out.push('measured.nightly is missing: a nightly seeds run on the pinned commit, exported with this template, before the switch (the pin rule: a build is measured before it is served)');
  else {
    if (config && /^[0-9a-f]{40}$/.test(String(config.pin)) && n.commit !== config.pin) out.push(`measured.nightly is for ${String(n.commit).slice(0, 8)}, the pin is ${String(config.pin).slice(0, 8)}: re-run the nightly on the pin with the custom template`);
    if (!(Array.isArray(n.seeds) && n.seeds.length > 0 && typeof n.max === 'number')) out.push('measured.nightly has no seeds and largest primary reading');
    if (!Array.isArray(n.over) || n.over.length > 0 || !Array.isArray(n.missing) || n.missing.length > 0) out.push('measured.nightly has a clip over the limit or a clip missing (a missing clip is not a pass)');
  }
  // Legal's RL-199 item 1: the clips already captured, standard against custom on the same commit, compared frame by frame (tools/flash/compare-frames.mjs): identical or within noise; a frame beyond
  // noise means the full required set is run on the custom build and recorded in measured.full
  const pin = config && /^[0-9a-f]{40}$/.test(String(config.pin)) ? config.pin : null;
  const fr = m.frames;
  const fullOk = !!(m.full && m.full.clips > 0 && m.full.pass === m.full.clips && (!pin || m.full.commit === pin));
  if (!fr || typeof fr !== 'object' || !(fr.frames > 0) || typeof fr.beyondNoise !== 'number') out.push('measured.frames is missing: compare the clips already captured, standard against custom on the same commit (node tools/flash/compare-frames.mjs --json), and record its counts');
  else {
    if (pin && fr.commit !== pin) out.push(`measured.frames compares ${String(fr.commit).slice(0, 8)}, the pin is ${pin.slice(0, 8)}: compare the clips of the pinned commit`);
    if (fr.beyondNoise > 0 && !fullOk) out.push(`measured.frames has ${fr.beyondNoise} frame${fr.beyondNoise === 1 ? '' : 's'} beyond noise: the full required set must be run on the custom build and recorded in measured.full (every clip PASS, on the pin)`);
  }
  if (m.full && !fullOk) out.push('measured.full is not a complete passing set on the pin (clips and pass counts equal, the pinned commit)');
  // RL-199 item 2: the template's build flags and hash are pinned; a change to either (a module on or off, a compression change) is a new flip with this same list
  const b = rec.build;
  if (!b || typeof b !== 'object' || typeof b.flags !== 'string' || !b.flags.trim() || !SHA512.test(String(b.source)) || !b.emscripten || !b.patches || typeof b.patches !== 'object' || !Object.keys(b.patches).length) out.push('the record does not pin the build: build.flags (the SCons flags, extra ones included), build.source (SHA-512 of the Godot source), build.emscripten and build.patches (file name to SHA-256)');
  else if (ctx) {
    const wf = ctx.workflow ? { flags: /^\s*SCONS_FLAGS:\s*(.+?)\s*$/m.exec(ctx.workflow), source: /^\s*GODOT_SRC_SHA512:\s*([0-9a-f]+)\s*$/m.exec(ctx.workflow), em: /^\s*EM_VERSION:\s*(\S+)\s*$/m.exec(ctx.workflow) } : null;
    if (wf) {
      if (!wf.flags || !(b.flags === wf.flags[1] || b.flags.startsWith(wf.flags[1] + ' '))) out.push(`the build flags changed since the pin: web-template.yml builds with "${wf.flags ? wf.flags[1] : '?'}", the record pins "${b.flags}": a new flip (re-measure and re-pin)`);
      if (!wf.source || wf.source[1] !== b.source) out.push('the Godot source of the build changed since the pin: a new flip');
      if (!wf.em || wf.em[1] !== String(b.emscripten)) out.push('the Emscripten version of the build changed since the pin: a new flip');
    }
    if (ctx.patches) {
      const names = new Set([...Object.keys(ctx.patches), ...Object.keys(b.patches)]);
      for (const name of [...names].sort()) {
        const have = ctx.patches[name] ? createHash('sha256').update(ctx.patches[name]).digest('hex') : null;
        if (have !== b.patches[name]) out.push(`the engine patch ${name} ${have === null ? 'is gone' : b.patches[name] === undefined ? 'is not pinned' : 'changed'} since the pin: a new flip`);
      }
    }
  }
  // every measurement was taken on THIS zip: a different zip (another flag, another module, another compression) has none of these readings
  if (SHA512.test(String(rec.sha512))) for (const k of ['parity', 'signature', 'collapse', 'nightly', 'frames', 'full']) if (m[k] && typeof m[k] === 'object' && m[k].template !== rec.sha512) out.push(`measured.${k} was not taken on this zip (its "template" is ${m[k].template ? String(m[k].template).slice(0, 16) + '...' : 'not recorded'}, the pinned zip is ${rec.sha512.slice(0, 16)}...): a new flip`);
  return out;
}

/** The workflow and the engine patches as the record is checked against (RL-199 item 2). null parts are not compared. */
export function loadCtx(root = join(HERE, '..')) {
  const wf = join(root, '.github', 'workflows', 'web-template.yml'), pd = join(root, 'tools', 'engine', 'patches');
  const patches = {};
  if (existsSync(pd)) for (const f of readdirSync(pd)) if (f.endsWith('.patch')) patches[f.replace(/\.patch$/, '')] = readFileSync(join(pd, f));
  return { workflow: existsSync(wf) ? readFileSync(wf, 'utf8') : null, patches: existsSync(pd) ? patches : null };
}

/** Reads one entry of a zip held in a Buffer (stored or deflated), or null. Just enough of the format for the template zip. */
export function readZipEntry(buf, name) {
  let eocd = -1;
  for (let i = buf.length - 22; i >= Math.max(0, buf.length - 65557); i--) if (buf.readUInt32LE(i) === 0x06054b50) { eocd = i; break; }
  if (eocd < 0) return null;
  const count = buf.readUInt16LE(eocd + 10);
  let p = buf.readUInt32LE(eocd + 16);
  for (let k = 0; k < count; k++) {
    if (buf.readUInt32LE(p) !== 0x02014b50) return null;
    const method = buf.readUInt16LE(p + 10), csize = buf.readUInt32LE(p + 20), nlen = buf.readUInt16LE(p + 28), elen = buf.readUInt16LE(p + 30), clen = buf.readUInt16LE(p + 32), off = buf.readUInt32LE(p + 42);
    const entry = buf.toString('utf8', p + 46, p + 46 + nlen);
    if (entry === name) {
      const lnlen = buf.readUInt16LE(off + 26), lelen = buf.readUInt16LE(off + 28);
      const data = buf.subarray(off + 30 + lnlen + lelen, off + 30 + lnlen + lelen + csize);
      return method === 0 ? Buffer.from(data) : method === 8 ? inflateRawSync(data) : null;
    }
    p += 46 + nlen + elen + clen;
  }
  return null;
}

/** Downloads the pinned zip into dir with curl and checks its size and SHA-512; the file is removed on a mismatch. Returns the path. `o.insecure` allows any curl URL (the self-test's local server). */
export function fetchTemplate(rec, dir, o = {}) {
  if (!o.insecure && !RELEASE_URL.test(String(rec && rec.url))) throw new Error('the record has no release asset URL');
  mkdirSync(dir, { recursive: true });
  const file = join(dir, TEMPLATE_FILE);
  rmSync(file, { force: true });
  const r = spawnSync('curl', ['-fsSL', '--retry', '3', '-o', file, String(rec.url)], { encoding: 'utf8' });
  if (r.status !== 0) throw new Error(`curl could not fetch ${rec.url}: ${(r.stderr || '').trim() || `exit ${r.status}`}`);
  const buf = readFileSync(file);
  const bad = Number.isInteger(rec.bytes) && buf.length !== rec.bytes ? `its size is ${buf.length} bytes, the record says ${rec.bytes}` : sha512(buf) !== rec.sha512 ? `its SHA-512 is ${sha512(buf).slice(0, 16)}..., the record pins ${String(rec.sha512).slice(0, 16)}...` : null;
  if (bad) { rmSync(file, { force: true }); throw new Error(`the downloaded template is not the pinned one: ${bad}`); }
  const wasm = readZipEntry(buf, 'godot.wasm');
  if (rec.wasmSha512 && (!wasm || sha512(wasm) !== rec.wasmSha512)) { rmSync(file, { force: true }); throw new Error('the zip holds no godot.wasm with the pinned SHA-512'); }
  return file;
}

/** The zip the site's export uses for this config: null for the standard template, else the fetched, verified file. Throws when custom is asked for and the pin is not complete. */
export function templateFor(config, rec, dir, o = {}) {
  if (templateOf(config) === 'standard') return null;
  const p = recordProblems(rec, config, o.ctx === undefined ? loadCtx() : o.ctx);
  if (p.length) throw new Error(`the site asks for the custom template and it is not ready: ${p.join('; ')}`);
  return fetchTemplate(rec, dir, o);
}

/** The built site's engine against the pin: { ok, message }. */
export function siteWasmProblems(config, rec, siteDir) {
  const f = join(siteDir, 'play', 'index.wasm');
  if (!existsSync(f)) return ['the built site has no play/index.wasm'];
  const h = sha512(readFileSync(f));
  const pinned = rec && SHA512.test(String(rec.wasmSha512)) ? rec.wasmSha512 : null;
  if (templateOf(config) === 'custom') return h === pinned ? [] : [`play/index.wasm is ${h.slice(0, 16)}..., not the pinned custom template's godot.wasm (${pinned ? pinned.slice(0, 16) + '...' : 'none pinned'})`];
  return pinned && h === pinned ? ['the site says "standard" but play/index.wasm is the custom template\'s godot.wasm'] : [];
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  const opt = (n) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : undefined; };
  let config, rec = null;
  try { config = JSON.parse(readFileSync(resolve(opt('--config') || join(HERE, 'site.json')), 'utf8')); } catch (e) { console.error(`site template: tools/site.json could not be read: ${e.message}`); process.exit(2); }
  try { rec = JSON.parse(readFileSync(resolve(opt('--record') || RECORD_FILE), 'utf8')); } catch { /* reported when custom */ }
  let t;
  try { t = templateOf(config); } catch (e) { console.error(`site template: ${e.message}`); process.exit(1); }
  if (args.includes('--download')) {
    try { console.log(fetchTemplate(rec, resolve(opt('--download')))); } catch (e) { console.error(`site template: ${e.message}`); process.exit(1); }
  } else if (args.includes('--fetch')) {
    if (t === 'standard') process.exit(0);
    try { console.log(templateFor(config, rec, resolve(opt('--fetch')))); } catch (e) { console.error(`site template: ${e.message}`); process.exit(1); }
  } else {
    const problems = t === 'custom' ? recordProblems(rec, config, loadCtx(opt('--root') ? resolve(opt('--root')) : undefined)) : [];
    if (opt('--site') && config.offline !== true) problems.push(...siteWasmProblems(config, rec, resolve(opt('--site'))));   // an offline site holds no game: nothing to compare
    if (problems.length) { for (const p of problems) console.error(`site template check FAILED: ${p}`); process.exit(1); }
    console.log(t === 'standard' ? `site template check ok: standard (the default; ${opt('--site') ? 'the built site\'s engine is not the custom one' : 'nothing to check'})` : `site template check ok: custom ${rec.sha512.slice(0, 16)}... (pinned, measured on the custom export${opt('--site') ? ', and the built site runs it' : ''})`);
  }
}
void statSync; void writeFileSync;
