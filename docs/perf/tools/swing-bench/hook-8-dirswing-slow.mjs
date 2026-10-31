// SCRATCH HOOK (a scratch tree only): prints any DirSwing entry point that takes over 20 ms in one call ("SLOW name ms"), to find what a swing's first tick costs.
//   node hook-8-dirswing-slow.mjs <tree>
import { readFileSync, writeFileSync } from 'node:fs';
const root = process.argv[2];
const f = `${root}/sim/director/swing.gd`;
let s = readFileSync(f, 'utf8');
const names = ['places', 'candidates', 'scored', 'atLaunch', 'atBlow', 'atChase', 'atSend', 'atPlanned', 'atPause', '_brawlTick', '_fleeTick', '_nudgeTick', 'tick', '_take', '_offer', '_direction', '_timing', '_planOn', '_planOff', '_launchPick', '_frame', '_tallAhead', '_biomeRoom', '_joltSign', '_cue', '_feed', '_beats', '_flyingByChoice', '_flyer', '_resting', '_coreCause', '_restSec'];
for (const n of names) {
  const re = new RegExp(String.raw`^static func ${n}\(([^)]*)\)( -> ([A-Za-z0-9_]+))?:\n`, 'm');
  const m = s.match(re);
  if (!m) { console.log('skip', n); continue; }
  const args = m[1], ret = m[3];
  const call = args.split(',').map((a) => a.trim().split(':')[0].trim()).filter(Boolean).join(', ');
  const wrapper = `static func ${n}(${args})${m[2] || ''}:\n\tvar _t0: int = Time.get_ticks_usec()\n\t${ret && ret !== 'void' ? 'var _r = ' : ''}${n}0(${call})\n\tvar _d: int = Time.get_ticks_usec() - _t0\n\tif _d > 20000:\n\t\tprint("SLOW ${n} ", _d / 1000, " ms")\n\t${ret && ret !== 'void' ? 'return _r' : 'pass'}\n\n\nstatic func ${n}0(${args})${m[2] || ''}:\n`;
  s = s.replace(re, wrapper);
}
writeFileSync(f, s);
console.log('hook-8 applied');
