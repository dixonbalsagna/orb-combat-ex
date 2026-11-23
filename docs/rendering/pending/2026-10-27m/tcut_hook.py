# SCRATCH (Rendering): the terrain fragment's parts behind compile-time cuts, one shader file a cut, chosen by the
# page's ?tcut=<name> (planet_view's terrain material). For timing the ground's fragment on the Radeon, part by part.
#   python tcut_hook.py <tree>   (main f8b8af7f)
import sys
root = sys.argv[1]
p = root + '/render/shaders/terrain.gdshaderinc'
s = open(p, encoding='utf-8').read()


def rep(a, b):
    global s
    assert s.count(a) == 1, (a[:80], s.count(a))
    s = s.replace(a, b)


# the border zone: one biome, no zone
rep("""	int v_bb = int(gf(ci, 22) + 0.5);
	float jb = gf(ci, 23);
	float du = cx - jb;
	du -= float(nc) * floor(du / float(nc) + 0.5);
	float zt = (jb < -1.0e8 || v_ba == v_bb) ? 0.0 : clamp(0.5 + du * col_w / biome_zone, 0.0, 1.0);
	float zf = zt <= 0.0 ? 0.0 : (zt >= 1.0 ? 1.0 : (floor(zt * 5.0) + 0.5) / 5.0);
""", """#ifdef CUT_ZONE
	int v_bb = v_ba;
	float zf = 0.0;
#else
	int v_bb = int(gf(ci, 22) + 0.5);
	float jb = gf(ci, 23);
	float du = cx - jb;
	du -= float(nc) * floor(du / float(nc) + 0.5);
	float zt = (jb < -1.0e8 || v_ba == v_bb) ? 0.0 : clamp(0.5 + du * col_w / biome_zone, 0.0, 1.0);
	float zf = zt <= 0.0 ? 0.0 : (zt >= 1.0 ? 1.0 : (floor(zt * 5.0) + 0.5) / 5.0);
#endif
""")
# the rock bands
rep("""	float above = rk.g * 10000.0;
	float g0 = rock_slope.x * (above > 0.0 ? mix(1.0, rock_high, clamp((v_h - above) / above, 0.0, 1.0)) : 1.0);
	float rr = clamp((length(v_grad) - g0) / max(rock_slope.y - g0, 0.01), 0.0, 1.0);
	float rs = rr <= 0.0 ? 0.0 : (rr >= 1.0 ? 1.0 : (floor(rr * 5.0) + 0.5) / 5.0);
	vec3 c = mix(mix(biome_tone(v_ba, tone), biome_tone(v_bb, tone), zf), mix(biome_tone(v_ba, 3 + tone), biome_tone(v_bb, 3 + tone), zf), rs);
""", """#ifdef CUT_ROCK
	float rs = 0.0;
	vec3 c = mix(biome_tone(v_ba, tone), biome_tone(v_bb, tone), zf);
#else
	float above = rk.g * 10000.0;
	float g0 = rock_slope.x * (above > 0.0 ? mix(1.0, rock_high, clamp((v_h - above) / above, 0.0, 1.0)) : 1.0);
	float rr = clamp((length(v_grad) - g0) / max(rock_slope.y - g0, 0.01), 0.0, 1.0);
	float rs = rr <= 0.0 ? 0.0 : (rr >= 1.0 ? 1.0 : (floor(rr * 5.0) + 0.5) / 5.0);
	vec3 c = mix(mix(biome_tone(v_ba, tone), biome_tone(v_bb, tone), zf), mix(biome_tone(v_ba, 3 + tone), biome_tone(v_bb, 3 + tone), zf), rs);
#endif
""")
# strata
rep("""	if (rs > 0.5 && rk.r > 0.5) {
		// strata lines""", """#ifndef CUT_STRATA
	if (rs > 0.5 && rk.r > 0.5) {
		// strata lines""")
rep("""		c = mix(c, c * 0.62, ln);
	}
""", """		c = mix(c, c * 0.62, ln);
	}
#endif
""")
# the far land's ladder
rep("""	if (ladder_on && v_s >= ladder_from) {""", """#ifndef CUT_LADDER
	if (ladder_on && v_s >= ladder_from) {""")
rep("""		c = mix(c, flat_shade(v_col, NORMAL, 0.55) * mix(1.2, 0.95, v_back), v_s);   // the far land: its own colour, shaded as before
	}
""", """		c = mix(c, flat_shade(v_col, NORMAL, 0.55) * mix(1.2, 0.95, v_back), v_s);   // the far land: its own colour, shaded as before
	}
#endif
""")
# the streets
rep("""		c = mix(sea_floor.rgb * tk, c, v_s);
	} else if (v_street > 0.001) {""", """		c = mix(sea_floor.rgb * tk, c, v_s);
	}
#ifndef CUT_STREET
	else if (v_street > 0.001) {""")
rep("""		c = mix(c, st.rgb * tk, st.a * v_street);
	}
""", """		c = mix(c, st.rgb * tk, st.a * v_street);
	}
#endif
""")
# craters and rims
rep("""	if (v_dent < -dent_min) {""", """#ifndef CUT_DENT
	if (v_dent < -dent_min) {""")
rep("""		c = mix(c, ejecta.rgb * tk, (v_dent > 2.5 * dent_min ? 0.5 : 0.25) * (1.0 - v_new));   // rubble on the rim, in two hard steps
	}
""", """		c = mix(c, ejecta.rgb * tk, (v_dent > 2.5 * dent_min ? 0.5 : 0.25) * (1.0 - v_new));   // rubble on the rim, in two hard steps
	}
#endif
""")
# cracks and rubble
rep("""	if (v_crack > 0.01) {""", """#ifndef CUT_CRACK
	if (v_crack > 0.01) {""")
rep("""		c = mix(c, rubble.rgb * (0.8 + 0.4 * n), clamp(v_rubble / rubble_tint_h, 0.0, 1.0) * 0.9);
	}
""", """		c = mix(c, rubble.rgb * (0.8 + 0.4 * n), clamp(v_rubble / rubble_tint_h, 0.0, 1.0) * 0.9);
	}
#endif
""")
# the scar
rep("""	if (sc > scar_band.y) {""", """#ifndef CUT_SCAR
	if (sc > scar_band.y) {""")
rep("""		c = mix(biome_tone(v_ba, sc > scar_band.y + rim ? 9 : 10), biome_tone(v_bb, sc > scar_band.y + rim ? 9 : 10), zf);
	}
""", """		c = mix(biome_tone(v_ba, sc > scar_band.y + rim ? 9 : 10), biome_tone(v_bb, sc > scar_band.y + rim ? 9 : 10), zf);
	}
#endif
""")
# the lane cue and the pair's mark
rep("""	vec4 cue = lane_cue_at(v_px, fwidth(v_px.y));
	c = mix(c, cue.rgb, cue.a);
	c = pair_mark_on(c, v_px, fwidth(v_px.y));
""", """#ifndef CUT_CUES
	vec4 cue = lane_cue_at(v_px, fwidth(v_px.y));
	c = mix(c, cue.rgb, cue.a);
	c = pair_mark_on(c, v_px, fwidth(v_px.y));
#endif
""")
# the heat's glow
rep("""	float hh = clamp(v_heat, 0.0, 1.6);""", """#ifndef CUT_HEAT
	float hh = clamp(v_heat, 0.0, 1.6);""")
rep("""	c = mix(c, glow, smoothstep(0.2, 1.0, hh) * 0.85 * heat_gain * opened) + glow * max(0.0, hh - 1.0) * 0.6 * heat_gain * heat_gain * opened;
""", """	c = mix(c, glow, smoothstep(0.2, 1.0, hh) * 0.85 * heat_gain * opened) + glow * max(0.0, hh - 1.0) * 0.6 * heat_gain * heat_gain * opened;
#endif
""")
# the haze
rep("""	ALBEDO = lk >= 0 ? haze_step(""", """#ifdef CUT_HAZE
	ALBEDO = c;
#else
	ALBEDO = lk >= 0 ? haze_step(""")
i = s.index('#else\n\tALBEDO = lk >= 0 ? haze_step(')
j = s.index('\n', s.index('haze_ground(c, v_view, -v_wz, fog_far);', i))
s = s[:j + 1] + '#endif\n' + s[j + 1:]
open(p, 'w', encoding='utf-8', newline='\n').write(s)

CUTS = {
    'none': [], 'zone': ['ZONE'], 'rock': ['ROCK'], 'strata': ['STRATA'], 'ladder': ['LADDER'], 'street': ['STREET'],
    'dent': ['DENT'], 'crack': ['CRACK'], 'scar': ['SCAR'], 'cues': ['CUES'], 'heat': ['HEAT'], 'haze': ['HAZE'],
    'all': ['ZONE', 'ROCK', 'STRATA', 'LADDER', 'STREET', 'DENT', 'CRACK', 'SCAR', 'CUES', 'HEAT', 'HAZE'],
}
for name, defs in CUTS.items():
    body = '// SCRATCH: the terrain with cuts ' + ','.join(defs) + '\nshader_type spatial;\nrender_mode unshaded, cull_disabled;\n\n'
    body += ''.join('#define CUT_%s\n' % d for d in defs)
    body += '#include "res://render/shaders/terrain.gdshaderinc"\n'
    open(root + '/render/shaders/tcut_%s.gdshader' % name, 'w', encoding='utf-8', newline='\n').write(body)

q = root + '/render/core/planet_view.gd'
t = open(q, encoding='utf-8').read()
a = "\t_terrain_mat.shader = TERRAIN_SHADER\n"
assert t.count(a) == 1
t = t.replace(a, """	_terrain_mat.shader = TERRAIN_SHADER
	if OS.has_feature("web"):   # SCRATCH: ?tcut=<name> swaps in a cut terrain (tcut_hook.py)
		var tq: String = str(JavaScriptBridge.eval("(new URLSearchParams(location.search)).get('tcut') || ''", true))
		if tq != "" and ResourceLoader.exists("res://render/shaders/tcut_%s.gdshader" % tq):
			_terrain_mat.shader = load("res://render/shaders/tcut_%s.gdshader" % tq)
			JavaScriptBridge.eval("window.__tcut = '%s';" % tq, true)
""")
open(q, 'w', encoding='utf-8', newline='\n').write(t)
print('tcut hook ok:', ', '.join(CUTS))
