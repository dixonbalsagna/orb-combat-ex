// Self-test of tools/preview/stack.mjs: the manifest, the owners, applying parks in order, the first conflict by file and owner, what is missing, the switches, validate, the error attribution, the key and the change
// report, and the whole run against a throwaway repository and a stand-in for Godot. Node built-ins and git only; no Godot, no browser.
import { createHash } from 'node:crypto';
import { execFileSync, spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { findPython, snapshotTree, loadManifest, patchFiles, ownerOfPath, readOwners, tryApply, applyStack, missingNeeds, flipAll, runValidate, attributeErrors, errorBlocks, stackKey, changesBetween, checkScratch, runStack, describeReport } from './stack.mjs';

const here = dirname(fileURLToPath(import.meta.url));
let failed = 0;
const check = (name, ok, detail) => { console.log(`${ok ? 'ok  ' : 'FAIL'} ${name}${ok || !detail ? '' : '\n     ' + detail}`); if (!ok) failed++; };

// ---- pure pieces
const good = { parks: [{ id: 'a', owner: 'x', steps: [{ patch: 'p.patch' }] }, { id: 'b', owner: 'y', steps: [{ overlay: ['sim'] }], needs: [{ park: 'a' }] }] };
check('a good manifest loads with no problems', loadManifest(JSON.stringify(good)).problems.length === 0);
const prob = (m) => loadManifest(JSON.stringify(m)).problems.join(' | ');
check('a park needs an id, an owner and steps, each step exactly one kind, and ids are unique', /needs an id/.test(prob({ parks: [{ owner: 'x', steps: [{ patch: 'a' }] }] })) && /needs an owner/.test(prob({ parks: [{ id: 'a', steps: [{ patch: 'a' }] }] })) && /needs steps/.test(prob({ parks: [{ id: 'a', owner: 'x' }] })) && /exactly one of/.test(prob({ parks: [{ id: 'a', owner: 'x', steps: [{ patch: 'a', copy: [] }] }] })) && /used twice/.test(prob({ parks: [good.parks[0], good.parks[0]] })));
check('a need on a park the manifest does not have, and malformed copy and overlay steps, are named', /not in the manifest/.test(prob({ parks: [{ id: 'a', owner: 'x', steps: [{ patch: 'a' }], needs: [{ park: 'zz' }] }] })) && /copy is a list/.test(prob({ parks: [{ id: 'a', owner: 'x', steps: [{ copy: [{ from: 'a' }] }] }] })) && /overlay is a list/.test(prob({ parks: [{ id: 'a', owner: 'x', steps: [{ overlay: [] }] }] })) && /not JSON/.test(loadManifest('{').problems.join()));
check('the files of a patch are its b sides, once each', patchFiles('diff --git a/x/a.gd b/x/a.gd\n--- a\n+++ b\ndiff --git a/x/a.gd b/x/a.gd\ndiff --git a/n.json b/n.json\nnew file mode 100644\n').join() === 'x/a.gd,n.json');
check('a plain unified diff (no diff --git lines) names its files by the +++ lines, and /dev/null is not one', patchFiles('--- a/x/a.gd\t2026\n+++ b/x/a.gd\t2026\n@@\n--- /dev/null\n+++ b/new.json\n--- a/gone\n+++ /dev/null\n').join() === 'x/a.gd,new.json');
const OW = { 'sim/': 'sim-owner', 'sim/input/': 'controls', 'docs/ui/': 'ui', 'tools': 'tools' };
check('a path\'s owner is the longest prefix of the charters\' owns lists', ownerOfPath('sim/input/x.gd', OW) === 'controls' && ownerOfPath('sim/core/x.gd', OW) === 'sim-owner' && ownerOfPath('docs/ui/p/x.md', OW) === 'ui' && ownerOfPath('tools/x.mjs', OW) === 'tools' && ownerOfPath('art/x', OW) === null);
check('the attribution of a log line reads its res:// file, the park that touched it and the file\'s owner', (() => { const a = attributeErrors(['SCRIPT ERROR: Parse Error: x', 'SCRIPT ERROR: bad at: GDScript::reload (res://sim/input/hub.gd:12)', 'ERROR: res://render/y.gd:3 oops'], new Map([['sim/input/hub.gd', 'controls-right-hand']]), { 'sim/': 'sim-owner', 'render/': 'rendering' }); return a[0].file === null && a[1].file === 'sim/input/hub.gd' && a[1].park === 'controls-right-hand' && a[1].fileOwner === 'sim-owner' && a[2].park === null && a[2].fileOwner === 'rendering'; })());
const rep0 = { firstConflict: null, parks: [{ id: 'a', status: 'applied' }], validate: { summary: { errors: 0, warnings: 0 } }, import: { ok: true, errors: [] }, smoke: { ok: true }, missing: {} };
const rep1 = { firstConflict: { park: 'b', file: 'f.gd', with: 'a', fileOwner: 'o', parkOwner: 'p' }, parks: [{ id: 'a', status: 'applied' }, { id: 'b', status: 'conflict' }], validate: { summary: { errors: 2, warnings: 0 } }, import: { ok: false, errors: [1] }, smoke: { ok: false, why: 'x' }, missing: { b: [1] } };
const ch = changesBetween(rep0, rep1);
check('what changed between two reports is the first conflict, each park, validate, import, the smoke match and the needs; the first run says so; no change is empty', ch.some((l) => /first conflict: none -> b: f\.gd \(with a; file owner o, park owner p\)/.test(l)) && ch.some((l) => /park b: new -> conflict/.test(l)) && ch.some((l) => /validate: 0 errors, 0 warnings -> 2 errors/.test(l)) && ch.some((l) => /import: clean -> 1 errors/.test(l)) && ch.some((l) => /smoke match: ok -> failed \(x\)/.test(l)) && ch.some((l) => /still need: 0 -> 1/.test(l) || /still need/.test(l)) && changesBetween(null, rep0)[0] === 'first run of this stack' && changesBetween(rep0, rep0).length === 0, JSON.stringify(ch));

// ---- a throwaway repository: two directors' folders, a data file, parks in the working tree
const tmp = mkdtempSync(join(tmpdir(), 'stack-selftest-'));
const git = (cwd, ...a) => execFileSync('git', ['-c', 'user.name=t', '-c', 'user.email=t@example.invalid', '-c', 'commit.gpgsign=false', '-c', 'core.autocrlf=false', ...a], { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
try {
  const repo = join(tmp, 'repo');
  const put = (f, text, base = repo) => { const p = join(base, ...f.split('/')); mkdirSync(dirname(p), { recursive: true }); writeFileSync(p, text); };
  git(tmp, 'init', '-q', repo);
  put('docs/directors/alpha.md', '# Alpha\n\nSession title: `A`  |  model: `m`  |  owns: `sim/alpha/, docs/alpha/`  |  kickoff: `/director alpha`\n');
  put('docs/directors/beta.md', '# Beta\n\nSession title: `B`  |  model: `m`  |  owns: `sim/beta/, docs/beta/`  |  kickoff: `/director beta`\n');
  put('sim/alpha/a.gd', 'one\ntwo\nthree\nfour\nfive\n');
  put('sim/beta/b.gd', 'b1\nb2\nb3\nb4\nb5\n');
  put('data/d.json', '{\n  "flag": false,\n  "n": 1\n}\n');
  put('sim/alpha/c.gd', 'c1\nc2\nc3\n');
  put('sim/gamma/g.gd', 'gamma\n');
  put('sim/world/field.gd', 'extends RefCounted\n');
  put('sim/world/swing.gd', 'class_name SimSwing\nextends RefCounted\n');   // the class the probe needs
  put('research/ring-any-angle/swing_smoke.gd.txt', 'extends SceneTree\n');   // Research\'s stand-in probe: copied into the scratch tree only
  put('.gitattributes', '* text=auto eol=lf\n');   // as the real repository has: an archive must not turn the fixture's lines into CRLF
  git(repo, 'add', '-A'); git(repo, 'commit', '-q', '-m', 'the fixture');
  const SHA = git(repo, 'rev-parse', 'HEAD').trim();
  // patches made by editing and diffing (then the edit is undone: the park is a file, not a change)
  const mk = (file, from, to, name) => { const p = join(repo, file); const old = readFileSync(p, 'utf8'); writeFileSync(p, old.replace(from, to)); const d = git(repo, 'diff', file); writeFileSync(p, old); put(name, d); return d; };
  mk('sim/alpha/a.gd', 'two', 'two (alpha)', 'docs/alpha/pending/p1.patch');
  mk('sim/alpha/a.gd', 'two', 'two (beta)', 'docs/beta/pending/p2.patch');
  mk('sim/beta/b.gd', 'b4', 'b4 (beta)', 'docs/beta/pending/p3.patch');
  put('docs/beta/pending/p3-again.patch', readFileSync(join(repo, 'docs/beta/pending/p3.patch'), 'utf8'));
  put('docs/beta/pending/stale.patch', 'diff --git a/sim/alpha/c.gd b/sim/alpha/c.gd\n--- a/sim/alpha/c.gd\n+++ b/sim/alpha/c.gd\n@@ -1,3 +1,3 @@\n c1\n-not what the file says\n+x\n c3\n');
  put('docs/alpha/pending/new.json', '{"k": 1}\n');
  put('sim/beta/over/o.gd', 'overlay file\n');
  put('sim/beta/over/sub/o2.gd', 'overlay file two\n');
  const park = (id, owner, steps, extra = {}) => ({ id, owner, steps, ...extra });
  const parks = [
    park('p-alpha', 'alpha', [{ patch: 'docs/alpha/pending/p1.patch' }]),
    park('p-beta-clash', 'beta', [{ patch: 'docs/beta/pending/p2.patch' }]),
    park('p-beta', 'beta', [{ patch: 'docs/beta/pending/p3.patch' }], { needs: [{ park: 'p-alpha' }, { park: 'p-beta-clash' }, { file: 'sim/beta/b.gd' }, { file: 'sim/beta/none.gd' }, { grep: { in: 'sim/beta/b.gd', text: 'b4 (beta)' } }, { grep: { in: 'sim/beta/b.gd', text: 'not there' }, owner: 'beta' }, { note: 'a hook', owner: 'alpha' }] }),
    park('p-landed', 'beta', [{ patch: 'docs/beta/pending/p3-again.patch' }]),
    park('p-stale', 'beta', [{ patch: 'docs/beta/pending/stale.patch' }]),
    park('p-copy', 'alpha', [{ copy: [{ from: 'docs/alpha/pending/new.json', to: 'data/new.json' }] }, { copy: [{ from: 'docs/alpha/pending/new.json', to: 'data/d.json' }] }]),
    park('p-copy-replace', 'alpha', [{ copy: [{ from: 'docs/alpha/pending/new.json', to: 'data/d.json', replace: true }] }]),
    park('p-overlay', 'beta', [{ overlay: ['sim/beta/over'] }]),
    park('p-overlay-same', 'beta', [{ overlay: ['sim/gamma'] }]),
    park('p-overlay-over-patch', 'beta', [{ overlay: ['sim/alpha'] }]),
    park('p-missing', 'beta', [{ patch: 'docs/beta/pending/nothing.patch' }]),
    park('p-manual', 'alpha', [{ manual: 'run the apply script by hand' }, { patch: 'docs/alpha/pending/p1.patch' }]),
  ];
  // an install script a park ships: python, standard library only, edits inside the tree it is given
  const PY = findPython();
  const script = [
    'import os, sys',
    'R = sys.argv[1]',
    'p = os.path.join(R, "sim/beta/b.gd")',
    's = open(p, encoding="utf-8", newline="").read()',
    'assert s.count("b2") == 1, ("sim/beta/b.gd", "b2", s.count("b2"))',
    'open(p, "w", encoding="utf-8", newline="").write(s.replace("b2", "b2 (installed)"))',
    'open(os.path.join(R, "sim/beta/installed.txt"), "w").write("yes")',
  ].join('\n') + '\n';
  put('docs/beta/pending/install.py', script);
  const sha1of = (text) => createHash('sha1').update(text).digest('hex');
  const failScript = script.replace('"b2"', '"zzz"').replace('"b2", s.count("b2")', '"zzz", s.count("zzz")');
  put('docs/beta/pending/install-fails.py', failScript);
  if (PY) {
    parks.push(park('p-script', 'beta', [{ script: 'docs/beta/pending/install.py', sha1: sha1of(script) }]));
    parks.push(park('p-script-changed', 'beta', [{ script: 'docs/beta/pending/install.py', sha1: 'a'.repeat(40) }]));
    parks.push(park('p-script-fails', 'beta', [{ script: 'docs/beta/pending/install-fails.py', sha1: sha1of(failScript) }]));
  }
  const man = loadManifest(JSON.stringify({ parks }));
  check('the fixture manifest is valid', man.problems.length === 0, man.problems.join(' | '));
  const owners = readOwners(join(repo, 'docs/directors'));
  check('the owners come from the charters\' owns lines', owners['sim/alpha/'] === 'alpha' && owners['docs/beta/'] === 'beta' && ownerOfPath('sim/beta/b.gd', owners) === 'beta');
  check('tryApply applies a patch, says "already" for one that reverses cleanly, and reports the file that does not apply', (() => {
    const d = mkdtempSync(join(tmpdir(), 'stack-try-')); put('sim/alpha/a.gd', 'one\ntwo\nthree\nfour\nfive\n', d);
    const p1 = readFileSync(join(repo, 'docs/alpha/pending/p1.patch'), 'utf8');
    const r1 = tryApply(d, p1), r2 = tryApply(d, p1), r3 = tryApply(d, readFileSync(join(repo, 'docs/beta/pending/p2.patch'), 'utf8'));
    const ok = r1.ok && !r1.already && readFileSync(join(d, 'sim/alpha/a.gd'), 'utf8').includes('two (alpha)') && r2.ok && r2.already && !r3.ok && r3.failedFiles[0] === 'sim/alpha/a.gd' && !existsSync(join(d, '.stack-step.patch'));
    rmSync(d, { recursive: true, force: true }); return ok;
  })());

  check('tryApply with an exclude leaves that file alone and applies the rest (two parks carrying one hunk), and lists only the files it changed', (() => {
    const d = mkdtempSync(join(tmpdir(), 'stack-excl-')); put('sim/alpha/a.gd', 'one\ntwo (beta)\nthree\nfour\nfive\n', d); put('sim/beta/b.gd', 'b1\nb2\nb3\nb4\nb5\n', d);
    const both = readFileSync(join(repo, 'docs/alpha/pending/p1.patch'), 'utf8') + readFileSync(join(repo, 'docs/beta/pending/p3.patch'), 'utf8');
    const plain = tryApply(d, both), cut = tryApply(d, both, ['sim/alpha/a.gd']);
    const ok = !plain.ok && cut.ok && cut.files.join() === 'sim/beta/b.gd' && readFileSync(join(d, 'sim/alpha/a.gd'), 'utf8').includes('two (beta)') && readFileSync(join(d, 'sim/beta/b.gd'), 'utf8').includes('b4 (beta)')
      && loadManifest(JSON.stringify({ parks: [{ id: 'q', owner: 'alpha', steps: [{ patch: 'x', exclude: ['a'] }] }] })).problems.some((p) => /says why/.test(p));
    rmSync(d, { recursive: true, force: true }); return ok;
  })());

  const tree = join(tmp, 'tree'); mkdirSync(tree);
  const ex = (await import('../flash/head-export.mjs')).exportRevision(repo, tree, SHA);
  check('the fixture exports', ex.ok, ex.message);
  const res = applyStack({ repo, tree, parks: man.parks, owners });
  const st = Object.fromEntries(res.parks.map((p) => [p.id, p.status]));
  check('parks apply in order: the first applies, the clashing one is a conflict and the stack goes on', st['p-alpha'] === 'applied' && st['p-beta-clash'] === 'conflict' && st['p-beta'] === 'applied', JSON.stringify(st));
  check('the FIRST CONFLICT names the park, the file, the park it clashes with and both owners', res.firstConflict && res.firstConflict.park === 'p-beta-clash' && res.firstConflict.file === 'sim/alpha/a.gd' && res.firstConflict.with === 'p-alpha' && res.firstConflict.fileOwner === 'alpha' && res.firstConflict.parkOwner === 'beta', JSON.stringify(res.firstConflict));
  check('a park already in the tree is landed, not a conflict', st['p-landed'] === 'landed');
  const stale = res.parks.find((p) => p.id === 'p-stale').steps[0];
  check('a stale park (HEAD moved) conflicts with the commit itself and names the file\'s owner', st['p-stale'] === 'conflict' && stale.conflict.with === 'HEAD' && stale.conflict.file === 'sim/alpha/c.gd' && stale.conflict.fileOwner === 'alpha', JSON.stringify(stale));
  const ovp = res.parks.find((p) => p.id === 'p-overlay-over-patch');
  check('an overlay that would overwrite a file an earlier park changed is a conflict with that park (it is not laid silently)', ovp.status === 'conflict' && ovp.steps[0].conflict.file === 'sim/alpha/a.gd' && ovp.steps[0].conflict.with === 'p-alpha' && ovp.steps[0].conflict.fileOwner === 'alpha', JSON.stringify(ovp.steps));
  check('a copy lands a new file; one onto a file that differs is a conflict unless it says replace', st['p-copy'] === 'conflict' && readFileSync(join(tree, 'data/new.json'), 'utf8').includes('"k"') && st['p-copy-replace'] === 'applied' && readFileSync(join(tree, 'data/d.json'), 'utf8').includes('"k"'));
  check('an overlay lays the working tree\'s folder over the commit (files in subfolders too); one that equals the commit counts as landed', st['p-overlay'] === 'applied' && readFileSync(join(tree, 'sim/beta/over/sub/o2.gd'), 'utf8').includes('two') && st['p-overlay-same'] === 'landed', JSON.stringify([st['p-overlay'], st['p-overlay-same'], res.parks.find((p) => p.id === 'p-overlay-same').steps, existsSync(join(tree, 'sim/gamma/g.gd')) ? JSON.stringify(readFileSync(join(tree, 'sim/gamma/g.gd'), 'utf8')) : 'absent', JSON.stringify(readFileSync(join(repo, 'sim/gamma/g.gd'), 'utf8'))]));
  check('a park whose file is not in the working tree is "missing", not a conflict', st['p-missing'] === 'missing' && res.parks.find((p) => p.id === 'p-missing').steps[0].state === 'missing');
  check('a manual step is listed and never run; the park\'s other steps still apply (here: already in the tree)', st['p-manual'] === 'landed' && res.parks.find((p) => p.id === 'p-manual').steps[0].state === 'manual');
  check('the files each park touched are recorded for attributing errors', res.touched.get('sim/alpha/a.gd') === 'p-alpha' && res.touched.get('sim/beta/b.gd') === (PY ? 'p-script' : 'p-beta') && res.touched.get('sim/beta/over/o.gd') === 'p-overlay');
  if (PY) {
    const ps = res.parks.find((p) => p.id === 'p-script');
    check('a reviewed install script runs on the scratch tree only and what it wrote is read back by comparing the tree before and after', st['p-script'] === 'applied' && readFileSync(join(tree, 'sim/beta/b.gd'), 'utf8').includes('b2 (installed)') && existsSync(join(tree, 'sim/beta/installed.txt')) && ps.files.includes('sim/beta/installed.txt') && ps.files.includes('sim/beta/b.gd') && res.touched.get('sim/beta/installed.txt') === 'p-script', JSON.stringify(ps));
    check('the repository\'s own copy of the file the script edited is untouched', !readFileSync(join(repo, 'sim/beta/b.gd'), 'utf8').includes('installed') && !existsSync(join(repo, 'sim/beta/installed.txt')));
    const pc = res.parks.find((p) => p.id === 'p-script-changed');
    check('a script that is not the file Tools reviewed (its hash differs) is NOT run: the park is "unreviewed" and says why', st['p-script-changed'] === 'unreviewed' && pc.steps[0].state === 'unreviewed' && /not the script Tools reviewed/.test(pc.steps[0].detail));
    const pf = res.parks.find((p) => p.id === 'p-script-fails');
    check('a script that stops (an assertion about a line it replaces) is a conflict naming the file, and the park is marked tainted', st['p-script-fails'] === 'conflict' && pf.steps[0].conflict.file === 'sim/beta/b.gd' && pf.tainted === true, JSON.stringify(pf.steps));
  }
  check('a manifest script step needs its path and the reviewed hash', /script is a path, and sha1/.test(prob({ parks: [{ id: 'a', owner: 'x', steps: [{ script: 'x.py' }] }] })) && /script is a path, and sha1/.test(prob({ parks: [{ id: 'a', owner: 'x', steps: [{ script: 'x.py', sha1: 'abc' }] }] })) && prob({ parks: [{ id: 'a', owner: 'x', steps: [{ script: 'x.py', sha1: 'a'.repeat(40) }] }] }) === '');
  check('snapshotTree lists every file with its time and size, so a change is a difference', (() => { const a = snapshotTree(tree); writeFileSync(join(tree, 'sim/gamma/g.gd'), 'changed!\n'); const b = snapshotTree(tree); return a.has('sim/gamma/g.gd') && a.get('sim/gamma/g.gd') !== b.get('sim/gamma/g.gd'); })());
  const miss = missingNeeds(man.parks, res, tree);
  const pb = (miss.get('p-beta') || []).map((m) => m.need);
  check('what a park needs that is missing: a park that conflicted, a file, a text, and a known gap (with its owner); what is there is not listed', pb.some((n) => /the park p-beta-clash/.test(n)) && pb.some((n) => n === 'sim/beta/none.gd') && pb.some((n) => /"not there" in sim\/beta\/b\.gd/.test(n)) && pb.includes('a hook') && !pb.includes('sim/beta/b.gd') && !pb.some((n) => /p-alpha/.test(n)) && (miss.get('p-beta').find((m) => m.need === 'a hook') || {}).owner === 'alpha', JSON.stringify(pb));

  // the switches
  const fa = flipAll(tree, [{ id: 'flag', file: 'data/d.json', path: ['flag'], from: false, to: true, what: 'x' }, { id: 'ghost', file: 'data/none.json', path: ['a'], from: 0, to: 1, what: 'x' }]);
  check('every switch whose key is in the tree is turned on and the rest wait; nothing is guessed', fa.on.includes('flag') === false /* data/d.json was replaced by the copy: no flag key */ && fa.waiting.some((w) => w.id === 'flag') && fa.waiting.some((w) => w.id === 'ghost') && fa.on.includes('gen3') /* a setup switch: on because the fixture has sim/world/field.gd */ && fa.waiting.some((w) => w.id === 'tiles'), JSON.stringify(fa));
  put('data/d.json', '{\n  "flag": false\n}\n', tree);
  const fb = flipAll(tree, [{ id: 'flag', file: 'data/d.json', path: ['flag'], from: false, to: true, what: 'x' }]);
  check('a switch in the tree is flipped in the scratch text', fb.on.includes('flag') && readFileSync(join(tree, 'data/d.json'), 'utf8').includes('"flag": true'));
  put('tools/validate.js', "console.log('error  data/d.json:2 /flag [type] flag must be a boolean'); console.log('warning  ui/x.json:1 /a [xref:r] note'); console.log('3 files checked, 1 errors, 1 warnings'); process.exit(1);\n", tree);
  const rv = runValidate(tree);
  check('validate is run in the scratch tree and its findings and count are read', rv.summary && rv.summary.errors === 1 && rv.summary.warnings === 1 && rv.findings.length === 2 && rv.findings[0].file === 'data/d.json' && rv.findings[0].rule === 'type');

  // the key, the scratch rule
  const k0 = stackKey(repo, SHA, man.parks);
  const k0b = stackKey(repo, SHA, man.parks.map((p) => ({ ...p })));
  put('docs/alpha/pending/p1.patch', readFileSync(join(repo, 'docs/alpha/pending/p1.patch'), 'utf8') + '\n');
  const k1 = stackKey(repo, SHA, man.parks);
  check('the key follows the commit and the bytes of every park file', k0 === k0b && k0 !== k1 && k1 !== stackKey(repo, 'f'.repeat(40), man.parks));
  put('docs/alpha/pending/p1.patch', readFileSync(join(repo, 'docs/alpha/pending/p1.patch'), 'utf8').trimEnd() + '\n');
  check('an edit of a park\'s manifest entry (its needs, notes, switches) changes the key too, not only its files', stackKey(repo, SHA, man.parks) !== stackKey(repo, SHA, man.parks.map((p, i) => (i === 0 ? { ...p, needs: [{ note: 'a new gap' }] } : p))));
  check('the scratch folder may not be the repository or inside it', (() => { const bad = (d) => { try { checkScratch(repo, d); return false; } catch (e) { return /scratch folder/.test(e.message); } }; return bad(repo) && bad(join(repo, 'x')) && bad(tmp) && !(() => { try { checkScratch(repo, join(tmp, 'scratch')); return false; } catch { return true; } })(); })());

  // the whole run, with a stand-in for Godot
  const stub = join(tmp, 'godot-stub.mjs');
  writeFileSync(stub, [
    "const a = process.argv.slice(2);",
    "if (a.some((x) => /swing_smoke/.test(x))) { console.log('SWINGSMOKE ok gen=3 ticks=900 frames=900 frame=true'); console.log('SWINGSMOKE asked=3 refused=0 swings=3 clamps=0'); process.exit(0); }",
    "if (a.includes('--script')) { if (process.env.STUB_SMOKE_ERROR) console.log('SCRIPT ERROR: Parse Error: oops\\n   at: GDScript::reload (res://sim/beta/b.gd:3)'); console.log(process.env.STUB_SMOKE_SHORT ? 'SMOKE SHORT ticks=10 wanted=900' : 'SMOKE ok ticks=900 wanted=900 frames=900 gen=' + ((a.find((x) => x.startsWith('--planet-gen=')) || '=0').split('=')[1])); process.exit(process.env.STUB_SMOKE_SHORT ? 1 : 0); }",
    "console.log('import ok');",
  ].join('\n'));
  writeFileSync(join(tmp, 'stack.json'), JSON.stringify({ parks: man.parks.filter((p) => ['p-alpha', 'p-beta', 'p-copy-replace', 'p-overlay'].includes(p.id)).map((p) => (p.id === 'p-beta' ? { ...p, needs: [] } : p)) }));
  const base = join(tmp, 'scratch');
  const opts = { repo, manifest: join(tmp, 'stack.json'), rev: 'HEAD', out: base, godotNode: stub, ticks: 900 };
  const r1 = await runStack({ ...opts, noGodot: true });
  check('a run without Godot applies the parks, flips, finds no conflict and says "apply and validate only"', r1.report.firstConflict === null && r1.report.parks.every((p) => p.status === 'applied') && r1.report.partial === true && r1.report.import === null && r1.changes[0] === 'first run of this stack', JSON.stringify(r1.report.parks.map((p) => p.status)));
  check('the scratch tree is removed after the run and nothing was written into the repository', !existsSync(join(base, `${SHA.slice(0, 8)}-${r1.report.key}`, 'tree')) && git(repo, 'status', '--porcelain', '--untracked-files=no').trim() === '');
  const r2 = await runStack({ ...opts, noGodot: true });
  check('the same stack again does no work and says so', r2.unchanged === true && /nothing the stack is made of has changed/.test(r2.changes[0]));
  const r3 = await runStack({ ...opts });
  check('World\'s code in the tree (sim/world/field.gd) adds a second match, asked for planetGen 3 on a whole ring, named apart', r3.report.smoke3 && r3.report.smoke3.ok === true && /gen=3/.test(r3.report.smoke3.line) && /gen=0/.test(r3.report.smoke.line) && r3.changes.some((c) => /gen 3 whole ring: not run -> ok/.test(c)) && /Smoke match, gen 3 whole ring: ok/.test(describeReport(r3.report).join('\n')), JSON.stringify(r3.report.smoke3));
  check('Research\'s swing probe plays when the tree has SimSwing and the repo has the probe: copied into the scratch tree only, its two lines kept, the change named', r3.report.smokeSwing && r3.report.smokeSwing.ok === true && /asked=3/.test(r3.report.smokeSwing.line) && r3.changes.some((c) => /swing probe: not run -> ok/.test(c)) && /Swing probe .*: ok/.test(describeReport(r3.report).join('\n')) && !existsSync(join(repo, 'tools', 'preview', 'swing_smoke.gd')), JSON.stringify(r3.report.smokeSwing));
  check('a run with the stand-in Godot imports clean and plays the smoke match', r3.report.import && r3.report.import.ok === true && r3.report.smoke && r3.report.smoke.ok === true && /SMOKE ok/.test(r3.report.smoke.line) && r3.changes.some((c) => /import: not run -> clean/.test(c)) && r3.changes.some((c) => /smoke match: not run -> ok/.test(c)), JSON.stringify([r3.report.import, r3.report.smoke, r3.changes]));
  process.env.STUB_SMOKE_ERROR = '1';
  const r4 = await runStack({ ...opts, force: true });
  delete process.env.STUB_SMOKE_ERROR;
  check('a script error in the smoke match is attributed to the park that touched the file and its owner', r4.report.smoke.ok === false && r4.report.smoke.errors.some((e) => e.file === 'sim/beta/b.gd' && e.park === 'p-beta' && e.fileOwner === 'beta') && r4.changes.some((c) => /smoke match: ok -> failed/.test(c)), JSON.stringify(r4.report.smoke));
  process.env.STUB_SMOKE_SHORT = '1';
  const r5 = await runStack({ ...opts, force: true });
  delete process.env.STUB_SMOKE_SHORT;
  check('a match that stops short is a failed smoke match with its reason', r5.report.smoke.ok === false && /stopped short/.test(r5.report.smoke.why));
  // a fixup: a bridge between two parks, named as such, the text there exactly as often as it says
  const fixPark = (from, to, count) => ({ id: 'p-fix', owner: 'alpha', notes: 'a bridge', steps: [{ fixup: [{ file: 'sim/alpha/c.gd', from, to, ...(count ? { count } : {}) }], why: 'the two parks disagree on a name' }] });
  const fixRun = async (park) => { writeFileSync(join(tmp, 'stack-fix.json'), JSON.stringify({ parks: [park] })); return runStack({ ...opts, manifest: join(tmp, 'stack-fix.json'), noGodot: true, force: true }); };
  const x1 = await fixRun(fixPark('c2', 'C2'));
  const fx = x1.report.parks[0];
  check('a fixup replaces its text once in the scratch tree, is reported as a FIXUP with its reason, and the file counts as that park\'s', fx.status === 'applied' && fx.steps[0].label.startsWith('FIXUP') && /two parks disagree/.test(fx.steps[0].detail) && fx.files === 1 && /FIXUP sim\/alpha\/c.gd.*two parks disagree/.test(describeReport(x1.report).join('\n')), JSON.stringify(fx));
  const x2 = await fixRun(fixPark('nowhere', 'x'));
  check('a fixup whose text is not there is a conflict (a stale bridge must not pass), naming the file and the reason', x2.report.firstConflict && x2.report.firstConflict.file === 'sim/alpha/c.gd' && /expects its text 1 time\(s\).*finds it 0/.test(x2.report.firstConflict.why), JSON.stringify(x2.report.firstConflict));
  const x3 = await fixRun(fixPark('c', 'k', 2));
  check('the count is checked: "c" is in c.gd three times, not two, so it conflicts; a bad fixup entry is refused by the manifest check', x3.report.firstConflict !== null && loadManifest(JSON.stringify({ parks: [{ id: 'q', owner: 'alpha', steps: [{ fixup: [{ file: 'a', from: 'b', to: 'c' }] }] }] })).problems.some((p) => /says why/.test(p)));
  check('the repository is untouched by a fixup', git(repo, 'status', '--porcelain', '--untracked-files=no').trim() === '');
  // a park file changes: the next run says which park
  put('docs/beta/pending/p3.patch', readFileSync(join(repo, 'docs/beta/pending/p3.patch'), 'utf8').replace('b4 (beta)', 'b4 (changed)'));
  const r6 = await runStack({ ...opts, noGodot: true });
  check('a changed park file is not "unchanged": the stack runs again', r6.unchanged === false);
  put('docs/beta/pending/p3.patch', readFileSync(join(repo, 'docs/beta/pending/p3.patch'), 'utf8').replace('b4 (changed)', 'b4 (beta)'));
  const lines = describeReport(r3.report).join('\n');
  check('the report prints each park, the first conflict (or none), the switches, the import and the smoke match', /APPLIED\s+p-alpha/.test(lines) && /First conflict: none/.test(lines) && /Switches on:/.test(lines) && /Import: clean/.test(lines) && /Smoke match: ok/.test(lines));
  const bad = describeReport({ ...r3.report, firstConflict: { park: 'x', step: 'patch a', file: 'f.gd', with: 'HEAD', fileOwner: 'o', parkOwner: 'p', why: 'does not apply' } }).join('\n');
  check('a conflict with the commit says HEAD moved since the park was made', /FIRST CONFLICT: park x \(p\), patch a/.test(bad) && /HEAD moved since the park was made/.test(bad));
  // the command line
  const cli = (...a) => spawnSync(process.execPath, [join(here, 'stack.mjs'), ...a], { encoding: 'utf8' });
  const c1 = cli('--bogus');
  check('an unknown option is refused with exit 2', c1.status === 2 && /unknown option/.test(c1.stderr));
  const c2 = cli('--list', '--manifest', join(tmp, 'stack.json'));
  check('--list prints the parks in order with owners and what each does', c2.status === 0 && /p-alpha\s+alpha\s+ready\s+patch/.test(c2.stdout) && /p-overlay\s+beta\s+ready\s+overlay/.test(c2.stdout), c2.stdout + c2.stderr);
  check('the stack never runs in the repository: a --out inside it is refused', (() => { const c = cli('--repo', repo, '--manifest', join(tmp, 'stack.json'), '--rev', 'HEAD', '--out', join(repo, 'scratch'), '--no-godot'); return c.status === 2 && /scratch folder/.test(c.stderr); })());
} finally { rmSync(tmp, { recursive: true, force: true }); }

console.log(failed ? `stack self-test FAILED (${failed})` : 'stack self-test ok');
process.exit(failed ? 1 : 0);
