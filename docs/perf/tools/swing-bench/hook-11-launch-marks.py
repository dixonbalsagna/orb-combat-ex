# SCRATCH HOOK (a scratch tree only): statement-level timers (no wrapper functions: those changed the match) on the launch-time path of the swing director.
#   python hook-11-launch-marks.py <tree>
# DirSwing.pm[name] = microseconds of the last run of each piece; swing_bench2.gd clears it each tick and prints it on a HITCH line. Static dictionary, never a sim input.
import sys
root = sys.argv[1]

def edit(path, pairs):
    s = open(path, encoding='utf8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (path, a[:70], s.count(a))
        s = s.replace(a, b)
    open(path, 'w', encoding='utf8').write(s)

T = 'Time.get_ticks_usec()'
edit(f'{root}/sim/director/melee.gd', [
 ('\tDirSwing.atLaunch(S, att, tgt, force)   # the swing is decided first',
  f'\tvar _m0: int = {T}\n\tDirSwing.atLaunch(S, att, tgt, force)   # the swing is decided first'),
 ('\tDirRally.clearNoDown()\n\tDirSwing.atPlanned(S, r.best)\n',
  f'\tDirSwing.pm["m_choose"] = {T} - _m0\n\t_m0 = {T}\n\tDirRally.clearNoDown()\n\tDirSwing.atPlanned(S, r.best)\n\tDirSwing.pm["m_atPlanned"] = {T} - _m0\n'),
 ('\tvar r: Dictionary = DirLaunch.chooseLaunch(S, att, tgt, force, longOnly,',
  f'\tDirSwing.pm["m_atLaunch"] = {T} - _m0\n\t_m0 = {T}\n\tvar r: Dictionary = DirLaunch.chooseLaunch(S, att, tgt, force, longOnly,'),
 ('\tDirLaunch.doLaunch(S, att, tgt, r.best, force, longOnly)\n',
  f'\t_m0 = {T}\n\tDirLaunch.doLaunch(S, att, tgt, r.best, force, longOnly)\n\tDirSwing.pm["m_doLaunch"] = {T} - _m0\n\t_m0 = {T}\n'),
 ('\tDirSwing.atSend(S, att, tgt, r.best)',
  f'\tDirSwing.atSend(S, att, tgt, r.best)   # the swing starts as the hit-stop ends\n\tDirSwing.pm["m_atSend"] = {T} - _m0'),
])
edit(f'{root}/sim/director/swing.gd', [
 ('static var _was = null', 'static var pm: Dictionary = {}\nstatic var _was = null'),
 ('\tSimField.far()\n\tSimSwing._poses(S, true)\n\n\nstatic func _planOff',
  f'\tvar _a: int = {T}\n\tSimField.far()\n\tpm["s_far"] = {T} - _a\n\t_a = {T}\n\tSimSwing._poses(S, true)\n\tpm["s_posesOn"] = {T} - _a\n\n\nstatic func _planOff'),
 ('\tSimField.near()\n\tSimSwing._poses(S, true)\n',
  f'\tSimField.near()\n\tvar _b: int = {T}\n\tSimSwing._poses(S, true)\n\tpm["s_posesOff"] = {T} - _b\n'),
 ('\tif restRule(S) == "" and _flyingByChoice(S) == null and force >= float(cfg().fit.minForce):\n\t\t_plan = _launchPick(S, A, D, force)\n',
  f'\tvar _c: int = {T}\n\tif restRule(S) == "" and _flyingByChoice(S) == null and force >= float(cfg().fit.minForce):\n\t\t_plan = _launchPick(S, A, D, force)\n\tpm["s_pick"] = {T} - _c\n\t_c = {T}\n'),
 ('\t\tSimSwing._applyTurn(fr, float(_plan.pv), float(_plan.top.turn))\n\t\t_planOn(S, fr)\n',
  f'\t\tSimSwing._applyTurn(fr, float(_plan.pv), float(_plan.top.turn))\n\t\tpm["s_copyTurn"] = {T} - _c\n\t\t_c = {T}\n\t\t_planOn(S, fr)\n\t\tpm["s_planOn"] = {T} - _c\n'),
 ('\tvar list: Array = scored(S, "launch", A, D, float(A.x), side, cap, reach, cap)\n',
  f'\tvar _d: int = {T}\n\tvar list: Array = scored(S, "launch", A, D, float(A.x), side, cap, reach, cap)\n\tpm["s_scored"] = {T} - _d\n'),
])
print('hook-11 applied')
