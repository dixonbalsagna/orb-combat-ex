// Self-test of the pure parts of tools/first-run/first-run.mjs (Tools, 2026-11-23). node tools/first-run/first-run-selftest.mjs
// What it cannot test: the window half (window.ps1 against a game window), which is unproven until the first click. It checks that the file parses, that every key the steps use is one the helper knows, and that
// the script never presses through the flashing-effects warning (no key step before the human step, no bypass word on the command line).
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { xdotoolKeys, refusal, timeline, ownLines, dataFiles, matchInData } from './linux-numbers.mjs';
import { parseFps, fpsStats, parseLoad, sizesFor, stepProblems, reportText, ownProfile } from './first-run.mjs';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
const HERE = dirname(fileURLToPath(import.meta.url));
let bad = 0, n = 0;
const check = (name, ok, extra) => { n++; if (!ok) { bad++; console.log(`FAIL ${name}${extra ? ': ' + extra : ''}`); } };

const out = ['Requested V-Sync mode: Enabled', 'Project FPS: 7 (142.85 mspf)', 'Project FPS: 23 (43.47 mspf)', 'Project FPS: 99 (10.10 mspf)', 'pair bake: 244 ms, 1084 poses', 'pair bake incremental: 1090 poses queued, 6 baked on demand, drained at tick 108', ...Array(10).fill('Project FPS: 100 (10.00 mspf)')].join('\n');
const rows = parseFps(out);
check('the frame-rate lines are read, in order', rows.length === 13 && rows[0].fps === 7 && rows[2].mspf === 10.1);
const st = fpsStats(rows, 3);
check('the steady figures skip the load seconds and the settle time is the first second at 80% of steady', st.steadySeconds === 10 && st.median === 100 && st.mean === 100 && st.settledAtS === 2 && st.min === 100 && st.over60 === 1, JSON.stringify(st));
const st2 = fpsStats([{ fps: 10 }, { fps: 50 }, { fps: 20 }, { fps: 61 }, { fps: 59 }], 1);
check('the shares at 30 and at 58 frames a second', st2.over30 === 0.75 && st2.over60 === 0.5, JSON.stringify(st2));
check('no frame-rate lines gives empty figures, not zeros', fpsStats([], 3).mean === null && fpsStats([], 3).settledAtS === null);
const ld = parseLoad(out);
check('the pair bake and the drained tick are read', ld.pairBakeMs === 244 && ld.poses === 1084 && ld.drainedAtTick === 108);
check('a missing load line is null', parseLoad('nothing').pairBakeMs === null);

const table = JSON.parse(readFileSync(join(HERE, 'sizes.json'), 'utf8'));
const all = sizesFor(table, 'all');
check('every size is a row of the table; default and medium have arguments, small and big wait until they are offered', all.length === 4 && ['default', 'medium'].every((n) => Array.isArray(all.find((s) => s.name === n).args)) && ['small', 'big'].every((n) => { const s = all.find((x) => x.name === n); return s.args === null && /only medium/.test(s.waiting); }), JSON.stringify(all));
{
  const sizesData = JSON.parse(readFileSync(join(HERE, '..', '..', 'data', 'biomes', 'sizes.json'), 'utf8'));
  const offered = Object.keys(sizesData.sizes).filter((k) => sizesData.sizes[k].offered);
  check('the table agrees with the sizes the game offers: an offered size has arguments, a hidden one of these has none', ['small', 'medium', 'big'].every((n) => offered.includes(n) === Array.isArray(table.sizes[n].args)), 'offered: ' + offered.join());
}
{
  const base = mkdtempSync(join(tmpdir(), 'first-run-profile-'));
  const env = ownProfile(base);
  const read = (...p) => JSON.parse(readFileSync(join(...p, 'ui_prefs.json'), 'utf8'));
  const win = read(env.APPDATA, 'Godot', 'app_userdata', 'Orb Combat EX'), lin = read(env.XDG_DATA_HOME, 'godot', 'app_userdata', 'Orb Combat EX');
  const name = readFileSync(join(HERE, '..', '..', 'project.godot'), 'utf8').includes('config/name=' + String.fromCharCode(34) + 'Orb Combat EX' + String.fromCharCode(34));
  const key = readFileSync(join(HERE, '..', '..', 'ui', 'hud', 'ui_hud.gd'), 'utf8').includes('get_bool(' + String.fromCharCode(34) + 'howto_seen');
  check('the run gets its own settings with the card marked seen, in the folder the game uses on each platform, under the base given', win.howto_seen === true && lin.howto_seen === true && Object.keys(win).length === 1 && env.APPDATA.startsWith(base) && env.XDG_DATA_HOME.startsWith(base) && name && key);
  rmSync(base, { recursive: true, force: true });
  const sources = ['first-run.mjs', 'linux-numbers.mjs'].map((f) => readFileSync(join(HERE, f), 'utf8'));
  check('both scripts start the program with those settings', sources[0].includes('...ownProfile(profile)') && sources[1].includes('...profile }') && sources[1].includes('ownProfile(mkdtempSync('));
}
let threw = false; try { sizesFor(table, 'huge'); } catch { threw = true; }
check('a size that is not a row is refused', threw);
check('a comma list picks rows in order', sizesFor(table, 'medium, default').map((s) => s.name).join() === 'medium,default');

const steps = JSON.parse(readFileSync(join(HERE, 'steps.json'), 'utf8'));
check('the steps file has no problems', stepProblems(steps).length === 0, stepProblems(steps).join('; '));
check('a bad key, a repeated id and a step with no id are named', stepProblems({ steps: [{ id: 'a', keys: ['F13'] }, { id: 'a' }, {}] }).length === 3);
check('the flashing-effects warning is a person\'s step and comes first: no key is pressed before it', steps.steps[0].human && !(steps.steps[0].keys || []).length && steps.steps.findIndex((s) => (s.keys || []).length) > 0);
const src = readFileSync(join(HERE, 'first-run.mjs'), 'utf8');
check('no bypass word is put on the program\'s command line (a locked build honours none, and the warning must show)', !/['"`]--?(nonotice|flashcap|study|shot|bench)\b/.test(src.replace(/\/\/.*$/gm, '').replace(/`--frames=\$\{frames\}`/g, '')), 'a bypass word in the source');
check('the headless run is ended by --frames and nothing else; the window run is not given --frames', /headless \? \[`--frames=\$\{frames\}`\] : \[\]/.test(src));
const ps = readFileSync(join(HERE, 'window.ps1'), 'utf8');
check('the window helper knows every key the steps use', steps.steps.flatMap((s) => s.keys || []).every((k) => new RegExp(`\\b${k} = 0x`).test(ps)));
check('the helper names nothing but the process it is given (no process search by name, no kill)', !/Get-Process\s+-Name|Stop-Process|taskkill/i.test(ps));
const r = reportText({ date: '2026-11-23', build: { version: '0.1.1', commit: 'abc1234', date: '2026-11-23' }, machine: { cpu: 'A CPU', gpu: 'A GPU', ramGb: 32, os: 'Windows 11' }, window: '1280x720', runs: [
  { size: 'default', steps: [{ id: 'notice', what: 'w', ok: true, detail: 'the picture changed', still: '00.png' }, { id: 'pause', what: 'p', ok: false, detail: 'no still' }], fps: st, load: ld, loading: { firstPictureS: 4.2 }, closed: true, wallS: 100 },
  { size: 'medium', waiting: 'GW1c has not landed the planet sizes', steps: [] }] });
check('the report says what failed, what was waiting, and gives the numbers', /1 step\(s\) did not go as planned/.test(r) && /Not offered by this build/.test(r) && /4\.2 s/.test(r) && /FAILED: no still/.test(r) && /pair bake 244 ms/.test(r) && /closed: yes, by itself/.test(r), r);
check('a headless report says its frame rates are not a window\'s', /NOT a window's/.test(reportText({ date: 'd', build: {}, machine: { cpu: 'c', gpu: '', ramGb: 1, os: 'o' }, window: null, runs: [{ size: 'default', steps: [{ id: 'x', ok: null }], fps: st, load: ld, loading: {}, closed: true, wallS: 1, headless: true }] })));
const ln = readFileSync(join(HERE, 'linux-numbers.mjs'), 'utf8');
check('every key steps.json uses has an xdotool name', xdotoolKeys(steps.steps.flatMap((s) => s.keys || [])).every(Boolean) && xdotoolKeys(['ENTER', 'P', 'UP']).join() === 'Return,p,Up');
check('the Linux numbers script presses keys only on a CI runner with a virtual display the workflow started (RL-270: never on a person screen)', refusal({}) !== '' && refusal({ GITHUB_ACTIONS: 'true', DISPLAY: ':99' }) !== '' && refusal({ GITHUB_ACTIONS: 'true', DISPLAY: ':99', FIRST_RUN_VIRTUAL_DISPLAY: '1' }) === '' && refusal({ GITHUB_ACTIONS: 'true', FIRST_RUN_VIRTUAL_DISPLAY: '1' }) !== '' && refusal({ DISPLAY: ':0', FIRST_RUN_VIRTUAL_DISPLAY: '1' }) !== '');
check('it takes no still, video or capture, and adds no bypass word or flag to the program (RL-270 conditions 1 and 3)', !/import -window|xwd|scrot|ffmpeg|screenshot|--shot|--frames|--bench|nonotice|flashcap|study|get_image/i.test(ln.replace(/\/\/.*$/gm, '')));
check('the frame-rate timeline buckets by ten seconds', timeline(Array.from({ length: 25 }, (_, i) => ({ fps: i < 10 ? 2 : 20 })), 10).map((b) => b.mean).join() === '2,20,20' && timeline([], 10).length === 0);
const NLN = String.fromCharCode(10);
check("the program's own lines leave out the frame-rate line, cap the count and take folder paths out", ownLines(['Project FPS: 9 (1 mspf)', 'a line', 'at C:/Users/someone/x', ''].join(NLN)).length === 2 && !ownLines('at C:/Users/someone/x').join('').includes('someone') && ownLines(Array(100).fill('x').join(NLN), 40).length === 40);
check('a match shows in the data folder by a field cache or a report, and a bare data folder does not', matchInData([{ path: 'Orb Combat EX/field-cache/a.wfc', size: 1 }]) && matchInData([{ path: 'Orb Combat EX/reports/x.json', size: 1 }]) && !matchInData([{ path: 'Orb Combat EX/logs/godot.log', size: 1 }]) && !matchInData([]) && dataFiles('/no/such/folder').length === 0);
check('the keys closing the program is a row that can fail the run, and the window manager stays as the fallback that reports', ln.includes("add({ id: 'quit-keys'") && ln.includes('ok: keysClosed, detail') && !ln.includes('reported only') && ln.includes("press(['ALT_F4']") && ln.includes('process.exit(run.steps.some((s) => !s.ok) ? 1 : 0)'));
console.log(`first-run selftest: ${n} checks, ${bad} failed`);
process.exit(bad ? 1 : 0);
