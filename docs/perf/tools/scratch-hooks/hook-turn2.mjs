// SCRATCH HOOK (a scratch stage-timer tree only; after hook-stages.mjs and hook-script.mjs): stages World's calm-moment turn on the stage-timer tree, behind --arenacols=N --turn.
// A planet match gets an arena of N columns with the turn on (setup.arena = {cols, turn}); at tick 10 the hook does what the director's ask and pick do (WorldEpoch.ask, then WorldEpoch.choose with the largest bearing, k and the
// fallback from --turnk=N --turnfb=D: a landing is 16 and 2.5, a form step 32 and 0); World's own calm then decides the swap tick. The timers: d_arenaturn (main._arena_turn), t_build (each pane's planet.build), s_epoch (the sim's WorldEpoch.tick).
//   node hook-turn2.mjs <tree>
import { readFileSync, writeFileSync } from 'node:fs';

const root = process.argv[2];
if (!root) throw new Error('usage: node hook-turn2.mjs <tree>');
const sub = (s, a, b) => { if (s.split(a).length !== 2) throw new Error(`anchor not found once: ${JSON.stringify(a.slice(0, 70))}`); return s.replace(a, () => b); };

let m = readFileSync(`${root}/render/core/main.gd`, 'utf8');
m = sub(m, '\t\treturn {"planet": int(args["planet"]), "touch": int(args.get("touch", 3))}', '\t\tvar pp: Dictionary = {"planet": int(args["planet"]), "touch": int(args.get("touch", 3))}\n\t\tif args.has("arenacols"):\n\t\t\tpp["arena"] = {"cols": int(args["arenacols"]), "turn": args.has("turn")}\n\t\treturn pp');
m = sub(m, '\t\t\t_arena_turn(e)\n', '\t\t\tvar _ptat: int = Time.get_ticks_usec()\n\t\t\t_arena_turn(e)\n\t\t\tPerfT.t("d_arenaturn", _ptat)\n\t\t\tPerfT.g("turned", 1)\n');
m = sub(m, '\t\tp.planet.build(host.S)\n', '\t\tvar _ptb: int = Time.get_ticks_usec()\n\t\tp.planet.build(host.S)\n\t\tPerfT.t("t_build", _ptb)\n');
m = sub(m, 'func _perf_keys() -> void:\n', `func _perf_keys() -> void:
	if args.has("turn") and host.ticks == 10 and not _turn_done:
		_turn_done = true
		var st0: SimState = host.S
		if st0.epoch != null:
			var a0 = st0.fighters[0]
			var b0 = st0.fighters[1]
			var dx0: float = SimWrap.sdx(a0.x, b0.x)
			st0.epoch.lastT = -1.0e9
			var cands: Array = WorldEpoch.ask(st0, "perf", SimWrap.wrap(a0.x + 0.5 * dx0), 1 if dx0 >= 0.0 else -1, st0.tick + 80)
			if not cands.is_empty():
				WorldEpoch.choose(st0, cands.size() - 1, int(args.get("turnk", 32)), float(args.get("turnfb", 2.5)))
`);
m = m.replace(/\s*$/, '') + '\n\n\nvar _turn_done: bool = false\n';
writeFileSync(`${root}/render/core/main.gd`, m);

let s = readFileSync(`${root}/sim/core/sim.gd`, 'utf8');
s = sub(s, '\t\tWorldEpoch.tick(S, DirCalm.hold(S))', '\t\tvar _ptep: int = Time.get_ticks_usec()\n\t\tWorldEpoch.tick(S, DirCalm.hold(S))\n\t\tPerfT.t("s_epoch", _ptep)\n\t\tvar _pteq: int = 0');
writeFileSync(`${root}/sim/core/sim.gd`, s);
console.log('turn hook applied to', root);
