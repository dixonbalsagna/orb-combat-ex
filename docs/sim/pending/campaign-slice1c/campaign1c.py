# PARKED BUILD (Simulation): campaign slice 1c, the cross-back (Game Design's campaign.md 2.2: the rise's untaken place
# offered again at the escalation). Runs on a tree with slice 1b applied (docs/sim/pending/campaign-slice1b) and World's
# campaign-prefer (WorldCampaign.column's opts.prefer). Behind data/fight/campaign.json's enabled (off): with it off
# nothing moves, and the golden does not.
#   sim/core/campaign.gd: data crossBack {from, to}; crossBackPlace(arc) (column `from`'s first untaken named place);
#     beginColumn asks World for it at column `to` (prefer); columnDone keeps the place asked (arc.back) and each site's
#     preferred (0 or 1);
#   data/fight/campaign.json: crossBack {from 2, to 4};
#   sim/core/tools/campaign_episode.gd: a cross-back row, and the preferred site marked *;
#   sim/core/tools/parity.gd: the campaign's check asks the cross-back of a seeded episode, and none when there is none.
# Tools' schema lines are grant_tools.py. Usage: python campaign1c.py <repo root>
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(sys.argv[1])
assert 'WorldCampaign.mergeWear' in open('sim/core/campaign.gd', encoding='utf-8').read(), 'slice 1b first'
assert 'prefer' in open('sim/world/campaign.gd', encoding='utf-8').read(), "World's campaign-prefer first"

def edit(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:90], s.count(a))
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8', newline='\n').write(s)

def text(name):
    return open(os.path.join(HERE, 'files', name), encoding='utf-8').read()

edit('sim/core/campaign.gd', [
('const SITE_KEYS: Array = ["id", "kind", "place", "arc", "entry", "dir"]   # a site as the run state keeps it: whole numbers and short strings\n',
 'const SITE_KEYS: Array = ["id", "kind", "place", "arc", "entry", "dir", "preferred"]   # a site as the run state keeps it: whole numbers and short strings\n'),
('static var ringCols: int = 2400 ',
 'static var crossFrom: int = 2        # the cross-back (campaign.md 2.2): column crossFrom\'s untaken place is asked again at column crossTo\n'
 'static var crossTo: int = 4\n'
 'static var ringCols: int = 2400 '),
('\tringCols = _int("ringCols", j.get("ringCols"), 600, SimConst.PLANET_NC)\n',
 '\tringCols = _int("ringCols", j.get("ringCols"), 600, SimConst.PLANET_NC)\n' + text('ensure_cross.gd.txt')),
('"turns": [], "rings": [],\n', '"turns": [], "rings": [], "back": -1,\n'),
('\ta.turns = []\n\ta.rings = []\n', '\ta.turns = []\n\ta.rings = []\n\ta.back = -1\n'),
('\treturn WorldCampaign.beginColumn(int(state.planet.seed), episodeSeed(String(a.id), int(a.episode)), int(a.column) + 1, a.ring, int(a.pc),\n'
 '\t\t{"used": used, "wear": a.wear, "pin": climaxHome(a, P), "turn": true})\n',
 text('begin_column.gd.txt')),
("## ring length (its sites lie on it), whether the stage needs a match of another length (the climax's whole circle),\n## and the turn's degrees.\n",
 "## ring length (its sites lie on it), whether the stage needs a match of another length (the climax's whole circle),\n"
 "## the turn's degrees, and at column crossTo the place the cross-back asked (back; World marks it preferred if offered).\n"),
('\tvar sites: Array = []\n\tfor site in res.get("sites", []):\n',
 '\tif int(a.column) + 1 == crossTo:\n\t\ta.back = crossBackPlace(a)\n\tvar sites: Array = []\n\tfor site in res.get("sites", []):\n'),
])

edit('data/fight/campaign.json', [
('  "sideShare": ',
 '  "crossBack": {\n    "from": 2,\n    "to": 4\n  },\n'
 '  "_crossBack": "the cross-back (campaign.md 2.2): column `from`\'s untaken named place is asked of World again at column `to` (WorldCampaign.column\'s prefer); World offers it, leading the sites, when it stands in the band of a ring",\n'
 '  "sideShare": '),
])

edit('sim/core/tools/campaign_episode.gd', [
('\t\t\tss.append("%d:%s%s@%+d" % [x.id, x.kind, "" if int(x.place) < 0 else "#" + str(x.place), x.arc])\n',
 '\t\t\tss.append("%d:%s%s@%+d%s" % [x.id, x.kind, "" if int(x.place) < 0 else "#" + str(x.place), x.arc, "*" if int(x.get("preferred", 0)) == 1 else ""])   # *: the cross-back\'s place\n'),
('\tprint("  QA\'s record: %s" % JSON.stringify(a1.campaign, "", false))\n',
 '\tprint("  %s" % crossBackRow(arc))\n\tprint("  QA\'s record: %s" % JSON.stringify(a1.campaign, "", false))\n'),
])
s = open('sim/core/tools/campaign_episode.gd', encoding='utf-8').read()
open('sim/core/tools/campaign_episode.gd', 'w', encoding='utf-8', newline='\n').write(s + text('cross_back_row.gd.txt'))

edit('sim/core/tools/parity.gd', [
('\t\t\t\treturn "the episode used place %d twice" % int(a1.used[k])\n',
 '\t\t\t\treturn "the episode used place %d twice" % int(a1.used[k])\n' + text('parity_cross.gd.txt')),
])
print("the campaign, slice 1c: the cross-back (column 2's untaken place asked again at column 4), its row and check")
