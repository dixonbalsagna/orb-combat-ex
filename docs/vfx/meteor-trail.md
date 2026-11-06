# The meteor trail: a fighter's own burn, from close up to a view 53,000 wide (2026-10-31)

Owner: VFX Director. **Paper only; nothing is built, no render file is touched.** For Research's stand-in in the prototype (section 9) and, later, a park.

Orb (docs/ep/vision.md, "Orb on zoom, power and the meteor launch", 2026-10-31): at the peak of both fighters' power, "a fully charged launch attack landing on a stunned or weakened foe … knocks them diagonally up at high speed, the camera dynamically zooms out and the knocked back character leaves a burning trail through the atmosphere as they shoot skyward, even if the fighter is only a few pixels at this zoom level if there is a visual cue like a meteor-trail left behind it would be a stunning show of power." And, on the beam (2026-10-30): "visually distinctive procedural shaders … composition should be determined by the fighter's energy fighting style, their current form, any other unique situations future fighters may possess".

## 1. What it is

The fighter's **own burn**: the body in the air at speed, heating the air it passes through and leaving a hot, cooling line of it behind. It is a ribbon along his real path, starting at his body and ending where it has cooled out. It is not a marker (no ring, arrow, icon or halo drawn round him; the fighter sits inside the head of the ribbon, which is widest just behind him), and it does not depend on the camera: the camera zooms out by its own rules (Camera's), and the trail only reads the zoom to know how many pixels a unit is.

**It is the existing trail taken up the power scale.** Today's trail (README, "Trails") is nothing below 40 bh/s and full at 110 (bh = 75 units). **Orb's ruling (2026-10-31, docs/ep/vision.md): "the entire burnup should be determined by the altitude, the speed, and the rule-of-cool. At high levels of power, maybe fighters should be able to leave a trail when they fly at max speed."** So there is no launch gate; any body burns by:

`burn = air(altitude) × smoothstep(burn_from, burn_full, speed) × cool`

- **`speed`** is the body's own speed, a launch's or a flier's. `burn_from` and `burn_full` are data in units a second (`data/vfx/meteor.json`): placeholders **3,500 and 10,000 u/s**, so a fighter's own max-speed flight (about 6,100 u/s) reads at about 0.35 and Simulation's launch of about 12,000 u/s (simulation.md section 10) at full. When Game Design rules the launch speed V, `burn_full` becomes `0.92 V`.
- **`cool`** (the rule of cool) is a data term, 0 to 1, summed and clamped: `tier` (the four tiers: 1 and 2: 0, 3: 0.3, 4: 0.7; a fifth tier, if the data ever has one, is a new row, not assumed here), `form` (+0.1 a form step taken, to 0.3), `charge` (+0.4 for a fully charged launch, from the launch event if Combat gives one). It is a `cool` block on the fighter's row, with `situations` as in section 5. At tier 1 or 2 it is 0, so ordinary fights never show a burn (Orb: "the camera would never zoom out this far"); a tier-4 flier at max speed leaves a faint trail (0.35 × 0.7); a fully charged launch at high power is 1.
- Nothing is keyed by name to "a peak launch"; the numbers are the power. If Combat gives a `peak` flag, a `situations` row can set `cool` to 1.

**Whose burn.** The launch event's `actor` is the **sent** body (Combat's convention, memory note "launch event: actor is the sent body"), so the trail follows `actor` and is composed from **his** look. One option for the first half second only: the strike's colour (the launcher's accent) as the *ignition* tint at the launch point, so the trail starts as the blow's colour and turns into his. Default off (`ignite_from: "self"`); an Orb call, section 8.

## 2. How it reads, close to far

Screen-space numbers at 1,920 px wide (1,280 px: multiply by 0.67). A fighter is 75 units tall. One burn at the largest power: core 0.9, body 2.2 and sheath 4.0 times a base width of 60 units (the beam look's own layer ratios, `docs/vfx/beam-look.md`), times 1.6 for a peak launch (the same 1.6 the heavy tell uses for the trail).

| View width | px per unit | Fighter | The burn as geometry | What the player reads |
| ---: | ---: | ---: | :--- | :--- |
| 1,500 | 1.28 | 96 px | core 123 px, sheath 490 px: **clamped to 160 px** (section 3) | A flaming plume with the form's texture: boil rings, facets, lances or slag gaps. Embers shed from the edge, lit air round it, the heat ramp readable along 400 px of its length |
| 6,000 | 0.32 | 24 px | core 31 px, sheath 123 px | A thick banner of fire the length of the screen, the texture still readable, fewer embers |
| 20,000 | 0.096 | 7 px | core 9 px, sheath 37 px | A glowing rope. Texture is gone as pattern and survives as **tone**: the boil is a slow brightness swell, the facets a hue mosaic, the lances streaks along the length |
| 53,000 | 0.036 | 2.7 px | core 3.1 px, sheath 14 px (raw); core held at 3 px, sheath at 12 | A single bright, coloured line with a soft sheath and a hot head, bending with the planet's curve, the fighter a dot inside it |

At 1,280 px and 53,000 wide the fighter is 1.8 px. The line is what Orb's "visual cue" is, so it is built never to drop below readable.

## 3. Thickness and brightness by distance (the rule)

Thickness is a function of **pixels**, not units, with the world width as its starting point:

- `w_px = clamp(w_world × px_per_unit, w_min, w_max)` per layer.
- Floors: core **3 px**, body 5 px, sheath **10 px**, **defined at a 1,280-px-wide screen and growing with width** (1.5 times at 1,920, so 4.5/7.5/15 there), never below that for a window narrower than 1,280. (Corrected 2026-10-31: I had them at 1,920, which left a 1,280 window at 2 px; the least sizes are in section 3b.) Ceilings: sheath **160 px at 1,920** (about 8% of the screen's width), body 80, core 40. The ceiling is what bounds the fill at close zoom (section 7) and the flash area (section 6).
- **Who burns (Orb, 2026-11-01, after a green column stood behind a fighter who had dived to the ground):** "a base-form fighter should never burn up." The burn is laid only for a body that is **sent** (state launched or dropped; a fighter flying under his own power never burns: the flight line is his, and is its own switch) and only for a **real high-energy send**: tier `min_tier` (4) or more, or a real meteor on the director's curve (DirArc, any tier). Data `send_only` (1) and `min_tier` (4). Plain launches reach about 850 to 1,150 units a second at any tier, under the burn's 3,500, so they never laid a ribbon; the column came from flying fast under his own power at tier 3 or 4.
- **The floors grow with the view's width** (the EP, 2026-11-01, after Camera's peak shot fired): at the meteor's peak shot the pane is 50,000 across and the fighters are about 2 px, so a 3 px core is a hair on a phone-sized thumbnail and the trail has to carry the picture. From 12,000 across the floors rise (smoothstep) to `wfloor_mul` times their value at 50,000 and past: core 3 to 9.6 px, body 5 to 12, sheath 10 to 16, at a 1,280-wide screen (data `wfloor_from`, `wfloor_to`, `wfloor_mul`). At that width the trail also stays hot: a point's colour and alpha cool by only `wfloor_hot` (0.25) of its age, so it does not darken and dim along its length, and the dim for being thinner than the floor is measured against the old floor. Alpha never passes what the trail's layers already allow; no new hue (the lane colour, no gold, white or red). It is the same floor, not a new line: no fade, no blur, nothing drawn that the trail did not already draw, and the ceiling still holds. Under 12,000 across nothing changes.
- **Below the floor it stops getting thinner and gets only slightly dimmer**: `alpha × (w_world_px / w_min)^0.5`, never below 0.6. So at 53,000 the trail keeps nearly its brightness per pixel, as a thin hot wire does.
- **Brightness is luminance-capped, not stacked.** The core is the lane colour lightened by a tenth at most (Art's rule: the core at most L* 86, never white). The sheath is mixed over the scene (capped by `glow_cap` 0.92, as the clash look found), never added: added over a bright sky it went white. No bloom, no tint of the sky.
- The whole thing is **one ribbon**: it does not swap to a different effect as the camera pulls out. Embers, filaments and gaps are geometry or shader detail that go sub-pixel and merge into the ribbon's tone as they would in life. Nothing cross-fades between zoom bands. (Orb rejected dissolves as transitions.)
- Altitude scale: the ribbon's **world width** shrinks with the fighter's speed ratio (a slow trail is narrower) and with **air**, so the plume is fat low down and a wire up high. The floors above keep the far view readable.

## 3b. Least sizes, 4,200 to 53,000 wide (for Camera's shot, 2026-10-31)

Camera's rule: at the widest the foe is about 2 px, found by the trail at least 3 px wide, and the launcher by where the trail starts, plus his aura and crater. Pixels at a **1,280-wide** screen (the smallest I design for; ×1.5 at 1,920). "True" is the size with no floor: foe 75 u tall, trail core 86 u (a peak launch: 0.9 × 60 × 1.6), sheath 344 u, aura about 120 u tall by 80 wide (the aura-plan's oval at tier 3 to 4; it grows a little with the form step).

| View width | px/unit | Foe (true) | Trail core (true → drawn) | Trail sheath (true → drawn) | Aura height (true → drawn) |
| ---: | ---: | ---: | :--- | :--- | :--- |
| 4,200 | 0.305 | 23 | 26 → 26 | 105 → 105 (ceiling) | 37 → 37 |
| 10,000 | 0.128 | 9.6 | 11 → 11 | 44 → 44 | 15 → 15 |
| 20,000 | 0.064 | 4.8 | 5.5 → 5.5 | 22 → 22 | 7.7 → 8 |
| 30,000 | 0.043 | 3.2 | 3.7 → 3.7 | 15 → 15 | 5.1 → **8** |
| 53,000 | 0.024 | 1.8 | 2.1 → **3** | 8.3 → **10** | 2.9 → **8** |

**The least sizes I will hold, at every width in the range:**
- **Trail core 3 px, body 5 px, sheath 10 px** (1,280 screen), at least 70% brightness per pixel for the core (the sqrt rule, floor 0.6 for the sheath). The core is the 3 px Camera is counting on.
- **Aura 8 px tall by 5 wide, his aura's own oval** (the tier's shape, scaled), lane colour at **0.30 alpha, mixed, never added**, behind the body. Under 20,000 wide it is true size, so the floor only works past 20,000. It is steady and shaped like him, a soft shoulder-and-crest oval, not a ring, disc or marker; it never goes under 0.30 alpha, never over his body's own colours.
- **Where the trail starts** is read from the ribbon itself: its tail end at the launch point is as bright and wide as its body (the tail narrows only at the end of its life, never at the start). The start is hot (the ignition tint, section 1) for the first 0.5 s of its age, so on a 53,000 wide the launch point still has a brighter 1.5-times-wider knot.
- **The crater** is the ground effect's (Earth's, the exchange's), not the trail's; it is drawn at its true size. At 53,000 on a 1,280 screen a bowl of radius 170 u is 8 px across, so only a launch that digs a tier-3 or bigger bowl will register at the widest; the launch point is more reliably read by the trail's start and his aura than by the crater. I have not measured the bowl's size at a launch.

## 4. How it glows through the atmosphere

Air density is data, `air(alt) = exp(-alt / H)` with a floor, `H` and the thin edge taken from the planet record (World), as a fraction of the atmosphere's depth so a bigger planet works. I don't have World's atmosphere height: the camera paper puts "above the atmosphere" at about 20,000 units on today's ground, so my placeholders are `H` = 0.28 of that depth and the burn ending at 1.0. **Needs from World**, section 8.

| Altitude | The air | The burn |
| :--- | :--- | :--- |
| Low, dense | Lit air round the ribbon: the sheath is **tinted by the sky behind it** (a mix toward the sky's lower band by `air`), widest, shed embers, a **bow wave** at the head: a short soft cone, 1.5 body lengths long, hugging the body's wake (a part of the ribbon, never a ring round him) | Full heat ramp, 100% width, the texture of his form clear |
| Mid | The sheath narrows with `air`; heat shifts from the hot tint toward his lane colour | 40–70% width; texture merges into tone |
| Edge of space | The sheath is a faint ionised line a few pixels wide | Core only, held at its pixel floor |
| Above | Nothing to heat. **A floor remains** (Orb: "enough to look cool when the camera dynamically zooms"; Research found 25% weak): `air_eff = max(air, 0.6)` for the core and body, so the core keeps **60% of its brightness and 100% of its pixel floor**, and the sheath keeps **0.4 of its width** (at least 10 px at 1,280), still scaled by `speed` and `cool`. His own energy leaving a clear wake of lane colour, with a hot head, where a real object would show none | Core, body and a narrow sheath, no embers |

The glow is local to the ribbon. No sky colour moves, no light is cast on the planet from the trail, and no screen-read shader is used at any level (the clash look's distortion needs one; this does not).

## 5. A look per fighter and form, from data

The same composition order as the clash look (`docs/vfx/clash-look.md`; the code is parked, so this section is the contract rather than a reference to live code), each step overriding the last:

1. **His lane colour** (Art's, `VfxAura.lane_color` from his aura, so colour-vision presets follow) and his **beam flavour** (energy.json: second tint hue shift at the same luminance, `pat`).
2. The `default` row, then the row for his **roster id** (lower case; the Anti-hero is `rival`).
3. The row's **`forms`** entry for his form step (`Fighter.form.step`).
4. Each of the row's **`situations`** whose condition holds (`{"read": "tier", "min": 4, "set": {...}}`, a dotted path off the fighter, plus `launch.charge` and `peak` if Combat provides them).

The trail shares the **`front`** and **`texture`** words with the clash, so one fighter's beam, clash and burn are one identity. A new fighter is one data row; a genuinely new pattern is one shader id and one name.

| Roster id | Colour (lane, hot tint, cool tint) | Front / texture | The burn |
| :--- | :--- | :--- | :--- |
| **protagonist** | cyan to azure (#8fd6ff), hot end the lane lightened by a tenth, cool end deep azure | wall / boil | **Broad and rolling**: widest of the roster (1.15), bubble rings travelling down the ribbon at 0.9 Hz at most, a soft braided edge; form steps add a second braid and 10% width each |
| **rival** (Anti-hero) | violet to magenta (#9a80d8), hue up to 320° | lances / facets | **Exact and cold**: a hard-edged needle (0.8 of the base width) with long straight filaments streaming back, a flat facet mosaic in the sheath; the line **lasts 1.3 times longer** and cools to a colder line, the least ember |
| **reference** | quiet neutral | plain / none | A plain steady ribbon, narrow, no texture |
| **empress** (parked kit; row only) | ivory (#f0e6c8) with a gold rim (#c9a227) | wire / none | A long **taut arc** with a thin gold rim line following it like a drawn wire; very little shed |
| **cyborg** (parked kit; row only) | slag orange (#e2742c) with grey (#8c9098) | sputter / none | **Broken**: gaps along the path, fixed in the world and moving with it (never flickering in time), heavy sparks, a duller core with a hot rim; a tier ≥ 4 situation widens the gaps' sparks |

Form and "other unique situations" map to levers already in the file: `width_k`, `braids` (second layer count), `ring_k`, `spike_k` (filament and spark count), `linger_k`, and the heat tints. A fighter whose power state matters (a fully powered form, a mounted weapon) is a `situations` row, not code. Not assumed: the Empress and Cyborg rows are rows only, marked so.

## 6. Flash, motion and the rules this must keep

Presentation only: it reads the fighter's pose and velocity, writes nothing of the sim, draws no random number, and is driven by `S.T`. The hash cannot change.

- **No dissolve, fade or wipe as a transition.** It begins as a length of zero and **grows with the fighter** (the ribbon is the path). It ends by **narrowing to a point, tail first**: each point's width falls to zero over the last 15% of its age, with colour held at its ramp value, so a tail burns out, not fades. No alpha ramps by time at a fixed place.
- **No full-screen flare, no screen tint, no blur, no screen read.** The largest area it covers is the sheath: at most a 160-px band about 1,900 px long at the closest zoom, which is about 15% of the frame and falls to under 3% by 20,000 wide.
- **A pixel sees a single slow cooling, never an alternation.** Brightness is a function of a point's **age**, monotone: the head passes (one rise), then the ramp cools over seconds. There is no pulsing in time. Travelling features (the boil rings, pulses of the lances) are slower than 0.9 Hz at any point, the clash look's number (Legal: 2 Hz, 1.5 Hz calm).
- **Lifetime floors.** No trail lives under 4 s (2 s under Reduce flashing, with the taper longer), so no pixel can rise and fall inside a second.
- **A flier near the threshold must not flicker.** With no launch gate the burn can cross `burn_from` on and off with his speed. It is smoothed in sim time (rise 0.3 s, fall 1.0 s) and a segment's width and heat are fixed when its point is laid, so a speed dip leaves a thinner stretch of ribbon, not a strobe. The ramp is a width and heat, never an on-off.
- **Launch's own flash is not the trail's.** The impact that sends him is already granted by the flash registry (`docs/vfx/flash-registry.md`); the trail asks for no weight because it begins steady.
- **Reduce flashing:** brightness cap 0.82 of normal, half the linger, ember sparkle off (embers steady and dimmer), the ring and pulse rates at 0.55 Hz. **Reduced motion:** no travelling features (the pattern is fixed to the ribbon and moves only as the fighter moves), embers off, no filament sway. Both still draw the full ribbon in his colour.
- **Legal:** under RL-119 and RL-120, the gate is at most 2.5 on the analyser, and no sensitivity run over 3. I claim nothing until there is a clip: the check is a scripted launch, a camera pull to 53,000 and back, **both modes, both sizes** (1,024 × 768 and 1,280 × 720), and the look gate's side-by-side (ADR 0010). Not a Legal clearance.

## 7. How long it lingers on the world

The path is stored in **planet coordinates** (x on the wrap, altitude), not on the screen, so it stays put as the camera zooms and as the turntable swings the world round the fighters; the view maps the points each frame. Segments crossing the seam split at it (shortest-arc wrap math).

Four phases, by a point's age in **sim seconds**, all in `data/vfx/meteor.json`:

| Age | Look | Width | Colour |
| ---: | :--- | ---: | :--- |
| 0 to 1.2 s | **Burn**: the hot tint, the form's full texture, embers | 100% | Lane colour lightened by a tenth |
| 1.2 to 4 s | **Cool** | 100% → 40% | Lane colour → his deep tint |
| 4 to 9 s | **Smoulder**: a thin line at its pixel floor, near-camera embers only | 40% → 25% | Deep tint, dimmer |
| 9 to 16 s | **Vapour** (High and up): a pale wind-sheared band, 8% contrast above the sky, no glow | 3× wider, sheared sideways by the world's wind | A desaturated tint of the lane |

A peak launch's linger is 12 s on the ladder's middle (Standard); the table is the maximum. When the **camera returns** to ground scale the part of the trail in view is real geometry with the shape the fighter made, drifting embers and a slowly widening band; the part over his head was always the same ribbon. The **point where he ends** (his fall, a landing, his coming back into the air) is not drawn by the trail: the impact is the sim's, and the trail simply ends at his last point.

Two things the trail does not do: it **leaves no scar on the ground** (the launch's crater is the exchange's, the landing's is the sim's), and it does not damage anything (no sim reads it).

## 8. Cost per quality level

Levels are the ladder in `docs/world/ring-any-angle/quality-range.md` (section 2): Performance, Low, Standard, High, Maximum, mapped to VFX `Q_LOW`, `Q_MEDIUM`, `Q_HIGH`, `Q_HIGH` and the new top tier it proposes.

| | Performance | Low | Standard | High | Maximum |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Ribbon points drawn | 32 | 64 | 96 | 128 | 192 |
| Layers | core + body | all three | all three | all three | all three + a second braid |
| Pattern (front, texture) | tone only, no noise | one noise lookup | the form's own | the form's own | + filaments |
| Embers (near zoom only) | 0 | 40 | 120 | 200 | 320 |
| Longest linger | 4 s | 8 s | 12 s | 16 s with vapour | 16 s with vapour |
| Sheath ceiling (1,920 px) | 100 px | 120 | 160 | 160 | 160 |
| Screen read | none | none | none | none | none |

**Draw calls:** the ribbon is one (a single mesh of ≤ 192 points × 3 layers; the layers are separate surfaces of one mesh), the embers go into the shard pool's one draw (inside its cap of 460, so 0 extra).

**GPU, arithmetic, not measured.** Fill is the cost, and bounded by the ceilings. Worst case, closest zoom, Standard: a 160-px sheath, a 80-px body and a 40-px core over about 1,900 px of ribbon on screen is about 530,000 px of fill, or 25% of a 1080p frame, over a few seconds. On the Radeon iGPU that is of the order of the clouds' overdraw (−3.8 ms off, `level-bench.json`), so **about 1 to 2 ms at Standard for those seconds**; the Performance level has two layers and a 100-px ceiling, about a third of it. At 20,000 wide the fill is a tenth, at 53,000 about 1%. No screen read, so no back-buffer copy. **Performance's bench is the measure**; the quality auto-step (below 42 fps for 2 s drops a level) is the lever if it is wrong.

**CPU:** one point per tick into a ring of 960, a stride by level (the fixed stride, so the curve does not shimmer when quality changes), a mesh rebuilt each frame from ≤ 192 points. By comparison with the existing layer (`update` 0.17 ms mean) it is of the order of 0.1 to 0.2 ms on this PC and about 1 ms on one five times slower, only while a trail is alive. Memory a few kilobytes. **Simulation cost: zero.**

**The web:** same, no threads needed. No new shader is more than the beam's.

## 9. For Research's stand-in (a thin one, to test the reading)

A polyline of the fighter's recent path in world coordinates with a point every 40 units; three layers drawn in screen pixels with the clamps from section 3; colour from age (hot lane lightened 10% at 0 s, lane at 1.2 s, deep tint at 4 s); width from age and a fixed air curve `exp(-alt/H)` with the 25% floor; the ribbon as three lines of widths `max(core,3)`, `max(2.2×core,5)`, `max(4×core,10)` px; a bright 5-px head dot **only if you must**, since the real thing has none (the fighter is the head). Look at it at view widths 1,500, 6,000, 20,000 and 53,070 and compare with section 2's table. The pattern (boil/facets/lances/gaps) is not worth the stand-in; the tone along the length is.

## 10. Where it would live (when built)

`render/vfx/meteor_look.gd` (data, composition, the heat ramp, the air curve: pure functions, tested), `render/vfx/meteor_view.gd` (the node: ribbon, embers, the path ring), `render/vfx/shaders/meteor_core.gdshaderinc` plus one thin shader per layer (reusing the beam look's tint and filament code), `data/vfx/meteor.json`, `tools/schemas/vfx-meteor.schema.json` (rates capped 0.9 Hz, 0.55 Hz calm; brightness cap ≤ 0.92) and a map row, fixtures, and `effects_check` cases. The hub reads the `launch` event (`actor` is the sent body), then follows the fighter; the node hangs on a view Rendering owns (a grant, as with the clash look).

## 11. Open, and what I need

- **Orb:** whose colours ignite the trail: his own (default) or the launcher's strike colour for the first half second (section 1)? The above-the-air floor is now 60% core and 0.4 sheath, up from 25% (`air_floor`, data); say if it should be brighter.
- **World:** the atmosphere's depth and a density curve on the planet record, and the wind direction for the vapour band.
- **Camera:** the zoom is theirs; the trail needs `px_per_unit` each frame (from the view's zoom and render scale), nothing else.
- **Combat:** a launch `charge` (full or not) for the `cool` term, and a `peak` flag if they want the trail forced; the body's speed already comes from the sim.
- **Art:** the heat ramps' hot and cool tints for each lane (the L* 86 cap on the core), and the Empress and Cyborg gold and slag choices.
- **Rendering:** the node's place in the view, `px_per_unit`, and the ladder level in the hub.
- **Performance:** a bench on the Radeon iGPU for the closest-zoom case at Standard.
- **Legal:** a flash reading when a clip exists; I claim none.
- **Not decided:** the vapour band (High and up) may not be worth its cost; a pass on the picture will say.

## 12. Built (2026-10-31, Orb's order: "a working version with the 3d world"; parked in docs/vfx/pending/meteor-trail/)

Behind its own switch, **off by default and byte-identical off**: `VfxHub.meteor_enabled` (`VfxLook.METEOR_DEFAULT` false). With it off the model never steps and nothing draws (the view node is hidden; the effects check asserts the model's clock stays at 0, and the old blade is only skipped while the switch is on). Files: `render/vfx/meteor.gd` (the model: data, rows, `cool`, `air`, the burn, the runs, planet coordinates, the ring's turn), `meteor_view.gd` (the ribbon), `shaders/meteor.gdshader`, `data/vfx/meteor.json` + `tools/schemas/vfx-meteor.schema.json`, the hub and trail-view hooks, and `_meteor()` in effects_check (39 checks).

- **Planet coordinates (the EP's order, on Simulation's field frame, `docs/world/ring-any-angle/simulation.md` section 11):** when the state has a `frame` (a field world), each point is kept as the planet direction it was laid at (`place`: the frame's point at strip x turned about the line by z / R) and carried to the pane by the inverse (`unplace`: the frame's strip x and depth); a turn of the frame, the turntable swing, maps every point again once, and a frame at rest costs nothing. On a world with no frame the points stay in the ring's own coordinates and the ring's turn (`arena_turn`) drops those beyond the carry, as for the scars; a field world's points are left alone by it. **The two functions restate `SimField.placeIn` and `strip` from the frame's seven numbers** (the park `docs/architecture/pending/field-frame/` is not on main, so they could not be called), held by a round-trip check on a stand-in frame; **when the frame lands, the cross-check against `SimField` is the first thing to run**, and `VfxMeteor.place` and `unplace` become two calls if they match. The camera's interpolation between two ticks of a swing is not done: a swing of 4 degrees a tick would step the trail a few thousand units a tick against the fighters' interpolation, so the first look at a swing is a thing to watch.
- **One trail (the EP's call):** while a body's burn is the trail, the old white blade is not drawn for him (`blade_on` 0.3 of burn, back below `blade_off` 0.18, so it does not flicker); his wind marks and break ring stay. With the switch off the blade is drawn as ever.
- **Burn = air x speed ramp x cool, all data**, floor 0.6 above the air, four tiers, as in sections 1 to 5. `cool` reads `tier`, `form.step` and the row's situations. A burn becomes strength as `alpha = layer alpha x burn x bright_k` (1.6: a tier-4 burn tops out at 0.7 times the air, so it needs more than 1 to read as a full trail once the white blade is gone).
- **Look per fighter:** roster id, form step and situations from `data/vfx/meteor.json`; the Protagonist a rolling boil, the Anti-hero lances and facets (the narrower needle, 1.3 times the linger), rows for the Empress and Cyborg that nothing reads yet.
- **Pixel floors and ceilings** at a 1,280 screen (core 3 px, body 5, sheath 10; ceilings 27, 53, 107), growing with width; the effects check asserts the core stays at 3 px or more across 4,200 to 53,000 wide.
- **Quality:** the hub's three levels (`Q_LOW` to `Q_HIGH`): 32, 64 and 96 points drawn, a lay spacing of 800, 500 and 300 units, a linger of 4, 8 and 12 s. The five-level ladder has no code behind it yet.
- **Reduce flashing or reduced motion:** the linger halves (never under 2 s), the brightness is 0.82, the pattern rate 0.55 Hz and, under reduced motion, still.

**Not built:** embers, the vapour band, the aura's pixel floor (3b), the `ignite_from` option and the sheath's air scaling. **No far zoom exists in the game's camera yet**, so nothing here has been seen at 53,000 wide: the floors are proved by number, not by picture (the pictures are at the game's own zoom, the widest it frames a launch).

**Flash** (Tools' analyser, the scripted launch scene: both at tier 4, the AI sent diagonally at 12,000 u/s from tick 120 and every 300 ticks, 600 frames, 1,280 x 720, the game's own camera and split): **the first build read 3 in both modes against a baseline of 2.5 and 2.5** (the baseline is already at the gate). A ribbon's flash weight follows its area, so a ribbon that is wide on screen is dimmed (`wide_k` 0.3 beyond 1.5 times its pixel floor, full at 5; a thin far ribbon keeps its full strength). Sweep, normal mode, with the old blade still drawn: alpha x0.6 3; x0.35 2.5; alpha x0.6 with width x0.6 2.5; the ceilings at 0.65 or 0.5 of theirs 3; the area rule at 0.4 with width x0.8, at 0.5 with width x0.6, and at 0.3 alone 2.5. With the blade off and `bright_k` 1.6 the area rule at 0.3 reads 2.5 and at 0.6, 0.8 or 1.0 it reads 3. **Shipped (`wide_k` 0.3, `bright_k` 1.6, blade off): normal 2.5, reduced 2.5, against baselines of 2.5 and 2.5, PASS.** Not a Legal clearance, and one scene: the next read is the nightly seeds with the switch on. The price of the area rule: at the game's own close zoom the burn is a soft violet band, much quieter than the white blade it replaces; it is at its strongest where it is thin, and the far view is where it is meant to be read.

**Cost:** not benched. The arithmetic of section 8 stands; the view rebuilds one ArrayMesh a fighter each frame from at most 96 points x 3 layers.

## 12b. Two data sets, judged by a page word (the EP's order, 2026-10-31: "the glow should be enough to look cool"; ADR 0010: no test result justifies a worse look)

The quiet set of section 12 passed the flash gate by dimming; the EP asked for the loud one beside it, stated with its flash reading, so Orb judges both. Both are in `data/vfx/meteor.json` as `profiles`, and **the preview's page word picks one**: `?meteor=quiet` (or `?meteor=1`) the base values, `?meteor=loud` the loud set, no word the trail off (the public build's values come after Orb's choice). The word is read only where UI honours its own bypass words (`UiHud.bypass_allowed`: a local page), so a public page's link cannot turn it on; **a hosted private preview that is not a local page needs the word added to UI's allow list**, which is a one-line call for the EP.

| | Quiet | Loud |
| --- | --- | --- |
| A ribbon wide on screen | dimmed to 0.3 of its strength (`wide_k`) | **full strength** (`wide_k` 1.0) |
| The camera sweeping the world fast | no change | **dimmed to 0.1** from 0.6 to 3 screen widths a second (`pan_k`, `pan_from`, `pan_to`) |
| Everything else | the base | the base (a burn is strength x 1.6, the blade off) |
| **Flash, the scripted launch, normal / reduced** | **2.5 / 2.5 PASS** | **2.5 / 2.5 PASS** (baselines 2.5 / 2.5) |

**How the loud one passes, and what the first tries taught.** Run with full strength and no other change it read 3 (OVER) in both modes. The first fix I tried, a heat-up ramp over 0.08, 0.15, 0.3 and 0.6 s after the head lays a point (`ramp_s`, so no frame sees a whole ribbon edge change at once), changed nothing: all four read 3. The events the loud ribbon added were not at its head but 2 to 4 s after the launch, in the **other fighter's pane**: a saturated band, anchored in the world, sweeping across a pane whose camera rides along a fast flight, which is a whole-pane luminance change the analyser counts however slowly the ribbon itself cools. So the fix is where it sits in motion, not how strong it is: the ribbon dims **by the camera's speed across the world** (`pan_k`). At 0.1 the clip reads 2.5; at 0.25 and 0.5 it reads 3, and looser thresholds (from 1.2 to 4, from 2 to 6) read 3 too. The values are the loosest that pass on this scene.

**The price, said plainly:** loud is vivid whenever the camera is calm, but **during the launch's own whip the trail is nearly gone from that pane** (the camera rides along at up to 0.3 of a screen width a tick), so the first frames after a launch show little of it, and it comes up as the camera settles; quiet shows a faint band throughout. The sheet `docs/vfx/img/meteor-trail/meteor-off-quiet-loud.png` has the switch off, quiet and loud side by side at six moments. If Orb wants the launch's first second loud as well, the open ways are not a dimmer ribbon: a shorter whip (Camera's), the trail drawn only in the pane that follows the burning fighter, or a clip that reads 3 and a Legal call (RL-208 makes reduced mode the take-down trigger, so I would not).

The experiments' scratch options (alpha, width, ceilings, ramp and pan values from the page) are not in the park; `ramp_s` and the pan keys are, in data, off by default in the base.

## 13. Legal's conditions on the trail (RL-222, 2026-11-01)
Legal: yes, with conditions (a trail along the real path is not mark 3, the upward flame aura), checked at the look gate. Where each stands:
1. **The ribbon starts at the body, trails behind it, never wraps or rises as tongues; at close zoom the head's width is capped** so it does not read as a body-wide flame: **built** (`head_cap_bh` 0.6, `head_len_bh` 4.0, data). Within a few body heights of the fighter the sheath is at most 0.6 of a body height wide (58 px of a 96-px body at a close view; the body and the core in the layers' ratio), widening to its ceiling over four body heights back; a check holds it. The cap lets the pixel floor stand, so a body a few pixels tall at a wide view keeps the thin line Orb asked for.
2. **If it ever reads as a flame hugging or rising off the body, it counts as mark 3 at that tick and the two-marks cap applies:** the look gate's stills are where this is judged; the cap above and the ribbon's drawing behind the fighter's plane are what keep it a trail.
3. **At touchdown** the trail has narrowed from the tail (the taper) and the heat has cooled to its deep tint; the landing's own marks are the sim's (rubble ring with wind, crack): nothing here adds a scream, lightning on the body, a hair change or a shouted flash.
4. **The ignition tint is never gold, white or red:** the `ignite_from` option is not built, so there is no ignition tint at all. If it is built, it is the strike colour or his own lane colour, passed through `VfxAura.lane_color` (which already swaps fire, gold and white for Art's accent), and has no shouted name.
5. **The trail shares his lane colour and the L* 86 core cap:** built (the colours are `VfxBeamLook.tints` of his lane; the core is the lane lightened by a tenth at most; never white).
6. **The look gate:** the side-by-side and both flash modes, as in RL-221: the sheet and the clips are in docs/vfx/img/meteor-trail; the flash clips are required before anything public.
