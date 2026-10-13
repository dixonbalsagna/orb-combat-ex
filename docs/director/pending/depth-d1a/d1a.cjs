// d1a.cjs <copy root>: depth, slice D1a: the drift. For a scratch export of main with Simulation's depth_a.py
// applied. Every new line is behind S.depthOn (or the frame it opens), so with depth off a match is the same to the
// bit: no draw is taken, no integer of mine is added, and every read takes today's arguments.
//
// The idea. A pair in a brawl stands on a line that sits 10 to 30 degrees from the street. The brawl's own rules
// (reach, the closing rule, giving ground, the 68-unit rule) are written in two axes: along the pair, and up. So
// for the director's part of a tick the pair is put in the line's own frame: each fighter's x becomes his distance
// along the line from the pair's middle, and both take the middle's depth. Every rule then runs as written, on true
// distances. At the end of the director's part each fighter is put back on the line in the world, through the
// core's SimFighter.stepTo, so a face stops him as it stops any step. The pair's velocity is turned the same way:
// along the line, plus the drift in depth (the carry, the ease home), held to the cap and to World's room.
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
function edit(rel, fn) {
  const p = path.join(root, rel);
  let t = fs.readFileSync(p, 'utf8');
  const crlf = t.includes('\r\n');
  if (crlf) t = t.replace(/\r\n/g, '\n');
  const ctx = {
    rep(a, b, times) {
      const n = t.split(a).length - 1;
      if (n !== (times || 1)) throw new Error(rel + ': expected ' + (times || 1) + ' match, got ' + n + ' for: ' + a.slice(0, 80));
      t = t.split(a).join(b);
    },
    // every WorldTerrain.groundY(S, <expr>) gains the depth it is read at
    ground(zexpr) {
      const key = 'WorldTerrain.groundY(S, ';
      let out = '', i = 0, n = 0;
      for (;;) {
        const at = t.indexOf(key, i);
        if (at < 0) { out += t.slice(i); break; }
        let j = at + key.length, depth = 1;
        while (depth > 0) { const c = t[j]; if (c === '(') depth++; else if (c === ')') depth--; j++; }
        const inner = t.slice(at + key.length, j - 1);
        out += t.slice(i, at) + key + inner + ', ' + zexpr + ')';
        i = j; n++;
      }
      t = out;
      return n;
    },
  };
  fn(ctx);
  fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  console.log(rel + ': ok');
}
const L = (...lines) => lines.join('\n') + '\n';

edit('sim/director/bands.gd', c => {
  c.rep(L(
    'static func dist(a, b) -> float:',
    '\treturn SimDetMath.hypot(SimWrap.sdx(a.x, b.x), b.y - a.y)'),
  L(
    'static func dist(a, b) -> float:',
    '\tif a.z != b.z and (a.zT != 0.0 or b.zT != 0.0):   # D1: in three axes. A home depth is set only with depth on; a flight into a building moves a fighter\'s depth with it off too, and that must read as it does today',
    '\t\treturn SimDetMath.hypot(SimDetMath.hypot(SimWrap.sdx(a.x, b.x), b.y - a.y), b.z - a.z)',
    '\treturn SimDetMath.hypot(SimWrap.sdx(a.x, b.x), b.y - a.y)'));
  c.rep(L(
    '\tr.end = S.T + float(n) * SimConst.DT',
    '\tA.rush = r'),
  L(
    '\tr.end = S.T + float(n) * SimConst.DT',
    '\tif S.depthOn:',
    '\t\tr.offZ = DirBrawl.arriveOff(S, D, r.off)   # D1: he arrives a little to one side in depth, on the brawl\'s line',
    '\tA.rush = r'));
});

edit('sim/director/brawl.gd', c => {
  const n = c.ground('_gz()');
  if (n !== 12) throw new Error('expected 12 ground reads, got ' + n);
  c.rep('\treturn WorldStructures.blockedAt(S, x, yy, 0.0, 0.0)\n', '\treturn WorldStructures.blockedAt(S, x, yy, _gz(), 0.0)\n');
  // ---- the start: the line
  c.rep('\t_reset(ex)\n\tSimAct.clear(ex.D)   # no request waits in a brawl: a press is a blow, or it is spent\n',
        '\t_reset(ex)\n\tif S.depthOn:\n\t\t_lineStart(S, ex)\n\tSimAct.clear(ex.D)   # no request waits in a brawl: a press is a blow, or it is spent\n');
  c.rep('\tex.loser = -1\n\t_reset(ex)\n\tfor f in [ex.A, ex.D]:\n\t\tSimAct.clear(f)\n',
        '\tex.loser = -1\n\t_reset(ex)\n\tif S.depthOn:\n\t\t_lineStart(S, ex)\n\tfor f in [ex.A, ex.D]:\n\t\tSimAct.clear(f)\n');
  // ---- the movement: the drift in depth, and the pair's velocity turned along the line
  c.rep('\t_s(A, CEN_VX, int(round(vx * 16.0)))\n\t_s(A, CEN_VY, int(round(vy * 16.0)))\n',
        '\tif _frOn:\n\t\t_moveZ(S, ex, wx, tx != 0.0 or ty != 0.0)\n\t_s(A, CEN_VX, int(round(vx * 16.0)))\n\t_s(A, CEN_VY, int(round(vy * 16.0)))\n');
  c.rep(L(
    '\t\tf.vx = float(_g(ex.A, MOVE_X)) / 16.0 / keep',
    '\t\tf.vy = float(_g(ex.A, MOVE_Y)) / 16.0 / keep'),
  L(
    '\t\tf.vx = float(_g(ex.A, MOVE_X)) / 16.0 / keep',
    '\t\tf.vy = float(_g(ex.A, MOVE_Y)) / 16.0 / keep',
    '\t\tif _frOn:   # D1: the pair moves along its line, and drifts in depth',
    '\t\t\tf.vx = float(_g(ex.A, MOVE_X)) / 16.0 * _frCos / keep',
    '\t\t\tf.vz = _frVz / keep'));
  // ---- the read for Camera, Animation and UI
  c.rep(L(
    '\treturn {"x": m[0], "y": m[1], "vx": (ex.A.vx + ex.D.vx) * 0.5 * keep, "vy": (ex.A.vy + ex.D.vy) * 0.5 * keep,',
    '\t\t"part": _g(ex.A, PART_N), "double": (maxi(0, dbl - _now(S)) if dbl > 0 else -1)}'),
  L(
    '\tvar out := {"x": m[0], "y": m[1], "vx": (ex.A.vx + ex.D.vx) * 0.5 * keep, "vy": (ex.A.vy + ex.D.vy) * 0.5 * keep,',
    '\t\t"part": _g(ex.A, PART_N), "double": (maxi(0, dbl - _now(S)) if dbl > 0 else -1)}',
    '\tif S.depthOn:   # D1: the middle\'s depth and its speed, and the line (its sine, and which way it is turned)',
    '\t\tout["z"] = (ex.A.z + ex.D.z) * 0.5',
    '\t\tout["vz"] = (ex.A.vz + ex.D.vz) * 0.5 * keep',
    '\t\tout["lineSin"] = S.dirS.lineSin',
    '\t\tout["lineSide"] = S.dirS.lineSide',
    '\treturn out'));
  // ---- the frame and its helpers
  c.rep('## For Camera, Animation and UI: the brawl\'s centre.',
    L(
    '# ---------------------------------------------------------------- depth: the line and its frame (D1a)',
    '',
    '## The frame, for the director\'s part of one tick (not state: it opens in lineEnter and closes in lineLeave).',
    'static var _frOn: bool = false',
    'static var _frX: float = 0.0      # the pair\'s middle as the frame opened: along the street, and in depth',
    'static var _frZ: float = 0.0',
    'static var _frCos: float = 1.0    # the line\'s direction: along the street, and in depth (the sine with its side)',
    'static var _frSin: float = 0.0',
    'static var _frVz: float = 0.0     # the pair\'s speed in depth for this tick, units a second',
    'static var _frA = null',
    'static var _frD = null',
    'static var _frP: PackedFloat64Array = PackedFloat64Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])   # where each stood as it opened',
    'static var _dc: Dictionary = {}',
    '',
    '',
    '## The director\'s own depth numbers (data/combat/depth.json, "director"; the file is Simulation\'s).',
    'static func _dcfg() -> Dictionary:',
    '\tif _dc.is_empty():',
    '\t\tvar j = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat/depth.json"))',
    '\t\tvar d: Dictionary = j.get("director", {}) if j is Dictionary else {}',
    '\t\t_dc = {"lineSinMin": float(d.get("lineSinMin", 0.1736)), "lineSinMax": float(d.get("lineSinMax", 0.5)),',
    '\t\t\t"arriveSin": float(d.get("arriveSin", 0.342)), "homeAfterTicks": int(d.get("homeAfterTicks", 30)),',
    '\t\t\t"homeBhPerSec": float(d.get("homeBhPerSec", 0.5))}',
    '\treturn _dc',
    '',
    '',
    '## The depth a ground or a face is read at from inside the brawl: the pair\'s middle while the frame is open, and',
    '## the plane otherwise (so with depth off every read is today\'s).',
    'static func _gz() -> float:',
    '\treturn _frZ if _frOn else 0.0',
    '',
    '',
    '## +1 when a body at f has more room toward the camera than away from it, else -1 (World\'s depthRoom).',
    'static func _roomSide(S: SimState, f) -> int:',
    '\tvar b: Array = WorldLanes.body()',
    '\tvar room: Array = WorldLanes.depthRoom(S, f.x, f.y, f.z, float(b[0]), float(b[2]))',
    '\treturn 1 if (float(room[1]) - f.z) >= (f.z - float(room[0])) else -1',
    '',
    '',
    '## An approach ends a little to one side of D in depth, on the side with more room, so the attacker arrives on a',
    '## line (DirBands._startRush; Rush.offZ). off: the rush\'s offset along the street.',
    'static func arriveOff(S: SimState, D, off: float) -> float:',
    '\treturn float(_roomSide(S, D)) * float(_dcfg().arriveSin) * absf(off)',
    '',
    '',
    '## The line as a brawl starts: from the way the attacker came in, held between lineSinMin and lineSinMax (10 and 30',
    '## degrees). lineSide is +1 when the fighter further along the street is the nearer to the camera. Two who stand',
    '## at one depth take the smallest angle, with the attacker on the side that has more room. The carry\'s depth part',
    '## is what the two were moving at in depth, by the brawl\'s carryShare.',
    'static func _lineStart(S: SimState, ex) -> void:',
    '\tvar dc: Dictionary = _dcfg()',
    '\tvar A = ex.A',
    '\tvar D = ex.D',
    '\tvar dx: float = SimWrap.sdx(D.x, A.x)',
    '\tvar dz: float = A.z - D.z',
    '\tvar hl: float = SimDetMath.hypot(dx, dz)',
    '\tvar side: int = _roomSide(S, D) * (1 if dx >= 0.0 else -1)',
    '\tif absf(dz) > 0.5 and dx != 0.0:',
    '\t\tside = 1 if (dz > 0.0) == (dx > 0.0) else -1',
    '\tS.dirS.lineSin = clampf(absf(dz) / maxf(hl, 1.0), float(dc.lineSinMin), float(dc.lineSinMax))',
    '\tS.dirS.lineSide = side',
    '\tS.dirS.carryZ = (A.vz + A.vzX + D.vz + D.vzX) * float(cfg().carryShare)',
    '\tS.dirS.homeWait = 0',
    '',
    '',
    '## The frame opens (DirExchange.tick, before the brawl\'s part of the tick): each fighter\'s x becomes his distance',
    '## along the line from the pair\'s middle, and both take the middle\'s depth. False when there is none to open:',
    '## depth is off, or ex is not a running brawl with both held.',
    'static func lineEnter(S: SimState, ex) -> bool:',
    '\tif not S.depthOn or _frOn or not isBrawl(ex) or ex.branch != "" or ex.A.state != "locked" or ex.D.state != "locked":',
    '\t\treturn false',
    '\tSimDepth.enabled()   # the core\'s depth numbers are loaded',
    '\tvar A = ex.A',
    '\tvar D = ex.D',
    '\tvar xc: float = SimWrap.wrap(A.x + SimWrap.sdx(A.x, D.x) * 0.5)',
    '\tvar zc: float = (A.z + D.z) * 0.5',
    '\tvar sn: float = S.dirS.lineSin',
    '\t_frX = xc',
    '\t_frZ = zc',
    '\t_frCos = sqrt(maxf(0.0, 1.0 - sn * sn))',
    '\t_frSin = sn * float(S.dirS.lineSide)',
    '\t_frVz = 0.0',
    '\t_frA = A',
    '\t_frD = D',
    '\tvar k: int = 0',
    '\tfor f in [A, D]:',
    '\t\t_frP[k] = f.x',
    '\t\t_frP[k + 1] = f.y',
    '\t\t_frP[k + 2] = f.z',
    '\t\tk += 3',
    '\t\tvar hx: float = SimWrap.sdx(xc, f.x)',
    '\t\tvar h: float = SimDetMath.hypot(hx, f.z - zc)',
    '\t\tif hx < 0.0 or (hx == 0.0 and (f.z - zc) * _frSin < 0.0):',
    '\t\t\th = -h',
    '\t\tf.x = SimWrap.wrap(xc + h)',
    '\t\tf.z = zc',
    '\t\tf.zT = zc',
    '\tex.z = zc',
    '\t_frOn = true',
    '\treturn true',
    '',
    '',
    '## The frame closes (DirExchange.tick, wherever the brawl\'s part of the tick ends): each fighter is put back on the',
    '## line in the world, from where he stood as it opened, through the core\'s step call. So a face stops him as it',
    '## stops any step, and he is back on the line by the next tick. A fighter sent off inside the frame is put back',
    '## the same way.',
    'static func lineLeave(S: SimState) -> void:',
    '\tif not _frOn:',
    '\t\treturn',
    '\t_frOn = false',
    '\tvar k: int = 0',
    '\tfor f in [_frA, _frD]:',
    '\t\tvar h: float = SimWrap.sdx(_frX, f.x)',
    '\t\tvar y: float = f.y',
    '\t\tf.x = _frP[k]',
    '\t\tf.y = _frP[k + 1]',
    '\t\tf.z = _frP[k + 2]',
    '\t\tk += 3',
    '\t\tSimFighter.stepTo(S, f, _frX + h * _frCos, y, _frZ + h * _frSin)',
    '\t_frA = null',
    '\t_frD = null',
    '',
    '',
    '## The pair\'s speed in depth for this tick, once from _move with the frame open. One sum: the push and the pull\'s',
    '## share along the line (wx, the pair\'s speed along it, by the line\'s sine), the carry\'s depth part as it fades,',
    '## and the ease home (after homeAfterTicks live ticks with no stick, toward the middle of its street or crossing,',
    '## at homeBhPerSec). One cap: the core\'s (depth.json maxBhPerSec). Then World\'s room: the pair\'s middle never goes',
    '## where a body has none.',
    'static func _moveZ(S: SimState, ex, wx: float, held: bool) -> void:',
    '\tvar dc: Dictionary = _dcfg()',
    '\tvar d = S.dirS',
    '\tvar wz: float = wx * _frSin',
    '\tvar cn: int = _g(ex.A, CARRY_N)',
    '\tif d.carryZ != 0.0:',
    '\t\twz += d.carryZ * float(cn) / maxf(1.0, float(int(cfg().carryTicks)))',
    '\t\tif cn <= 0:',
    '\t\t\td.carryZ = 0.0',
    '\tif held:',
    '\t\td.homeWait = 0',
    '\telse:',
    '\t\td.homeWait += 1',
    '\t\tif d.homeWait >= int(dc.homeAfterTicks):',
    '\t\t\tvar hm: Array = WorldLanes.home(S, _frX, _frZ, 0.0)',
    '\t\t\tvar sp: float = float(dc.homeBhPerSec) * DirInterrupt.BH',
    '\t\t\twz += clampf((float(hm[1]) - _frZ) / SimConst.DT, -sp, sp)',
    '\twz = clampf(wz, -SimDepth.cap, SimDepth.cap)',
    '\tvar b: Array = WorldLanes.body()',
    '\tvar m: PackedFloat64Array = _mid(ex)',
    '\tvar room: Array = WorldLanes.depthRoom(S, _frX, m[1], _frZ, float(b[0]), float(b[2]) + SimDepth.margin)',
    '\tvar lo: float = minf(float(room[0]), _frZ)',
    '\tvar hi: float = maxf(float(room[1]), _frZ)',
    '\t_frVz = clampf(wz, (lo - _frZ) / SimConst.DT, (hi - _frZ) / SimConst.DT)',
    '',
    '',
    '') + '## For Camera, Animation and UI: the brawl\'s centre.');
});

edit('sim/director/exchange.gd', c => {
  c.rep(L(
    '\tDirBrawl.tick(S, ex)   # a brawl\'s lines: held presses and heavies, the magnet, and what ends it',
    '\tDirBrawl.tellTick(S, ex)   # a signature\'s tell: its defender may move',
    '\tif S.dirS.ex != ex:',
    '\t\treturn'),
  L(
    '\tDirBrawl.lineEnter(S, ex)   # D1, with depth on: the pair is put in its line\'s frame for the brawl\'s part of the tick',
    '\tDirBrawl.tick(S, ex)   # a brawl\'s lines: held presses and heavies, the magnet, and what ends it',
    '\tDirBrawl.tellTick(S, ex)   # a signature\'s tell: its defender may move',
    '\tif S.dirS.ex != ex:',
    '\t\tDirBrawl.lineLeave(S)',
    '\t\treturn'));
  c.rep(L(
    '\t\t\tb.done = true',
    '\t\t\trunBeat(S, ex, b)',
    '\t\t\tif S.dirS.ex != ex:',
    '\t\t\t\treturn',
    '\t\ti += 1',
    '\t_struggleTick(S, ex)'),
  L(
    '\t\t\tb.done = true',
    '\t\t\trunBeat(S, ex, b)',
    '\t\t\tif S.dirS.ex != ex:',
    '\t\t\t\tDirBrawl.lineLeave(S)',
    '\t\t\t\treturn',
    '\t\ti += 1',
    '\tDirBrawl.lineLeave(S)   # D1: the frame closes, and each is put back on the line in the world',
    '\t_struggleTick(S, ex)'));
});

edit('data/combat/depth.json', c => {
  c.rep('  "capExempt": ["shove", "sidestep"],\n',
        '  "capExempt": ["shove", "sidestep"],\n' +
        '  "director": {"lineSinMin": 0.1736, "lineSinMax": 0.5, "arriveSin": 0.342, "homeAfterTicks": 30, "homeBhPerSec": 0.5},\n' +
        '  "_director": "the director\'s own (sim/director/brawl.gd; docs/director/depth-d1.md). lineSinMin and lineSinMax: the sines of the least and the most angle a brawl\'s line makes with the street, 10 and 30 degrees. arriveSin: an approach ends this share of its street offset to one side in depth, about 20 degrees. homeAfterTicks and homeBhPerSec: with no stick held for this many live ticks the pair eases to the middle of its street or crossing, at this speed",\n');
});
