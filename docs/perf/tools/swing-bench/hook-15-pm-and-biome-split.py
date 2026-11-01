# SCRATCH HOOK (a scratch tree only, after hooks 11 to 13; hook 11's swing.gd part fails on trees with field-frame-2): DirSwing.pm exists, and DirLaunch._biomeCandsRead's B_ice_marsh block is split by call.
#   python hook-15-pm-and-biome-split.py <tree>
# pm keys added: s_scored, s_planOn (swing.gd), Bi_sea (WorldTerrain.seaAt), Bi_look (WorldContact.lookAt), Bi_burial (WorldWater.burialOK, when it runs).
import sys
root = sys.argv[1]
U = 'Time.get_ticks_usec()'


def edit(path, pairs):
    s = open(path, encoding='utf8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (path, a[:70], s.count(a))
        s = s.replace(a, b)
    open(path, 'w', encoding='utf8').write(s)


edit(f'{root}/sim/director/swing.gd', [
    ('static var _was = null', 'static var pm: Dictionary = {}\nstatic var _was = null'),
    ('\tvar list: Array = scored(S, "launch", A, D, float(A.x), side, cap, reach, cap)\n',
     f'\tvar _d: int = {U}\n\tvar list: Array = scored(S, "launch", A, D, float(A.x), side, cap, reach, cap)\n\tpm["s_scored"] = {U} - _d\n'),
    ('\t\t_plan = _launchPick(S, A, D, force)\n\tif _plan != null:\n\t\tvar fr = S.frame.copy()\n\t\tSimSwing._applyTurn(fr, float(_plan.pv), float(_plan.top.turn))\n\t\t_planOn(S, fr, float(D.x))\n',
     f'\t\t_plan = _launchPick(S, A, D, force)\n\tvar _c: int = {U}\n\tif _plan != null:\n\t\tvar fr = S.frame.copy()\n\t\tSimSwing._applyTurn(fr, float(_plan.pv), float(_plan.top.turn))\n\t\t_planOn(S, fr, float(D.x))\n\t\tpm["s_planOn"] = {U} - _c\n'),
])
edit(f'{root}/sim/director/launch.gd', [
    ('\tvar sea: bool = WorldTerrain.seaAt(S, D.x)\n\tvar look: String = WorldContact.lookAt(S, D.x)\n\tq = cd.get("ICE SKID", {})',
     f'\tvar sea: bool = WorldTerrain.seaAt(S, D.x)\n\tDirSwing.pm["Bi_sea"] = {U} - _bt\n\t_bt = {U}\n\tvar look: String = WorldContact.lookAt(S, D.x)\n\tDirSwing.pm["Bi_look"] = {U} - _bt\n\t_bt = {U}\n\tq = cd.get("ICE SKID", {{}})'),
    ('\tDirSwing.pm["B_ice_marsh"] = ',
     f'\tDirSwing.pm["Bi_rest"] = {U} - _bt\n\tDirSwing.pm["B_ice_marsh"] = '),
])
print('hook-15 applied')
