// Self-test of tools/lint-godot-launch.mjs and of the launcher's own refusals and environment (no engine is started: a stand-in prints what it was given).   node tools/lint-godot-launch-selftest.mjs
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { judge, readScript } from './lint-godot-launch.mjs';
import { userdataEnv, USERDATA_VARS } from './lib/userdata.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`FAIL ${name}${extra ? ': ' + extra : ''}`); } };
const R = (n, t) => readScript(n, t);

check('shell starts are found: $G, $GODOT, the named exe, plain godot', ['"$G" --headless --path .', '"${GODOT}" -s x.gd', 'x=1; godot --headless', '"/c/G/Godot_v4.7.2-stable_win64_console.exe" --path .'].every((t) => R('a.sh', t).starts));
check('the engine\'s --headless as a word of its own is found in node, shell and PowerShell; a browser\'s --headless=new, a message and a look in a list are not', R('a.mjs', "const args = ['--headless', '--path', t]").starts && R('a.sh', '"$ENGINE" --headless -s x.gd').starts && R('a.ps1', "$a = @('--headless')").starts && !R('a.mjs', "const f = ['--headless=new'];\nconsole.log('run godot --headless --path .');\nif (a.includes('--headless')) n++;").starts);
check('a comment, a word and a variable alone are not starts', !R('a.sh', '# "$G" --headless\necho godot\nexport GODOT=$G').starts && !R('a.mjs', '// spawn(godot, [])\nconst godot = godotExe();').starts);
check('node starts are found: spawn(godot, ...), run(godot, ...), runGodot(...)', ['spawnSync(godot, a)', "await run(godot, ['--headless'])", 'await runGodot({ godot }, args)', 'spawn(process.env.GODOT, a)'].every((t) => R('a.mjs', t).starts), '');
check('PowerShell and python starts are found', R('a.ps1', '& $godot --headless').starts && R('a.ps1', 'Start-Process -FilePath $GodotExe').starts && R('a.py', 'subprocess.run([godot, "--headless"])').starts);
check('through the launcher: the shell names godot-run.sh; node imports userdata', R('a.sh', 'G="$R/tools/godot-run.sh"\n"$G" --path .').through && R('a.mjs', "import { userdataEnv } from './lib/userdata.mjs';\nspawn(godot, a, { env: userdataEnv(d) })").through && !R('a.sh', '# godot-run.sh\n"$G" --path .').through);
const QA = "const { runEnv } = require('./godot');\nconst p = guard(spawn(g.exe, ['--headless', '--path', ROOT], { env: runEnv() }));\n";
check('under qa/, every call that starts the engine must hand over QA\'s own environment', R('qa/godot/a.js', QA).starts && R('qa/godot/a.js', QA).through && !R('qa/godot/a.js', QA + "spawnSync(g.exe, ['--headless', '--path', ROOT], { encoding: 'utf8' });\n").through && !R('qa/godot/a.js', "const r = spawnSync(GODOT, args);\n").through && R('qa/godot/a.js', "spawnSync(GODOT, args);\n").starts);
check('the ratchet: a new offender fails, a baseline one passes, a fixed one is a note', judge(['tools/new.sh'], []).problems.length === 1 && judge(['a'], ['a']).problems.length === 0 && judge([], ['a']).notes.length === 1 && judge([], ['a']).problems.length === 0);
const e = userdataEnv('D', { PATH: 'p', APPDATA: 'real', USERPROFILE: 'real' });
check('userdataEnv moves every written folder and keeps the rest', e.PATH === 'p' && USERDATA_VARS.every((k) => e[k] && e[k].startsWith('D')));

// the launcher itself, with a stand-in engine that writes down its arguments and folders
const bash = process.platform === 'win32' ? ['C:/Program Files/Git/bin/bash.exe', 'C:/Program Files/Git/usr/bin/bash.exe'].find((p) => existsSync(p)) : '/bin/bash';
if (!bash) console.log('note: no bash found: the launcher itself was not run');
else {
  const dir = mkdtempSync(join(tmpdir(), 'launch-'));
  try {
    const fake = join(dir, 'fake-engine.sh');
    writeFileSync(fake, '#!/bin/bash\necho "ARGS $*"\necho "APPDATA $APPDATA"\necho "HOME $HOME"\necho "USERPROFILE $USERPROFILE"\necho "XDG $XDG_DATA_HOME"\nexit 7\n');
    chmodSync(fake, 0o755);
    const real = join(dir, 'realroaming');
    mkdirSync(join(real, 'Godot', 'app_userdata', 'Orb Combat EX'), { recursive: true });
    const fwd = (p) => p.split('\\').join('/');
    const tpl = join(dir, 'templates');   // a stand-in for the installed export templates, so no real one is linked by this test
    mkdirSync(join(tpl, '4.7.2.stable'), { recursive: true });
    writeFileSync(join(tpl, '4.7.2.stable', 'web_release.zip'), 'stand-in');
    const go = (args, env = {}) => spawnSync(bash, [fwd(join(HERE, 'godot-run.sh')), ...args], { encoding: 'utf8', env: { ...process.env, GODOT: '', APPDATA: real, ORB_TEMPLATES: fwd(tpl), ORB_FRESH: '', ORB_GODOT_EXE: fwd(fake), ORB_RUN_DATA: fwd(join(dir, 'data')), ...env } });
    const dataOf = (r) => (r.stdout.split(/\r?\n/).find((l) => l.startsWith('APPDATA ')) || '').slice(8);
    const a = go(['--path', '.', '--script', 'res://x.gd', '--', '--display-driver']);
    const line = (n) => (a.stdout.split(/\r?\n/).find((l) => l.startsWith(n + ' ')) || '').slice(n.length + 1);
    check('the engine gets --headless first and the arguments as given, and its exit code comes back', line('ARGS') === '--headless --path . --script res://x.gd -- --display-driver' && a.status === 7, `${a.status} ${a.stdout}${a.stderr}`);
    check('every written folder it is given is inside the scratch data folder, none the real one', ['APPDATA', 'HOME', 'USERPROFILE', 'XDG'].every((n) => /[\\/]data[\\/]/.test(line(n)) && !line(n).includes('realroaming')), a.stdout);
    check('--headless is not given twice', (go(['--headless', '--import']).stdout.match(/--headless/g) || []).length === 1);
    const inside = go(['--import'], { ORB_RUN_DATA: fwd(join(real, 'Godot', 'x')) });
    check('a data folder inside the real one is refused before anything is made there', inside.status === 2 && /inside a real data folder|app_userdata/.test(inside.stderr) && !existsSync(join(real, 'Godot', 'x')), inside.stderr);
    check('a display driver is refused (headless only)', go(['--display-driver', 'windows']).status === 2);
    check('--print-env moves only the two that decide user://', (() => { const o = go(['--print-env']).stdout; return /^export APPDATA='[^']*appdata' XDG_DATA_HOME='[^']*xdg'\s*$/.test(o); })(), go(['--print-env']).stdout);
    const placed = (root) => ['appdata/Godot', 'xdg/godot'].some((p) => existsSync(join(root, ...p.split('/'), 'export_templates', '4.7.2.stable', 'web_release.zip')));
    check('the installed templates are put into the run\'s data folder, where an engine under it looks', placed(join(dir, 'data')));
    check('a second launch from an environment already moved still finds them', go(['--path', '.', '--export-release', 'Web', 'x'], { APPDATA: fwd(join(dir, 'data', 'appdata')), XDG_DATA_HOME: fwd(join(dir, 'data', 'xdg')), ORB_RUN_DATA: fwd(join(dir, 'data2')), ORB_TEMPLATES: '' }).status === 7 && placed(join(dir, 'data2')));
    const f1 = dataOf(go(['--fresh', '--import'])), f2 = dataOf(go(['--fresh', '--import'])), f3 = dataOf(go(['--import'], { ORB_FRESH: '1' })), kept = dataOf(go(['--import']));
    check('--fresh (or ORB_FRESH=1) gives each run a new data folder of its own; without it the folder is kept', [f1, f2, f3].every((p) => /[\\/]data[\\/]fresh-[^\\/]+[\\/]appdata$/.test(p)) && new Set([f1, f2, f3]).size === 3 && /[\\/]data[\\/]appdata$/.test(kept), [f1, f2, f3, kept].join(' | '));
    check('--fresh --where names a folder and makes nothing', (() => { const w = go(['--fresh', '--where']).stdout.trim(); return /fresh-/.test(w) && !existsSync(w); })());
    check('the real folder was not touched', readFileSync(fake, 'utf8').length > 0 && existsSync(join(real, 'Godot', 'app_userdata', 'Orb Combat EX')));
  } finally { rmSync(dir, { recursive: true, force: true }); }
}
console.log(failed ? `godot launch self-test FAILED: ${failed} of ${ran}` : `godot launch self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
