// Scratch (Performance and Platform, 2026-11-01): layer cuts by NODE NAME for the stack with the tile ground (hook-layers.mjs knew only the older layers). window.__cut = "Name1,Name2" hides, in every pane's planet
// (three levels down) and under the main node (one level), each node whose name BEGINS with one of the names; clearing __cut shows them again. window.__dump = 1 makes the hook publish the node tree it can cut
// (window.__names: "path|class|visible") so a driver can read what there is to cut. It also publishes the engine's draw calls and primitives of the last frame (window.__flashcap.rinfo), as hook-layers.mjs did.
// Reads and hides nodes in a scratch export only; the sim is untouched.
import { readFileSync, writeFileSync } from 'node:fs';
const p = process.argv[2] + '/render/tools/flash_capture.gd';
let s = readFileSync(p, 'utf8');
const a = '\t_shown_due = true\n';
if (!s.includes(a)) throw new Error('anchor: _shown_due');
s = s.replace(a, '\t_apply_cut()\n' + a);
if (!s.includes('func poll() -> void:\n')) throw new Error('anchor: poll');
s = s.replace('func poll() -> void:\n', 'func poll() -> void:\n\t_apply_cut()\n\t_publish_rinfo()\n');
s += `

var _cut_hidden: Dictionary = {}


func _publish_rinfo() -> void:
	JavaScriptBridge.eval("window.__flashcap.rinfo = %s;" % JSON.stringify({"draws": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), "prims": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME), "fx": [snappedf(main.host.S.fighters[0].x, 1.0), snappedf(main.host.S.fighters[1].x, 1.0)], "fy": [snappedf(main.host.S.fighters[0].y, 1.0), snappedf(main.host.S.fighters[1].y, 1.0)], "tick": main.host.S.tick}), true)


func _walk_names(n: Node, depth: int, path: String, out: Array) -> void:
	out.append("%s|%s|%s" % [path, n.get_class(), str(n.get("visible")) if n.get("visible") != null else "-"])
	if depth <= 0:
		return
	for c in n.get_children():
		_walk_names(c, depth - 1, path + "/" + String(c.name), out)


func _cut_walk(n: Node, depth: int, parts: PackedStringArray) -> void:
	var nm: String = String(n.name)
	var hit := false
	for q in parts:
		if q != "" and nm.begins_with(q):
			hit = true
	if hit and n.get("visible") != null:
		n.set("visible", false)
		_cut_hidden[n.get_instance_id()] = true
	elif _cut_hidden.has(n.get_instance_id()) and n.get("visible") != null:
		n.set("visible", true)
		_cut_hidden.erase(n.get_instance_id())
	if depth <= 0:
		return
	for c in n.get_children():
		_cut_walk(c, depth - 1, parts)


## a token 'p1:Copy' applies to pane 1 only; 'p1:root' hides pane 1's whole planet node; a token with no 'pN:' applies to every pane
func _parts_for(parts: PackedStringArray, idx: int) -> PackedStringArray:
	var r := PackedStringArray()
	for q in parts:
		if q.length() > 3 and q[0] == "p" and q[2] == ":":
			if int(q[1]) == idx:
				r.append(q.substr(3))
		else:
			r.append(q)
	return r


func _apply_cut() -> void:
	var cut: String = str(JavaScriptBridge.eval("window.__cut || ''", true))
	var parts: PackedStringArray = cut.split(",", false)
	var dump: bool = str(JavaScriptBridge.eval("window.__dump ? '1' : ''", true)) == "1"
	var out: Array = []
	var i: int = 0
	var panes: Array = main.panes.duplicate()
	if main.get("inset") != null:
		panes.append(main.inset)
	for pane in panes:
		var pl = pane.get("planet")
		if pl != null:
			if dump:
				_walk_names(pl, 3, "pane%d.planet" % i, out)
			var mine := _parts_for(parts, i)
			if mine.has("root"):
				pl.visible = false
				_cut_hidden[pl.get_instance_id()] = true
			elif _cut_hidden.has(pl.get_instance_id()):
				pl.visible = true
				_cut_hidden.erase(pl.get_instance_id())
			_cut_walk(pl, 3, mine)
		for k in ["beams", "particles", "vfx_layer"]:
			var nd = pane.get(k)
			if nd != null and nd is Node:
				var nm: String = String(nd.name)
				var hit := false
				for q in parts:
					if q == k or (q != "" and nm.begins_with(q)):
						hit = true
				nd.set("visible", not hit)
				if dump:
					out.append("pane%d.%s|%s|%s" % [i, k, nd.get_class(), str(nd.get("visible"))])
		var fv = pane.get("fighter_views")
		if fv != null:
			for v in fv:
				if v is Node and v.get("visible") != null:
					if parts.has("fighters"):
						v.set("visible", false)
		i += 1
	for c in main.get_children():
		if dump:
			out.append("main/%s|%s|%s" % [String(c.name), c.get_class(), str(c.get("visible")) if c.get("visible") != null else "-"])
		_cut_walk(c, 0, parts)
	if main.get("ui_hud") != null and main.get("hud") != null:
		main.ui_hud.visible = not parts.has("hud")
		main.hud.visible = not parts.has("hud")
	if dump:
		JavaScriptBridge.eval("window.__names = %s; window.__dump = 0;" % JSON.stringify(out), true)
`;
writeFileSync(p, s); console.log('layer-cut hook v2 applied');
