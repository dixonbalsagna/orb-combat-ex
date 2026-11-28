// Exports a tiny project through the launcher (Tools, 2026-11-28; the EP: isolated exports came out empty, because the engine's templates live under the real APPDATA). Two runs: from this environment as it is,
// and from one whose data folders were moved already (a gate shell, or a hand isolation). Each must write a Web page with its engine and its pack, and the installed templates must be as they were.
//   node tools/godot-export-check.mjs [--require]     without the engine or its Web templates it says so and passes, unless --require
import { existsSync, mkdirSync, mkdtempSync, readdirSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { templatesDir, userdataEnv } from './lib/userdata.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REQUIRE = process.argv.includes('--require');
const skip = (why) => { console.log(`${REQUIRE ? 'FAIL' : 'skip'} export check: ${why}`); process.exit(REQUIRE ? 1 : 0); };
const fwd = (p) => p.split('\\').join('/');

const bash = process.platform === 'win32' ? ['C:/Program Files/Git/bin/bash.exe', 'C:/Program Files/Git/usr/bin/bash.exe'].find((p) => existsSync(p)) : '/bin/bash';
if (!bash) skip('no bash for the launcher');
const local = process.env.LOCALAPPDATA ? join(process.env.LOCALAPPDATA, 'Programs', 'Godot', '4.7.2', 'Godot_v4.7.2-stable_win64_console.exe') : '';
const godot = [process.env.ORB_GODOT_EXE, process.env.GODOT, local].find((p) => p && !/godot-run\.sh$/i.test(p) && existsSync(p))
  || (spawnSync(bash, ['-c', 'command -v godot'], { encoding: 'utf8' }).stdout || '').trim();
if (!godot) skip('no engine (set GODOT to the 4.7.2 build)');
const templates = templatesDir();
const web = templates && readdirSync(templates).some((v) => existsSync(join(templates, v, 'web_nothreads_release.zip')));
if (!web) skip('the Web export templates are not installed');
const listing = () => readdirSync(templates).flatMap((v) => readdirSync(join(templates, v)).map((f) => { const s = statSync(join(templates, v, f)); return `${v}/${f} ${s.size} ${Math.round(s.mtimeMs)}`; })).sort().join('\n');
const before = listing();

let failed = 0;
const check = (name, ok, extra) => { console.log(`${ok ? 'ok  ' : 'FAIL'} ${name}`); if (!ok) { failed++; if (extra) console.log(extra); } };
const dir = mkdtempSync(join(tmpdir(), 'export-check-'));
try {
  const tiny = join(dir, 'tiny');
  mkdirSync(tiny);
  writeFileSync(join(tiny, 'project.godot'), '[application]\nconfig/name="Tiny export check"\nrun/main_scene="res://m.tscn"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
  writeFileSync(join(tiny, 'm.tscn'), '[gd_scene format=3]\n\n[node name="M" type="Node"]\n');
  writeFileSync(join(tiny, 'export_presets.cfg'), '[preset.0]\nname="Web"\nplatform="Web"\nrunnable=true\nexport_filter="all_resources"\ninclude_filter=""\nexclude_filter=""\nexport_path=""\n[preset.0.options]\nvariant/thread_support=false\n');
  const run = (name, env) => {
    const out = join(dir, name);
    mkdirSync(out);
    const r = spawnSync(bash, [fwd(join(HERE, 'godot-run.sh')), '--fresh', '--path', fwd(tiny), '--export-release', 'Web', fwd(join(out, 'index.html'))],
      { encoding: 'utf8', timeout: 600000, env: { ...env, GODOT: '', ORB_GODOT_EXE: fwd(godot), ORB_RUN_DATA: fwd(join(dir, `data-${name}`)) } });
    const size = (f) => { try { return statSync(join(out, f)).size; } catch { return 0; } };
    return { ok: r.status === 0 && size('index.wasm') > 1e6 && size('index.pck') > 0 && size('index.html') > 0, say: `${r.status} wasm ${size('index.wasm')} pck ${size('index.pck')}\n${String(r.stderr || '').slice(-600)}` };
  };
  const a = run('plain', process.env);
  check('an export through the launcher writes the page, the engine and the pack', a.ok, a.say);
  const moved = userdataEnv(join(dir, 'empty'), { ...process.env, APPDATA: join(dir, 'nothing'), XDG_DATA_HOME: join(dir, 'nothing'), HOME: join(dir, 'nothing') });
  delete moved.ORB_TEMPLATES;
  const b = run('moved', moved);
  check('so does one from an environment whose data folders were moved already', b.ok, b.say);
  check('the installed templates are as they were (names, sizes, times)', listing() === before);
} finally { rmSync(dir, { recursive: true, force: true }); }
console.log(failed ? `EXPORT CHECK: ${failed} FAILED` : 'EXPORT CHECK: all ok');
process.exit(failed ? 1 : 0);
