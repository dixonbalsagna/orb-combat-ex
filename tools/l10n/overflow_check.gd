extends SceneTree
## The pseudo-locale against the real layout and the real font (Accessibility and Localization). A report, not a gate:
## it lays out each screen with ui/data and then with localization/pseudo/ui/data (tools/l10n/pseudo.mjs --write),
## using the widgets' own plan() functions, and lists what fits with English but not with the longer text. It also
## checks which scripts the game's one font can draw.
##
##     godot --headless --path . --script res://tools/l10n/overflow_check.gd
##
## Read only: it swaps the tables inside UiData for this process and writes nothing. Exit 0 with a report; exit 1 only
## when the pseudo files are missing. The screens it cannot reach this way (the plates, the legend, the prompt row)
## are listed at the end as not checked.

const SRC_DIR := "res://ui/data/"
const PSEUDO_DIR := "res://localization/pseudo/ui/data/"
const NAMES := ["terms", "options", "settings", "howto", "hints", "stances", "reads", "feedback", "send", "glyphs"]

# Viewports from hud_check's lists: desktop, a small window, phones both ways, and two small browser windows.
const CASES := [[Vector2(1920, 1080), 1.0], [Vector2(1280, 720), 1.0], [Vector2(1024, 576), 1.0], [Vector2(2400, 1080), 2.6],
	[Vector2(2532, 1170), 3.0], [Vector2(1170, 2532), 3.0], [Vector2(1080, 2340), 2.75], [Vector2(390, 844), 1.0], [Vector2(360, 640), 1.0]]

# One word or phrase per script, to see what the font can draw (the l10n plan's font table).
const SCRIPTS := {
	"Latin (French, Spanish, Portuguese)": "Paramètres Configuración Configurações ÀÉÎÕÜÇÑ",
	"Latin (German, Polish, Czech, Turkish)": "Einstellungen ß Ustawienia ąęłńśźż Nastavení řůě Ayarlar ğış",
	"Latin (Vietnamese)": "Cài đặt Tiếng Việt ằẳẵặ",
	"Greek": "Ρυθμίσεις",
	"Cyrillic": "Настройки Налаштування",
	"Arabic": "الإعدادات",
	"Hebrew": "הגדרות",
	"Devanagari (Hindi)": "सेटिंग्स",
	"Thai": "การตั้งค่า",
	"Chinese (Simplified)": "设置游戏",
	"Japanese": "設定 せってい セッテイ",
	"Korean": "설정",
}

var src: Dictionary = {}
var pseudo: Dictionary = {}
var lines: PackedStringArray = []
var newly_bad := 0
var cut_desktop: PackedStringArray = []   # the Settings rows whose English help is cut at 1920x1080


func _initialize() -> void:
	for n in NAMES:
		src[n] = _load(SRC_DIR + n + ".json")
		var p: String = PSEUDO_DIR + n + ".json"
		pseudo[n] = _load(p) if FileAccess.file_exists(p) else src[n]
	if not FileAccess.file_exists(PSEUDO_DIR + "terms.json"):
		print("overflow_check: no pseudo-locale at %s (run node tools/l10n/pseudo.mjs --write)" % PSEUDO_DIR)
		quit(1)
		return
	_fonts()
	_screens()
	_cards_and_banner()
	lines.append("")
	lines.append("Not checked here (no plan() to call without a live fighter model): the nameplates and their chips (UiPlate cuts a long name with an ellipsis), the control legend (UiHints.plan), the prompt row and the How to play stances table's cells.")
	lines.append("overflow_check: %d screen layouts fit in English but not in the pseudo-locale" % newly_bad)
	print("\n".join(lines))
	quit(0)


func _load(path: String) -> Dictionary:
	var v = JSON.parse_string(FileAccess.get_file_as_string(path))
	return v if v is Dictionary else {}


## Point UiData at one set of tables for this process.
func _use(t: Dictionary) -> void:
	UiData.ensure()
	UiData._terms = t["terms"]
	UiData._options = (t["options"] as Dictionary).get("options", {})
	UiData._settings = t["settings"]
	UiData._howto = t["howto"]
	UiData._hints = t["hints"]
	UiData._stances = t["stances"]
	UiData._reads = t["reads"]
	UiData._feedback = t["feedback"]
	UiData._send = t["send"]
	UiData._glyphs = t["glyphs"]


func _fonts() -> void:
	var f: Font = UiText.f()
	lines.append("Font: %s (the engine's built-in fallback; no font is bundled)" % f.get_font_name())
	var miss := ""
	for ch in "áçďéĝĥíĵķĺñöŕšţüŵýžÅÇĎÉĜĤÎĴĶĹÑÖŔŠŢÜŴÝŽ":
		if not f.has_char(ch.unicode_at(0)):
			miss += ch
	lines.append("  pseudo-locale accents: %s" % ("all drawn" if miss == "" else "MISSING " + miss))
	for name in SCRIPTS:
		var s: String = SCRIPTS[name]
		var n := 0
		var have := 0
		for ch in s:
			if ch == " ":
				continue
			n += 1
			if f.has_char(ch.unicode_at(0)):
				have += 1
		lines.append("  %-40s %3d%% of its letters (%d of %d)" % [name, int(round(100.0 * have / maxf(1.0, n))), have, n])
	lines.append("")


## One screen at every case, English then pseudo: {tag: [fits_en, fits_pseudo, note]}.
func _screens() -> void:
	lines.append("Screens: fits in English / fits in the pseudo-locale (cs is the type scale a card shrank to)")
	var vo := {"camera_zoom": 7.0, "pad_preset": "arena", "left_handed": false, "thickness": 1.0, "hitstop_scale": 0.5}
	var cfg := {"players": 1, "p1": "kb", "p2": "kb", "intros": true, "reduce_flashing": true, "shake": true, "captions": true, "guide": true}
	var results: Dictionary = {}
	for which in [0, 1]:
		_use(src if which == 0 else pseudo)
		for cs in CASES:
			var sz: Vector2 = cs[0]
			var dpv: float = cs[1]
			for touch in [false, true]:
				var lay := UiLayout.new()
				lay.dp = dpv
				lay.touch_ui = touch
				lay.compute(sz, false)
				var vt := "%dx%d dp %.1f%s" % [int(sz.x), int(sz.y), dpv, " touch" if touch else ""]
				_put(results, "notice (gate)", vt, which, UiNotice.plan(sz, lay.s, dpv, touch, {"focus": -1, "gate": true, "safe": lay.safe}), "can_scroll")
				for players in [1, 2]:
					cfg["players"] = players
					_put(results, "start menu, %d player%s" % [players, "s" if players > 1 else ""], vt, which, UiMenu.plan(sz, lay.s, dpv, touch, {"focus": 0, "cfg": cfg, "mid_match": false, "safe": lay.safe, "not_now": true}), "")
				for confirm in [false, true]:
					_put(results, "pause menu%s" % (", confirm" if confirm else ""), vt, which, UiPause.plan(sz, lay.s, dpv, touch, {"focus": 0, "confirm": confirm}), "")
				var sp: Dictionary = UiSettings.plan(sz, lay.s, dpv, touch, {"focus": 1, "scroll": 0.0}, vo)
				# The foot shows the focused row's help in help_lines lines and ends a longer one in "..." (UiSettings.draw).
				var cut := 0
				for rec in sp["rows"]:
					if UiText.wrap(str(rec.get("help", "")), int(sp["fs_small"]), (sp["footer"] as Rect2).size.x).size() > int(sp["help_lines"]):
						cut += 1
						if which == 0 and sz == Vector2(1920, 1080) and not touch:
							cut_desktop.append(str(rec.get("key", rec.get("label", "?"))))
				sp["cut"] = cut
				_put(results, "settings", vt, which, sp, "cut")
				var npages: int = (UiData.howto().get("pages", []) as Array).size()
				for pg in range(npages):
					_put(results, "how to play, page %d" % (pg + 1), vt, which, UiHowto.plan(sz, lay.s, dpv, touch, pg, "xbox", 0), "cs")
				for st in [UiFeedback.STATE_WRITE, UiFeedback.STATE_COPIED, UiFeedback.STATE_REVIEW]:
					_put(results, "feedback, %s" % st, vt, which, UiFeedback.plan(sz, lay.s, dpv, touch, st), "")
				if not touch:
					for ph in UiLoading.PHASES:
						_put(results, "loading, %s" % ph, vt, which, UiLoading.plan(sz, lay.s, 1.0, lay.safe, {"phase": ph, "progress": 0.5}), "")
				if sz.y > sz.x:
					_put(results, "turn your phone", vt, which, UiTurn.plan(sz, lay.s, dpv), "")
				var rect: Rect2 = lay.prompts[1]
				if rect.size.y > 0.0:
					for kind in ["prompt", "joined", "left"]:
						for kbd in [false, true]:
							var p: Dictionary = UiJoin.plan(rect, lay.s, kind, kbd)
							var ok: bool = bool(p.get("fits", false)) and UiText.width(str(p.get("text", "")), int(p.get("fs", 14))) <= rect.size.x
							_put(results, "join line, %s%s" % [kind, " (keyboard)" if kbd else ""], vt, which, {"fits": ok}, "")
	var screens: Array = results.keys()
	screens.sort()
	for scr in screens:
		var per: Dictionary = results[scr]
		var bad_en: PackedStringArray = []
		var bad_ps: PackedStringArray = []
		var notes: PackedStringArray = []
		for vt in per:
			var r: Array = per[vt]
			if not r[0]:
				bad_en.append(vt)
			if not r[1]:
				bad_ps.append(vt)
				if r[0]:
					newly_bad += 1
			if str(r[2]) != "" or str(r[3]) != "":
				notes.append("%s: English %s, pseudo %s" % [vt, str(r[2]) if str(r[2]) != "" else "-", str(r[3]) if str(r[3]) != "" else "-"])
		var verdict: String = "fits everywhere" if bad_ps.is_empty() else "OVERFLOWS at %s" % ", ".join(bad_ps)
		if not bad_en.is_empty():
			verdict += "  (English already fails at %s)" % ", ".join(bad_en)
		lines.append("  %-34s %s" % [scr, verdict])
		for nt in notes:
			lines.append("      %s" % nt)
	lines.append("  Settings rows whose English help ends in ... at 1920x1080: %s" % ", ".join(cut_desktop))
	lines.append("")


func _put(results: Dictionary, screen: String, vt: String, which: int, p: Dictionary, extra: String) -> void:
	if not results.has(screen):
		results[screen] = {}
	var per: Dictionary = results[screen]
	if not per.has(vt):
		per[vt] = [true, true, "", ""]
	per[vt][which] = bool(p.get("fits", true))
	# What the screen gave up to fit, worth knowing even when it fits: a scroll, a smaller type, help cut short.
	if extra != "" and p.has(extra):
		var v = p[extra]
		var note := ""
		if extra == "can_scroll" and bool(v):
			note = "scrolls"
		elif extra == "cut" and int(v) > 0:
			note = "%d helps cut with ..." % int(v)
		elif extra == "cs" and float(v) < 0.999:
			note = "type x%.2f" % float(v)
		per[vt][2 + which] = note


## The wound card titles (UiCards: shrink to the floor, then split in two) and the banner (UiCenter: one line, no fit).
func _cards_and_banner() -> void:
	lines.append("In-match text (the widths of the real font at the size each widget uses):")
	for which in [0, 1]:
		_use(src if which == 0 else pseudo)
		var titles: PackedStringArray = []
		var T: Dictionary = UiData._terms
		for rk in T.get("region", {}):
			for sk in T.get("stage", {}):
				titles.append(UiData.fmt("card.region_stage", {"region": T["region"][rk], "stage": T["stage"][sk]}))
			for sk in T.get("internal_stage", {}):
				titles.append(UiData.fmt("card.internal", {"region": T["region"][rk], "stage": T["internal_stage"][sk]}))
		for ck in T.get("card", {}):
			if ck in ["region_stage", "internal"]:
				continue
			titles.append(UiData.fmt("card." + ck, {"n": 9, "station": str(T.get("station", {}).get("chest", "")), "stage": str(T.get("chip_stage", {}).get("2", ""))}))
		var banners: PackedStringArray = []
		for v in (T.get("banner_rename", {}) as Dictionary).values():
			banners.append(str(v))
		banners.append(UiData.fmt("state.chain", {"n": 5}))
		var label: String = "English" if which == 0 else "pseudo"
		var card_bad: Dictionary = {}
		var banner_bad: Dictionary = {}
		for cs in CASES:
			var sz: Vector2 = cs[0]
			var lay := UiLayout.new()
			lay.dp = cs[1]
			lay.compute(sz, false)
			var vt := "%dx%d dp %.1f" % [int(sz.x), int(sz.y), cs[1]]
			var s: float = lay.s
			var r := Rect2(lay.cards[0].position, Vector2(lay.cards[0].size.x, lay.card_h))
			if r.size.x > 0.0 and not lay.cards_none:
				var g: float = r.size.y - 8.0 * s
				var max_w: float = r.size.x - g - 34.0 * s
				var fl: int = int(UiLook.text_floor)
				for t in titles:
					if UiText.width(t, fl) <= max_w:
						continue
					var parts: PackedStringArray = t.split(": ", false, 1)
					var two: PackedStringArray = parts if parts.size() == 2 else UiText.wrap(t, fl, max_w)
					var ok: bool = two.size() <= 2 and float(two.size()) * (float(fl) + 2.0) <= r.size.y
					for l in two:
						ok = ok and UiText.width(l, fl) <= max_w
					if not ok:
						if not card_bad.has(t):
							card_bad[t] = []
						card_bad[t].append(vt)
			var fs: int = UiText.px(clampf(sz.x * 0.03, 30.0, 46.0) / maxf(s, 0.01), s, 22.0)
			var room: float = lay.safe.size.x
			if not lay.portrait:
				var a: Rect2 = lay.plate[0]
				var b: Rect2 = lay.plate[1]
				room = maxf(a.position.x, b.position.x) - minf(a.end.x, b.end.x)
			for bt in banners:
				if UiText.width(bt.to_upper(), fs) > room:
					if not banner_bad.has(bt):
						banner_bad[bt] = []
					banner_bad[bt].append(vt)
		lines.append("  %s: %d of %d wound card titles do not fit their card at the text floor somewhere" % [label, card_bad.size(), titles.size()])
		for t in card_bad:
			lines.append("      %s  at %s" % [t, ", ".join(PackedStringArray(card_bad[t]))])
		lines.append("  %s: %d of %d banners are wider than the room between the plates somewhere" % [label, banner_bad.size(), banners.size()])
		for t in banner_bad:
			lines.append("      %s  at %s" % [t, ", ".join(PackedStringArray(banner_bad[t]))])
	_use(src)
