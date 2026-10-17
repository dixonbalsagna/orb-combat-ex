// la.cjs (rebuilt 2026-10-17): launch anywhere, Game Design's thirteenth round (docs/design/launch-anywhere.md, 992adcbb)
// as re-ruled in ff68e994, BEHIND A SWITCH: data/director/interrupts.json brawl.launcher.anywhere.enabled (false). With
// it off nothing new is read into play and nothing new is written, so play is window 1's to the bit.
//   node la.cjs <checkout root> [--check]
// Needs window 1 (LC_LATE) and the grapple G1 (DirGrapple: the launcher's integers sit after the grapple's, found at
// run time and sized only when written). With the switch on:
//   1 The link: a B within anywhere.link ticks of one of his clean landed blows is the launcher (anywhere.kept before one
//     lands, thrown at the landing); a B within anywhere.mashTicks of his last B is the heavy flurry; an opening is a
//     launcher, as in window 1.
//   2 Safety: sure (he is staggered: it holds his stagger and can't be perfect-blocked), hard to answer (he reels from a
//     medium or a heavy), answerable (otherwise). The launcher is armoured against lights (half damage, nothing more), as
//     a fist heavy is; a medium or a heavy that lands ends its wind-up.
//   3 Power = string x state x wounds (the timing x1: the perfect window isn't on this build); it scales the launching
//     blow's worth and the send's force (and reaches World's building ladder and the landing as tgt.launchPower when
//     Simulation's and World's grants are in).
//   4 Freshness at the send: x fresh.factor (0.75) for each launch of that kind on him within windowS (60 s), and x
//     fresh.general (0.9) for each launch of him of any kind in it; never under fresh.floor (0.4). The rest and the
//     hammer give way to it. The planner prefers a fresh kind; the stick's kind is kept, the bend inside it at most
//     aim.bendCos (30 degrees).
//   5 The AI: after an opening, brawl.anywhere.launcher by level (0.15, 0.35, 0.6); in its string at a hard-to-answer
//     moment, brawl.anywhere.inString (0.08, 0.18, 0.28). Its answer to a launcher that isn't sure is a guess made at
//     the landing before it (brawl.anywhere.answer: 0.1, 0.25, 0.4), pressed its reaction time after the throw.
//   6 Cues: launcher_open gains UI's marks (source sure, k pips, amount the fresh mask); launcher_link (new) lights B for
//     the link after each clean landing; launch_power (new) at each launch: amount the power at the send after
//     freshness, k 1 for a full launch (anywhere.full, 0.8 and over: QA's counter), text the kind.
//   Combat's enders: read from res://data/combat/enders.json when Combat lands it there.
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
  fn(rep, t);
  if (rel.endsWith('.json')) JSON.parse(t);
  if (!check) fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  console.log(rel + (check ? ': anchors ok' : ': ok'));
}
{
  const b = fs.readFileSync(path.join(root, 'sim/director/brawl.gd'), 'utf8');
  if (!b.includes('const LC_LATE: int')) throw new Error('window 1 first (the launcher window: LC_LATE is missing)');
  if (b.includes('static func anywhere()')) throw new Error('launch anywhere is in already');
  if (!fs.existsSync(path.join(root, 'sim/director/grapple.gd'))) throw new Error('the grapple G1 first (the launcher\'s integers sit after DirGrapple.END)');
}

edit('sim/director/brawl.gd', rep => {
  // 1 the link, and 2 safety, at the throw
  rep('\tvar lau: bool = st == 2 and not paid and _g(f, LC_UNTIL) > 0 and (o.stunTicks > 0 or S.tick <= _g(f, LC_UNTIL)) and f.ki >= float(c.launcher.ki)\n',
      '\tvar lcOpen: bool = _g(f, LC_UNTIL) > 0 and (o.stunTicks > 0 or S.tick <= _g(f, LC_UNTIL))   # an opening: the window around the close\n' +
      '\tvar any: bool = anywhere()   # launch anywhere (the thirteenth round), behind its switch\n' +
      '\tvar lau: bool = st == 2 and not paid and (lcOpen or (any and _linked(S, f, p))) and not (any and _bMash(f, p)) and f.ki >= float(c.launcher.ki)\n' +
      '\tvar safety: int = _safety(S, f, o) if (lau and any) else 0   # 1 sure, 2 hard to answer, 3 answerable\n');
  rep('\t\t\tworth = float(c.launcher.worth) if launcherRest(S, o) == 0 else float(c.heavy.worth)   # a resting launcher is the hammer: a full heavy on the launcher\'s wind-up\n',
      '\t\t\tif any:\n\t\t\t\tworth = float(c.launcher.worth) * _power(S, f, o, safety)   # launch anywhere: the launching blow\'s worth is worth x power\n' +
      '\t\t\telse:\n\t\t\t\tworth = float(c.launcher.worth) if launcherRest(S, o) == 0 else float(c.heavy.worth)   # a resting launcher is the hammer: a full heavy on the launcher\'s wind-up\n');
  rep('\t\targs["ready"] = launcherRest(S, o) == 0   # a launch when one is ready on him; while the launcher rests, the hammer\n\t\tif not args["ready"]:\n\t\t\targs["hammer"] = true   # it always lands, it staggers him in place, and the brawl goes on\n',
      '\t\targs["ready"] = any or launcherRest(S, o) == 0   # a launch when one is ready on him; while the launcher rests, the hammer (launch anywhere: always ready)\n\t\tif not args["ready"]:\n\t\t\targs["hammer"] = true   # it always lands, it staggers him in place, and the brawl goes on\n' +
      '\t\tif any:\n' +
      '\t\t\targs["safety"] = safety\n' +
      '\t\t\targs["power"] = _power(S, f, o, safety)   # string x state x timing; wounds at its landing, freshness at its send\n' +
      '\t\t\tif safety != 1:\n' +
      '\t\t\t\to2["weighed"] = true   # the AI cannot react to a launcher in time: it answers only by a guess made at the landing before it (_laAnswerPlan)\n');
  // the launcher's piece by Combat's enders (when loaded), and his last blow's family and path for the next one
  rep('\t_s(f, BOLT_N, (_g(f, BOLT_N) + 1) if bolt else 0)\n\tif piece != "":\n\t\targs["piece"] = piece\n',
      '\t_s(f, BOLT_N, (_g(f, BOLT_N) + 1) if bolt else 0)\n' +
      '\tif lau and any:\n\t\tvar ep: String = _ender(S, f, int(args.get("aim", 0)))\n\t\tif ep != "":\n\t\t\tpiece = ep   # Combat\'s enders: the launch that follows his last blow\'s family and path\n' +
      '\tif piece != "":\n\t\targs["piece"] = piece\n\t\tif any:\n\t\t\t_ls(f, LA_FP, _famPath(piece))\n');
  rep('\tif lau:\n\t\to.stunTicks = maxi(o.stunTicks, lead + 2)   # the stagger holds until it lands\n',
      '\tif lau and (safety == 1 or not any):\n\t\to.stunTicks = maxi(o.stunTicks, lead + 2)   # the stagger holds until it lands (launch anywhere: only a sure launcher\'s, so one that isn\'t sure can be answered)\n\tif lau:\n');
  // the held B goes before a light pressed after it while it is the launcher (an opening, or his string)
  rep('\tif st == 0 and (_g(f, HELD_P) & 7) == 3 and _g(f, LC_UNTIL) > 0:\n',
      '\tif st == 0 and (_g(f, HELD_P) & 7) == 3 and (_g(f, LC_UNTIL) > 0 or (anywhere() and _linked(S, f, _g(f, HELD_AT)))):\n');
  // the link's clock, and what he was hit with, at a clean landing
  rep('\n\t_s(f, STRING_N, _g(f, STRING_N) + 1)\n',
      '\n\t_s(f, STRING_N, _g(f, STRING_N) + 1)\n' +
      '\tif anywhere():\n' +
      '\t\t_ls(f, LA_LINK, S.tick)   # his string\'s link: B within anywhere.link of this is the launcher\n' +
      '\t\t_ls(o, LA_HITK, kind + 1)\n' +
      '\t\t_laAnswerPlan(S, f, o)   # an AI he hits may guess now that a launcher follows (never by reacting to one)\n' +
      '\t\t_linkCue(S, f, o)   # UI\'s lit B: his B is the launcher for the link\n');
  // the launcher is armoured against lights, as a fist heavy is (Game Design, ff68e994)
  rep('\tif oWinding and oKind == BIG and _g(o, FLAV) == 0 and not special:\n',
      '\tif oWinding and oKind == BIG and (_g(o, FLAV) == 0 or (_g(o, FLAV) == 2 and anywhere())) and not special:   # launch anywhere: the launcher is armoured against lights too\n');
  rep('\te.dur = float(ticks)   # the stagger: inside it his B always lands\n',
      '\te.dur = float(ticks)   # the stagger: inside it his B always lands\n\tif anywhere():\n\t\t_marks(S, e, f, o, 1)   # an opening\'s launcher is sure: its marks for UI\n');
  rep('\t\tvar share: float = float(DirAI.lv().get("brawl", {}).get("launcher", 0.0))\n',
      '\t\tvar share: float = float(DirAI.lv().get("brawl", {}).get("anywhere", {}).get("launcher", 0.0)) if anywhere() else float(DirAI.lv().get("brawl", {}).get("launcher", 0.0))\n');
  // the landed launcher sends with its power
  rep('\t\tif bool(a.get("ready", false)):\n\t\t\t_send(S, ex, f, o, int(a.get("aim", 0)), "the launcher", float(c.launcher.flightMul))\n\t\telse:\n',
      '\t\tif bool(a.get("ready", false)):\n' +
      '\t\t\tif a.has("power"):\n' +
      '\t\t\t\t_ls(f, LA_POW, int(round(float(a.power) * _woundMul(o, String(a.get("piece", ""))) * 1000.0)))\n' +
      '\t\t\t_send(S, ex, f, o, int(a.get("aim", 0)), "the launcher", float(c.launcher.flightMul))\n' +
      '\t\t\tif a.has("power"):\n' +
      '\t\t\t\t_ls(f, LA_POW, 0)\n\t\telse:\n');
  rep('\tDirMelee.launchBeat(S, ex, f, o, float(cfg().heavy.force) * mul, false, {"forced": true, "tilt": tilt, "why": why})\n',
      '\tvar la: Dictionary = {"forced": true, "tilt": tilt, "why": why}\n' +
      '\tif _lg(f, LA_POW) > 0:\n' +
      '\t\tla["power"] = float(_lg(f, LA_POW)) / 1000.0   # the launcher\'s power: freshness is applied once the send is picked\n' +
      '\t\tvar want: String = _sendOf(aim)\n' +
      '\t\tif want != "" and DirLaunch.SENDS.has(want):\n' +
      '\t\t\tla["sends"] = want   # the stick\'s kind is kept: the choreographer bends only inside it\n' +
      '\tDirMelee.launchBeat(S, ex, f, o, float(cfg().heavy.force) * mul, false, la)\n');
  rep('static func launcherRest(S: SimState, o) -> int:\n',
      'static func launcherRest(S: SimState, o) -> int:\n\tif anywhere():\n\t\treturn 0   # launch anywhere: freshness replaces the rest\n');
  // the launcher's integers of a brawl are cleared as it begins (the freshness marks are kept)
  rep('\tfor f in [ex.A, ex.D]:\n\t\tf.act.dirI[FLASH_AT] = flash\n',
      '\tfor f in [ex.A, ex.D]:\n\t\tf.act.dirI[FLASH_AT] = flash\n' +
      '\t\tfor k in range(LA_LINK, LA_FRESH):\n\t\t\tif DirGrapple.END + k < f.act.dirI.size():\n\t\t\t\tf.act.dirI[DirGrapple.END + k] = 0   # (written only with launch anywhere on)\n');
  // the AI's guessed answer comes due, once a tick for each fighter
  rep('\t\t# A launcher on its way holds the stagger until it lands. The launcher\'s window lasts as long as the stagger.\n',
      '\t\t_laAnswerTick(S, f)\n\t\t# A launcher on its way holds the stagger until it lands. The launcher\'s window lasts as long as the stagger.\n');
  // 5 the AI in its string
  rep('\tif _g(f, AI_LSAW) == 1 and _g(f, LC_UNTIL) > 0:\n',
      '\tif anywhere() and _aiLaunchInString(S, f, c):\n' +
      '\t\t_s(f, AI_RIP, 0)\n\t\t_s(f, AI_GUARD, 0)\n\t\t_s(f, AI_LEFT, 0)\n\t\t_aiPress(S, f, i, 2, bl, true)\n\t\treturn\n' +
      '\tif _g(f, AI_LSAW) == 1 and _g(f, LC_UNTIL) > 0:\n');
  // the new functions, before the opening's own
  rep('## An opening (brawl-second-pass.md section 3, as re-ruled):',
`# ---------------------------------------------------------------- launch anywhere (the thirteenth round, behind its switch)

## Its integers sit after the grapple's (DirGrapple.END), found at run time and sized only when written: with
## brawl.launcher.anywhere.enabled off nothing is written, so play and the hash are window 1's.
const LA_LINK: int = 0    # S.tick his last blow landed clean: B within anywhere.link of it is the launcher
const LA_HITK: int = 1    # the kind of the last blow that landed clean on him, plus 1 (a reel from a medium or a heavy is hard to answer)
const LA_POW: int = 2     # the landing launcher's power x 1000, for its send; 0 none
const LA_ANS: int = 3     # S.tick until which the AI's guess that a launcher follows holds; 0 none
const LA_AILW: int = 4    # the landing the AI last weighed a launch in its string for
const LA_FP: int = 5      # his last blow's family and path for Combat's enders: family x 8 + path, plus 1
const LA_FRESH: int = 6   # the kinds of send marked on him (up, across, down, behind, building), four live ticks each; kept across brawls
const LA_N: int = 26


static func la() -> Dictionary:
	return cfg().get("launcher", {}).get("anywhere", {})


## True when launch anywhere is on (data/director/interrupts.json brawl.launcher.anywhere.enabled).
static func anywhere() -> bool:
	return on() and bool(la().get("enabled", false))


static func _lg(f, k: int) -> int:
	var i: int = DirGrapple.END + k
	return f.act.dirI[i] if i < f.act.dirI.size() else 0


static func _ls(f, k: int, v: int) -> void:
	DirGrapple._size(f)
	if f.act.dirI.size() < DirGrapple.END + LA_N:
		f.act.dirI.resize(DirGrapple.END + LA_N)
	f.act.dirI[DirGrapple.END + k] = v


## True when a B of f's pressed at p is in his string (docs/design/launch-anywhere.md section 2): within anywhere.link
## ticks after one of his landed blows, or anywhere.kept ticks or fewer before one lands (held on his line, it is
## thrown as the launcher at the landing).
static func _linked(S: SimState, f, p: int) -> bool:
	var at: int = _lg(f, LA_LINK)
	if at <= 0 or p <= 0:
		return false
	if p >= at:
		return p - at <= int(la().get("link", 24))
	return at - p <= int(la().get("kept", 10))


## A B within anywhere.mashTicks of his last B press is the heavy flurry, never the launcher (the mash rule).
static func _bMash(f, p: int) -> bool:
	var last: int = _g(f, B_TAP)
	return last > 0 and p - last < int(la().get("mashTicks", 9))


## How safe f's launcher is (section 3): 1 sure (he is staggered: an opening), 2 hard to answer (he reels from a medium
## or a heavy), 3 answerable (he reels from a light or a bolt, or is free).
static func _safety(S: SimState, f, o) -> int:
	if o.stunTicks > 0:
		return 1
	var k: int = _lg(o, LA_HITK) - 1
	if _now(S) < _g(o, REEL_AT) and (k == MEDIUM or k == BIG):
		return 2
	return 3


## The launcher's power before its wounds and its freshness (section 4): the string (his run's whole points, one at
## least) x the rival's state x the timing (x1: the perfect launcher waits on the perfect window, not on this build).
static func _power(S: SimState, f, o, safety: int) -> float:
	var pw: Dictionary = la().get("power", {})
	if pw.is_empty():
		return 1.0
	var run: int = clampi(_g(f, RUN) / RUN_U, 1, 4)
	var st: Dictionary = pw.state
	var sm: float = float(st.sure) if safety == 1 else (float(st.hard) if safety == 2 else float(st.answerable))
	return float(pw.string[run - 1]) * sm


## The wounds' factor at the launcher's landing: the region its piece strikes, battered or broken on him.
static func _woundMul(o, piece: String) -> float:
	var pw: Dictionary = la().get("power", {})
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


## The marks of a kind on o still inside anywhere.fresh.windowS of fight time (none with the switch off).
static func freshMarks(S: SimState, o, kind: int) -> int:
	var fr: Dictionary = la().get("fresh", {})
	if not anywhere() or fr.is_empty() or kind < 0 or kind > 4:
		return 0
	var win: int = int(round(float(fr.windowS) * DirData.TICKS_PER_SEC))
	var now: int = _now(S)
	var n: int = 0
	for q in range(4):
		var t: int = _lg(o, LA_FRESH + kind * 4 + q)
		if t > 0 and now - t <= win:
			n += 1
	return n


## Freshness: x factor for each mark of that kind on o in the window, x general for each mark of any kind, never under
## floor (Game Design, ff68e994). A fighter not launched in the window is full.
static func freshMul(S: SimState, o, kind: int) -> float:
	var fr: Dictionary = la().get("fresh", {})
	if not anywhere() or fr.is_empty():
		return 1.0
	var m: float = 1.0
	for q in range(freshMarks(S, o, kind)):
		m *= float(fr.factor)
	var all: int = 0
	for kd in range(5):
		all += freshMarks(S, o, kd)
	for q in range(all):
		m *= float(fr.get("general", 1.0))
	return maxf(float(fr.floor), m)


## Each launch marks its kind on the fighter it sends (DirMelee.launchBeat): the oldest of that kind's four marks goes.
static func markKind(S: SimState, o, kind: int) -> void:
	if not anywhere() or kind < 0 or kind > 4 or la().get("fresh", {}).is_empty():
		return
	var at: int = 0
	var oldest: int = 1 << 30
	for q in range(4):
		var t: int = _lg(o, LA_FRESH + kind * 4 + q)
		if t < oldest:
			oldest = t
			at = q
	_ls(o, LA_FRESH + kind * 4 + at, maxi(1, _now(S)))


## The cue launch_power at each launch (DirMelee.launchBeat), for QA's full-launch counter and the views: amount the
## power at the send after freshness (1 for a launch that isn't the launcher's), k 1 for a full one (anywhere.full and
## over), text the kind (up, across, down, behind, building).
static func powerCue(S: SimState, a, o, kind: int, power: float) -> void:
	if not anywhere():
		return
	var e = _ev(S, a, "launch_power", ["up", "across", "down", "behind", "building"][clampi(kind, 0, 4)])
	e.target = float(S.fighters.find(o))
	e.amount = power
	e.k = 1.0 if power >= float(la().get("full", 0.8)) - 0.0005 else 0.0
	e.n = S.tick


## The AI against a launcher that isn't sure (section 8): its reaction time is the wind-up's length, so it can't
## answer one it sees. Its only answer is one it was already guessing: when f's blow lands clean on an AI o, it decides
## once, at its level's brawl.anywhere.answer, that a launcher will follow while a B of his would still be one (the
## link). Keyed draws.
static func _laAnswerPlan(S: SimState, f, o) -> void:
	_ls(o, LA_ANS, 0)
	if o.ai == null:
		return   # a player answers for himself
	var share: float = float(DirAI.lv().get("brawl", {}).get("anywhere", {}).get("answer", 0.0))
	if share <= 0.0 or SimRng.keyed(int(S.game.seed), "brawl.answerLauncher", S.tick * 8 + S.fighters.find(o)) >= share:
		return
	_ls(o, LA_ANS, S.tick + int(la().get("link", 24)) + 1)


## The AI's guess, once a tick: a launcher that isn't sure winds on it, thrown while the guess held, and its reaction time
## has passed since it was thrown: it presses guard (never sooner, so it never answers within its reaction time; the
## contact is still inside the perfect window). The guess is spent with the press, or lapses.
static func _laAnswerTick(S: SimState, f) -> void:
	var until: int = _lg(f, LA_ANS)
	if until <= 0:
		return
	var ex = S.dirS.ex
	if f.ai == null or ex == null or (f != ex.A and f != ex.D):
		_ls(f, LA_ANS, 0)
		return
	var o = ex.D if f == ex.A else ex.A
	var began: int = _g(o, LAND_AT)   # S.tick his launcher was thrown (his line is busy until it lands)
	if _g(o, FLAV) == 2 and _g(o, LINE) == 1 and _g(o, LC_LATE) == 1 and began <= until:
		if f.stunTicks <= 0 and S.tick - began >= int(DirAI.skill().get("reactTicks", 14)):
			_ls(f, LA_ANS, 0)
			DirInterrupt.guardPress(S, f)
		return
	if S.tick > until:
		_ls(f, LA_ANS, 0)   # no launcher came while the guess held


## The AI launches in its string at a hard-to-answer moment (section 8): once a landed blow, at its level's
## brawl.anywhere.inString. True when it presses B now.
static func _aiLaunchInString(S: SimState, f, c: Dictionary) -> bool:
	var at: int = _lg(f, LA_LINK)
	if at <= 0 or _lg(f, LA_AILW) == at:
		return false
	_ls(f, LA_AILW, at)
	var ex = S.dirS.ex
	if ex == null or (f != ex.A and f != ex.D):
		return false
	var o = ex.D if f == ex.A else ex.A
	if not _linked(S, f, S.tick) or _safety(S, f, o) != 2 or f.ki < float(c.launcher.ki):
		return false
	var share: float = float(DirAI.lv().get("brawl", {}).get("anywhere", {}).get("inString", 0.0))
	return share > 0.0 and SimRng.keyed(int(S.game.seed), "brawl.launchInString", at * 2 + (0 if f == ex.A else 1)) < share


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


## A piece's family and path, packed for LA_FP (family x 8 + path, plus 1; 0 unknown).
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
	var fp: int = _lg(f, LA_FP) - 1
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
## kinds fresh on his rival (up, across, down, behind). Empty outside a brawl, or with launch anywhere off.
static func launcherNow(S: SimState, f) -> Dictionary:
	if not anywhere() or not inBrawl(S, f):
		return {}
	var ex = S.dirS.ex
	var o = ex.D if f == ex.A else ex.A
	var lcOpen: bool = _g(f, LC_UNTIL) > 0 and (o.stunTicks > 0 or S.tick <= _g(f, LC_UNTIL))
	var lit: bool = (lcOpen or _linked(S, f, S.tick)) and not _bMash(f, S.tick) and f.ki >= float(cfg().launcher.ki)
	if not lit:
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


## A blow of f's landed clean: his B is the launcher for anywhere.link ticks. The cue launcher_link says so, for UI's lit
## B (an opening keeps its own cue, launcher_open, which Audio and Animation read as an opening). n: the S.tick the link
## ends; dur: its length. Its safety is read as the landing leaves him: sure in an opening, hard after a medium or a
## heavy, answerable after a light or a bolt (the hit's own stun is no opening). Only when he has the ki.
static func _linkCue(S: SimState, f, o) -> void:
	if f.ki < float(cfg().launcher.ki) or quiet(S.dirS.ex):
		return
	var k: int = _lg(o, LA_HITK) - 1
	var sf: int = 1 if _g(f, LC_UNTIL) > 0 else (2 if (k == MEDIUM or k == BIG) else 3)
	var link: int = int(la().get("link", 24))
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
      '\t# With launch anywhere every launch marks its kind on the fighter it sends; the launcher\'s send is x its freshness, as planned.\n' +
      '\tvar lkind: int = DirBrawl.kindOfSend(r.best)\n' +
      '\tvar kf: float = 1.0\n' +
      '\tif lpow >= 0.0:\n' +
      '\t\tkf = DirBrawl.freshMul(S, tgt, lkind)\n' +
      '\t\tforce *= kf\n' +
      '\t\tif "launchPower" in tgt:\n' +
      '\t\t\ttgt.launchPower = lpow * kf   # for the building ladder and the flight\'s recovery (Simulation\'s and World\'s, when granted)\n' +
      '\tDirLaunch.doLaunch(S, att, tgt, r.best, force, longOnly)\n' +
      '\tDirBrawl.powerCue(S, att, tgt, lkind, (lpow * kf) if lpow >= 0.0 else 1.0)\n' +
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
      '\tvar preferW: float = float(DirBrawl.la().get("fresh", {}).get("preferW", 0.0)) if DirBrawl.anywhere() else 0.0   # launch anywhere: a fresh kind is preferred\n' +
      '\tfor k in c:\n\t\tk.s += S.rng.range_(0.0, NOISE)\n' +
      '\t\tif preferW > 0.0 and k.name != "KNOCK BACK":\n' +
      '\t\t\tk.s -= preferW * float(DirBrawl.freshMarks(S, D, DirBrawl.kindOfSend(k)))\n');
  rep('\t\t\tvar near: Array = c.filter(func(k): return k.name == "KNOCK BACK" or (k.ux * tx + k.uy * ty) / (tl * SimMathx.jmax(SimDetMath.hypot(k.ux, k.uy), 0.000001)) >= TILT_CONE)\n',
      '\t\t\tvar cone: float = float(DirBrawl.la().get("aim", {}).get("bendCos", TILT_CONE)) if DirBrawl.anywhere() else TILT_CONE   # launch anywhere: the choreographer bends at most this inside the stick\'s kind\n' +
      '\t\t\tvar near: Array = c.filter(func(k): return k.name == "KNOCK BACK" or (k.ux * tx + k.uy * ty) / (tl * SimMathx.jmax(SimDetMath.hypot(k.ux, k.uy), 0.000001)) >= cone)\n');
});

const NOTE = "Launch anywhere, Game Design's thirteenth round (docs/design/launch-anywhere.md) as re-ruled in ff68e994, behind enabled (false: window 1's launcher, its rest and its hammer, read from the keys above). link: B within this many ticks of one of his clean landed blows is the launcher; kept: a B pressed this many ticks or fewer before one lands is held and thrown as the launcher; mashTicks: a B within this of his last B is the heavy flurry. power: string by his run (1 to 4 points) x state (sure, hard, answerable) x timing (perfect, chain, max: waiting on the perfect window) x wounds (the region the piece strikes); it scales the launching blow's worth and the send. fresh: each launch marks its kind on the fighter it sends; x factor for each mark of the kind and x general for each mark of any kind within windowS, never under floor; the planner takes preferW off a candidate for each mark of its kind; airSense is for the flight's recovery (Simulation's, when granted). aim.bendCos: the most the choreographer bends a send inside the stick's kind (the cosine of 30 degrees). full: a launch whose power at the send is this or more is full (QA's counter; the cue launch_power). The launcher is armoured against lights, and only a sure one holds his stagger.";
edit('data/director/interrupts.json', rep => {
  rep('      "restS": 30,\n      "lateTicks": 24,\n      "flightMul": 1\n    }',
      '      "restS": 30,\n      "lateTicks": 24,\n      "flightMul": 1,\n' +
      '      "anywhere": {\n' +
      '        "_note": ' + JSON.stringify(NOTE) + ',\n' +
      '        "enabled": false,\n' +
      '        "link": 24,\n        "kept": 10,\n        "mashTicks": 9,\n' +
      '        "power": {"string": [0.55, 0.7, 0.85, 1.0], "state": {"sure": 1.0, "hard": 0.9, "answerable": 0.8}, "perfect": 1.25, "chain": 0.05, "max": 1.5, "wounds": {"battered": 1.1, "broken": 1.2}},\n' +
      '        "fresh": {"windowS": 60, "factor": 0.75, "general": 0.9, "floor": 0.4, "airSense": 0.25, "preferW": 12},\n' +
      '        "aim": {"bendCos": 0.866},\n' +
      '        "full": 0.8\n' +
      '      }\n    }');
});

edit('data/director/ai.json', rep => {
  rep('"perfectMul": 0.21, ', '"anywhere": {"launcher": 0.15, "inString": 0.08, "answer": 0.1}, "perfectMul": 0.21, ');
  rep('"perfectMul": 0.15, ', '"anywhere": {"launcher": 0.35, "inString": 0.18, "answer": 0.25}, "perfectMul": 0.15, ');
  rep('"perfectMul": 0.45, ', '"anywhere": {"launcher": 0.6, "inString": 0.28, "answer": 0.4}, "perfectMul": 0.45, ');
});

{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  const l = s.properties.brawl.properties.launcher;
  if (!l || !l.properties) throw new Error('director-interrupts schema: no brawl.launcher');
  if (l.properties.anywhere) throw new Error('director-interrupts schema: brawl.launcher.anywhere exists already');
  const num = d => ({ type: 'number', minimum: 0, description: d });
  const int = d => ({ type: 'integer', minimum: 0, description: d });
  l.properties.anywhere = { type: 'object', description: 'Launch anywhere (the thirteenth round), behind enabled.', properties: {
    _note: { type: 'string' },
    enabled: { type: 'boolean', description: "False: window 1's launcher." },
    link: int('A B within this many ticks of one of his landed blows is the launcher.'),
    kept: int('... and a B pressed this many ticks or fewer before one lands, held and thrown as the launcher.'),
    mashTicks: int('A B within this many ticks of his last B is the heavy flurry, never the launcher.'),
    power: { type: 'object', description: "The launcher's power: string x state x timing x wounds (x freshness at the send).", properties: {
      string: { type: 'array', items: num('By his run, one to four points.'), minItems: 4, maxItems: 4 },
      state: { type: 'object', properties: { sure: num('An opening.'), hard: num('He reels from a medium or a heavy.'), answerable: num('Otherwise.') }, required: ['sure', 'hard', 'answerable'], additionalProperties: false },
      perfect: num('A perfect launcher.'), chain: num('... and this for each earlier perfect in the chain.'), max: num('... at most this.'),
      wounds: { type: 'object', properties: { battered: num('The region it strikes battered.'), broken: num('... broken.') }, required: ['battered', 'broken'], additionalProperties: false } },
      required: ['string', 'state', 'wounds'], additionalProperties: false },
    fresh: { type: 'object', description: 'Freshness at the send, in place of the rest.', properties: {
      windowS: num('A mark lasts this many seconds of fight time.'), factor: num('Each mark of the kind multiplies by this ...'),
      general: num('... and each mark of any kind by this ...'), floor: num('... never under this.'),
      airSense: num('A fighter sent by a kind marked on him recovers this much sooner for each mark.'), preferW: num("The planner takes this off a candidate's score for each mark of its kind.") },
      required: ['windowS', 'factor', 'floor'], additionalProperties: false },
    aim: { type: 'object', description: "The choreographer's bend inside the stick's kind.", properties: { bendCos: num('The cosine of the most it bends a send from the stick.') }, additionalProperties: false },
    full: num('A launch whose power at the send is this or more is a full one.') },
    required: ['enabled'], additionalProperties: false };
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: brawl.launcher.anywhere' + (check ? ' (checked)' : ''));
}
{
  const sp = path.join(root, 'tools/schemas/director-ai.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  for (const k of ['easy', 'medium', 'hard']) {
    const b = s.properties.levels.properties[k].properties.brawl;
    if (!b || !b.properties) throw new Error('director-ai schema: no brawl block for ' + k);
    const sh = d => ({ type: 'number', minimum: 0, maximum: 1, description: d });
    b.properties.anywhere = { type: 'object', description: "The AI's launcher with launch anywhere on.", properties: {
      launcher: sh('The share of openings at which it launches.'),
      inString: sh('The share of hard-to-answer moments in its string at which it launches.'),
      answer: sh('The share of launchers that are not sure it answers, by a guess made at a landed blow of his before it (it never reacts to one).') },
      required: ['launcher', 'inString', 'answer'], additionalProperties: false };
  }
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-ai.schema.json: brawl.anywhere' + (check ? ' (checked)' : ''));
}
