// The trial clips' self-test (docs/tools/clips.md, "Trial clips"): the clip files are well formed and their switches are known or named by a park; the scene lines still fit the real capture hook (a drift check:
// Rendering's file) and refuse a changed one; the probe reader reads. No Godot, no browser.   node tools/clips/trial-clips-selftest.mjs
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import { linger, loadClips, problemsOf, seenIn } from './trial-clips.mjs';
import { patchClipHook, parkPatches, HOOK_FILE } from './trial-web.mjs';
import { linkTemplates } from '../lib/userdata.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(HERE, '..', '..');
let fails = 0;
const ok = (c, m) => { console.log(`${c ? 'ok  ' : 'FAIL'} ${m}`); if (!c) fails++; };

const clips = loadClips();
ok(clips.length >= 1 && clips.every((c) => problemsOf(c).length === 0), `the ${clips.length} clip files are well formed (${clips.flatMap(problemsOf).slice(0, 3).join('; ') || 'no problems'})`);
ok(clips.every((c) => c.segments.every((s) => s.caption.length <= 90)), 'every caption fits one line of the strip (90 characters at most)');
const good = clips[0], broken = (edit) => { const c = JSON.parse(JSON.stringify(good)); edit(c); return problemsOf(c).length > 0; };
ok(broken((c) => { c.segments[0].expect = []; }) && broken((c) => { delete c.segments[0].caption; }) && broken((c) => { c.segments[0].scene.events.push({ pad: 0, b: 'east', down: true }); })
  && broken((c) => { c.segments[0].scene.events.push({ at: 5, pad: 0 }); }) && broken((c) => { c.segments[0].scene.ticks = c.segments[0].to - 1; }), 'a segment with no expectation, no caption, an untimed or empty event, or too few ticks is refused');
let threw = ''; try { loadClips(undefined, ['no-such-clip']); } catch (e) { threw = e.message; }
ok(/no clip/.test(threw), 'an unknown clip name is refused');

const hook = readFileSync(join(ROOT, ...HOOK_FILE.split('/')), 'utf8');
let patched = ''; try { patched = patchClipHook(hook); } catch (e) { console.log(`     ${e.message}`); }
ok(patched.includes('"script": [false, false]') && patched.includes('_clip.drive(main, t)') && patched.includes('window.__clipScript') && patched.includes('_clip.seen(events'), `the scene lines fit the capture hook as it is (${HOOK_FILE})`);
const lines = patched.replace(/\r\n/g, '\n').split('\n');
let at = 0, lost = 0;
for (const l of hook.replace(/\r\n/g, '\n').split('\n')) { const i = lines.indexOf(l, at); if (i < 0) lost++; else at = i + 1; }
ok(patched !== '' && lost === 1, `they only add lines: every line of the hook is still there in order, but the one list they extend (${lost} changed)`);
let refused = false; try { patchClipHook(hook.replace('func drive(', 'func drive2(')); } catch { refused = true; }
ok(refused, 'a changed hook is refused, never patched by guess');

const seen = seenIn('Godot Engine\nev  108 blow \'release\' a0 att-1 vic-1 109.0\nev  199 beam_outcome \'PART\' a1 att-1 vic-1 0.0\nhp 1 p0 1\nPROBE done ticks=5\n');
ok(seen.has('blow') && seen.has('blow:release@0') && seen.has('beam_outcome:PART@1') && !seen.has('blow@1'), 'the probe\'s lines are read as name, name:text and name@actor');

const press = [{ B: 'tap', X: null, RS: { g: null } }, { B: null, X: null, RS: { g: 'tap' } }, { B: null, X: 'hold', RS: { g: null } }, { B: null, X: null, RS: { g: null } }, { B: null, X: null, RS: { g: null } }];
const kept = linger(press, 3);
ok(kept[1].B === 'tap' && kept[2].B === 'tap' && kept[3].B === null && kept[2].RS.g === 'tap' && kept[3].X === null, 'a tap stays lit for a few pictures after the button is up, a hold does not');

const t = mkdtempSync(join(tmpdir(), 'meridian-trial-selftest-'));
try {
  for (const n of ['b.patch', 'z.diff', 'a.patch', 'README.md']) writeFileSync(join(t, n), '');
  ok(parkPatches(t).map((f) => basename(f)).join() === 'z.diff,a.patch,b.patch', 'a park applies its diff first, then its patches by name, and nothing else');
  ok(linkTemplates(join(t, 'data'), { APPDATA: join(t, 'nothing-here') }) === null && !existsSync(join(t, 'nothing-here')) && !existsSync(join(t, 'data')), 'with no templates installed the helper says so (null) and makes nothing');
} finally { rmSync(t, { recursive: true, force: true }); }

console.log(fails ? `TRIAL CLIPS: ${fails} check(s) FAILED` : 'TRIAL CLIPS: all checks ok');
process.exit(fails ? 1 : 0);
