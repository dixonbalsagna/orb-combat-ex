// lw.cjs <checkout root> [--check] [--rest=30]: the launcher's wider window and its rest (Game Design's eleventh round
// item 1, kept by the twelfth: docs/design/brawl-second-pass.md). Apply after the return fix (its slot goes at END).
//   - A B counts as the launcher until launcher.lateTicks (24) after the close, where it was the stagger's 12. Inside
//     the stagger it always lands, as before. After it, it is still the launcher, with its 14-tick wind-up, but he can
//     answer it: it is not sure, it can be guarded, perfect-blocked or dodged, and it does not hold his stagger.
//   - A B pressed while his closing light is on its way waits on his line and is thrown as the launcher at the close (the
//     window's early side, 10 ticks and more: a light lands in fewer). That is today's hold, unchanged.
//   - launcher_open's n is the window's end (it was the stagger's); its dur is the stagger, the part where B always
//     lands. launcher_close goes out at the window's end. launcherOpen() returns the window's end.
//   - launcher.restS: 30 (from 40); --rest=40 keeps 40, the twelfth round's fallback if the route passes an edge.
// Every anchor is exact text; the script stops at the first missing. --check reads every anchor and writes nothing.
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
let rest = 30;
for (const o of opts) {
  if (o === '--check') continue;
  const m = /^--rest=(\d+)$/.exec(o);
  if (m) { rest = Number(m[1]); continue; }
  throw new Error('unknown option: ' + o);
}
if (!root || root.startsWith('--')) throw new Error('usage: node lw.cjs <checkout root> [--check] [--rest=30]');
const check = opts.includes('--check');
function edit(rel, fn) {
  const p = path.join(root, rel);
  let t = fs.readFileSync(p, 'utf8');
  const crlf = t.includes('\r\n');
  if (crlf) t = t.replace(/\r\n/g, '\n');
  const rep = (a, b) => {
    const n = t.split(a).length - 1;
    if (n !== 1) throw new Error(rel + ': expected 1 match, got ' + n + ' for: ' + a.slice(0, 80));
    t = t.replace(a, () => b);
  };
  t = fn(rep, t) || t;
  if (rel.endsWith('.json')) JSON.parse(t);
  if (!check) fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  console.log(rel + (check ? ': anchors ok' : ': ok'));
}

edit('sim/director/brawl.gd', (rep, t0) => {
  const m = t0.match(/\nconst END: int = BASE \+ (\d+)\n/g);
  if (!m || m.length !== 1) throw new Error('brawl.gd: no single END slot');
  const n = Number(/(\d+)/.exec(m[0])[1]);
  rep(`const END: int = BASE + ${n}\n`,
      `const LC_LATE: int = BASE + ${n}    # 1 while the launcher on his line was thrown after the stagger: he can answer it\n` +
      `const END: int = BASE + ${n + 1}\n`);
  // the window: the stagger, or lateTicks after the close if that is longer
  rep('\t_s(f, LC_UNTIL, maxi(was, S.tick + ticks))\n',
      '\t_s(f, LC_UNTIL, maxi(was, S.tick + maxi(ticks, int(lc.get("lateTicks", 0)))))   # the stagger, or lateTicks after the close (the wider window)\n');
  rep('\tvar e = _ev(S, f, "launcher_open", why)\n\te.target = float(S.fighters.find(o))\n\te.n = S.tick + ticks\n',
      '\tvar e = _ev(S, f, "launcher_open", why)\n\te.target = float(S.fighters.find(o))\n\te.n = _g(f, LC_UNTIL)   # the window\'s end\n\te.dur = float(ticks)   # the stagger: inside it his B always lands\n');
  // B is the launcher while the window is open, inside the stagger or after it
  rep('\tvar lau: bool = st == 2 and not paid and _g(f, LC_UNTIL) > 0 and o.stunTicks > 0 and f.ki >= float(c.launcher.ki)\n',
      '\tvar lau: bool = st == 2 and not paid and _g(f, LC_UNTIL) > 0 and (o.stunTicks > 0 or S.tick <= _g(f, LC_UNTIL)) and f.ki >= float(c.launcher.ki)\n');
  rep('\t_s(f, FLAV, 1 if energy else (2 if lau else 0))\n',
      '\t_s(f, FLAV, 1 if energy else (2 if lau else 0))\n' +
      '\t_s(f, LC_LATE, 1 if (lau and o.stunTicks <= 0) else 0)   # thrown after the stagger: he can answer it\n');
  rep('\tif rip > 0 or lau:\n',
      '\tif rip > 0 or (lau and o.stunTicks > 0):   # a launcher inside the stagger always lands; after it, he can answer it\n');
  // a launcher on its way holds the stagger only if it was thrown inside it
  rep('\t\tif _g(f, FLAV) == 2 and _g(f, LINE) == 1:\n',
      '\t\tif _g(f, FLAV) == 2 and _g(f, LINE) == 1 and _g(f, LC_LATE) == 0:\n');
  // the window lapses at its end, not at the stagger's
  rep('\t\telif _g(f, LC_UNTIL) > 0 and o.stunTicks <= 0:\n',
      '\t\telif _g(f, LC_UNTIL) > 0 and o.stunTicks <= 0 and S.tick > _g(f, LC_UNTIL):\n');
  rep('\treturn S.tick + maxi(0, o.stunTicks)\n',
      '\treturn maxi(_g(f, LC_UNTIL), S.tick + maxi(0, o.stunTicks))   # the window\'s end (the stagger\'s, or lateTicks after the close)\n');
});

edit('data/director/interrupts.json', (rep, t0) => {
  const a = '"launcher": {"minStagger": 12, "windupTicks": 14, "worth": 3, "ki": 5, "restS": 40, "flightMul": 1';
  if (t0.split(a).length === 2) {
    rep(a, `"launcher": {"minStagger": 12, "windupTicks": 14, "worth": 3, "ki": 5, "restS": ${rest}, "lateTicks": 24, "flightMul": 1`);
    return;
  }
  // pretty-printed form
  const m = t0.match(/"launcher": \{\n(\s+)"minStagger": 12,/);
  if (!m) throw new Error('interrupts.json: no single brawl.launcher block');
  rep('"restS": 40,\n', `"restS": ${rest},\n${m[1]}"lateTicks": 24,\n`);
});

{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  const l = s.properties.brawl.properties.launcher;
  if (!l || !l.properties) throw new Error('director-interrupts schema: no brawl.launcher');
  l.properties.lateTicks = { type: 'integer', minimum: 0, description: 'A B counts as the launcher until this many ticks after the close (the stagger, if longer). After the stagger he can answer it.' };
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: brawl.launcher.lateTicks' + (check ? ' (checked)' : ''));
}
