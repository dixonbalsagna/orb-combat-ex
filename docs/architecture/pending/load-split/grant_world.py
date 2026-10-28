"""World's grant for the sim's load split (docs/architecture/load-split.md): the wall kick in brunt.gd and the brawl's
pay in contact.gd call the director through SimDir, not by its class names. The same functions, the same arguments.
Usage: python grant_world.py <repo root>"""
import os, sys

root = sys.argv[1]

SUBS = [
    ("sim/world/brunt.gd", "not inside and DirWallKick.atWall(S, f, b, edge, dir, spN)\n\tvar km: float = DirWallKick.damageMul() if kicked",
     "not inside and SimDir.wallKickAt(S, f, b, edge, dir, spN)\n\tvar km: float = SimDir.wallKickMul() if kicked"),
    ("sim/world/contact.gd", "\tvar pay: float = DirBrawl.payMul(f)", "\tvar pay: float = SimDir.brawlPayMul(f)"),
]

for rel, a, b in SUBS:
    p = os.path.join(root, rel)
    s = open(p, encoding='utf-8', newline='').read()
    if '\r\n' in s:
        a, b = a.replace('\n', '\r\n'), b.replace('\n', '\r\n')
    n = s.count(a)
    if n != 1:
        sys.exit(f"{rel}: the anchor is found {n} times, not once: {a[:70]!r}")
    open(p, 'w', encoding='utf-8', newline='').write(s.replace(a, b))
print("grant_world: brunt.gd and contact.gd through SimDir")
