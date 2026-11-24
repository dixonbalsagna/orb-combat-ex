# GW1c look gate: how craters dig on the default planet, main against the GW1c stack (World, 2026-11-23)

The EP's request (the stand-in's review, `docs/ep/reviews/GW1c-medium-prelanding.md`, item 2): globe-step2 changes how craters dig on every default-planet match (the shaft cap reads the store, `craters.json settle` ships on, the store's ground is rim plus groove, clamped). A look-gate side-by-side was owed.

**Left (blue bar, label aaaaaaa): main `a345a380`. Right (orange bar, label bbbbbbb): main plus the stack of `docs/ep/reviews/GW1c-stack.txt`** (my copy of it: the 22 world, sim, rendering, UI and Tools pieces up to the Tools cases patch; the crater rules are the same code as the EP's 24). Default look: Reduce flashing on (`--reduced`), planet 7, landing 3 (what a match with no setup plays; the same pictures with `planet=7&touch=3` in the address, byte for byte). 960 by 540, one tick a frame, `tools/flash/capture-web.mjs` (Tools' launcher, one capture at a time, below normal; nothing of mine is left running).

## What was shown

The scenes are scratch (a test-only hook in a copy of `render/tools/flash_capture.gd`, nothing in any tree: `scratch-scenes-edit.js.txt`). The same two scenes ran on both builds:

| Scene | What happens | Stills (`img/`, git-ignored: they show the fighters) |
| :--- | :--- | :--- |
| `craterspot` | The second fighter is thrown down onto the same spot six times (ticks 30, 130 ... 530: the real `SLAM DOWN` launch, tier 3) | `spot-t00110.png` (after one), `spot-t00310.png` (after three), `spot-t00660.png` (after six), `spot.gif` |
| `cratertrench` | A slide trench (330 long, 130 deep; what a knockback slide cuts) is cut left of the spot, then the target is thrown down beside its end, on its far edge, then on the spot, twice round | `trench-t00110.png`, `trench-t00210.png`, `trench-t00310.png`, `trench-t00660.png`, `trench.gif` |

The camera is the game's own, so the framing differs between the two sides once the ground differs.

## What changed, and does it read as intended

- **A spot hit several times.** Main digs a new crater on every blow and the pit keeps going down: six slams leave a funnel the fighters stand at the bottom of, far deeper than a crater is wide (the headless numbers, `spots-main.txt`: the centre is 251 below the far ground after the first blow and 1,347 below after the eighth; the stack stays at 251). The stack digs the first crater and **refuses the rest**: six slams leave one wide, shallow dish with its rim and the heap beside it. **It reads as a crater, the same as the first blow made on main.** This is the shaft-cap fix, meant.
- **A crater beside a slide trench.** The trench is the same on both (its wall is a straight cut: the groove settling is off as shipped, and unchanged by the stack). The crater dug next to it comes out as a wide dish on the stack and as a deep pit with a trench-sized wall on main. No pit that stops reading as a crater; no shelf that is not the trench's own wall (zoomed on the stack's last frame: the one wall on the left is the trench's end, as on main).
- **What a player can feel.** After the first blow on a spot, blows within about one crater radius of it dig little or nothing: equal blows 60 units apart dig nothing, 120 apart 7 deep, 200 apart 45, from 300 apart the full 78 (a base blow; `offsets-stack.txt`); a tier-4 blow (four times the energy) digs nothing within 200 and 40 at 300 (`offsets-main.txt` for main: every one digs the full depth). A blow that digs nothing still lands as a hit; only the extra crater is missing. Whether the hit still *plays* its dust and shock on a refused blow is Rendering's and VFX's to look at: I did not look at that frame by frame.
- **Not looked at:** a crater on a natural cliff (the settling reads the store's marks only, noted in the park's risks); water (flood stays off); the first-run picture of the intro's two entrance craters (the same two records, just stored 16 numbers each).

## Records

| File | What |
| :--- | :--- |
| `spots-main.txt`, `spots-stack.txt` | The ground's height every 48 units round a spot after each of eight tier-3 blows, then the trench scene, then overlapping craters (`look_probe.gd.txt`, headless, planet 7 gen 3, the same seed on both) |
| `offsets-main.txt`, `offsets-stack.txt` | A second blow dug `off` units from a first of the same size: the centre's height before and after (`look_probe2.gd.txt`) |
| `scratch-scenes-edit.js.txt` | The scratch scenes added to both copies of `render/tools/flash_capture.gd` (a copy, never a tree) |
| `img/` | The stills and the two GIFs (git-ignored by `.gitignore` in this folder) |

Pictures stay on this PC in `img/`; nothing here is for a public page.

## Pillar 4: a stronger blow on a weaker crater (added 2026-11-23, the EP's question)

A first blow of x1 energy (a base crater), then a x2, x4 or x9 blow on the same spot and at 60, 120, 200, 300 and 500 units from it. The depth the second blow adds at its own centre, headless, planet 7, the same seed on both (`look_probe6.gd.txt`; `stronger-main.txt`, `stronger-stack.txt`):

| Second blow | Fresh ground | Main (any offset) | Stack, same spot | Stack, 60 | Stack, 120 | Stack, 200 | Stack, 300 and up |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| x2 | 110 | 110 | 45 | 49 | 60 | 85 | 110 |
| x4 | 156 | 156 | 106 | 111 | 123 | 149 | 156 |
| x9 | 234 | 234 | 199 | 203 | 216 | 234 | 234 |

**The stronger blow digs every time; none is refused.** On the stack a x4 on a x1 crater, 120 apart, adds 123 (against 156 on fresh ground; main always adds the full 156). The cap is 0.26 of the second blow's radius less the relief already there, and a bigger blow's radius is bigger, so the old small crater is a smaller share of what it can dig. A blow is refused only when the crater already there is as big as it can dig (same size or larger): x1 on x1 at 60, x4 on x4 within 200, x1 to x4 on a x4 crater (`same-spot-stack.txt`, `look_probe5.gd.txt`). So the power tiers still order the damage: a higher tier leaves a deeper mark on the same ground, and the bigger the tier the nearer to fresh ground's depth.

## Escalation holds: the same spot, a bigger blow after a smaller one (added 2026-11-23, the EP's request)

A first blow, then a second on the same spot (stack tree, planet 7, headless; `same-spot-stack.txt`, `look_probe5.gd.txt`). Depth the second blow adds at the centre; base blow = x1 (a 356-unit crater radius).

| First crater | Second blow | Result | Added depth |
| :--- | :--- | :--- | ---: |
| x1 | x1 | refused | 0 |
| x1 | x2 | dug | 45 |
| x1 | x4 | dug | 106 |
| x1 | x9 | dug | 199 |
| x1 | x16 | dug | 291 |
| x4 | x1, x2, x4 | refused | 0 |
| x4 | x9 | dug | 114 |
| x4 | x16 | dug | 213 |

A bigger tier leaves a deeper mark on the same ground, each time. A blow is refused only when it is no bigger than the crater already there. Main digs every blow in full (x1 78, x4 156, x9 234 each time), so there it does not matter what is already there.

## Settle false: nothing here changes (added 2026-11-23, the EP's question)

`craters.json globe.settle` is the one data switch among the three. The shaft cap (it reads the store: `sim/world/crater.gd`, 0.26 of the radius less the relief) is code with no data row, and the refusals are the cap. `settle-switch-stack.txt` (`look_probe4.gd.txt`), stack tree, planet 7, eight x4 blows on one spot and then a x4 second blow 120, 200 and 300 units from a x4 crater:

| Setting | Same-spot blows that dug (of 8) | Centre below the far ground | Second blow adds at 120 / 200 / 300 |
| :--- | ---: | ---: | :--- |
| Shipped (settle on, cap on) | 1 | 251 | 0 / 0 / 40 |
| Settle off, cap on | 1 | 251 | 0 / 0 / 40 |
| Settle off, cap blind (`WorldGlobe.blind`, the negative control) | 8 | 1,347 | 156 / 156 / 156 |

With settle false a repeated spot is still the one dish, not main's funnel. Settling only makes a steep bowl wider and shallower where it is dug beside a trench or an earlier crater. Not measured with settle false: the golden and the groove storage (`settleGrooves` is a separate switch, false as shipped).

**Fallback if Orb dislikes it in play (the EP, 2026-11-23): no data row for the cap; `globe.repeats` as a private build after GW1c.** A note only: `craters.json globe.repeats` is the existing data switch (0 as shipped) that lets a blow on a recent crater at the same planet point regrow that crater (1.25 times, at most twice) instead of being refused; it is behind Rendering's open line in `tile_ground.gd` (globe-step2 README, decision 1), so it is a private build's choice, not a flip.
