'use strict';
// Cross-reference rules for data/input/ (docs/controls/input-schema.md, ADR 0008): the action list, the layout presets and the
// timing table. Called from xref.js with its helpers: get(rel), err(file, pointer, rule, message, level), esc, isObj.

const ACTIONS = 'data/input/actions.json';
const LAYOUTS = 'data/input/layouts.json';
const TIMING = 'data/input/timing.json';
const STANCES = 'data/input/stances.json';

const KB_RESERVED = new Set(['kb:KeyN', 'kb:KeyT', 'kb:KeyY', 'kb:KeyP', 'kb:Escape']);
// The strike actions a preset's parked strikeBindings may use (sim/input/layout.gd reads these four) and how many controls each takes: the strike stick is one pad control or four keys with an axis, its
// D-pad mirror four controls with an axis, the single-key strike and the keyboard brace one control.
const STRIKE_ACTIONS = { strike: 'one control, or four with an axis of four directions', strike_mirror: 'four controls with an axis of four directions', strike_key: 'one control', brace_key: 'one control' };
const strikeShapeOk = (action, b) => {
  const n = Array.isArray(b.controls) ? b.controls.length : 0;
  const four = n === 4 && Array.isArray(b.axis) && b.axis.length === 4;
  if (action === 'strike') return four || (n === 1 && b.axis === undefined);
  if (action === 'strike_mirror') return four;
  return n === 1 && b.axis === undefined;
};
const LAYERABLE = /^(special[0-9]+|special_auto|signature|upgrade_[a-z]+)$/;
// Actions every preset must bind for its device. Two documented relaxations (see docs/tools/README.md):
// the Simple presets reach the heavy and the signature through the upgrade gestures, and a keyboard preset has no
// pause binding because its pause keys (P, Escape) are reserved for the system.
const SATISFIES = { heavy: ['heavy', 'upgrade_heavy'], signature: ['signature', 'upgrade_sig'] };

function xrefInput({ get, err, esc, isObj }) {
  const actionsDoc = get(ACTIONS);
  const layoutsDoc = get(LAYOUTS);
  const timing = get(TIMING);
  const actionIds = new Set();

  if (isObj(actionsDoc) && Array.isArray(actionsDoc.actions)) {
    const seen = new Map();
    actionsDoc.actions.forEach((a, i) => {
      if (!isObj(a)) return;
      if (seen.has(a.id)) err(ACTIONS, `/actions/${i}/id`, 'actions-id', `action id "${a.id}" is already used at ${seen.get(a.id)}`);
      else seen.set(a.id, `/actions/${i}`);
      actionIds.add(a.id);
      if ((a.kind === 'layer' || a.kind === 'gesture') && a.value === undefined) err(ACTIONS, `/actions/${i}`, 'actions-value', `a ${a.kind} action needs a value`);
      if (a.kind === 'layer' && a.layer === undefined) err(ACTIONS, `/actions/${i}`, 'actions-layer', 'a layer action names its layer');
    });
  }

  if (isObj(layoutsDoc) && Array.isArray(layoutsDoc.presets)) {
    const presets = layoutsDoc.presets.filter(isObj);
    const byId = new Map(presets.map((p) => [p.id, p]));
    const controlsOf = (p) => new Set([...(Array.isArray(p.bindings) ? p.bindings : []), ...(Array.isArray(p.strikeBindings) ? p.strikeBindings : [])].flatMap((b) => (isObj(b) && Array.isArray(b.controls) ? b.controls : [])));

    layoutsDoc.presets.forEach((p, pi) => {
      if (!isObj(p) || !Array.isArray(p.bindings)) return;
      const at = `/presets/${pi}`;
      const bindings = p.bindings.filter(isObj);
      const slot = isObj(p.slot) ? p.slot : {};

      // layout-action
      if (actionIds.size) {
        p.bindings.forEach((b, bi) => {
          if (isObj(b) && typeof b.action === 'string' && !actionIds.has(b.action)) err(LAYOUTS, `${at}/bindings/${bi}/action`, 'layout-action', `action "${b.action}" is not in actions.json`);
        });
      }
      // layout-device
      p.bindings.forEach((b, bi) => {
        if (!isObj(b) || !Array.isArray(b.controls)) return;
        b.controls.forEach((c, ci) => {
          if (typeof c === 'string' && c.split(':')[0] !== p.device) err(LAYOUTS, `${at}/bindings/${bi}/controls/${ci}`, 'layout-device', `control "${c}" does not belong to a ${p.device} preset`);
        });
      });
      // layout-required
      const bound = new Set(bindings.map((b) => b.action));
      const need = ['move', 'light', 'heavy', 'signature', 'guard', 'dodge', 'power', 'context', 'transform'];
      if (p.device !== 'kb') need.push('pause');
      if (slot.autoMode !== true) need.push('mode');
      if (slot.specialPick === 'auto') need.push('special_auto');
      else need.push('special1', 'special2', 'special3');
      for (const a of need) {
        const ok = (SATISFIES[a] || [a]).some((x) => bound.has(x));
        if (!ok) err(LAYOUTS, at, 'layout-required', `preset "${p.id}" does not bind the required action "${a}"`);
      }
      // layout-conflict: one action per control per layer (gestures and chord parts are exempt)
      const byControl = new Map();
      bindings.forEach((b, bi) => {
        if (b.gesture !== undefined || !Array.isArray(b.controls)) return;
        const single = b.controls.length === 1 || (b.action === 'move' && Array.isArray(b.axis));
        if (!single) return;
        for (const c of b.controls) {
          const key = `${b.layer || 'base'}|${c}`;
          const prev = byControl.get(key);
          if (prev && prev.action !== b.action) err(LAYOUTS, `${at}/bindings/${bi}`, 'layout-conflict', `control "${c}" is bound to "${prev.action}" and to "${b.action}" on the ${b.layer || 'base'} layer`);
          else if (!prev) byControl.set(key, { action: b.action, index: bi });
        }
      });
      // layout-layer
      const layered = bindings.filter((b) => b.layer === 'power');
      if (layered.length && !bindings.some((b) => b.action === 'power' && b.layer === undefined)) err(LAYOUTS, at, 'layout-layer', `preset "${p.id}" has power-layer bindings but does not bind "power"`);
      p.bindings.forEach((b, bi) => {
        if (isObj(b) && b.layer === 'power' && typeof b.action === 'string' && !LAYERABLE.test(b.action)) err(LAYOUTS, `${at}/bindings/${bi}/action`, 'layout-layer', `"${b.action}" cannot be layered; only special*, signature and upgrade* may be`);
      });
      // layout-pair
      if (typeof p.pair === 'string') {
        const other = byId.get(p.pair);
        if (!other) err(LAYOUTS, `${at}/pair`, 'layout-pair', `pair "${p.pair}" is not a preset`);
        else {
          if (other.players !== 2 || p.players !== 2) err(LAYOUTS, `${at}/pair`, 'layout-pair', 'a pair is two presets with players: 2');
          if (other.pair !== p.id) err(LAYOUTS, `${at}/pair`, 'layout-pair', `"${p.pair}" does not point back at "${p.id}"`);
          const mine = controlsOf(p);
          const shared = [...controlsOf(other)].filter((c) => mine.has(c));
          if (shared.length) err(LAYOUTS, `${at}/pair`, 'layout-pair', `"${p.id}" and "${p.pair}" share ${shared.join(', ')}`);
        }
      }
      // layout-reserved
      if (p.device === 'kb') {
        p.bindings.forEach((b, bi) => {
          if (!isObj(b) || !Array.isArray(b.controls)) return;
          b.controls.forEach((c, ci) => {
            if (KB_RESERVED.has(c) || /^kb:F[0-9]+$/.test(c)) err(LAYOUTS, `${at}/bindings/${bi}/controls/${ci}`, 'layout-reserved', `"${c}" is reserved for the system (N, T, Y, P, Escape and the F-keys)`);
          });
        });
      }
      // layout-strike: the right-hand attacks' parked bindings (joined to `bindings` only while timing.json switches.rightStick is on): a known action, once each, of the right shape, on this preset's device,
      // on no control the preset already binds (nor reserved for the system), each control once
      if (Array.isArray(p.strikeBindings)) {
        const baseControls = new Set(bindings.flatMap((b) => (Array.isArray(b.controls) ? b.controls : [])));
        const seenAction = new Map(), seenControl = new Map();
        p.strikeBindings.forEach((b, bi) => {
          if (!isObj(b)) return;
          const at2 = `${at}/strikeBindings/${bi}`;
          if (typeof b.action === 'string') {
            if (!Object.prototype.hasOwnProperty.call(STRIKE_ACTIONS, b.action)) err(LAYOUTS, `${at2}/action`, 'layout-strike-action', `"${b.action}" is not a strike action (${Object.keys(STRIKE_ACTIONS).join(', ')})`);
            else {
              if (seenAction.has(b.action)) err(LAYOUTS, `${at2}/action`, 'layout-strike-action', `"${b.action}" is bound twice in strikeBindings (first at ${seenAction.get(b.action)})`);
              else seenAction.set(b.action, at2);
              if (!strikeShapeOk(b.action, b)) err(LAYOUTS, at2, 'layout-strike-shape', `"${b.action}" takes ${STRIKE_ACTIONS[b.action]}`);
            }
          }
          if (!Array.isArray(b.controls)) return;
          b.controls.forEach((c, ci) => {
            if (typeof c !== 'string') return;
            const cat = `${at2}/controls/${ci}`;
            if (c.split(':')[0] !== p.device) err(LAYOUTS, cat, 'layout-device', `control "${c}" does not belong to a ${p.device} preset`);
            if (p.device === 'kb' && (KB_RESERVED.has(c) || /^kb:F[0-9]+$/.test(c))) err(LAYOUTS, cat, 'layout-reserved', `"${c}" is reserved for the system (N, T, Y, P, Escape and the F-keys)`);
            if (baseControls.has(c)) err(LAYOUTS, cat, 'layout-strike-conflict', `control "${c}" is already bound in preset "${p.id}"'s bindings, so the right-hand attacks could not have it`);
            else if (seenControl.has(c)) err(LAYOUTS, cat, 'layout-strike-conflict', `control "${c}" is bound twice in strikeBindings (first at ${seenControl.get(c)})`);
            else seenControl.set(c, cat);
          });
        });
      }
      // layout-axis
      p.bindings.forEach((b, bi) => {
        if (isObj(b) && p.device === 'kb' && b.action === 'move' && !(Array.isArray(b.axis) && b.axis.length === 4 && Array.isArray(b.controls) && b.controls.length === 4)) {
          err(LAYOUTS, `${at}/bindings/${bi}`, 'layout-axis', 'a keyboard move binding needs four controls and an axis of four directions');
        }
      });
    });

    // layout-default: exactly one default per device
    const devices = [...new Set(presets.map((p) => p.device))];
    for (const dev of devices) {
      const ofDev = layoutsDoc.presets.map((p, i) => [p, i]).filter(([p]) => isObj(p) && p.device === dev);
      const defaults = ofDev.filter(([p]) => p.default === true);
      if (defaults.length !== 1) err(LAYOUTS, `/presets/${ofDev[0][1]}`, 'layout-default', `${dev} presets have ${defaults.length} defaults; exactly one is needed`);
    }
    const ids = new Map();
    layoutsDoc.presets.forEach((p, i) => {
      if (!isObj(p)) return;
      if (ids.has(p.id)) err(LAYOUTS, `/presets/${i}/id`, 'layout-id', `preset id "${p.id}" is already used at ${ids.get(p.id)}`);
      else ids.set(p.id, `/presets/${i}`);
    });
  }

  // stances-right-stick: the hybrid masks that come on with the right-hand switch are besides `hybrids`, never also in it
  const stancesDoc = get(STANCES);
  if (isObj(stancesDoc) && Array.isArray(stancesDoc.withRightStick)) {
    const on = new Set(Array.isArray(stancesDoc.hybrids) ? stancesDoc.hybrids : []);
    stancesDoc.withRightStick.forEach((m, i) => { if (on.has(m)) err(STANCES, `/withRightStick/${i}`, 'stances-right-stick', `mask ${m} is already in hybrids: withRightStick lists the ones that come on besides it`, 'warning'); });
  }

  if (isObj(timing)) {
    const th = isObj(timing.tapHold) ? timing.tapHold : {};
    const pb = isObj(timing.perfectBlock) ? timing.perfectBlock : {};
    const st = isObj(timing.stick) ? timing.stick : {};
    const hs = isObj(timing.hitstopTicks) ? timing.hitstopTicks : {};
    if (typeof st.triggerOff === 'number' && typeof st.triggerOn === 'number' && !(st.triggerOff < st.triggerOn)) err(TIMING, '/stick/triggerOff', 'timing-order', `triggerOff ${st.triggerOff} must be below triggerOn ${st.triggerOn}`);
    if (Number.isInteger(pb.lightWindow) && pb.lightWindow > 15) err(TIMING, '/perfectBlock/lightWindow', 'timing-perfect', `lightWindow ${pb.lightWindow} is above 15, the authored tell`);
    if (Number.isInteger(pb.heavyWindow) && pb.heavyWindow > 20) err(TIMING, '/perfectBlock/heavyWindow', 'timing-perfect', `heavyWindow ${pb.heavyWindow} is above 20, the authored tell`);
    if (Number.isInteger(th.encoreConfirm) && Number.isInteger(th.transformConfirm) && th.encoreConfirm > th.transformConfirm) err(TIMING, '/tapHold/encoreConfirm', 'timing-hold', `encoreConfirm ${th.encoreConfirm} must not exceed transformConfirm ${th.transformConfirm}`);
    if (Number.isInteger(th.transformConfirm) && Number.isInteger(th.encoreOffer) && !(th.transformConfirm < th.encoreOffer)) err(TIMING, '/tapHold/encoreOffer', 'timing-hold', `transformConfirm ${th.transformConfirm} must be below encoreOffer ${th.encoreOffer}`);
    for (const [chain, label] of [[['light', 'chain', 'heavy', 'guardBreak', 'parry'], 'light <= chain <= heavy <= guardBreak <= parry'], [['beamConnect', 'beamClash', 'finalBlow'], 'beamConnect <= beamClash <= finalBlow']]) {
      for (let i = 0; i + 1 < chain.length; i++) {
        const a = hs[chain[i]];
        const b = hs[chain[i + 1]];
        if (Number.isInteger(a) && Number.isInteger(b) && a > b) err(TIMING, `/hitstopTicks/${chain[i]}`, 'timing-hitstop-order', `${chain[i]} (${a}) should not exceed ${chain[i + 1]} (${b}); the impact hierarchy is ${label}`, 'warning');
      }
    }
    const sk = isObj(timing.strike) ? timing.strike : {};
    if (typeof sk.on === 'number' && typeof sk.off === 'number' && !(sk.off < sk.on)) err(TIMING, '/strike/off', 'timing-strike-order', `off ${sk.off} must be below on ${sk.on}: a stick back under off is at rest, a push past on is a request`);
    for (const k of ['levels', 'beamLevels']) {
      const v = sk[k];
      if (Array.isArray(v) && v.every(Number.isInteger) && v.some((x, i) => i > 0 && !(v[i - 1] < x))) err(TIMING, `/strike/${k}`, 'timing-strike-levels', `${k} ${JSON.stringify(v)} must rise: each level is reached later than the one before`);
    }
    const am = isObj(timing.aim) ? timing.aim : {};
    if (Number.isInteger(am.dwellTicks) && Number.isInteger(am.exitWindow) && am.dwellTicks > am.exitWindow) err(TIMING, '/aim/dwellTicks', 'timing-aim', `dwellTicks ${am.dwellTicks} is above exitWindow ${am.exitWindow}: a direction cannot be held for more ticks than the exit read looks back over`);
    const rd = isObj(timing.read) ? timing.read : {};
    const lt2 = (x, y, pointer, what) => { if (Number.isInteger(rd[x]) && Number.isInteger(rd[y]) && rd[x] > rd[y]) err(TIMING, pointer, 'timing-read', what); };
    lt2('simpleMediumStart', 'simpleHeavyStart', '/read/simpleMediumStart', `simpleMediumStart ${rd.simpleMediumStart} is above simpleHeavyStart ${rd.simpleHeavyStart}: on the Simple layout the medium's hold cannot be longer than the heavy's`);
    if (Number.isInteger(rd.windupMedium) && Number.isInteger(rd.windupHeavy) && rd.windupMedium >= rd.windupHeavy) err(TIMING, '/read/windupMedium', 'timing-read', `windupMedium ${rd.windupMedium} is not below windupHeavy ${rd.windupHeavy}: the heavy's wind-up is the longer`);
    lt2('pairWindow', 'pairFresh', '/read/pairWindow', `pairWindow ${rd.pairWindow} is above pairFresh ${rd.pairFresh}: a pair would be wider than the freshness it asks of its two buttons`);
    const grace = Number.isInteger(rd.windupGrace) ? rd.windupGrace : 0;
    for (const k of ['windupMedium', 'windupHeavy', 'windupContext']) if (Number.isInteger(rd[k]) && Number.isInteger(rd.staleTicks) && rd[k] + grace > rd.staleTicks) err(TIMING, `/read/${k}`, 'timing-read', `${k} ${rd[k]} plus the grace ${grace} is the decision point, and it is later than staleTicks ${rd.staleTicks}: the log would have forgotten the press`);
    for (const k of ['flurryGapX', 'flurryGapY', 'flurryGapB']) lt2(k, 'staleTicks', `/read/${k}`, `${k} ${rd[k]} is longer than staleTicks ${rd.staleTicks}: a flurry could not be continued after the log has forgotten it`);
    lt2('flurryNeedSlow', 'logSize', '/read/flurryNeedSlow', `a flurry of ${rd.flurryNeedSlow} presses cannot be seen in a log of ${rd.logSize}`);
    if (Number.isInteger(rd.mixupSwitches) && Number.isInteger(rd.logSize) && rd.mixupSwitches >= rd.logSize) err(TIMING, '/read/mixupSwitches', 'timing-read', `${rd.mixupSwitches} switches need more than ${rd.logSize} presses, and the log keeps ${rd.logSize}`);
    lt2('rhythmNeed', 'rhythmOf', '/read/rhythmNeed', `rhythmNeed ${rd.rhythmNeed} is more than the ${rd.rhythmOf} presses rhythm looks at`);
    lt2('mashPresses', 'logSize', '/read/mashPresses', `a mash of ${rd.mashPresses} presses cannot be seen in a log of ${rd.logSize}`);
    lt2('mixShort', 'logSize', '/read/mixShort', `mixShort ${rd.mixShort} is more than the ${rd.logSize} presses the log keeps`);
    lt2('rhythmOf', 'logSize', '/read/rhythmOf', `rhythm looks at ${rd.rhythmOf} presses but the log keeps ${rd.logSize}`);
    lt2('mashGap', 'mashClear', '/read/mashGap', `mashGap ${rd.mashGap} is longer than mashClear ${rd.mashClear}, so a mash would be over before its next press`);
    lt2('mashClear', 'staleTicks', '/read/mashClear', `mashClear ${rd.mashClear} is longer than staleTicks ${rd.staleTicks}, so a log would read as nothing while a mash is still counted`);
    for (const [k, v] of Object.entries(hs)) {
      if (!k.startsWith('_') && Number.isInteger(v) && v > 30) err(TIMING, `/hitstopTicks/${esc(k)}`, 'timing-hitstop-budget', `${k} is ${v} ticks; more than 30 reads as a hang`);
    }
  }
}

module.exports = { xrefInput };
