# PARKED BUILD (Simulation): campaign slice 1b, SimCampaign wired to World's real calls (WorldCampaign, on main since
# 630dcbad; docs/world/campaign-route.md) in place of slice 1's stand-ins (docs/architecture/campaign-core.md). Runs on
# a tree with the first slice applied (622a0465). Behind data/fight/campaign.json's
# enabled (off), the campaign's one switch: with it off nothing moves, and the golden does not.
#   replaces sim/core/campaign.gd (SimCampaign: World's column job begun and its answer kept, the stage's setup at a
#     site re-centred by World's rebased, the wear merged by World's mergeWear, the side story by World's side, and
#     QA's campaign record from the run state, docs/qa/rally-campaign-rows.md),
#     sim/core/tools/campaign_recipes.gd (the episode on World's columns, its stage end read by World's wearOf),
#     sim/core/tools/campaign_episode.gd, data/fight/campaign.json (ringCols, the first ring, in place of
#     placesPerColumn, crossBack and stageCols, which are World's now) and parity's _campaign; slice 1's .uid files stay;
#   edits sim/core/replay.gd (a setup with wear takes World's campaign data into the replay's data hash).
# Tools' schema lines are grant_tools.py; World's one line (a setup's wear is laid whenever it has it) is grant_world.py.
# Usage: python campaign1b.py <repo root>
import os, shutil, sys
HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(sys.argv[1])
assert os.path.exists('sim/world/campaign.gd'), "World's campaign route (630dcbad) first"
s = open('sim/core/campaign.gd', encoding='utf-8').read() if os.path.exists('sim/core/campaign.gd') else ''
assert 'stageCols' in s, 'campaign-slice1 first (this replaces its stand-ins)'
assert 'SimCampaign.checkArc(state.arc)' in open('sim/core/run.gd', encoding='utf-8').read(), "slice 1's checkState hook"
FILES = ['sim/core/campaign.gd', 'sim/core/tools/campaign_recipes.gd', 'sim/core/tools/campaign_episode.gd', 'data/fight/campaign.json']
for f in FILES:
    assert os.path.exists(f) and (f.endswith('.json') or os.path.exists(f + '.uid')), f + ' (slice 1) is missing'
    shutil.copyfile(os.path.join(HERE, 'files', f + '.txt'), f)

def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:90], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)

edit('sim/core/replay.gd', [
("\tif setup.get(\"forms\", SimForms.enabled()) == true:   # forms: data/fight/forms.json and each fighter's forms.json, only for a match with them on\n"
 "\t\th.text(SimForms.dataHash())\n",
 "\tif setup.get(\"forms\", SimForms.enabled()) == true:   # forms: data/fight/forms.json and each fighter's forms.json, only for a match with them on\n"
 "\t\th.text(SimForms.dataHash())\n"
 "\tif setup.has(\"wear\"):   # a campaign stage's place state: World lays it by data/biomes/campaign.json's bands (campaign-core.md)\n"
 "\t\th.text(WorldCampaign.dataHash())\n"),
])

# parity: slice 1's check, from its doc comment to the next function, becomes slice 1b's
p = 'sim/core/tools/parity.gd'
s = open(p, encoding='utf-8').read()
a = "## The campaign's arc and episode (campaign-core.md)"
assert s.count(a) == 1 and s.count("\nfunc _campaign() -> String:\n") == 1, "slice 1's parity check"
i = s.index(a)
j = s.index("\nfunc _ringHolds(", i)
NEW = open(os.path.join(HERE, 'files', 'parity_campaign.gd.txt'), encoding='utf-8').read()
s = s[:i] + NEW + "\n\n" + s[j + 1:]
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print("the campaign, slice 1b: SimCampaign on World's calls, its recipe and check, the data's ringCols, the replay's wear, parity's check")
