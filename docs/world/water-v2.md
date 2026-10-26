# Water v2: holes fill, the pebble skip stays

World and Environment, 2026-10-23, for Orb's brief: "minor water physics ... keep the pebble skip ... water fills in gaps dynamically ... trenches, holes, anything bored out by energy blasts and impacts filled with water when necessary ... nothing that degrades performance, water a cosmetic backdrop, rule of cool, no fluid simulation."

## One page for Orb

**What you will see (when it is switched on).**
- Blast a trench on a beach, a coastal plain or a marsh and the water *rushes in*: a front runs from the sea along the scar (about 2,900 units a second), the level rising to the sea's, and the hole is a pool. A hole in a wetland or a jungle seeps full from below. A hole in a desert, a volcano or a mountain stays dry: nothing there would fill it.
- A fighter sent skimming down a flooded beam scar **skips along it** like a stone (up to 6 skips, each keeping 85%), the same skip as on the open sea. A slam into a flooded crater **throws a ring wave** that nudges anything at the surface a body-height outward and splashes the rim. A fill that reaches a scorched line **puts the fire out** (a hiss and thin steam).
- Shallow water is **waded**: a body or fighter in it is not dragged, sunk, held or slowed. Water never trapped anyone, never does damage, and a flooded crater in a town is a look only (Game Design's rulings 14 to 17).

**How it is built, in plain words.** The simulation keeps almost nothing: a hole opens a small "fill" that, for a few dozen steps, tops up each wet column toward the level the water would stand at, behind a front that runs outward from the source. Then it closes and costs nothing. The drama (the rushing front, the bore, the foam, the steam) is the renderer's: the sim sends it a short cue and Rendering draws it; it never writes back.

**What it costs.** Nothing when nothing is digging (0.2 to 0.4 microseconds a tick). With four fills open at once a water step costs about a quarter of what today's worst case (eight flow windows) costs: 220 to 540 microseconds against 800 to 950, measured, every second tick. At most four fills at a time, each at most 241 columns wide.

**What it will not do.** No flowing rivers, no tides, no pressure, no water that climbs: it fills holes to a level and stops. It is off by default (`data/biomes/water.json`), and with it off the water is exactly as it was, bit for bit.

**For Orb to decide.** (1) When it goes on (it is a data switch). (2) Whether a *hole in a desert next to the sea* should fill (it does, near the sea; far inland it does not). (3) Whether the crater wave's push (one body-height) is the right size.

## 1. Where water comes from

Four sources, each "of course that filled":
1. **The sea**: any hole dug within 36 columns (about 1,150 units) of the sea, on ground up to 40 units above sea level, fills to sea level. A trench that is dug as one scar fills along its whole length if any part is in reach (a scar joins the sea to its far end).
2. **A lake** (window 5 of gen 2) or **water already standing** (a bay a crater filled): the same rule, to that water's own level, so a hole beside a lake fills to the lake's flat surface even high in the hills.
3. **A water table** under wet ground. How far below the original ground the water stands: wetland 6 units, beach 14, jungle 45, sea ice 3; taiga 70 and tundra 40 only when water is in reach (permafrost seeps only near a lake or the sea). A hole dug through the table seeps full to it, with no front.
4. **Later: rivers**, by the same rule as a lake (a river is water standing along a line; Game Design's row 13: crossings closer than 640 units merge, at most one in 3,000).

Dry biomes (desert, volcanic, highland, mountains, plains and forest away from water) have no table: a hole stays a hole. Suggestions for what else reads as "of course that filled", not built: a hole in a river's flood plain; a crater under a waterfall; ice that breaks over the sea (sea ice, built at 3 units: a hole in the floe opens to the sea).

## 2. How it fills

Per hole: a **fill window** (at most four open, each at most 241 columns). Every second tick each column in it gains up to 9 units of depth toward its target level; columns beyond the front (3 columns a step from the source) wait their turn, so the water *arrives*. The window closes after three quiet steps. Deterministic, no draws, no per-tick work outside open windows. The state is S.water as before: the renderer reads the actual depth from it and the drama from the cue.

**The cue** (three events, for Rendering, VFX and Audio, never written by them):
- `water_fill`: x (where the front starts), y (the surface it heads for), n (columns), r (half extent in units), spd (front units a second; 0 for a seep), k (depth a second per column), amount (the deepest dig), dur (seconds to settle), cause ("sea", "water", "table").
- `water_wave`: x, y (the surface), r (ring radius, 600), spd, amount (the push, 75), n (steps), dur.
- `water_douse`: x (the fill's source), w (the extent), n (columns newly wet).

## 3. The skim

Unchanged on open water (speed over 500, descent shallower than 0.6, up to 6 skips, each keeping 85%). A flooded trench is water for it with no change: a send along a dug scar flooded from the sea skimmed 6 times in the check (0 when dry). Water shallower than 75 units is waded: no drag, no sink, the skim still works above it.

## 4. Cost, measured

(`fill_check.gd`, a busy machine; the numbers are the ratios.) A water step with four fill windows open: 220 to 540 microseconds; today's worst, eight flow windows: 800 to 950. A tick with nothing open: 0.2 to 0.4 microseconds. Columns touched a step are bounded by 4 x 241 against today's 8 x 481.

## 5. What is built

Window (a) sources and the table, (b) the cue, (c) skim and wade, and the sim side of Game Design's three payoffs: all one diff (`scratch-build/gen2-w10/`), behind the switch. Simulation's one line: `hash.gd` FX_FIELDS gets the three events' field lists. Tools' schema is in the diff (granted).

Not built: the renderer's drama (Rendering and VFX), the ring wave's splash and the steam's look, "a fighter landing in it surfaces set within 30 ticks" (Encounter's, with the lake rules that test the sea's absolute level: see window 7).
