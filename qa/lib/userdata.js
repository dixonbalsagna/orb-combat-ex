// Where a QA run's game writes (CLAUDE.md, machine discipline; docs/tools/godot-launcher.md). Every QA runner that starts the engine or a built program passes runEnv() to spawn, so no run touches a person's game data.
// The folders moved are Tools' list (tools/lib/userdata.mjs, the node side of tools/godot-run.sh).
// The data folder is a new one for each runner process, removed when it ends cleanly: World's planet caches are keyed by data, not code, so a folder kept across trees can answer with another tree's planet and hide the change under test.
// ORB_RUN_DATA names a folder to use and keep instead (the launcher's own override).
const fs = require('fs'), os = require('os'), path = require('path');
const { userdataEnv, USERDATA_VARS } = require('../../tools/lib/userdata.mjs');

let env = null;
const low = p => path.resolve(p).split('\\').join('/').toLowerCase() + '/';

function dataDir() {
  const named = process.env.ORB_RUN_DATA;
  if (!named) {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'orb-qa-data-'));
    process.on('exit', code => { if (code === 0) try { fs.rmSync(dir, { recursive: true, force: true }); } catch (e) { /* a child still holds a file; temp is cleared later */ } });
    return dir;
  }
  const dir = path.resolve(named);
  const real = [process.env.APPDATA && path.join(process.env.APPDATA, 'Godot'), path.join(process.env.XDG_DATA_HOME || path.join(os.homedir(), '.local', 'share'), 'godot')].filter(Boolean);
  if (!low(dir).includes('orb-run-data') && (low(dir).includes('/app_userdata/') || real.some(r => low(dir).startsWith(low(r))))) throw new Error('ORB_RUN_DATA is inside a real data folder: ' + dir);
  return dir;
}

function runEnv() {
  if (!env) {
    env = userdataEnv(dataDir());
    for (const k of USERDATA_VARS) fs.mkdirSync(env[k], { recursive: true });
  }
  return env;
}

// $GODOT or $ORB_GODOT_EXE may name the launcher for shell scripts; node starts the engine itself, so that value is passed over.
const engineFromEnv = () => [process.env.ORB_GODOT_EXE, process.env.GODOT].find(v => v && !/godot-run\.sh$/i.test(v)) || '';

module.exports = { runEnv, engineFromEnv };
