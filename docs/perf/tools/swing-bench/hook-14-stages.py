# SCRATCH HOOK (a scratch tree only): statement-level stage timers in SimCore._step (sim/core/sim.gd), for stage_bench.gd.
#   python hook-14-stages.py <tree>
# SimCore.stg[name] = microseconds of that stage this tick (a static dictionary, never a sim input; statements only, no wrapper functions: those changed the match before).
# Stages: head (the arena check, bindStep), swing (SimSwing.tick), epoch (the calm turn), pre (hit-stop, pause bank, ko), control, fighter, dirUpdate, beam, shots, water, mood, cata (cata + forms), collateral, fx (tickMark + clash glue).
import sys
root = sys.argv[1]
p = f'{root}/sim/core/sim.gd'
s = open(p, encoding='utf8').read()
T = 'Time.get_ticks_usec()'


def swap(a, b):
    global s
    assert s.count(a) == 1, (a[:80], s.count(a))
    s = s.replace(a, b)


def mark(name):
    return f'\tstg["{name}"] = {T} - _q\n\t_q = {T}\n'


swap('static func _step(S: SimState, inputs) -> bool:\n', 'static var stg: Dictionary = {}\n\n\nstatic func _step(S: SimState, inputs) -> bool:\n\tvar _q: int = ' + T + '\n')
swap('\tS.T += dt\n\tif S.frame != null:\n\t\tSimSwing.tick(S)', mark('head') + '\tS.T += dt\n\tif S.frame != null:\n\t\tSimSwing.tick(S)')
swap('\tif S.epoch != null:\n\t\tWorldEpoch.tick(S, DirCalm.hold(S))', mark('swing') + '\tif S.epoch != null:\n\t\tWorldEpoch.tick(S, DirCalm.hold(S))')
swap('\tif S.hitstopOn:\n\t\tSimHitstop.live(S)', mark('epoch') + '\tif S.hitstopOn:\n\t\tSimHitstop.live(S)')
swap('\tvar ord: Array = [0, 1] if S.rng.next() < 0.5', mark('pre') + '\tvar ord: Array = [0, 1] if S.rng.next() < 0.5')
swap('\tfor f in S.fighters:\n\t\tSimFighter.stepFighter(S, f, dt)\n\tDirExchange.dirUpdate(S, dt)\n\tDirBeam.beamStep(S, dt)\n\tSimShots.step(S, dt)',
     mark('control') + '\tfor f in S.fighters:\n\t\tSimFighter.stepFighter(S, f, dt)\n' + mark('fighter') + '\tDirExchange.dirUpdate(S, dt)\n' + mark('dirUpdate') + '\tDirBeam.beamStep(S, dt)\n' + mark('beam') + '\tSimShots.step(S, dt)')
swap('\tWorldWater.step(S)\n\tSimMood.tick(S)', mark('shots') + '\tWorldWater.step(S)\n' + mark('water') + '\tSimMood.tick(S)')
swap('\tif S.cata != null and S.cata.ashLeft > 0:', mark('mood') + '\tif S.cata != null and S.cata.ashLeft > 0:')
swap('\tWorldCollateral.tick(S)\n\tSimFx.tickMark(S, dt, false)\n', mark('cata') + '\tWorldCollateral.tick(S)\n' + mark('collateral') + '\tSimFx.tickMark(S, dt, false)\n' + mark('fx'))
swap('\tvar live: bool = _step(S, inputs)\n\tS.bindCheck()', '\tvar live: bool = _step(S, inputs)\n\tvar _z: int = ' + T + '\n\tS.bindCheck()')
swap('\tSimState.sealFresh()   # the generation records', '\tstg["tail_bind"] = ' + T + ' - _z\n\t_z = ' + T + '\n\tSimState.sealFresh()   # the generation records')
swap('\treturn live\n\n\nstatic var stg', '\tstg["tail_seal"] = ' + T + ' - _z\n\treturn live\n\n\nstatic var stg')
open(p, 'w', encoding='utf8').write(s)
print('hook-14 applied')
