"""World, 2026-10-30: the pages for the kept swap preparation and the replay-header helpers.   python mk_p45.py <root>"""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def calm(s):
    s = rep(s, "`E.cold` counts a swap that had to read (a state carried into a process that never warmed it: the same ring, so the same result, and a hitch); in play it stays 0.",
            "`WorldEpoch.coldCount` counts a swap that had to read (a state carried into a process that never warmed it: the same ring, so the same result, and a hitch); in play it stays 0. It is a process counter and not state (it was `E.cold`), so a rolled-back re-run of a swap leaves the state as a straight run does.")
    s = rep(s, "(`E.unprep` counts it), so the turn is the same either way.", "(`WorldEpoch.unprepCount`, a process counter like `coldCount`, counts it), so the turn is the same either way.")
    s = rep(s, "`epoch_check` has the equal-either-way test (the same state hash with the preparation and with it lost).",
            "`epoch_check` has the equal-either-way test (the same state hash with the preparation and with it lost).\n\n**Kept after the swap (2026-10-30).** The swap does not drop the ring job and the preparation it used: it retires them (`WorldEpoch._retire`), keyed by the world it turned away from, for `KEEP_TICKS` (21, NetSession's `maxAhead` 20 and one) sim ticks; `tick()` sweeps what has aged out, and `SimCore.dispose` releases a disposed sim's (`WorldEpoch.release`, which also drops every world the sim made entries for; `NetSnapshot.restore` disposes with `keepWorld`, since the restored state plays on). A rollback that restores a state of that world and runs the swap again finds them: the swap tick is the swap and not a ring read plus a preparation (`rerun_cost.gd`: about 60 ms before (90 to 107 on a loaded machine) and about 2 ms after, on a Half ring, with the same state hash). The kept preparation is safe to use twice because the swap binds its structures `fresh` (the prepared buildings and trees stay pristine) and the kept buildings' districts are generation records the restore puts back (packed-structures.md).")
    return s


def density(s):
    return s.rstrip('\n') + "\n\n## The replay header\n\n`WorldDensity.enabled()` is the switch and `WorldDensity.dataHash()` the hash of the parsed data without the `_` notes, made once. A gen 2 replay's buildings follow `density.json`, so Simulation folds the hash in for a gen 2 setup (`WorldClimate.genFor(setup)`: the setup's `planetGen`, else climate.json's `gen`, never `genNow()`, which is a tool's choice or the last match's). `WorldPlanet.dataHash(gen)` takes that generation (0, the default, is the one in force, as every caller so far).\n"


rw(R, 'docs/world/calm-turn-world.md', calm)
rw(R, 'docs/world/density.md', density)
print('p45 applied')
