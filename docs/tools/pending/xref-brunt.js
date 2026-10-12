'use strict';
// Order rules for World's data/biomes/brunt.json, copied to tools/lib/xref-brunt.js by docs/tools/pending/apply-biomes-brunt.cjs and called from xref-fight.js:
//   brunt-order  tierFactor, chainMax, towerPunches and lodgeSeconds never fall from tier 1 to 4; chainSpecial is at least chainMax's last, lodgeSpecialSeconds at least lodgeSeconds'
//                last; keepMin is at most keepHi, which is at most keepFree

const F = 'data/biomes/brunt.json';

function xrefBrunt({ get, err, isObj }) {
  const d = get(F);
  if (!isObj(d)) return;
  const num = (x) => typeof x === 'number' && Number.isFinite(x);
  for (const k of ['tierFactor', 'chainMax', 'towerPunches', 'lodgeSeconds']) {
    const a = d[k];
    if (!Array.isArray(a)) continue;
    for (let i = 1; i < a.length; i++) {
      if (num(a[i]) && num(a[i - 1]) && a[i] < a[i - 1]) err(F, `/${k}/${i}`, 'brunt-order', `${k}[${i}] ${a[i]} is below the tier before (${a[i - 1]}): the ladder does not fall with the tier`);
    }
  }
  const last = (a) => (Array.isArray(a) && a.length ? a[a.length - 1] : undefined);
  if (num(d.chainSpecial) && num(last(d.chainMax)) && d.chainSpecial < last(d.chainMax)) err(F, '/chainSpecial', 'brunt-order', `chainSpecial ${d.chainSpecial} is below tier 4's chainMax ${last(d.chainMax)}`);
  if (num(d.lodgeSpecialSeconds) && num(last(d.lodgeSeconds)) && d.lodgeSpecialSeconds < last(d.lodgeSeconds)) err(F, '/lodgeSpecialSeconds', 'brunt-order', `lodgeSpecialSeconds ${d.lodgeSpecialSeconds} is below tier 4's lodgeSeconds ${last(d.lodgeSeconds)}`);
  if (num(d.keepMin) && num(d.keepHi) && d.keepMin > d.keepHi) err(F, '/keepMin', 'brunt-order', `keepMin ${d.keepMin} is above keepHi ${d.keepHi}`);
  if (num(d.keepHi) && num(d.keepFree) && d.keepHi > d.keepFree) err(F, '/keepHi', 'brunt-order', `keepHi ${d.keepHi} is above keepFree ${d.keepFree}: speed kept through gone floors is at least that through punched ones`);
}

module.exports = { xrefBrunt };
