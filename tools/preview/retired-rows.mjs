// The switch table as it was BEFORE the golden window GW1a retired the rows it landed (Tools, 2026-11-14). For the self-tests only: the engine checks (flip, the cascade, waiting, the scratch patch, the stack builds) were
// written on that table and still prove the engine, so they run on it, rebuilt here from the live rows and tools/preview/retired-rows.json (the retired rows whole, with their old place; the kept rows' old `needs`).
// useHistoricTable() changes SWITCHES and IDS (the table module's own arrays) IN PLACE and returns the function that puts the live ones back. Nothing in a build reads this file.
import { readFileSync } from 'node:fs';
import { SWITCHES, IDS } from './switches.mjs';

const FILE = JSON.parse(readFileSync(new URL('./retired-rows.json', import.meta.url), 'utf8'));
export const RETIRED_ROWS = FILE.rows;

/** The old table: the retired rows at their old places, the live rows between them in their order, each kept row's old `needs` put back. Pure. */
export function historicRows(live = SWITCHES) {
  const out = new Array(live.length + RETIRED_ROWS.length);
  for (const r of RETIRED_ROWS) { const { index, evidence, ...row } = r; out[index] = row; }
  let k = 0;
  for (const r of live) { while (out[k] !== undefined) k++; out[k] = FILE.keptNeedsBefore[r.id] ? { ...r, needs: FILE.keptNeedsBefore[r.id] } : r; }
  return out;
}

export function useHistoricTable() {
  const liveRows = SWITCHES.slice(), liveIds = IDS.slice();
  const hist = historicRows(liveRows);
  SWITCHES.splice(0, SWITCHES.length, ...hist);
  IDS.splice(0, IDS.length, ...hist.map((s) => s.id));
  return () => { SWITCHES.splice(0, SWITCHES.length, ...liveRows); IDS.splice(0, IDS.length, ...liveIds); };
}
