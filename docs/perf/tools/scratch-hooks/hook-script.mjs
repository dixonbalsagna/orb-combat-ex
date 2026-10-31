// SCRATCH HOOK (a scratch tree only; run after hook-stages.mjs): a scripted first player for stage-timer runs, behind --script. Player one is handed to a "human" by the first key press (the hub's join) and then plays a ten-second cycle
// the way a player who digs and launches does: hold charge (powers up on the ground: a crater), the signature (a beam that carves), then heavy and light mashing with dashes. Player two stays the AI. The same frames every run (keys are by frame number).
//   node hook-script.mjs <tree>
import { readFileSync, writeFileSync } from 'node:fs';

const root = process.argv[2];
if (!root) throw new Error('usage: node hook-script.mjs <tree>');
const p = `${root}/render/core/main.gd`;
let s = readFileSync(p, 'utf8');
const anchor = '\tvar n: int = host.advance(delta, vp.x, vp.y)\n';
if (s.split(anchor).length !== 2) throw new Error('main.gd: the advance line was not found exactly once');
s = s.replace(anchor, () => `\t_perf_keys()\n${anchor}`);
s = s.replace(/\s*$/, '') + `


## SCRATCH (docs/perf stage timers): --script plays player one from frame 120 in a 600-frame cycle: charge 150 frames, the signature, then heavies and lights with dashes.
var _pk_on: Dictionary = {}


func _perf_keys() -> void:
	if args.has("stress") and frames >= 120 and (frames - 120) % int(args["stress"]) == 0:
		var st: SimState = host.S
		var k: int = (frames - 120) / int(args["stress"])
		var sf = st.fighters[k % 2]
		sf.tier = 2.0 + float(k % 3)
		sf.y = WorldTerrain.groundY(st, sf.x, sf.z)
		SimFighter.tierUp(st, sf)   # a ground-level power-up: the crater, the area damage, the debris and dust, the events (--stress=N: one every N frames, tiers 2 to 4)
	if not args.has("script") or frames < 120:
		return
	if host.S.fighters[0].ai != null:
		host.toggle_ai(0)
	var c: int = (frames - 120) % 600
	_pk("KeyQ", c < 150)
	_pk("KeyR", c >= 150 and c < 156)
	_pk("KeyG", c >= 200 and (c / 6) % 4 == 1)
	_pk("KeyF", c >= 200 and (c / 6) % 4 == 3)
	_pk("Space", c >= 200 and c % 45 < 3)


func _pk(code: String, down: bool) -> void:
	if down == bool(_pk_on.get(code, false)):
		return
	_pk_on[code] = down
	if down:
		host.key_down(code)
	else:
		host.key_up(code)
`;
writeFileSync(p, s);
console.log('script hook applied to', root);
