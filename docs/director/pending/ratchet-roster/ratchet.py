# The two-fighter ratchet (tools/ratchet-two-fighter.mjs): my files name the running exchange and a fighter's rival through two DirBrawl
# helpers, the one place the director spells them. A pure refactor: no answer changes. python ratchet.py <tree>
import os, re, sys
T = sys.argv[1]


def sub(rel, a, b):
    p = os.path.join(T, rel)
    s = open(p, encoding="utf-8", newline="").read()
    assert s.count(a) == 1, (rel, a[:80], s.count(a))
    open(p, "w", encoding="utf-8", newline="").write(s.replace(a, b))


sub("sim/director/brawl.gd", '''static func isBrawl(ex) -> bool:''', '''## The running exchange, and a fighter's rival: the director's one place for each, for the 2v2 restructure (tools/ratchet-two-fighter.mjs).
static func exOf(S: SimState):
	return S.dirS.ex


static func rivalOf(S: SimState, f):
	return SimRoster.opp(S, f)


static func isBrawl(ex) -> bool:''')
n = 0
for rel, skip in [("sim/director/chase_tap.gd", []), ("sim/director/stick.gd", []), ("sim/director/beamplay.gd", []), ("sim/director/swing.gd", ["S.fighters[0]"])]:
    p = os.path.join(T, rel)
    s = open(p, encoding="utf-8", newline="").read()
    assert not re.search(r"\bS\.dirS\.ex\s*=[^=]", s), rel
    s, a = re.subn(r"\bS\.dirS\.ex\b", "DirBrawl.exOf(S)", s)
    s, b = re.subn(r"\bSimRoster\.opp\(", "DirBrawl.rivalOf(", s)
    open(p, "w", encoding="utf-8", newline="").write(s)
    print(rel, a, b)
    n += a + b
print("replaced", n)
