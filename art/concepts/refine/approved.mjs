// Origin: the approved looks of the launch pair as figure-kit concepts, for the turnarounds and close-up sets (deterministic, no randomness, no external images or fonts).
// Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-04. Human direction: Orb, via the EP.
// Approved by Orb (2026-10-04): the Protagonist (broad body, dark plated fists, short swept tuft) and the rival (slim, long tail, flat coat plates, glasses frame C, the bare wedge).
// The side and three-quarter views reuse the approved figures; the front and back views get their own head, because the kit's face is a profile.

import { V, add, rotCW, pts } from '../anti-hero/kit.mjs';
import { OTHER_OPTS, rivalTail, rivalPlates } from './figures.mjs';
import { profileGlasses, FRAMES, INK, APPROVED } from './glasses.mjs';

// the build change that separates them: the Protagonist broader, the rival slimmer
export const scaled = (c, k) => ({ ...c, build: { tw: 1, tl: 1, lw: 1, hs: 1, leg: 1, arm: 1, ...(c.build ?? {}), tw: (c.build?.tw ?? 1) * k[0], lw: (c.build?.lw ?? 1) * k[1] } });
const raw = (a, fill, extra = '') => `<polygon points="${pts(a.map(p => Array.isArray(p) ? V(p[0], p[1]) : p))}" fill="${fill}" ${extra}/>`;
const ell = (cx, cy, rx, ry, n = 10) => Array.from({ length: n }, (_, i) => [cx + Math.cos(i / n * Math.PI * 2) * rx, cy + Math.sin(i / n * Math.PI * 2) * ry]);
// a point on the head from a depth a (forward), a lateral b and a height y, in the view's projection
const headAt = (sk, a, b, y) => add(sk.HB, rotCW(V((sk.yaw.c * a - b * sk.yaw.s) * sk.b.hs, y * sk.b.hs), sk.headAng));
const bodyAt = (sk, o, a, b, y) => add(o, rotCW(V((sk.yaw.c * a - b * sk.yaw.s) * sk.b.tw, y * sk.b.tl), sk.lean));

// ---------------------------------------------------------------------------------------------------- the Protagonist
export function hero(view) {
  const c = scaled(OTHER_OPTS.P.options[1].make(), [1.2, 1.14]);
  if (view.yaw < 60) return c;
  return {
    ...c, machineHead: true,
    blankHead: (pal, st) => {
      const back = st.face === 'back';
      const eye = s => ell(1.35 * s, 10.0, 0.62, 0.5), pup = s => ell(1.35 * s + 0.1, 9.95, 0.3, 0.3, 8);
      return {
        poly: [[-3, 6.5], [-2.7, 2.4], [-1.5, 0.6], [1.5, 0.6], [2.7, 2.4], [3, 6.5], [3, 12.5], [2.4, 15.6], [-2.4, 15.6], [-3, 12.5]],
        fill: back ? pal.hair.mid : pal.skin.mid, shadow: pal.skin.shadow, neck: pal.skin.shadow,
        marks: back ? [] : [{ poly: eye(-1), fill: '#f3efe8' }, { poly: eye(1), fill: '#f3efe8' }, { poly: pup(-1), fill: pal.line }, { poly: pup(1), fill: pal.line },
          { poly: [[-2.2, 11.5], [-0.5, 11.2], [-0.5, 11.9], [-2.2, 12.1]], fill: pal.hair.mid }, { poly: [[0.5, 11.2], [2.2, 11.5], [2.2, 12.1], [0.5, 11.9]], fill: pal.hair.mid },
          { poly: [[-0.9, 4.6], [0.9, 4.6], [0.9, 5.0], [-0.9, 5.0]], fill: pal.line }],
      };
    },
    // the short swept tuft: from the front it is a low cap with the tuft folded behind
    hair: (ctx, sk) => ctx.poly([[-3.3, 11.8], [-3.5, 16.2], [-0.8, 18.4], [2.8, 17.4], [3.5, 15], [3.3, 11.8], [1.6, 13.6], [0, 12], [-1.8, 13.8]].map(([x, y]) => sk.Hd(x, y)), ctx.pal.hair.mid),
  };
}

// ---------------------------------------------------------------------------------------------------- the rival (frame C)
// face-art coordinates (the close-up engine's, 21.8 units to one head unit) mapped onto the front of the head: lateral u, height y
const fromFace = ([x, y], k = 0.9) => [x * k / 21.8, 10 - (y + 36) / 21.8];
export function rival(view, state = 'clear') {
  const base = scaled(OTHER_OPTS.A.base(), [0.92, 0.94]), add_ = profileGlasses(APPROVED, state);
  if (view.yaw < 60) {
    const c = scaled(OTHER_OPTS.A.options[0].make(), [0.92, 0.94]), prev = c.after;
    return { ...c, after: (ctx, sk, st, cfg) => (prev ? prev(ctx, sk, st, cfg) : '') + add_(ctx, sk) };
  }
  const back = !!view.back;
  const lens = FRAMES[APPROVED].lens;
  // the lenses on the front of the head, as polygons in head units; right then left
  const R = lens.map(([x, y]) => fromFace([x * 1.12 + 68, y * 1.28 - 36])), L = R.map(([x, y]) => [-x, y]).reverse();
  return {
    ...base, machineHead: true,
    hair: (ctx, sk, st) => ctx.poly((back
      ? [[-3.2, 0.6], [-3.4, 16.4], [-1, 18.2], [2.2, 18], [3.4, 16.2], [3.2, 0.6], [1.6, 3], [0, 1.4], [-1.6, 3]]
      : [[-3.2, 11.5], [-3.4, 16.4], [-1, 18.2], [2.2, 18], [3.4, 16.2], [3.2, 11.5], [1.6, 14], [0.2, 12], [-1.2, 13.8]]).map(([x, y]) => sk.Hd(x, y)), ctx.pal.hair.mid),
    blankHead: (pal, st) => {
      const eye = s => ell(1.3 * s, 10.0, 0.62, 0.42), pup = s => ell(1.3 * s + 0.1, 9.98, 0.28, 0.28, 8);
      return {
        poly: [[-2.8, 6.5], [-2.5, 2.6], [-1.2, 0.6], [1.2, 0.6], [2.5, 2.6], [2.8, 6.5], [2.8, 12.5], [2.2, 15.6], [-2.2, 15.6], [-2.8, 12.5]],
        fill: back ? pal.hair.mid : pal.skin.mid, shadow: pal.skin.shadow, neck: pal.skin.shadow,
        marks: back ? [] : [{ poly: eye(-1), fill: '#f3efe8' }, { poly: eye(1), fill: '#f3efe8' }, { poly: pup(-1), fill: pal.line }, { poly: pup(1), fill: pal.line },
          { poly: [[-2.1, 11.0], [-0.5, 10.7], [-0.5, 11.2], [-2.1, 11.6]], fill: pal.hair.mid }, { poly: [[0.5, 10.7], [2.1, 11.0], [2.1, 11.6], [0.5, 11.2]], fill: pal.hair.mid },
          { poly: [[-0.8, 4.7], [0.8, 4.7], [0.8, 4.95], [-0.8, 4.95]], fill: pal.line },
          { poly: [[-2.3, 8], [-1.7, 8], [-1.9, 3.2], [-2.5, 3.2]], fill: pal.accent.light }],
      };
    },
    // the glasses on the front of the face (never from behind), and the tail down the back (never from the front)
    after: (ctx, sk, st, cfg) => {
      let s = rivalPlates(ctx, sk);
      if (!back) {
        const P = a => a.map(([u, y]) => sk.Hd(u / 1.8 * 1, y));
        for (const a of [L, R]) s += raw(P(a), INK.TINT, 'opacity="0.55"') + raw(P(a), 'none', `stroke="${INK.FRAME_INK}" stroke-width="0.34" stroke-linejoin="round"`);
        s += raw(P([[-0.5, 10.0], [0.5, 10.0], [0.5, 10.3], [-0.5, 10.3]]), INK.FRAME_INK);
      } else {
        // the tail as a tube down the middle of the back: a ribbon of constant visible width, tapering
        const path = [[-4.5, 12, 3.0], [-7, 0, 2.7], [-8, -14, 2.2], [-7.5, -26, 1.5], [-6.5, -36, 0.5]].map(([a, y, w]) => ({ p: headAt(sk, a, 0, y), w }));
        const left = [], right = [];
        path.forEach((q, i) => { const p0 = path[Math.max(0, i - 1)].p, p1 = path[Math.min(path.length - 1, i + 1)].p, dx = p1.x - p0.x, dy = p1.y - p0.y, l = Math.hypot(dx, dy) || 1, nx = -dy / l, ny = dx / l; left.push(V(q.p.x + nx * q.w, q.p.y + ny * q.w)); right.push(V(q.p.x - nx * q.w, q.p.y - ny * q.w)); });
        s += ctx.poly([...left, ...right.reverse()], ctx.pal.hair.mid, { sw: 1.3 });
      }
      return s;
    },
  };
}
