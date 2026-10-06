extends SceneTree
## HUD words check (headless): the old HUD (F2, render/core/hud.gd) names a fighter by his roster id through UI's
## display names, and needs no field the roster's rename takes out of the sim (the title; the name becomes the id:
## docs/architecture/pending/fighter-split.md section 10). No headless gate drew the old HUD, and a read of a field
## that is gone is a run-time error, so the words are asked for here, for:
## - a fresh match's own two fighters, as the sim makes them today or after the rename;
## - stand-ins under the new ids with no title field at all.
## For each: the panel's first line is UI's display name for the id (and CPU for the computer); the second is the
## title and the stance, the title being UI's (UiData.display_title, when UI has the function and a title for the
## id), else the fighter's own while he still has the field, else left out; the label over the head uses the same
## name. And the damage marks: an id's outfit and seed are the same under both spellings of the two ids, and are
## what the fighters' names gave before the seed moved to the outfit.
##   godot --headless --path . --script res://render/tools/hud_words_check.gd

## A fighter as the old HUD reads him, with no title (and no signature name): the rename's shape.
class Stand:
	var id: String = ""
	var name: String = ""
	var ai = null
	var stance: int = 0
	var tier: float = 1.0
	var hidden: bool = false

var fails: int = 0


func _expect(ok: bool, what: String) -> void:
	print("%s %s" % ["ok   " if ok else "FAIL ", what])
	if not ok:
		fails += 1


func _initialize() -> void:
	var ui: Script = load("res://ui/core/ui_data.gd")   # asked by name: the function may not be in the tree yet
	var ui_has: bool = false
	for m in ui.get_script_method_list():
		if String(m.name) == "display_title":
			ui_has = true
	print("UI's display_title: %s" % ("in the tree" if ui_has else "not in the tree yet (the fighter's own title stands in while he has one)"))
	var S := SimCore.createSim()
	SimCore.newMatch(S, 4)
	var list: Array = [S.fighters[0], S.fighters[1]]
	for id in ["PROTAGONIST", "RIVAL"]:
		var s := Stand.new()
		s.id = id
		s.name = id
		s.ai = true if id == "RIVAL" else null
		list.append(s)
	for f in list:
		var who: String = "%s%s" % [str(f.id), "" if "title" in f else " (a stand-in with no title field)"]
		var want_title: String = str(ui.call("display_title", str(f.id))) if ui_has else ""
		if want_title == "" and "title" in f:
			want_title = str(f.title)
		var w: Array = HudView.panel_words(f)
		var want_name: String = UiData.display_name(str(f.id)) + ("  (CPU)" if f.ai != null else "")
		var want_sub: String = (want_title + "  ·  " if want_title != "" else "") + RenderLook.STANCE_LONG[int(f.stance)]
		_expect(w.size() == 2 and w[0] == want_name and str(w[0]) != "" and not str(w[0]).begins_with("  "), "%s: the panel names him by his id (\"%s\")" % [who, w[0]])
		_expect(w[1] == want_sub and not str(w[1]).begins_with("  ·"), "%s: the second line is his title, where there is one, and his stance (\"%s\")" % [who, w[1]])
		_expect(HudView.label_words(f).begins_with(UiData.display_name(str(f.id)) + " "), "%s: the label over his head uses the same name (\"%s\")" % [who, HudView.label_words(f)])
	_expect(not ("title" in list[2]) and not ("title" in list[3]), "the stand-ins have no title field, as the sim's fighters will not after the rename")
	# The damage marks by id: both spellings of an id wear the same outfit with the same seed, and the seed is what the
	# old name's hash gave (so the marks sit where they sat).
	for pair in [["KAI", "PROTAGONIST", "protagonist"], ["VORR", "RIVAL", "empress"]]:
		var before: float = float(absi(String(pair[0]).hash()) % 97) / 97.0
		_expect(FighterView.damage_outfit(pair[0]) == pair[2] and FighterView.damage_outfit(pair[1]) == pair[2], "%s and %s wear the %s outfit" % pair)
		_expect(FighterView.damage_seed(pair[0]) == before and FighterView.damage_seed(pair[1]) == before, "%s and %s have the seed the name %s gave (%d of 97)" % [pair[0], pair[1], pair[0], int(round(before * 97.0))])
	_expect(FighterView.damage_outfit("SOMEONE") == RenderLook.DAMAGE_OUTFIT_DEFAULT and FighterView.damage_seed("SOMEONE") == float(absi("SOMEONE".hash()) % 97) / 97.0, "an id with no outfit of its own wears the default with a seed of its own")
	SimCore.dispose(S)
	print("hud words check %s" % ("passed" if fails == 0 else "FAILED (%d)" % fails))
	quit(0 if fails == 0 else 1)
