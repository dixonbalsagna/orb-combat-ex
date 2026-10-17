# World catastrophe: can our engine do Orb's boss fight, and how?

Research & Prototyping, 2026-10-16, for the EP's brief (Orb's words: docs/ep/vision.md, "Orb on the stored planet"). A feasibility study with headless prototypes. Nothing in `sim/`, `render/` or `data/` changed. Read against HEAD b1fd310d.

- **Prototypes:** `docs/research/world-catastrophe/`:
  - `sim_probe.gd`: the sim side, run in a clean HEAD export;
  - `proto/`: a standalone Godot project with the four render scenes, built for the web;
  - `tools/clips.sh`: the flash clips;
  - `img/`: the stills. None shows character art; the orbit scene's two "fighters" are dots of light.

> **One measurement caveat.** The PC was saturated for the whole session: 85 to 100% CPU, about 24 Godot and 12 Chrome processes from other sessions. Under the 2026-10-12 rule, **every timing taken here is invalid**: not reported as a number, only as an order of magnitude marked "invalid". The counts and checks below do not depend on load and stand: depths, flows, budgets, events, draw calls, triangles, overdraw and flash verdicts. The timings should be re-run with one command on a quiet machine (section 7).

## Answer in short

**Yes. All four effects fit the engine, the Compatibility renderer and the web build. None needs a new engine feature.** Two need new sim state, both small and deterministic:
- **magma:** a depth and a heat per terrain column, the twin of `S.water`;
- **a planet atmosphere:** 129 numbers.

Two are mostly presentation on systems that already exist:
- **the orbital view:** the renderer already curves the world and turns the sky to space as the camera climbs, and fighters can already fly about one planet radius up;
- **mass collapse:** the sim already has an implode mode and event folding.

| Effect | Sim | Render | Flash check (prototype, normal and reduced) | Lead owner | Hardest part |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1 Magma through the crust | New: a breach rule plus magma columns (depth, heat), flowing like water and cooling into rock | A glowing surface like the water grid; heat on the walls; bubbles and smoke (VFX) | **PASS**: 0 flashes, 0 red | World | Deciding what magma does to a fighter |
| 2 Mushroom cloud, the planet's sky darkens | New: a planet atmosphere state (64 cells, 2 layers, 1 global veil), updated at 1 Hz | A billboard cloud; the sky driver's "ruin" read from the atmosphere; world light dims | **PASS** | VFX for the cloud; World plus Art for the sky | Fill rate on old laptops (3 million fragments a frame at 720p) |
| 3 The exosphere fight seen from orbit | None new: blasts and craters as today; altitude is within the flight ceiling | A planet sphere (the stored planet) above about 0.3 planet radii; impact glows and rings drawn on it | **PASS** | Rendering, with Camera | Mapping the arena's live damage onto the sphere |
| 4 Many towers down at once | A "catastrophe" set-piece allowance, and a blast rule that may finish buildings | Falls, dust and debris, already batched | **PASS** with a steady camera; a fly-past is today's worst clip | World, with Game Design | Today's rules stop it: one blast cannot level a building |

## 0. The scale we are working at (measured from the code)

- **The planet.**
  - The arena is a great circle 153,600 units round, so the planet's radius is **24,446 units**.
  - A fighter is 75 units tall, so the planet is about 326 fighter heights in radius.
- **The flight ceiling** (`SimConst.CEILING`) is **24,000 units, about one planet radius above the ground.** The exosphere is already inside the flight envelope. Orbital altitude is a camera and rendering question, not a physics change.
- **How deep a cut can go.**
  - The deformation floor (`WorldCrater.DEFORM_FLOOR`) is **2,080 units (28 fighter heights)** below the original surface.
  - The probe asked `carveSegment` for a 6,000-unit-deep cut along 160 columns. It got exactly 2,080, with 142 of the 160 columns at the floor.
- **Craters.** The largest crater bowl is 8,320 units across (`R_MAX`), measured 1,830 units deep.

## 1. A beam that cuts through the crust to magma

**Approach.**
- **The breach.** Treat the deformation floor as the base of the crust. A column a world-catastrophe beam has dug to the floor is *breached*, so no deeper heightfield is needed.
- **The magma.** It rises at breached columns toward a head below the old surface (35% of the floor's depth). It flows along the cut by the same saturated two-column exchange the water model uses (old state in, changes out, so order does not matter), carries its heat, cools, and sets into rock (back into `S.deform`) when cold. No random draws.
- **In the prototype** (`sim_probe.gd`, on a real match's terrain):
  - the magma stood **610 units (8 fighter heights) below the surface**;
  - it lit 165 columns, along the whole 5,120-unit cut;
  - it stayed liquid for the simulated minute.

**Sim or render.** Put it in the sim. The reasons:
- Fighters will stand in it, be knocked into it, or be burned by it.
- Its rock must persist across a run.
- Replays and snapshots must hold it.

It is the twin of `S.water`: two float arrays plus a window list, run every second tick, only in windows around a breach. If Game Design wants it to be scenery only, it could be render-only, derived from `S.deform` at the floor and the time since the breach. But it would then not persist exactly or interact, and that only saves a little.

**Render.**
- **The surface.** Drawn like the water grid, on the fighter plane's profile. The foreground rule then lets the cut read from the side as a lit notch (`img/magma.png`).
- **Shading.** Slow-moving crust plates that never blink, with heat tinting the walls.
- **VFX.** Bubbles that grow and fade (no pop), and smoke.

**Flash rules (built in and checked).**
- Every colour keeps R/(R+G+B) under 0.8, so nothing is a saturated red.
- The surface "breathes" at 0.19 Hz by 8% (4% with Reduce flashing).
- Bubbles fade over 0.4 to 1 s.
- **The analyser:** 0 general flashes and 0 red, in both modes, over 5 s.

**Cost.**
- *Sim:* about 400 columns of flow every second tick. **The timing is invalid** (saturated); its order is tenths of a millisecond per tick on desktop GDScript. Estimated ×3 for an old laptop and ×2 more on the web: still about 1 ms. It only runs while a window is open.
- *Render:* 5 draw calls and 22,000 triangles for the whole scene. Effect overdraw: 1.3 layers mean, 10 at most, 1.2 million fragments at 720p. That is light.

**Owners.**
- World: the breach, the magma state, cooling, persistence.
- Rendering: the surface and the heat light.
- VFX: bubbles, embers, smoke.
- Game Design: what magma does to fighters and civilians.
- Combat: which abilities have a world-catastrophe variant.

**Smallest first build.** In scratch, World adds the breach flag and the probe's magma model to one story-boss scene. Rendering draws the magma with the water grid's code and a new material. One catastrophe beam variant cuts to the floor.

## 2. A mushroom cloud, and a planet sky that darkens

**The cloud** (VFX, presentation).
- **Shape.** Billboard sprites in three groups: a stem, a rolling cap (a torus whose minor angle turns with time) and a ground skirt. They rise and spread on fixed curves: 14,000 units up over about 20 s.
- **Colour.** Fire colour fades to smoke as the heat falls (`img/cloud-fireball.png`, `img/cloud.png`).
- **The fireball.** No frame-wide flash: the fireball grows and brightens over 0.6 s (1.0 s reduced) and stays a small share of the screen.
- **The sky never flashes. It only darkens.**

**The planet's sky** (World state, read by Art's sky).
- **The state.** A planet atmosphere of 64 cells round the lap (2,400 units each):
  - a **low layer** the wind carries, raining out with a 5-minute half-life;
  - a **high layer** carried round the planet in about 2 minutes;
  - a **global veil** fed by the high layer, decaying over 30 minutes.
- **What a cloud injects:** 60% into its own cell's low layer and 40% into the high layer.
- **The darkness the sky reads:** `1 - exp(-(low + 1.6 high + 40 veil))`.
- **What the probe shows** (`sim_probe.gd`):

  | Clouds so far | Planet-wide darkness |
  | :--- | ---: |
  | One (after 3 min) | 0.12 |
  | Two | 0.25 |
  | Three | about 0.40, then a slow fade over half an hour |

  The cloud's own cell goes to about 0.6 at once. All of these are tuning knobs.
- **Its size.** 129 numbers, updated once a second. Its cost is negligible (the probe's mean is tens of microseconds per update, invalid but irrelevant at this size).
- **Why it should be sim state, not render:**
  - it persists across a run's stages (Orb);
  - a replay seek and a snapshot must restore it;
  - a hashed tiny state is cheaper than re-deriving it from the event history.
- **How the renderer reads it.** `SkyDrive` already takes the sky "toward smoke" with ruin, dims the world light per layer (`wl_mood.ruin`), and limits how fast any sky colour can change. The atmosphere's darkness becomes ruin's input, so the change can never be fast.
- **Between stages,** the run keeps the state and decays it by the gap's length.

**Flash.** The prototype's clips include the most aggressive version: a bright ground shock ring, 45% opacity, sweeping outward (`img/cloud-fireball.png`). **The analyser passes both modes with 0 flashes.** Each pixel brightens once and fades over seconds, and the fireball ramps up. A closer camera makes the ring larger on screen and its sweep faster, so the ring should stay dim (the prototype's `ring=soft`, 12%) as a margin. That is VFX's call, with Tools' clips.

**Cost.**
- **Fill rate is the risk.** The full-grown cloud covers its area 3.4 layers deep on average, up to 77 at the core. That is **3.1 million blended fragments a frame at 720p, about 7 million at 1080p.**
- An old laptop's integrated GPU blends perhaps 1 to 2 billion fragments a second in practice *(estimate)*. That gives **about 2 to 7 ms of a 16.7 ms frame**: affordable for a set piece, not for a cloud on screen all match.
- **The levers:**
  - fewer, larger sprites with a noise texture (about 400 in place of 1,160);
  - a half-resolution pass for the cloud;
  - beyond a set distance, an impostor (a few textured quads).
- **The CPU side:** the prototype rewrites 23,000 floats a frame in GDScript. Moving the curves into the vertex shader (stateless, as the engine spike's particles did) brings that to zero.

**Owners.** VFX (the cloud); World (the atmosphere state and its persistence); Art and Rendering (the sky and the world light reading it); Tools and Legal (the clips).

**Smallest first build.**
1. World adds the atmosphere state behind a switch, with its 1 Hz update and the run hand-over.
2. Art connects it to `SkyDrive`'s ruin.
3. VFX builds the cloud as a stateless vertex-shader effect, with a sprite budget.

## 3. Fighters in the exosphere, explosions on the surface far below

**What already exists.**
- Fighters can fly to 24,000 units, about one planet radius up.
- The renderer curves the world as the camera climbs (`bend.gdshaderinc`: geometry sags by `bend * x²`). The sky's glow thins to a rim, and space and stars appear (`docs/rendering/README.md`, "One world to the horizon").
- Ground and sea are drawn to 12,000 units behind the fighter plane.

**What breaks.**
- The bend is a parabola. That is fine while the view is small next to the planet. At orbital altitude the view is about one radius wide, and a parabola no longer looks like a sphere.
- Behind the strip there is no planet: the arena is one great circle of a stored planet (World's `planet-slice.md`), and the rest exists only as a function.

**Approach.**
- **A planet sphere.** Above about 0.3 R, the far world cross-fades from the bent strip to a sphere drawn from the stored planet (`img/orbit.png`).
  - Colour comes from World's planet function, evaluated on the GPU. It is render-only, so it need not match the sim bit for bit.
  - The arena's live state is drawn onto the sphere's great-circle band: craters, scorch, magma and impacts, through a 4,800-texel strip texture, the same data the ground already uploads.
- **Blasts from orbit** are ordinary sim shots and craters (`WorldBlast`, `WorldCrater`) at the column below. Seen from far away, the impact is a glow and a shock ring on the sphere, plus the scar that stays.
- **The prototype's planet:** a 192 × 96 sphere (48,000 triangles), an atmosphere rim, and up to 8 impacts in the shader. It is 4 draw calls with negligible overdraw.

**Camera** (Camera's call).
- At orbital altitude the fighters are a few pixels, so the read rests on their glow trails and on the impact.
- An inset or a cut to the surface for each big impact is the strongest tool. Camera already has an inset pane.

**Flash.** Each impact rises over 0.25 s (0.5 s reduced) and decays over 1.6 s. Its area is small from orbit. **The analyser passes both modes with 0 flashes, six impacts in 10 s.**

**Cost.** It is cheap:
- the sphere is one draw call;
- impacts are uniforms;
- the strip texture is already uploaded for the ground.

The work is integration: the cross-fade, and drawing the arena's state onto the sphere.

**Owners.** Rendering (the sphere and the hand-over from the strip); Camera (orbital framing, the inset); World (the planet function on the GPU); VFX (streaks, impacts); Encounter and Combat (exosphere moves and AI).

**Smallest first build.** Rendering, in scratch: the sphere above 0.3 R, cross-faded with the strip, with the arena's crater strip drawn on its band. Then Camera's framing pass.

## 4. Large-scale destruction at boss tier

**Measured on the real sim** (a match on seed 1: 118 buildings, 36 towers; `sim_probe.gd`):

| Towers brought down in one tick | Fall events | Fx events | Deaths | Evacuated |
| :--- | ---: | ---: | ---: | ---: |
| 5 | 5 | 20 | 234 | 0 |
| 10 | 10 | 43 | 270 | 299 |
| 20 | 20 | 93 | **270** | **746** |

- **The collateral budget holds by construction.** Deaths stop at 270, which is the tier-4 budget (15% of a 60 s window × 1,800 people). Everyone else evacuates. A catastrophe cannot massacre a city unless the rules say so.
- **Today a blast cannot level anything.** City-scale explosions of radius 3,000, 6,000 and 12,000 units at tier 4 **levelled 0 buildings**. The cause is the `leaveFrac` rule: one blast leaves a standing building with a share of its hit points, and the next takes it. That is right for normal fights and wrong for a world catastrophe.
- **The largest crater** is one big dig in one tick. Timing invalid; order: ten milliseconds or more on desktop. That would be a visible hitch on an old laptop. It should be spread over a few ticks, or run during a set piece's pause (`SimPause`).

**Approach.**
- **A "catastrophe" set piece** in `WorldCollateral.EVENT_ALLOW`, beside slide, chain, landslide and quake. It borrows its own allowance, unlocked by mode:
  - versus: at the top tier;
  - story: only when the encounter allows it (Orb's ruling, 2026-10-11).
- **A blast flag** that lets a catastrophe finish buildings, ignoring `leaveFrac`.
- **The existing implode mode,** which already orders falls by distance and caps the events (`IMPLODE_EVENT_CAP`), with `fallFold` for the rest.

**Render** (`img/collapse.png`).
- **The prototype:** 30 of 60 towers fall over 2.6 s, ordered by distance, with 480 dust sprites and 3,000 debris cubes.
- **The cost:** 5 draw calls, 38,000 triangles, 1.2 layers mean overdraw, 1.1 million fragments at 720p.
- The game's renderer already batches buildings, debris and crowds as MultiMeshes, so the counts carry over.

**Flash.**
- Today's game has its worst clip here: the camera flying past collapsing facades (4.5 flashes, `docs/tools/flash-check.md`).
- The prototype keeps a **steady, wide camera**, grey dust, and a dim epicentre glow. **The analyser passes both modes with 0 flashes and 0 red** (section 6). So the risk sits in the camera's behaviour, not in the falling itself.
- **The rule to keep:** no camera fly-past in a mass collapse, and buildings' windows go dark in one step, never blinking.

**Owners.** World (the catastrophe allowance, the blast flag, spreading big digs); Game Design (where it is unlocked, and the budgets); Rendering and VFX (falls and dust at scale); Camera (no fly-past).

**Smallest first build.** World adds the set piece in scratch, with a probe that brings a whole district down at tier 4, checks the budget, the event cap and the tick time, and keeps the goldens unchanged with the switch off.

## 5. Costs, desktop to web

| | Desktop (measured counts; timings invalid) | Old laptop *(estimate)* | Web build *(estimate)* |
| :--- | :--- | :--- | :--- |
| Magma flow | Under 1 ms a tick while a window is open | About ×3 | About ×5 (wasm GDScript) |
| Atmosphere | Negligible (129 numbers, 1 Hz) | Negligible | Negligible |
| Mass collapse, one tick | A few ms for 20 towers; a max crater is the spike | A visible hitch unless spread over ticks | Same, worse |
| Cloud rendering | 3.1 million fragments at 720p | 2 to 7 ms a frame | As the old laptop on the same GPU |
| Orbit rendering | 1 draw call for the sphere | Light | Light |
| Draw calls, whole scene | 4 to 5 per scene in the prototype | | |

The web build's runtime is the same 39.5 MB wasm, so the prototypes add nothing to the download.

## 6. Flash: what makes these safe, and what was checked

Each effect has a hard rule against a frame-wide flash and no saturated red. With Reduce flashing on, every brightness swing is halved or slowed.

| Clip (640×360, 60 frames a second) | Frames | General flashes | Red | Verdict |
| :--- | ---: | ---: | ---: | :--- |
| magma, normal / reduced | 301 / 301 | 0 / 0 | 0 / 0 | PASS / PASS |
| cloud (bright ring), normal / reduced | 300 / 300 | 0 / 0 | 0 / 0 | PASS / PASS |
| orbit, six impacts, normal / reduced | 660 / 660 | 0 / 0 | 0 / 0 | PASS / PASS |
| collapse (30 towers, steady camera), normal / reduced | 301 / 301 | 0 / 0 | 0 / 0 | PASS / PASS |

The wording is Legal's, for exactly this kind of result: "An automated flash check based on WCAG 2.3.1 (general flash, red flash and area), run on recorded gameplay, found no failure." These are prototype clips, not the game. The real effects need their own clips in Tools' set, at the game's camera distances and with fighters on screen.

## 7. Re-run the timings on a quiet machine

From the repo root, in a clean HEAD export (`git archive HEAD | tar -x -C <dir>`, then `--import` there):
- `godot --headless --path <dir> -s res://docs/research/world-catastrophe/sim_probe.gd -- magma atmo collapse` (copy the script in first; the folder carries a `.gdignore`);
- `bash docs/research/world-catastrophe/tools/clips.sh <out>`, then `node tools/flash/analyse-frames.js <out>`.

## 8. Recommended order

1. **Atmosphere state and the sky** (World and Art). The smallest build with the biggest visible change. It also gives runs their memory of a ruined sky.
2. **The catastrophe set piece for collapse** (World and Game Design). The rules are what stop it today, not the engine.
3. **Magma** (World, Rendering, VFX), for the first boss variant.
4. **The cloud** (VFX), with a sprite budget and an impostor.
5. **The orbital sphere** (Rendering and Camera). Most of its parts exist; the integration is the work.

## Risks

- **Old laptops and phones:** a cloud or a dust storm in the foreground all match would cost the frame. Budget them as set pieces.
- **The flash gate is per scene, not per effect:** a catastrophe at close range, with fighters, beams and the camera's own cuts, needs Tools' clips before it ships.
- **Determinism:** magma and the atmosphere are new hashed state, so the goldens move when they are switched on. They are kept dormant behind switches until then.
- **Timings:** every timing in this study is invalid. The machine was saturated all session.
