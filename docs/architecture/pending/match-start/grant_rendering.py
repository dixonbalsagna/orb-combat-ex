# GRANT (Rendering's render/core/sim_host.gd and render/core/main.gd, for Simulation's match_start.py beside this): the
# game's host starts a match in pieces (SimCore.beginMatch) and draws the loading screen between them, through the load
# path the planet's load already uses (loading(), load_phase(), load_progress(), load_step() a frame, cancel_load() on
# Back). Opt-in: the host's stepped_start, which the game's main sets (not a tool's: a tool that starts matches through
# a SimHost gets them whole at once, as before).
#   sim_host.gd: stepped_start, match_job; new_match runs the head at once and leaves the rest to load_step; the rest of
#     new_match is _started(su, remember), run when the match has started; loading() and the phase ("match") and
#     progress read the job too; load_step steps it a piece a frame, and is true only when the match has started;
#     cancel_load drops it;
#   main.gd: host.stepped_start before the boot's match (not under a tool's main, not with --syncstart).
# Usage: python grant_rendering.py <repo root>
import os, sys
os.chdir(sys.argv[1])


def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:90], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)


edit('render/core/sim_host.gd', [
("var _load_call: Array = []               # the new_match call that waits: [seed, ai, setup, remember]\n",
 "var _load_call: Array = []               # the new_match call that waits: [seed, ai, setup, remember]\n"
 "var stepped_start: bool = false          # the game's: a match starts in pieces (SimCore.beginMatch), the loading screen between them (docs/architecture/match-start.md); a tool's host starts it whole\n"
 "var match_job = null                     # a match starting in pieces (SimCore.MatchJob): load_step runs one a frame\n"
 "var _start_args: Array = []              # what the host does when it has started: [setup, remember]\n"),
("\tSimCore.newMatch(S, seed, ai, su)\n\tsky.reset(S)\n",
 "\tif stepped_start:   # the match's start in pieces: the head now, the rest a piece a frame (load_step), the loading screen between them\n"
 "\t\tmatch_job = SimCore.beginMatch(S, seed, ai, su)\n"
 "\t\t_start_args = [su, remember]\n"
 "\t\tif not match_job.step():\n"
 "\t\t\treturn\n"
 "\t\tmatch_job = null   # refused (a gen 2 planet not made): done at once, as newMatch is\n"
 "\telse:\n"
 "\t\tSimCore.newMatch(S, seed, ai, su)\n"
 "\t_started(su, remember)\n"
 "\n\n"
 "## The host's part once the sim's match has started: the sky, the flashes, the camera, the effects and the first capture.\n"
 "func _started(su: Dictionary, remember: bool) -> void:\n"
 "\tsky.reset(S)\n"),
("func loading() -> bool:\n\treturn load_job != null\n",
 "func loading() -> bool:\n\treturn load_job != null or match_job != null\n"),
("\treturn load_job.phase if load_job != null else \"done\"\n",
 "\treturn load_job.phase if load_job != null else (\"match\" if match_job != null else \"done\")\n"),
("\treturn load_job.progress() if load_job != null else 1.0\n",
 "\treturn load_job.progress() if load_job != null else (match_job.progress() if match_job != null else 1.0)\n"),
("func load_step() -> bool:\n"
 "\tif load_job == null or not load_job.step(SimRun.planetUnitsPerRead):\n"
 "\t\treturn false\n",
 "func load_step() -> bool:\n"
 "\tif load_job == null and match_job != null:   # the match's own start, a piece a frame\n"
 "\t\tif not match_job.step():\n"
 "\t\t\treturn false\n"
 "\t\tmatch_job = null\n"
 "\t\t_started(_start_args[0], _start_args[1])\n"
 "\t\t_start_args = []\n"
 "\t\treturn true\n"
 "\tif load_job == null or not load_job.step(SimRun.planetUnitsPerRead):\n"
 "\t\treturn false\n"),
("\tnew_match(call[0], call[1], call[2], call[3])\n\tSimPlanetLoad.strict = was\n\treturn true\n",
 "\tnew_match(call[0], call[1], call[2], call[3])\n\tSimPlanetLoad.strict = was\n\treturn match_job == null   # with stepped_start the match's own pieces follow, a frame each\n"),
("func cancel_load() -> void:\n\tload_job = null\n\t_load_call = []\n",
 "func cancel_load() -> void:\n\tload_job = null\n\t_load_call = []\n\tmatch_job = null   # a match half started is dropped too: the next new_match starts one whole\n\t_start_args = []\n"),
])

edit('render/core/main.gd', [
("\tstart_match(int(args[\"seed\"]) if args.has(\"seed\") else fresh_seed())\n\tif args.has(\"human\"):\n",
 "\thost.stepped_start = not manual and not args.has(\"syncstart\")   # the match starts in pieces, the loading screen between them (docs/architecture/match-start.md); a tool's main starts it whole\n"
 "\tstart_match(int(args[\"seed\"]) if args.has(\"seed\") else fresh_seed())\n\tif args.has(\"human\"):\n"),
("\t\tif not args.has(\"nosplit\"):\n\t\t\tsplit_view.attach(self)\n",
 "\t\tif not args.has(\"nosplit\"):\n"
 "\t\t\tif host.loading():\n"
 "\t\t\t\t_attach_pending = true   # the boot's match is starting in pieces: the split attaches when it is built (_match_built), after it, as after a whole start\n"
 "\t\t\telse:\n"
 "\t\t\t\tsplit_view.attach(self)\n"),
("var _match_ever: bool = false ",
 "var _attach_pending: bool = false   # the split view waits for the boot's match, started in pieces (_match_built attaches it)\n"
 "var _match_ever: bool = false "),
("\tsplit_rig.reset(host.S, vp.x, vp.y)\n\trender_view(host.alpha())\n\n",
 "\tsplit_rig.reset(host.S, vp.x, vp.y)\n\trender_view(host.alpha())\n"
 "\tif _attach_pending:\n"
 "\t\t_attach_pending = false\n"
 "\t\tsplit_view.attach(self)\n\n"),
])
print("Rendering: the host starts a match in pieces (stepped_start, the game's), with the loading screen between them")
