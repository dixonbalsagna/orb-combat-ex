# The body's tint and palette: the sky's light on the fighters, and the colour-vision presets (Animation's side)

Owner: Animation. Date: 2026-10-06. Brief (the EP, for Rendering and Art): the dynamic sky is built (955ce1b1); the world's light must follow it, so the bodies need one multiply colour; Art's three colour-vision presets (`data/art/colour-vision.json`) remap the lane colours. Render only; the gameplay hash is untouched.

## 1. What is exposed

- **`AnimBody.set_tint(c: Color)`**: one multiply colour on a body, **white by default** (nothing changes by a pixel unset). Rendering calls it each frame from its SkyDrive value (a `FighterView` holds one `AnimBody` a pane; call it on each).
- **The shader** (`render/shaders/fighter_body.gdshader`, Rendering's file) needs four lines, in `docs/animation/handoff/body-tint-shader.patch`: a `uniform vec4 tint = vec4(1.0)` and `ALBEDO = flat_shade(albedo.rgb * c * mix(vec3(1.0), tint.rgb, COLOR.a), n, shade)`. Until it lands the call is harmless (a parameter the shader does not have).
- **`AnimBody.set_palette(pal: Dictionary)`**: a new palette on the same body (a colour-vision preset switched on or off while a fight runs, or a new outfit): the cached mesh of that palette, the bones and the skin kept. `FighterView` sets the material's `skin` and `gear` from its own palette, as at build.

## 2. What takes the tint, and what does not

| Takes it | Does not |
| :--- | :--- |
| The body mesh: torso, legs, sleeves, head, hair, gear, with the battle damage's scuffs, bruises and tears (they are mixed in before the tint, so a marked body dims as a whole) | **The lane colour's parts: the forearms and the sashes** (the palette's `accent`, which `FighterView` sets to the aura colour). They carry a 0 alpha in the mesh (1128 vertices of 6996) and the shader leaves them out of the tint |
| | **The keyline** (`fighter_hull`, the outline pass) is another material: no tint. Art asked for the outline's own colour at every hour |
| | **The hit flash**: a flash draws the body with the tint white for its ticks (`AnimBody.set_look`) |
| | Everything of VFX's: auras, glows, smears and ghosts, the zip's echoes, the energy lights, the guard arc, and Rendering's own cue rings: other materials, never mine |

Art's rule ("bodies may dim less than the ground") is the values Rendering passes: nothing here clamps.

## 3. What I draw in a lane colour

**Nothing but the one thing above.** The body's forearms and sashes are the `accent` vertices, coloured by the palette `FighterView` builds (`"accent": _aura_col`, `fighter_view.gd` line 204): so under a colour-vision preset Rendering passes the preset's lane colour in `pal.accent` (it already does for its own glows) and calls `set_palette` when the setting changes; nothing in `render/anim` holds a constant lane colour. After-images, ghosts, smears and the zip's echoes are VFX's, not drawn by the animation; the hit flash is white (8, 8, 8), not a lane colour; the study and lab tools in `render/anim/tools` have their own palettes for their own pictures (tools only).

## 4. Checked

- `anim_check` `_test_body_tint`: the mask is exact (1128 vertices at alpha 0, all in the accent colour; 5868 at alpha 1), `set_tint` sets the uniform, a flash draws untinted and the tint returns after it, `set_palette` swaps the mesh and keeps the skin.
- **A still compare, HEAD against the working tree** (the web build of the flurry study, 120 ticks of the burst clip, both fighters, headless Chrome, every tick): **all 120 frames byte-identical.** With the shader patch applied and the tint white the frames are identical too (see the report), and with the tint set the bodies dim and the forearms and the keyline do not.
