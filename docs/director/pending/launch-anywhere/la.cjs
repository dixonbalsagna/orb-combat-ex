// la.cjs <checkout root> [--check]: launch anywhere (Game Design's thirteenth round, docs/design/launch-anywhere.md,
// 992adcbb, section 9's six steps), on window 1 (the return fix and the launcher window, 9d0530dc).
//   1 The link: B within launcher.link (24) ticks of one of his landed blows is the launcher; a B pressed kept (10) or
//     fewer before one lands is held on his line and thrown as the launcher; a B within mashTicks (9) of his last B is
//     the heavy flurry, never a launcher. An opening (the window around the close) is still one.
//   2 Safety: sure in an opening (he is staggered: it always lands, armoured, holds the stagger); hard to answer while
//     he reels from a medium or a heavy; answerable otherwise. Any blow that lands on a launcher winding ends it.
//   3 Power = string x state x timing x wounds x freshness (timing is x1: the perfect window isn't on this build). It
//     scales the launching blow's worth (worth x power) and the send's force; it is handed to the building ladder and
//     the landing as tgt.launchPower when that field exists (Simulation's and World's grant).
//   4 Freshness by kind (up, across, down, behind, into a building): each launch marks its kind on the fighter it sends;
//     x factor (0.75) a mark within windowS (60 s), never under floor (0.4). Retires the rest and the hammer (restS stays in the data, unread).
//     The planner prefers a fresh kind (preferW a mark). The stick's kind is kept (a send filter), and the bend inside
//     it is at most aim.bendCos (30 degrees).
//   5 The AI: in a string at a hard-to-answer moment it launches at launchInString. It can't react to a launcher in
//     time (its reaction time is the wind-up's length), so it answers only by a guess: when a blow lands clean on it,
//     it decides at answerLauncher that a launcher will follow inside the link; if one that isn't sure does, it
//     presses guard its reaction time after the wind-up began (never sooner), which is still inside the perfect window.
//     It never perfect-blocks his other blows by it.
//   6 For UI: DirBrawl.launcherNow(S, f): whether a B would launch, sure or not, its power in pips, the fresh kinds.
//   Combat's enders (docs/combat/pending/launch/enders.json): read from res://data/combat/enders.json when Combat lands
//   it there; until then the launcher's piece is picked as before.
// Every anchor is exact text; the script stops at the first missing. --check reads every anchor and writes nothing.
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node la.cjs <checkout root> [--check]');
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
  t = fn(rep, t) || t;
  if (rel.endsWith('.json')) JSON.parse(t);
  if (!check) fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  console.log(rel + (check ? ': anchors ok' : ': ok'));
}
{
  const b = fs.readFileSync(path.join(root, 'sim/director/brawl.gd'), 'utf8');
  if (!b.includes('const LC_LATE: int')) throw new Error('window 1 first (the launcher window: LC_LATE is missing)');
}

edit('sim/director/brawl.gd', (rep, t0) => {
  const m = t0.match(/\nconst END: int = BASE \+ (\d+)\n/g);
  if (!m || m.length !== 1) throw new Error('brawl.gd: no single END slot');
  const n = Number(/(\d+)/.exec(m[0])[1]);
  rep(`const END: int = BASE + ${n}\n`,
      `const LINK_AT: int = BASE + ${n}    # S.tick his last blow landed clean: B within launcher.link of it is the launcher\n` +
      `const HIT_K: int = BASE + ${n + 1}      # the kind of the last blow that landed clean on him, plus 1 (a reel from a medium or a heavy is hard to answer)\n` +
      `const LA_POW: int = BASE + ${n + 2}     # the landing launcher's power x 1000, for its send; 0 none\n` +
      `const LA_ANS: int = BASE + ${n + 3}     # S.tick until which the AI's guess that a launcher follows holds; 0 none\n` +
      `const AI_LINKW: int = BASE + ${n + 4}   # the landing the AI last weighed a launch in its string for\n` +
      `const LP_FP: int = BASE + ${n + 5}      # his last blow's family and path for Combat's enders: family x 8 + path, plus 1\n` +
      `const FRESH0: int = BASE + ${n + 6}     # the kinds of send marked on him (up, across, down, behind, building), four live ticks each; kept across brawls\n` +
      `const FRESH_N: int = 20\n` +
      `const END: int = BASE + ${n + 26}\n`);
  // 1 the link, and 2 safety, at the throw
  rep('\tvar lau: bool = st == 2 and not paid and _g(f, LC_UNTIL) > 0 and (o.stunTicks > 0 or S.tick <= _g(f, LC_UNTIL)) and f.ki >= float(c.launcher.ki)\n',
      '\tvar lcOpen: bool = _g(f, LC_UNTIL) > 0 and (o.stunTicks > 0 or S.tick <= _g(f, LC_UNTIL))   # an opening: the window around the close\n' +
      '\tvar lau: bool = st == 2 and not paid and (lcOpen or _linked(S, f, p)) and not _bMash(f, p) and f.ki >= float(c.launcher.ki)   # launch anywhere: in his string, or in an opening\n' +
      '\tvar safety: int = _safety(S, f, o) if lau else 0   # 1 sure, 2 hard to answer, 3 answerable\n');
  rep('\t\t\tworth = float(c.launcher.worth) if launcherRest(S, o) == 0 else float(c.heavy.worth)   # a resting launcher is the hammer: a full heavy on the launcher\'s wind-up\n',
      '\t\t\tworth = float(c.launcher.worth) * _power(S, f, o, safety)   # the launching blow\'s worth is worth x power (no rest, no hammer)\n');
  rep('\t\targs["ready"] = launcherRest(S, o) == 0   # a launch when one is ready on him; while the launcher rests, the hammer\n\t\tif not args["ready"]:\n\t\t\targs["hammer"] = true   # it always lands, it staggers him in place, and the brawl goes on\n',
      '\t\targs["ready"] = true   # the thirteenth round: no rest and no hammer, so a launcher always launches\n' +
      '\t\targs["safety"] = safety\n' +
      '\t\targs["power"] = _power(S, f, o, safety)   # string x state x timing; wounds at its landing, freshness at its send\n' +
      '\t\tif safety != 1:\n' +
      '\t\t\to2["weighed"] = true   # the AI cannot react to a launcher in time: it answers only by a guess made at the landing before it (_laAnswerPlan)\n');
  // the launcher's piece by Combat's enders (when loaded), and his last blow's family and path for the next one
  rep('\t_s(f, BOLT_N, (_g(f, BOLT_N) + 1) if bolt else 0)\n\tif piece != "":\n\t\targs["piece"] = piece\n',
      '\t_s(f, BOLT_N, (_g(f, BOLT_N) + 1) if bolt else 0)\n' +
      '\tif lau:\n\t\tvar ep: String = _ender(S, f, int(args.get("aim", 0)))\n\t\tif ep != "":\n\t\t\tpiece = ep   # Combat\'s enders: the launch that follows his last blow\'s family and path\n' +
      '\tif piece != "":\n\t\targs["piece"] = piece\n\t\t_s(f, LP_FP, _famPath(piece))\n');
  // the held B goes before a light pressed after it while it is the launcher (an opening, or his string)
  rep('\tif st == 0 and (_g(f, HELD_P) & 7) == 3 and _g(f, LC_UNTIL) > 0:\n',
      '\tif st == 0 and (_g(f, HELD_P) & 7) == 3 and (_g(f, LC_UNTIL) > 0 or _linked(S, f, _g(f, HELD_AT))):\n');
  // the link's clock, and what he was hit with, at a clean landing
  rep('\n\t_s(f, STRING_N, _g(f, STRING_N) + 1)\n',
      '\n\t_s(f, STRING_N, _g(f, STRING_N) + 1)\n\t_s(f, LINK_AT, S.tick)   # his string\'s link: B within launcher.link of this is the launcher\n\t_s(o, HIT_K, kind + 1)\n' +
      '\t_laAnswerPlan(S, f, o)   # an AI he hits may guess now that a launcher follows (never by reacting to one)\n' +
      '\t_linkCue(S, f, o)   # UI\'s lit B: his B is the launcher for the link\n');
  rep('\tif lau:\n\t\to.stunTicks = maxi(o.stunTicks, lead + 2)   # the stagger holds until it lands\n',
      '\tif lau and safety == 1:\n\t\to.stunTicks = maxi(o.stunTicks, lead + 2)   # a sure launcher holds the stagger until it lands (one that isn\'t sure can be answered)\n\tif lau:\n');
  rep('\te.dur = float(ticks)   # the stagger: inside it his B always lands\n',
      '\te.dur = float(ticks)   # the stagger: inside it his B always lands\n\t_marks(S, e, f, o, 1)   # an opening\'s launcher is sure: its marks for UI\n');
  // any blow that lands on a launcher winding ends it (it has no armour)
  rep('\tif wound and oWinding and _g(o, LINE) != 0:\n',
      '\tif (wound or _g(o, FLAV) == 2) and oWinding and _g(o, LINE) != 0:   # a launcher has no armour: any blow that lands ends its wind-up\n');
  // the landed launcher always sends, with its power
  rep('\t\tif bool(a.get("ready", false)):\n\t\t\t_send(S, ex, f, o, int(a.get("aim", 0)), "the launcher", float(c.launcher.flightMul))\n\t\telse:\n',
      '\t\tif bool(a.get("ready", false)):\n' +
      '\t\t\t_s(f, LA_POW, int(round(float(a.get("power", 1.0)) * _woundMul(o, String(a.get("piece", ""))) * 1000.0)))\n' +
      '\t\t\t_send(S, ex, f, o, int(a.get("aim", 0)), "the launcher", float(c.launcher.flightMul))\n' +
      '\t\t\t_s(f, LA_POW, 0)\n\t\telse:\n');
  rep('\tDirMelee.launchBeat(S, ex, f, o, float(cfg().heavy.force) * mul, false, {"forced": true, "tilt": tilt, "why": why})\n',
      '\tvar la: Dictionary = {"forced": true, "tilt": tilt, "why": why}\n' +
      '\tif _g(f, LA_POW) > 0:\n' +
      '\t\tla["power"] = float(_g(f, LA_POW)) / 1000.0   # the launcher\'s power: freshness by kind is applied once the send is picked\n' +
      '\t\tvar want: String = _sendOf(aim)\n' +
      '\t\tif want != "" and DirLaunch.SENDS.has(want):\n' +
      '\t\t\tla["sends"] = want   # the stick\'s kind is kept: the choreographer bends only inside it\n' +
      '\tDirMelee.launchBeat(S, ex, f, o, float(cfg().heavy.force) * mul, false, la)\n');
  // the rest is retired
  rep('static func launcherRest(S: SimState, o) -> int:\n',
      'static func launcherRest(S: SimState, o) -> int:\n\tif true:\n\t\treturn 0   # the thirteenth round: freshness by kind of send replaces the rest\n');
  // the freshness marks are kept across brawls, as the last launch's tick is
  rep('\t\tvar launchedAt: int = f.act.dirI[LAUNCH_AT]\n',
      '\t\tvar launchedAt: int = f.act.dirI[LAUNCH_AT]\n\t\tvar marks: Array = []\n\t\tfor q in range(FRESH_N):\n\t\t\tmarks.append(f.act.dirI[FRESH0 + q])\n');
  rep('\t\tf.act.dirI[LAUNCH_AT] = launchedAt\n',
      '\t\tf.act.dirI[LAUNCH_AT] = launchedAt\n\t\tfor q in range(FRESH_N):\n\t\t\tf.act.dirI[FRESH0 + q] = marks[q]\n');
  // the AI's guessed answer comes due, once a tick for each fighter
  rep('\t\t# A launcher on its way holds the stagger until it lands. The launcher\'s window lasts as long as the stagger.\n',
      '\t\t_laAnswerTick(S, f)\n\t\t# A launcher on its way holds the stagger until it lands. The launcher\'s window lasts as long as the stagger.\n');
  // 5 the AI in its string
  rep('\tif _g(f, AI_LSAW) == 1 and _g(f, LC_UNTIL) > 0:\n',
      '\tif _aiLaunchInString(S, f, c):\n' +
      '\t\t_s(f, AI_RIP, 0)\n\t\t_s(f, AI_GUARD, 0)\n\t\t_s(f, AI_LEFT, 0)\n\t\t_aiPress(S, f, i, 2, bl, true)\n\t\treturn\n' +
      '\tif _g(f, AI_LSAW) == 1 and _g(f, LC_UNTIL) > 0:\n');
  // the new functions, before the opening's own
  rep('## An opening (brawl-second-pass.md section 3, as re-ruled):',
`# ---------------------------------------------------------------- launch anywhere (the thirteenth round)

## True when a B of f's pressed at p is in his string (docs/design/launch-anywhere.md section 2): within launcher.link
## ticks after one of his landed blows, or launcher.kept ticks or fewer before one lands (held on his line, it is
## thrown as the launcher at the landing).
static func _linked(S: SimState, f, p: int) -> bool:
	var la: int = _g(f, LINK_AT)
	if la <= 0 or p <= 0:
		return false
	var lc: Dictionary = cfg().launcher
	if p >= la:
		return p - la <= int(lc.get("link", 24))
	return la - p <= int(lc.get("kept", 10))


## A B within launcher.mashTicks of his last B press is the heavy flurry, never the launcher (the mash rule).
static func _bMash(f, p: int) -> bool:
	var last: int = _g(f, B_TAP)
	return last > 0 and p - last < int(cfg().launcher.get("mashTicks", 9))


## How safe f's launcher is (section 3): 1 sure (he is staggered: an opening), 2 hard to answer (he reels from a medium
## or a heavy), 3 answerable (he reels from a light or a bolt, or is free).
static func _safety(S: SimState, f, o) -> int:
	if o.stunTicks > 0:
		return 1
	var k: int = _g(o, HIT_K) - 1
	if _now(S) < _g(o, REEL_AT) and (k == MEDIUM or k == BIG):
		return 2
	return 3


## The launcher's power before its wounds and its freshness (section 4): the string (his run's whole points, one at
## least) x the rival's state x the timing (x1: the perfect launcher waits on the perfect window, not on this build).
static func _power(S: SimState, f, o, safety: int) -> float:
	var pw: Dictionary = cfg().launcher.get("power", {})
	if pw.is_empty():
		return 1.0
	var run: int = clampi(_g(f, RUN) / RUN_U, 1, 4)
	var st: Dictionary = pw.state
	var sm: float = float(st.sure) if safety == 1 else (float(st.hard) if safety == 2 else float(st.answerable))
	return float(pw.string[run - 1]) * sm


## The wounds' factor at the launcher's landing: the region its piece strikes, battered or broken on him.
static func _woundMul(o, piece: String) -> float:
	var pw: Dictionary = cfg().launcher.get("power", {})
	if pw.is_empty() or piece == "":
		return 1.0
	var pc = DirRecipe.rec().get("pieces", {}).get(piece) if DirRecipe.on() else null
	var tg: String = String(pc.get("target", "")) if pc is Dictionary else ""
	var r: int = -1
	if tg == "head" or tg == "jaw":
		r = SimWounds.HEAD
	elif tg == "chest" or tg == "gut":
		r = SimWounds.CORE
	elif tg.begins_with("arm"):
		r = SimWounds.ARMS
	elif tg == "legs" or tg == "shins":
		r = SimWounds.LEGS
	if r < 0:
		return 1.0
	if SimWounds.broken(o, r):
		return float(pw.wounds.broken)
	if SimWounds.battered(o, r):
		return float(pw.wounds.battered)
	return 1.0


## The five kinds of send (section 5), by the planner's candidate: 0 up, 1 across, 2 down, 3 behind, 4 into a building.
## Behind has no candidate yet (the planner has no turned send): a stick held away is the planner's own pick until it does.
static func kindOfSend(k: Dictionary) -> int:
	var nm: String = String(k.get("name", ""))
	if k.has("brunt") or nm == "BUILDING SMASH" or (k.has("p") and k.p is Dictionary and bool(k.p.get("building", false))):
		return 4
	if nm == "UPPERCUT":
		return 0
	if nm == "DRIVE DOWN" or nm == "CRATER SLAM":
		return 2
	if nm == "SMASH BEHIND":
		return 3
	return 1


## The marks of a kind on o still inside launcher.fresh.windowS of fight time.
static func freshMarks(S: SimState, o, kind: int) -> int:
	var fr: Dictionary = cfg().launcher.get("fresh", {})
	if fr.is_empty() or kind < 0 or kind > 4:
		return 0
	var win: int = int(round(float(fr.windowS) * DirData.TICKS_PER_SEC))
	var now: int = _now(S)
	var n: int = 0
	for q in range(4):
		var t: int = _g(o, FRESH0 + kind * 4 + q)
		if t > 0 and now - t <= win:
			n += 1
	return n


## Freshness: x factor for each mark of that kind on o in the window, never under floor. A kind not marked is full.
static func freshMul(S: SimState, o, kind: int) -> float:
	var fr: Dictionary = cfg().launcher.get("fresh", {})
	if fr.is_empty():
		return 1.0
	var m: float = 1.0
	for q in range(freshMarks(S, o, kind)):
		m *= float(fr.factor)
	return maxf(float(fr.floor), m)


## Each launch marks its kind on the fighter it sends (DirMelee.launchBeat): the oldest of that kind's four marks goes.
static func markKind(S: SimState, o, kind: int) -> void:
	if kind < 0 or kind > 4 or cfg().launcher.get("fresh", {}).is_empty():
		return
	var at: int = 0
	var oldest: int = 1 << 30
	for q in range(4):
		var t: int = _g(o, FRESH0 + kind * 4 + q)
		if t < oldest:
			oldest = t
			at = q
	_s(o, FRESH0 + kind * 4 + at, maxi(1, _now(S)))


## The AI against a launcher that isn't sure (section 8): its reaction time is the wind-up's length, so it can't
## answer one it sees. Its only answer is one it was already guessing: when f's blow lands clean on an AI o, it decides
## once, at its level's brawl.answerLauncher, that a launcher will follow while a B of his would still be one (the
## link). Keyed draws.
static func _laAnswerPlan(S: SimState, f, o) -> void:
	_s(o, LA_ANS, 0)
	if o.ai == null:
		return   # a player answers for himself
	var share: float = float(DirAI.lv().get("brawl", {}).get("answerLauncher", 0.0))
	if share <= 0.0 or SimRng.keyed(int(S.game.seed), "brawl.answerLauncher", S.tick * 8 + S.fighters.find(o)) >= share:
		return
	_s(o, LA_ANS, S.tick + int(cfg().launcher.get("link", 24)) + 1)


## The AI's guess, once a tick: a launcher that isn't sure winds on it, thrown while the guess held, and its reaction time
## has passed since it was thrown: it presses guard (never sooner, so it never answers within its reaction time; the
## contact is still inside the perfect window). The guess is spent with the press, or lapses.
static func _laAnswerTick(S: SimState, f) -> void:
	var until: int = _g(f, LA_ANS)
	if until <= 0:
		return
	var ex = S.dirS.ex
	if f.ai == null or ex == null or (f != ex.A and f != ex.D):
		_s(f, LA_ANS, 0)
		return
	var o = ex.D if f == ex.A else ex.A
	var began: int = _g(o, LAND_AT)   # S.tick his launcher was thrown (his line is busy until it lands)
	if _g(o, FLAV) == 2 and _g(o, LINE) == 1 and _g(o, LC_LATE) == 1 and began <= until:
		if f.stunTicks <= 0 and S.tick - began >= int(DirAI.skill().get("reactTicks", 14)):
			_s(f, LA_ANS, 0)
			DirInterrupt.guardPress(S, f)
		return
	if S.tick > until:
		_s(f, LA_ANS, 0)   # no launcher came while the guess held


## The AI launches in its string at a hard-to-answer moment (section 8): once a landed blow, at its level's
## brawl.launchInString. True when it presses B now.
static func _aiLaunchInString(S: SimState, f, c: Dictionary) -> bool:
	var la: int = _g(f, LINK_AT)
	if la <= 0 or _g(f, AI_LINKW) == la:
		return false
	_s(f, AI_LINKW, la)
	var ex = S.dirS.ex
	if ex == null or (f != ex.A and f != ex.D):
		return false
	var o = ex.D if f == ex.A else ex.A
	if not _linked(S, f, S.tick) or _safety(S, f, o) != 2 or f.ki < float(c.launcher.ki):
		return false
	var share: float = float(DirAI.lv().get("brawl", {}).get("launchInString", 0.0))
	return share > 0.0 and SimRng.keyed(int(S.game.seed), "brawl.launchInString", la * 2 + (0 if f == ex.A else 1)) < share


## Combat's enders (docs/combat/launch-enders.md), loaded once from res://data/combat/enders.json when it exists.
static var _endersData = null
static func _enders() -> Dictionary:
	if _endersData == null:
		_endersData = {}
		if FileAccess.file_exists("res://data/combat/enders.json"):
			var j = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat/enders.json"))
			if j is Dictionary:
				_endersData = j
	return _endersData


const FAMS: Array = ["hands", "legs", "close"]
const PATHS: Array = ["line", "rise", "drop", "arc_in", "arc_out", "spin"]


## A piece's family and path, packed for LP_FP (family x 8 + path, plus 1; 0 unknown).
static func _famPath(piece: String) -> int:
	var pc = DirRecipe.rec().get("pieces", {}).get(piece) if DirRecipe.on() else null
	if not (pc is Dictionary):
		return 0
	var limb: String = String(pc.get("limb", ""))
	var fam: int = 0 if limb == "hand" else (1 if (limb == "foot" or limb == "knee") else (2 if limb != "" else -1))
	var pth: int = PATHS.find(String(pc.get("path", "")))
	if fam < 0 or pth < 0:
		return 0
	return fam * 8 + pth + 1


## The launcher's piece by Combat's enders: his last blow's family and path, and the send his stick asks (none: the
## planner picks the send, and the piece is picked as before). The lowest step first; a keyed draw within it.
static func _ender(S: SimState, f, aim: int) -> String:
	var en: Dictionary = _enders()
	var fp: int = _g(f, LP_FP) - 1
	if en.is_empty() or fp < 0 or aim <= 0 or aim > 4:
		return ""
	var send: String = ["up", "across", "down", "turned"][aim - 1]
	var key: String = String(FAMS[fp / 8]) + "." + String(PATHS[fp % 8])
	var rows = en.get("fighters", {}).get(DirRecipe.poolKey(f), {}).get("enders", {}).get(key, {}).get(send)
	if not (rows is Array) or rows.is_empty():
		return ""
	var best: int = 99
	for row in rows:
		best = mini(best, int(row.get("step", 99)))
	var pick: Array = []
	for row in rows:
		if int(row.get("step", 99)) == best:
			pick.append(String(row.strike))
	return pick[mini(pick.size() - 1, int(SimRng.keyed(int(S.game.seed), "brawl.ender", S.dirS.exN * 64 + _g(f, BLOWS)) * float(pick.size())))]


## For UI (section 9's marks): whether f's B would launch now, sure or not, its power in pips (1 to 5), and the four
## kinds fresh on his rival (up, across, down, behind). Empty outside a brawl.
static func launcherNow(S: SimState, f) -> Dictionary:
	if not inBrawl(S, f):
		return {}
	var ex = S.dirS.ex
	var o = ex.D if f == ex.A else ex.A
	var lcOpen: bool = _g(f, LC_UNTIL) > 0 and (o.stunTicks > 0 or S.tick <= _g(f, LC_UNTIL))
	var on: bool = (lcOpen or _linked(S, f, S.tick)) and not _bMash(f, S.tick) and f.ki >= float(cfg().launcher.ki)
	if not on:
		return {"on": false}
	var sf: int = _safety(S, f, o)
	var fresh: Array = []
	for kd in range(4):
		fresh.append(freshMarks(S, o, kd) == 0)
	return {"on": true, "sure": sf == 1, "safety": sf, "pips": clampi(int(round(_power(S, f, o, sf) * 5.0)), 1, 5), "fresh": fresh}



## UI's launcher marks as a cue's fields (the cue list's rules: k a count, amount a value). source: sure, hard or
## answerable; k: its power in pips (1 to 5); amount: the kinds fresh on his rival as a mask (1 up, 2 across, 4 down,
## 8 behind; a set bit is fresh).
static func _marks(S: SimState, e, f, o, sf: int) -> void:
	e.source = ["", "sure", "hard", "answerable"][clampi(sf, 1, 3)]
	e.k = float(clampi(int(round(_power(S, f, o, sf) * 5.0)), 1, 5))
	var m: int = 0
	for kd in range(4):
		if freshMarks(S, o, kd) == 0:
			m |= 1 << kd
	e.amount = float(m)


## A blow of f's landed clean: his B is the launcher for launcher.link ticks. The cue launcher_link says so, for UI's lit
## B (an opening keeps its own cue, launcher_open, which Audio and Animation read as an opening). n: the S.tick the link
## ends; dur: its length. Its safety is read as the landing leaves him: sure in an opening, hard after a medium or a
## heavy, answerable after a light or a bolt (the hit's own stun is no opening). Only when he has the ki.
static func _linkCue(S: SimState, f, o) -> void:
	if f.ki < float(cfg().launcher.ki) or quiet(S.dirS.ex):
		return
	var k: int = _g(o, HIT_K) - 1
	var sf: int = 1 if _g(f, LC_UNTIL) > 0 else (2 if (k == MEDIUM or k == BIG) else 3)
	var link: int = int(cfg().launcher.get("link", 24))
	var e = _ev(S, f, "launcher_link", "link")
	e.target = float(S.fighters.find(o))
	e.n = S.tick + link
	e.dur = float(link)
	_marks(S, e, f, o, sf)

## An opening (brawl-second-pass.md section 3, as re-ruled):`);
});

edit('sim/director/melee.gd', rep => {
  // the launcher's power scales the force before the planner, and each candidate's own freshness is applied in the
  // planner, so the flight it predicts is the flight that flies
  rep('\tvar r: Dictionary = DirLaunch.chooseLaunch(S, att, tgt, force, longOnly, String(args.get("sends", "")) if args != null else "", tilt, forced or (gate.get("enabled", false) and not DirData.contact().is_empty()))\n',
      '\tvar lpow: float = float(args.get("power", -1.0)) if args != null else -1.0   # the brawl\'s launcher (launch anywhere); -1 for any other launch\n' +
      '\tif lpow >= 0.0:\n' +
      '\t\tforce *= lpow\n' +
      '\t\tif "launchPower" in tgt:\n' +
      '\t\t\ttgt.launchPower = lpow * DirBrawl.freshMul(S, tgt, 4)   # for World\'s building aim (when granted)\n' +
      '\tvar r: Dictionary = DirLaunch.chooseLaunch(S, att, tgt, force, longOnly, String(args.get("sends", "")) if args != null else "", tilt, forced or (gate.get("enabled", false) and not DirData.contact().is_empty()), lpow >= 0.0)\n');
  rep('\tif r.best.name == "KNOCK BACK":\n\t\t# Nothing scored above holding back: the strike knocks the target back instead of launching it.\n',
      '\tif r.best.name == "KNOCK BACK":\n\t\t# Nothing scored above holding back: the strike knocks the target back instead of launching it.\n' +
      '\t\tif "launchPower" in tgt:\n\t\t\ttgt.launchPower = 1.0   # no launch: no power carried\n');
  rep('\tDirLaunch.doLaunch(S, att, tgt, r.best, force, longOnly)\n',
      '\t# Every launch marks its kind on the fighter it sends; the launcher\'s send is x its kind\'s freshness, as planned.\n' +
      '\tvar lkind: int = DirBrawl.kindOfSend(r.best)\n' +
      '\tif lpow >= 0.0:\n' +
      '\t\tvar kf: float = DirBrawl.freshMul(S, tgt, lkind)\n' +
      '\t\tforce *= kf\n' +
      '\t\tif "launchPower" in tgt:\n' +
      '\t\t\ttgt.launchPower = lpow * kf   # for the building ladder and the flight\'s recovery (Simulation\'s and World\'s, when granted)\n' +
      '\tDirLaunch.doLaunch(S, att, tgt, r.best, force, longOnly)\n' +
      '\tDirBrawl.markKind(S, tgt, lkind)\n');
});

edit('sim/director/launch.gd', (rep, t0) => {
  rep('static func chooseLaunch(S: SimState, A, D, force: float, longOnly: bool = false, sends: String = "", tilt: int = 0, noKnock: bool = false) -> Dictionary:\n',
      'static func chooseLaunch(S: SimState, A, D, force: float, longOnly: bool = false, sends: String = "", tilt: int = 0, noKnock: bool = false, fresh: bool = false) -> Dictionary:\n');
  rep('\t\tvar plan = WorldBrunt.aim(S, A, D, S.buildings[bi], force, tierF, longOnly)\n',
      '\t\tvar plan = WorldBrunt.aim(S, A, D, S.buildings[bi], force * (DirBrawl.freshMul(S, D, 4) if fresh else 1.0), tierF, longOnly)   # fresh: the launcher\'s send into a building, x its freshness\n');
  const street = t0.includes('\t\tif k.name == "SMASH ACROSS" and not street and p.travel < HAUL_TARGET:\n') ? ' and not street' : '';   // window 2 (the levers) adds the street test
  rep('\t\tif k.name == "SMASH ACROSS"' + street + ' and p.travel < HAUL_TARGET:\n',
      '\t\tif k.name == "SMASH ACROSS"' + street + ' and p.travel < HAUL_TARGET and not fresh:   # a launcher\'s length is its power\'s: no long-haul boost\n');
  rep('\t\tvar fm: float = k.fm if k.has("fm") else 1.0\n\t\tvar p: Dictionary = predictFlight(S, D.x, D.y, WorldSlide.launchVX(k.ux, k.uy, force * fm * tierF), k.uy * force * fm * tierF, WorldSlide.launchTravel(k.ux, k.uy))\n',
      '\t\tvar fm: float = (k.fm if k.has("fm") else 1.0) * (DirBrawl.freshMul(S, D, DirBrawl.kindOfSend(k)) if fresh else 1.0)   # fresh: each candidate x its own kind\'s freshness\n' +
      '\t\tvar p: Dictionary = predictFlight(S, D.x, D.y, WorldSlide.launchVX(k.ux, k.uy, force * fm * tierF), k.uy * force * fm * tierF, WorldSlide.launchTravel(k.ux, k.uy))\n');
  rep('\tfor k in c:\n\t\tk.s += S.rng.range_(0.0, NOISE)\n',
      '\tfor k in c:\n\t\tk.s += S.rng.range_(0.0, NOISE)\n' +
      '\t\tif k.name != "KNOCK BACK":\n' +
      '\t\t\tk.s -= float(DirBrawl.cfg().launcher.get("fresh", {}).get("preferW", 0.0)) * float(DirBrawl.freshMarks(S, D, DirBrawl.kindOfSend(k)))   # a fresh kind is preferred\n');
  rep('\t\t\tvar near: Array = c.filter(func(k): return k.name == "KNOCK BACK" or (k.ux * tx + k.uy * ty) / (tl * SimMathx.jmax(SimDetMath.hypot(k.ux, k.uy), 0.000001)) >= TILT_CONE)\n',
      '\t\t\tvar cone: float = float(DirBrawl.cfg().launcher.get("aim", {}).get("bendCos", TILT_CONE))   # the choreographer bends at most this inside the stick\'s kind\n' +
      '\t\t\tvar near: Array = c.filter(func(k): return k.name == "KNOCK BACK" or (k.ux * tx + k.uy * ty) / (tl * SimMathx.jmax(SimDetMath.hypot(k.ux, k.uy), 0.000001)) >= cone)\n');
});

edit('data/director/interrupts.json', rep => {
  rep('      "restS": 30,\n      "lateTicks": 24,\n      "flightMul": 1\n    }',
      '      "restS": 30,\n      "lateTicks": 24,\n      "flightMul": 1,\n' +
      '      "link": 24,\n      "kept": 10,\n      "mashTicks": 9,\n' +
      '      "power": {"string": [0.55, 0.7, 0.85, 1.0], "state": {"sure": 1.0, "hard": 0.9, "answerable": 0.8}, "perfect": 1.25, "chain": 0.05, "max": 1.5, "wounds": {"battered": 1.1, "broken": 1.2}},\n' +
      '      "fresh": {"windowS": 60, "factor": 0.75, "floor": 0.4, "airSense": 0.25, "preferW": 12},\n' +
      '      "aim": {"bendCos": 0.866},\n' +
      '      "_launchAnywhere": "The thirteenth round (docs/design/launch-anywhere.md): B within link ticks of one of his landed blows is the launcher, kept ticks before one lands too, never within mashTicks of his last B. power: string by his run (1 to 4 points) x state x timing (perfect, chain, max: waiting on the perfect window) x wounds; it scales the launching blow and the send. fresh: each launch marks its kind on the fighter it sends; x factor for each mark within windowS, never under floor; the planner takes preferW off a candidate for each mark of its kind; airSense is for the flight\'s recovery (Simulation\'s, when granted). aim: the bend inside the stick\'s kind (the cosine of 30 degrees). restS (the rest) and the hammer are retired: nothing reads restS, which stays until Tools retires its fixture cases; the 15% extension for a set piece waits (it would part the prediction of the planner from the flight)."\n    }');
});

edit('data/director/ai.json', rep => {
  rep('"perfectMul": 0.21, ', '"launchInString": 0.05, "answerLauncher": 0.1, "perfectMul": 0.21, ');
  rep('"perfectMul": 0.15, ', '"launchInString": 0.12, "answerLauncher": 0.25, "perfectMul": 0.15, ');
  rep('"perfectMul": 0.45, ', '"launchInString": 0.2, "answerLauncher": 0.4, "perfectMul": 0.45, ');
});

{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  const l = s.properties.brawl.properties.launcher;
  if (!l || !l.properties) throw new Error('director-interrupts schema: no brawl.launcher');
  const num = d => ({ type: 'number', minimum: 0, description: d });
  const int = d => ({ type: 'integer', minimum: 0, description: d });
  l.properties.link = int('A B within this many ticks of one of his landed blows is the launcher.');
  l.properties.kept = int('... and a B pressed this many ticks or fewer before one lands, held and thrown as the launcher.');
  l.properties.mashTicks = int('A B within this many ticks of his last B is the heavy flurry, never the launcher.');
  l.properties.power = { type: 'object', description: "The launcher's power: string x state x timing x wounds (x freshness at the send).", properties: {
    string: { type: 'array', items: num('By his run, one to four points.'), minItems: 4, maxItems: 4 },
    state: { type: 'object', properties: { sure: num('An opening.'), hard: num('He reels from a medium or a heavy.'), answerable: num('Otherwise.') }, additionalProperties: false },
    perfect: num('A perfect launcher.'), chain: num('... and this for each earlier perfect in the chain.'), max: num('... at most this.'),
    wounds: { type: 'object', properties: { battered: num('The region it strikes battered.'), broken: num('... broken.') }, additionalProperties: false } }, additionalProperties: false };
  l.properties.fresh = { type: 'object', description: 'Freshness by kind of send, in place of the rest.', properties: {
    windowS: num('A mark lasts this many seconds of fight time.'), factor: num('Each mark of the kind multiplies by this ...'), floor: num('... never under this.'),
    airSense: num('A fighter sent by a kind marked on him recovers this much sooner for each mark.'), preferW: num("The planner takes this off a candidate's score for each mark of its kind.") }, additionalProperties: false };
  l.properties.aim = { type: 'object', description: "The choreographer's bend inside the stick's kind.", properties: {
    bendCos: num('The cosine of the most it bends a send from the stick.') }, additionalProperties: false };
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: brawl.launcher' + (check ? ' (checked)' : ''));
}
{
  const sp = path.join(root, 'tools/schemas/director-ai.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  for (const k of ['easy', 'medium', 'hard']) {
    const b = s.properties.levels.properties[k].properties.brawl;
    if (!b || !b.properties) throw new Error('director-ai schema: no brawl block for ' + k);
    b.properties.launchInString = { type: 'number', minimum: 0, maximum: 1, description: 'The share of hard-to-answer moments in its string at which the AI launches.' };
    b.properties.answerLauncher = { type: 'number', minimum: 0, maximum: 1, description: 'The share of launchers that are not sure the AI answers, by a guess made at a landed blow of his before it (it never reacts to one).' };
  }
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-ai.schema.json: launchInString, answerLauncher' + (check ? ' (checked)' : ''));
}
