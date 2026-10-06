// Origin: the search that picks the colour-vision presets' lane colours (deterministic: a fixed grid, no randomness).
// Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-06. Human direction: Orb, via the EP.
import { dE00, simulate, fromHsl, hsl, lchOf, toOklab, toLab } from '../sky/colour.mjs';
import { CUES, DEFAULT_LANES, skySamples } from './cues.mjs';

const SK = skySamples(), SKY = SK.map(s => s.hex), SKY_HL = SK.filter(s => s.band === 'horizon' || s.band === 'lower').map(s => s.hex), CUE = Object.values(CUES);
// Legal's hue families for the auras (docs/legal/rule-of-cool-screen.md): the Protagonist cool (green to blue), the Anti-hero violet (hue 260 to 320); never white, red, orange, gold or yellow
export const FAMILY = { protagonist: { h: [150, 250], l: [26, 88], s: [45, 100] }, rival: { h: [260, 320], l: [26, 88], s: [40, 100] } };

export function scoreOne(hexc, kind) {
  const x = simulate(hexc, kind);
  let dCue = 99, dSky = 99, dHL = 99, wc = '', ws = '';
  for (const [n, c] of Object.entries(CUES)) { const d = dE00(x, simulate(c, kind)); if (d < dCue) { dCue = d; wc = n; } }
  for (const s of SKY) { const d = dE00(x, simulate(s, kind)); if (d < dSky) { dSky = d; ws = s; } }
  for (const s of SKY_HL) { const d = dE00(x, simulate(s, kind)); if (d < dHL) dHL = d; }
  return { dCue, dSky, dHL, wc, ws, x };
}
export function candidates(fighter, kind) {
  const F = FAMILY[fighter], out = [];
  for (let h = F.h[0]; h <= F.h[1]; h += 5) for (let s = F.s[0]; s <= F.s[1]; s += 10) for (let l = F.l[0]; l <= F.l[1]; l += 4) { const hexc = fromHsl(h, s, l), sc = scoreOne(hexc, kind); out.push({ hex: hexc, h, s, l, ...sc, base: Math.min(sc.dCue, sc.dHL, sc.dSky * 1.6) }); }
  return out.sort((a, b) => b.base - a.base);
}
// the pair: from the best of each family, the pair with the largest of (the smaller of its own distances and the distance between them)
export function bestPair(kind, K = 60) {
  const P = candidates('protagonist', kind).slice(0, K), A = candidates('rival', kind).slice(0, K);
  let best = null;
  for (const p of P) for (const a of A) {
    const between = dE00(p.x, a.x), score = Math.min(p.base, a.base, between);
    // prefer a colour near the default when the scores are close (a smaller change to the look)
    const near = -(Math.hypot(...toOklab(p.hex).map((v, i) => v - toOklab(DEFAULT_LANES.protagonist.aura)[i])) + Math.hypot(...toOklab(a.hex).map((v, i) => v - toOklab(DEFAULT_LANES.rival.aura)[i])));
    const tot = score + 0.05 * near;
    if (!best || tot > best.tot) best = { p, a, between, score, tot };
  }
  return best;
}
export function defaultScore(kind) {
  const P = scoreOne(DEFAULT_LANES.protagonist.aura, kind), A = scoreOne(DEFAULT_LANES.rival.aura, kind);
  return { P, A, between: dE00(P.x, A.x) };
}

// the choice rule: every candidate must clear a floor against the wound and guard marks and against the sky near the fighters; the pair must be far apart;
// of those, take the pair nearest to the default colours (the smallest change to the look)
export function pick(kind, floors = { cue: 18, hl: 15, between: 25 }) {
  const near = (hx, ref) => Math.hypot(...toOklab(hx).map((v, i) => v - toOklab(ref)[i]));
  const P = candidates('protagonist', kind).filter(c => c.dCue >= floors.cue && c.dHL >= floors.hl && c.s <= 90), A = candidates('rival', kind).filter(c => c.dCue >= floors.cue && c.dHL >= floors.hl && c.s <= 90);
  let best = null;
  for (const p of P) for (const a of A) { const between = dE00(p.x, a.x); if (between < floors.between) continue; if (floors.gap && Math.abs(toLab(p.x)[0] - toLab(a.x)[0]) < floors.gap) continue; const d = near(p.hex, DEFAULT_LANES.protagonist.aura) + near(a.hex, DEFAULT_LANES.rival.aura); if (!best || d < best.d) best = { p, a, between, d, floors }; }
  return best;
}

// the strongest pair: the largest of the smallest distance (to the wound and guard marks, to the sky near the fighters, and between the two), a lightness gap of at least 25 L*,
// colours not more saturated than 90 (so the presets stay in the game's feel); ties go to the pair nearest the default
export function strongest(kind, K = 80) {
  const near = (hx, ref) => Math.hypot(...toOklab(hx).map((v, i) => v - toOklab(ref)[i]));
  const P = candidates('protagonist', kind).filter(c => c.s <= 90).slice(0, K), A = candidates('rival', kind).filter(c => c.s <= 90).slice(0, K);
  let best = null;
  for (const p of P) for (const a of A) {
    if (Math.abs(toLab(p.x)[0] - toLab(a.x)[0]) < 25) continue;
    const between = dE00(p.x, a.x), score = Math.min(p.dCue, p.dHL, a.dCue, a.dHL, between), d = near(p.hex, DEFAULT_LANES.protagonist.aura) + near(a.hex, DEFAULT_LANES.rival.aura);
    const tot = score - 4 * d;
    if (!best || tot > best.tot) best = { p, a, between, score, d, tot };
  }
  return best;
}
