# Multi-fighting and choreography: what VFX draws, and the cues it needs (2026-10-15)

Owner: VFX. Built in scratch on HEAD and parked (`docs/vfx/pending/multi-fight/`), measured on Tools' path, not applied. Reads Game Design's tenth round (`docs/design/brawl-second-pass.md` §14), `docs/combat/barrage-signature.md`, `docs/vfx/barrage-flash-plan.md`, Encounter's `docs/director/one-v-many.md` and Game Design's `docs/design/empress-guards.md`.

**The rule for every effect below:** a hollow ring, a thin line or a short streak in a lane colour, drawn between points. None is a flash disc but the barrage's last landing, which asks the register as `energy` (a disc of at most 0.4 of the area threshold, none in reduced motion). Nothing on the face, nothing red, white or gold, nothing steadier than a mark that the blow's own ticks already own. The code is `VfxReach` (cue arms, `reach.gd`) and `VfxShotsView._reach` (drawn arms), behind the same `press_enabled` flag as the other brawl marks; the duel's glass and cracks are `react.gd` and the hub's.

## The cues I propose to Encounter

Every one is a `cue` event (`type "cue"`, `kind` the name), as `windup` and `double_hit` are. `actor` and `target` are any two bodies the state holds (a guard is slot 2 or more; nothing here assumes two). `n` is an absolute tick where a time is named.

| Cue (`kind`) | Fields | Sent when |
| :-- | :-- | :-- |
| `duel` | actor the fighter who has just perfect-blocked and answers, target, `k` the level 1 to 8, x and y the lean | At each answered perfect block of a duel |
| `duel_end` | actor the one whose blow lands, target the one sent, `k` the level, `text` `amplified`, `cash_in` or `apart`, x and y the lean | The duel's end: a missed timing (`amplified`), the cash-in (`cash_in`), level 8 (`apart`, both sent) |
| `cash_in` | actor, target, `n` the contact tick (2 ticks after the press) | The cash-in is thrown |
| `chase` | actor the chaser, target, `text` `start`, `blow`, `arrive` or `end` | The chase begins; each of its blows (up to six); his arrival; it ends |
| `perfect_window` | actor the striker, target, `text` `open` or `close`, `n` the tick it closes | A perfect window opens on a light; it closes |
| `barrage_hand` | actor, target, `k` the volley 1 to 3, `text` `sweep`, `thrust` or `flick`, `n` the release tick | At the volley's wind-up (4 ticks or more before the release) |
| `barrage_land` | actor, target, `k` the volley, `text` `hit`, `guard` or `miss`, x and y the lean | A volley lands |
| `guard_volley` | actor the guard, target the one, `k` the bolt 1 to 3, `n` the release tick | A guard's covering volley, one cue a bolt |
| `interject` | actor the ring guard, target the one, `text` `light`, `medium` or `bolt`, `n` the contact tick | The grant of an interjection, at least 8 ticks before its contact |

The shots themselves (the barrage's fan, line and split; the guards' bolts) stay `S.shots`, which `shots.gd` already draws; `guard_volley` only adds the palm. The chase's travel is Camera's and the sim's drawn path: VFX reads the body, it never moves it.

## What is drawn

| Piece | Look | Quads | Ask |
| :-- | :-- | ---: | :-- |
| **Duel, levels 1 to 8** | At the middle of the pair a crossed crack (one limb in each fighter's colour), a hollow ring and sparks, all growing with the level (crack 27 units long at level 1 to 62 at level 8, the ring growing to 22 units at level 1 and to 50 at level 8, sparks 2 to 7). One mark at a time: a new level replaces the last | 7 at level 1, 9 at 3 (with the wave 10), 13 at 5, 14 at 8; 8 in reduced motion | none |
| **Duel, from level 3: the wave** | A thin flat ring runs out along the ground to 4 body heights over 12 ticks (a second at level 5 and up). The windows of every tower within 4 bh blow out, nearest first, at the shock's speed and a floor row more per level (`react.on_wave`, the crater's own jobs). The ground takes a crack web at levels 3, 5, 7 and 8 (a crater-style set, at most one in 30 ticks, on the cracks layer and its caps) | 1 or 2; the glass is the debris pool's | none (glass and cracks are not flashes) |
| **The amplified send** | His real path drawn as a trail wider by the level, a flat ring on the ground where he left it (42 units plus 8 a level), streaks lifting off (3 plus half the level), rims on both, dust along the ground. `apart` draws it for both | 14 at level 2, 17 at 6, 34 for `apart` at level 8 | none |
| **The cash-in** | The sure blow's tell in 2 or 3 ticks (a thin committed line hand to chest and four corner brackets closing on it, nothing to block), then at the contact a double ring, a crossed crack and one thin vertical cut through the chest, and two puffs of dust. The heavy's own press look comes with the blow as it does today | 9 for the tell, 7 at the contact | none |
| **The chase** | While it lasts a thin trail behind the chaser along his real path (5 segments, 3 in reduced motion); each blow and the arrival put four corner brackets and a flat ring on the rival's chest for 8 ticks. Ends on `end` or after 90 ticks | 5, plus 9 for 8 ticks a blow | none |
| **The shine** | While the window is open on a light: two thin edge lines along the striking fist and a small hollow ring on it, in his colour lightened. Steady: no pulse, no flicker (nothing here changes in luminance from one tick to the next). Until the close | 3 | none |
| **The barrage's hand** | A thin lit edge along the hand for the 4 ticks before the release (never a ball): half the usual length for the sweep (9 units, alpha 0.6), one knuckle for the thrust (8), the fullest for the flick (18) with a short cone of three streaks at the release | 2 (5 at the flick's release) | none |
| **The barrage's landing** | A rim on the rival (a thin edge, never over the body); a ring on volleys 2 and 3; on volley 3 if it hit, one soft disc of 3 ticks (radius 38 units, 0.35 of the area threshold at the close framing) | 1, 2, 2 and a disc | `energy`, once, `flash_every` pace; none in reduced motion |
| **A guard's bolt** | The bolt's palm comes up on the guard's hand as on any fighter's (the `lit` look: a small hollow ring and two streaks, gone at the release), in his own lane colour | 4 | none |
| **An interjection's tell** | Two small hollow chevrons over the guard's head that point at the one and close up over the tell (14 units apart to 6); in the last 6 ticks the blow's committed line from his hand to the one's chest. A bolt keeps the chevrons only | 4, then 5 | none |

At fight size the chevrons and the committed line are what separates a ring guard's blow from the partner's: the partner's blow has no tell above his head. Each is thin, in a lane colour, and gone with the blow; the guards carry the one colour of their lane so a ring of three reads as one hand.

## Against the budgets

- **Flash register.** One ask in the whole set: the barrage's last landing, `energy` (low priority, so none under reduced flashing at 1.0, and not in the same second as another `energy` flash beyond the register's own caps). Everything else is a ring, a line or a streak: pixels the analyser sees and the register does not, so each is kept thin (a ring's band at most 2.6 px, lines at most 3 px) and short (10 ticks or less except the chase's trail and the shine, which are steady, not changing).
- **Ghosts (m12).** None of it draws a whole-figure ghost. The amplified send's trail is the fighter's real path as a line, as the launch's send-off is.
- **Marks on a body (k01, `riposte-plan.md`).** The striker carries at most one of: the shine, the cash-in's line, an edge. The target carries at most one of: brackets (cash-in or arrival), a rim, a ring. No two run on one fighter in one tick.
- **Quads.** The worst cue is the level-8 `apart` at 34 quads; the whole set, with a duel, an amplified send, a chase and a barrage all live at once, stays under 80 of `VfxShotsView.CAP` 380.
- **Reduced motion.** Fewer sparks and one ring, no lifting streaks or second rings, a shorter trail, no cone and no dust; the shine, the brackets, the chevrons and the lines stay (they are still). The barrage's flash is dropped.
- **Cost.** Nothing runs when no cue comes; each is a handful of floats a tick and no random number is drawn. 1v1 matches never send a cue, so nothing moves in them.

## Measured on Tools' path

A scratch scenario `multi` (an AI match with these cues injected on a 300-tick cycle: a window and its close, a duel through levels 1 to 6 and its amplified end, a cash-in, a chase of two blows, the barrage's three volleys 24 ticks apart with the last landing, a guard's volley, an interjection), seed 12345, ticks 541 to 870, 1024 by 768, session vfx, one capture at a time.

| | primary / area-15% / area+15% / 2 s memory | events |
| :-- | :-- | :-- |
| Normal, with the effects | 2 / 2 / 2 / 2 PASS | 249+ 1.2, 270- 2.2, 278+ 1.8, 280- 3.2, 306- 4.0, 322+ 2.1 |
| Reduced, with the effects | 2 / 2 / 2 / 2 PASS | 248+ 1.3, 270- 2.2, 278+ 1.8, 281- 3.2, 306- 4.0, 323+ 1.7 |
| Normal, the hub off (the same cues, nothing drawn) | 3 / 3 / 1 / 1 | 248+ 1.7, 270- 1.1, 272+ 1.3, 277- 1.0, 278+ 2.0, 281- 3.2, 306- 4.0, 323+ 1.9 |
| Reduced, the hub off | 3 / 3 / 1 / 1 | the same eight |

The cues add no counted event: every event in the window is in the hub-off run (the world's own, 3.2 and 4.0 times the threshold, are the match's camera and ground); with the effects on, the nearby small ones merge into fewer. The duel's levels 1 to 6, the cash-in, the chase and the shine fall in ticks 600 to 760 and read no counted change at all; the barrage's volleys (ticks 770 to 830) share the second with the world's events listed.

## What each of these needs, and from whom

- **Encounter:** the cues above and their fields (`n` the contact or release tick, absolute). The duel's levels in the simulation, the cash-in's 2-tick contact, the chase's blows and the interjection's grant as the paper rules; nothing is asked of the hash.
- **Rendering:** the guards' slots in `host.fighter_x`, `fighter_pose` and `fighter_z` (every arm reads them by slot), and a lane colour for a guard's aura (VfxAura reads `fighter.aura`).
- **Camera:** the chase's drawn travel and the duel's close-in are theirs; the marks here sit in world space and follow.
- **Legal:** a screen of the set as drawn (the shine and the cash-in's cut are the two new shapes; both are thin lines and steady or 10 ticks), and the barrage's last landing's one disc under sg01.
- **Audio, UI:** their own. The rumble on a perfect is UI's.

## Not built, and why

- The "camera closes in", "the sound rises a step" and "the pads pulse" of the duel are Camera's, Audio's and Controls'; VFX draws only the sparks and the wave.
- A distinct `duel` colour pairing for guards (two guards and the one in a duel) is not defined: the cues take two bodies; a duel is always a pair.
- The chase's "drawn travel inside Legal's travel floor" is Camera's contract; the trail here is only the body's own path.
