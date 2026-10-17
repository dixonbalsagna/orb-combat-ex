# PARKED BUILD (Simulation): what Animation asked of the sim's events (docs/animation/ragdoll-physics-paper.md section 5),
# as view fields outside the hash, so no golden moves:
#   launch   tier: the launch's power tier, the launcher's (R2's weight curve, the flail's gain)
#   damage   stop and tier on a hit (SimDamage.hit): the hit-stop ticks in force after it, as SimCore.step will spend them,
#            and the hitter's tier (R5: the body's impulse waits for the release)
# The air brake has no rule in the sim yet (docs/architecture/pending/anim-events/README.md), so air_brake waits for it.
#   edits sim/core/state.gd (FxEvent.stop), fx.gd (launch's tier; stopTicks), damage.gd (the hit's two fields),
#         tools/parity.gd (one check), docs/architecture/fx-events.md (the two rows)
# Independent of forms.py: either order. Usage: python anim_events.py <repo root>
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(sys.argv[1])
def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:80], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)

p = 'sim/core/state.gd'
s = open(p, encoding='utf-8').read()
i = s.index('\tvar run_to: int = 0')
j = s.index('\n', i) + 1
assert 'var stop: int' not in s
s = s[:j] + "\tvar stop: int = 0             # damage (a hit): the hit-stop ticks in force after it, as SimCore.step spends them (Animation). Not hashed\n" + s[j:]
open(p, 'w', encoding='utf-8', newline='\n').write(s)

edit('sim/core/fx.gd', [
("\te.amount = speed; e.face = dir; e.n = n\n",
 "\te.amount = speed; e.face = dir; e.n = n\n"
 "\te.tier = by.tier if by != null else 1.0   # a view field outside the hash: the launch's power tier, the launcher's (Animation)\n"),
("static func launch(S: SimState, f, by, speed: float, dir: float, n: int = 0) -> void:\n",
 "## The hit-stop's length in live ticks as SimCore.step spends it: each frozen tick takes SimConst.DT off it while it is\n"
 "## above 0 (a hit's damage event carries it, for Animation).\n"
 "static func stopTicks(stop: float) -> int:\n"
 "\tvar n: int = 0\n"
 "\tvar s: float = stop\n"
 "\twhile s > 0.0 and n < 3600:\n"
 "\t\ts -= SimConst.DT\n"
 "\t\tn += 1\n"
 "\treturn n\n"
 "\n\n"
 "static func launch(S: SimState, f, by, speed: float, dir: float, n: int = 0) -> void:\n"),
])

edit('sim/core/damage.gd', [
("\tvar region: int = hurt(S, D, dd, A, fam, kind, ",
 "\tvar n0: int = S.out.fx.size()\n"
 "\tvar region: int = hurt(S, D, dd, A, fam, kind, "),
("\tif kind == \"heavy\" and dd > 0.0:\n\t\tSimWounds.stagger(S, D)\n",
 "\tif n0 < S.out.fx.size() and S.out.fx[n0].type == \"damage\":   # view fields outside the hash (Animation): the hit-stop in force after this hit, and the hitter's tier\n"
 "\t\tS.out.fx[n0].stop = SimFx.stopTicks(S.dirS.stop)\n"
 "\t\tS.out.fx[n0].tier = A.tier\n"
 "\tif kind == \"heavy\" and dd > 0.0:\n\t\tSimWounds.stagger(S, D)\n"),
])

p = 'docs/architecture/fx-events.md'
s = open(p, encoding='utf-8').read()
for typ, note in [
    ('damage', "A hit (`SimDamage.hit`) also carries `stop` (the hit-stop ticks in force after it, as `SimCore.step` will spend them; a hit-stop from an impact, a brunt or an interrupt is read from `S.dirS.stop` and each tick's `frozen`) and `tier` (the hitter's tier): view fields outside the hash, for Animation"),
    ('launch', "It also carries `tier` (the launch's power tier, the launcher's): a view field outside the hash, for Animation"),
]:
    i = s.index('| `%s` |' % typ)
    j = s.index('\n', i)
    row = s[i:j]
    cells = row.split(' | ')
    assert len(cells) >= 4, (typ, len(cells))
    cells[2] = cells[2].rstrip() + ('' if cells[2].rstrip().endswith('.') else '.') + ' ' + note
    s = s[:i] + ' | '.join(cells) + s[j:]
open(p, 'w', encoding='utf-8', newline='\n').write(s)

p = 'sim/core/tools/parity.gd'
edit(p, [
("\tcheck(\"the blow cue's run stays out of the hash\", _cueRun())\n",
 "\tcheck(\"the blow cue's run stays out of the hash\", _cueRun())\n"
 "\tcheck(\"Animation's view fields: a launch's tier, a hit's stop and tier\", _animFields())\n"),
])
s = open(p, encoding='utf-8').read()
assert s.endswith('\n') and '_animFields() -> String' not in s
s += open(os.path.join(HERE, 'anim_check.gd'), encoding='utf-8').read()
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print("Animation's view fields are in")
