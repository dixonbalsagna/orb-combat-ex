# Open floors (2026-10-12)

Owner: Rendering and Technical Art. Built to Orb's ruling of 2026-10-12, shown a tower holed and a tower sunk to a stub and told of this third way: "'open floors' sounds like it would look the most natural, get that implemented". Render only: it reads the sim and writes nothing to it. The gameplay hash is unchanged.

**It needs depth to be seen.** A fight stands behind a tower only when depth is on, and no match has depth on yet. It was built, checked and recorded against a scratch build whose match starts with depth on and whose scene moves the two fighters. With depth off nothing of it runs and the picture is as it was.

## To see it move

Open `docs/rendering/img/lanes/motion-open-floors/index.html` in a browser (a local page, not committed: 1,121 frames beside it, 31 MB). It plays 19 seconds at the game's 60 ticks a second: a pair goes back down an avenue from the downtown front street to the middle street, moves along it behind a tower, stands there, and comes back. Space pauses, the arrow keys step a tick, the slider scrubs.

## What it does

- **A tall building standing between the camera and the fight loses the floors the fight is seen through,** across its whole width, in that pane. The street behind shows under it. The tower above and the skyline stay.
- **For a pair on the ground it is the lowest two floors.** For a fight in the air it is the floors at that height, and the building stands below them as well as above.
- **Behind two blocks, both open.** A fight in the back street is seen under the front block's tower and the back block's.
- **It opens before the fight is hidden,** and closes three quarters of a second after the fight is clear.

## One building, one method

| The building | What it does when it is in front of the fight | Never |
|---|---|---|
| **5 floors or more as built** (`RenderLook.OPEN_FLOORS_MIN`; in today's world 35 of 118 buildings, the lowest 9 fighter heights tall) | Opens floors | Is holed, patched or sunk |
| **Fewer than 5 floors** (houses, shops, sheds, warehouses, the foreground row's houses; the tallest is 8.6 fighter heights) | The patch: Orb's see-through window sized to the action, and the building sinks as the patch grows large | Opens floors |

- **The threshold is the building's floors as built,** so a building is of one kind for the whole match, whatever is knocked off it. Five floors is World's own line: the buildings a brunt can clear floors from.
- **In height the two kinds meet at about 9 fighter heights:** the tallest building that takes the patch is 643 units, the lowest that opens floors is 675. At a close brawl the frame shows about 7 above the street at the front block, so a building that opens floors always stands out of the top of the frame, and sinking it would change the whole screen.
- `open_check` asserts on every tick that no building does both.

**With depth on the patch works through every row.** Until now the patch was the foreground row's alone, and the rows behind had each fighter's own hole or stubs. In a match with depth on, the one patch opens every low building in front of the fight in any row, by the foreground row's code: each of its ends lies at its own fighter's depth, so it cuts what stands in front of their line and nothing behind it. With depth off the rows behind keep the hole and the stubs.

## How many floors, and how it is held

- **The action is the patch's own capsule:** both fighters, the gap between them, and what is travelling (where each will be in 0.3 s, a beam's stretch, a shot). So both methods follow one action and are held alike.
- **A tower opens for the capsule's line, not for the room round it.** It opens when the line comes within 75 units of being hidden by it (`OPEN_SIDE`). A pair standing clear in an avenue opens neither corner tower.
- **How high:** the floors the capsule is seen through at that building, from the camera's own sight lines to the capsule's top and bottom at the building's front and back faces, taken 20 units larger (`OPEN_PAD`).
- **Whole floors.** The opening's low end is a floor's foot and its high end a floor's ceiling. A pair on the ground behind a tower with floors of 154 units: the sight line to their heads passes the tower at 108 units, the capsule's top at about 205, so two floors open (307 units).
- **The hold.** An end grows as soon as it is asked to. It draws back only when nothing has asked for it for 0.75 s (`OPEN_HOLD_S`, the patch's hold).
- **The building a launched fighter is aimed at stays whole,** as under his own hole: its cut floors show him inside.
- **Camera's request is honoured as the patch honours it:** `request` false asks for nothing and what is open closes; `only` makes the action one fighter's.

## How it looks, and why it is not damage

Between the two heights the walls are gone: front, sides and back. What is left says it is built that way.

| | An opened floor (the camera's) | A cleared floor (a brunt's damage) |
|---|---|---|
| Through it | The street, the crowd and the fight behind the building | The building's dark back wall |
| What stands in it | A post at each corner and one a bay along the front, in the wall's own colour | Nothing |
| Its edges | The clean pale edge of the floor above (`OPEN_SLAB_COL`), straight across the whole width | The wall's own edge |
| Round it | The facade as it was: lit panes, no soot | Windows out, soot, cracks, a sheared corner at the next stage |
| VFX | None: no glass, no debris, no dust | Glass and debris when it happens |
| When the fight leaves | It closes | It stays |

- **The dark under the tower** is the inside of the building above, seen from below. Nothing dark is painted into the opening.
- **Posts are thin** (9 units, never under a pixel and a bit) and few: the side and back walls keep their corners only, so little stands between the camera and the fight.
- **No dither.** The hole and the patch are dithered because they cut a round window through a wall. An opened floor ends on a floor line and needs none.

## How fast it changes

- **By area, with the patch.** All the openings of a pane together, and the patch, never turn more than 16,000 pixels a tick at 1024 by 768 (`PATCH_AREA_TICK`; the frame analyser's area threshold is 21,824). The openings take what the patch left of that this frame, shared by what each asks for.
- **Closing is half as fast** (`OPEN_CLOSE`), and only after the hold.
- **Measured, headless** (`open_check`, 1280 by 720, where the budget is 18,750): a pair put behind a tower at once is opened to in 11 ticks, at most 18,746 pixels a tick. It closes in 23 ticks at 9,375 a tick.
- **Measured, the frame analyser** (Tools' `analyse-frames.js` on the clip's scene at 1024 by 768, 2,130 ticks): 0.5 flashes in the worst second on the primary reading, 0.5 with the area threshold 15% lower, 0.5 with the two-second memory. A pass, with room.

## What I see in the clip

- **Down the avenue nothing opens.** The pair is seen all the way to the middle street between the two corner towers.
- **The tower opens ahead of the pair.** As it turns along the middle street the tower's two floors rise open in about a fifth of a second, a little before the pair passes behind its corner.
- **Under the tower the fight reads.** The pair, the middle street's crowd and the back block's lit ground floors show between four posts, under a dark ceiling. The tower above is untouched.
- **It reads as a building on posts,** not as a broken one.
- **The pair is small.** The camera does not follow depth yet, so in the middle street a fighter is half his size. That is Camera's, and it is the larger problem in this picture.
- **Closing** is a low dark edge coming down. It is the quieter of the two changes.

## Checks

- `render/tools/open_check.gd` (headless, 10 checks): depth off, a real match opens nothing and every building's texel says it never will; depth on, a building's kind is its floors as built; in front of a tower nothing opens; behind it the tower opens from the ground to a floor line above the sight line to the pair's heads, by no more than the area budget a tick, and does not sink; back in front it holds, then closes at half the budget, and is shut; Camera's request off closes it; behind a low building the patch is handed to the blocks' material and no floor opens; on every tick no building does both.
- The gates and the flash clip are in the report that came with this batch.

## Limits

- **Seen on one tower** (a plain shaft, downtown) and, in a still, on two towers one behind the other. Not seen: a stepped tower (its tiers are nested boxes, so its posts stand in tiers), the bell tower, a tapered stack or lighthouse, a shell, a tower with a brunt's tunnel in it, a tall building in the foreground row, a split screen's two panes.
- **A post can cross a fighter.** It is 9 units wide against his 45.
- **A fight in the air behind a tower** opens a band of floors that starts above the ground. That is built and has not been seen.
- **A few buildings of 5 floors or more are not towers:** the village hall, the hill chapel, the stack, the lighthouse. They open floors like the rest and have not been looked at.
- **Nothing was seen with the game's own movement:** the scratch scene slides the pair along a path. A launch into the rows with depth on has not been seen.
- **Cost is not measured.** A pane's stub texture is four floats an instance where it was one, and an opened building draws its back faces.
- **The ground behind a tower is drawn as it is on the plane.** With depth on the sim has its own rows of ground in depth, and the renderer does not read them yet (`fighters-in-depth.md`).
