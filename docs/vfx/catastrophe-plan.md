# The catastrophe tier's VFX (paper)

Owner: VFX Director. 2026-10-16. **Paper only; nothing is built, no Godot or Chrome was run for it.** Written for the EP's brief against Research's study (`docs/research/world-catastrophe.md`, 79a0941e), Game Design's `docs/design/run-mode.md` §3 (0dfe3f91) and Legal's RL-145 conditions c01 to c09 (`docs/legal/catastrophe-and-city-screen.md`). Audio's cue list (`docs/audio/catastrophe.md` §4) is the cue vocabulary. Every size below is a **starting knob** for Tools' clips to set, not a measured value; every cost is a count or an estimate, because no timing is allowed in the quiet window.

## 0. The short version

1. **Four effects, one light rule.** The blast cloud, the magma's glow, the orbital impact and the tremor's dust. The first three carry a *catastrophe light event*; the dust carries none (it is dark and slow).
2. **One light class, `cat`, in the flash registry** (§1). It enforces c02 itself: one event per 2 s across the screen, rise at least 0.3 s, fall at least 1 s, a calm form, red never. The effects cannot draw a catastrophe light the registry did not grant; a refused event still draws its body (smoke, dust, scar) without its light, so nothing is silent.
3. **The blast cloud is stateless** (§2): one `MultiMesh` of at most 400 billboards whose positions are closed-form curves of the cloud's age, computed in the vertex shader. No per-frame CPU rewrite (Research's prototype wrote 23,000 floats a frame), one draw call, and a replay seek or a pause is correct for free because the age is a sim tick.
4. **Two of Research's looks change to meet c06** (§2.4, §4): the ground shock *ring* becomes a low dust wall (no ring), and the orbital impact's expanding *ring* on the sphere becomes a lobed, noise-broken bloom that smears downwind and leaves a scar (no ring front leaving the planet).
5. **Nothing here is on the sim.** All of it reads cues and the world's `ash`; it never writes the sim, never touches `S.rng` (random-looking choices are hashes of the event's id, column and tick).

## 1. The `cat` light class (the rule the three bright effects share)

Added to `VfxFlashRegistry` (mine) beside the existing sources:

| Rule | Value | From |
| :--- | :--- | :--- |
| Events granted | one per **120 ticks** (2 s), counted across everything on screen, whatever the pane | c02, run-mode §3.2 |
| Rise | smootherstep over **at least 18 ticks** (0.3 s); the starting values are per event below | c02 |
| Fall | exponential-to-zero over **at least 60 ticks** (1 s), none under 1.0 s | c02 |
| Calm form (`registry.reduced`) | peak ×0.6, rise ×1.7 (never under 0.5 s), fall ×1.5, **no repeats**: a second event inside 4 s draws without light | c02 |
| Red | never: the ask carries the glow's colour and the existing `is_red` refusal applies; every colour keeps R/(R+G+B) under 0.8 | c03 |
| Irregularity | an event's phase offset and the lobes of its shape come from `hash(cat_id, x)`, not a clock; two events never share a shape | c03, c04 |
| Refused or held | the light is not drawn; the body is. The ask returns false with the reason `cat_gap`, logged like any refusal | c01 |

**One event, one id.** A landing seen on the sphere and in Camera's picture-in-picture window is *one* event with one `cat_id` and one registry ask; both views draw from the same envelope. (Camera's §3.3 asks for exactly this.)

**Small impacts are not catastrophe events.** An impact whose glow, at the current camera, weighs under **0.05 of the 21,824 px threshold (about 1,090 px at 1024 x 768, a 33 x 33 px spot)** is asked as an ordinary low-priority source (`far_impact`, in `LOW`), under the existing caps. At or above it, it is a `cat` event. This split is my proposal; **Legal should confirm the 0.05** (§7). It matters because c04 lets small impacts land at most two a second in a window, while c02 allows one *large* event per 2 s.

**The darkened sky.** c02 says the same glow is a bigger step in a darkened sky. So each event's peak is scaled by the world's `ash`: `peak_eff = peak × (1 − 0.35 ash)` as a starting value, and the worst-case clips for the three bright effects are recorded at ash 0, 0.5 and 1.0 (the boss fight is at ash 1.0 after the second blast). The scale is a knob the darkest clip sets, not a claim.

**The bright pieces never hide a fighter.** All catastrophe VFX draw **behind the fighters' plane** and under the rim light, with a top alpha of 0.85, so c05's lane-colour contrast in the darkest sky is not VFX's to lose; the cloud's smoke is dark grey-brown, never a black that swallows the lane colours.

## 2. The blast cloud (`blast_cloud`; run-mode §3.2, c06, c07)

**Cue** (Audio's list): `blast_cloud` with `x`, `y`, `amount` (3,000), `n` the landing tick; it may be preceded by a hush at `n − 8`. The cloud starts at `n`. The world's `ash` is read-only.

### 2.1 Stateless vertex-shader effect

One `MultiMesh` (quad, instance count fixed at build) and one `ShaderMaterial`; `INSTANCE_CUSTOM` holds `(group, u, seed, jitter)` and never changes. Uniforms, set once a tick from the cue: `age` (seconds, from the sim tick and the tick fraction, **never wall time**), `origin` (the one shortest-arc offset from the camera, computed on the CPU, so no per-vertex wrap), `scale` (`amount / 3000`), `calm`, `ash`, `heat0`.

| Group | Sprites (high) | Curve of the centre, with `t = age` |
| :--- | ---: | :--- |
| Stem | 120 | height `h(u) = u · 0.8 H(t)`, `H(t) = 14,000 (1 − e^(−t/6.5))`; width profile narrow in the middle, flaring at the base; sway `n(h, t)` from the hash noise, ≤ 6% of the width |
| Cap (a rolling torus seen from the side) | 200 | angle `φ = 2πu + ω t` with `ω = −0.35 rad/s`, minor angle `μ = 2π · frac(7u) − 0.5 ω t`; screen `x = (R + r cos μ) cos φ`, `y = H(t) + r sin μ`, depth `(R + r cos μ) sin φ` (sorted by that, in the shader, with a fixed draw order as the tie); `R(t) = 2,600 (1 − e^(−t/8))`, `r(t) = 1,500 · min(1, t/5)` |
| Skirt | 80 | a low wall on the ground each way from `origin`, `x = ± s(t)`, `s(t) = 4,500 (1 − e^(−t/3.2))`, height 300 to 600; a **dust wall, not a ring** |
| Ash flecks | 0 on the cloud's pass (see §2.4) | |

**Colour: fire into smoke by a heat ramp.** `heat(t) = heat0 · e^(−t/τ)` with `τ = 4 s` for the cap's core and 2.2 s for the stem; the ramp runs white-amber (the core, brief, small) → amber → ember brown → warm grey → grey-brown smoke. Red is never reached; the amber end holds R/(R+G+B) under 0.7. Fragments sample a procedural two-octave value noise in the fragment shader (our own code, no texture file) to break every edge: **no clean arc anywhere on the cap or stem**, and the fireball is an irregular billow, never a hemisphere (c06).

**The fireball is the light event.** An additive core inside the cap's lower third and the stem's base: it grows and brightens over **0.6 s (calm 1.0 s)** and falls over 2.4 s (calm 3.6 s), through the `cat` class; the body of the cloud is darker than the sky behind it after 2 s, so it is not a second light event. Its area share is kept small: the core's radius caps at 0.35 of the cap's major radius.

**Sprite budget and degrade ladder** (the fill rate is the risk: Research counted 3.1 million blended fragments a frame at 720p for 1,160 sprites):

| Level | Sprites | Pass | Target blended fragments, 720p | When |
| :--- | ---: | :--- | ---: | :--- |
| High | 400 | full resolution | **at most 1.5 million** *(target; to measure)* | quality high |
| Medium | 260 | full | at most 1.0 million | quality medium |
| Low | 140 | half-resolution pass, 2x upscaled with the noise, blended once | at most 0.4 million | quality low, or the frame's p99 over budget two seconds running (the existing governor) |
| Far | 6 textured quads (an impostor of the cloud's silhouette, cap and stem) | full | at most 0.2 million | the cloud is more than 9,000 units from the camera |

The cloud is a **set piece**: at most 3 blast clouds a fight (run-mode §10.1, at most 2 blast clouds), 30 s apart at least, so at most one is alive at a time for its first 25 s. It is retired after 40 s (the cap has become smoke) into the **ash fall** and the sky's darkening, which are not cloud sprites (§2.4). The ground cost is checked once, on a quiet machine, with Performance (§6).

### 2.2 The ground

The blast's crater, scorch and the towers' falls are the sim's and the existing debris pool's. VFX adds: the **dust wall** (the skirt) and a low **glow on the crater floor** that follows `heat(t)` (steady, no breathing).

### 2.3 What c06 and c07 take out

- **No ring leaving the planet or the blast.** Research's prototype drew "a bright ground shock ring, 45% opacity, sweeping outward" and passed its clips, but a ring-shaped shockwave leaving a planet is on c06's list. It is replaced by the skirt: a dark-grey dust wall that rises and sweeps, with a ragged top edge, no bright front, no circle. Research noted the ring should be dim at 12% as a margin anyway.
- **No perfect hemisphere of light consuming a city.** The glow is a lumpy core inside a stem-and-cap, never an enclosing dome; its silhouette is noise-broken (±30% radius).
- **Words.** Code, data and copy say `blast_cloud`; no "mushroom", "nuclear", "atomic", "A-bomb" or "H-bomb" in any shipped string or id, no radiation sign, no siren or countdown cue, no real place or date (c07). (Research's study uses the colloquial word; the build does not.)
- **The boss does not charge a sphere** and the VFX has no such tell: the wind-up of the blast is the fighter's own detonation cue, and the 8-tick hush is a darkening of the air in the blast's column, not a glowing orb in a hand.

### 2.4 Ash fall (the cloud's aftermath)

Not the cloud: a **slow field of dim flecks** and the darkening, driven by `ash`. The sky and the world light are Art's and Rendering's (the sky driver's ruin reads `ash`, under its slew limit, minutes long, c05). VFX adds a falling-flecks layer: up to 90 grey flecks in one `MultiMesh`, stateless (a hash of the fleck's id and the age gives its drift), alpha rising with `ash`, **no luminance rhythm** (the flecks are dim, uniform and many; none above 0.1 step on the sky).

## 3. Magma glow (`breach`, `magma`; c03, c06)

World owns the magma state; Rendering draws the glowing surface with the water grid's code (Research §1). **VFX owns what moves above and around it:**

| Piece | What it is | Rules (c03) |
| :--- | :--- | :--- |
| **The head's flare** | The bore's front as the beam meets the crust: an amber core, sparks and a soft halo that follows the cue's `x` | A `cat` event: rise 0.5 s (calm 0.85 s), fall 1.6 s; the breach cue's *start* draws it once; the head's travel after that is a steady glow at 35% of the peak, with no pulse |
| **Magma bubbles** | Domes that swell, then thin and settle, never a pop | Spawned by an **irregular hash process** per cut (a Poisson-like schedule from `hash(column, tick bucket)`, never a fixed period): at most **3 alive per 1,000 units of cut**; a spot lives 0.4 to 1.0 s, so a spot cannot repeat faster than 2 Hz; the highlight is a **luminance step under 8%** (the c03 limit is 10%); sizes vary 3x; two spots within 400 units are separated by at least 12 ticks and by different size. Never a regular spot or stripe pattern over a large area: a dedicated check counts spots per 1,000 units and rejects a lattice |
| **Surface breathing** | A slow swell of the whole glow, Research's 0.19 Hz | 8% of the glow (4% under Reduce flashing); **off under Reduced motion**; the phase differs by section (`hash(section)`), so a long cut never pulses as one |
| **Embers** | Arcs thrown from the head and the thin crust, cooling to dark | Through the existing debris pool (a new job, "ember"), at most 60 alive, 40 spawned a second, colour amber to brown, never red, fade 0.8 to 2 s |
| **Steam and smoke** | Slow grey columns off the walls, a breath | The pool's smoke job, low contrast, no flicker |
| **Heat on the walls** | Tint on the cut's walls | Rendering's, from the same heat; VFX gives no light of its own here |
| **The cooling set** | When the rock sets (`magma` text `cooling`) | The glow dims on a 6 s slow ramp; a dull steam puff. Never a flash |

**c06:** there is **one cut**, bounded to the slice, glowing only inside it, and it ends at the crust floor. VFX draws nothing that leaves the far side, and **no glowing fissures branch across the ground**: the existing crack sets stay dark hairlines. A beam through a planet or a spreading net of lit cracks is exactly what c06 forbids, so the glow is held to the notch by a mask the same width as the cut plus a soft margin.

**Colour:** all glow colours are amber-orange with R/(R+G+B) under 0.8, checked in `effects_check` over the whole ramp (Research held 0.8 and passed 0 red; I hold it with the beam's own `is_red`).

## 4. The orbital impact read (`exo_impact`, `meteor`; c04, c06)

Rendering draws the planet sphere above about 0.3 R and the arena's crater strip on it; Camera frames it (`docs/camera/exosphere.md`). **VFX supplies how an impact reads from far away,** as a shader include Rendering's sphere shader pulls in (`render/vfx/shaders/orbit_impact.gdshaderinc`, with Rendering's grant, §7) and an array of at most 8 uniforms, each `(strip_x, age, size, seed)`:

- **A bloom, not a ring.** A soft additive glow on the great-circle band at the strip position: a lumpy blob whose radius is modulated by noise (±40% around its edge), so it has no circular front. It grows over **0.3 s (calm 0.5 s)** and falls over **1.6 s** (c02's 0.3 and 1.0 at least), a `cat` event only if its area weighs at least 0.05 (§1).
- **A smear.** The plume's glow leaves a dim, brown-grey smear that drifts along the band with the low layer's wind (read from the atmosphere's cell, so it agrees with the sky) over 12 s, fading; this is what stays visible after the glow has gone and carries the "someone struck here" read from far away.
- **The scar** is not VFX's: it is the strip texture's crater, uploaded by Rendering. VFX only dims the bloom as the scar appears, so the transition is a hand-over, not a pop.
- **A falling shot's glow** (the 90-tick fall): the shot is a short bright streak whose tail points up the column; steady (no flicker), no larger than 3 px at the wide; its light is a `far_impact`-class edge, small. The exosphere fighters' glow is a **steady edge** (c04) and it is Aura's (VFX), already steady.
- **c06:** no ring shockwave off the planet's edge, no planet cracking, no crust-wide fissures. Research's orbit scene drew rings on the sphere; they are removed. The blast is local, the bloom is lumpy, and nothing travels around the limb.
- **c04, spacing:** the sim spaces landings (one per 30 ticks within 6,000 units); VFX adds a second guard: if two blooms would overlap within 6 ticks on one screen window, the later one's envelope is **merged into the earlier** (it grows it by 25%), never doubled, and a bloom's phase comes from its `cat_id`, so two never rise in step.
- **Camera's window and the wide share the same uniform array.** In the window the impact is the same event at a closer scale; its area weight is higher, so the window is where the 2 s rule is most often invoked. Under Reduce flashing the window's still frame (Camera's rule) is taken from this envelope at 0.5 s after the landing.

## 5. The tremor's dust (`tremor`; run-mode §3.1, c06)

The tremor is a live set piece: heaving ground and swaying towers (World, Animation) for the cue's length (`n` is the end tick; Audio's is 3.6 s). **A quake, never glowing fissures and never a ring** (c06).

- **Dust curtains.** Low sheets of dust rising off the ground along the whole visible slice and from the towers' bases: one `MultiMesh`, **at most 160 sprites**, stateless on `age` and the tremor's start and end ticks. The onset rises over 1.0 s (no step), holds with an irregular hash-driven wander, and settles over 4 s after the end. Colour: warm grey, **alpha at most 0.5**, a luminance step against the sky under 0.07 even at its thickest (it is dark and slow, so it is not a catastrophe light event and never asks the `cat` class).
- **No rhythm.** The audio wobbles at 2.5 Hz; the picture does not. Any shiver in the dust is a low-amplitude irregular noise of at most 3% luminance, uncorrelated between sprites; there is no period. Camera shake is the camera's own, not VFX's.
- **Rubble.** A patter of small bits through the existing debris pool, at most 40 a second with hashed jitter, from the towers' bases and the ground; the pool's cap (460) and evictions already hold.
- **The towers' windows** go dark in one step with the quake's onset (Research §4), a fade over 1 s in practice; they never blink.
- **Calm form:** the same, with the onset over 1.5 s, the shiver off, and the rubble thinned by half. It remains visible: a dust curtain is information, so it is never removed under Reduce flashing, only slowed.
- **Reduced motion:** the curtains hold their final shape and slowly thicken; no wander.

## 6. Files (all mine) and what needs a grant

| File | New or changed | What |
| :--- | :--- | :--- |
| `render/vfx/catastrophe.gd` (`VfxCatastrophe`) | new | cue handlers (`tremor`, `breach`, `magma`, `blast_cloud`, `exo_impact`, `meteor`), per-event state (id, start tick, size), envelopes, registry asks, uniform packing; no sim writes |
| `render/vfx/cloud_view.gd` | new | the cloud's `MultiMesh` build, the degrade ladder, the impostor and half-res pass |
| `render/vfx/shaders/cloud.gdshader`, `dust.gdshader`, `orbit_impact.gdshaderinc` (+ `.uid`) | new | the vertex curves, the heat ramp, the noise, the bloom and smear |
| `render/vfx/magma_fx.gd` | new | the head's flare, bubbles (hash process), embers, steam, the breathing |
| `render/vfx/flash_registry.gd` | changed | the `cat` class and its `ask_cat` (§1); `far_impact` added to `LOW` |
| `render/vfx/debris.gd`, `explode.gd` | changed | "ember" and "rubble" jobs, a dust-curtain feed |
| `render/vfx/vfx_hub.gd` | changed | routes the new cues; reads `ash` read-only; passes `cat` calm state |
| `data/vfx/catastrophe.json` + `tools/schemas/vfx-catastrophe.schema.json` + `tools/schemas/map.json` | new, changed | every number in §1 to §5 as data (sprite counts, curves' constants, rise and fall, caps, the ash scale, colours) |
| `render/vfx/tools/effects_check.gd` | changed | checks below |
| `docs/vfx/catastrophe-plan.md`, `docs/vfx/effect-budgets.md` | new, changed | this plan; the budget rows |

**Checks (`effects_check`)**, deterministic and fast: the `cat` gap (a second event 119 ticks after the first is refused with `cat_gap`, one at 120 is granted); rise and fall never under 18 and 60 ticks in both modes; no colour in any ramp is red (R/(R+G+B) under 0.8); the calm form's peak is 0.6 of the normal and its rise at least 0.5 s; the same cue stream gives the same uniforms (determinism); the sprite counts per level; the bubble schedule's per-1,000-unit cap and its 2 Hz limit, and no lattice; `ash` scaling at 0, 0.5 and 1.

**Grants needed:** Rendering's, for the sphere shader to include `orbit_impact.gdshaderinc` and the 8-uniform array (§4), and for the cloud to sit in the backdrop layer order behind the fighters; I touch no file of theirs. I do not touch `transform_view.gd` or `vfx_layer.gd`; the cloud and the dust views are added to the hub's layer from the hub (mine).

## 7. Flash clips (Tools' set, c01) and costs

**Worst-case clips**, each in both modes, recorded in the required set on the commit that carries it, at the game's camera distance with fighters on screen: (1) the blast cloud's detonation at ash 0, 0.5 and 1.0; (2) the breach: the bore, the head's flare, the bubbles on a 600-unit cut; (3) the bombardment: six impacts in 10 s in the exosphere, the wide, and the same through Camera's window; (4) the tremor's dust with the towers' windows; (5) the **combined** boss beat: a breach and then a blast 30 s later in the darkened sky (the worst realistic case). The analyser's red flashes must read 0 in all, the general flash count must stay under the existing limit, and Legal reads the three bright effects' storyboards at their worst frame with the calm forms (their c01 request).

**Costs**, counts only (no timing was taken): the cloud is 1 draw call and at most 400 instances at high; the dust 1 draw call and 160 instances; the ash flecks 1 and 90; the magma effects live in the existing debris pool plus at most 32 bubble quads; the orbital impact is uniforms and one include in a sphere shader that is already one draw. The cloud's blended fragments are **targeted** at 1.5 million at 720p, high (an estimate from Research's 3.1 million at 1,160 sprites; the real number needs a quiet machine and Performance's bench, Research's §7 recipe). Nothing runs unless the cue has fired, so the idle cost is zero.

## 8. Needs, risks, order

**Needs from the EP**
- **Legal:** confirm the 0.05 split between a small impact and a catastrophe light event (§1); see the storyboards at the worst frame; confirm that the skirt (a dark dust wall) and the lumpy bloom meet c06's ring and hemisphere lines.
- **Simulation (cues):** `tremor`, `breach`, `magma`, `blast_cloud`, `exo_impact`, `meteor` as Audio asks, plus a `cat_id` on each (a sim counter) and the world's `ash` as a read-only 0 to 1; the shot's landing as an event with its column (so a falling streak can draw on the sphere).
- **Rendering:** the grant in §6, and the magma surface's heat as a uniform I can read for the head's flare.
- **Camera:** that the window and the wide may share the uniform array.
- **Tools:** the five clips in §7, and a quiet-machine bench for the cloud's fill.

**Risks**
- **Fill rate on an old laptop** is the largest cost risk; the ladder (400, 260, 140 with a half-res pass, then an impostor) is the answer, and the cloud is budgeted as a set piece, never ambient.
- **The darkened sky** makes the same glow a larger step; the `ash` scale is a guess until the ash-1.0 clip is read.
- **The combined beat** (breach, then cloud) is where the 2 s rule will bite; the design lets a second event keep its body and lose its light, and a lost light is a design cost (the blast may feel less loud) that Game Design should know about.
- **A fly-past** at a mass collapse stays Camera's rule (steady wide). If Camera moves during the cloud, its size on screen changes and so does its area weight; the registry reads the camera distance (`cam_dist`), as it already does.

**Order (smallest first)**
1. The `cat` class and its checks, in the registry (needs no art and no cue).
2. The tremor's dust (the easiest; no light event; unlocks the first set piece the run has).
3. The blast cloud (the stateless shader, the ladder, the clips).
4. Magma's flare and bubbles (with World's magma and Rendering's surface).
5. The orbital impact include (with Rendering's sphere).
