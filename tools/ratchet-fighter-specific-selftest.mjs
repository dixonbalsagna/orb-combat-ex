// Self-test of tools/ratchet-fighter-specific.mjs (A-ENERGY-06): what is counted (a fighter's id as a whole word, in code, in the files a system lists), what is not (comments, other words, files of no system),
// the globs, the ratchet's own baseline file, on a throwaway tree. Node built-ins only. CI runs it.
//   node tools/ratchet-fighter-specific-selftest.mjs
import { execFileSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { codeOf, count, countIn, elsewhere, expand, namesOf } from './ratchet-fighter-specific.mjs';

const here = dirname(fileURLToPath(import.meta.url));
let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };

check('a comment is not code: the text from # on is dropped, a # inside a string is kept', countIn('x = 1  # RIVAL here\nif id == "PROTAGONIST":   # and here\n\ty = "a#b RIVAL"', ['RIVAL', 'PROTAGONIST']) === 2);
check('a name counts only as a whole word', countIn('var RIVALS = 1\nvar SUPERRIVAL = 2\nvar x = RIVAL', ['RIVAL']) === 1);
check('a name in a doc comment line is not counted', countIn('## The PROTAGONIST steps\nvar a = 1', ['PROTAGONIST']) === 0);
check('codeOf keeps the code before a comment and the quote state across an escaped quote', codeOf('a = "x\\"#y"  # c').includes('"x\\"#y"') && !codeOf('a = "x\\"#y"  # c').includes('# c'));
check('no names means no count', countIn('RIVAL', []) === 0);

const d = mkdtempSync(join(tmpdir(), 'rfs-'));
try {
  const put = (p, t) => { mkdirSync(dirname(join(d, p)), { recursive: true }); writeFileSync(join(d, p), t); };
  put('data/fighters/roster.json', '["PROTAGONIST", "RIVAL"]');
  put('sim/core/power.gd', 'func f(id):\n\tif id == "PROTAGONIST":\n\t\treturn 1\n\treturn KAI\n');
  put('sim/director/beam.gd', 'var a = "RIVAL"  # RIVAL\n');
  put('sim/director/beamplay.gd', 'var b = RIVAL\nvar c = RIVAL\n');
  put('sim/core/forms.gd', '# PROTAGONIST\nvar z = 0\n');
  put('sim/core/other.gd', 'var o = "RIVAL"\n');
  put('sim/core/tools/x_check.gd', 'var t = "RIVAL"\n');
  const names = namesOf(d);
  check('the names are the roster ids plus the old placeholders', names.includes('PROTAGONIST') && names.includes('RIVAL') && names.includes('KAI') && names.includes('VORR'));
  check('a glob stands for the files with that prefix in that folder, a missing file is skipped', expand(d, ['sim/director/beam*.gd', 'sim/core/gone.gd', 'sim/core/power.gd']).join() === 'sim/director/beam.gd,sim/director/beamplay.gd,sim/core/power.gd');
  const systems = { energy: ['sim/core/power.gd', 'sim/director/beam*.gd'], stamina: [], forms: ['sim/core/forms.gd'] };
  const c = count(d, systems);
  check('the count by system and in all: power 2 (a string and a placeholder), the beams 3 (a comment is not counted), forms 0 (a comment), stamina 0', c.bySystem.energy === 5 && c.bySystem.stamina === 0 && c.bySystem.forms === 0 && c.total === 5, JSON.stringify(c));
  const e = elsewhere(d, systems);
  check('outside the systems: the other shipped file counts, a check script does not', e.total === 1 && e.files['sim/core/other.gd'] === 1 && !e.files['sim/core/tools/x_check.gd'], JSON.stringify(e));
  const base = JSON.parse(readFileSync(join(here, 'ratchet-fighter-specific.json'), 'utf8'));
  check('the baseline file names the four systems, an empty stamina list and a total that is the sum of its systems', ['energy', 'stamina', 'body', 'forms'].every((k) => k in base.systems) && base.systems.stamina.length === 0 && base.total === Object.values(base.bySystem).reduce((a, b) => a + b, 0));
  const run = (...a) => { try { return { code: 0, out: execFileSync(process.execPath, [join(here, 'ratchet-fighter-specific.mjs'), ...a], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }) }; } catch (e2) { return { code: e2.status, out: String(e2.stdout) + String(e2.stderr) }; } };
  const cur = run();
  check('the check on the repository passes at the baseline and says the count', cur.code === 0 && /fighter-specific code: \d+ places/.test(cur.out), cur.out);
} finally { rmSync(d, { recursive: true, force: true }); }

console.log(failed ? `ratchet-fighter-specific self-test: ${failed} of ${ran} FAILED` : `ratchet-fighter-specific self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
