# PARKED BUILD (Simulation): Orb's homework 3 answer, the reference fighter goes into the roster as a training dummy
# (docs/design/fighter-pipeline.md section 8). Apply after n_bodies.py.
#   data  data/fighters/roster.json gains REFERENCE, third; data/fighters/bench.json is left empty (the Empress's guards
#         will stand there)
#   code  sim/core/replay.gd: a replay's data hash takes the fighters in its slots, one hash each, in place of the
#         whole roster's; sim/core/tools/parity.gd: the roster's order, and the dummy's check in place of the bench's
#   golden: the roster's hash moves once (rosterHash) and with it the replays' data hash. No match moves: the default
#   pairing is the roster's first two, as before. ONE REGENERATION.
# Usage: python dummy_roster.py <repo root>
import json, os, sys
os.chdir(sys.argv[1])
def edit(p, pairs):
    s=open(p,encoding='utf-8').read()
    for a,b in pairs:
        assert s.count(a)==1,(p,a[:80],s.count(a))
        s=s.replace(a,b)
    open(p,'w',encoding='utf-8',newline='\n').write(s)

assert json.load(open('data/fighters/roster.json',encoding='utf-8')) == ["PROTAGONIST", "RIVAL"]
assert json.load(open('data/fighters/bench.json',encoding='utf-8')) == ["REFERENCE"]
open('data/fighters/roster.json','w',encoding='utf-8',newline='\n').write('["PROTAGONIST", "RIVAL", "REFERENCE"]\n')
open('data/fighters/bench.json','w',encoding='utf-8',newline='\n').write('[]\n')

edit('sim/core/replay.gd', [
('''	h.text(DirData.dataHash())
	h.text(FighterData.dataHash())
''','''	h.text(DirData.dataHash())
'''),
('''	for id in setup.get("slots", []):
		if id is String and FighterData.bench().has(id):
			h.text(id)
			h.text(FighterData.hashOf(id))
	return h.hex()
''','''	# the fighters in its slots, one hash each (FighterData.hashOf): a change to a fighter who is not in the match, the
	# training dummy's say, leaves the replay alone. The default pairing is the roster's first two.
	for id in setup.get("slots", FighterData.order().slice(0, 2)):
		h.text(String(id))
		h.text(FighterData.hashOf(String(id)))
	return h.hex()
'''),
('''## setup is the match's: a fighter from the bench that its slots name is folded in too. He is not in the roster, so he is
## not in the roster's hash; a replay that does not name him is the same whatever his data are.
''','''## setup is the match's: the fighters its slots name are folded in, one hash each, and nobody else.
'''),
])

p='sim/core/tools/parity.gd'
s=open(p,encoding='utf-8').read()
for a,b in [
 ('	if FighterData.order() != ["PROTAGONIST", "RIVAL"]:\n', '	if FighterData.order() != ["PROTAGONIST", "RIVAL", "REFERENCE"]:\n'),
 ('	check("the bench, and the reference fighter", _benchFighter())\n', '	check("the training dummy in the roster", _dummyFighter())\n'),
]:
    assert s.count(a)==1,(a[:60],s.count(a)); s=s.replace(a,b)
i=s.index('## The bench (data/fighters/bench.json): fighters that load and can be named in a match\'s setup but are not in the')
j=s.index('\n\n\n## ', s.index('func _benchFighter() -> String:'))+3
s=s[:i]+'''## The training dummy (fighter-pipeline.md section 8): the reference fighter, in the roster, last. His numbers are frozen:
## base stats, no care, no meter, the game's wounds and ladder. The bench is empty. Every fighter has a hash of his own, and
## a replay's data hash takes only the fighters in its slots: a change to the dummy's data moves the roster's hash and his
## own replays, and leaves a replay of the other two alone. He plays in either slot, and against himself.
func _dummyFighter() -> String:
	if FighterData.order() != ["PROTAGONIST", "RIVAL", "REFERENCE"] or not FighterData.bench().is_empty():
		return "the roster reads %s and the bench %s" % [str(FighterData.order()), str(FighterData.bench())]
	var d: Dictionary = FighterData.def("REFERENCE")
	var p: Dictionary = FighterData.def("PROTAGONIST")
	if d.dmgMul != 1.0 or d.spd != 1.0 or d.care != 0.0 or d.anguish or d.menace or d.role != "reference":
		return "the dummy's numbers are not the frozen base: damage %s, speed %s, care %s" % [str(d.dmgMul), str(d.spd), str(d.care)]
	for fname in ["wounds.json", "ladder.json", "meters.json"]:
		if FileAccess.file_exists(FighterData.ROOT + "REFERENCE/" + fname):
			return "the dummy has a %s of his own: his numbers are the game's" % fname
	if d.wd.wearPerDamage != p.wd.wearPerDamage or d.wd.family.light != p.wd.family.light or d.ld.taken != p.ld.taken or d.ld.thresholds != p.ld.thresholds:
		return "the dummy's wounds or ladder are not the game's"
	var hs := {}
	for id in FighterData.order():
		var hx: String = FighterData.hashOf(id)
		if hx == "" or hs.has(hx):
			return "the hash of %s is empty, or another fighter's" % id
		hs[hx] = true
	var d0: String = SimReplay.dataHash()
	if SimReplay.dataHash({"slots": ["PROTAGONIST", "RIVAL"]}) != d0:
		return "a replay of the default pairing named or not reads two data hashes"
	var dref: String = SimReplay.dataHash({"slots": ["REFERENCE", "RIVAL"]})
	if dref == d0:
		return "a replay of the dummy does not carry his data"
	for slots in [["REFERENCE", "REFERENCE"], ["REFERENCE", "PROTAGONIST"], ["RIVAL", "REFERENCE"]]:
		var S := SimCore.createSim()
		var su := {"slots": slots}
		if slots[0] == slots[1]:
			su.names = ["REFERENCE-A", "REFERENCE-B"]
		SimCore.newMatch(S, 5, {}, su)
		for t in range(900):
			SimCore.step(S)
			S.out.fx.clear()
			S.out.feed.clear()
		for i in range(2):
			var f = S.fighters[i]
			if f.id != slots[i] or not is_finite(f.x) or not is_finite(f.y):
				return "a match of %s: slot %d did not play as %s" % [str(slots), i, slots[i]]
		SimCore.dispose(S)
	var R := SimCore.createSim()
	var rec := SimReplay.recorder(R, 7, {}, {"slots": ["REFERENCE", "RIVAL"]})
	for t in range(600):
		rec.step([null, null])
		R.out.fx.clear()
		R.out.feed.clear()
	var rp: Dictionary = rec.finish()
	SimCore.dispose(R)
	if rp.data != dref or not SimReplay.play(JSON.parse_string(JSON.stringify(rp))).ok:
		return "a replay of the dummy does not carry his data hash, or does not play back"
	# his data change: the roster's hash and his own replays move; a replay of the other two does not
	var h0: String = FighterData.dataHash()
	var dir := "user://dummy_fixture/"
	for id in FighterData.order():
		DirAccess.make_dir_recursive_absolute(dir + id)
		for fname in ["fighter.json", "meters.json"]:
			if not FileAccess.file_exists(FighterData.ROOT + id + "/" + fname):
				continue
			var text: String = FileAccess.get_file_as_string(FighterData.ROOT + id + "/" + fname)
			if id == "REFERENCE" and fname == "fighter.json":
				if text.count("\\"dmgMul\\": 1.0") != 1:
					return "the fixture's pattern is not in the dummy's file once"
				text = text.replace("\\"dmgMul\\": 1.0", "\\"dmgMul\\": 1.04")
			var fw := FileAccess.open(dir + id + "/" + fname, FileAccess.WRITE)
			fw.store_string(text)
			fw.close()
	for name in ["roster.json", "bench.json"]:
		var fr := FileAccess.open(dir + name, FileAccess.WRITE)
		fr.store_string(FileAccess.get_file_as_string(FighterData.ROOT + name))
		fr.close()
	FighterData.quiet = true
	FighterData.loadFrom(dir)
	var out: String = ""
	if not FighterData.errors().is_empty():
		out = "the dummy fixture: " + "; ".join(FighterData.errors())
	elif FighterData.dataHash() == h0:
		out = "a change to the dummy's data did not move the roster's hash"
	elif SimReplay.dataHash() != d0:
		out = "a change to the dummy's data moved a replay of the other two"
	elif SimReplay.dataHash({"slots": ["REFERENCE", "RIVAL"]}) == dref or SimReplay.play(JSON.parse_string(JSON.stringify(rp))).reason != "data":
		out = "a replay of the dummy was not refused after his data changed"
	FighterData.quiet = false
	FighterData.loadFrom()
	return out


'''+s[j:]
open(p,'w',encoding='utf-8',newline='\n').write(s)

# two earlier checks built their fixtures for a roster of two: they take the roster as it is now
edit('sim/core/tools/parity.gd', [
("""		for id in ["PROTAGONIST", "RIVAL"]:
			DirAccess.make_dir_recursive_absolute(dir + id)
			for fname in ["fighter.json", "meters.json"]:
				var fw := FileAccess.open(dir + id + "/" + fname, FileAccess.WRITE)""",
 """		for id in FighterData.order():
			DirAccess.make_dir_recursive_absolute(dir + id)
			for fname in ["fighter.json", "meters.json"]:
				if not FileAccess.file_exists(FighterData.ROOT + id + "/" + fname):
					continue
				var fw := FileAccess.open(dir + id + "/" + fname, FileAccess.WRITE)"""),
("""		rf.store_string("[\\"PROTAGONIST\\", \\"RIVAL\\"]")
		rf.close()
		return dir""",
 """		rf.store_string(JSON.stringify(FighterData.order()))
		rf.close()
		return dir"""),
("""		for id in ["PROTAGONIST", "RIVAL"]:
			for fname in ["wounds.json", "ladder.json"]:
				full[id + "/" + fname]""",
 """		for id in FighterData.order():
			for fname in ["wounds.json", "ladder.json"]:
				full[id + "/" + fname]"""),
("""	for id in FighterData.order():
		for fname in ["fighter.json", "wounds.json", "meters.json", "ladder.json"]:
			files[id + "/" + fname] = _fighterText(id, fname)""",
 """	for id in ["PROTAGONIST", "RIVAL"]:   # the wired probes play the default pairing, in a roster of the two
		for fname in ["fighter.json", "wounds.json", "meters.json", "ladder.json"]:
			files[id + "/" + fname] = _fighterText(id, fname)"""),
])
print("the training dummy is in the roster")
