# PARKED BUILD (Simulation): our own pi and tau, SimMathx.PI and SimMathx.TAU, built from their bits as epoch.gd builds
# its _PI, for Tools' determinism lint (tools/lint-determinism.mjs: no engine PI or TAU in the sim). They are the
# engine's doubles exactly (0x400921fb54442d18, and twice it, exact), so Encounter's and World's one-word swaps move
# nothing, and the golden does not move. Nothing reads them until those swaps.
#   edits sim/core/mathx.gd (the two constants) and sim/core/tools/parity.gd (a check, "SimMathx.PI and TAU").
# Usage: python pi.py <repo root>
import os, sys
os.chdir(sys.argv[1])
def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:90], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)

assert 'static var PI' not in open('sim/core/mathx.gd', encoding='utf-8').read(), 'already in'
edit('sim/core/mathx.gd', [
("## prefers -0); round() rounds halves away from zero (JS rounds them up). Use these wherever the JS core uses Math.*.\n",
 "## prefers -0); round() rounds halves away from zero (JS rounds them up). Use these wherever the JS core uses Math.*.\n"
 "\n"
 "## pi and tau from their bits: the sim's own, in place of the engine's PI and TAU (Tools' determinism lint). The same\n"
 "## doubles as the engine's today (tau is twice pi, exact); never assigned.\n"
 "static var PI: float = f64(\"400921fb54442d18\")    # det-ok: the definition, from its bits\n"
 "static var TAU: float = f64(\"401921fb54442d18\")   # det-ok: the definition, from its bits\n"),
])

edit('sim/core/tools/parity.gd', [
("\tcheck(\"a clash's meeting point\", _clashMid())\n",
 "\tcheck(\"a clash's meeting point\", _clashMid())\n"
 "\tcheck(\"SimMathx.PI and TAU\", _piTau())\n"),
("func _boons() -> String:\n",
 "## Our own pi and tau: from their bits, tau twice pi exactly, and both the engine's doubles, so a swap moves nothing.\n"
 "func _piTau() -> String:\n"
 "\tif SimMathx.bits(SimMathx.PI) != \"400921fb54442d18\" or SimMathx.bits(SimMathx.TAU) != \"401921fb54442d18\" or SimMathx.TAU != 2.0 * SimMathx.PI:\n"
 "\t\treturn \"pi %s, tau %s (want 400921fb54442d18 and twice it)\" % [SimMathx.bits(SimMathx.PI), SimMathx.bits(SimMathx.TAU)]\n"
 "\tif SimMathx.PI != PI or SimMathx.TAU != TAU:\n"
 "\t\treturn \"the engine's PI or TAU is another double on this build: the swaps would move a result\"\n"
 "\treturn \"\"\n"
 "\n"
 "\n"
 "func _boons() -> String:\n"),
])
print("SimMathx.PI and SimMathx.TAU, from their bits")
