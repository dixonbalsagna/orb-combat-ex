# GRANT (World's sim/world/planet_world.gd, one line, and its check in sim/world/tools/campaign_check.gd, one line,
# for Simulation's campaign1b.py beside this): the campaign's one switch. A stage's setup carries `wear` only when the
# campaign's host made it, and the host makes it only while data/fight/campaign.json's enabled is on; so the match lays
# a setup's wear whenever the setup has it, with no second switch read inside the match (data/biomes/campaign.json's
# enabled stays World's tools' own). The setup is a match's input (a replay carries it, and SimReplay.dataHash takes
# World's campaign data with it), so a replay lays the same wear whatever either file's switch says. On main since
# 630dcbad, World's line reads its own switch, and campaign_check holds that a setup's wear is ignored with it off;
# the check now holds the reverse. Usage: python grant_world.py <root>
import os, sys
os.chdir(sys.argv[1])

def edit(p, a, b):
    s = open(p, encoding='utf-8').read()
    assert s.count(a) == 1, (p, a[:90], s.count(a), "World's campaign route (630dcbad) first")
    open(p, 'w', encoding='utf-8', newline='\n').write(s.replace(a, b))

edit('sim/world/planet_world.gd',
     "\tif setup.has(\"wear\") and WorldCampaign.enabled():   # the campaign's place state",
     "\tif setup.has(\"wear\"):   # the campaign's place state (the setup is the switch: the campaign's host gives it wear only while data/fight/campaign.json is on)")
edit('sim/world/tools/campaign_check.gd',
     "\tok(str(SimHash.stateHash(off).gameplay) == str(SimHash.stateHash(plain).gameplay), \"with the campaign off a setup's wear is ignored: the match is the plain one\")\n",
     "\tok(str(SimHash.stateHash(off).gameplay) == str(SimHash.stateHash(worn).gameplay), \"the setup is the switch: with World's own flag off a setup's wear is laid the same (the campaign's one switch is data/fight/campaign.json's, read by its host)\")\n")
print("World: a setup's wear is laid whenever it has it (the campaign's one switch is the run's), and campaign_check holds it")
