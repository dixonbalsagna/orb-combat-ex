# The re-laid city: what Camera must do, and what the flash check should watch (2026-10-11)

Owner: Rendering and Technical Art. For the EP to route to Camera, Tools, VFX and Legal. Measured on the web build in headless Chrome at 1024 by 768 and 1280 by 720, on exports of f5517adb (the old look), 9a22894a (the re-laid city as committed in 4e139947) and that plus the contrast budget (`lanes-look.md`).

## 1. Camera: so the fight is never hidden

**The geometry at fight framing** (0.6 pixels a unit at 720p): the camera stands about 2,240 units in front of the fighter plane and about 320 above the street. It sees 1,200 units of height.

**Correction, 2026-10-12.** Those numbers are the camera at a zoom of 0.6, with the fighters well apart. At a close brawl the camera is nearer: measured at zoom 1.15 (1280 by 720, the mash scenario) it stands 1,168 units in front of the plane and about 175 above the street, and sees 626 units of height (8.3 fighter heights) and 1,113 of width. Everything below that depends on the distance is worse at the close end: a foreground building hides more of the street, and a fighter's size changes faster with his depth. Camera's `docs/camera/city-in-depth.md` section 1 took the 2,240 and the 320 from here.

### Row 0, the foreground (off in the data until this is settled)

- **Every row-0 building hides the street.** Row 0 stands 562 to 938 units in front of the plane. From the camera, a building there taller than 120 to 170 units hides a fighter's feet, and one taller than 170 to 210 hides him whole. Suburb houses are 225 to 490 tall. A 300-unit house covers the screen from its bottom edge to just under the middle.
- **The hole is not enough for it.** Its radius is 70 pixels or 1.6 body heights: it shows the fighter and not the street, the other fighter's approach or a beam. Stubs clear it. Both, with row 0 switched on in a scratch copy of the data: ![hole](img/lanes/camera-row0-hole.png) ![stubs](img/lanes/camera-row0-stub.png)
- **What I need from Camera** (through the pane's `cutaway` request, which exists):
  1. Agreement that row 0 always opens by stubs, whatever method the rows behind use. I build it.
  2. How wide to clear. My proposal: every row-0 building over the pane's view of the street between the fighters, and a quarter of a screen each side.
  3. A hold before a stub stands again (I propose half a second), so a fighter pacing a street does not make the houses bob.
- **The foreground crowd** stands between row 0 and the plane, close to the camera, and its figures are drawn large. Art and World decide whether row 0 has one.

### Block row 1, in front of the back street (when depth goes live)

- Today the fighters stay on the plane, and row 1 is behind them: it hides nothing.
- At L4 a fight in the back street is behind towers up to 150 fighter heights tall. The hole gives two 70-pixel circles, or one slot. Stubs would sink whole towers each time a fighter crosses: a change the size of the screen, and a flash risk.
- **A third method I can build: open floors.** The buildings in front of the fight lose only their lowest floors, across their whole width, in that pane (the floor-cut tunnel, which is drawn already). The tower and the skyline stay; the street shows under them. It needs the cut data a pane. **Camera decides** between the joined hole and this before L4.

### Following a launched body through the city

- **Measured, the collapse clip, ticks 1427 to 1456:** a body is launched at 533 units a tick and the camera follows it, zooming from 1.0 to 0.2 pixels a unit in half a second. On every tick of that half second 25 to 30 percent of the screen turns brighter or darker by a tenth of full luminance. That is true of the old look and of the new one alike.
- The analyser reads that half second as 2 flashes with the old look and 4 with the new. The difference is a few frames near balance, where the count takes whichever direction turned more pixels: at tick 1433 the new look has 49,000 brighter against 32,000 darker, the old 42,000 against 56,000.
- Camera's limit on a re-frame at a sudden velocity step (f5517adb) is in both builds and does not bound this zoom.
- **Ask to Camera:** bound the zoom-out's rate when a body is launched through a district, or cut once to a wide frame and hold it.

### What the camera cannot show at fight framing

- **A tower's top.** The median downtown tower is 4,650 units tall and 1,200 are in view. A sheared corner, a shell's broken top and a tower's loss of height are all out of the frame.
- **The sky.** Downtown the towers fill the frame.
- If a stage change should read as an event, Camera would have to show the top (a tilt or a pull-back). Otherwise the street-level marks carry it (`lanes-look.md`, "Stages at the new heights").

## 2. What the flash check should watch

### What went wrong today, and the rule that came of it

- **The re-laid city as first committed failed the collapse clip in reduced mode: 5.5 flashes in the worst second, where the old look read 2.** Normal mode read 2.
- **The cause was the facades' own pattern under screen shake.** Downtown was stripes of pale pier and dark glass (or the dark inside, once the windows were out), a column every 46 units. In a hit-stop the sim is frozen and the camera shakes a few pixels: with the stripes, 14 percent of the screen turned brighter and 14 percent darker on every tick; with the old dark walls it was 1 percent each way.
- **The fix is a contrast budget** (`RenderLook.PATTERN_BUDGET`, 0.085 of relative luminance): on a look whose windows cover most of its wall, a pane and its wall stay within that of each other, a burnt-out floor's wall is as dark as its panes, and the towers are massed in the look's shadow tone. With it the hit-stop is back to 1 percent a tick.
- **The rule for any future look:** a pattern that covers more than three tenths of a wall is tone on tone. `shape_check` asserts that such a look carries the budget.

### The collapse clip now

| Full clip, 1,500 ticks | Normal | Reduced |
|---|---|---|
| Old look (f5517adb) | 2 (2 with the area threshold 15% lower, 2 with the two-second memory) | 2 (2, 2) |
| Re-laid city as committed (9a22894a) | 2 (3, 2) | **5.5** (6, 4) |
| With the contrast budget and shadow-tone towers | **3** (4, 3) | **4** (4, 4) |

- **It still fails.** What is left is the half second of the launched body above, in both modes: Camera's zoom over a city of dark towers and bright sky. It was at 2 with the old look by the fall of three balanced frames, not by a margin.
- Two things were tried on top and did not help: the pan haze (it follows travel along the ground, and this is a zoom), and the facades going to their average under fast travel (its own coming and going added changes; normal went to 5.5). Neither ships.

### Clips worth adding (for Tools)

1. **Shake at the foot of the towers:** a mash in the downtown front street, both modes. Watch the pixels turning on ticks where the sim is frozen.
2. **A body launched along the downtown front street:** the collapse clip's half second as its own scenario, so Camera's change can be judged on it.
3. **A wave of stage changes:** a beam down the front row that takes several buildings a stage in one second. A shadow-tone tower changes little (its lit panes go out). The Gatebell and a plaster house change more: at stage 2 a sixth of their bays turn dark on a pale wall, about 29,000 pixels for the Gatebell at fight framing, over the area threshold on its own.
4. **A zoom sweep over downtown:** the windows go to their average with distance (`lanes-look.md`); the wall should not change value on the way.
5. **A pan across a district edge:** pale suburb, dark downtown, sky.
6. **Stubs on tall buildings,** when Camera's row-0 rule lands: a house sinking to a stub is a change of its own.
7. **A tower's fall** uncovers bright sky behind it over the length of the sink.

### Standing notes

- The frame analyser counts, on each frame, only the direction that turned more pixels. In a busy scene two frames within a few percent of balance move the count by a whole flash. Read the areas turning a tick, not only the count.
- Large dark faces against bright sky remain, by choice: tall towers are dark so that a damaged tower and a whole one are one value. The edge of a tower passing the screen is a single change, not a strobe.
