// Scratch: layer cuts. window.__cut = "terrain,water,bld,bld0,trees,crowd,fighters,beams,particles,vfx" hides those layers after each step's frame, so a driver can read
// the draw calls, primitives and frame time of the scene with a layer missing. Names are PlanetView's copies' children (Terrain*, Water*, Buildings, Buildings0, Trees, Crowd).
import { readFileSync, writeFileSync } from 'node:fs';
const p = process.argv[2] + '/render/tools/flash_capture.gd';
let s = readFileSync(p, 'utf8');
const a = '\t_shown_due = true\n';
if (!s.includes(a)) throw new Error('anchor');
s = s.replace(a, '\t_apply_cut()\n' + a);
// also on every poll, so a scene paused at one tick can be drawn with layers hidden and its rendering info read (RenderingInfo is for the last drawn frame)
s = s.replace('func poll() -> void:\n', 'func poll() -> void:\n\t_apply_cut()\n\t_publish_rinfo()\n');
s += `

func _publish_rinfo() -> void:
	var rid: RID = main.get_viewport().get_viewport_rid()
	JavaScriptBridge.eval("window.__flashcap.rinfo = %s;" % JSON.stringify({"draws": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), "prims": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME), "objects": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME), "panes": main.panes.size(), "inset": main.inset != null}), true)


func _apply_cut() -> void:
	var cut: String = str(JavaScriptBridge.eval("window.__cut || ''", true))
	var parts: PackedStringArray = cut.split(",", false)
	var all_panes: Array = main.panes.duplicate()
	if main.inset != null:
		all_panes.append(main.inset)   # Camera's inset pane draws a whole second view of the world while it is up
	for pane in all_panes:
		for copy in pane.planet.get_children():
			if not (copy is Node3D):
				continue
			for c in copy.get_children():
				var n: String = String(c.name)
				if n.begins_with("Terrain"):
					c.visible = not parts.has("terrain")
				elif n.begins_with("Water"):
					c.visible = not parts.has("water")
				elif n == "Buildings":
					c.visible = not parts.has("bld")
				elif n == "Buildings0":
					c.visible = not parts.has("bld0")
				elif n == "Trees":
					c.visible = not parts.has("trees")
				elif n == "Crowd":
					c.visible = not parts.has("crowd")
		for v in pane.fighter_views:
			v.visible = v.visible and not parts.has("fighters")
		pane.beams.visible = not parts.has("beams")
		pane.particles.visible = not parts.has("particles")
		pane.vfx_layer.visible = not parts.has("vfx")
	main.ui_hud.visible = not parts.has("hud")
	main.hud.visible = not parts.has("hud")
`;
writeFileSync(p, s); console.log('layer-cut hook applied');
