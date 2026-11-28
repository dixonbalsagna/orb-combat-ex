// The data-folder guard, read from project.godot (Tools, 2026-11-28). A run FROM THE PROJECT (the engine's editor build: every check, bench and headless run) keeps its data in "Orb Combat EX dev"; a built
// program (a player's: it has no "editor" feature) keeps it in "Orb Combat EX" as before. This holds the lines to that. CI.   node tools/userdata-guard-check.mjs [--self-test]
// tools/userdata/userdata_check.gd shows the same from inside the engine.
import { readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const REPO = resolve(fileURLToPath(new URL('..', import.meta.url)));
export const NAME = 'Orb Combat EX';
export const DEV_DIR = 'Godot/app_userdata/Orb Combat EX dev';

/** Problems with the two files' texts. Pure. */
export function guardProblems(project, presets) {
  const problems = [];
  const lines = project.split(/\r?\n/).map((l) => l.trim());
  const keys = (k) => lines.filter((l) => l.startsWith(k + '='));
  const one = (k, v) => { const h = keys(k); if (h.length !== 1 || h[0] !== `${k}=${v}`) problems.push(`project.godot needs exactly one line ${k}=${v}`); };
  one('config/name', `"${NAME}"`);
  one('config/use_custom_user_dir.editor', 'true');
  one('config/custom_user_dir_name.editor', `"${DEV_DIR}"`);
  // the player's side: no line without a feature, and no other feature's line, may move or rename a built program's folder
  for (const l of lines) {
    const m = l.match(/^config\/(use_custom_user_dir|custom_user_dir_name)(\.[A-Za-z0-9_]+)?=/);
    if (m && m[2] !== '.editor') problems.push(`project.godot: "${l}" would move a player's data folder: only the .editor lines may be there`);
  }
  for (const l of presets.split(/\r?\n/)) { const m = l.match(/^custom_features="([^"]*)"/); if (m && m[1].split(',').map((s) => s.trim()).includes('editor')) problems.push('export_presets.cfg: a preset adds the feature "editor": its program would use the dev folder'); }
  return problems;
}

function selfTest() {
  const good = ['[application]', `config/name="${NAME}"`, 'config/use_custom_user_dir.editor=true', `config/custom_user_dir_name.editor="${DEV_DIR}"`].join('\r\n');
  const rows = [
    ['the lines as they should be pass', guardProblems(good, 'custom_features=""').length === 0],
    ['a missing guard line is named', guardProblems(good.replace('config/use_custom_user_dir.editor=true', ''), '').length === 1],
    ['a line without .editor (it would move a player\'s folder) is refused', guardProblems(good + '\r\nconfig/use_custom_user_dir=true', '').length === 1],
    ['another feature\'s line is refused', guardProblems(good + '\r\nconfig/custom_user_dir_name.windows="x"', '').length === 1],
    ['a renamed game is refused (a player\'s saves would be left behind)', guardProblems(good.replace(`name="${NAME}"`, 'name="Other"'), '').length === 1],
    ['a preset with the editor feature is refused', guardProblems(good, 'custom_features="a, editor"').length === 1],
  ];
  const bad = rows.filter(([, ok]) => !ok);
  for (const [n] of bad) console.log('FAIL ' + n);
  console.log(bad.length ? `userdata guard self-test FAILED: ${bad.length} of ${rows.length}` : `userdata guard self-test ok: ${rows.length} checks`);
  process.exit(bad.length ? 1 : 0);
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  if (process.argv.includes('--self-test')) selfTest();
  const problems = guardProblems(readFileSync(join(REPO, 'project.godot'), 'utf8'), readFileSync(join(REPO, 'export_presets.cfg'), 'utf8'));
  for (const p of problems) console.error('userdata guard: ' + p);
  console.log(problems.length ? `userdata guard FAILED: ${problems.length} problem(s)` : 'userdata guard ok: runs from the project use the dev folder; a built program keeps "' + NAME + '"');
  process.exit(problems.length ? 1 : 0);
}
