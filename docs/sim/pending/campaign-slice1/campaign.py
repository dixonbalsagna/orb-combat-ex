# PARKED BUILD (Simulation): the campaign's sim foundation for first-slice step 1 (Game Design's campaign.md 1.1 to
# 1.4, 2 and 7; docs/architecture/campaign-core.md): one solo episode, five columns on one planet, chosen by flying.
# Behind data/fight/campaign.json's enabled (off): with it off nothing moves, and the golden does not.
#   adds sim/core/campaign.gd (SimCampaign: the arc block in the run state, the episode seed H(arc, "episode", e) and
#     every column's draws from it, column progression, the side story, threads as ids, the season record) and its
#     .uid; sim/core/tools/campaign_recipes.gd (SimCampaignRun: a seeded episode played headless) and its .uid;
#     sim/core/tools/campaign_episode.gd (the episode twice, the same to the bit) and its .uid; data/fight/campaign.json;
#   edits sim/core/run.gd (checkState checks an arc block) and sim/core/tools/parity.gd ("the campaign's arc and
#     episode").
# Tools' schema lines (fight-campaign.schema.json, its map rule, its cases, the virtual copy) are grant_tools.py.
# Usage: python campaign.py <repo root>
import os, shutil, sys
HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(sys.argv[1])
FILES = ['sim/core/campaign.gd', 'sim/core/campaign.gd.uid', 'sim/core/tools/campaign_recipes.gd', 'sim/core/tools/campaign_recipes.gd.uid',
         'sim/core/tools/campaign_episode.gd', 'sim/core/tools/campaign_episode.gd.uid', 'data/fight/campaign.json']
for f in FILES:
    assert not os.path.exists(f), f + ' is already there'
for f in FILES:
    shutil.copyfile(os.path.join(HERE, 'files', f + '.txt'), f)

def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:90], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)

edit('sim/core/run.gd', [
("\tif not (state.get(\"ledger\") is Array):\n\t\treturn \"the ledger is a list\"\n\treturn \"\"\n",
 "\tif not (state.get(\"ledger\") is Array):\n\t\treturn \"the ledger is a list\"\n"
 "\tif state.has(\"arc\"):   # a campaign episode's arc block (SimCampaign, campaign-core.md)\n"
 "\t\tvar r: String = SimCampaign.checkArc(state.arc)\n"
 "\t\tif r != \"\":\n"
 "\t\t\treturn \"arc: \" + r\n"
 "\treturn \"\"\n"),
])

CHECK = open(os.path.join(HERE, 'files', 'parity_campaign.gd.txt'), encoding='utf-8').read()
edit('sim/core/tools/parity.gd', [
("\tcheck(\"the run's state and carry\", _runState())\n",
 "\tcheck(\"the run's state and carry\", _runState())\n"
 "\tcheck(\"the campaign's arc and episode\", _campaign())\n"),
("func _ringHolds(ev: Dictionary, id: int) -> bool:\n", CHECK + "\n\nfunc _ringHolds(ev: Dictionary, id: int) -> bool:\n"),
])
print("the campaign: SimCampaign, its recipe and check, the switch (off), checkState's arc, parity's check")
