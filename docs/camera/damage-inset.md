# A live inset of the damage: a dodged beam that hits a skyscraper behind you (Camera, 2026-10-16)

Owner: Camera and Cinematography. **Paper.** Nothing here is built. Asked by the EP from Orb's homework 5 (docs/ep/vision.md, "Orb answers homework 5"): "dodging a beam that hits a skyscraper behind you should give a live picture-in-picture view of the damage, depending on how significant it is". When it opens (a significance threshold), where it sits, how long it stays, how it shares the split screen, the flash and cost limits. Every number is a first value and is marked when it wants a measurement.

## 0. The short version

1. **It is a second camera on a place, not on a fighter.** The panel strip (rule-of-cool-shots.md row 11) already draws a second view of the live world with Rendering's inset pane; the damage inset points the same pane at the building, framed to the building's width and height. One inset at a time, whichever kind.
2. **It opens when a dodged beam damages a structure and the damage is worth seeing and is not already in the picture.** The dodge is the `beam_outcome` of kind dodge; the damage is `building_stage`, `floors_fall` and `building_fall` events within 2 s of it that the beam caused. A significance score decides; below the threshold nothing opens.
3. **Size follows significance.** A corner thumbnail for damage (22% of the width), the strip's band for a collapse. It sits in the dodger's own pane, on the side the building lies, and never crosses the divider.
4. **It stays while the damage is happening**: at least 1.4 s, at most 4 s (6 s for a collapse), and closes 0.6 s after the last damage event.
5. **It is the only part of the picture the flash register does not see**, so it carries its own rule: under Reduce flashing (the default) it is a still frame, and in the ordinary mode the inset draws the world's flashes at a cap. It costs one extra world render at inset size (0.45 ms on desktop, about 3 ms on the web at a 4x slowdown for the strip's size), which is why there is one at a time and a ration.
6. **What it needs:** the cause on the damage events (which beam), and a calm flag for the inset's view from VFX. Section 7.

## 1. What exists

| Piece | Today |
| :--- | :--- |
| The panel strip | A slanted band over the live view, 56% of the width and 20% of the height, opened in 0.08 s and shut in 0.12 s, drawn by Camera's compositor from `SplitFrame.panel` and Rendering's inset pane (`make_inset`, `inset_view`); top band (19% to 39% of the height) where UI's HUD leaves it whole, else the bottom band; one per 12 s for earned hits, peaks always; a stronger replaces a running weaker one |
| Its modes | `camera_panels`: full, still (a frozen frame, the inset renders twice and is off), off; at VFX's lowest quality a live strip becomes a still one; reduced motion also makes it still |
| Its cost | One extra render of the world at 749 x 144 px for under a second: 0.45 ms on desktop, about 3 ms on the web at a 4x CPU slowdown |
| The events | `beam_outcome` (kind: hit, guard, dodge, clash, escape; 20 ticks after `beam_fire` in the dynamic profile); `building_stage {b, from, to, x, y, z, w, h, kind, cx, owner, n}`; `floors_fall {b, from, to, n, x, z, w}`; `building_fall {b, x, y, w, depth, mode, delay, cx, rubble, n, landmark}`; `S.beams` (origin, direction, length, owner, depth) |

## 2. When it opens

**The trigger is three facts together**, all inside 2 s of the `beam_outcome` of kind dodge for the beam (`beam_outcome {actor, target, kind}`: the actor fired it, the target dodged it; the beam crosses the target's place in the tick the outcome is read, and carries on):
1. the beam's owner is the other fighter (a dodged beam, the dodger the one it was aimed at);
2. a structure on the beam's line (within its carve width) is damaged by it: `building_stage` with `to > from`, or `floors_fall`, or `building_fall`;
3. the damage is **not already in the dodger's picture** (the building's centre is outside the pane, or inside it but under 60 px wide on the screen): a collapse that fills the view needs no inset.

**Significance** is computed from the events the beam caused on that structure, summed over the window:

| Event | Points |
| :--- | ---: |
| each stage stepped (`to - from`) | 0.5 |
| floors cleared, as a share of the building's floors (`floors_fall`: `(to - from) / floors`) | 1.0 x the share |
| the building falls (`building_fall`) | 2.0 |
| a landmark (`landmark: true`) | x 1.5 |
| the building's height, in body heights over 10 (a tower) | + 0.1 per body height over 10, at most 0.5 |

**Open at 1.0 or more** (two stages, or a third of the floors, or a fall); **big at 2.0 or more** (a collapse, or a tower half gone). Two structures hit by one beam count separately and the larger opens. The values are first values: Tools' captures of a dodged beam through the re-laid city will say how often it opens (I have not measured it); the aim is **0.5 to 1.5 a minute of a five-minute fight**, so the 1.0 may move.

**Rationing** (the strip's grammar): at most one every 15 s, three a minute; never during the intro, a transformation, a finisher, a KO, a launch's solo shot, a lunge, or while a fighter strip is up (it waits up to 1.0 s for the strip to end, else it is dropped); a stronger one replaces a running weaker one.

**Only a beam this version.** A blow that sends the opponent through a building has the building in the picture already; a blast aimed at a building is the same case as a beam (the cause is on the event). Orb's ask is the beam.

## 3. Where it sits

| Size | Shape | Where |
| :--- | :--- | :--- |
| **Damage** (1.0 to 2.0) | A thumbnail: 22% of the width by 16% of the height (a phone in landscape: 30% x 22%), a thin border in the dodger's lane colour, rounded to the screen's grid | In the **dodger's own pane**, in the top corner on the side the building lies (the picture says "it is that way"), under the HUD's plates (UI's `panel_floor_y()`), clear of the pane's edge by 2% |
| **Big** (2.0 and over) | The strip's band: 56% x 20%, slanted, the panel strip's own placement and wipe | Top band, else bottom band, as the strip; in a split it sits across the dodger's pane only (the strip's slant is cut at the divider) |

- **In the merged view** the thumbnail sits in the top corner on the building's side of the screen; a big one is the strip.
- **In a split view** it is drawn inside the dodger's pane and clipped to it; the other pane's player sees nothing of it (they see the beam land in their own view). The split's divider never moves for it.
- **A solo shot on the dodger** (a launch chase) closes it.
- **Direction** is part of the read: the thumbnail's corner is the building's side, and its frame is oriented as the world is (no flip).

**What it shows.** The inset's camera stands at the building's centre at 55% of its height, level (no pitch), with the zoom that fits the building's `w` and `h` plus 20% (the damaged height `h` of the event for a stage step; the whole building for a fall); for a fall it follows `cx` (the collapse's centre) and the rubble. A landmark gets 35% margin. Minimum drawn height 60 px, so a short wall in the distance is not a speck. It is the real world, live; the camera is steady (a slow 4% push-in over the first second).

## 4. How long

- Opens when the first qualifying damage event arrives (the beam takes 20 ticks to reach the building; the opening waits for the damage, not the dodge).
- Stays at least **1.4 s**, and while damage events continue (a collapse's floors keep falling for 1 to 2 s); closes **0.6 s** after the last event; at most **4 s** (**6 s** with a `building_fall` and its rubble).
- Wipe: in 0.12 s, out 0.18 s (the strip's are 0.08 and 0.12; a thumbnail is smaller and can take longer). Reduced motion or the still setting: it opens at once on the peak frame and shuts at once.

## 5. How it shares the split screen

- The inset belongs to **one pane** (the dodger's) and is clipped to it. In a split the other pane is untouched, so a two-human match gives the inset to the dodger only.
- It never covers a fighter: the thumbnail's rectangle is tested against both fighters' boxes in the pane each frame (the strip's rule), and it moves to the other top corner (or closes) if a fighter's box would be under it.
- **Priority across insets:** a fighter strip (signature, KO, finisher, clash, riposte) beats a damage inset; the damage inset beats nothing. One of the two is up at a time (the cost).
- It adds nothing to `SplitFrame` that changes the layout: a `damage` record beside `panel` (`kind`, `pane`, `rect` in px, `cam` of the inset, `size`).

## 6. Flash and cost limits

**Flash.** The flash register counts what the main world draws. The inset draws the *same* world from another place: a building's collapse, fire, debris and the beam's own glare that the main view does not show. So the inset adds changing area the register has not seen.
- **Area.** At 1,024 x 768 the analyser's area threshold is 21,824 px (2.8% of the frame). A thumbnail of 22% x 16% is 3.5%: it can count on its own. The strip is 11%.
- **Reduce flashing (the default) or reduced motion: the inset is a still frame** (the panel's still mode): taken at the collapse's most legible moment (0.5 s after the first fall event), held for the inset's life, shut at once. No flash can come from it.
- **The ordinary mode: live, with a cap.** VFX draws the inset's view with a calm flag (`inset_calm`): no full-view flashes (the flash layers off), explosion brightness capped, embers and sparks at their reduced counts. Tools' flash set reads a clip with a dodged beam into a tower (and a collapse clip with the inset) with the inset in the picture: the capture is of the page, so the inset is in it.
- **Travel.** The inset's camera is fixed or slow (4% push), so its picture changes only by what burns and falls in it.
- **Cuts.** Opening and closing are wipes, never cuts; the strip's wipe is not a counted change in the clips that have it.

**Cost.** One extra world render at the inset's size; the thumbnail is smaller than the strip (282 x 115 against 749 x 144 at 720p), so about 0.3 ms on desktop and 2 ms on the web at 4x. One at a time; off at VFX's lowest quality (still), off with `camera_panels` off. A still inset costs two frames.

## 7. What it needs

| Who | What |
| :--- | :--- |
| **Simulation / Encounter** | The **cause on the damage events**: `building_stage`, `floors_fall`, `building_fall` carry `by_beam` (an id that `S.beams` and `beam_outcome` share), or at least the beam's `owner` and tick; the `beam_outcome` (today `{actor, target, kind}`) also carries the beam's id. Today `building_stage.kind` is the building's kind, not the cause. Without it the camera can only guess from "a dodge, then damage near the line" |
| **World** | The number of floors of a building in the event (`floors`), so the share of floors is computed without a lookup |
| **Rendering** | The inset pane at an arbitrary world point (it is, for the strip, at a fighter) and a distant-structure level of detail for a building 5,000 units off; the calm flag `inset_calm` on the inset's VFX hub view |
| **VFX** | What `inset_calm` turns off (section 6) |
| **UI** | The corner's clear zone under the plates (`panel_floor_y` already); an option `camera_panels` covers it (full, still, off); whether Orb wants a separate switch |
| **Tools** | A scenario for the flash set: a dodged beam into a tower in the city, normal and reduced (the `rushcity` start with a signature aimed across the street); the inset in the composite |

## 8. Build order, behind a switch (`damage_inset`, default off)

1. **The trigger and the score** from the events, with a stand-in cause (the beam's line, the owner and the window), tested in the sweep with synthetic events: below the threshold nothing; at 1.0 a thumbnail; at 2.0 the strip; the ration; the priority against a strip; the building in the picture suppresses it.
2. **The frame**: the inset camera at the building, the margin, the minimum size, the follow of `cx`.
3. **The layout**: the corner in the dodger's pane, the HUD floor, the fighters' boxes, the split clip.
4. **The still mode and the calm flag**; the flash clip.

## 9. Open for Orb

- Whether a blow that sends the opponent through a skyscraper out of the picture should also get one (I would not: the building is in the picture).
- Whether the inset may show for the fighter who *fired* the beam (his view of the damage he did). I would not at first: it rewards the shooter with a second camera on every shot; the ask is the dodger's.
