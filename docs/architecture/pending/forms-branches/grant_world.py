# GRANT (World's sim/world/collateral.gd, for Simulation's forms branches: branches.py beside this). Two lines, both the
# same as today with forms off:
#   kill   tells SimForms where the people died and who caused it (Witness fills from the opponent's kills near the hero)
#   _feed  a fighter with branches no longer takes the opponent's kills into his anguish (hero-forms.md section 7: only
#          his own kills cost him; the opponent's go to Witness); SimForms.anguishOther returns today's number for anyone
#          else, and for everyone while forms are off
# Applies before or after World's collateral window (collateral-run). World applies it, or grants it.
# Usage: python grant_world.py <repo root>
import os, sys
os.chdir(sys.argv[1])
p = 'sim/world/collateral.gd'
s = open(p, encoding='utf-8').read()
pairs = [
("\tif granted > 0.0:\n\t\t_feed(S, granted, cause)\n",
 "\tif granted > 0.0:\n\t\t_feed(S, granted, cause)\n"
 "\t\tif S.formsOn:   # forms: where they died and who caused it, for the hero's Witness fill (sim/core/forms.gd)\n"
 "\t\t\tSimForms.casualty(S, granted, cause, b.x if b != null else cx)\n"),
("(f.md.anguishCasSelf if cause == f else f.md.anguishCasOther)",
 "(f.md.anguishCasSelf if cause == f else SimForms.anguishOther(S, f))"),
]
for a, b in pairs:
    assert s.count(a) == 1, (a[:70], s.count(a))
    s = s.replace(a, b)
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print("World tells the forms where people died")
