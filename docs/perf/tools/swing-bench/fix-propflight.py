# SCRATCH FIX (a scratch tree only; Combat's file, so a proposal, not an edit): DirLaunch._propFlight stops once the flying body is in the air and past the farthest prop ahead.
#   python fix-propflight.py <tree>
# Keeps the original as _propFlightOld for prop_equiv.gd. Props are only offered within `reach` ahead of the launcher (_propTargets), sorted nearest first, and a body in the air moves one way (vx never changes sign in moveAir), so past the farthest prop plus PROP_STOP it cannot hit one.
import sys
f = sys.argv[1] + '/sim/director/launch.gd'
s = open(f, encoding='utf8').read()
i = s.index('static func _propFlight(')
j = s.index('\n\n\n', i)
old = s[i:j]
new = old.replace('static func _propFlight(', 'static func _propFlightOld(', 1)
fixed = old.replace('\tvar ev: Array = []\n\tfor t in range(WorldContact.TICK_CAP):\n', '\tvar ev: Array = []\n\tvar bound: float = float(props[props.size() - 1].d) + WorldContact.PROP_STOP + 1.0 if not props.is_empty() else 0.0\n\tfor t in range(WorldContact.TICK_CAP):\n\t\tif rec == null and b.mode == WorldContact.AIR and SimWrap.sdx(D.x, b.x) * b.dir > bound:\n\t\t\treturn -1   # past the farthest prop and still flying one way\n', 1)
assert fixed != old
s = s[:i] + fixed + '\n\n\n' + new + s[j:]
open(f, 'w', encoding='utf8').write(s)
print('fix applied')
