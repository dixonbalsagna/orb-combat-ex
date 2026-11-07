# The HUD in a 70/30 split, and the legend when RB is held (UI & UX, paper, 2026-11-01)

For Camera's `docs/camera/split-unequal.md` (a 70/30 split against a computer, `SplitRig.split_share`) and Orb's first play ("they couldn't always figure out how to fire a beam"). Paper and two short probes; nothing built. The probes are numbers from `UiLayout` and `UiHints` on the real code, run once, headless.

## 1. Does the top plate fit a 30% pane?

**It depends on the line's lean, and at the steepest lean it does not.** Everything on the edge (plates, wound cards, legend, prompt row) is a column the width of the plate, fixed to the screen corner of its slot. A plate is 380 px at 1080p and scales with the screen's height (253 px at 1280x720). The 30% pane is 30% of the width at the middle of the screen, but the line leans up to 30 degrees, so at the plates' height (near the top) the narrow pane is wider or narrower than that.

| Screen | Plate | 30% pane at the top, line upright | at 15 degrees | at 30 degrees (the most it leans) |
| :-- | --: | --: | --: | --: |
| 1280x720 | 253 | 384, fits | 308, fits | **220: crosses by 49** |
| 1366x768 | 270 | 410, fits | 328, fits | **233: crosses by 54** |
| 1280x800 (Steam Deck) | 253 | 384, fits | 298, fits | **199: crosses by 70** |
| 1920x1080 | 380 | 576, fits | 460, fits | **325: crosses by 79** |
| 1024x768 | 203 | 307, fits | 225, fits | **130: crosses by 85** |
| 2560x1440 | 507 | 768, fits | 613, fits | **433: crosses by 106** |

(Gap to the line counted as one margin, 24 px at 1080p.) So against a flat or gently leaning line, a plate fits the small pane with room. Only a steep lean (the fighters far apart in height) pushes the line over the plate, and the plate is as wide as the pane, as Camera said, only at that extreme. What crosses the line is nothing urgent: a plate edge over the other pane's picture.

**The distance chip fits.** It sits between its fighter and the line, a margin short of the line: its width is 96 to 146 px (the big one) against a pane at least 253 px across even on a phone-sized landscape. Its clearance from the fighter (`chip_clear`) is one chip's height; the CPU's fighter is centred in the small pane, so about 190 px at 1280 lie between him and the line, which holds the chip.

**What else is a column:** the bark lanes are 34% of the width, so wider than a 30% pane: a line of speech crosses the divider.

**A second problem that is not the width: which plate is in which pane.** The plates are fixed by slot (player one's on the left, player two's on the right), but the panes face each other along the shortest way round, so the CPU's small pane can be on the left. Then the player's plate sits in the small pane and the CPU's in the big one.

## 2. What I would change, under a switch (`split_fit`, off), tied to `split_share`

1. **A column width cap while the split has a share.** `UiLayout` takes a `col_cap` (the narrowest the small pane gets at its steepest lean, less a margin) and the columns (plates, cards, prompts, legend) are `min(380 x scale, col_cap)`: 204 px at 1280x720, 301 at 1080p, 401 at 1440p. It is a fixed value per screen size, not per frame, so the HUD relayouts once, when the share turns on or off. A floor of 170 px stops it going to nothing (at 1024x768 the cap would be 117, so the floor wins and a plate there can still touch the line at the steepest lean). The plate planner already drops tags and cuts the name by tiers down to 171 px (the phone-landscape plate).
2. **The bark lanes** are capped the same way (34% of the width becomes 0.28).
3. **Plates ride their pane.** With a share on, the plate of the large pane is the player's, at that pane's outer corner, and the small pane's is the CPU's (the existing "Follow" panel mode, switched on by the share; Camera's `sigma` already says which side is which). That also puts the larger plate in the larger pane.
4. **During a beam struggle,** Camera plans to go back to even; the cap and the sides go with it (the record's `share` reads 0 then).
5. **What I need from Camera:** the split record carries `share` (0 or 0.7) and, if easy, which slot has the large pane. That is two keys in `split_record()`.

Cost: about a day, mostly the checks (a plate, a legend and a chip at the six sizes and three leans never crossing the line; the columns unchanged when `share` is 0, so 50/50 is byte for byte as it is). One risk: a narrower column makes the plate drop its tag or cut the name earlier; the 204 px plate looks like today's phone-landscape one.

## 3. The legend when RB is held: no, not clearly enough

What I read from the code and a probe (legend rows for each held stance):

| Held | What the legend shows | The problem |
| :-- | :-- | :-- |
| Nothing | Fly, Light, Heavy, Big blow, Guard, Energy (hold), Power (hold), Dodge | fine |
| **RB (energy)** | The stance's own words: Light is **Bolts**, Heavy **Charged shot**, Action **Mine**, B **Beam**; the Energy row is marked as held | **1. The legend goes at three seconds** (`legend_alpha`: full for 3 s after the stance changes, then cut, even while the button is still down). A player who presses RB and looks for the beam sees the rows vanish. **2. With the right-hand attacks on, the stick's row still says "Strike"**, but with RB held the stick is the beam (RB + stick fires it, and answers one). **3. B says "Beam"**, the old signature beam, while the beam is now the stick's and B is the big blow or the driver. |
| **RT (power)** | Big blow, with the stance row marked | The signature is RT + B (45 Charge), and the B row says only "Big blow": the way to the signature is not on the screen. |

**What I would change** (UI, behind `legend_beam`, off until Game Design names the words):
- **Stay up while a stance button is held,** no three-second limit; a clean cut 0.5 s after the button is let go. (This one is small and I would do it first.)
- **With RB held, the stick row reads "Beam (hold to charge)"** with the stick glyph, and the face rows read what each face does in that layer. With RT held the stick row is not listed (the stick is inert there).
- **B with RB held:** a word from Game Design for what B does there. "Beam" is wrong if the stick fires it.
- **With RT held, B reads "Signature (45 Charge)"**, so a player who holds RT finds it.
- **How to play, Controls page:** one line, "Beam: hold Energy, push the strike stick; hold it out to charge, let go to fire."
- The quiet timer I added (4 s with nothing changed) must not run while a stance button is down: today it would also hide the legend after four seconds of holding RB. That one is a bug against the above, and I would fix it with the first item.

## 4. Questions
1. Camera: the two record keys (`share`, the large pane's slot); and do the lanes and plates ride their pane (my item 3) or stay by slot?
2. Game Design: B's word in the energy layer, and whether the stick row says "Beam".
3. Orb: at the steepest lean the plate crossing the line is a small thing, but it shows. Cap the columns always while the share is on (my pick, a little narrower), or only when the line is leaning past 15 degrees (a plate that grows and shrinks)?
