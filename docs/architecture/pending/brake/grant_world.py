# GRANT (World's sim/world/contact.gd, for Simulation's air brake: brake.py beside this). One new function, called only
# by SimBrake while the brake is on: when the brake gives a sent fighter control back in the air, his journey ends where
# he is, with World's own journey_end (kind "brake") and the same resets as a journey's end, and he is free with his
# speed. Nothing calls it with the brake off, so a match is the same to the bit. World applies it, or grants it.
# Usage: python grant_world.py <repo root>
import os, sys
os.chdir(sys.argv[1])
p = 'sim/world/contact.gd'
s = open(p, encoding='utf-8').read()
a = "static func _record(S: SimState, f, by) -> void:\n"
assert s.count(a) == 1 and 'static func brakeEnd(' not in s
s = s.replace(a,
"## The air brake gave him control back in the air (SimBrake; docs/architecture/brake-core.md): his journey ends where he\n"
"## is, as a recovery. journey_end says so (kind \"brake\"), the flight's aim and chain are released, and he is free, with\n"
"## the speed he has (SimBrake has divided the traversal factor out of it).\n"
"static func brakeEnd(S: SimState, f) -> void:\n"
"\tvar je := SimFx.contactEvent(S, \"journey_end\", f, f.x, f.y, SimDetMath.hypot(f.vx, f.vy))\n"
"\tje.contacts = f.jContacts\n"
"\tje.lips = f.jLips\n"
"\tje.nb = int(f.bounces)\n"
"\tje.dur = float(f.jT) * SimConst.DT\n"
"\tje.kind = \"brake\"\n"
"\tje.n = _launchN(f)\n"
"\tf.slide = 0.0\n"
"\tf.tumbleT = -1\n"
"\tf.state = \"free\"\n"
"\tf.stateT = 0.0\n"
"\tf.bounces = 0.0\n"
"\tf.launchBy = null\n"
"\tf.launchT = 1.0\n"
"\tf.launchSpecial = false\n"
"\tf.slideFeet = false\n"
"\tf.hopped = false\n"
"\tWorldBrunt.endFlight(S, f)\n"
"\n\n" + a)
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print("World's journey can end by the brake")
