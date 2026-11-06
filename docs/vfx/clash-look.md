# The beam clash's air (2026-10-30)

Orb: "ideally I'd like to see that solid white glowing flare replaced with visually distinctive procedural shaders, the air should look like its rippling and glowing with pressure and energy, dynamic distortions and color changes and patterns should erupt out based on the composition and power behind each of the beams of each fighter, composition should be determined by the fighter's energy fighting style, their current form, any other unique situations future fighters may possess or cause when we increase the roster."

The solid white sphere where two beams meet (BeamView's `_flare`) is replaced by **rippling, glowing air** at the meeting point: pressure rings travelling out of it, each side's own colours, front and texture, rays and rings that erupt when a player surges, and the screen behind it bent by the pressure. Presentation only: it reads the clash, the fighters and the struggle model, writes nothing of the sim, draws no random number, and is driven by the sim's clock (`S.T`), never the wall clock.

## What the player sees

| Part | What it is |
|---|---|
| **The air** | A disc of air at the meeting point, from 165 units across at an even low-tier clash up to 360 at the most power. The screen behind it is displaced along the radius by the pressure rings' wave and warped slowly: the sky, the ground and the far mountains ripple like heat over a road. It is a displacement, never a blur (the screen is sampled without mipmaps), and it thins to nothing toward both fighters' bodies. |
| **Two sides** | The disc is one fighter's energy on his half and the other's on his, the seam leaning toward the side that is **losing** (the leader's energy pushes across the middle), wavering with a slow noise. Each side has its own lane colour and second tint (Art's, the same two tints as his beam), so the clash is the colours of the two beams. |
| **The mix** | Where the two meet, the pair's mix colour (the lane colours averaged in hue by the short way round, so opposite hues stay a colour) erupts. A new pairing is a new mix with no code. |
| **Each side's front** | How its pressure moves, from Combat's struggle looks (docs/combat/energy-movesets.md): **wall** (broad arcs pushed toward the loser: the Protagonist), **lances** (straight dashes streaming along the beams: the Anti-hero), **wire** (taut arcs about a point far behind the winner, quivering: the Empress's row), **sputter** (ragged jets in and out of being: the Cyborg's row), **plain**. None of them rotates, spirals or drills (Legal e11). |
| **Each side's texture** | The beam's own pattern (energy.json `pat`): **boil** (bubble rings) or **facets** (crystal cells, flat hue mosaic), or none. |
| **Power** | More power (tier, and the form step he has taken) means a bigger disc, tighter rings, more and brighter rays. The leader's pressure runs tighter. |
| **A surge** | When a surge's swell reaches the point (Encounter's `beam_surge`, through the struggle model's waves) a ring and rays erupt there in the presser's accent colour, for 0.55 s, at most one every 30 ticks (40 under Reduce flashing). |
| **The knot** | The struggle model's slow swell grows the core and the rays over the first seconds. The core is a boiling paler tint of the two lanes, never a flat disc and never white. |
| **Colour** | Mixed over the scene, never added to it (added over a bright sky it went white), at a brightness capped by `glow_cap` (0.92). |

Nothing covers the fighters: the quad sits at the beams' own depth, so a body in front hides it by the depth test, and both the glow and the displacement thin to nothing over a keep zone on each body (`keep_r` 105 units about the torso).

## It is composed from data (data/vfx/clash.json, schema tools/schemas/vfx-clash.schema.json)

A side is composed in this order, each step overriding the last (render/vfx/clash_look.gd):

1. **His lane colour** (Art's: `VfxAura.lane_color` of his aura, so a colour-vision preset follows) and **his beam flavour** (energy.json: the second tint's hue shift, the beam's pattern, which is the clash's texture unless the row names one).
2. The **`default` row**, then **the row for his roster id** (lower case; the Anti-hero is the roster's `rival`).
3. The row's **`forms` entry** for the form step he has taken (`Fighter.form.step`, while forms are on).
4. Each of the row's **`situations`** whose condition holds: `{"read": "tier", "min": 4, "set": {"spike_k": 1.6}}`. `read` is a dotted path off the fighter (`tier`, `form.step`, `form.branch` ...); `is`, `min` and `max` are the condition; `set` is any of the row's keys. A path the fighter does not have is false.

**A new fighter is a data row.** Example, the two rows already in the file for the parked kits (nothing reads them until those fighters are on the roster):

```json
"empress": { "lane": "#b8c96a", "accent": "#6d7d30", "front": "wire", "texture": "none", "ring_k": 0.9, "spike_k": 0.9, "scale": 0.9 },
"cyborg":  { "lane": "#e2742c", "accent": "#8c9098", "front": "sputter", "ring_k": 1.1, "spike_k": 1.3, "scale": 1.2,
             "situations": [ { "read": "tier", "min": 4, "set": { "spike_k": 1.6 } } ] }
```

A fighter's special case (a form, a branch, a state the sim can read off him) is a `situations` entry on his row; a new front or texture is one new shader id and one name in `fronts` or `textures` (the only code a genuinely new kind of pattern needs). The sources are the ones Orb named: Art's colour lanes (through the aura), Combat's energy kits (their struggle looks are the fronts) and the fighters' forms. Not assumed: Combat's energy overhaul is parked and unbuilt, so the Empress and Cyborg rows are rows only, marked as such.

## Cost on the Compatibility renderer, and the fallback

- **The distortion reads the screen** (`hint_screen_texture`). On Compatibility (WebGL 2 and GL ES 3) the engine copies the whole frame once into a back buffer before the first draw that samples it, **once a frame, only while a clash is on**. That is one full-resolution RGBA copy: at 1080p about 8 MB read and 8 MB written a frame, which on an old laptop's shared memory is a few percent of its bandwidth for the 2 to 4 seconds a clash lasts; with MSAA on, the copy needs a resolve too and costs more. On top of that the quad's own pixels: a disc up to 360 units across, about 250 px a side at the game's usual zoom, with two noise lookups, a worley cell where a side has a texture, and one sample of the screen.
- **Not measured on an iGPU.** The captures here are headless Chrome in software, which says nothing about a real laptop's frame time. Performance's quiet-window bench is the measure; the figure above is arithmetic, not a reading.
- **The cheaper fallback keeps the pressure.** With no screen read (`VfxClashView.screen_read` 0, or the hub at `Q_LOW`) the air pass draws **dark lens bands** just past each ring's crest, and the glow pass draws the crest itself: bright band, dark band, the edge-of-a-lens contrast the eye takes for air bending. The same shader code, the same rings and fronts and colours; no back-buffer copy. The hub's quality picks it (the distortion at medium and high).
- The glow and the air are two quads of one include, so Rendering can drop either.

## Reduce flashing and Reduced motion

Still drawn, still energy: the same rings, fronts and colours at 0.82 of the strength, the rings at 0.55 Hz (0.9 normally), the fronts at 0.7 of their rate, half the displacement (`distort_calm`), and an eruption at most every 40 ticks. Every rate is inside Legal's (2 Hz, 1.5 Hz calm; the schema bounds them). It moves edges and hue; the only brightness that moves is a ring crest passing a point at 0.9 Hz or slower. No dissolve, fade or full-screen blur anywhere.

## Where it lives

| File | What |
|---|---|
| `render/vfx/clash_look.gd` | The composition: data, rows, forms, situations, power, the pair's mix, a surge's eruptions (pure functions, tested). |
| `render/vfx/clash_view.gd` | The node: two quads at the meeting point, built from the composition each frame. `VfxClashView.update(...)`. |
| `render/vfx/shaders/clash_core.gdshaderinc`, `clash_glow.gdshader`, `clash_air.gdshader`, `clash_air_lite.gdshader` | The shaders. |
| `data/vfx/clash.json`, `tools/schemas/vfx-clash.schema.json` (+ map row, ten fixtures) | The numbers and the rows; `enabled` false puts the old flare back. |
| `render/core/beam_view.gd` | **Rendering's, a grant** (docs/vfx/pending/clash-look/grant-beam-view.patch): builds the node, calls `update` where the flare was set, keeps the flare for the switch. |

## Honest limits

- The pictures were made with a **scratch scenario** that fakes Encounter's beam struggle (scripted pulses and surges, the point moved by a ramp, the sim's 1.6 s clash resolve postponed), because the struggle is parked and `Clash.mid` is -1 in the game: without it a clash is the sim's 1.6 s glide, and the air is drawn but there are no surges, no eruptions and no lead beyond the glide's.
- The Empress and Cyborg pairing is **their rows on two stand-in fighters** (ids and aura colours set in the scratch scene): their beams are not built, so the two sides' colours are as the rows say.
- Tuned by eye at the game's own zoom on desert sand and dusk sky; the numbers are data. The camera zooms in on a long clash, so the same units read bigger there.
- The flash analyser reads are in the park's README. Not a Legal clearance.

## The press: two beams shoving at the point (2026-11-01)

Orb (docs/ep/vision.md, 2026-11-01): the beams should "look like they are colliding and pressed against each other at the center point of the beam struggle, beam shape should flare out or erupt in eddies", and all energy consistent. Research's note (`research/rule-of-cool/beam-contact.md`) recommended three layers; this is the first two on the beam mesh and a vertex-and-hue form of the third:

- **The flare.** Each clash beam's head widens toward the contact (`flare_k`), over the last `reach` units of its length.
- **The sheet.** The head is cut flat where it meets the other, not rounded off (`sheet_k`), its last few percent bell out sideways, and a thin bright line (the lane colour lightened, held under 0.92) lies along the pressed face.
- **The eddies.** A travelling value-noise field rolls back along each beam from the head (`eddy_v` units a second, one every `eddy_wl`): it moves the silhouette (the radius) and takes the second tint where it swells. Never a closed disc and nothing goes round the axis. A point of the beam sees one go by at 0.71 Hz (checked at most 0.9). The mesh's 24 rings are bunched toward the head in the vertex stage (no new mesh), so the flare is drawn with more than a few of them.
- **What drives it.** Each side's power (the same composition as the air), the struggle's knot and the surges that have reached the head (`VfxBeamStruggle.apply`), the lead's sign; with no struggle the sim's glide gets the flare and the sheet and a steady eddy depth. **The loser still bulges and quivers, never thins** (the buckle patch's rule): the press only adds to the head.
- **The air and the shine.** The screen-reading air is drawn BEFORE the beams (render priority below their 0 to 2): the screen copy holds only the opaque pass, so the air in front repainted the plain scene over the beams' ends. The shine (rings, rays, the core: no screen read) is drawn in front, with a strip through the beams cleared (`strip_k`) so it lies on the air beside and above the pressed heads and never covers them. `strip_k` 0 puts it over them again.
- **By level.** Low: the flare and the sheet only (no eddy noise; the lite air). Medium: the eddies' shape. High: the eddies' hue as well.
- **Cost, arithmetic, not measured (Performance benches it).** The vertex stage adds a pow and two value-noise samples a vertex over about 2,400 vertices (two beams, three layers, 24 x 16): negligible. The fragment stage adds, in the head's last `reach` units only, two noise samples and a hue mix at High: up to about 0.3 million fragment-evaluations at 1080p while a clash is on, a few tenths of a millisecond on an old iGPU; Low and Medium add one smoothstep.
- **Colours.** The beams' tints are each fighter's lane (RL-221: the Empress is moss, no gold, white or red); the bright line is the lane lightened under 0.92.
