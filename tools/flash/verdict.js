// How a clip's analysis (tools/flash/wcag.js analyse) is shown: one place for the table columns and the verdict of the combined rule (Legal, RL-119 and RL-120), used by
// analyse-frames.js and run-pixels.mjs. PASS, OVER GATE or FAIL: FAIL when the worst second is over 3 on the primary reading (one-second memory), with the area threshold 15% lower,
// or with a two-second memory (general or red); OVER GATE when the primary reading is over 2.5 and nothing is over 3; PASS otherwise.
'use strict';

const HEADER = `${'general'.padStart(8)} ${'red'.padStart(4)} ${'area-15%'.padStart(9)} ${'2 s mem'.padStart(8)} ${'margin'.padStart(7)} ${'dips'.padStart(5)}  verdict`;

/** The columns of one result. margin = changes of the worst second within 15% above the area threshold, over the changes of that second (general + red). */
function columns(r) {
  const c = r.combined;
  const worst = r.general.worstSecond.length + r.red.worstSecond.length;
  const marg = r.general.marginal + r.red.marginal;
  const stricter = c.stricter === null ? 'n/a' : String(c.stricter);
  return `${String(r.general.flashes).padStart(8)} ${String(r.red.flashes).padStart(4)} ${String(c.lower).padStart(9)} ${stricter.padStart(8)} ${(marg + '/' + worst).padStart(7)} ${String(r.dips.list.length).padStart(5)}  ${c.verdict}${c.reasons.length ? ': ' + c.reasons.join('; ') : ''}${c.crossChecked ? '' : ' (no two-second cross-check: the clip is too short)'}`;
}

module.exports = { HEADER, columns };
