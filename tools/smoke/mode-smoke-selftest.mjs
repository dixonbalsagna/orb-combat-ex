// Self-test of the mode smoke's runner (pure parts: reading a result, the isolated environment). A-MODES-08, Tools.  node tools/smoke/mode-smoke-selftest.mjs
import { readResult, isolatedEnv } from './mode-smoke.mjs';
let bad = 0, n = 0;
const check = (name, ok) => { n++; if (!ok) { bad++; console.log('FAIL ' + name); } };
const good = { mode: 'solo', pass: true, steps: [{ name: 'a', ok: true, detail: '' }, { name: "the start menu has a 'quit' row (not built)", ok: true, detail: 'not built' }] };
let r = readResult(good, 'solo');
check('a clean result passes', r.ok && !r.failed.length);
check('a row that is not built is listed, not failed', r.notBuilt.length === 1);
r = readResult({ ...good, steps: [...good.steps, { name: 'b', ok: false, detail: '' }], pass: false }, 'solo');
check('a failed step fails the run and is named', !r.ok && r.failed.join() === 'b');
check('a pass flag that is not true fails', !readResult({ ...good, pass: false }, 'solo').ok);
check('the wrong mode fails', !readResult(good, 'two').ok);
check('a result with no steps fails', !readResult({ mode: 'solo', pass: true, steps: [] }, 'solo').ok);
check('a run that stopped before the quit row fails', !readResult({ mode: 'solo', pass: true, steps: [{ name: 'a', ok: true }] }, 'solo').ok);
check('no document fails', !readResult(null, 'solo').ok);
const env = isolatedEnv({ APPDATA: 'real', HOME: 'real', X: '1' }, '/tmp/x');
check('the data folders are moved off the real ones', !Object.values({ a: env.APPDATA, b: env.HOME, c: env.XDG_DATA_HOME, d: env.LOCALAPPDATA }).some((v) => v === 'real') && env.X === '1');
console.log(`mode-smoke-selftest: ${n} checks, ${bad} failed`);
process.exit(bad ? 1 : 0);
