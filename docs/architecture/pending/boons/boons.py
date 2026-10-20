# PARKED BUILD (Simulation): the run's rare boons (Game Design, rulings-2026-10-18b.md section 4), run-only: a match's
# setup names them ("boons": {slot: id}), which no versus match does, so with none named nothing moves.
#   new   sim/core/boons.gd (SimBoons), data/fight/boons.json
#   edits sim/core/state.gd (Fighter.boon), sim.gd (newMatch applies them), hash.gd (the boon, only when named),
#         replay.gd (boons.json in the data hash, only for a setup that names one), wounds.gd (the borrowed form's price),
#         tools/parity.gd (one check)
# Needs an import (a new class). Applies before or after the other parks. Usage: python boons.py <repo root>
import os, shutil, sys
HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(sys.argv[1])
def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:90], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)

assert not os.path.exists('sim/core/boons.gd'), 'the boons are already in'
shutil.copyfile(os.path.join(HERE, 'src', 'boons.gd'), 'sim/core/boons.gd')
shutil.copyfile(os.path.join(HERE, 'src', 'boons.json'), 'data/fight/boons.json')

edit('sim/core/state.gd', [
("\tvar launchPower: float = 1.0",
 "\tvar boon: String = \"\"           # the run's rare boon (sim/core/boons.gd): born_ready, second_skin or borrowed; \"\" for none\n\tvar launchPower: float = 1.0"),
])
edit('sim/core/sim.gd', [
("\tSimForms.setup(S)   # each fighter's form state while forms are on, and his own steps when his data has them\n",
 "\tSimForms.setup(S)   # each fighter's form state while forms are on, and his own steps when his data has them\n"
 "\tSimBoons.apply(S, setup)   # the run's rare boons (the setup's \"boons\"): none in versus\n"),
])
edit('sim/core/hash.gd', [
("\t\tif float(f.launchPower) != 1.0:\n\t\t\tout.append(f.launchPower)   # a launcher's power, hashed only while a launch carries one\n",
 "\t\tif float(f.launchPower) != 1.0:\n\t\t\tout.append(f.launchPower)   # a launcher's power, hashed only while a launch carries one\n"
 "\t\tif f.boon != \"\":\n\t\t\tout.append(f.boon)   # the run's rare boon, only when the setup names one\n"),
])
edit('sim/core/replay.gd', [
("\tif SimDepth.enabled():   # fighters in depth: data/combat/depth.json, once its switch is on (a match with depth off reads none of it)\n\t\th.text(SimDepth.dataHash())\n",
 "\tif SimDepth.enabled():   # fighters in depth: data/combat/depth.json, once its switch is on (a match with depth off reads none of it)\n\t\th.text(SimDepth.dataHash())\n"
 "\tif setup.has(\"boons\"):   # the run's rare boons: data/fight/boons.json, only for a setup that names one\n"
 "\t\th.text(SimBoons.dataHash())\n"),
])
edit('sim/core/wounds.gd', [
("\tvar add: int = int(SimMathx.jround(damage * wearK(S, f)))\n",
 "\tvar k: float = wearK(S, f)\n"
 "\tif f.boon != \"\":\n"
 "\t\tk *= SimBoons.wearMul(f)   # the borrowed form's price: his first broken region comes sooner\n"
 "\tvar add: int = int(SimMathx.jround(damage * k))\n"),
])
p = 'sim/core/tools/parity.gd'
edit(p, [
("\tcheck(\"the blow cue's run stays out of the hash\", _cueRun())\n",
 "\tcheck(\"the blow cue's run stays out of the hash\", _cueRun())\n"
 "\tcheck(\"the run's rare boons\", _boons())\n"),
])
s = open(p, encoding='utf-8').read()
assert s.endswith('\n') and '_boons() -> String' not in s
s += open(os.path.join(HERE, 'src', 'boons_check.gd'), encoding='utf-8').read()
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print("the run's rare boons are in (only a setup that names one reads them)")
