# GRANT (World's sim/world/contact.gd and brunt.gd, for Simulation's ricochet.py beside this): where a sent body meets a
# surface, the ricochet's glance (SimRicochet, behind data/fight/ricochet.json, off). Every line runs only with S.ricOn;
# off, World's contact is as before to the bit.
#   contact.gd  Body.rics (the row so far, from SimRicochet.inRow in toBody); _land: a fast, shallow landing on ground
#               sloped 30 degrees or more (SimRicochet.steepGround; not the sea, not past the journey's caps; flatter
#               ground keeps its skid, bounce, tumble and slam) glances by SimRicochet.rule in the slope's
#               frame, as a bounce World already pays (keep 0.7: wear and area by the speed removed, World's bounce
#               event with its keep) and leaves the ground; _apply tells it (SimRicochet.told: the count, the event)
#   brunt.gd    checkHit and its swept test: a building's face glances a fast, steep-to-the-face send (SimRicochet.offFace)
#               before the hit; a glance strikes nothing
# World applies it, or grants it. Usage: python grant_world.py <repo root>
import os, sys
os.chdir(sys.argv[1])
def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:90], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)

edit('sim/world/contact.gd', [
("\tvar z: float = 0.0            # depth (T: the row the ground is read on when depth is on)\n",
 "\tvar z: float = 0.0            # depth (T: the row the ground is read on when depth is on)\n"
 "\tvar rics: int = 0             # Simulation's ricochets in this send's row so far (SimRicochet.inRow): a glance's cap\n"),
("\tb.lips = f.jLips\n\tb.mode = AIR\n",
 "\tb.lips = f.jLips\n\tb.rics = SimRicochet.inRow(f)\n\tb.mode = AIR\n"),
("\tvar forceTumble: bool = b.contacts >= K_MAXC or b.t >= K_MAXT\n\tif slam:\n",
 "\tvar forceTumble: bool = b.contacts >= K_MAXC or b.t >= K_MAXT\n"
 "\tif S.ricOn and not sea and not forceTumble and SimRicochet.steepGround(s):   # Simulation's ricochet (sim/core/ricochet.gd): fast and shallow on steep ground, a glance\n"
 "\t\tvar gl: PackedFloat64Array = SimRicochet.rule(vn, vt, b.rics)\n"
 "\t\tif int(gl[0]) == SimRicochet.GLANCE:\n"
 "\t\t\tvar vxg: float = (gl[2] - s * gl[1]) / q\n"
 "\t\t\tvar vyg: float = (s * gl[2] + gl[1]) / q\n"
 "\t\t\tb.vx = vxg * tv\n"
 "\t\t\tb.vy = vyg\n"
 "\t\t\tb.rics += 1\n"
 "\t\t\tb.spin = _spinFor(b, vt)\n"
 "\t\t\tinfo[\"k\"] = \"bounce\"   # paid and told as a bounce that keeps SimRicochet.keep\n"
 "\t\t\tinfo[\"glance\"] = true\n"
 "\t\t\tinfo[\"n\"] = int(b.bounces)\n"
 "\t\t\tinfo[\"keep\"] = SimRicochet.keep\n"
 "\t\t\tev.append(info)\n"
 "\t\t\tev.append({\"k\": \"left_ground\", \"cause\": \"glance\", \"x\": b.x, \"y\": g, \"vx\": b.vx, \"vy\": b.vy, \"speed\": SimDetMath.hypot(vxg, vyg), \"slope\": s})\n"
 "\t\t\treturn\n"
 "\tif slam:\n"),
("\telif k in [\"skid\", \"tumble\", \"bounce\", \"slam\"]:\n\t\t_contact(S, f, by, b, e)\n",
 "\telif k in [\"skid\", \"tumble\", \"bounce\", \"slam\"]:\n\t\t_contact(S, f, by, b, e)\n"
 "\t\tif e.get(\"glance\", false):\n"
 "\t\t\tSimRicochet.told(S, f, \"glance\", String(e.surface), float(e.x), float(e.y))   # Simulation's: the row, the event\n"),
])
edit('sim/world/brunt.gd', [
("\thit(S, f, b, yc, edge, dir)\n\treturn true\n",
 "\tif S.ricOn and SimRicochet.offFace(S, f, b, yc, edge, dir):\n"
 "\t\treturn true   # Simulation's ricochet: he glanced off the face, and struck nothing\n"
 "\thit(S, f, b, yc, edge, dir)\n\treturn true\n"),
("\thit(S, f, b, hr.y, hr.x, dir)\n\treturn true\n",
 "\tif S.ricOn and SimRicochet.offFace(S, f, b, hr.y, hr.x, dir):\n"
 "\t\treturn true   # Simulation's ricochet: he glanced off the face, and struck nothing\n"
 "\thit(S, f, b, hr.y, hr.x, dir)\n\treturn true\n"),
])
print("World: the ground and a building's face glance, with the ricochet on")
