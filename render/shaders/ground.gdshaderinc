// The ground band's height field, shared by the terrain and water shaders. Data layout and the reasoning are in
// render/core/ground_field.gd (whose offset_at() is the CPU twin of ground_offset() below). The crater profile is
// WorldCrater.profile from sim/world/crater.gd. Every size is a uniform set from the sim's constants (WorldCrater)
// or RenderLook by planet_view.gd, so nothing here assumes today's world scale.
uniform sampler2D heights : filter_nearest, repeat_disable;   // RF: 21 data rows of NC, each as rpl texture rows of tw
uniform sampler2D craters : filter_nearest, repeat_disable;   // RGBAF, 400 x 2
uniform int nc = 1200;
uniform int tw = 1200;
uniform int rpl = 1;
uniform float far_scale = 1.0;       // WS: the far relief's depth wavelengths grow with the world
uniform float sea_base = -30.0;      // WorldWater.RESERVOIR_BASE: base ground below this is the sea
uniform float wet_min = 0.5;         // WorldWater.MIN_DEPTH: water shallower than this counts as dry
uniform float dent_min = 6.0;        // a dent deeper than this colours as a crater floor (6 x WS)
uniform float calm_ease = 0.0;       // 1 under reduced flashing: a new crater's colours spread in (crater_new); 0: at once, as ever
uniform float crater_now = 0.0;      // the match time (SimState.T), for a crater's age; set only while calm_ease is on
uniform float crater_calm_s = 1.5;   // RenderLook.CRATER_CALM_S
uniform float col_w = 8.0;
uniform float world_w = 9600.0;
uniform float rim_in = 0.3;          // WorldCrater.RIM_IN
uniform float rim_out = 1.0;         // WorldCrater.RIM_OUT
uniform float groove_w0 = 30.0;      // WorldCrater.SCORCH_HW0 and SCORCH_HW_P: a groove's half width from P
uniform float groove_wp = 22.0;
uniform float groove_i0 = 0.35;      // WorldCrater.SCORCH_INT0 and SCORCH_INT_P: burn intensity from P
uniform float groove_ip = 0.15;
uniform float groove_pmin = 0.5;     // the beam-power range
uniform float groove_pmax = 4.5;
uniform float spread_w = 60.0;       // RenderLook.GROUND_SPREAD
uniform float furrow_wr = 0.3;       // RenderLook.FURROW_W_R and FURROW_W_MIN
uniform float furrow_wmin = 20.0;
uniform float z_band_back = -520.0;  // RenderLook: rows behind this are the far terrain ...
uniform float far_blend = 900.0;     // ... which blends in from the band's heights over this depth
uniform float rubble_edge = 240.0;   // RenderLook.RUBBLE_EDGE: a heap eases off over this depth past its range
uniform float shore_flood = 24.0;    // RenderLook.SHORE_FLOOD: dry land this shallow under the water beside it is drawn flooded
uniform float meander_amp = 600.0;   // RenderLook.MEANDER: how far (in x) the far land's biomes wander with depth
uniform vec4 biome_colors[7] : source_color;   // RenderLook.BIOME in ground_field.gd's BIOME_ORDER
uniform vec3 fore_cam = vec3(0.0, 0.0, 3000.0);  // the camera's world position, every frame (planet_view.gd)
uniform float fore_drop = 0.03;                  // RenderLook.FORE_DROP
uniform float fore_span = 2.0;                   // RenderLook.FORE_SPAN: the fighter plane's profile the rule reads is its lowest within this many columns either side

float gf(int i, int row) {
	return texelFetch(heights, ivec2(i % tw, row * rpl + i / tw), 0).r;
}

// (height, d height / du) of WorldCrater.profile.
vec2 crater_profile(float u, float d, float hr) {
	if (u < 1.0) {
		float t = 1.0 - u * u;
		vec2 h = vec2(-d * t * t, 4.0 * d * u * t);
		float lo = 1.0 - rim_in;
		if (u > lo) {
			float a = (u - lo) / rim_in;
			h += vec2(hr * a * a * (3.0 - 2.0 * a), hr * 6.0 * a * (1.0 - a) / rim_in);
		}
		return h;
	} else if (u < 1.0 + rim_out) {
		float b = (u - 1.0) / rim_out;
		return vec2(hr * (1.0 - b * b * (3.0 - 2.0 * b)), -hr * 6.0 * b * (1.0 - b) / rim_out);
	}
	return vec2(0.0);
}

// (height, d/dx, d/dz) of a glancing impact's furrow.
vec3 furrow(float dx, float z, float r, float skid, float sd) {
	if (sd <= 0.0 || skid == 0.0 || dx * skid < 0.0) {
		return vec3(0.0);
	}
	float L = abs(skid);
	float q = 1.0 - abs(dx) / L;
	if (q <= 0.0) {
		return vec3(0.0);
	}
	float wf = max(furrow_wmin, furrow_wr * r);
	float t = 1.0 - z * z / (wf * wf);
	if (t <= 0.0) {
		return vec3(0.0);
	}
	return vec3(-sd * q * q * t * t, 2.0 * sd * q * t * t * sign(dx) / L, 4.0 * sd * q * q * t * z / (wf * wf));
}

// ground_field.gd groove_half(): a slide trench's own half width, else a beam groove's (from its burn), else spread_w.
float groove_half_at(int i) {
	float s = gf(i, 3);
	float tr = gf(i, 16);
	float w = s > 0.01 ? groove_w0 + groove_wp * clamp((s - groove_i0) / groove_ip, groove_pmin, groove_pmax) : 0.0;
	if (tr > 0.0) {
		return max(w, tr);
	}
	return w > 0.0 ? w : spread_w;
}

// A heap's share in depth and its slope: 1 on [lo, hi], easing to 0 over rubble_edge beyond (ground_field.gd heap()).
vec2 heap_at(float z, float lo, float hi) {
	float out_d = max(lo - z, z - hi);
	if (out_d <= 0.0) {
		return vec2(1.0, 0.0);
	}
	float u = clamp(out_d / rubble_edge, 0.0, 1.0);
	float du = u < 1.0 ? 6.0 * u * (1.0 - u) / rubble_edge : 0.0;
	return vec2(1.0 - u * u * (3.0 - 2.0 * u), z > hi ? -du : du);
}

// The heap's height at column i, depth z (for the rubble tint).
float rubble_at(int i, float z) {
	float r = gf(i, 17);
	return r > 0.0 ? r * heap_at(z, gf(i, 18), gf(i, 19)).x : 0.0;
}

// (height offset added to base, d/dx, d/dz) at column i, world x xw, depth z; the height is not used on the
// fighter-plane row, which reads the sim's deform directly. The gradient gives the terrain smooth normals.
vec3 ground_offset3(int i, float xw, float z) {
	vec3 s = vec3(0.0);
	for (int k = 0; k < 6; k++) {
		float fi = gf(i, 6 + k);
		if (fi < 0.0) {
			break;
		}
		int ci = int(fi + 0.5);
		vec4 a = texelFetch(craters, ivec2(ci, 0), 0);
		vec4 b = texelFetch(craters, ivec2(ci, 1), 0);
		float dx = xw - a.x;
		dx -= world_w * round(dx / world_w);
		float rho = sqrt(dx * dx + z * z);
		vec2 p = crater_profile(rho / a.y, a.z, a.w);
		float k2 = rho > 0.0001 ? p.y / (a.y * rho) : 0.0;
		s += vec3(p.x, k2 * dx, k2 * z) + furrow(dx, z, a.y, b.x, b.y);
	}
	// The residual less the heap, spread across the band; the heap as its own plateau in depth (ground_field.gd).
	int il = (i + nc - 1) % nc;
	int ir = (i + 1) % nc;
	float r = gf(i, 17);
	float w = groove_half_at(i);
	float t = 1.0 - z * z / (w * w);
	if (t > 0.0) {
		float gl = gf(il, 2) - gf(il, 17);
		float gr = gf(ir, 2) - gf(ir, 17);
		float g = gf(i, 2) - r;
		s += vec3(g * t * t, (gr - gl) / (2.0 * col_w) * t * t, -4.0 * g * t * z / (w * w));
	}
	if (r > 0.0) {
		vec2 h = heap_at(z, gf(i, 18), gf(i, 19));
		s += vec3(r * h.x, (gf(ir, 17) - gf(il, 17)) / (2.0 * col_w) * h.x, r * h.y);
	}
	return s;
}


float ground_offset(int i, float xw, float z) {
	return ground_offset3(i, xw, z).x;
}

// Under reduced flashing: how much of its own colour the ground at column i, world x xw, depth z still keeps under a
// crater dug moments ago (1: all of it; 0: none, the crater's colours as ever). A crater's colours spread from its
// centre to the edge of its apron over crater_calm_s of match time (the record's time is the sim's). Ground that any
// crater has already coloured is not given back: the least of the craters over a point decides.
float crater_new(int i, float xw, float z) {
	float keep = 1.0;
	bool any = false;
	for (int k = 0; k < 6; k++) {
		float fi = gf(i, 6 + k);
		if (fi < 0.0) {
			break;
		}
		int ci = int(fi + 0.5);
		vec4 a = texelFetch(craters, ivec2(ci, 0), 0);
		vec4 b = texelFetch(craters, ivec2(ci, 1), 0);
		float dx = xw - a.x;
		dx -= world_w * round(dx / world_w);
		float rho = sqrt(dx * dx + z * z) / max(a.y * (1.0 + rim_out) + abs(b.x), 1.0);   // 1 at the edge of its apron (and its furrow's tail)
		if (rho >= 1.15) {
			continue;
		}
		float u = (crater_now - b.w) / crater_calm_s;
		float kk = 0.0;   // an older crater: its colours are all there
		if (u >= 0.0 && u < 1.0) {
			kk = smoothstep(u - 0.08, u + 0.08, rho);
			any = true;
		}
		keep = min(keep, mix(kk, 1.0, smoothstep(1.0, 1.15, rho)));
	}
	return any ? keep : 0.0;
}

// Far relief noise (n, dn/dx, dn/dz), n in about [-1, 1]: whole harmonics of the planet's circumference along x, so it
// wraps with the planet, and free along the depth.
vec3 far_noise3(float x, float z) {
	float t = 6.2831853 / world_w;
	vec3 n = vec3(0.0);
	vec4 k[3] = vec4[3](vec4(5.0, 0.00061 / far_scale, 0.3, 0.45), vec4(17.0, -0.0013 / far_scale, 1.7, 0.3), vec4(43.0, 0.0029 / far_scale, 4.1, 0.25));
	for (int j = 0; j < 3; j++) {
		float fx = k[j].x * t;
		float p = fx * x + k[j].y * z + k[j].z;
		float c = cos(p) * k[j].w;
		n += vec3(sin(p) * k[j].w, c * fx, c * k[j].y);
	}
	return n;
}

// Behind the crater rows, a far point at world x reads the terrain column of a shifted x, the shift wandering smoothly
// with depth (and with x, in whole harmonics of the planet so it wraps), weighted by the far blend: coastlines,
// ranges and forests meander into the distance instead of running straight back, and the fighter plane is untouched.
float far_x(float xw, float z, float s) {
	float t = 6.2831853 / world_w;
	float m = 0.6 * sin(3.0 * t * xw + 0.00047 / far_scale * z + 0.4) + 0.4 * sin(8.0 * t * xw - 0.00083 / far_scale * z + 2.2);
	float xs = xw + meander_amp * m * s * s;
	return xs - world_w * floor(xs / world_w);
}

// A far row's value at the shifted x, linear between columns so the meander never steps a coast into a cliff.
float gfx(float xs, int row) {
	float c = xs / col_w;
	int i = int(c) % nc;
	return mix(gf(i, row), gf((i + 1) % nc, row), fract(c));
}

// The biome at the shifted x (nearest column).
float far_biome(float xs) {
	return gf(int(xs / col_w + 0.5) % nc, 14);
}

vec3 biome_rgb(float xs) {
	return biome_colors[int(far_biome(xs) + 0.5)].rgb;
}

// Base-terrain slope at column i.
float base_slope(int i) {
	return (gf((i + 1) % nc, 0) - gf((i + nc - 1) % nc, 0)) / (2.0 * col_w);
}

// The far terrain (h, dh/dx, dh/dz) read at the shifted x (far_x): that place's own base height (scaled per biome)
// with its biome's relief (rows 12 and 13, smoothed across biome borders), so the land far away is the same land as
// near. The slope ignores the meander's own variation, which is gentle.
vec3 far_height3(float xs, float xw, float z) {
	float amp = gfx(xs, 12);
	float mul = gfx(xs, 13);
	vec3 n = far_noise3(xw, z);
	return vec3(gfx(xs, 0) * mul + amp * n.x, base_slope(int(xs / col_w) % nc) * mul + amp * n.y, amp * n.z);
}

// 0 in the crater rows, rising smoothly to 1 at far_blend beyond them, behind the fighter plane or in front of it.
float far_weight(float z) {
	float s = clamp((abs(z) + z_band_back) / far_blend, 0.0, 1.0);
	return s * s * (3.0 - 2.0 * s);
}

// The fighter-plane row at column i: its ground, and its top (the standing water over the ground, if any).
float fp_ground(int i) {
	return gf(i, 0) + gf(i, 1);
}

float fp_top(int i) {
	float wd = gf(i, 4);
	return fp_ground(i) + (wd >= wet_min ? wd : 0.0);
}

// The foreground rule. In front of the fighter plane (z > 0) nothing rises above the sight line from the camera to the
// fighter-plane row behind it, less fore_drop of its depth. So nothing in front hides the fighter plane, and the camera
// is never inside the ground or under a water sheet. Where land or water would rise into view it falls away instead,
// and from the camera it lies just under the fighter plane's own profile, as the old front face did. xr: world x (the
// camera sits near 0); ox: the planet copy's offset (planet-local x = world x - ox); top: the sight line to the row's
// top (its water) rather than its ground. Returns (cap, d cap/dx, d cap/dz).
vec3 fore_cap3(float xr, float z, float ox, bool top) {
	float t = z / fore_cam.z;
	if (t >= 1.0) {
		return vec3(fore_cam.y - fore_drop * z, 0.0, -fore_drop);
	}
	float xs = fore_cam.x + (xr - fore_cam.x) / (1.0 - min(t, 0.9));   // where the sight line meets the fighter plane
	float c = (xs - ox) / col_w;
	float c0 = floor(c);
	// The fighter plane's lowest within fore_span columns either side of where the sight line meets it: a narrow rise
	// in the plane throws no ridge toward the camera, and the cap is never higher. Its slope is that profile's
	// difference across one column, which changes smoothly as the camera moves (the lowest column's own slope flipped
	// from tick to tick where two columns stood near the same height). The columns are read once.
	float ys[10];
	for (int k = 0; k < 10; k++) {
		int ii = int(mod(c0 + float(k - 4), float(nc)));
		ys[k] = top ? fp_top(ii) : fp_ground(ii);
	}
	float span = min(fore_span, 3.0);
	float lows[3] = {1.0e9, 1.0e9, 1.0e9};   // the profile's lowest at c - 0.5, c and c + 0.5
	for (int q = 0; q < 3; q++) {
		float p = c - c0 + 0.5 * float(q - 1);   // -0.5 to 1.5 columns from c0
		float pf = floor(p);
		float fr = p - pf;
		for (int k = -3; k <= 3; k++) {
			if (abs(float(k)) > span) {
				continue;
			}
			int j = int(pf) + k + 4;
			lows[q] = min(lows[q], mix(ys[j], ys[j + 1], fr));
		}
	}
	float yp = lows[1];
	float dy = (lows[2] - lows[0]) / col_w;
	return vec3(mix(yp, fore_cam.y, t) - fore_drop * z, dy, (dy * (xs - fore_cam.x) + fore_cam.y - yp) / fore_cam.z - fore_drop);
}

// Applies the foreground rule at world x xr, depth z to a ground h (with its gradient) and the top over it (its water
// surface, or h where dry): both fall by what the top must, then the ground alone if it still rises above the sight
// line to the fighter plane's own ground. The water keeps at least its depth.
void fore_fall(inout float h, inout vec2 grad, inout float top, float xr, float z, float ox) {
	if (z <= 0.0) {
		return;
	}
	bool dry = top <= h;
	vec3 ct = fore_cap3(xr, z, ox, true);
	float cut = top - ct.x;
	if (cut > 0.0) {
		h -= cut;
		top = ct.x;
		grad = dry ? ct.yz : grad + ct.yz;
	}
	vec3 cg = fore_cap3(xr, z, ox, false);
	if (h > cg.x) {
		h = cg.x;
		grad = cg.yz;
		if (dry) {
			top = h;
		}
	}
}

// The ground at column i, world x xw, depth z: (height, d/dx, d/dz, dent), dent being the crater-and-groove offset
// that the terrain colours by. exact: the fighter-plane row, which reads the sim's deform directly. ox: the planet
// copy's world offset, for the foreground rule (fore_fall), which sees the water the water shader draws there.
vec4 ground4(int i, float xw, float z, bool exact, float ox) {
	float b = gf(i, 0);
	vec3 o = abs(z) <= -z_band_back + 0.5 ? ground_offset3(i, xw, z) : vec3(0.0);
	float off = exact ? gf(i, 1) : o.x;
	float h = b + off;
	vec2 grad = vec2(base_slope(i) + o.y, o.z);
	float s = far_weight(z);
	float top = h;
	if (s > 0.0) {
		float xs = far_x(xw, z, s);
		vec3 f = far_height3(xs, xw, z);
		h = mix(h, f.x, s);
		grad = mix(grad, f.yz, s);
		top = (h < 0.0 && (mix(b, gfx(xs, 0), s) < sea_base || gfx(xs, 4) >= wet_min)) ? 0.0 : h;
	} else {
		float wd = gf(i, 4);
		float surf = b + gf(i, 1) + wd;
		top = (wd >= wet_min && (b < sea_base || off < -wet_min || abs(surf) < wet_min) && surf > h) ? surf : h;
	}
	fore_fall(h, grad, top, xw + ox, z, ox);
	return vec4(h, grad, off * (1.0 - s));
}

// A vertex's ground: UV.x its column, flag 1 the exact row, a flag of 2 or more a run's boundary row that snaps to that
// coarser column stride (linear between the coarse columns), so the finer and the coarser run meet without a crack.
// ox: the planet copy's world offset (MODEL_MATRIX's translation).
vec4 ground_vertex(float col, float flag, float z, float ox) {
	if (flag > 1.5) {
		float st = floor(flag + 0.5);
		float c0 = floor(col / st + 0.0001) * st;
		float fr = (col - c0) / st;
		vec4 g0 = ground4(int(c0) % nc, c0 * col_w, z, false, ox);
		vec4 g1 = ground4(int(c0 + st) % nc, (c0 + st) * col_w, z, false, ox);
		return mix(g0, g1, fr);
	}
	return ground4(int(col + 0.5) % nc, col * col_w, z, flag > 0.5, ox);
}


// --- Fight lanes (ADR 0009; render/core/lanes.gd): the streets painted on the ground, and the lane cue. ---
uniform int street_n = 0;           // street strips in use
uniform vec4 street_strips[16];     // zTop, zBottom (world z; the top is nearer the camera), kind (0 sidewalk, 1 kerb parking, 2 carriageway), the street's centre z
uniform int span_n = 0;             // districts in use
uniform vec4 street_spans[16];      // a district's world x interval (x0, x1); z, w: its lane mask and look (not read yet)
uniform float span_edge = 120.0;    // RenderLook.STREET_EDGE: the paint fades in over this at a district's ends
uniform vec4 street_walk : source_color = vec4(0.52, 0.53, 0.56, 1.0);
uniform vec4 street_road : source_color = vec4(0.25, 0.26, 0.29, 1.0);
uniform vec4 street_kerb : source_color = vec4(0.36, 0.37, 0.40, 1.0);
uniform vec4 street_line : source_color = vec4(0.78, 0.76, 0.66, 1.0);
uniform float street_dash = 120.0;  // RenderLook.STREET_DASH: a centre-line dash and its gap, each
uniform float street_bay = 190.0;   // RenderLook.STREET_BAY: a kerb parking bay's length
uniform int avenue_n = 0;           // avenues in use: the cross streets that part the blocks
uniform vec4 avenues[24];           // an avenue's world x interval (x0, x1); z: its district
uniform vec4 lot_z;                 // the two block lanes in depth: the first's zTop, zBottom, the second's
uniform vec4 lot_col[8] : source_color;   // a look's paved ground in its blocks; a: how strongly it covers the biome's (0: yards)
uniform float avenue_walk = 60.0;   // RenderLook.AVENUE_WALK
uniform vec4 lane_cue[2];           // a fighter's world x, his depth, the stripe's half length along x, its strength (0: none)
uniform vec4 lane_cue_col[2] : source_color;
uniform float lane_cue_w = 14.0;    // RenderLook.LANE_CUE_W: the stripe's half width in depth
uniform vec4 pair_mark = vec4(0.0); // the pair's mark: one fighter's world x and depth, then the other's
uniform float pair_mark_k = 0.0;    // its strength, 0 to 1 (0: none)
uniform vec2 pair_mark_w = vec2(2.5, 0.6);   // its half width in pixels at its middle (by the nearer fighter's size) and RenderLook.PAIR_MARK_TAPER
uniform vec4 pair_mark_v = vec4(0.09, 0.07, 0.05, 0.55);   // RenderLook.PAIR_MARK_CORE, GRAD, RIM and PALE

// The ground's colour c with the pair's mark on it at world x and depth px: a stroke from under one fighter to under
// the other, a wedge in width and in value (broader and brighter toward the one nearer the camera, by how far their
// line is turned in depth; full at 30 degrees). It is drawn against the ground it lies on: its core within
// pair_mark_v.x of the ground's relative luminance (lighter, or darker on pale ground), its rim darker by
// pair_mark_v.z; so it is never a bright line on a dark road. upz: world units a pixel spans in depth (the stroke's
// width is in pixels, because the ground is seen at a low angle).
vec3 pair_mark_on(vec3 c, vec2 px, float upz) {
	if (pair_mark_k <= 0.0) {
		return c;
	}
	vec2 d = pair_mark.zw - pair_mark.xy;
	d.x -= world_w * floor(d.x / world_w + 0.5);
	vec2 q = px - pair_mark.xy;
	q.x -= world_w * floor(q.x / world_w + 0.5);
	float t = clamp(dot(q, d) / max(dot(d, d), 1.0), 0.0, 1.0);
	float turn = clamp(-d.y / max(0.5 * length(d), 1.0), -1.0, 1.0);   // above 0: the first fighter is the nearer
	float hw = upz * pair_mark_w.x * (1.0 + pair_mark_w.y * turn * (1.0 - 2.0 * t));
	float r = length(q - d * t) / max(hw, 0.0001);
	float cover = 1.0 - smoothstep(0.75, 1.0, r);
	if (cover <= 0.0) {
		return c;
	}
	float near = turn >= 0.0 ? 1.0 - t : t;   // 1 at the nearer fighter's end
	float core = (pair_mark_v.x - pair_mark_v.y * (1.0 - near)) * (dot(c, vec3(0.2126, 0.7152, 0.0722)) < pair_mark_v.w ? 1.0 : -1.0);
	return max(c + vec3(mix(-pair_mark_v.z, core, 1.0 - smoothstep(0.35, 0.6, r)) * cover * pair_mark_k), vec3(0.0));
}

// How much of a district's street paint a world x gets (0 outside every district), for the vertex stage.
float street_weight(float xw) {
	float w = 0.0;
	for (int k = 0; k < span_n; k++) {
		vec4 sp = street_spans[k];
		w = max(w, smoothstep(sp.x, sp.x + span_edge, xw) * (1.0 - smoothstep(sp.y - span_edge, sp.y, xw)));
	}
	return w;
}

// The street's colour at world x and depth px.y: rgb, and alpha 0 off the streets. upx: world units a pixel spans along
// x, so thin lines fade out before they alias.
vec4 street_paint(vec2 px, float upx) {
	for (int k = 0; k < street_n; k++) {
		vec4 st = street_strips[k];
		if (px.y > st.x || px.y <= st.y) {
			continue;
		}
		float fine = 1.0 - smoothstep(4.0, 12.0, upx);
		if (st.z < 1.5) {
			// A crossing: where an avenue's carriageway meets the street, the sidewalk and the kerb give way to road.
			for (int a = 0; a < avenue_n; a++) {
				vec4 av = avenues[a];
				float e = min(px.x - av.x, av.y - px.x);
				if (e > min(avenue_walk, 0.2 * (av.y - av.x))) {
					return vec4(street_road.rgb, 1.0);
				}
			}
		}
		if (st.z < 0.5) {
			// Sidewalk, with slab joints across it.
			float joint = 1.0 - smoothstep(0.0, 2.5, abs(fract(px.x / 75.0) - 0.5) * 75.0);
			return vec4(mix(street_walk.rgb, street_kerb.rgb, 0.5 * joint * fine), 1.0);
		}
		if (st.z < 1.5) {
			// Kerb parking: bays marked across the strip.
			float bay = 1.0 - smoothstep(0.0, 3.0, abs(fract(px.x / street_bay) - 0.5) * street_bay);
			return vec4(mix(street_kerb.rgb, street_line.rgb, 0.7 * bay * fine), 1.0);
		}
		// Carriageway: a dashed centre line.
		float on = step(0.5, fract(px.x / (2.0 * street_dash)));
		float mid = 1.0 - smoothstep(2.0, 5.0, abs(px.y - st.w));
		return vec4(mix(street_road.rgb, street_line.rgb, 0.85 * on * mid * fine), 1.0);
	}
	return vec4(0.0);
}

// The ground of a block at world x and depth px.y, where no street strip lies: an avenue crossing it (a carriageway
// between two sidewalks, a dashed line down its middle), or its district's paved lot. rgb, and alpha 0 where the
// biome's own ground shows (a suburb's and a village's yards, and anything outside the blocks).
vec4 block_paint(vec2 px, float upx) {
	bool first = px.y <= lot_z.x && px.y > lot_z.y;
	bool second = px.y <= lot_z.z && px.y > lot_z.w;
	if (!first && !second) {
		return vec4(0.0);
	}
	for (int k = 0; k < avenue_n; k++) {
		vec4 av = avenues[k];
		if (px.x > av.x && px.x < av.y) {
			float e = min(px.x - av.x, av.y - px.x);
			if (e < min(avenue_walk, 0.2 * (av.y - av.x))) {
				return vec4(street_walk.rgb, 1.0);
			}
			float fine = 1.0 - smoothstep(4.0, 12.0, upx);
			float mid = 1.0 - smoothstep(2.0, 5.0, abs(px.x - 0.5 * (av.x + av.y)));
			float on = step(0.5, fract(px.y / (2.0 * street_dash)));
			return vec4(mix(street_road.rgb, street_line.rgb, 0.85 * on * mid * fine), 1.0);
		}
	}
	for (int k = 0; k < span_n; k++) {
		vec4 sp = street_spans[k];
		if (px.x >= sp.x && px.x < sp.y) {
			return lot_col[clamp(int(sp.w + 0.5), 0, 7)];
		}
	}
	return vec4(0.0);
}

// The lane cue at world x and depth px: a soft stripe on the ground at a fighter's depth, in his colour (rgb, alpha).
// upz: world units a pixel spans in depth, so the stripe is never thinner than a pixel or two.
vec4 lane_cue_at(vec2 px, float upz) {
	vec4 c = vec4(0.0);
	for (int k = 0; k < 2; k++) {
		if (lane_cue[k].w <= 0.0) {
			continue;
		}
		float dx = px.x - lane_cue[k].x;
		dx -= world_w * floor(dx / world_w + 0.5);
		float hw = max(lane_cue_w, 1.2 * upz);
		float a = lane_cue[k].w * (1.0 - smoothstep(0.5 * hw, hw, abs(px.y - lane_cue[k].y))) * (1.0 - smoothstep(0.25 * lane_cue[k].z, lane_cue[k].z, abs(dx)));
		if (a > c.a) {
			c = vec4(lane_cue_col[k].rgb, a);
		}
	}
	return c;
}
