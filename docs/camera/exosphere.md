# The exosphere: the camera for the run mode's 60 seconds above the atmosphere (Camera, 2026-10-16)

Owner: Camera and Cinematography. **Paper.** Nothing here is built. Asked by the EP for Game Design's run mode (`docs/design/run-mode.md`, section 3.2, the third catastrophe move): "a 60 s fight above the atmosphere, shots falling to the surface". Research's prototype (`docs/research/world-catastrophe.md` section 3) shows the orbital view works on the curved world; Legal's c01 to c05 (`docs/legal/catastrophe-and-city-screen.md`) bind it. Every number is a first value.

## 0. The short version

1. **The fight shot needs nothing new.** I flew the pair to 20,000 units in the real scene (`render/camera/tests/clip_probe.gd --scenario=exo`): the rig frames them exactly as at 3,000 (same zoom, same travel, the same layout changes); only the camera's height follows, under its clamp (`CEILING - CAM_Y_TOP`). The altitude zoom-out is capped at 0.69, so up there a fighter is drawn at about 5.9% of the screen height (42 px at 720p), the same as any fight in the sky. The planet below is Rendering's sphere (from 0.3 of a radius) behind the same camera.
2. **What is new is what the camera has to show that a fighter-scale shot cannot:** shots that fall 24,000 units to a surface that is out of the picture, the planet itself, and the fight coming down. Four additions, in order of cost: **the impact window** (the damage inset's machinery, pointed at the surface), **the wide** (an orbital establishing shot), **the descent** (the camera falls with the sent fighter, then cuts to the landing site) and **the return** (the pair coming down after the 60 s).
3. **Legal's c01 to c05 become camera rules**: no cut within 0.5 s of a catastrophe light event's peak; at most one impact framed every 2.5 s (so at most one in the window per 2 s window, c02 and c04); the window and the wide are wipes and dissolves, never cuts across a bright event; under Reduce flashing the window is a still frame; the fighters keep their size in the darkest sky (c05).
4. **It needs from Simulation** the exosphere's band and the shot's fall as events (a shot is on its way down and lands at x, in so many ticks), and from Rendering the sphere with its limb and a second camera at a surface point.

## 1. What the rig does at height, measured

`clip_probe.gd --scenario=exo --exoy=20000`: both fighters held at 20,000 units (300 units of drift), 300 ticks, seed 12345: mode sequence opening, split, closing, merged; cameras at x 90,550 to 89,845 and y 20,165 to 19,920; zoom 0.59 to 1.08; worst travel 0.046 (14 ticks over 0.03). Identical to the same run at 3,000 units in zoom, mode and travel; y alone differs by the altitude. So:

- **No ground rule applies** (the low frames, the foreground opening, the setdown hold, `LOW_AIR_DEAD`): there is no ground in the picture.
- **The clamp**: camera y is clamped to `CEILING - CAM_Y_TOP` = 23,800 (not exercised at 20,000); a pair flown to the ceiling will meet it, and I have not probed what the frame does there.
- **The layouts work** (split, closing, merged); a free flight with no gravity is more mobile than the ground fight (the pair moves in y too), so the vertical spread term of the zoom (`_pair_dy`) matters more; I would expect it to dominate. This is a first read on an idle pair; a flown one (the AI in free flight) is for the build.

## 2. The shots

### 2.1 The fight (S-A): the rig as it is
Space for a backdrop, the sphere's limb a curve in the lower part of the frame. Fighters at 42 px at 720p, tier-5 glows (VFX), trails. Nothing to build for the camera except the cuts' rule (3.1). Cue for Rendering: the sphere's limb should be below the pair in the frame at the usual anchor (the plane at 0.7 of the height); the rig's pitch is 0.

### 2.2 The impact window (S-C): a live view of what the fall did
The planet pays for every miss: a shot that misses falls to the column below its line and lands about 90 ticks later as a tier-5 impact (a crater, buildings, people). The fighters cannot see it (24,000 units down). The window is Orb's picture-in-picture of damage (`damage-inset.md`) pointed at the landing point:
- **Trigger:** the shot's landing, with the same score idea: size of the impact (tier-5 crater, the towers cracked, the share of the slice's people) against a threshold; **the largest impact in each 2.5 s window opens it, the others are not framed**; never two at once (cost, and c04: the window is a screen window).
- **Frame:** the inset camera at the landing x, level, at the ground, 3,000 units wide (the tier-5 crater is 3,000), looking up the column the shot came down; opens 0.2 s before the landing by the event's countdown, so the viewer sees the shot arrive (the falling glow is Rendering's and VFX's) and the crater open; closes 0.8 s after the shock ring is gone (2.5 s total).
- **Where:** the damage inset's rules (a thumbnail in the pane of the fighter who fired, top corner, under the HUD; the strip's band for the largest). In the exosphere both fighters are in the sky, so the window is the screen's own corner: top right for the shooter's right, as the damage inset puts it on the building's side, which here is "down": I would use the bottom corner nearest the pane's inside edge instead, since down is where the planet is; Rendering's limb and the window then read as one picture.
- **Flash (c02, c04):** the window's content is the impact, a catastrophe light event: **at most one per 2 s counted across the screen**, rising over 0.3 s (0.5 s reduced), falling over 1 s; under Reduce flashing the window is a still frame of the crater after the ring (taken 0.5 s after the landing) with no live flash; the fight's own picture never carries the impact's glow (it is far below). The window's open and close are wipes. Cost: one extra world render at inset size (0.3 ms desktop, 2 ms web at 4x), one at a time; the damage inset and this window are the same slot.

### 2.3 The wide (S-B): the planet itself
At fight scale the planet is a curve. The wide pulls the camera back to an orbital framing: the limb across the lower third, the sphere's lit side, the great circle of the arena as a band with the impacts' scars, the fighters as two glints with their trails (a marker ring around them if smaller than 12 px: UI's), and the 60 s clock. It is the establishing shot of the exosphere and a re-orientation, so:
- **When:** once on entering the exosphere (1.2 s), at the 30 s mark (1.0 s) and when the descent begins (1.0 s); never in an exchange; never over a catastrophe light event's peak (±0.5 s); the fight shot resumes by a 0.3 s dissolve (a cut under no setting that Reduce flashing does not already allow).
- **How:** it is not the rig's zoom (fighters at 4 px, the zoom floor refuses): it is **a separate camera, Rendering's orbital camera**, pulled back and tilted to the planet, cross-faded with the fight camera. Camera drives the fade and chooses the moment; Rendering draws it. The sphere is one draw call and the impacts are uniforms, so the cost is the camera's second pass for 1 s.
- **Reduced motion:** a still: the wide is held as one frame for 1.2 s, no slow pan.

### 2.4 The descent (S-D): the power send aimed down
"The fight comes down when a power send is aimed down: the sent fighter lands as the largest impact in the game." The sent fighter falls from the exosphere to the surface in a few seconds (the speed is Combat's; the intro's fall is 6,000 units in 0.6 s, this one is up to 24,000):
- **Fall:** the intro's *ride-along* shot (F1 of `varied-intros.md`: the camera falls with him) is the wrong shot here: it scrolls the world at 0.06 to 0.29 of the width a tick (measured, `docs/camera/beam-struggle.md` section 2) and for a longer fall. Use **a cut at the send to the landing site**: a fixed low frame on the surface at the landing x, the sky above, the sent fighter streaking into the top of the frame through the atmosphere; the streak is a body moving over a still background (no scroll). It opens 1.0 s before the impact (the fall's countdown) and holds through the impact and its dust.
- **The sender:** a short hold on him in the exosphere (his send), then the cut; the other fighter is not shown until the wide at the end.
- **Flash:** the impact is the largest catastrophe light event; it takes the window's rule (rise 0.3 s, fall 1 s, at most one per 2 s) and no other cut within 0.5 s of its peak. Under Reduce flashing the impact frame is held as a dissolved still after the ring.

### 2.5 The return (S-E): the pair comes down after 60 s
The same grammar as the intro's fall done as a pair: a cut to the surface, a low wide frame, both fighters landing with a gap (the intro's landing shots L1/L2), the ground first (the exosphere's band ends, the sphere fades back to the strip). The camera never rides the descent.

## 3. The rules Legal's conditions make for the camera

| Rule | From | What the camera does |
| :--- | :--- | :--- |
| 3.1 **No cut within 0.5 s of a catastrophe light event's peak**; all view changes in the exosphere are dissolves (0.3 s) or wipes | c01, c02 | the cut machinery asks the registry for "an event within ±0.5 s"; a cut that would fall there waits (at most 0.4 s) or becomes a dissolve |
| 3.2 **At most one framed impact in 2.5 s; one window at a time** | c02, c04 | the window picks the largest in its window; the others stay unframed (a dot on the sphere in the wide) |
| 3.3 **The window and the wide add no flash the register has not counted** | c01 | Reduce flashing: a still window, a still wide; ordinary: live with VFX's calm flag, in the required flash set with its own clips |
| 3.4 **The darkest sky** | c05 | the fighters keep their lane-colour contrast: the fight shot never zooms out below the pane size (42 px) in the exosphere; the camera has nothing to do with the rim light (Rendering's) |
| 3.5 **No camera fly-past a mass collapse** | Research | the descent and the window are fixed cameras, never a fly-by |
| 3.6 **Reduced motion** | camera-v2 | the wide and the window are stills; the descent is a cut and a held frame; no slow pan, no push |
| 3.7 **Casualty presentation** | c08 | the window frames the crater, the towers and the dust, never people (no bodies); the toll stays a count in the HUD |

## 4. What it needs

| Who | What |
| :--- | :--- |
| **Simulation** | the exosphere as a band: `S.game.exo` (a flag) or the pair's mean height; events `exo_enter`, `exo_shot {actor, x, y, vx, vy, land_x, land_tick, tier}` when a shot starts to fall (so the window opens 0.2 s ahead), `exo_impact {x, y, size, owner, crater, towers, people}` at the landing, `meteor_send {actor, target, land_x, land_tick}`, `exo_end {kind: meteor | time}` |
| **Rendering** | the sphere above 0.3 of a radius with its limb and its great-circle band; **an orbital camera** (pulled back, tilted) for the wide, cross-fadable with the fight camera; a second camera at a surface point for the window, with the atmosphere and a distant-structure level of detail; the pitch and field of view for the descent's low frame |
| **VFX** | the falling glow (a streak 90 ticks long), the impact's calm form, the window's `inset_calm`, the sent fighter's streak and the atmosphere entry |
| **Game Design / Combat** | the fall speed of a power send, the 60 s clock as an event, how many impacts a minute the exosphere is allowed (Legal's spacing: at most one in 30 ticks within 6,000 units of ground) |
| **UI** | the clock chip, the off-screen pointer to the opponent (the glints in the wide), the window's corner |
| **Legal** | storyboards of S-B, S-C, S-D at their worst frame (the darkest sky) before any of it ships |
| **Tools** | required-set clips for each (c01): the fight at height, the window with a landing, the wide, the descent; both modes; in the darkened sky |

## 5. Build order, behind a switch (`exosphere`, default off)

1. **The rig at height** (nothing to build): a sweep row that holds a pair at 20,000 and checks the same bounds as on the ground, and the clamp.
2. **The registry's "event within 0.5 s" rule** for cuts (also useful at the surface for the beam struggle's detonation).
3. **The impact window** on the damage inset's code (shared slot), against stand-in `exo_impact` events; the still mode.
4. **The wide** with Rendering's orbital camera: the fade, the schedule, the rule against peaks.
5. **The descent and the return**: the fixed low frame at the landing site; the countdown.

## 6. Open for Orb and Game Design

- Whether the fight in the exosphere is seen as a side-on fight with a planet behind (S-A with the wide as a punctuation, what this paper assumes) or as a fight on a planet seen from outside (the wide as the main shot): the second is a different game (fighters at 4 px) and I would not.
- Whether the sender of a meteor is seen falling at all (the paper cuts to the landing site, so the player sees the streak arrive and the crater, not the fall's start); the fall's start is the moment the player chose, so a half-second of it before the cut may be wanted.
