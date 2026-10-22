// cc.cjs: cam_intent v3: the touchdown on Simulation's launch curve, and the story cut (below) (Simulation's shared park: SimFlight.track,
// tick, predict). With the curve on (S.flightOn), the send's cam_intent launch cue takes its touchdown from the curve,
// stepped from the body as sent (and met at the aimed building's face), plus the stop still to run. Off, or with the
// feed off, the cue is today's. It writes only the cue, so play and the golden don't move.
//   node cc.cjs <checkout root> [--check]   (after Simulation's shared park)
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node cc.cjs <checkout root> [--check]');
const check = opts.includes('--check');
function edit(rel, fn) {
  const p = path.join(root, rel);
  let t = fs.readFileSync(p, 'utf8');
  const crlf = t.includes('\r\n');
  if (crlf) t = t.replace(/\r\n/g, '\n');
  const rep = (a, b) => {
    const n = t.split(a).length - 1;
    if (n !== 1) throw new Error(rel + ': expected 1 match, got ' + n + ' for: ' + a.slice(0, 90));
    t = t.replace(a, () => b);
  };
  fn(rep);
  if (!check) fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  console.log(rel + (check ? ': anchors ok' : ': ok'));
}
if (!fs.readFileSync(path.join(root, 'sim/core/flight.gd'), 'utf8').includes('static func predict(')) throw new Error('Simulation\'s shared park first (SimFlight.predict)');
edit('sim/director/melee.gd', rep => {
  rep('\tDirBrawl.markKind(S, tgt, lkind)\n',
      '\tDirCamIntent.launched(S, tgt)   # the camera-intent feed: with the launch curve, the touchdown is the curve\'s\n' +
      '\tDirBrawl.markKind(S, tgt, lkind)\n');
});
edit('sim/director/camintent.gd', rep => {
  rep('\t_send(S, f, o, "clinch", plan)\n',
      '\t_send(S, f, o, "clinch", plan)\n\n\n' +
      '## After the send (DirMelee.launchBeat, once the body flies): with Simulation\'s launch curve on, the touchdown is the\n' +
      '## curve\'s. SimFlight\'s track is stepped from the body as sent, to the ground or the water (SimFlight.predict) or to\n' +
      '## the aimed building\'s near face, the way the flight meets it; the stop still to run is added. The launch cue\'s n,\n' +
      '## dur and x, and its land, take it. A set piece\'s send and a knock-back\'s slide aren\'t paced, so they keep the\n' +
      '## planner\'s. Off (the curve or the feed), nothing changes.\n' +
      'static func launched(S: SimState, tgt) -> void:\n' +
      '\tif not on() or not S.flightOn or tgt.state != "launched" or tgt.launchSpecial or tgt.slideFeet:\n\t\treturn\n' +
      '\tvar slot: int = _slot(S, tgt)\n' +
      '\tvar e = null\n' +
      '\tfor i in range(S.out.fx.size() - 1, -1, -1):\n' +
      '\t\tvar x = S.out.fx[i]\n' +
      '\t\tif String(x.type) == "cue" and String(x.kind) == "cam_intent" and String(x.text) == "launch" and int(x.target) == slot:\n' +
      '\t\t\te = x\n\t\t\tbreak\n' +
      '\tif e == null:\n\t\treturn\n' +
      '\tvar p: PackedFloat64Array = SimFlight.predict(S, tgt.x, tgt.y, tgt.vx, tgt.vy, tgt.aimB)\n' +
      '\tvar n: int = int(p[0])\n' +
      '\tvar lx: float = p[1]\n' +
      '\tif tgt.aimB >= 0 and tgt.aimB < S.buildings.size() and S.buildings[tgt.aimB].alive:\n' +
      '\t\tvar b = S.buildings[tgt.aimB]\n' +
      '\t\tvar dir: float = SimMathx.jsign(tgt.vx)\n' +
      '\t\tvar edge: float = SimWrap.wrap(b.x - dir * b.w * 0.5)\n' +
      '\t\tvar tr = SimFlight.track(tgt.x, tgt.y, tgt.vx, tgt.vy, tgt.aimB)\n' +
      '\t\tvar most: int = n if n > 0 else 900\n' +
      '\t\twhile tr.t < most:\n' +
      '\t\t\tvar ox: float = tr.x\n' +
      '\t\t\tSimFlight.tick(S, tr)\n' +
      '\t\t\tif SimWrap.sdx(ox, edge) * dir > 0.0 and SimWrap.sdx(tr.x, edge) * dir <= 0.0:\n' +
      '\t\t\t\tn = tr.t   # he meets the aimed face\n\t\t\t\tlx = edge\n\t\t\t\tbreak\n' +
      '\tif n < 0:\n\t\treturn\n' +
      '\tvar held: int = SimFx.stopTicks(S.dirS.stop)   # the stop still to run: the flight starts after it\n' +
      '\te.n = S.tick + held + n\n' +
      '\te.dur = float(n)\n' +
      '\te.x = lx\n' +
      '\tif e.has_meta("launch"):\n' +
      '\t\tvar m: Dictionary = e.get_meta("launch")\n' +
      '\t\tm["land"] = {"x": lx, "n": int(e.n)}\n' +
      '\t\tm["curve"] = true\n' +
      '\t\te.set_meta("launch", m)\n');
});

// The story cut (the EP's finding from Rendering's roll probe, 2026-10-22): every decisive moment is told as a plan as
// it happens; a beam at its fire, a beam clash at its start and a finisher at its plan are told; a plan's weight starts
// from what it holds (a finisher 5; a beam or a clash 4; a launch, a guard break or a clash's resolve 3; a heavy or a
// knock-back 2) and its "decisive" tag is the outcome's when it is known, else "big".
edit('sim/director/camintent.gd', rep => {
  rep('const WEIGHT: Dictionary = {"strike": 1, "chainStrike": 1, "window": 0, "dodge": 1, "slip": 1, "stagger": 3, "rush": 1,\n\t"launch": 4, "knockBack": 4, "guardBreak": 4, "clashResolve": 4, "clashWave": 4, "beamFire": 4, "beamImpact": 4}\n',
      'const WEIGHT: Dictionary = {"strike": 1, "chainStrike": 1, "window": 0, "dodge": 1, "slip": 1, "stagger": 3, "rush": 1,\n\t"launch": 4, "knockBack": 4, "guardBreak": 4, "clashResolve": 4, "clashWave": 4, "beamFire": 4, "beamImpact": 4, "beamReach": 4}\n');
  rep('\t"clashResolve": "set", "clashWave": "set", "beamFire": "set", "beamImpact": "set"}\n',
      '\t"clashResolve": "set", "clashWave": "set", "beamFire": "set", "beamImpact": "set", "beamReach": "set"}\n');
  rep('const DECISIVE: Array = ["launch", "knockBack", "guardBreak", "clashResolve", "beamFire", "beamImpact"]\n',
      'const DECISIVE: Array = ["launch", "knockBack", "guardBreak", "clashResolve", "beamFire", "beamImpact", "beamReach"]\n');
  rep('const STRIKES: Array = ["strike", "chainStrike", "launch", "knockBack", "guardBreak", "beamImpact"]\n',
      'const STRIKES: Array = ["strike", "chainStrike", "launch", "knockBack", "guardBreak", "beamImpact", "beamReach"]\n');
  rep("## The story the beat tells (Research's rec 16: spend by story weight). a attacks, d defends; fav the side the plan\n## favours (a, d or null); big: the plan has a launch, a heavy or a set piece.\nstatic func _story(S: SimState, ex, a, d, fav, big: bool, finisher: bool) -> Dictionary:\n",
      "## The story the beat tells (Research's rec 16: spend by story weight). a attacks, d defends; fav the side the plan\n## favours (a, d or null); big: the plan has a launch, a heavy or a set piece. base: what the plan holds (a finisher 5;\n## a beam or a clash 4; a launch, a guard break or a clash's resolve 3; a heavy or a knock-back 2; else 1), and each\n## of reversal, comeback, crippling and first blood adds one, to 5. known: its outcome is decided, so it is tagged\n## decisive; a big plan whose outcome isn't is tagged big.\nstatic func _story(S: SimState, ex, a, d, fav, big: bool, finisher: bool, base: int = 1, known: bool = false) -> Dictionary:\n");
  rep('\tif big or a.brink or d.brink:\n\t\ttags.append("decisive")\n',
      '\tif known:\n\t\ttags.append("decisive")\n\telif big or a.brink or d.brink:\n\t\ttags.append("big")\n');
  rep('\treturn {"w": 5 if finisher else mini(5, tags.size()), "tags": tags}\n',
      '\tvar bonus: int = 0\n\tfor tg in tags:\n\t\tif tg == "reversal" or tg == "comeback" or tg == "crippling" or tg == "first_blood":\n\t\t\tbonus += 1\n' +
      '\treturn {"w": 5 if finisher else mini(5, maxi(1, base) + bonus), "tags": tags}\n');
  rep('## A planned exchange has its beats (DirExchange._start, after the alchemist dressed them).\nstatic func exchange(S: SimState, ex) -> void:\n',
      "## A planned exchange has its beats (DirExchange._start, after the alchemist dressed them). why: what told it again\n## (\"finisher\" at its plan, \"clash\" at a beam clash's start, \"beam\" and \"beam:<outcome>\" at a beam's fire), or \"\".\nstatic func exchange(S: SimState, ex, why: String = \"\") -> void:\n");
  rep('\tvar fin: bool = String(ex.tag) == "FINISHER" or String(ex.tpl).begins_with("finisher")\n',
      '\tvar fin: bool = why == "finisher" or String(ex.tag) == "FINISHER" or String(ex.tpl).begins_with("finisher")\n' +
      '\tvar resolves: bool = false\n\tfor x in beats:\n\t\tif String(x.op) == "guardBreak" or String(x.op) == "clashResolve":\n\t\t\tresolves = true\n' +
      '\tvar base: int = 5 if fin else (4 if (why == "clash" or why.begins_with("beam") or beam[0] >= 0) else (3 if (launchAt >= 0 or resolves) else (2 if big else 1)))\n' +
      '\tvar known: bool = fin or why == "clash" or why == "beam:HIT" or (big and int(ex.loser) >= 0)\n');
  rep('\t\t"story": _story(S, ex, ex.A, ex.D, fav, big, fin)}\n\t_send(S, ex.A, ex.D, String(ex.tpl), plan)\n',
      '\t\t"story": _story(S, ex, ex.A, ex.D, fav, big, fin, base, known)}\n\t_send(S, ex.A, ex.D, String(ex.tpl) if why == "" else why, plan)\n');
  rep('\t\t"story": _story(S, S.dirS.ex, f, o, f if (lau or closing) else null, lau or closing or kind == "heavy", false)}\n',
      '\t\t"story": _story(S, S.dirS.ex, f, o, f if (lau or closing) else null, lau or closing or kind == "heavy", false, 3 if lau else (2 if (closing or kind == "heavy") else 1), lau and int(args.get("safety", 1)) == 1)}\n');
  rep('\t\t"beam": false, "story": {"w": 2, "tags": ["decisive", "clash"]}}\n',
      '\t\t"beam": false, "story": {"w": 3, "tags": ["decisive", "clash"]}}\n');
  rep('## The send, from the plan (DirMelee.launchBeat, before doLaunch).',
      '## A decisive exchange is won (DirExchange.decisive and decisiveShot): the moment itself, told as it happens, so the\n' +
      "## camera holds its story whatever came before it. Its kind (why), the exchange's beats still to come, and its weight:\n" +
      '## a clash or a beam 4, a launch, a guard break or an interrupt 3, a knock-back or a shot 2, and one more when the\n' +
      '## loser is on the brink (a set-up or a finisher follows).\n' +
      'static func decisive(S: SimState, W, L, why: String) -> void:\n' +
      '\tif not on() or W == null or L == null:\n\t\treturn\n' +
      '\tvar base: int = int({"clash": 4, "beam": 4, "beam_clash": 4, "launch": 3, "guard_break": 3, "interrupt": 3, "knockback": 2, "blast": 2}.get(why, 3)) + (1 if L.brink else 0)\n' +
      '\tvar beats: Array = [{"n": S.tick, "op": why, "kind": "set", "w": 4, "a": _slot(S, W), "d": _slot(S, L)}]\n' +
      '\tvar contacts: Array = [S.tick]\n' +
      '\tvar ex = S.dirS.ex\n' +
      '\tif ex != null:\n' +
      '\t\tfor b in ex.beats:\n' +
      '\t\t\tif not b.done and WEIGHT.has(b.op):\n' +
      '\t\t\t\tvar n: int = tickOf(S, ex, b.t)\n' +
      '\t\t\t\tbeats.append({"n": n, "op": String(b.op), "kind": String(KIND[b.op]), "w": int(WEIGHT[b.op]), "a": _slot(S, W), "d": _slot(S, L)})\n' +
      '\t\t\t\tif STRIKES.has(b.op):\n\t\t\t\t\tcontacts.append(n)\n' +
      '\tvar plan := {"ex": int(S.dirS.exN), "tpl": "decisive:" + why, "a": _slot(S, W), "d": _slot(S, L), "at": S.tick,\n' +
      '\t\t"beats": beats, "contacts": contacts, "pauses": [], "noCut": [[S.tick - 4, S.tick + 24]], "launch": {}, "set": true,\n' +
      '\t\t"beam": why.begins_with("beam"), "story": _story(S, ex, W, L, W, true, false, base, true)}\n' +
      '\t_send(S, W, L, "decisive", plan)\n\n\n' +
      '## The send, from the plan (DirMelee.launchBeat, before doLaunch).');
});
edit('sim/director/exchange.gd', rep => {
  rep('\tif S.game.ko != null or ex == null:\n\t\treturn\n\tSimFx.decisive(S, W, L, why)\n',
      '\tif S.game.ko != null or ex == null:\n\t\treturn\n\tDirCamIntent.decisive(S, W, L, why)   # the camera-intent feed: the decisive moment, told as it happens\n\tSimFx.decisive(S, W, L, why)\n');
  rep('\tif S.game.ko != null:\n\t\treturn\n\tSimFx.decisive(S, W, L, why)\n\tSimWounds.onDecisive(S, null, W, L, why)\n',
      '\tif S.game.ko != null:\n\t\treturn\n\tDirCamIntent.decisive(S, W, L, why)   # the camera-intent feed: the decisive moment, told as it happens\n\tSimFx.decisive(S, W, L, why)\n\tSimWounds.onDecisive(S, null, W, L, why)\n');
  rep('\tDirData.planFinisher(ex, W)\n\tif chk != null:\n\t\tplanCheck.call(chk, ex, S.rng.a, "finisher")\n',
      "\tDirData.planFinisher(ex, W)\n\tif chk != null:\n\t\tplanCheck.call(chk, ex, S.rng.a, \"finisher\")\n\tDirCamIntent.exchange(S, ex, \"finisher\")   # the camera-intent feed: the finisher's plan\n");
});
edit('sim/director/beam.gd', rep => {
  rep('\tDirExchange.schedule(ex, ex.t + 1.6, "clashResolve", {"aw": aw, "variant": variant})\n\tDirExchange.schedule(ex, ex.t + 2.6, "nop")\n',
      "\tDirExchange.schedule(ex, ex.t + 1.6, \"clashResolve\", {\"aw\": aw, \"variant\": variant})\n\tDirExchange.schedule(ex, ex.t + 2.6, \"nop\")\n\tDirCamIntent.exchange(S, ex, \"clash\")   # the camera-intent feed: the beam clash's plan\n");
  rep('\telse:\n\t\tDirExchange.schedule(ex, ex.t + 0.02, "beamEscape")\n\tDirExchange.schedule(ex, ex.t + 0.9, "nop")\n',
      "\telse:\n\t\tDirExchange.schedule(ex, ex.t + 0.02, \"beamEscape\")\n\tDirExchange.schedule(ex, ex.t + 0.9, \"nop\")\n\tDirCamIntent.exchange(S, ex, \"beam:\" + out)   # the camera-intent feed: the beam's plan, its outcome known\n");
});
edit('sim/director/beamplay.gd', rep => {
  rep('\tDirExchange.schedule(ex, ex.t + float(tv) / DirData.TICKS_PER_SEC, "beamReach", {"perfect": perfect, "ux": dxs / L, "uy": dyy / L, "dist": dist, "variant": String(args.variant)})\n',
      '\tDirExchange.schedule(ex, ex.t + float(tv) / DirData.TICKS_PER_SEC, "beamReach", {"perfect": perfect, "ux": dxs / L, "uy": dyy / L, "dist": dist, "variant": String(args.variant)})\n\tDirCamIntent.exchange(S, ex, "beam")   # the camera-intent feed: the beam on its way\n');
});
