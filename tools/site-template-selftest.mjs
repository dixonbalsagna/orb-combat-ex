// Self-test of tools/site-template.mjs and what hangs on it: the switch (tools/site.json "template", default standard), the record that must be complete before "custom" works, the zip's
// download and its checks, the scratch tree's Web preset getting the template path (and no other preset), the built site's engine against the pin, and the command. No browser, no Godot
// (the exporter is a stub), no network (curl fetches from a local server). CI runs it.
//   node tools/site-template-selftest.mjs
import { createHash } from 'node:crypto';
import { execFileSync, spawn, spawnSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { deflateRawSync } from 'node:zlib';
import { templateOf, recordProblems, readZipEntry, fetchTemplate, templateFor, siteWasmProblems, REDUCED_MAX } from './site-template.mjs';
import { setWebCustomTemplate, webPresetChanged } from './flash/web-preset.mjs';
import { exportPinned } from './site-pin.mjs';

const SHA_HEX = /^[0-9a-f]{128}$/;
let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };
const sha512 = (b) => createHash('sha512').update(b).digest('hex');
const sha256 = (b) => createHash('sha256').update(b).digest('hex');
const BUILD_FLAGS = 'platform=web target=template_release threads=no production=yes optimize=size lto=none';
const SRC512 = 'f'.repeat(128);
const PATCH = Buffer.from('--- a/x\n+++ b/x\n');
const WF = ['env:', `  GODOT_SRC_SHA512: ${SRC512}`, '  EM_VERSION: 4.0.11', `  SCONS_FLAGS: ${BUILD_FLAGS}`, ''].join('\n');
const CTX = { workflow: WF, patches: { '4.7.2-p': PATCH } };
const here = import.meta.dirname;

// a zip written by hand: entries are [name, Buffer, 'stored' | 'deflate']
function crc32(buf) { let c, crc = 0xffffffff; for (let n = 0; n < buf.length; n++) { c = (crc ^ buf[n]) & 0xff; for (let k = 0; k < 8; k++) c = c & 1 ? (c >>> 1) ^ 0xedb88320 : c >>> 1; crc = (crc >>> 8) ^ c; } return (crc ^ 0xffffffff) >>> 0; }
function makeZip(entries) {
  const parts = [], central = [];
  let off = 0;
  for (const [name, data, how] of entries) {
    const nb = Buffer.from(name), comp = how === 'deflate' ? deflateRawSync(data) : data, method = how === 'deflate' ? 8 : 0, crc = crc32(data);
    const lh = Buffer.alloc(30);
    lh.writeUInt32LE(0x04034b50, 0); lh.writeUInt16LE(20, 4); lh.writeUInt16LE(method, 8); lh.writeUInt32LE(crc, 14); lh.writeUInt32LE(comp.length, 18); lh.writeUInt32LE(data.length, 22); lh.writeUInt16LE(nb.length, 26);
    parts.push(lh, nb, comp);
    const ch = Buffer.alloc(46);
    ch.writeUInt32LE(0x02014b50, 0); ch.writeUInt16LE(20, 4); ch.writeUInt16LE(20, 6); ch.writeUInt16LE(method, 10); ch.writeUInt32LE(crc, 16); ch.writeUInt32LE(comp.length, 20); ch.writeUInt32LE(data.length, 24); ch.writeUInt16LE(nb.length, 28); ch.writeUInt32LE(off, 42);
    central.push(ch, nb);
    off += 30 + nb.length + comp.length;
  }
  const cd = Buffer.concat(central), end = Buffer.alloc(22);
  end.writeUInt32LE(0x06054b50, 0); end.writeUInt16LE(entries.length, 8); end.writeUInt16LE(entries.length, 10); end.writeUInt32LE(cd.length, 12); end.writeUInt32LE(off, 16);
  return Buffer.concat([...parts, cd, end]);
}

const WASM = Buffer.from('\0asm-custom-engine-bytes-' + 'x'.repeat(500));
const ZIP = makeZip([['godot.js', Buffer.from('// js'), 'deflate'], ['godot.wasm', WASM, 'deflate'], ['godot.audio.worklet.js', Buffer.from('w'), 'stored']]);
const PIN = 'a'.repeat(40);
const good = (over = {}) => ({
  version: '4.7.2-stable', url: 'https://github.com/owner/repo/releases/download/web-template-4.7.2-1/web_nothreads_release.zip', sha512: sha512(ZIP), wasmSha512: sha512(WASM), bytes: ZIP.length,
  build: { flags: BUILD_FLAGS, source: SRC512, emscripten: '4.0.11', patches: { '4.7.2-p': sha256(PATCH) } },
  measured: {
    parity: { keys: 51, match: 51, template: sha512(ZIP) },
    signature: { reduced: { primary: 2.5, area15: 3, twoSec: 2 }, normal: { primary: 3.5, area15: 5, twoSec: 3 }, template: sha512(ZIP) },
    collapse: { reduced: { primary: 2, area15: 2.5, twoSec: 2 }, normal: { primary: 2, area15: 2.5, twoSec: 2 }, template: sha512(ZIP) },
    nightly: { commit: PIN, seeds: [1000, 1001], max: 3, over: [], missing: [], template: sha512(ZIP) },
    frames: { commit: PIN, clips: ['mash-normal', 'collapse-normal', 'collapse-reduced'], frames: 1800, identical: 600, withinNoise: 1200, beyondNoise: 0, limit: 0.001, template: sha512(ZIP) },
  },
  ...over,
});
const cfg = (over = {}) => ({ offline: false, pin: PIN, ...over });

// the switch
check('an absent "template" key is standard (nothing changes until the key says custom)', templateOf(cfg()) === 'standard');
check('"standard" and "custom" are read as they are', templateOf(cfg({ template: 'standard' })) === 'standard' && templateOf(cfg({ template: 'custom' })) === 'custom');
check('any other value is an error, not a silent standard', (() => { for (const v of ['Custom', true, 'patched', null, '']) { try { templateOf(cfg({ template: v })); return false; } catch (e) { if (!/"standard" or "custom"/.test(e.message)) return false; } } return true; })());

// the record
check('a complete record (URL, both hashes, size, parity, signature both modes, collapse both modes, a nightly on the pin) has no problem', recordProblems(good(), cfg(), CTX).length === 0, JSON.stringify(recordProblems(good(), cfg(), CTX)));
// the zip is published and pinned (Orb's yes to option (b), 2026-10-28): what the tree's record still lacks is readings, never the pin itself (URL, hashes, size, build)
{
  const real = JSON.parse(readFileSync(join(here, 'web-template.json'), 'utf8'));
  const left = recordProblems(real, cfg());
  check('the record in the tree pins the published zip (release URL, both SHA-512, size, build) and what "custom" is still refused for is a reading', /^https:\/\/github\.com\/[^/]+\/[^/]+\/releases\/download\/[^/]+\/web_nothreads_release\.zip$/.test(real.url) && SHA_HEX.test(real.sha512) && SHA_HEX.test(real.wasmSha512) && real.bytes === 9861157 && left.every((m) => /^measured\./.test(m)), JSON.stringify(left));
  check('the parity reading of the tree is the pinned zip own (it carries the SHA-512 of the zip); the other readings are not there yet or carry it too', real.measured.parity.template === real.sha512 && ['signature', 'collapse', 'nightly', 'frames'].every((k) => real.measured[k] === null || (real.measured[k] && real.measured[k].template === real.sha512)));
}
const bad = (what, rec, re, ctx = CTX) => { const p = recordProblems(rec, cfg(), ctx); check(`custom is refused when ${what}`, p.length > 0 && (!re || p.some((m) => re.test(m))), JSON.stringify(p)); };
bad('there is no record', null, /missing or unreadable/);
bad('the template is not published (no URL)', good({ url: null }), /not published/);
bad('the URL is not a github.com release asset', good({ url: 'https://example.com/web.zip' }), /release asset URL/);
bad('the URL is http, not https', good({ url: 'http://github.com/o/r/releases/download/t/f.zip' }), /release asset URL/);
bad('the zip has no SHA-512', good({ sha512: null }), /SHA-512 of the zip/);
bad('the SHA-512 is short', good({ sha512: 'abc' }), /SHA-512 of the zip/);
bad('the wasm has no SHA-512', good({ wasmSha512: undefined }), /godot\.wasm/);
bad('the size is missing', good({ bytes: 0 }), /byte size/);
bad('parity is not measured', good({ measured: { ...good().measured, parity: null } }), /parity/);
bad('parity matched fewer keys than it has', good({ measured: { ...good().measured, parity: { keys: 51, match: 50 } } }), /parity/);
bad('the signature clip has one mode only', good({ measured: { ...good().measured, signature: { reduced: good().measured.signature.reduced } } }), /both modes/);
bad('signature reduced reads 3 on the primary (worse than 2.5)', good({ measured: { ...good().measured, signature: { ...good().measured.signature, reduced: { primary: 3, area15: 3, twoSec: 2 } } } }), /worse than 2\.5/);
bad('signature reduced reads 3.5 on the area reading', good({ measured: { ...good().measured, signature: { ...good().measured.signature, reduced: { primary: 2.5, area15: 3.5, twoSec: 2 } } } }), /worse than 2\.5/);
bad('signature reduced reads 2.5 on the two-second memory', good({ measured: { ...good().measured, signature: { ...good().measured.signature, reduced: { primary: 2.5, area15: 3, twoSec: 2.5 } } } }), /worse than 2\.5/);
bad('the collapse clip is not measured', good({ measured: { ...good().measured, collapse: null } }), /collapse/);
bad('there is no nightly', good({ measured: { ...good().measured, nightly: null } }), /nightly is missing/);
bad('the nightly was run on another commit than the pin', good({ measured: { ...good().measured, nightly: { ...good().measured.nightly, commit: 'b'.repeat(40) } } }), /re-run the nightly on the pin/);
bad('the nightly has a clip over the limit', good({ measured: { ...good().measured, nightly: { ...good().measured.nightly, over: [{ id: 'ai-1001-normal' }] } } }), /over the limit/);
bad('the nightly has a clip missing', good({ measured: { ...good().measured, nightly: { ...good().measured.nightly, missing: ['ai-1000-reduced'] } } }), /missing/);
const M = (over) => ({ ...good().measured, ...over });
bad('the frame comparison is missing (RL-199 item 1)', good({ measured: M({ frames: null }) }), /measured\.frames is missing/);
bad('the frame comparison has no frames in it', good({ measured: M({ frames: { ...good().measured.frames, frames: 0 } }) }), /measured\.frames is missing/);
bad('the frame comparison is of another commit than the pin', good({ measured: M({ frames: { ...good().measured.frames, commit: 'b'.repeat(40) } }) }), /compare the clips of the pinned commit/);
bad('a frame differs beyond noise and there is no full set', good({ measured: M({ frames: { ...good().measured.frames, beyondNoise: 2 } }) }), /beyond noise: the full required set must be run/);
check('a frame beyond noise is allowed once the full set is recorded, passing, on the pin and on this zip', recordProblems(good({ measured: M({ frames: { ...good().measured.frames, beyondNoise: 2 }, full: { commit: PIN, clips: 76, pass: 76, template: sha512(ZIP) } }) }), cfg(), CTX).length === 0, JSON.stringify(recordProblems(good({ measured: M({ frames: { ...good().measured.frames, beyondNoise: 2 }, full: { commit: PIN, clips: 76, pass: 76, template: sha512(ZIP) } }) }), cfg(), CTX)));
bad('a frame differs beyond noise and the full set has a failing clip', good({ measured: M({ frames: { ...good().measured.frames, beyondNoise: 1 }, full: { commit: PIN, clips: 76, pass: 74, template: sha512(ZIP) } }) }), /full is not a complete passing set/);
bad('the full set was run on another commit', good({ measured: M({ full: { commit: 'c'.repeat(40), clips: 76, pass: 76, template: sha512(ZIP) } }) }), /full is not a complete passing set/);
bad('the build is not pinned (no flags, source, emscripten or patches)', good({ build: null }), /does not pin the build/);
bad('the build pin has no flags', good({ build: { ...good().build, flags: '' } }), /does not pin the build/);
bad('the workflow builds with other flags than the pin (a module on or off)', good(), /build flags changed since the pin/, { ...CTX, workflow: WF.replace('lto=none', 'lto=none module_jolt_physics_enabled=no') });
bad('the workflow builds with other flags (a compression or optimisation change)', good(), /build flags changed since the pin/, { ...CTX, workflow: WF.replace('optimize=size', 'optimize=speed') });
check('extra flags after the pinned base flags are part of the pin and do not trip the workflow comparison', recordProblems(good({ build: { ...good().build, flags: BUILD_FLAGS + ' module_jolt_physics_enabled=no' } }), cfg(), CTX).length === 0);
bad('the Godot source of the build changed', good(), /source of the build changed/, { ...CTX, workflow: WF.replace(SRC512, 'e'.repeat(128)) });
bad('the Emscripten version changed', good(), /Emscripten version of the build changed/, { ...CTX, workflow: WF.replace('4.0.11', '4.0.20') });
bad('an engine patch changed since the pin', good(), /patch 4\.7\.2-p changed/, { ...CTX, patches: { '4.7.2-p': Buffer.from('another patch') } });
bad('an engine patch was added that the pin does not know', good(), /patch 4\.7\.2-q is not pinned/, { ...CTX, patches: { ...CTX.patches, '4.7.2-q': Buffer.from('q') } });
bad('an engine patch of the pin is gone', good(), /patch 4\.7\.2-p is gone/, { ...CTX, patches: {} });
check('without the workflow and patches to read (a test) only the record\'s own completeness is checked', recordProblems(good(), cfg(), null).length === 0);
bad('a measurement was taken on another zip (parity)', good({ measured: M({ parity: { keys: 51, match: 51, template: 'd'.repeat(128) } }) }), /measured\.parity was not taken on this zip/);
bad('a measurement carries no zip at all (signature)', good({ measured: M({ signature: { ...good().measured.signature, template: undefined } }) }), /measured\.signature was not taken on this zip.*not recorded/);
bad('the zip was replaced (a new SHA-512) and the readings were not retaken', { ...good(), sha512: 'a'.repeat(128) }, /was not taken on this zip/);
check('the limits are the signature pin\'s (2.5 / 3 / 2)', REDUCED_MAX.primary === 2.5 && REDUCED_MAX.area15 === 3 && REDUCED_MAX.twoSec === 2);

// the zip
check('readZipEntry reads a deflated entry, a stored one, and says null for a name that is not there', readZipEntry(ZIP, 'godot.wasm').equals(WASM) && readZipEntry(ZIP, 'godot.audio.worklet.js').toString() === 'w' && readZipEntry(ZIP, 'nope') === null);
check('readZipEntry says null for bytes that are not a zip', readZipEntry(Buffer.from('not a zip at all'), 'godot.wasm') === null);

// the download: a local server stands in for the release; curl is what the site job uses. The server is a CHILD process (the download is a synchronous curl: a server in this process would never answer it).
const tmp = mkdtempSync(join(tmpdir(), 'site-template-'));
mkdirSync(join(tmp, 'www'), { recursive: true });
writeFileSync(join(tmp, 'www', 'ok.zip'), ZIP);
writeFileSync(join(tmp, 'www', 'short.zip'), ZIP.subarray(0, ZIP.length - 5));
writeFileSync(join(tmp, 'www', 'other.zip'), makeZip([['godot.wasm', Buffer.from('another engine'), 'deflate']]));
writeFileSync(join(tmp, 'www', 'nowasm.zip'), makeZip([['godot.js', Buffer.from('js'), 'deflate']]));
const srv = spawn(process.execPath, ['-e', "const http = require('http'), fs = require('fs'), p = require('path'); const root = process.argv[1]; http.createServer((q, s) => { const f = p.join(root, p.basename(q.url)); if (fs.existsSync(f)) { s.writeHead(200); s.end(fs.readFileSync(f)); } else { s.writeHead(404); s.end('no'); } }).listen(0, '127.0.0.1', function () { console.log('PORT ' + this.address().port); });", join(tmp, 'www')], { stdio: ['ignore', 'pipe', 'inherit'] });
const port = await new Promise((ok, fail) => { srv.stdout.on('data', (d) => { const m = /PORT (\d+)/.exec(String(d)); if (m) ok(Number(m[1])); }); srv.on('error', fail); setTimeout(() => fail(new Error('the test server did not start')), 15000); });
const base = `http://127.0.0.1:${port}`;
try {
  const rec = (path, over = {}) => ({ ...good(), url: base + path, ...over });
  const throws = (fn, re) => { try { fn(); return false; } catch (e) { return re.test(e.message); } };
  const f1 = fetchTemplate(rec('/ok.zip'), join(tmp, 'd1'), { insecure: true });
  check('a download that matches the pin is written as web_nothreads_release.zip', existsSync(f1) && readFileSync(f1).equals(ZIP) && f1.endsWith('web_nothreads_release.zip'));
  check('a download with another SHA-512 is refused and removed', throws(() => fetchTemplate(rec('/other.zip', { bytes: undefined }), join(tmp, 'd2'), { insecure: true }), /not the pinned one: its SHA-512/) && !existsSync(join(tmp, 'd2', 'web_nothreads_release.zip')));
  check('a download of the wrong size is refused', throws(() => fetchTemplate(rec('/short.zip'), join(tmp, 'd3'), { insecure: true }), /size is/));
  check('a 404 is an error that names the URL', throws(() => fetchTemplate(rec('/gone.zip'), join(tmp, 'd4'), { insecure: true }), /could not fetch/));
  check('a zip with no godot.wasm of the pinned hash is refused even if its own SHA-512 were right', (() => { const z = makeZip([['godot.js', Buffer.from('js'), 'deflate']]); return throws(() => fetchTemplate({ ...rec('/nowasm.zip'), sha512: sha512(z), bytes: z.length }, join(tmp, 'd5'), { insecure: true }), /no godot\.wasm/); })());
  check('without the test switch only a github.com release URL is fetched', throws(() => fetchTemplate(rec('/ok.zip'), join(tmp, 'd6')), /no release asset URL/));
  check('templateFor: standard needs nothing and gives no file', templateFor(cfg(), null, join(tmp, 'd7')) === null && templateFor(cfg({ template: 'standard' }), { url: null }, join(tmp, 'd7')) === null);
  check('templateFor: custom with an incomplete record is an error, not a fallback to standard', throws(() => templateFor(cfg({ template: 'custom' }), { ...good(), url: null }, join(tmp, 'd8')), /not ready/));
  check('templateFor: custom with a record whose URL is not a github.com release asset is refused before any download', (() => { const g = good({ url: base + '/ok.zip' }); try { templateFor(cfg({ template: 'custom' }), g, join(tmp, 'd9')); return false; } catch (e) { return /not ready/.test(e.message); } })());

  // the Web preset of a scratch tree
  const WEB = '[preset.0]\n\nname="Web"\nplatform="Web"\n\n[preset.0.options]\n\ncustom_template/debug=""\ncustom_template/release=""\nvariant/extensions_support=false\n\n';
  const WIN = '[preset.1]\n\nname="Windows Desktop"\nplatform="Windows Desktop"\n\n[preset.1.options]\n\ncustom_template/debug=""\ncustom_template/release=""\n\n';
  const LIN = '[preset.2]\n\nname="Linux"\nplatform="Linux"\n\n[preset.2.options]\n\ncustom_template/release=""\n';
  const cfgText = WEB + WIN + LIN;
  const out = setWebCustomTemplate(cfgText, 'C:\\t\\web_nothreads_release.zip');
  check('the Web preset\'s custom_template/release is set (backslashes become forward slashes)', out.includes('[preset.0.options]\n\ncustom_template/debug=""\ncustom_template/release="C:/t/web_nothreads_release.zip"\nvariant/extensions_support=false'));
  check('the Windows and Linux presets are left as they were', out.includes(WIN) && out.includes(LIN));
  check('setting it twice gives the same file', setWebCustomTemplate(out, 'C:\\t\\web_nothreads_release.zip') === out);
  check('a Web options section with no such key gets one', setWebCustomTemplate(WEB.replace('custom_template/release=""\n', '') + WIN, '/z.zip').includes('custom_template/release="/z.zip"\nvariant/extensions_support=false') || setWebCustomTemplate(WEB.replace('custom_template/release=""\n', '') + WIN, '/z.zip').includes('custom_template/release="/z.zip"'));
  check('line endings are kept', setWebCustomTemplate(cfgText.replace(/\n/g, '\r\n'), '/z.zip').includes('custom_template/release="/z.zip"\r\n') && !/[^\r]\n/.test(setWebCustomTemplate(cfgText.replace(/\n/g, '\r\n'), '/z.zip')));
  check('a file with no Web preset is returned unchanged', setWebCustomTemplate(WIN + LIN, '/z.zip') === WIN + LIN);
  check('it is a change of the Web block (RL-197): only ever made in a scratch tree, never in the committed preset', webPresetChanged(cfgText, out));

  // the scratch tree of an export: template given, null, and (a throwaway repo) not read from the real site.json
  const repo = join(tmp, 'repo');
  const git = (...a) => execFileSync('git', ['-c', 'user.name=t', '-c', 'user.email=t@t', '-c', 'commit.gpgsign=false', ...a], { cwd: repo, encoding: 'utf8' }).trim();
  mkdirSync(repo, { recursive: true });
  git('init', '-q');
  writeFileSync(join(repo, 'project.godot'), 'config/name="x"');
  writeFileSync(join(repo, 'export_presets.cfg'), cfgText);
  git('add', '-A'); git('commit', '-q', '-m', 'one');
  const C = git('rev-parse', 'HEAD');
  const stub = join(tmp, 'stub-godot.mjs');
  writeFileSync(stub, "import { mkdirSync, writeFileSync } from 'node:fs'; import { dirname } from 'node:path'; const a = process.argv.slice(2); const ex = a.indexOf('--export-release'); if (ex < 0) process.exit(0); mkdirSync(dirname(a[ex + 2]), { recursive: true }); writeFileSync(a[ex + 2], '<!doctype html>');\n");
  const T = join(tmp, 'zip', 'web_nothreads_release.zip');
  exportPinned(C, join(tmp, 'w1'), { repo, tree: join(tmp, 't1'), godotNode: stub, template: T });
  check('an export with a template writes its path into the scratch tree\'s Web preset only', readFileSync(join(tmp, 't1', 'export_presets.cfg'), 'utf8').replace(/\r\n/g, '\n') === setWebCustomTemplate(cfgText, T));
  exportPinned(C, join(tmp, 'w2'), { repo, tree: join(tmp, 't2'), godotNode: stub, template: null });
  check('an export with template null is the committed preset, as ever', readFileSync(join(tmp, 't2', 'export_presets.cfg'), 'utf8').replace(/\r\n/g, '\n') === cfgText);
  exportPinned(C, join(tmp, 'w3'), { repo, tree: join(tmp, 't3'), godotNode: stub });
  check('an export from a throwaway repo never reads the real tools/site.json', readFileSync(join(tmp, 't3', 'export_presets.cfg'), 'utf8').replace(/\r\n/g, '\n') === cfgText);
  check('the committed export_presets.cfg of this repository has no custom template path in any preset', !/custom_template\/(release|debug)="[^"]+"/.test(readFileSync(join(here, '..', 'export_presets.cfg'), 'utf8')));

  // the built site's engine
  const site = (wasm) => { const d = mkdtempSync(join(tmp, 'site-')); mkdirSync(join(d, 'play'), { recursive: true }); if (wasm) writeFileSync(join(d, 'play', 'index.wasm'), wasm); return d; };
  check('custom: a site whose index.wasm is the pinned godot.wasm passes', siteWasmProblems(cfg({ template: 'custom' }), good(), site(WASM)).length === 0);
  check('custom: a site with another engine fails', /not the pinned custom template/.test(siteWasmProblems(cfg({ template: 'custom' }), good(), site(Buffer.from('standard engine'))).join()));
  check('standard: a site with the standard engine passes', siteWasmProblems(cfg(), good(), site(Buffer.from('standard engine'))).length === 0);
  check('standard: a site that carries the custom engine fails (the switch says standard)', /says "standard"/.test(siteWasmProblems(cfg(), good(), site(WASM)).join()));
  check('a site with no play/index.wasm fails', /no play\/index\.wasm/.test(siteWasmProblems(cfg(), good(), site(null)).join()));

  // the command
  // a repo root with the workflow and the engine patch the good record pins (the command reads them from the real repository otherwise)
  const root = join(tmp, 'root');
  mkdirSync(join(root, '.github', 'workflows'), { recursive: true }); mkdirSync(join(root, 'tools', 'engine', 'patches'), { recursive: true });
  writeFileSync(join(root, '.github', 'workflows', 'web-template.yml'), WF); writeFileSync(join(root, 'tools', 'engine', 'patches', '4.7.2-p.patch'), PATCH);
  const run = (args) => spawnSync(process.execPath, [join(here, 'site-template.mjs'), ...args, '--root', root], { encoding: 'utf8' });
  const cf = (c) => { const f = join(tmp, `c-${Math.random().toString(36).slice(2)}.json`); writeFileSync(f, JSON.stringify(c)); return f; };
  const rf = (r) => { const f = join(tmp, `r-${Math.random().toString(36).slice(2)}.json`); writeFileSync(f, JSON.stringify(r)); return f; };
  check('--check: standard passes with an empty record', run(['--check', '--config', cf(cfg()), '--record', rf({ url: null })]).status === 0);
  check('--check: custom with an incomplete record fails and says why', (() => { const r = run(['--check', '--config', cf(cfg({ template: 'custom' })), '--record', rf({ url: null })]); return r.status === 1 && /not published/.test(r.stderr); })());
  check('--check: custom with a complete record passes', run(['--check', '--config', cf(cfg({ template: 'custom' })), '--record', rf(good())]).status === 0);
  check('--check: an unknown value of "template" fails', run(['--check', '--config', cf(cfg({ template: 'x' })), '--record', rf(good())]).status === 1);
  check('--check --site: custom with the wrong engine fails', run(['--check', '--config', cf(cfg({ template: 'custom' })), '--record', rf(good()), '--site', site(Buffer.from('standard engine'))]).status === 1);
  check('--check --site: custom with the pinned engine passes', run(['--check', '--config', cf(cfg({ template: 'custom' })), '--record', rf(good()), '--site', site(WASM)]).status === 0);
  check('--check --site: an offline site (no game, no wasm) is not compared', run(['--check', '--config', cf({ offline: true }), '--record', rf({ url: null }), '--site', site(null)]).status === 0);
  check('--fetch: standard prints nothing and exits 0', (() => { const r = run(['--fetch', join(tmp, 'f1'), '--config', cf(cfg()), '--record', rf(good())]); return r.status === 0 && r.stdout.trim() === ''; })());
  check('--download: a record with no release URL fails whatever the site says', run(['--download', join(tmp, 'dl1'), '--config', cf(cfg()), '--record', rf({ url: null })]).status === 1);
  check('--download: a URL that is not a github.com release asset is refused before anything is fetched', (() => { const r = run(['--download', join(tmp, 'dl2'), '--record', rf(good({ url: 'http://evil.example/x.zip' }))]); return r.status === 1 && /no release asset URL/.test(r.stderr) && !existsSync(join(tmp, 'dl2')); })());
  check('--fetch: custom with an incomplete record fails', run(['--fetch', join(tmp, 'f2'), '--config', cf(cfg({ template: 'custom' })), '--record', rf({ url: null })]).status === 1);
} finally {
  srv.kill();
  rmSync(tmp, { recursive: true, force: true });
}
void dirname;
console.log(failed ? `site template self-test FAILED: ${failed} of ${ran}` : `site template self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
