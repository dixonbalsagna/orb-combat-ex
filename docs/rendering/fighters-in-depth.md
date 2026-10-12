# Fighters in depth: what the renderer has, what breaks, what to build (2026-10-12)

Owner: Rendering and Technical Art. For the EP, on Orb's ask that the depth axis stand out as a new feature, and on Game Design's rules in `docs/design/depth.md` (the pair's line at 10 to 30 degrees to the street, up to 1.5 fighter heights a second in depth, a mark on the ground under the pair). Render only: everything here reads the sim and writes nothing to it. The gameplay hash is unchanged.

**How it was looked at.** A scratch web build whose pose scenario can start a match with depth on and hold the two fighters at any depth, in headless Chrome at 1280 by 720, on the city of 3cee6dce (three streets, an avenue every block). Nothing of that scenario is in the repo. The stills are review pictures, not committed: `img/lanes/depth-*.png`, listed in `img/lanes/INDEX.md`. bh is a fighter height, 75 units.

## In short

- **Most of it already works.** A fighter is drawn at the sim's depth with the world's own perspective, sorts against every building by true depth, has his shadow at his depth, and is opened to view by a hole or by stubs when a building stands in front of him. That was built for brunt launches and holds for a fighter anywhere in the band.
- **A crossing needs no cutaway.** A fight in the middle or the back street, at a crossing, is seen down the avenue with nothing in front of it, as long as the camera keeps the pair near the middle of the frame.
- **The largest problem is size, and it is Camera's.** At a close brawl the camera stands 1,170 units from the plane. In the middle street a fighter is half his size and in the back street a third.
- **One thing was wrong in my own code and is fixed in this batch:** every beam was drawn on the plane, whatever depth the sim fired it at.
- **One thing is new in this batch:** the pair's mark on the ground. It is drawn only in a match with depth on.
- **Everything in this batch draws nothing new with depth off.** A beam with no depth is placed by the old formula, to the bit, and the mark is never set.
- **Still to build, with their owners, are in the last table.** Since this was written: Simulation gave the effect particles a depth and Rendering draws them at it in a depth-on match; and Orb picked open floors for a tower in front of the fight, which is built (`open-floors.md`), with the patch working through every row for the low buildings.

## 1. Size and movement on screen

Measured at a close brawl (the mash scenario, zoom 1.15 at 720p): the camera stands 1,168 units in front of the plane and about 175 above the street, with a 30 degree lens. A 75-unit fighter on the plane is 86 pixels tall.

| Where he stands | Depth | His size, close brawl | His size at zoom 0.6 (camera 2,240 away) |
|---|---|---|---|
| The front street's near kerb | +187 | 119% | 109% |
| The plane | 0 | 100% | 100% |
| The front street's far kerb | -187 | 86% | 92% |
| The middle of the middle street | -1,012 | 54% (46 pixels) | 69% |
| The middle of the back street | -2,025 | 37% (32 pixels) | 53% |

- **A drift at Game Design's cap** (1.5 bh a second) changes his size by about 10% a second at a close brawl and 5% at zoom 0.6. `depth.md` section 3 says about 3%.
- **It moves his feet 19 pixels a second up or down the screen,** a fifth of his height. The ground is seen at a low angle: a unit of depth is 0.17 pixels of screen height, against 1.15 for a unit along the street.
- **So the line barely shows as a slope.** Two fighters 90 units apart on a line turned 20 degrees stand 33 units apart in depth. On screen that is 6 pixels between their feet and 3% between their sizes. A line of 20 degrees on the ground is a slope of 3 degrees on screen.
- **Across the front street, kerb to kerb,** he goes from 119% to 86%. That reads as depth and is comfortable.
- **In the middle and back streets he is too small to fight at this camera.** Either the camera moves in toward the pair's depth, so that the block in front of the fight is behind it, or it zooms and the block is opened. Both are Camera's. I would not scale the fighters up against the world: his feet would leave the ground he stands on and the doors and the crowd beside him would give it away.

## 2. What holds today

Seen in stills and asserted by `render/tools/depth_check.gd`.

| What | How |
|---|---|
| Place and size | `FighterView` sits at the sim's depth (`SimHost.fighter_z`, interpolated); the camera's perspective does the rest |
| Sorting against buildings in rows 1 and 2 and across the avenues | The depth buffer. Buildings are opaque (their holes are dithered, not blended), so nothing sorts wrongly |
| His shadow | On the ground as drawn at his depth, fainter and wider as he rises (`PaneWorld._place_shadow`) |
| The lane cue | A stripe along the street at his depth in his colour, when the two are more than 40 units apart in depth or his depth changes fast |
| A building in front of him | The pane's hole or its stubs, found by the true sight line (`PlanetView.occluders`). In the middle street behind a tower both fighters count as hidden and the tower opens; in a crossing neither does |
| After-images, the hit flash, the head badge, UI's anchor | Each follows the fighter's own depth |
| The world's bend at far zoom | The sag is worked out for his depth |

## 3. What breaks when a fighter is off the plane

| What | What is seen | Whose |
|---|---|---|
| **Beams** | Drawn on the plane at any depth. By the numbers, a beam fired in the middle street would be drawn nearly twice the fighter's scale and would not leave from his hands. Not seen: no pose fires a beam in depth | Rendering. **Fixed in this batch** |
| **The sim's effect particles** (sparks, rings, dust, the shock) | They had no depth, so every one was drawn on the plane: in the middle street a hit's sparks would have been 1,000 units in front of the fighters, nearly twice their size | **Done, 2026-10-12.** Simulation gave `SimFxView.Part` and the damage numbers a depth (9a8b3a2c). In a match with depth on Rendering draws them at it, and its own impact particles at their event's. With depth off they stay on the plane: a brunt launch's events carry a depth too, and moving those is a look change for another day |
| **Size** | Section 1 | **Camera** |
| **The angle of the pair's line** | Section 1: 6 pixels and 3%. The lane cue does not show under 40 units of depth | Rendering. **The pair's mark, in this batch** |
| **The crowd at depth** | In the middle and back streets the fighters stand among grey figures of their own size. Neither is hazed, and at half size the fighters are hard to pick out | Rendering: give the crowd the rows' haze by its depth (a look change: it needs the flash clip and Orb's eye) |
| **The hole** | 1.6 of his heights, 70 pixels at least. Behind a tower it shows the two fighters and nothing of the street, the approach or a beam. Orb ruled the same of the foreground row | Rendering: the patch, section 4 |
| **Stubs** | They clear the view, by taking a whole tower away: a change the size of the screen each time a fighter passes behind one | Rendering, with Camera: section 4 |
| **The ground at depth** | With depth on the sim has eight rows of ground across the band (`WorldTerrain.groundY(S, x, z)`). The renderer draws its own bowl field off the plane and does not read those rows. Where a crater lies in depth, a fighter's feet and the drawn ground can part | Rendering: the ground field reads the rows when depth is on. Not built: nothing digs in depth until L4 |
| **A fighter on a roof** | His shadow is put on the ground under the building, where nobody sees it | Rendering, once World gives a read for the surface he stands on |
| **The front street's crowd** | It stands in front of a hole's lower part | Rendering and Art. Small figures; a fighter is not hidden by them |
| **VFX's own layers** | Shots and the beam's head read the sim's depth. The rest I have not audited | **VFX** |

## 4. The patch for anything in front of the fight

Orb's ruling for the foreground row was one see-through patch sized to the action, and a building that shrinks when the patch must grow large. The same question comes back one row deeper: a fight in the middle street stands behind the front block, and one in the back street behind both.

- **What I can build at once:** the same patch (one capsule round both fighters and where they are going, soft edge, held, grown by area) through every building nearer the camera than the action. The blocks' material already takes a capsule hole with a depth, so this is the foreground row's code applied to more rows.
- **What is not settled is the second half:** what a tower does when the patch grows large. A house can sink to a stub. A tower of 20 to 40 fighter heights cannot: it is a third of the screen. Camera's paper (`docs/camera/city-in-depth.md` section 3) names two candidates: the patch alone at any size (a window through the whole tower), or open floors (the lowest floors cut across the tower's width, the tower standing above). Open floors keeps the skyline and changes each tower once.
- **My recommendation:** the patch for a small fight, open floors past the size where the foreground row's houses sink. Orb judges from motion, as with the foreground row.
- **It is not in this batch.** A fighter enters the rows today in a brunt launch with depth off, so changing how the blocks open changes today's picture and needs the flash clips first.
- **The crossings need none of it,** and they are where Game Design wants the fight to change streets.

## 5. Built in this batch

**Beams in depth** (`render/core/beam_view.gd`). A beam is drawn along its true line: from the sim's depth at its origin (`Beam.oz`) by its change along its length (`zs`). A clash's two beams run from each fighter's depth to where they meet. A beam with no depth takes the old code path and the old numbers.

**The pair's mark** (`RenderLook.PAIR_MARK_*`, drawn by the ground and water shaders).
- A stroke on the ground from under one fighter to under the other. The two shadows are its ends.
- **It tapers:** broader under the fighter nearer the camera, by how far the line is turned (full at 30 degrees). The slope alone is too small to read (section 1), and a taper reads as near and far at any size.
- **A pale core in a dark rim,** so it shows on a pale sidewalk and on a dark road. No fighter's hue.
- **Its width is in pixels** (about 5 at its middle), because a width on the ground would be under a pixel at this camera.
- **When:** only in a match with depth on; the two within 4 fighter heights along the street, 6 units or more apart in depth, and neither more than 2 fighter heights above his ground. It comes up in 0.2 s and goes in 0.5 s, on tick time.
- **With depth off it sets nothing,** not even a uniform.
- Game Design asked UI and VFX for this mark. It is paint on the ground, so the ground shader draws it; its look is theirs and Art's to change. These are first values.

**What I see** (scratch stills, depth on, the downtown front street). With the fighters 38 units apart in depth the stroke is plain between their feet and its broad end says who is nearer. At 80 units the two lane cues come up as well, one stripe in each fighter's colour, and the three marks together read at a glance.

## 6. Checks

- `render/tools/depth_check.gd` (headless, 10 checks): depth off, a real match never sets the mark; a beam with no depth is placed by the old formula to the bit; a beam in depth lies along its true line; depth on, a fighter and his shadow are at the sim's depth; a close pair at different depths has the mark from one to the other; it goes level in depth, in the air and apart, and not at once; the lane cues; hidden behind a tower in the middle street and clear in a crossing.
- **Depth off, on screen:** the same still from the build before and from this one differs in 2,046 to 4,189 pixels of 921,600, all of them in the band where the crowd stands. Two runs of the build before differ from each other by 4,186 pixels in the same band. Outside that band no pixel differs. (The posed scene's crowd is not the same from run to run. I did not find why.)
- **Gates,** on an export of 5c144497 with this batch: determinism (plain, and `--intro --seeds=2 --ticks=900`), seam sweep, pane, stage, lane, sky, flash register, hud words, ground, shape, after, patch and depth all pass.
- **Flash:** the collapse clip reads the same with the batch as without it, change for change: 2.5 in normal mode and 3.5 in reduced.

## 7. To build, and by whom

| What | Who | When |
|---|---|---|
| A depth on the sim's effect particles (`SimFxView.Part.z`) | Simulation, then Rendering's one line | **Done** (9a8b3a2c and the batch after it) |
| The camera closes on the pair's depth, or zooms; it keeps a pair in a crossing near the middle of the frame | Camera | Before the middle street is fought in |
| The patch through every row in front of the action | Rendering | **Done** with depth on, for buildings under 5 floors (`open-floors.md`). With depth off the rows behind keep the hole and stubs |
| How a tower opens when the fight is behind it | Orb picked open floors (2026-10-12) | **Done:** `open-floors.md` |
| The crowd hazed by its depth | Rendering | A small look batch, with the flash clip |
| The ground field reads the sim's rows of ground in depth | Rendering | With L4's first crater in depth |
| A shadow on the roof he stands on | World's read, then Rendering | With roofs as a place to stand |
| The mark's look | UI, VFX, Art | Any time |
| VFX's layers off the plane | VFX | Before depth is switched on |
| The flash clips for a fight in depth (a drift across the street, a fight behind a tower, a send down an avenue) | Tools, with Camera's list | With the patch |

## Limits

- **Stills only.** Nothing here was seen moving: the scratch scenario holds the fighters still.
- The sizes in section 1 are for the one-view camera at a close brawl and at zoom 0.6. A split's panes were not measured.
- The beam in depth is proved by its numbers, not by a picture: no pose fires a beam in depth yet.
- The mark was seen on a street. On water, grass and char it is drawn by the same code and was not looked at.
