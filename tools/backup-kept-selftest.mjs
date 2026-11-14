// Self-test of tools/backup-kept.mjs (A-TOOLS-09): the copy, the second run, a changed file never overwritten, the verify, the restore with its refusal, and the guards on where it may write. Throwaway folders, node only.
//   node tools/backup-kept-selftest.mjs
import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { MANIFEST, backup, inside, listFiles, restore, verify } from './backup-kept.mjs';

const here = dirname(fileURLToPath(import.meta.url));
let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };

const d = mkdtempSync(join(tmpdir(), 'backup-kept-'));
try {
  const src = join(d, 'Files'), bak = join(d, 'copy'), back = join(d, 'restored');
  const put = (p, t) => { mkdirSync(dirname(join(src, p)), { recursive: true }); writeFileSync(join(src, p), t); };
  put('builds/orb-first-play-aaaaaaaa-11111111/web/index.pck', 'pack-a');
  put('builds/orb-first-play-aaaaaaaa-11111111/tree/project.godot', 'proj');
  put('builds/orb-first-play-bbbbbbbb-22222222/web/index.pck', 'pack-b');
  put('builds/loose-file.txt', 'not a build folder');
  put('orb-first-play-20261101-1424.json', '{"a":1}');
  put('oldpc-result-20261101-1813.json', '{"r":1}');
  put('notes.md', 'not a play file');
  put('reports/orb-lan-report-1/README.txt', 'r');
  put('reports/orb-lan-report-1.zip', 'zipbytes');
  put('clips/x.gif', 'not backed up');

  const all = listFiles(src);
  check('the sets: every file of every builds/ folder, the saved matches and results of the top folder, the report folders and zips; not a loose file of builds/, a note, or the clips',
    all.length === 7 && all.includes('builds/orb-first-play-aaaaaaaa-11111111/web/index.pck') && all.includes('orb-first-play-20261101-1424.json') && all.includes('oldpc-result-20261101-1813.json') && all.includes('reports/orb-lan-report-1.zip') && !all.includes('notes.md') && !all.includes('clips/x.gif') && !all.includes('builds/loose-file.txt'), all.join());
  check('--only and --include narrow the list', listFiles(src, ['builds'], 'bbbbbbbb').join() === 'builds/orb-first-play-bbbbbbbb-22222222/web/index.pck' && listFiles(src, ['play']).length === 2);
  check('inside(): the same folder and a folder under it are inside; a sibling is not', inside(join(src, 'a'), src) && inside(src, src) && !inside(bak, src));

  let r = await backup({ from: src, to: bak });
  check('the first run copies all seven files and writes a manifest with their sizes and hashes', r.copied === 7 && r.same === 0 && r.differs.length === 0 && existsSync(join(bak, MANIFEST)) && Object.keys(JSON.parse(readFileSync(join(bak, MANIFEST), 'utf8')).files).length === 7, JSON.stringify(r));
  r = await backup({ from: src, to: bak });
  check('a second run copies nothing: every file is already there and the same', r.copied === 0 && r.same === 7 && r.differs.length === 0, JSON.stringify(r));
  put('builds/orb-first-play-cccccccc-33333333/web/index.pck', 'pack-c');
  r = await backup({ from: src, to: bak });
  check('a new kept build is added by the next run, the rest left', r.copied === 1 && r.same === 7, JSON.stringify(r));
  let v = await verify(bak);
  check('verify reads the copy whole against its manifest', v.ok && v.checked === 8, JSON.stringify(v));
  writeFileSync(join(bak, 'orb-first-play-20261101-1424.json'), '{"a":2}');
  v = await verify(bak);
  check('verify names a file that changed in the copy, with the reason', !v.ok && v.bad.length === 1 && /differs|size/.test(v.bad[0].why) && v.bad[0].path === 'orb-first-play-20261101-1424.json', JSON.stringify(v));
  r = await backup({ from: src, to: bak });
  check('a run never overwrites a file of the copy that is not the source\'s: it is named', r.differs.join() === 'orb-first-play-20261101-1424.json' && readFileSync(join(bak, 'orb-first-play-20261101-1424.json'), 'utf8') === '{"a":2}', JSON.stringify(r));
  writeFileSync(join(bak, 'orb-first-play-20261101-1424.json'), '{"a":1}');
  put('orb-first-play-20261101-1424.json', '{"a":1}');
  rmSync(join(bak, 'reports', 'orb-lan-report-1.zip'));
  v = await verify(bak);
  check('verify names a file gone from the copy', !v.ok && v.bad.some((b) => b.path === 'reports/orb-lan-report-1.zip' && b.why === 'missing'));
  r = await backup({ from: src, to: bak });
  check('and the next run puts it back', r.copied === 1 && (await verify(bak)).ok);

  let g = null; try { await backup({ from: src, to: join(src, 'inner') }); } catch (e) { g = e.message; }
  check('a destination inside the source is refused (and so is the source inside the destination)', g !== null && /inside one another/.test(g));
  g = null; try { await backup({ from: join(bak, 'x'), to: bak }); } catch (e) { g = e.message; }
  check('the source inside the destination is refused', g !== null);

  let rr = await restore({ from: bak, to: back });
  check('a restore into a new folder copies every file and checks each against the manifest', rr.copied === 8 && rr.refused.length === 0 && readFileSync(join(back, 'builds/orb-first-play-bbbbbbbb-22222222/web/index.pck'), 'utf8') === 'pack-b', JSON.stringify(rr));
  rr = await restore({ from: bak, to: back });
  check('a second restore finds everything there and the same', rr.copied === 0 && rr.same === 8 && rr.refused.length === 0, JSON.stringify(rr));
  writeFileSync(join(back, 'orb-first-play-20261101-1424.json'), '{"changed":true}');
  rr = await restore({ from: bak, to: back });
  check('a restore never overwrites a different file: it refuses and says so, the file untouched', rr.refused.length === 1 && /not overwritten/.test(rr.refused[0].why) && readFileSync(join(back, 'orb-first-play-20261101-1424.json'), 'utf8') === '{"changed":true}', JSON.stringify(rr));
  rr = await restore({ from: bak, to: join(d, 'only'), only: 'bbbbbbbb' });
  check('--only restores part: one build', rr.copied === 1 && rr.total === 1);
  let nm = null; try { await restore({ from: join(d, 'nothing-here'), to: join(d, 'z') }); } catch (e) { nm = e.message; }
  check('a folder with no manifest is not a backup', nm !== null && /not a backup folder/.test(nm));
  const dry = await backup({ from: src, to: join(d, 'dry'), dry: true });
  check('--dry counts and writes nothing', dry.copied === 8 && !existsSync(join(d, 'dry')));
  const c = spawnSync(process.execPath, [join(here, 'backup-kept.mjs'), '--from', src, '--to', join(d, 'cli')], { encoding: 'utf8' });
  check('the command copies, prints the counts and exits 0; --verify then reads it whole', c.status === 0 && /8 files copied/.test(c.stdout) && spawnSync(process.execPath, [join(here, 'backup-kept.mjs'), '--verify', '--to', join(d, 'cli')], { encoding: 'utf8' }).stdout.includes('THE COPY IS WHOLE'), c.stdout + c.stderr);
  check('no --to: the usage and exit 2', spawnSync(process.execPath, [join(here, 'backup-kept.mjs')], { encoding: 'utf8' }).status === 2);
} finally { rmSync(d, { recursive: true, force: true }); }

console.log(failed ? `backup-kept self-test: ${failed} of ${ran} FAILED` : `backup-kept self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
