// Pad lab, the maths. Pure functions, no DOM, no network: Node loads this with require(), the page with a plain script tag (window.PadLabCore).
// Samples are arrays of { t (ms), x, y }. Stick axes use the gamepad convention: x right is +, y down is + (so "up" on the stick is y < 0).
// Honest limit: the page samples once per animation frame, so every time here has a resolution of one frame (about 16 ms at 60 Hz).
(function () {
  'use strict';

  const hypot = Math.hypot;
  const mean = (a) => (a.length ? a.reduce((s, v) => s + v, 0) / a.length : 0);
  const std = (a) => { if (!a.length) return 0; const m = mean(a); return Math.sqrt(mean(a.map((v) => (v - m) * (v - m)))); };
  const median = (a) => {
    if (!a.length) return null;
    const s = a.slice().sort((p, q) => p - q);
    const h = s.length >> 1;
    return s.length % 2 ? s[h] : (s[h - 1] + s[h]) / 2;
  };
  /** Rounds up to 0.01 (with a small allowance so 0.15 stays 0.15 and not 0.16). */
  const ceil2 = (v) => Math.round(Math.ceil(v * 100 - 1e-9)) / 100;
  const round = (v, d) => { if (!Number.isFinite(v)) return v; const k = Math.pow(10, d); return Math.round(v * k) / k; };
  const wrap180 = (d) => { let r = d % 360; if (r > 180) r -= 360; if (r <= -180) r += 360; return r; };
  /** Screen angle of a stick position in degrees, counter-clockwise from "right" (right 0, up 90, left 180, down -90). */
  const angleDeg = (x, y) => (Math.atan2(-y, x) * 180) / Math.PI;

  /** median, min, max, spread (max minus min) and standard deviation of a list of numbers. */
  function summarize(values) {
    const v = (values || []).filter(Number.isFinite);
    if (!v.length) return { n: 0, median: null, min: null, max: null, spread: null, std: null };
    const mn = Math.min(...v), mx = Math.max(...v);
    return { n: v.length, median: median(v), min: mn, max: mx, spread: mx - mn, std: std(v) };
  }

  // ---- rest: dead zone and drift --------------------------------------------------------------------------------------------------------
  /** The stick left alone. Offset = mean position; noise = how far readings stray (max distance from zero, max distance from the mean, standard deviation);
   *  drift = the mean of the last second minus the mean of the first second; deadzone = noise ceiling x 1.5 rounded up to 0.01, never below 0.05. */
  function restStats(samples) {
    const n = samples ? samples.length : 0;
    if (n < 2) return { ok: false, n, reason: 'not enough samples' };
    const xs = samples.map((s) => s.x), ys = samples.map((s) => s.y);
    const mx = mean(xs), my = mean(ys);
    let maxMag = 0, maxDev = 0;
    for (const s of samples) { maxMag = Math.max(maxMag, hypot(s.x, s.y)); maxDev = Math.max(maxDev, hypot(s.x - mx, s.y - my)); }
    const sx = std(xs), sy = std(ys);
    const t0 = samples[0].t, t1 = samples[n - 1].t, dur = t1 - t0;
    const win = Math.min(1000, dur / 3);
    const first = samples.filter((s) => s.t - t0 < win), last = samples.filter((s) => t1 - s.t < win);
    const dx = first.length && last.length ? mean(last.map((s) => s.x)) - mean(first.map((s) => s.x)) : 0;
    const dy = first.length && last.length ? mean(last.map((s) => s.y)) - mean(first.map((s) => s.y)) : 0;
    const ceiling = maxMag;
    return {
      ok: true, n, durationMs: dur,
      offset: { x: mx, y: my, mag: hypot(mx, my) },
      noise: { maxMag, maxDev, std: hypot(sx, sy), stdX: sx, stdY: sy },
      drift: { x: dx, y: dy, mag: hypot(dx, dy), windowMs: win },
      noiseCeiling: ceiling,
      deadzone: Math.max(0.05, ceil2(1.5 * ceiling)),
    };
  }

  // ---- one flick: rise time, spring-back, overshoot -------------------------------------------------------------------------------------
  /** One flick, from a little before the push to after the stick came back. opts.rest = { x, y, band }: the rest position (subtracted) and the rest-noise radius
   *  that counts as "back at rest" (default 0, 0 and 0.02).
   *  riseMs: time from 10% to 90% of the flick's peak magnitude (linear interpolation between frames; the true resolution is still one frame).
   *  releaseT: the moment the magnitude falls below 90% of the peak after the peak. springMs: from release until the stick is back inside the band and stays there.
   *  overshoot: the largest push on the opposite side of centre after release, as a share of the peak. */
  function flickStats(samples, opts) {
    const o = opts || {};
    const rest = o.rest || {};
    const rx = rest.x || 0, ry = rest.y || 0;
    const band = rest.band > 0 ? rest.band : 0.02;
    if (!samples || samples.length < 4) return { ok: false, reason: 'too few samples' };
    const pts = samples.map((s) => ({ t: s.t, x: s.x - rx, y: s.y - ry, m: hypot(s.x - rx, s.y - ry) }));
    let pk = 0;
    for (let i = 1; i < pts.length; i++) if (pts[i].m > pts[pk].m) pk = i;
    const peak = pts[pk].m;
    if (peak < 0.2) return { ok: false, reason: 'the push was too small to measure' };
    const dirx = pts[pk].x / peak, diry = pts[pk].y / peak;
    // crossing time going backwards from the peak: the last frame before the peak that is below the level
    const backCross = (level) => {
      let i = pk;
      while (i >= 0 && pts[i].m >= level) i--;
      if (i < 0) return { t: pts[0].t, clipped: true };
      const a = pts[i], b = pts[i + 1];
      return { t: a.t + ((level - a.m) / (b.m - a.m)) * (b.t - a.t), clipped: false };
    };
    const c90 = backCross(0.9 * peak), c10 = backCross(0.1 * peak);
    // release: first frame after the peak below 90%
    let j = pk;
    while (j < pts.length && pts[j].m >= 0.9 * peak) j++;
    if (j >= pts.length) return { ok: false, reason: 'the stick was not let go before the recording ended' };
    const a0 = pts[j - 1], b0 = pts[j];
    const releaseT = a0.t + ((a0.m - 0.9 * peak) / (a0.m - b0.m)) * (b0.t - a0.t);
    // first entry into the band, and the last (the stick settled)
    let firstEntry = null;
    for (let i = j; i < pts.length; i++) {
      if (pts[i].m <= band) {
        const a = pts[i - 1], b = pts[i];
        firstEntry = a.t + ((a.m - band) / (a.m - b.m)) * (b.t - a.t);
        break;
      }
    }
    let k = pts.length - 1;
    while (k >= j && pts[k].m <= band) k--;
    let settleT = null;
    if (k < pts.length - 1) {
      if (k < j) settleT = firstEntry;
      else { const a = pts[k], b = pts[k + 1]; settleT = a.t + ((a.m - band) / (a.m - b.m)) * (b.t - a.t); }
    }
    let minP = 0;
    for (let i = j; i < pts.length; i++) minP = Math.min(minP, pts[i].x * dirx + pts[i].y * diry);
    const overshootMag = Math.max(0, -minP);
    return {
      ok: true, peak, peakT: pts[pk].t, angleDeg: angleDeg(dirx, diry),
      t10: c10.t, t90: c90.t, riseMs: c90.t - c10.t, riseClipped: c10.clipped || c90.clipped,
      releaseT, firstEntryMs: firstEntry === null ? null : firstEntry - releaseT,
      settled: settleT !== null, springMs: settleT === null ? null : settleT - releaseT,
      overshootMag, overshoot: overshootMag / peak,
    };
  }

  // ---- aim: eight compass directions ----------------------------------------------------------------------------------------------------
  /** samples: { t, x, y, dir } where dir is an index into nominalAngles (degrees, counter-clockwise from right: use angleDeg's convention); without dir the nearest
   *  nominal angle is used. Only samples with magnitude above opts.minMag (0.7) count, and the first opts.skipMs of each direction (the swing in) are left out.
   *  Per direction: mean angle error (signed: + is counter-clockwise on screen) and its standard deviation. Overall spread = the within-direction standard deviation pooled
   *  over all samples; rmsError = typical distance from the target direction; worst = the direction with the biggest rms error. */
  function aimStats(samples, nominalAngles, opts) {
    const o = opts || {};
    const minMag = o.minMag === undefined ? 0.7 : o.minMag;
    const skipMs = o.skipMs || 0;
    const by = nominalAngles.map(() => []);
    for (const s of samples || []) {
      if (hypot(s.x, s.y) <= minMag) continue;
      const a = angleDeg(s.x, s.y);
      let d = s.dir;
      if (d === undefined || d === null) {
        let best = 0, bd = 1e9;
        nominalAngles.forEach((na, i) => { const e = Math.abs(wrap180(a - na)); if (e < bd) { bd = e; best = i; } });
        d = best;
      }
      by[d].push({ t: s.t, a, m: hypot(s.x, s.y) });
    }
    const perDir = nominalAngles.map((na, i) => {
      const list = by[i].sort((p, q) => p.t - q.t);
      const kept = list.length ? list.filter((p) => p.t - list[0].t >= skipMs) : [];
      const errs = kept.map((p) => wrap180(p.a - na));
      const me = mean(errs), sd = std(errs);
      return { index: i, nominal: na, n: errs.length, meanErr: errs.length ? me : null, sd: errs.length ? sd : null, rms: errs.length ? Math.sqrt(mean(errs.map((e) => e * e))) : null, meanMag: errs.length ? mean(kept.map((p) => p.m)) : null };
    });
    const used = perDir.filter((d) => d.n > 0);
    const N = used.reduce((s, d) => s + d.n, 0);
    if (!N) return { ok: false, perDir, reason: 'no samples above the magnitude limit' };
    const spread = Math.sqrt(used.reduce((s, d) => s + d.n * d.sd * d.sd, 0) / N);
    const rmsError = Math.sqrt(used.reduce((s, d) => s + d.n * d.rms * d.rms, 0) / N);
    const biasRms = Math.sqrt(mean(used.map((d) => d.meanErr * d.meanErr)));
    let worst = used[0];
    for (const d of used) if (d.rms > worst.rms) worst = d;
    return { ok: true, n: N, directionsMeasured: used.length, spreadDeg: spread, rmsErrorDeg: rmsError, biasRmsDeg: biasRms, worst: { index: worst.index, nominal: worst.nominal, rms: worst.rms, meanErr: worst.meanErr, sd: worst.sd }, perDir };
  }

  // ---- suggestions in the game's units (data/input/timing.json: stick.deadzone 0.2, triggerOn 0.35, triggerOff 0.25, awayDead 0.3) ------------------------------------------
  /** Suggested values from the measurements. They are suggestions only; nothing here changes the game. triggerRestMax (optional) = the biggest trigger value seen with hands off. */
  function recommend(m) {
    const a = m || {};
    const rest = a.rest && a.rest.ok ? a.rest : null;
    const deadzone = rest ? rest.deadzone : 0.05;
    const awayDead = Math.max(ceil2(deadzone * 1.5), ceil2(deadzone + 0.05));
    const out = { deadzone, awayDead };
    const notes = [];
    if (Number.isFinite(a.triggerRestMax)) {
      const off = Math.max(0.25, ceil2(a.triggerRestMax + 0.15));
      out.triggerOff = off;
      out.triggerOn = Math.max(0.35, ceil2(off + 0.1));
    } else { out.triggerOn = 0.35; out.triggerOff = 0.25; notes.push('triggerOn and triggerOff were not measured: these are the game\'s current values, unchanged'); }
    const rise = a.rise && a.rise.n ? a.rise.median : null;
    const spring = a.spring && a.spring.n ? a.spring.median : null;
    if (rise !== null) out.flickRiseMs = Math.round(rise);
    if (spring !== null) out.springBackMs = Math.round(spring);
    if (a.aim && a.aim.ok) out.aimToleranceDeg = Math.max(5, Math.ceil(2 * a.aim.spreadDeg));
    if (!rest) notes.push('no rest measurement: deadzone is the 0.05 floor');
    out.notes = notes;
    out.isSuggestion = true;
    return out;
  }

  // ---- phantom pads ---------------------------------------------------------------------------------------------------------------------
  const PD = { jitter: 0.03, offCenter: 0.1, moveRange: 0.08, liveMs: 350, windowMs: 1000, mirrorTol: 0.01, mirrorMinFrames: 8, mirrorShare: 0.9, deflect: 0.3, pushed: 0.3, stickAxes: 4 };

  /** Biggest max-minus-min of vs inside any time window of w ms (sliding window, one pass). */
  function bestWindowRange(ts, vs, w) {
    const n = ts.length;
    let best = 0, lo = 0, hmax = 0, hmin = 0;
    const qmax = [], qmin = [];
    for (let i = 0; i < n; i++) {
      const v = vs[i];
      while (qmax.length > hmax && vs[qmax[qmax.length - 1]] <= v) qmax.pop();
      qmax.push(i);
      while (qmin.length > hmin && vs[qmin[qmin.length - 1]] >= v) qmin.pop();
      qmin.push(i);
      while (ts[i] - ts[lo] > w) lo++;
      while (qmax[hmax] < lo) hmax++;
      while (qmin[hmin] < lo) hmin++;
      best = Math.max(best, vs[qmax[hmax]] - vs[qmin[hmin]]);
    }
    return best;
  }

  const padOf = (frame, i) => (frame && frame.pads && frame.pads[i]) || null;

  /** history = { idle: frames, active: frames }; a frame is { t, pads: [ pad | null, ... ] } and a pad is { index, id, mapping, connected, axes: [..], buttons: [values..] }.
   *  idle = the frames recorded with hands off every pad; active = the frames from normal use (pushing sticks).
   *  Finds: pads that move by themselves or sit off centre in the idle frames, the pad that moved most, the pad(s) moving right now (the last opts.liveMs of active),
   *  and pads that carry exactly the same values as another pad while a stick is pushed ("mirror of pad N"). summary = plain sentences. */
  function phantomReport(history, opts) {
    const o = Object.assign({}, PD, opts || {});
    const idle = (history && history.idle) || [], active = (history && history.active) || [];
    const indices = new Set();
    for (const f of idle.concat(active)) (f.pads || []).forEach((p, i) => { if (p) indices.add(p.index === undefined ? i : p.index); });
    const idxList = [...indices].sort((a, b) => a - b);
    const lastOf = (frames, i) => { for (let k = frames.length - 1; k >= 0; k--) { const p = padOf(frames[k], i); if (p) return p; } return null; };
    const pads = idxList.map((i) => {
      const info = lastOf(active, i) || lastOf(idle, i) || {};
      const rec = { index: i, id: info.id || '', mapping: info.mapping || '', connected: info.connected !== false, axes: (info.axes || []).length, buttons: (info.buttons || []).length, flags: [], idle: null, peakRange: 0, recentRange: 0, mirrorOf: null, silent: false, movesByItself: false, offCenter: false };
      // idle test
      const fr = idle.filter((f) => padOf(f, i) && padOf(f, i).connected !== false);
      if (fr.length >= 5) {
        const nAx = padOf(fr[0], i).axes.length;
        const ranges = [], means = [];
        for (let k = 0; k < nAx; k++) {
          const vs = fr.map((f) => padOf(f, i).axes[k]).filter(Number.isFinite);
          ranges.push(vs.length ? Math.max(...vs) - Math.min(...vs) : 0);
          means.push(mean(vs));
        }
        const nBt = padOf(fr[0], i).buttons.length;
        const btRanges = [];
        for (let k = 0; k < nBt; k++) {
          const vs = fr.map((f) => padOf(f, i).buttons[k]).filter(Number.isFinite);
          btRanges.push(vs.length ? Math.max(...vs) - Math.min(...vs) : 0);
        }
        const limit = rec.mapping === 'standard' ? 1.01 : 0.95;   // an unmapped pad may rest a trigger axis at -1: that is not a stick sitting off centre
        const wobbling = [], off = [], btn = [];
        ranges.forEach((r, k) => { if (r > o.jitter) wobbling.push({ axis: k, range: r }); });
        means.slice(0, o.stickAxes).forEach((mv, k) => { if (Math.abs(mv) > o.offCenter && Math.abs(mv) < limit) off.push({ axis: k, mean: mv }); });
        btRanges.forEach((r, k) => { if (r > 0.05) btn.push({ button: k, range: r }); });
        rec.idle = { frames: fr.length, ranges, means, wobbling, offCenter: off, buttonsChanging: btn };
        rec.movesByItself = wobbling.length > 0 || btn.length > 0;
        rec.offCenter = off.length > 0;
        if (wobbling.length) rec.flags.push({ kind: 'moves-by-itself', text: 'moves by itself (axis ' + wobbling.map((w) => w.axis + ' by ' + w.range.toFixed(2)).join(', axis ') + ' with nobody touching it): a phantom pad or a drifting stick' });
        if (btn.length) rec.flags.push({ kind: 'buttons-by-themselves', text: 'buttons change by themselves (button ' + btn.map((b) => b.button).join(', ') + ')' });
        if (off.length) rec.flags.push({ kind: 'off-centre', text: 'sits away from zero with nobody touching it (axis ' + off.map((w) => w.axis + ' at ' + w.mean.toFixed(2)).join(', axis ') + ')' });
      }
      // active use: the best one-second range of any stick axis
      const act = active.filter((f) => padOf(f, i) && padOf(f, i).connected !== false);
      if (act.length >= 2) {
        const ts = act.map((f) => f.t);
        const nAx = Math.min(o.stickAxes, padOf(act[act.length - 1], i).axes.length);
        for (let k = 0; k < nAx; k++) {
          const vs = act.map((f) => { const p = padOf(f, i); return p.axes[k] === undefined ? 0 : p.axes[k]; });
          rec.peakRange = Math.max(rec.peakRange, bestWindowRange(ts, vs, o.windowMs));
          const tEnd = ts[ts.length - 1];
          let mn = Infinity, mx = -Infinity;
          for (let q = vs.length - 1; q >= 0 && tEnd - ts[q] <= o.liveMs; q--) { mn = Math.min(mn, vs[q]); mx = Math.max(mx, vs[q]); }
          if (mx >= mn) rec.recentRange = Math.max(rec.recentRange, mx - mn);
        }
      }
      return rec;
    });

    // mirrors: the same values on two pads while a stick is deflected
    const mirrors = [];
    for (let a = 0; a < pads.length; a++) {
      for (let b = a + 1; b < pads.length; b++) {
        if (pads[b].mirrorOf !== null) continue;
        const ia = pads[a].index, ib = pads[b].index;
        let cand = 0, same = 0;
        for (const f of active) {
          const pa = padOf(f, ia), pb = padOf(f, ib);
          if (!pa || !pb || pa.connected === false || pb.connected === false) continue;
          const n = Math.min(o.stickAxes, pa.axes.length, pb.axes.length);
          if (!n) continue;
          let deflected = false, equal = true;
          for (let k = 0; k < n; k++) {
            if (Math.abs(pa.axes[k]) >= o.deflect || Math.abs(pb.axes[k]) >= o.deflect) deflected = true;
            if (Math.abs(pa.axes[k] - pb.axes[k]) > o.mirrorTol) equal = false;
          }
          if (!deflected) continue;
          cand++;
          if (equal) same++;
        }
        if (cand >= o.mirrorMinFrames && same / cand >= o.mirrorShare) {
          pads[b].mirrorOf = ia;
          pads[b].flags.push({ kind: 'mirror', text: 'mirror of pad ' + ia + ' (the same values at the same time: one of the two is a copy)' });
          mirrors.push({ pad: ib, of: ia, frames: cand });
        }
      }
    }

    // silent pads: a pad that stayed still while another pad was pushed hard
    const bestOther = (p) => Math.max(0, ...pads.filter((q) => q.index !== p.index).map((q) => q.peakRange));
    for (const p of pads) {
      if (p.connected && p.axes >= 2 && p.mirrorOf === null && p.peakRange < o.moveRange && bestOther(p) >= 0.5) {
        p.silent = true;
        p.flags.push({ kind: 'silent', text: 'did not react while another pad was pushed (if the game reads this pad it sees nothing)' });
      }
    }

    // moving right now
    const moving = pads.filter((p) => p.recentRange > o.moveRange).sort((a, b) => b.recentRange - a.recentRange);
    const leader = moving.length ? moving[0].index : null;

    // the default pad to measure: moved most, not flagged as a phantom or a copy
    const usable = pads.filter((p) => p.connected && p.axes >= 2 && p.mirrorOf === null && !p.movesByItself);
    const pool = usable.length ? usable : pads.filter((p) => p.connected && p.axes >= 2);
    const ranked = pool.slice().sort((a, b) => b.peakRange - a.peakRange || a.index - b.index);
    let defaultPad = null;
    if (ranked.length) {
      defaultPad = ranked[0].peakRange >= o.pushed
        ? { index: ranked[0].index, reason: 'it moved the most when you pushed a stick' }
        : { index: ranked[0].index, reason: 'nobody has pushed a stick yet, so this is the first usable pad' };
    }

    // plain sentences
    const summary = [];
    const name = (p) => 'Pad ' + p.index + (p.id ? ' (' + p.id + ')' : '');
    const idleRun = pads.some((p) => p.idle);
    if (!pads.length) summary.push('No pad is reported by the browser. Press a button on the controller (Chrome shows a pad only after a first press).');
    if (idleRun) {
      const bad = pads.filter((p) => p.idle && (p.movesByItself || p.offCenter));
      if (!bad.length) summary.push('Idle test: no pad moved by itself and none sat away from zero. No phantom pad found.');
      for (const p of bad) summary.push('Idle test: ' + name(p) + ' ' + p.flags.filter((f) => f.kind !== 'mirror' && f.kind !== 'silent').map((f) => f.text).join('; ') + '.');
    } else if (pads.length) summary.push('The idle test has not been run yet (hands off every pad for a few seconds).');
    for (const m of mirrors) summary.push('Pad ' + m.pad + ' is a mirror of pad ' + m.of + ': it showed exactly the same values at the same time while a stick was pushed.');
    for (const p of pads) if (p.silent) summary.push(name(p) + ' did not move while another pad was pushed. If the game reads this pad, it sees nothing.');
    if (leader !== null) summary.push('Right now the pad that is moving is pad ' + leader + '.');
    else if (defaultPad && defaultPad.reason.indexOf('moved the most') >= 0) summary.push('The stick you pushed is on pad ' + defaultPad.index + '.');
    return { pads, mirrors, moving: { pads: moving.map((p) => p.index), leader }, defaultPad, summary, options: o };
  }

  const api = { mean, std, median, ceil2, round, wrap180, angleDeg, summarize, restStats, flickStats, aimStats, recommend, phantomReport, bestWindowRange };
  if (typeof module === 'object' && module && module.exports) module.exports = api;
  if (typeof window !== 'undefined') window.PadLabCore = api;
})();
