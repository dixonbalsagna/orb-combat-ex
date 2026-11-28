# The skeleton capsule read (Animation, 2026-11-28; for VFX's L3 aura trial)

Ten capsules round the body a pane is drawing, so the energy shader can hang its outline on the moving figure. The Look Profile spec asks for it (`docs/ep/proposals/look-profile-spec.md`, section 6). It is `render/anim/anim_capsules.gd` (`AnimCapsules`), in `docs/animation/pending/capsule-read/` until the EP lands it.

## How to call it (VFX)

One `Caps` per fighter per pane, made once and kept. Call after the pane has updated its fighters; `VfxLayer.update` already runs after them.

```gdscript
var caps := AnimCapsules.Caps.new()

# each frame
var pane := get_parent() as PaneWorld
if AnimCapsules.read_slot(pane, slot, caps):
    var box: Rect2 = caps.box.grow(reach)          # reach: how far the aura goes past the body, in world units
    mat.set_shader_parameter("anchor", caps.anchor)
    mat.set_shader_parameter("box", Vector4(box.position.x, box.position.y, box.size.x, box.size.y))
    mat.set_shader_parameter("seg", caps.seg)      # uniform vec4 seg[10]
    mat.set_shader_parameter("rad", caps.rad)      # uniform float rad[10]
else:
    pass   # no body to wrap (the slot is missing, or the view is hidden, as before an intro): draw nothing
```

- **A staged match's other bodies** have views of their own: `AnimCapsules.read(pane.other_views[j], pane.cam_rig.global_transform.basis, pane.mats._globe_r, caps)`. `read` takes any `FighterView`.
- **`f.hidden` is not looked at.** Whether an aura shows stays your rule (`render/vfx/aura.gd`).
- **The order of the ten** is `AnimCapsules.HEAD, TORSO, UPPER_ARM_L, FOREARM_L, UPPER_ARM_R, FOREARM_R, THIGH_L, SHIN_L, THIGH_R, SHIN_R`. "L" and "R" are the rig's own sides; a mirrored fighter keeps them.

## What the numbers are

- **`seg[i]` = (ax, ay, bx, by):** the two ends of capsule i, as offsets from `anchor` along the camera's right and up, in world units at the anchor's own scale. A fighter is about 80 tall.
- **`rad[i]`:** the capsule's radius, same units. The head's and torso's change with how far the body is turned to the camera.
- **`box`:** the rectangle round all ten, radii included, in the same offsets.
- **`a[i]`, `b[i]`:** the same ends in pane world space before the projection, if something needs to be placed in the world.

The offsets already carry everything the body goes through: the pose actually written to the mesh, the turn and mirror, the launch spin, the yaw, depth and sag, and on the tile ground the globe's bend. `project()` is the CPU twin of `ortho_clip`'s offset (`render/shaders/ortho.gdshaderinc`).

## The shader side

Place the rectangle with the same projection the body uses, and hand the fragment the offset directly. This is the recipe the stills below were drawn with:

```glsl
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never;
#include "res://render/shaders/bend.gdshaderinc"
uniform vec3 anchor = vec3(0.0);
uniform vec4 box = vec4(0.0);
uniform vec4 seg[10];
uniform float rad[10];
varying vec2 at;      // offsets from the anchor: the space seg and rad are in

void vertex() {       // a QuadMesh of size 1
    at = box.xy + (VERTEX.xy + vec2(0.5)) * box.zw;
    vec4 place = (globe_r > 0.0) ? globe_place(anchor) : vec4(anchor, 1.0);
    vec4 ca = PROJECTION_MATRIX * (VIEW_MATRIX * place);
    POSITION = ca + vec4(PROJECTION_MATRIX[0][0] * at.x, PROJECTION_MATRIX[1][1] * at.y, 0.0, 0.0);
}

float body(vec2 p) {  // signed distance to the figure; negative inside
    float d = 1.0e9;
    for (int i = 0; i < 10; i++) {
        vec2 a = seg[i].xy;
        vec2 ab = seg[i].zw - a;
        float h = clamp(dot(p - a, ab) / max(dot(ab, ab), 1.0e-6), 0.0, 1.0);
        d = min(d, length(p - a - ab * h) - rad[i]);   // the toy joins these with smin; k of about 3.5 world units matches its figure
    }
    return d;
}
```

- **Give the material to the pane:** `pane.mats.track(mat)`, so the globe's uniforms reach it, and `pane.mats.untrack(mat)` when it goes.
- **Depth is yours.** The snippet leaves the rectangle at the anchor's depth. For an aura behind the body, set `POSITION.z` from a point a little behind the anchor (`cp.z / cp.w * ca.w`, as `ortho_clip` does).
- **Give the mesh a large `extra_cull_margin`:** the vertex shader places it, so its own bounds say nothing.

## What is checked

`render/anim/tools/capsule_check.gd` (headless) stages both fighters standing, mirrored, flying, dashing, charging, launched and turning, losing and winning a beam struggle, and through a whole transformation. It draws each through the real `FighterView` and measures every body vertex of the mannequin against the union of the capsules:

| Part | Drawn outside the capsules by at most | Allowed |
| :--- | ---: | ---: |
| head | 0.2 | 1.5 |
| torso and shoulders | 1.4 | 4.5 |
| arms | 1.3 | 1.5 |
| hands | 1.9 | 3.5 |
| legs | 1.4 | 2.0 |
| feet (the toes) | 3.5 | 4.0 |

- It also checks that a read changes no sim hash and no pose, that `read_slot` works on a live pane on the tile ground, and that with animation off there is a plain standing outline.
- With every radius cut to 60% it fails, so it can fail.

The stills (the real web build, the capsules drawn over both fighters with the snippet above, in play): standing, flying, transforming, launched and in a beam struggle. They show fighters, so they are not in git: `docs/animation/private-img/capsule-read/`.

## Limits

- **Cloth is not in the outline:** the pack and the sashes stick out of it. An aura drawn behind the body is hidden by them there, not shaped by them.
- **Capsules are round, the body is faceted:** the outline sits up to about 2 units inside the hands' corners and 3.5 inside the toes.
- **A shin's lower end sits 2.5 forward of the ankle,** so the outline reaches into the foot.
- **Only the mannequin.** The radii are written in `anim_capsules.gd` from `anim_rig.gd`'s part sizes. A new body shape needs its own row, and the check will say so.
- **Offsets belong to one pane.** `read_slot` uses that pane's camera and views, so in a split each pane reads for itself.

## Cost

About 16 µs a read in the headless editor build on Orb's PC: two fighters in one view 32 µs, in a split 64 µs. The spec allows the whole look system 0.1 ms of script a frame, so read only while that fighter's aura is showing. The web build will be slower than this; that reading is Performance's (L13).
