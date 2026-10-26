# PARKED BUILD (Simulation): the planet's pacing in the run's data (the EP's go, 2026-10-23): World's host constant
# PLANET_UNITS_PER_READ (run.gd: planet units spent on a cold planet's make for each read a host asks of the ground)
# becomes data/fight/run.json's ground.planetUnitsPerRead, beside framesPerRead, read by SimRun's loader. The same 250:
# nothing moves, and the golden does not.
#   edits sim/core/run.gd and data/fight/run.json. Tools' schema line is grant_tools.py beside this.
# Usage: python units.py <repo root>
import json, os, sys
os.chdir(sys.argv[1])
def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:90], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)

s = open('sim/core/run.gd', encoding='utf-8').read()
assert 'const PLANET_UNITS_PER_READ: int = 250\n' in s, "World's host (w12) first"
i = s.index('## Planet units (a climate cell')
j = s.index('const PLANET_UNITS_PER_READ: int = 250\n') + len('const PLANET_UNITS_PER_READ: int = 250\n')
s = s[:i] + ('static var planetUnitsPerRead: int = 250   # data: ground.planetUnitsPerRead, planet units a read spends on a cold planet\'s make (World: a climate\n'
             '                                          # cell about 20 microseconds, a place\'s try-set 1000: about 5 ms a read)\n') + s[j:]
open('sim/core/run.gd', 'w', encoding='utf-8', newline='\n').write(s)
edit('sim/core/run.gd', [
("\tstages = _int(\"ground.stagesBeforeBoss\", g.get(\"stagesBeforeBoss\"), 1, 12)\n",
 "\tstages = _int(\"ground.stagesBeforeBoss\", g.get(\"stagesBeforeBoss\"), 1, 12)\n"
 "\tplanetUnitsPerRead = _int(\"ground.planetUnitsPerRead\", g.get(\"planetUnitsPerRead\"), 1, 100000)\n"),
("(PLANET_UNITS_PER_READ each)", "(SimRun.planetUnitsPerRead each, from the data)"),
("\t\t\tif not pj.step(n * SimRun.PLANET_UNITS_PER_READ):\n", "\t\t\tif not pj.step(n * SimRun.planetUnitsPerRead):\n"),
])

p = 'data/fight/run.json'
d = json.load(open(p, encoding='utf-8'))
assert 'planetUnitsPerRead' not in d['ground']
g = {}
for k, v in d['ground'].items():
    g[k] = v
    if k == '_framesPerRead':
        g['planetUnitsPerRead'] = 250
        g['_planetUnitsPerRead'] = ("planet units a read spends on the planet's own make while it is not made yet (World's host: a gen 2 planet, about a second, "
                                    "is made over the first beats of the stage before it, a frame at a time, and the pick starts when it is whole). A climate cell is a "
                                    "unit, about 20 microseconds, and a place's try-set 1000: 250 is about 5 ms a read")
d['ground'] = g
open(p, 'w', encoding='utf-8', newline='\n').write(json.dumps(d, indent=2, ensure_ascii=False) + '\n')
print("the planet's pacing in the run's data: ground.planetUnitsPerRead 250")
