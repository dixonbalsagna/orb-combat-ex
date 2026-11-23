# Citizens stand on the tile ground

Parked by Rendering, 2026-11-01. `cit.diff` stacks on `2026-11-01f-fine-cells/fine.diff`. Only with the tile ground's switch on.

**The fault.** Brown figures floated in front of walls (Tools' clash still). They're first-ring citizens; far places have none.

**The cause.** They were placed before the tile field existed, so each stood at the fighters' line height wherever they were. One 2,735 units back was at 1,311, over ground at about 932.

**The change.** Their feet go on the ground the way trees' and props' do (`add_feet`), and a building update keeps them there, read through the plan's frame.

**Seen:** `docs/rendering/img/lookgate/citizens-feet-before-after.png`. The readout matches the ground at the five citizens read.

**Known:** feet are read from whichever tile is there when the slice runs, which can be a coarse one. Standing on a steep slope may be a few units off, like trees.
