class_name UiLicences
extends RefCounted
## The third-party licences page of How to play (docs/ui/hud-spec.md section 44): Godot Engine's own licence text and copyright notice, the list of
## components built into the engine with their copyright lines, and every licence text the engine lists (MIT, OFL-1.1 for the Open Sans font, and the
## rest). The engine itself supplies them (Engine.get_license_text, get_copyright_info, get_license_info), as its licence terms ask, so the page is
## always the true text for the engine version in the build and nothing is pasted into our data. About 90,000 characters, so the page scrolls.

static var _blocks: Array = []
static var _lines_key := ""
static var _lines: Array = []


## The page's text as blocks: [[heading: bool, text: String], ...]. Built once.
static func blocks() -> Array:
	if not _blocks.is_empty():
		return _blocks
	var out: Array = []
	out.append([true, "Godot Engine"])
	out.append([false, Engine.get_license_text().strip_edges()])
	out.append([true, "Components built into Godot Engine"])
	for c in Engine.get_copyright_info():
		var parts: PackedStringArray = []
		for p in c["parts"]:
			parts.append("Copyright %s. Licence: %s." % [", ".join(PackedStringArray(p["copyright"])), str(p["license"])])
		out.append([false, "%s: %s" % [str(c["name"]), " ".join(parts)]])
	out.append([true, "Licence texts"])
	var info: Dictionary = Engine.get_license_info()
	var keys: Array = info.keys()
	keys.sort()
	for k in keys:
		out.append([true, str(k)])
		out.append([false, str(info[k]).strip_edges()])
	_blocks = out
	return out


## The whole text as one string (what a test compares with the engine's own).
static func full_text() -> String:
	var parts := PackedStringArray()
	for b in blocks():
		parts.append(str(b[1]))
	return "\n\n".join(parts)


## One block's text as paragraphs: single line breaks inside a licence's hard-wrapped lines join into one paragraph; a blank line, an indented line or a
## list marker starts a new one.
static func paragraphs(text: String) -> PackedStringArray:
	var out := PackedStringArray()
	var cur := ""
	for raw in text.split("\n"):
		var ln: String = str(raw).strip_edges(false, true)
		if ln.strip_edges() == "":
			if cur != "":
				out.append(cur)
				cur = ""
			continue
		var starts_new: bool = ln.begins_with(" ") or ln.begins_with("\t") or _bullet(ln.strip_edges())
		if cur != "" and starts_new:
			out.append(cur)
			cur = ""
		cur = ln.strip_edges() if cur == "" else cur + " " + ln.strip_edges()
	if cur != "":
		out.append(cur)
	return out


static func _bullet(ln: String) -> bool:
	if ln.begins_with("*") or ln.begins_with("- ") or ln.begins_with("o "):
		return true
	var i := 0
	while i < ln.length() and ln[i] >= "0" and ln[i] <= "9":
		i += 1
	if i > 0 and i < ln.length() and (ln[i] == "." or ln[i] == ")"):
		return true
	return ln.length() > 2 and ln[0] == "(" and (ln[2] == ")" or (ln.length() > 3 and ln[3] == ")"))


## The wrapped lines for a text width and a font size: [[kind, text], ...] with kind 0 body, 1 heading, 2 blank. Cached for the last width and size.
static func lines(max_w: float, fs: int) -> Array:
	var key := "%d|%d" % [int(max_w), fs]
	if key == _lines_key:
		return _lines
	var out: Array = []
	for b in blocks():
		var heading: bool = bool(b[0])
		if heading and not out.is_empty():
			out.append([2, ""])
		for para in paragraphs(str(b[1])):
			for ln in _wrap(para, fs, max_w):
				out.append([1 if heading else 0, ln])
			if not heading:
				out.append([2, ""])
	_lines = out
	_lines_key = key
	return out


## Greedy word wrap with each word measured once (a cache per font size: the text repeats its words thousands of times, and measuring every trial line
## was over a second on a throttled phone-class CPU). A word wider than the line is broken by letters (a web address on a phone).
static var _word_w: Dictionary = {}


static func _w(word: String, fs: int) -> float:
	var key := "%d|%s" % [fs, word]
	if not _word_w.has(key):
		_word_w[key] = UiText.width(word, fs)
	return float(_word_w[key])


static func _wrap(text: String, fs: int, max_w: float) -> PackedStringArray:
	var out := PackedStringArray()
	var space: float = _w(" ", fs)
	var line := ""
	var line_w := 0.0
	for word in text.split(" ", false):
		var ww: float = _w(word, fs)
		if ww > max_w:
			if line != "":
				out.append(line)
				line = ""
				line_w = 0.0
			var cur := ""
			var cur_w := 0.0
			for ch in word:
				var cw: float = _w(ch, fs)
				if cur != "" and cur_w + cw > max_w:
					out.append(cur)
					cur = ""
					cur_w = 0.0
				cur += ch
				cur_w += cw
			line = cur
			line_w = cur_w
			continue
		var joined: float = ww if line == "" else line_w + space + ww
		if joined <= max_w:
			line = word if line == "" else line + " " + word
			line_w = joined
		else:
			out.append(line)
			line = word
			line_w = ww
	if line != "":
		out.append(line)
	return out
