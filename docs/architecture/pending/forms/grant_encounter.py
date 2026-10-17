# GRANT (Encounter's files, for Simulation's forms build: forms.py beside this). Four director lines read the tier's
# step through SimForms, which returns today's number with forms off, so with the switch off a match is the same to the
# bit. Encounter applies it in its own window, or grants it to Simulation. Apply after forms.py.
#   sim/director/exchange.gd   the transform event names the tier the release brings (a live step keeps the tier)
#   sim/director/data.gd       the director's estimate of the defender's top speed
#   sim/director/launch.gd     the launch planner's and doLaunch's tier factor on force
# Not here (Encounter's own, for the forms window): the AI's holds (hero-forms.md section 4b: up to 10 s at medium while
# its rival is above it; up to 30 s at hard while its coil is under 60), spending SimForms.armoured / useArmour on a blow
# that lands, and predictFlight's recovery (it reads no fighter).
# Usage: python grant_encounter.py <repo root>
import os, sys
os.chdir(sys.argv[1])
def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:80], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)

edit('sim/director/exchange.gd', [
("\t\tSimFx.transform(S, f, f.tier + 1.0, transformSource(f), hold, SimPause.VERSIONS[pz.version])\n",
 "\t\tSimFx.transform(S, f, SimForms.nextTier(S, f), transformSource(f), hold, SimPause.VERSIONS[pz.version])   # (forms: the tier his release brings)\n"),
])
edit('sim/director/data.gd', [
("\tvar top: float = 430.0 * D.spd * (1.0 + D.ld.speed * (D.tier - 1.0))\n",
 "\tvar top: float = 430.0 * D.spd * SimForms.speedMul(S, D)   # (forms: his own steps and the surge)\n"),
])
edit('sim/director/launch.gd', [
("\tvar tierF: float = 1.0 + A.ld.launch * (A.tier - 1.0)   # D1b: ladder.json\n",
 "\tvar tierF: float = SimForms.launchMul(S, A)   # D1b: ladder.json (forms: his own steps)\n"),
("\tvar f: float = force * fm * (1.0 + att.ld.launch * (att.tier - 1.0))   # D1b: ladder.json\n",
 "\tvar f: float = force * fm * SimForms.launchMul(S, att)   # D1b: ladder.json (forms: his own steps)\n"),
])
print("the director reads the forms' gains")
