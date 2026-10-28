"""The sim's load split, my part (docs/architecture/load-split.md): SimDir (sim/core/dir.gd), the core's five scripts
calling the director through it, and the check (sim/core/tools/load_split.gd). Usage: python load_split.py <repo root>"""
import os, shutil, sys

root = sys.argv[1]
here = os.path.dirname(os.path.abspath(__file__))

SUBS = [
    ("sim/core/damage.gd", "\t\tDirExchange.endEx(S, S.dirS.ex)\n", "\t\tSimDir.endEx(S, S.dirS.ex)\n"),
    ("sim/core/damage.gd", "\t\tDirLaunch.doLaunch(S, A, D, {", "\t\tSimDir.doLaunch(S, A, D, {"),
    ("sim/core/fighter.gd", "\t\tSimFx.transformReady(S, f, f.tier + 1.0, DirExchange.transformSource(f))\n\tDirExchange.formBreak(S, f)",
     "\t\tSimFx.transformReady(S, f, f.tier + 1.0, SimDir.transformSource(f))\n\tSimDir.formBreak(S, f)"),
    ("sim/core/fighter.gd", "if not f.act.formReady: SimFx.transformReady(S, f, f.tier + 1.0, DirExchange.transformSource(f))",
     "if not f.act.formReady: SimFx.transformReady(S, f, f.tier + 1.0, SimDir.transformSource(f))"),
    ("sim/core/forms.gd", "\t\t\tSimFx.transformReady(S, f, nextTier(S, f), DirExchange.transformSource(f))   # the rising edge, as today",
     "\t\t\tSimFx.transformReady(S, f, nextTier(S, f), SimDir.transformSource(f))   # the rising edge, as today"),
    ("sim/core/forms.gd", "DirBands.who(S) < 0", "SimDir.bandsWho(S) < 0"),
    ("sim/core/forms.gd", "\t\tSimFx.transformReady(S, f, nextTier(S, f), DirExchange.transformSource(f))\n\tDirExchange.formBreak(S, f)",
     "\t\tSimFx.transformReady(S, f, nextTier(S, f), SimDir.transformSource(f))\n\tSimDir.formBreak(S, f)"),
    ("sim/core/fx.gd", "\tDirCalm.atReady(S, f)   # the ready tell", "\tSimDir.calmAtReady(S, f)   # the ready tell"),
    ("sim/core/shots.gd", "\tif DirBlast.rules(S) and f != S.fighters[sh.owner]:\n\t\treturn DirBlast.hit(S, sh, f)",
     "\tif SimDir.blastRules(S) and f != S.fighters[sh.owner]:\n\t\treturn SimDir.blastHit(S, sh, f)"),
]

FILES = [
    ("dir.gd.txt", "sim/core/dir.gd"),
    ("dir.gd.uid.txt", "sim/core/dir.gd.uid"),
    ("load_split.gd.txt", "sim/core/tools/load_split.gd"),
    ("load_split.gd.uid.txt", "sim/core/tools/load_split.gd.uid"),
]


def sub(rel, a, b):
    p = os.path.join(root, rel)
    s = open(p, encoding='utf-8', newline='').read()
    if '\r\n' in s:
        a, b = a.replace('\n', '\r\n'), b.replace('\n', '\r\n')
    n = s.count(a)
    if n != 1:
        sys.exit(f"{rel}: the anchor is found {n} times, not once: {a[:70]!r}")
    open(p, 'w', encoding='utf-8', newline='').write(s.replace(a, b))


for src, dst in FILES:
    if os.path.exists(os.path.join(root, dst)):
        sys.exit(f"{dst} is there already")
for rel, a, b in SUBS:
    sub(rel, a, b)
for src, dst in FILES:
    shutil.copyfile(os.path.join(here, 'files', src), os.path.join(root, dst))
print("load_split: SimDir, the core's five scripts and the check")
