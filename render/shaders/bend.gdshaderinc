// Planet curvature: world geometry sags by bend * x^2, where x is the distance from the camera across (the camera
// sits at x = 0), weighted by depth so the fighter plane (z = 0) and everything near it stays exactly flat and only
// the world behind curves away. The weight also divides out perspective (cam_dist / (cam_dist + depth)), so every
// layer from 1,260 units back to the horizon sags the same number of pixels at the screen edge: one clean curve.
// bend and cam_dist are set every frame from the zoom and the camera height, per pane (pane_world.gd).
#ifndef BEND_GDSHADERINC
#define BEND_GDSHADERINC
uniform float bend = 0.0;
uniform float cam_dist = 3000.0;
uniform float bend_focus = 0.0;      // the depth of the camera's focus plane (Camera's dolly): the plane that stays flat. 0: the fighter plane

// The tile ground's placement (RenderTileGround; off while globe_r is 0, and then nothing below runs): the true globe, one
// function for everything drawn, with the view's frame at the camera's strip x. A point's strip place, x from the camera along the
// line and z in depth, is a direction on the planet; its height is along that direction, so a wall leans as on a planet. A world
// thing turns with the planet (globe_m, about the swing's pivot); what stands on the fighters' plane does not, and takes the lift
// that keeps it on the drawn ground.
global uniform float globe_r;
uniform float globe_sx = 0.0;             // the camera's strip x
uniform float globe_lift_on = 0.0;        // 1 once globe_off is bound (RenderMats.set_globe)
uniform mat3 globe_m = mat3(1.0);         // the planet's turn, on (along the line, up, toward the camera) at the camera
uniform float globe_world = 0.0;          // 1: planet-keyed, it turns; 0: on the plane
uniform float globe_small = 0.0;          // 1: a small world thing: gone at the near line, no rule for it
uniform int globe_near_mode = 3;          // a tower near the line: 0 the rule, 1 sink, 2 hard clip, 3 rule and sink, 4 sink and clip
uniform float globe_line = -80.0;
uniform vec3 globe_band = vec3(-150.0, -30.0, 150.0);   // RenderLook.TILE_BAND: a building comes down as its front face goes from .x to .y of depth; past .z a small thing is gone
uniform float globe_lead = 0.5;           // a near tower's roof: how far its near side leads, in its widest sides over its height (a rise of a quarter of its width across it)
uniform float globe_base = 90.0;          // ... and what's left of it, in units
uniform sampler2D globe_off : filter_nearest, repeat_enable;   // per column: drawn ground less the sim's, and the sim's

// How far a thing has come toward the near line, 0 to 1. plan: its depth in the plan; now: its depth in the view; width: the ramp.
// At rest now is plan, so this is 0 and the rule does nothing: only a swing that brings a thing nearer than its own plan moves it.
float globe_near(float plan, float now, float width) {
	float l = max(clamp(plan + width, globe_line, 150.0), plan + 1.0);
	return smoothstep(max(plan, l - width), l, now);
}

vec3 globe_dir(vec3 w) {
	float xr = w.x / globe_r;
	float zr = w.z / globe_r;
	float cz = cos(zr);
	vec3 d = vec3(cz * sin(xr), cz * cos(xr), sin(zr));
	return globe_world > 0.5 ? globe_m * d : d;
}

float globe_view_z(vec3 w) {
	return globe_dir(w).z * globe_r;
}

vec4 globe_place(vec3 w) {
	float y = w.y;
	if (globe_lift_on > 0.5 && globe_world < 0.5 && abs(w.z) < 600.0) {
		float col = floor((globe_sx + w.x) / 32.0);
		vec2 o = texelFetch(globe_off, ivec2(int(col - 1024.0 * floor(col / 1024.0)), 0), 0).rg;
		y += o.r * (1.0 - smoothstep(75.0, 150.0, y - o.g)) * (1.0 - smoothstep(300.0, 600.0, abs(w.z)));
	}
	vec3 d = globe_dir(w);
	if (d.y < 0.05 || (globe_small > 0.5 && (globe_near(w.z, d.z * globe_r, 1.0) > 0.5 || d.z * globe_r > globe_band.z))) {
		y -= 1.0e6;   // past the horizon of any height in the game; or a small thing come round to the near line
	}
	float rr = globe_r + y;
	return vec4(rr * d.x, rr * d.y - globe_r, rr * d.z, 1.0);
}

// How far the globe lowers a point: for what keeps its own shape (a fighter's part, a beam's ring, ortho.gdshaderinc).
float globe_sag(vec3 w) {
	return globe_r * (1.0 - cos(w.x / globe_r) * cos(w.z / globe_r));
}

// A tower near the line: where its height goes as it comes round. a: its anchor, v: this vertex, foot and top: its own, wide: its widest side.
float globe_tower(vec3 a, vec3 v, float foot, float top, float wide, float half_d) {
	// The band between the camera and the fight, at rest too: a building whose front face reaches it comes down, wherever its plan has it. A place laid
	// anywhere on the planet has a plan that says nothing about where the fight is now. By its anchor and its depth, so it doesn't lean at rest.
	float rest = smoothstep(globe_band.x, globe_band.y, globe_view_z(a) + half_d);
	float sa = max(globe_near(a.z, globe_view_z(a), 300.0), rest);
	float sv = max(globe_near(v.z, globe_view_z(v), 500.0), rest);
	float tall = v.y - foot;
	if (globe_near_mode == 1) {
		return sa >= 1.0 ? foot - 200.0 : foot + tall * (1.0 - sa);
	}
	if (globe_near_mode == 3) {
		// Orb's pick: the whole building goes down, its near side leading. How far the near side leads is bounded by the building's width,
		// so a tall tower's roof doesn't turn into a wedge or a spike; and its base stays, a floor or two high.
		// Its base stays only behind the fight: past .y its front face stands between the lens and the fight, where a base would be a slab across the frame, so it's gone.
		float reach = globe_view_z(a) + half_d;
		if (reach > globe_band.y) {
			return v.y - 1.0e6;
		}
		float total = max(top - foot, 1.0);
		float lead = 0.5 * clamp(sv - sa, -globe_lead * wide / total, globe_lead * wide / total);
		float kept = min(globe_base, total) * (1.0 - smoothstep(globe_band.x, globe_band.y, reach));
		return foot + tall * (1.0 - min(sa + lead, 1.0 - kept / total));
	}
	if (globe_near_mode == 4) {
		return foot + tall * (1.0 - 0.67 * globe_near(a.z, globe_view_z(a), 400.0));
	}
	if (globe_near_mode == 0) {
		return sv >= 1.0 ? foot - 60.0 : foot + tall * (1.0 - sv);
	}
	return v.y;
}

vec4 bent_world(mat4 model, vec3 v) {
	vec4 w = model * vec4(v, 1.0);
	if (globe_r > 0.0) {
		return globe_place(w.xyz);
	}
	float back = max(bend_focus - w.z, 0.0);
	float k = clamp((back - 60.0) / 1200.0, 0.0, 1.0) * cam_dist / (cam_dist + back);
	w.y -= bend * w.x * w.x * k;
	return w;
}

vec4 bent_clip(mat4 model, mat4 view, mat4 proj, vec3 v) {
	return proj * (view * bent_world(model, v));
}
#endif
