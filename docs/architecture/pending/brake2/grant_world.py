# GRANT (World's sim/world/contact.gd, for Simulation's brake2.py beside this). A journey's end, World's own (_finish)
# and the brake's (brakeEnd), clears the launcher's power as SimFighter.impact does, so a later send that carries no
# power (a knock-back, a finisher, a beam's) never reads an old launch's: it reached World's building ladder (effTier)
# and the brake's window. With launch anywhere off launchPower is always 1, so nothing moves. Usage: python grant_world.py <root>
import os, sys
os.chdir(sys.argv[1])
p = 'sim/world/contact.gd'
s = open(p, encoding='utf-8').read()
a = "\tf.launchSpecial = false\n\tf.slideFeet = false\n\tf.hopped = false\n\tWorldBrunt.endFlight(S, f)\n"
assert s.count(a) == 2, s.count(a)
s = s.replace(a, "\tf.launchSpecial = false\n\tf.launchPower = 1.0   # the flight is over: no launcher's power carried\n\tf.slideFeet = false\n\tf.hopped = false\n\tWorldBrunt.endFlight(S, f)\n")
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print("a journey's end clears the launcher's power")
