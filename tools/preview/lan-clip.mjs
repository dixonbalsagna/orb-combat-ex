// The clip of a LAN report: the last ~30 s before a "report this" press, with the button strip (Tools, 2026-11-08; docs/tools/lan-report.md).
//
//   node tools/preview/lan-clip.mjs --file <lan-report json | black box json> --dir <kept web build of the SAME commit> --out <folder>
//        [--slot N] [--tick N] [--before 1800] [--after 120] [--every 6] [--width 960 --height 540] [--limit 1200] [--dry]
//
// It plays the report's replay through tools/preview/blackbox-clip.mjs (the existing replay path: the page's own `replay=1`, the sim stepped with the recorded intents, a picture every --every
// ticks from tick-before to tick+after, played on a small page until just before the window) and then writes a player page that draws the button strip UNDER the picture (a canvas of its
// own: nothing covers a fighter). The strip is decoded from the replay's recorded intents (tools/preview/lan-strip.mjs), the same controls and words as the clip kit's strip.
// Chrome is started only by blackbox-clip.mjs through the guarded launcher (below-normal, CPU cap, a time limit, this session's name in the profile). One browser at a time. Never run while a match is open.
// The tick: --tick, else the report's last `reportTicks` entry, else the match's last tick. The slot: --slot, else 0 for side "main" and 1 for side "old", else 0.
// Output: <out>/frames/f-NNNNNN.jpg, <out>/strip.json, <out>/index.html (open it in a browser: Space plays, arrows step), <out>/lan-clip.json, <out>/clip.json (blackbox-clip's own record).
// Exit: 0 made, 3 not made with a plain reason in lan-clip.json (no build of that commit, a replay the page refuses ...), 2 usage.
import { readFileSync, writeFileSync, mkdirSync, existsSync, readdirSync } from 'node:fs';
import { join, resolve, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawn } from 'node:child_process';
import { stripFor } from './lan-strip.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const FILE = opt('--file'), DIR = opt('--dir'), OUT = opt('--out');
/** A path for a record that may be committed: forward slashes, no account name (C:/Users/<user>/...), and a path inside the repository made relative to it. */
export function scrubPath(p) {
  let s = String(p).replace(/\\/g, '/');
  const repo = resolve(HERE, '../..').replace(/\\/g, '/');
  if (s.toLowerCase().startsWith(repo.toLowerCase() + '/')) return s.slice(repo.length + 1);
  return s.replace(new RegExp('^([A-Za-z]:/' + 'Us' + 'ers/)[^/]+/'), '$1<user>/');
}

/** The report marks of a file: Netcode's `marks` [{tick, kind:"report", tag, note}] (kind "report" only; the black box's other marks are not reports), else a plain `reportTicks` list. Ticks, ascending. */
export function reportMarks(doc) {
  const m = Array.isArray(doc.marks) ? doc.marks.filter((x) => x && x.kind === 'report' && Number(x.tick) > 0) : [];
  if (m.length) return m.map((x) => ({ tick: Number(x.tick), tag: x.tag || '', note: x.note || '' })).sort((a, b) => a.tick - b.tick);
  return (Array.isArray(doc.reportTicks) ? doc.reportTicks : []).map(Number).filter((n) => n > 0).sort((a, b) => a - b).map((tick) => ({ tick, tag: '', note: '' }));
}
/** The commit a file was recorded on: Netcode's build.commit, a black box's build.commit, else a top-level `commit`. */
/** The stamp the save's replay names as its build (SimReplay's "build"), or '' when it names none. Pure. */
export function homeOf(doc) { const rp = (doc && doc.replay) || doc || {}; return typeof rp.build === 'string' ? rp.build : ''; }
export function commitOf(doc) { return (doc.build && doc.build.commit) || doc.commit || null; }
/** Which PC: Netcode's `pc` ("main" or "old"), else `side`. */
export function pcOf(doc) { return doc.pc || doc.side || null; }

/** Groups report ticks whose 30 s windows overlap, so one clip serves them: [{at, before, ticks:[...]}], `at` the last tick of a group and `before` reaching back to the first one's window. */
export function groupMarks(ticks, before = 1800, after = 120) {
  const out = [];
  for (const t of ticks) {
    const g = out[out.length - 1];
    if (g && t - g.ticks[g.ticks.length - 1] <= before + after) { g.ticks.push(t); g.at = t; g.before = t - g.ticks[0] + before; } else out.push({ at: t, before, ticks: [t] });
  }
  return out;
}

export function planWindow(doc, o = {}) {
  const rp = doc.replay || doc;
  const ticks = Number(rp.ticks) || doc.tick || 0;
  const given = o.tick > 0 ? Number(o.tick) : 0;
  const rt = reportMarks(doc).map((m) => m.tick);
  const at = Math.min(ticks, given || (rt.length ? rt[rt.length - 1] : ticks));
  const before = o.before ?? 1800, after = o.after ?? 120;
  const from = Math.max(1, at - before), to = Math.min(ticks, at + after);
  const slot = o.slot !== undefined && o.slot !== '' ? Number(o.slot) : Number.isInteger(doc.slot) ? doc.slot : pcOf(doc) === 'old' ? 1 : 0;
  return { at, from, to, slot, ticks, reportTicks: rt.filter((t) => t >= from && t <= to) };
}

export function html(n, fps, info, strip = null) {   // the strip is written INTO the page: a page opened from disk (a double-click, or out of the zip) cannot fetch a neighbouring file
  return `<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Report clip</title>
<style>html,body{margin:0;background:#0b0d12;color:#e8e8e0;font:16px/1.4 sans-serif}#w{max-width:1000px;margin:0 auto;padding:12px}canvas{width:100%;display:block;background:#000}
#bar{display:flex;gap:10px;align-items:center;margin:10px 0;flex-wrap:wrap}button{font:bold 16px sans-serif;padding:8px 14px;border-radius:8px;border:2px solid #8c8a80;background:#14171e;color:#e8e8e0;cursor:pointer}input[type=range]{flex:1;min-width:200px}.note{color:#a8a69c;font-size:14px}</style>
<div id="w"><h2 style="margin:6px 0">Report clip</h2>
<div class="note">${info}</div>
<canvas id="c" width="960" height="540"></canvas><canvas id="s" width="960" height="64"></canvas>
<div id="bar"><button id="play">Play</button><span id="t">1</span><input id="s2" type="range" min="1" max="${n}" value="1"></div>
<div class="note" id="load">Loading the pictures...</div></div>
<script>
const N=${n},FPS=${fps},imgs=[],c=document.getElementById('c').getContext('2d'),sc=document.getElementById('s').getContext('2d');let cur=1,playing=false,last=0,loaded=0,S=${JSON.stringify(strip).replace(/</g, '\\u003c')};
const NAMES=['LS','LT','LB','X','Y','B','A','RB','RT','RS'];
function strip(st){const W=960,H=64;sc.fillStyle='#10131a';sc.fillRect(0,0,W,H);if(!st)return;sc.font='bold 15px sans-serif';sc.textAlign='center';
 NAMES.forEach((k,i)=>{const x=40+i*88;let lit=false,word='';
  if(k==='LS'){const v=st.LS||[0,0];lit=Math.hypot(v[0],v[1])>0.15;sc.strokeStyle=lit?'#f2d16b':'#5a5d66';sc.lineWidth=3;sc.beginPath();sc.arc(x,24,17,0,7);sc.stroke();sc.fillStyle=lit?'#f2d16b':'#5a5d66';sc.beginPath();sc.arc(x+v[0]*14,24+v[1]*14,5,0,7);sc.fill();}
  else if(k==='RS'){const r=st.RS||{};lit=!!r.dir||!!r.g;word=r.g||'';sc.strokeStyle=lit?'#f2d16b':'#5a5d66';sc.lineWidth=3;sc.beginPath();sc.arc(x,24,17,0,7);sc.stroke();if(r.dir){const d=[[0,0],[0,-1],[0,1],[-1,0],[1,0]][r.dir];sc.fillStyle='#f2d16b';sc.beginPath();sc.arc(x+d[0]*12,24+d[1]*12,6,0,7);sc.fill();}}
  else{word=st[k]||'';lit=!!word;sc.fillStyle=lit?'#f2d16b':'#262a33';sc.beginPath();sc.roundRect(x-26,7,52,34,8);sc.fill();sc.fillStyle=lit?'#10131a':'#8c8a80';sc.fillText(k,x,30);}
  sc.fillStyle='#e8e8e0';sc.font='13px sans-serif';sc.fillText(word,x,58);sc.font='bold 15px sans-serif';});}
function draw(){const im=imgs[cur];if(im&&im.complete&&im.naturalWidth){c.canvas.width=im.naturalWidth;c.canvas.height=im.naturalHeight;c.drawImage(im,0,0);}strip(S&&S.frames[cur-1]);document.getElementById('t').textContent=cur+' / '+N+(S&&S.ticks?'  (tick '+S.ticks[cur-1]+')':'');document.getElementById('s2').value=cur;}
draw();
for(let i=1;i<=N;i++){const x=new Image();x.onload=()=>{loaded++;document.getElementById('load').textContent=loaded<N?'Loading the pictures: '+loaded+' of '+N:'Ready.';if(i===cur)draw();};x.src='frames/f-'+String(i).padStart(6,'0')+'.jpg';imgs[i]=x;}
function frame(ts){if(playing&&ts-last>=1000/FPS){last=ts;cur=cur>=N?1:cur+1;draw();}requestAnimationFrame(frame);}requestAnimationFrame(frame);
document.getElementById('play').onclick=()=>{playing=!playing;document.getElementById('play').textContent=playing?'Pause':'Play';};
document.getElementById('s2').oninput=e=>{cur=+e.target.value;draw();};
addEventListener('keydown',e=>{if(e.code==='Space'){e.preventDefault();document.getElementById('play').click();}if(e.code==='ArrowRight'){cur=Math.min(N,cur+1);draw();}if(e.code==='ArrowLeft'){cur=Math.max(1,cur-1);draw();}});
</script>`;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  if (!FILE || !OUT || (!DIR && !argv.includes('--dry'))) { console.error('usage: node tools/preview/lan-clip.mjs --file <lan-report json> --dir <kept web build folder> --out <folder> [--slot N] [--tick N] [--before 1800] [--after 120] [--every 6] [--dry]'); process.exit(2); }
  const out = resolve(OUT);
  mkdirSync(out, { recursive: true });
  const rec = { source: scrubPath(FILE), dir: DIR ? scrubPath(DIR) : null, made: false, reason: null };
  const finish = (code, reason) => { if (reason) rec.reason = reason; writeFileSync(join(out, 'lan-clip.json'), JSON.stringify(rec, null, 2)); if (reason) console.error(`[lan-clip] ${reason}`); process.exit(code); };
  let doc;
  try { doc = JSON.parse(readFileSync(FILE, 'utf8')); } catch (e) { finish(3, `cannot read the report file: ${e.message}`); }
  const rp = doc.replay || doc;
  if (!rp || !Array.isArray(rp.inputs) || !Number(rp.ticks)) finish(3, 'the file holds no replay (no inputs or ticks)');
  const w = planWindow(doc, { tick: Number(opt('--tick', 0)), before: Number(opt('--before', 1800)), after: Number(opt('--after', 120)), slot: opt('--slot', undefined) });
  const EVERY = Math.max(1, Number(opt('--every', 6)));
  const WIDTH = Number(opt('--width', 960)), HEIGHT = Number(opt('--height', 540));
  Object.assign(rec, { commit: commitOf(doc), pc: pcOf(doc), slot: w.slot, reportTicks: w.reportTicks, at: w.at, from: w.from, to: w.to, every: EVERY, width: WIDTH, height: HEIGHT });
  // the build must be the report's commit: a kept folder is named for it (orb-first-play-<commit8>-<key8>), so a mismatch is refused before a browser starts
  const c8 = commitOf(doc) ? String(commitOf(doc)).slice(0, 8) : null;
  const dirName = DIR ? basename(dirname(resolve(DIR))) + '/' + basename(resolve(DIR)) : '';
  if (c8 && DIR && !dirName.includes(c8)) finish(3, `the report is from commit ${c8} and the web folder is ${dirName}: no kept build of that commit, so the clip is not made (the rest of the report still holds)`);
  if (argv.includes('--dry')) { rec.dry = true; console.log(JSON.stringify(rec)); process.exit(0); }
  if (!existsSync(join(resolve(DIR), 'index.html'))) finish(3, `no index.html in ${DIR}`);
  const args = [join(HERE, 'blackbox-clip.mjs'), '--file', resolve(FILE), '--dir', resolve(DIR), '--out', out, '--width', String(WIDTH), '--height', String(HEIGHT), '--scale', '1', '--every', String(EVERY), '--from', String(w.from), '--to', String(w.to)];
  const q = opt('--query', null); if (q) args.push('--query', q);
  const home = homeOf(doc); if (home) args.push('--home', home);   // the save's own stamp (A-NET-05): a LAN save is made by the kit's stamp, not the page's
  const limitS = Math.max(60, Number(opt('--limit', 1200)));
  const env = { ...process.env, MERIDIAN_SESSION: process.env.MERIDIAN_SESSION || 'tools-pipeline' };
  const child = spawn(process.execPath, args, { env, stdio: 'inherit', windowsHide: true });
  const timer = setTimeout(() => { console.error(`[lan-clip] over ${limitS} s: stopping the clip tool (pid ${child.pid})`); try { child.kill(); } catch { /* gone */ } }, limitS * 1000);
  child.on('close', (code) => {
    clearTimeout(timer);
    let clip = null; try { clip = JSON.parse(readFileSync(join(out, 'clip.json'), 'utf8')); } catch { /* none */ }
    if (code !== 0 || !clip || clip.error || !clip.frames) finish(3, `the replay did not play: ${clip && clip.error ? clip.error : `clip tool exit ${code}`} (a replay carries a data hash, and the page refuses another commit's)`);
    const s = stripFor(rp.inputs, w.slot, w.from, w.to, EVERY);
    if (s.ticks.length !== clip.frames) rec.stripNote = `strip has ${s.ticks.length} states for ${clip.frames} pictures`;
    writeFileSync(join(out, 'strip.json'), JSON.stringify(s));
    const esc = (s) => String(s).replace(/[<>&"]/g, '');
    const marks = reportMarks(doc).filter((m) => m.tick >= w.from && m.tick <= w.to);
    const info = `Commit ${c8 || '?'}, ${pcOf(doc) || 'one'} PC${doc.mode ? ', ' + esc(doc.mode) : ''}${doc.reason ? ', saved on ' + esc(doc.reason) : ''}. About ${Math.round((w.at - w.from) / 60)} s before and ${Math.round((w.to - w.at) / 60)} s after tick ${w.at} (${(w.at / 60).toFixed(1)} s into the match). The strip under the picture is player ${w.slot + 1}'s controls as the game was fed them.${marks.length ? ' "Report this" pressed at: ' + marks.map((m) => 'tick ' + m.tick + (m.tag ? ' [' + esc(m.tag) + ']' : '') + (m.note ? ' "' + esc(m.note) + '"' : '')).join('; ') + '.' : ''}`;
    writeFileSync(join(out, 'index.html'), html(clip.frames, Math.round(60 / EVERY), info, s));
    rec.made = true; rec.frames = clip.frames; rec.checkpoints = clip.checkpoints;
    finish(0);
  });
}
