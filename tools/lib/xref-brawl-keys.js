'use strict';
// Cross-reference for the blast's ender run, copied to tools/lib/xref-brawl-keys.js by docs/tools/pending/apply-brawl-required-keys.cjs and called from xref-fight.js:
//   brawl-order  data/director/interrupts.json brawl.energy.reach.blast.enderRun is at most brawl.flurry.runToClose: a run never goes past the close, so a larger enderRun would make the blast never an ender

const IT = 'data/director/interrupts.json';

function xrefBrawlKeys({ get, err, isObj }) {
  const itr = get(IT);
  if (!isObj(itr) || !isObj(itr.brawl)) return;
  const b = itr.brawl;
  const blast = isObj(b.energy) && isObj(b.energy.reach) ? b.energy.reach.blast : null;
  const close = isObj(b.flurry) ? b.flurry.runToClose : undefined;
  if (isObj(blast) && Number.isInteger(blast.enderRun) && Number.isInteger(close) && blast.enderRun > close) {
    err(IT, '/brawl/energy/reach/blast/enderRun', 'brawl-order', `enderRun ${blast.enderRun} is above flurry.runToClose ${close}: a run never gets that high, so the blast would never be an ender`);
  }
}

module.exports = { xrefBrawlKeys };
