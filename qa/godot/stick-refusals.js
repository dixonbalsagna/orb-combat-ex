// Refusal counts by reason for the stick-only arm (EP brief 2026-11-06, item 2): sums the STICKPLAY lines of several files (chunks of one level) and prints the flicks, the landed hits and every stick_refused cue by its reason.
//   node qa/godot/stick-refusals.js easy=a.out,b.out medium=c.out,d.out
// A cue's key in stickplay.gd is refused:<direction>/<source>. The source is the reason: late (the charge waited over pendTicks with no blow; its direction is empty), replaced (a newer press took the pending one), ki, chase, answered, refused, cancel,
// dodged, taken, or a number: the mask of the buttons held (0 = none) when the press could not start and no buffer is on (stick.json bufferTicks 0), "can't now" in plain words (the fighter was in a state that cannot start a strike).
const fs = require('fs');
const NAMES = { late: 'late: the charge waited with no blow to carry it', replaced: 'replaced by a newer press', ki: 'not enough energy (ki)', chase: 'in the air, chasing: never sends', answered: 'a planned exchange took the request', refused: 'his rival has the first move', cancel: 'a guard or dodge press ended it', dodged: 'dodged out from under it', taken: 'a held beam charge was taken' };
const label = s => (/^\d+$/.test(s) ? `no start, no buffer (cannot start now; buttons held ${s})` : (NAMES[s] || s));
const out = [];
for (const arg of process.argv.slice(2)) {
  const [lv, files] = arg.split('=');
  const tot = { n: 0, done: 0, won: 0, lost: 0, flicks: 0, hits: 0, clean: 0, refused: 0, thrown: 0 }, by = {}, dir = {};
  for (const f of files.split(',')) {
    for (const line of fs.readFileSync(f, 'utf8').split('\n')) {
      if (!line.startsWith('STICKPLAY ')) continue;
      const j = JSON.parse(line.slice(10)), c = j.cues;
      tot.n += j.n; tot.done += j.done; tot.won += j.won; tot.lost += j.lost; tot.thrown += j.flicksThrown;
      tot.flicks += c.flicks; tot.hits += c.hits; tot.clean += c.clean; tot.refused += c.refused;
      for (const k of Object.keys(c)) if (k.startsWith('refused:')) { const [d, s] = k.slice(8).split('/'); by[s] = (by[s] || 0) + c[k]; dir[d || '(none)'] = (dir[d || '(none)'] || 0) + c[k]; }
    }
  }
  out.push(`### ${lv}: ${tot.done} matches, the pad won ${tot.won} and lost ${tot.lost}`);
  out.push(`Flicks thrown ${tot.thrown}; started (stick_start) ${tot.flicks}; landed (stick_hit) ${tot.hits}, stunning ${tot.clean}; refused ${tot.refused} (${(100 * tot.refused / Math.max(1, tot.thrown)).toFixed(1)}% of the flicks thrown).`);
  out.push('', '| Reason | Count | Share of refusals |', '| :--- | ---: | ---: |');
  for (const [s, n] of Object.entries(by).sort((a, b) => b[1] - a[1])) out.push(`| ${label(s)} (${s}) | ${n} | ${(100 * n / Math.max(1, tot.refused)).toFixed(1)}% |`);
  out.push('', 'By direction: ' + Object.entries(dir).sort((a, b) => b[1] - a[1]).map(([d, n]) => `${d} ${n}`).join(', '), '');
}
console.log(out.join('\n'));
