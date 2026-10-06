// Origin: the gameplay-critical cue colours the lane colours must stay apart from (read from ui/core/ui_look.gd and render/core/look.gd on 2026-10-06), and the sky samples.
// Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-06. Human direction: Orb, via the EP.
import { KEYS, BANDS, moodSky } from '../sky/keys.mjs';

export const DEFAULT_LANES = { protagonist: { col: '#3d8fdc', aura: '#8fd6ff' }, rival: { col: '#a52a2a', aura: '#9a80d8' } };
// the marks that sit on or around a fighter's body and carry gameplay: the wound stages (ui/core/ui_look.gd STAGE_*, INTERNAL) and the guard (the defensive stance colour, STANCE_COL[1]).
// The HUD chips (charge, hidden, warn and the other stance colours) are shape-coded UI and are listed in HUD_CUES for UI to check; they are not part of the lane search.
// UI's own wound-stage sets per preset (ui/data/colour_vision.json), read from the file so they are never copied by hand. Since 2026-10-06 "fresh" is the neutral #dfe6f0.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
const UI = JSON.parse(readFileSync(join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..', 'ui', 'data', 'colour_vision.json'), 'utf8'));
export const FRESH = '#dfe6f0';
export const CUES_DEFAULT = { 'wound fresh': FRESH, 'wound bruised': '#f2e6a0', 'wound battered': '#ffb454', 'wound broken': '#ff5c8a', 'wound internal': '#bfeeff', 'guard': '#5aaaff' };
export const cuesFor = kind => { const m = UI.presets[kind]?.map; if (!m) return CUES_DEFAULT; return { 'wound fresh': FRESH, 'wound bruised': m.STAGE_BRUISED, 'wound battered': m.STAGE_BATTERED, 'wound broken': m.STAGE_BROKEN, 'wound internal': '#bfeeff', 'guard': '#5aaaff' }; };
export const CUES = CUES_DEFAULT;
export const HUD_CUES = { 'charge': '#5fb4ff', 'charge ready': '#c8e6ff', 'hidden': '#bedcff', 'warn': '#ffd45a', 'stance 1': '#ff6a5a', 'stance 3': '#62d986', 'stance 4': '#b892ff' };
// every sky colour a fighter can be seen against: each key, calm and under each mood extreme
export function skySamples() {
  const out = [];
  for (const k of KEYS) for (const m of [{}, { frenzy: 1 }, { ruin: 1 }, { frenzy: 1, ruin: 1, glow: 1 }, { glow: 1 }]) { const b = moodSky(k.bands, m); for (const bd of BANDS) out.push({ key: k.id, band: bd, hex: b[bd] }); }
  return out;
}
