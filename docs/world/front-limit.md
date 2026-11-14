# The front limit: no wall between the camera and the fight (World, 2026-11-01)

Rendering's reel v5 (through the EP): a huge building wall hides the fight, with buildings at every place on.

## What it was

Not size. A free place is the first ring's generator on another plan: widest 831 against 777, deepest 637 against 633, tallest 4,875 for both. It was **depth.** The first ring lays a building only in a lane (`data/biomes/lanes.json`): blocks from -2.5 bh back, the front street empty, nothing in front (the foreground row is off in the data). A free place has no lane. It is planet-fixed, so in the fight's frame it stands at whatever depth its planet point has, in front of the line as easily as behind. Simulation's index took every building within 3,000 units of depth either side (`swing.json indexBand`), and Rendering draws the buildings `WorldStructures.near` returns. So a tall building 10 to 40 bh toward the camera was drawn between the camera and the fight.

Measured on planet 7, touch 1 (3,600 ticks, 120 samples, the buildings `near` returns around the fight): tall buildings (h 400 or more) in front of both fighters covered **99%** of the fight's +-900 units in every sample, from free buildings; the first ring covered 0. 2,889 building-frames lay more than 10 bh in front, most past 60 bh.

## The cure

`WorldStructures.inBand` (sim/world/structures.gd) has a front limit, data `plans.indexFrontBH` = **-2.0** (-150 units), tested on a building's **front face** (its z plus half its depth): a building whose front face is in front of that is not in the index, so it is not struck. It is Rendering's number and its test (its rule brings a building down as the front face goes from -150 to -30), so the sim strikes only what the view has not lowered; a building centred behind the band can still reach past the plane, which a test on the centre missed. A first-ring block is flush to the street's back edge (-2.5 bh = -187.5), so its face is always behind the limit and none is lost.

The same predicate runs at the index build and in the swing's pose (`SimSwing._poseThese`), which now passes the building's depth too (`grant-simulation-depth.patch`, two arguments in Simulation's file; without it the pose tests the centre, and a rebucket could insert a building twice, so land them together). Checked over 7 swings of 70 degrees on planets 7 and 12: 43 index checks each, no duplicate, nothing in band left out, nothing out of band left in.

(The first cut, a centre at -3.0 bh, measured cover 0.000 on planets 7 and 12, from 99% before; with the face at -2.0 the check finds 1,625 far buildings left out of the index on planet 7.)

## The back, which was also wrong

`indexBand` is 3,000 each way, and the first ring's background row (row 3, a skyline) stands at 3,037. With places everywhere on, its 95 buildings were out of the index, so out of the draw. `plans.indexBackBH` = 45 (the background lane's far edge is 44.5) keeps them: the first ring's 263 are all indexed again (`everywhere_check`).

## For Rendering

The view draws every building in `S.buildings`, not the index, so this limit stops strikes and the picture is Rendering's rule; the two start at the same face depth. `ground_field.gd:394` paints no pads for a far building (Rendering checked).
