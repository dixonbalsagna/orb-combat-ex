// SCRATCH HOOK (scratch export only): splits the strip's first-frame cost (the AI match's tick 238) with a page flag sx=...: it switches off one piece of the strip at a time.
//   sx=render_only     the strip's viewport renders but the strip is never shown (no compositing, no flash of the wipe)
//   sx=composite_only  the strip is shown but its viewport never renders (the compositing of an empty texture)
//   sx=nocut           the strip's world is drawn without the cutaway request (no targets)
//   sx=nearcam         the strip's world is drawn from pane 0's camera instead of the close-up one
// Compare the hitch at tick 238 (frame-bench.mjs, scene ai) with and without. Apply after hook-perf.mjs.
import { readFileSync, writeFileSync } from 'node:fs';
const p = process.argv[2] + '/render/camera/split_view.gd';
let s = readFileSync(p, 'utf8');
const r1 = '\treturn {"cam_x": p["cam_x"], "cam_y": p["cam_y"], "cam_z": p["cam_z"], "pitch": 0.0,\n\t\t"cutaway": {"request": true, "radius_px": 0.9 * float(p["size"].y), "only": -1}}';
if (!s.includes(r1)) throw new Error('anchor inset_view return');
s = s.replace(r1, `\tif not _sx_read:
\t\t_sx_read = true
\t\t_sxv = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('sx') || ''", true)) if OS.has_feature("web") else ""
\tvar cut: Dictionary = {} if _sxv == "nocut" else {"request": true, "radius_px": 0.9 * float(p["size"].y), "only": -1}
\tif _sxv == "nearcam":
\t\tvar k2: float = float(_panel_vp.size.y) / maxf(size.y, 2.0)
\t\treturn {"cam_x": fr.cam_x[0], "cam_y": fr.cam_y[0], "cam_z": float(fr.cam_z[0]) * k2, "pitch": 0.0, "cutaway": cut}
\treturn {"cam_x": p["cam_x"], "cam_y": p["cam_y"], "cam_z": p["cam_z"], "pitch": 0.0, "cutaway": cut}`);
const r2 = '\t_panel_rect.visible = true\n\t_panel_mat.set_shader_parameter("box", r.size)';
if (!s.includes(r2)) throw new Error('anchor present visible');
s = s.replace(r2, '\t_panel_rect.visible = _sxv != "render_only"\n\t_panel_mat.set_shader_parameter("box", r.size)');
const r3 = '\t_panel_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED if frozen else SubViewport.UPDATE_ALWAYS\n';
if (!s.includes(r3)) throw new Error('anchor update mode');
s = s.replace(r3, '\t_panel_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED if (frozen or _sxv == "composite_only") else SubViewport.UPDATE_ALWAYS\n');
s = s.replace('var _panel_frames: int = 0', 'var _sxv: String = ""\nvar _sx_read: bool = false\nvar _panel_frames: int = 0');
writeFileSync(p, s); console.log('strip hook applied');
