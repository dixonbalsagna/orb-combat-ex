extends SceneTree
## HUD words check (headless): the old HUD (F2, render/core/hud.gd) names a fighter by his roster id through UI's
## display names, and reads no word from the sim (the sim keeps no title, and its name is the id). No other headless
## gate draws the old HUD, and a read of a field the sim has dropped is a run-time error, so the words are asked for
## here, for:
## - a fresh match's own two fighters;
## - stand-ins with an id UI has no words for.
## For each: the panel's first line is UI's display name for the id (and CPU for the computer); the second is UI's
## title for the id, where it has one, and the stance; the label over the head uses the same name.
## And the damage marks: each roster id wears its outfit with the outfit's seed (the marks sit where they always
## sat), and an id with no outfit of its own wears the default with a seed of its own.
## And the demo's key help: it keeps to the screen's lowest fifth, so a short screen gets fewer lines.
##   godot --headless --path . --script res://render/tools/hud_words_check.gd

## A fighter as the old HUD reads him: an id, and nothing of the words.
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
	var S := SimCore.createSim()
	SimCore.newMatch(S, 4)
	var list: Array = [S.fighters[0], S.fighters[1]]
	for id in ["SOMEONE", "SOMEONE_ELSE"]:
		var s := Stand.new()
		s.id = id
		s.name = id
		s.ai = true if id == "SOMEONE_ELSE" else null
		list.append(s)
	_expect(not ("title" in list[0]) and not ("title" in list[1]), "the sim's fighters carry no title: the words are UI's")
	for f in list:
		var who: String = str(f.id)
		var title: String = UiData.display_title(who)
		var w: Array = HudView.panel_words(f)
		var want_name: String = UiData.display_name(who) + ("  (CPU)" if f.ai != null else "")
		var want_sub: String = (title + "  ·  " if title != "" else "") + RenderLook.STANCE_LONG[int(f.stance)]
		_expect(w.size() == 2 and w[0] == want_name and str(w[0]) != "" and not str(w[0]).begins_with("  "), "%s: the panel names him by his id (\"%s\")" % [who, w[0]])
		_expect(w[1] == want_sub and not str(w[1]).begins_with("  ·"), "%s: the second line is his title, where UI has one, and his stance (\"%s\")" % [who, w[1]])
		_expect(HudView.label_words(f).begins_with(UiData.display_name(who) + " "), "%s: the label over his head uses the same name (\"%s\")" % [who, HudView.label_words(f)])
	_expect(UiData.display_title(str(list[0].id)) != "" and UiData.display_title("SOMEONE") == "", "UI has a title for a roster fighter and none for an id it does not know")
	# The damage marks by roster id: the outfit, and the outfit's seed (the numbers the marks have always had).
	for row in [["PROTAGONIST", "protagonist", 16], ["RIVAL", "empress", 48]]:
		_expect(FighterView.damage_outfit(row[0]) == row[1], "%s wears the %s outfit" % [row[0], row[1]])
		_expect(FighterView.damage_seed(row[0]) == float(row[2]) / 97.0, "%s has his outfit's seed (%d of 97)" % [row[0], row[2]])
	_expect(FighterView.damage_outfit("SOMEONE") == RenderLook.DAMAGE_OUTFIT_DEFAULT and FighterView.damage_seed("SOMEONE") == float(absi("SOMEONE".hash()) % 97) / 97.0, "an id with no outfit of its own wears the default with a seed of its own")
	for id in S.fighters.map(func(f): return str(f.id)):
		_expect(RenderLook.DAMAGE_OUTFIT.has(id), "the roster's %s has an outfit of his own" % id)
	# The demo's key help: three lines fit a 720 screen as before; a shorter screen gets fewer, and the prompt alone
	# when there is no room.
	_expect(HudView.help_room(720.0) >= 3 and HudView.help_room(1080.0) >= HudView.help_room(720.0), "a 720 screen has room for the three lines of key help it always had (%d)" % HudView.help_room(720.0))
	_expect(HudView.help_room(450.0) == 1 and HudView.help_room(360.0) == 0, "a 450 screen keeps one line and a 360 screen the prompt alone (%d, %d)" % [HudView.help_room(450.0), HudView.help_room(360.0)])
	SimCore.dispose(S)
	print("hud words check %s" % ("passed" if fails == 0 else "FAILED (%d)" % fails))
	quit(0 if fails == 0 else 1)
