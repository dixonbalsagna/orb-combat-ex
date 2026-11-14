#!/usr/bin/env python3
"""Horde trial T1 (docs/ep/proposals/horde-trial-design.md sections 5, 6.1 to 6.3; Game Design's rulings docs/design/horde-trial.md):
the state, the data file and its loader, the five slots, `ended`, the hash and replay lines, and the away body made inert (step, input, hit).
Places stand as dummies: every place starts away, parked straight up. Scratch only; nothing lands.
python t1_build.py <tree>"""
import sys, os, json
root = sys.argv[1]
HERE = os.path.dirname(os.path.abspath(__file__))


def edit(rel, pairs):
    p = os.path.join(root, rel)
    s = open(p, encoding='utf8', newline='').read()
    crlf = '\r\n' in s
    s = s.replace('\r\n', '\n')
    for a, b in pairs:
        assert s.count(a) == 1, (rel, s.count(a), a[:100])
        s = s.replace(a, b)
    if crlf:
        s = s.replace('\n', '\r\n')
    open(p, 'w', encoding='utf8', newline='').write(s)


def put(rel, text):
    p = os.path.join(root, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, 'w', encoding='utf8', newline='').write(text)


# --- the data: the design's block with Game Design's default arm (row G: the gap 113 at medium, easy 170, hard 68; blows 2, 4, 2; bodyShare 1.0)
put('data/fight/horde.json', open(os.path.join(HERE, 'horde.json'), encoding='utf8').read())

# --- the core's file
put('sim/core/horde.gd', open(os.path.join(HERE, 'horde_core.gd'), encoding='utf8').read())

# --- state.gd: the switch, the run, a body's part
edit('sim/core/state.gd', [
    ('var kickOn: bool = false              # the kick and the coin turn',
     'var hordeOn: bool = false             # the horde (sim/core/horde.gd): data/fight/horde.json\'s switch, or the setup\'s "horde"\n'
     'var horde = null                      # ... HordeRun while S.hordeOn, null otherwise\n'
     'var kickOn: bool = false              # the kick and the coin turn'),
    ('## A fighter\'s kick and coin turn while S.kickOn (sim/core/kick.gd).\nclass KickState:',
     '## The horde\'s run, while S.hordeOn (sim/core/horde.gd).\n'
     'class HordeRun:\n'
     '\tvar wave: int = 0                 # the wave now, from 1; 0 before the first\n'
     '\tvar up: int = 0                   # bodies of this wave not yet down (sent or still to come)\n'
     '\tvar mix := PackedInt32Array()     # bodies of this wave still to send: fodder, bruiser, speedster\n'
     '\tvar rest: int = 0                 # ticks left of the breather; 0 while a wave is on\n'
     '\tvar t: int = 0                    # live ticks of the run\n'
     '\tvar over: int = 0                 # 0 running, 1 every wave cleared, 2 every player down, 3 the backstop\n'
     '\tvar sent: int = 0                 # bodies sent in so far: the keyed draws\' counter\n'
     '\tvar felled: int = 0               # for the result\n'
     '\tvar mark := PackedInt32Array()    # for each slot, the slot it is fighting now\n'
     '\tvar lane := PackedInt32Array()    # for each seat, `places` lanes: the tick the lane is free from; -1 while a wind-up holds it\n'
     '\n\n'
     '## A body\'s part in the horde\'s run, while S.hordeOn; null otherwise, as f.kik is.\n'
     'class HordeBody:\n'
     '\tvar kind: int = 0                 # 0 a seat, 1 fodder, 2 bruiser, 3 speedster\n'
     '\tvar phase: int = 0                # 0 away, 1 arriving, 2 in the fight, 3 winding up, 4 open, 5 reeling, 6 sent, 7 down (a seat only)\n'
     '\tvar t: int = 0                    # the tick this phase ends, or the tick a place refills; 0 none\n'
     '\tvar worth: float = 0.0            # toughness left\n'
     '\tvar at: int = 0                   # the tick this body\'s own pack blow lands; 0 none\n'
     '\tvar w: int = 0                    # that blow\'s weight: 1 light, 2 medium, 3 heavy\n'
     '\tvar buf: int = 0                  # a seat: one kept press\'s weight; 0 none\n'
     '\tvar ready: int = 0                # a place: the tick from which it may wind up\n'
     '\tvar ln: int = -1                  # a place: the lane it holds at its mark while it winds up; -1 none\n'
     '\tvar due: int = -100000            # a seat: the latest tick a pack blow is due to land on them\n'
     '\tvar dg: int = -100000             # a seat: the last dodge tap seen\n'
     '\tvar dgOk: int = 0                 # a seat: 1 when that tap was clean\n'
     '\tvar was: int = 0                  # a seat: 1 once a pad has taken it in this run\n'
     '\tvar taken: int = 0                # a seat: pack blows that landed, for the result\n'
     '\tvar downs: int = 0                # a seat: times down\n'
     '\n\n'
     '## A fighter\'s kick and coin turn while S.kickOn (sim/core/kick.gd).\nclass KickState:'),
    ('\tvar kik = null                   # the kick: KickState while S.kickOn (sim/core/kick.gd), null otherwise\n',
     '\tvar kik = null                   # the kick: KickState while S.kickOn (sim/core/kick.gd), null otherwise\n'
     '\tvar hd = null                    # the horde: HordeBody while S.hordeOn (sim/core/horde.gd), null otherwise\n'),
])

# --- sim.gd: the slots, the bodies past the pair on the computer, the switch, the set-up, ended, the away body not stepped
edit('sim/core/sim.gd', [
    ('\tvar slots: Array = setup.get("slots", SimStage.slotsFor() if fights == 2 else FighterData.order().slice(0, 2))\n',
     '\tvar horde: bool = setup.get("horde", SimHorde.enabled()) == true   # the horde: five fixed slots, the seats then the places (sim/core/horde.gd)\n'
     '\tvar slots: Array = SimHorde.slots(setup) if horde else setup.get("slots", SimStage.slotsFor() if fights == 2 else FighterData.order().slice(0, 2))\n'),
    ('\t\tS.fighters.append(SimRoster.createFighter(FighterData.def(slots[k]), gx, key, ai.get(key, fights == 2) == true))\n',
     '\t\tS.fighters.append(SimRoster.createFighter(FighterData.def(slots[k]), gx, key, horde or ai.get(key, fights == 2) == true))\n'),
    ('\tSimKick.setup(S, setup)\n\tJ.phase = 4\n',
     '\tSimKick.setup(S, setup)\n'
     '\tS.hordeOn = setup.get("horde", SimHorde.enabled()) == true   # the horde: the data\'s switch (data/fight/horde.json), or the setup\'s\n'
     '\tJ.phase = 4\n'),
    ('\tSimPause.reset(S)        # Q10: the pause bank\n\tSimShots.reset(S)        # no shots in flight\n\tJ.phase = 6\n',
     '\tSimPause.reset(S)        # Q10: the pause bank\n\tSimShots.reset(S)        # no shots in flight\n'
     '\tSimHorde.setup(S, setup)   # the horde\'s run and each body\'s part; away bodies parked (after the floor\'s start above, which would set them down)\n'
     '\tJ.phase = 6\n'),
    ('static func ended(S: SimState) -> bool:\n',
     'static func ended(S: SimState) -> bool:\n'
     '\tif S.hordeOn:\n\t\treturn S.horde.over != 0   # the horde: the run\'s own end, never a KO\n'),
    ('\tfor f in S.fighters:\n\t\tSimFighter.stepFighter(S, f, dt)\n\tDirExchange.dirUpdate(S, dt)\n',
     '\tfor f in S.fighters:\n'
     '\t\tif S.hordeOn and f.out:\n'
     '\t\t\tcontinue   # the horde: an away body is not stepped (no power fills, no tier rises, no pause from an empty slot)\n'
     '\t\tSimFighter.stepFighter(S, f, dt)\n\tDirExchange.dirUpdate(S, dt)\n'),
])

# --- hash.gd: only when on
edit('sim/core/hash.gd', [
    ('\t\tif S.kickOn:   # the kick: only when on, so a match without it hashes as before\n',
     '\t\tif S.hordeOn:   # the horde: only when on, so a match without it hashes as before\n'
     '\t\t\t_obj(out, f.hd, SimHorde.HASHED_BODY)\n'
     '\t\t\tout.append(1.0 if f.out else 0.0)\n'
     '\t\tif S.kickOn:   # the kick: only when on, so a match without it hashes as before\n'),
    ('\t_obj(out, S.world, ["pop0", "mass0",',
     '\tif S.hordeOn:   # the horde\'s run: only when on\n'
     '\t\t_obj(out, S.horde, SimHorde.HASHED_RUN)\n'
     '\t\tfor v in S.horde.mix: out.append(float(v))\n'
     '\t\tfor v in S.horde.mark: out.append(float(v))\n'
     '\t\tfor v in S.horde.lane: out.append(float(v))\n'
     '\t_obj(out, S.world, ["pop0", "mass0",'),
])

# --- replay.gd: the file in a replay's data hash, only for a match with it on
edit('sim/core/replay.gd', [
    ('\tif setup.get("kick", SimKick.enabled()) == true:',
     '\tif setup.get("horde", SimHorde.enabled()) == true:   # the horde: data/fight/horde.json, only for a match with it on\n'
     '\t\th.text(SimHorde.dataHash())\n'
     '\tif setup.get("kick", SimKick.enabled()) == true:'),
])

# --- control.gd (Controls' file): away or down, no input is read
edit('sim/input/control.gd', [
    ('\tSimIntent.clearIntent(i)\n',
     '\tSimIntent.clearIntent(i)\n'
     '\tif S.hordeOn and (f.out or f.hd.phase == 7):\n'
     '\t\treturn   # the horde: away or down, no input is read\n'),
])

# --- damage.gd: away or down, nothing lands
edit('sim/core/damage.gd', [
    ('static func hit(S: SimState, ex, A, D, dmg: float, o = null) -> float:\n',
     'static func hit(S: SimState, ex, A, D, dmg: float, o = null) -> float:\n'
     '\tif S.hordeOn and (D.out or D.hd.phase == 7):\n'
     '\t\treturn 0.0   # the horde: away or down, nothing lands on them, whatever threw it\n'),
])

put('sim/director/tools/horde_check.gd', open(os.path.join(HERE, 'horde_check.gd'), encoding='utf8').read())
print('T1 applied to', root)

# --- exchange.gd (moved up from T3: without it the pad's request starts an exchange with the away seat): the three places an exchange is made
edit('sim/director/exchange.gd', [
    ('static func _start(S: SimState, A, kind: String) -> int:\n',
     'static func _start(S: SimState, A, kind: String) -> int:\n'
     '\tif S.hordeOn:\n\t\treturn DROPPED   # the horde: in a horde match nothing starts an exchange; the request is spent (sim/director/horde.gd)\n'),
    ('static func startZip(S: SimState, A, D, kind: String):\n',
     'static func startZip(S: SimState, A, D, kind: String):\n'
     '\tif S.hordeOn:\n\t\treturn null   # the horde: no exchange (reached only through DirZip.takes; belt and braces)\n'),
    ('static func _shotFinisher(S: SimState, W, L) -> void:\n',
     'static func _shotFinisher(S: SimState, W, L) -> void:\n'
     '\tif S.hordeOn:\n\t\treturn   # the horde: no exchange\n'),
])
print('T1 exchange guards applied')
