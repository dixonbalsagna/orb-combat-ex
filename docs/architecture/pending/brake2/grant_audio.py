# GRANT (Audio's audio/audio_carry.gd, for Simulation's brake2.py beside it): the air brake's new "ready" (Controls'
# brake_ready, the first tick of a send he could brake) is a haptic tick, not the brake's sound. Today _brake plays the
# brake for any text but "end", so a "ready" would start the sound with no end to stop it. One line: a "ready" plays
# nothing (Audio may give it a sound of its own later). Only with the brake on: off, no air_brake event is sent.
# Audio applies it, or grants it. Usage: python grant_audio.py <repo root>
import os, sys
os.chdir(sys.argv[1])
p = 'audio/audio_carry.gd'
s = open(p, encoding='utf-8').read()
a = "\tvar B: Dictionary = cfg.brake\n\tif String(e.text) == \"end\":\n"
assert s.count(a) == 1, 'the anchor in _brake moved'
s = s.replace(a, "\tvar B: Dictionary = cfg.brake\n\tif String(e.text) == \"ready\":\n\t\treturn   # the brake's ready (Simulation's brake2): Controls' haptic tick, no sound\n\tif String(e.text) == \"end\":\n")
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print("Audio: the brake's ready plays no sound")
