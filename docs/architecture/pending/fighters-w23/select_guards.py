# PARKED BUILD (Simulation): window 3 of docs/architecture/fighters-as-data.md, on top of windows 1 and 2.
# Selection: a match's setup names any two fighters the data has. Two guards:
#   - SimCore.newMatch refuses slots that are not two fighters the data has, and plays the default pairing (an error is
#     reported; it does not fail inside the fighter's construction);
#   - sim/core/tools/batch.gd takes any two ids: --a=ID --b=ID.
# The third guard of the plan, the default pairing written in the roster file, is NOT built: Tools' flash tools and
# Legal's pairing list read data/fighters/roster.json as a plain list. The default pairing stays the roster's first two,
# and parity's roster check holds the order.
# No golden moves. Usage: python select_guards.py <repo root>
import os, sys
os.chdir(sys.argv[1])
def edit(p, pairs):
    s=open(p,encoding='utf-8').read()
    for a,b in pairs:
        assert s.count(a)==1,(p,a[:80],s.count(a))
        s=s.replace(a,b)
    open(p,'w',encoding='utf-8',newline='\n').write(s)

edit('sim/core/sim.gd', [
('''	var slots: Array = setup.get("slots", FighterData.order().slice(0, 2))
''','''	var slots: Array = setup.get("slots", FighterData.order().slice(0, 2))
	if slots.size() != 2 or not (slots[0] is String and slots[1] is String) or not FighterData.has(slots[0]) or not FighterData.has(slots[1]):
		# slots that are not two fighters the data has (the roster's or the bench's): the default pairing plays
		if not FighterData.quiet:
			push_error("SimCore.newMatch: the setup's slots %s are not two fighters the data has; the default pairing plays" % str(slots))
		slots = FighterData.order().slice(0, 2)
'''),
('''## setup (D1a; the replay header's `setup`): {"slots": [id, id]} picks the fighters (default: the roster's first two),''',
 '''## setup (D1a; the replay header's `setup`): {"slots": [id, id]} picks any two fighters the data has, from the roster
## or the bench (default: the roster's first two; slots that are not two such fighters play the default, with an error),'''),
])

edit('sim/core/tools/batch.gd', [
('''##   godot --headless --path . --script res://sim/core/tools/batch.gd -- [matches=60] [baseSeed=1] [--arm=NAME] [--json] [--jobs=N]
''','''##   godot --headless --path . --script res://sim/core/tools/batch.gd -- [matches=60] [baseSeed=1] [--arm=NAME] [--json] [--jobs=N] [--a=ID --b=ID]
## --a=ID --b=ID plays any two fighters the data has, by id, in place of an arm's pairing (the same id twice is a mirror;
## with them --arm may only be default or default-flip).
'''),
('''var re_atk := RegEx.create_from_string(''','''var pair: Array = []   # --a and --b: the two fighters by id; empty for the arm's pairing

var re_atk := RegEx.create_from_string('''),
('''		elif a.begins_with("--records="):
			records_out = a.substr(10)
''','''		elif a.begins_with("--records="):
			records_out = a.substr(10)
		elif a.begins_with("--a="):
			pair = [a.substr(4), pair[1] if pair.size() == 2 else ""]
		elif a.begins_with("--b="):
			pair = [pair[0] if pair.size() == 2 else "", a.substr(4)]
'''),
('''	if n < 1 or not (arm.trim_suffix("-flip") in ["default", "swap", "mirror-villain", "mirror-hero"]):
''','''	if not pair.is_empty() and (not FighterData.has(pair[0]) or not FighterData.has(pair[1]) or arm.trim_suffix("-flip") != "default"):
		print("--a and --b take two fighter ids the data has (%s), with --arm=default or default-flip" % ", ".join(FighterData.order() + FighterData.bench()))
		quit(2)
		return
	if n < 1 or not (arm.trim_suffix("-flip") in ["default", "swap", "mirror-villain", "mirror-hero"]):
'''),
('''"--arm=" + arm, "--records=" + out]))''','''"--arm=" + arm, "--records=" + out] + ([] if pair.is_empty() else ["--a=" + pair[0], "--b=" + pair[1]])))'''),
('''	SimCore.newMatch(S, seed)
	SimGolden.applyArm(arm, S.fighters)
	var fs: Array = S.fighters
	var slot := {}
''','''	if pair.is_empty():
		SimCore.newMatch(S, seed)
		SimGolden.applyArm(arm, S.fighters)
	else:   # any two fighters by id; a mirror's two are told apart by name
		var su := {"slots": pair}
		if pair[0] == pair[1]:
			su.names = [pair[0] + "-A", pair[0] + "-B"]
		if arm.ends_with("-flip"):
			su.flip = true
		SimCore.newMatch(S, seed, {}, su)
	var fs: Array = S.fighters
	var slot := {}
'''),
])

edit('sim/core/tools/parity.gd', [
('''	check("the bench, and the reference fighter", _benchFighter())
''','''	check("the bench, and the reference fighter", _benchFighter())
	check("a match's slots name two fighters the data has", _slotGuard())
'''),
('''## D1a negative controls: fixtures made from PROTAGONIST's real files with one fault each''','''## A match's setup names any two fighters the data has. Slots that are not two such fighters (an id nobody has, one id,
## three, a number) play the default pairing: the match is the default match to the hash.
func _slotGuard() -> String:
	var want: String = ""
	var D := SimCore.createSim()
	SimCore.newMatch(D, 5)
	for t in range(300):
		SimCore.step(D)
		D.out.fx.clear()
		D.out.feed.clear()
	want = SimHash.stateHash(D).gameplay
	SimCore.dispose(D)
	FighterData.quiet = true
	var out: String = ""
	for bad in [["NOBODY", "RIVAL"], ["PROTAGONIST"], ["PROTAGONIST", "RIVAL", "REFERENCE"], [1, 2], []]:
		var S := SimCore.createSim()
		SimCore.newMatch(S, 5, {}, {"slots": bad})
		if S.fighters.size() != 2 or S.fighters[0].id != "PROTAGONIST" or S.fighters[1].id != "RIVAL":
			out = "slots %s did not play the default pairing" % str(bad)
		else:
			for t in range(300):
				SimCore.step(S)
				S.out.fx.clear()
				S.out.feed.clear()
			if SimHash.stateHash(S).gameplay != want:
				out = "slots %s played a match that is not the default match" % str(bad)
		SimCore.dispose(S)
		if out != "":
			break
	FighterData.quiet = false
	if out == "":
		var G := SimCore.createSim()
		SimCore.newMatch(G, 5, {}, {"slots": ["RIVAL", "REFERENCE"]})
		if G.fighters[0].id != "RIVAL" or G.fighters[1].id != "REFERENCE":
			out = "good slots were refused"
		SimCore.dispose(G)
	return out


## D1a negative controls: fixtures made from PROTAGONIST's real files with one fault each'''),
])
print("window 3: the slot guard and the batch tool's --a and --b are in")
