// What the tile ground's two vertex stages share (terrain_tile.gdshader, water_tile.gdshader): the frame, the field's arrays, and a tile
// vertex's node. The heights are the field's nodes, read as the mesh's own two triangles.
uniform sampler2DArray hts : filter_nearest, repeat_disable;
uniform sampler2DArray ids : filter_nearest, repeat_disable;
uniform vec3 pv = vec3(1.0, 0.0, 0.0);
uniform vec3 hd = vec3(0.0, 1.0, 0.0);
uniform vec3 sd = vec3(0.0, 0.0, 1.0);
uniform vec3 pv0 = vec3(1.0, 0.0, 0.0);
uniform vec3 hd0 = vec3(0.0, 1.0, 0.0);
uniform vec3 sd0 = vec3(0.0, 0.0, 1.0);
uniform vec3 pvp = vec3(1.0, 0.0, 0.0);   // the plan's frame at the camera: the land's light stays with the land through a swing
uniform vec3 hdp = vec3(0.0, 1.0, 0.0);
uniform vec3 sdp = vec3(0.0, 0.0, 1.0);
uniform float strip_x = 0.0;
uniform sampler2D plane_tex : filter_nearest, repeat_disable;
uniform float plane_span = 3000.0;
uniform int cb_n = 0;              // the bowls near the camera, from World's store (RenderTileGround._bowls)
uniform vec4 cb_a[16];             // its planet direction, its radius
uniform vec4 cb_b[16];             // its depth, its rim, when it was made
uniform vec2 cb_rim = vec2(0.2, 0.5);   // WorldCrater.RIM_IN, RIM_OUT
uniform float cb_now = 0.0;
uniform float cb_open = 0.25;      // the seconds a new bowl takes to open
uniform float crater_look = 0.0;   // Art's crater (RenderTileGround.crater_look): the rest of its numbers are RenderLook.CRATER_*
uniform vec4 crater_rings = vec4(6.0, 40.0, 120.0, 0.12);   // depth of the lip, the outer wall's end, the inner wall's end; below .w of slope it's floor
uniform vec4 crater_steps = vec4(0.74, 0.68, 0.08, 1.6);   // the inner ring's step, the floor's, a floor stripe's half-step, its width in nodes
uniform sampler2D scar_tex : filter_nearest, repeat_enable;   // per column: how much of a scar's width is left, 0 at its ends (RenderTileGround._scar_slice)
uniform vec4 scar_look = vec4(0.27, 0.1, 1.0, 0.33);   // RenderLook.SCAR_LOOK: the width as a share of the burn alone, the outline's variation, its rate along the line, the fringe past the core
uniform float scar_fringe = 0.72;   // RenderLook.SCAR_FRINGE: the ground under the singe, by multiply
uniform float fore_tone = 1.0;   // one tone in front of the plane (RenderTileGround.fore_tone)

vec2 tile_chart(vec3 d, vec3 h, vec3 s, vec3 p) {
	float x = dot(d, h);
	float z = dot(d, s);
	float q = sqrt(x * x + z * z);
	float k = q > 1.0e-5 ? atan(q, dot(d, p)) / q : 1.0;
	return vec2(x, z) * k * globe_r;
}

float tile_h(ivec2 a, int layer) {
	return texelFetch(hts, ivec3(clamp(a.x, 0, 27), clamp(a.y, 0, 27), layer), 0).r;
}

vec3 tile_dir(vec3 n, vec3 u, vec3 w, vec2 st) {
	return normalize(n + u * tan(st.x * 0.7853982) + w * tan(st.y * 0.7853982));
}

// A tile vertex: its direction on the planet, whether it's the skirt, the ground's height, a lake's or a river's depth at its node, and where
// it reads from. m: the instance's matrix (the face's axes, its place on the face); c: its custom data (layer and data level, morph, width).
void tile_node(mat4 m, vec4 c, vec2 uv, out vec3 dir, out float skirt, out float h, out float wet, out ivec2 ic, out int layer, out float dist, out vec2 st, out float dsize) {
	vec3 n = m[0].xyz;
	vec3 u = m[1].xyz;
	vec3 wv = m[2].xyz;
	vec3 place = m[3].xyz;
	vec2 uvc = clamp(uv, vec2(0.0), vec2(1.0));
	skirt = (uv.x != uvc.x || uv.y != uvc.y) ? 1.0 : 0.0;
	vec2 g = uvc * 25.0;
	vec2 st0 = place.xy + uvc * place.z;
	vec3 d0 = tile_dir(n, u, wv, st0);
	dist = atan(length(cross(d0, pv)), dot(d0, pv)) * globe_r;
	float mk = smoothstep(c.g * 1000.0, c.b * 1000.0, dist);
	// To the parent's lattice: every other node of this level's own grid across the face (25 is odd, so a tile's parity is its place's).
	vec2 cellxy = floor((place.xy + 1.0) / place.z + 0.5);
	vec2 odd = mod(cellxy, 2.0);
	vec2 gm = g - mod(g + odd, 2.0) * mk;
	st = place.xy + gm / 25.0 * place.z;
	dir = tile_dir(n, u, wv, st);
	layer = int(c.r + 0.01);
	float dl = floor(c.a / 16.0);
	dsize = 2.0 / (3.0 * pow(2.0, dl));
	vec2 d0xy = floor((place.xy + vec2(1.0)) / dsize + 0.001) * dsize - vec2(1.0);
	vec2 dg = (st - d0xy) / dsize * 25.0 + vec2(1.0);   // on the layer: the ring outside the tile is its first row
	ivec2 i0 = ivec2(floor(dg));
	vec2 f = dg - vec2(i0);
	float h00 = tile_h(i0, layer);
	float h10 = tile_h(i0 + ivec2(1, 0), layer);
	float h01 = tile_h(i0 + ivec2(0, 1), layer);
	float h11 = tile_h(i0 + ivec2(1, 1), layer);
	h = f.x + f.y <= 1.0 ? h00 + f.x * (h10 - h00) + f.y * (h01 - h00) : h11 + (1.0 - f.x) * (h01 - h11) + (1.0 - f.y) * (h10 - h11);
	ic = ivec2(floor(dg + 0.5));
	wet = texelFetch(ids, ivec3(ic.x, ic.y, layer), 0).g * 255.0 * 4.0;
}

// The ground's change from the bowls at a planet direction: WorldCrater.profile, the sim's own shape.
float tile_bowls(vec3 d) {
	float s = 0.0;
	for (int k = 0; k < cb_n; k++) {
		float u = length(d - cb_a[k].xyz) * globe_r / cb_a[k].w;
		if (u < 1.0 + cb_rim.y) {
			float h = 0.0;
			if (u < 1.0) {
				float t = 1.0 - u * u;
				h = -cb_b[k].x * t * t;
				float lo = 1.0 - cb_rim.x;
				if (u > lo) {
					float a = (u - lo) / cb_rim.x;
					h += cb_b[k].y * a * a * (3.0 - 2.0 * a);
				}
			} else {
				float b = (u - 1.0) / cb_rim.y;
				h = cb_b[k].y * (1.0 - b * b * (3.0 - 2.0 * b));
			}
			float o = clamp((cb_now - cb_b[k].z) / cb_open, 0.0, 1.0);
			s += h * o * o * (3.0 - 2.0 * o);
		}
	}
	return s;
}

// The foreground rule: in front of the plane nothing stands above the sight line to the line's own ground behind it.
float tile_fore(float y, vec2 p) {
	if (p.y <= 0.0) {
		return y;
	}
	float t = min(p.y / fore_cam.z, 0.95);
	float pu = clamp((p.x / (1.0 - t) + plane_span) / (2.0 * plane_span), 0.0, 1.0) * 63.0;
	int ua = int(pu);
	float pl = mix(texelFetch(plane_tex, ivec2(ua, 0), 0).r, texelFetch(plane_tex, ivec2(min(ua + 1, 63), 0), 0).r, pu - float(ua));
	return min(y, mix(pl, fore_cam.y, t) - fore_drop * p.y);
}
