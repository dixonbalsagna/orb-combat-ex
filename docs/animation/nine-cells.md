# The nine cells: what the body shows, what plays today, what is built

Owner: Animation. Date: 2026-10-12. **Paper first, then what needed no sim change, built in scratch and parked** (nothing here is committed; the EP applies it). The brief: Game Design's acceptance table, `docs/design/brawl-second-pass.md` section 15 (X, Y and B each tapped, mashed and held), and Orb's: "every attack has some meaningful way to be utilized either held, tapped, mashed rapidly". On the phone's Simple layout Attack is read by how long it is held, so the body has to teach the difference.
Render only; the gameplay hash is untouched. Every number is a first value. Headless only.

## 0. What I found first: three of the studies Orb liked never played in the live brawl

I drove the brawl with a scripted pad on slot 0 against the medium AI (`anim_check` `_cells_run`, the probe in this note's section 6), each cell pressed its own way, and read the body's own debug.

1. **The `burst`, `medium` and `super` press-style rows were never reached.** The brawl's beats carry an explicit `style` ("speed" for a light, "heavy" for a wound blow), and my map from the beat's `strength` came after it. So a held X's blows played the plain `speed` row; a Y played the old `heavy` row, wound for the style's own 14 ticks; a B the same. The three flurry studies (the burst's slowing hands, the drum roll of mediums, the hammer blows wound in plain sight) played nowhere.
2. **A held B was drawn wrongly.** The sim keeps the wound blow after its 28 ticks while the button is down (the tap rule's wait, the charge from 32). The body threw the blow at its 28th tick anyway, stood idle through the whole charge (22 to 24 ticks in the trace), and threw a second, four ticks long, on the release. So the charge showed nothing and the release was a pop.
3. **A held X's set pose could not play.** The sim creates a burst's blows only as they are due (2 ticks ahead), so there is never a next beat to key the "set" on.

All three are fixed in scratch (section 3). Nothing else in the tier or the energy pieces plays live: the brawl's `_piece` draws from `data/combat/recipes.json` (today's pieces), and Combat's `recipes.brawl.json`, which names `su_*`, `pk.*` and `rk.*`, is still parked.

## 1. The nine cells

"Today" is the live brawl as measured before this paper; "Plays now" is with the scratch build.

| Cell | Today | What the body must show, to tell it apart | What I built (scratch) | What it needs from others |
| :--- | :--- | :--- | :--- | :--- |
| **X tapped** (the beat) | One light, `speed` row, a 2-tick wind-up (so it pops to the contact key; unavoidable at 2 ticks). The beat is not built | A blow placed and its **return** held a tick longer than a flurry's: the pinned contact and the clean snap back are the beat, not a bigger blow | Sketch only (section 4) | The beat on the sim's side (slice C3, Orb's yes). A cue for "on the beat" |
| **X mashed** (the pressure) | `speed` row, 30 blows in 200 ticks at a 7-tick tap; the hands alternate; a different piece each time | A drum roll of hands, never one limb repeated: exists. And a heavy's **armour must read**: a light landing on a winding heavy barely moves him | The armour read (section 3.5) | Nothing |
| **X held** (the easy pressure) | Before: the burst's blows played the `speed` row, so the curve showed only in the sim's gaps, and the set pose never played. A light, a 16-tick wait, seven more | **One move easing into a rhythm.** The set (the body loading, 5 to 16 ticks after the press), then blows that start as short quick snaps near the guard and open out to full blows as the gaps lengthen; the same hand alternation throughout | The `burst` row now plays (blows 2 to 8, with `gap_amp`); the set pose by the live X read; the floor pace's blows (9 and on) continue in the same row, at a 10-tick gap close to full range, so it reads as the rhythm the curve reached and not a second move | The floor pace itself (Encounter, pass 1): its blows carry a `burst` number 9 and on. A public read for "X held, burst not begun" in place of my two private slots |
| **Y tapped** (the stop) | A 12-tick medium, `heavy` row wound for the style's own 14 ticks, so most of the tell sat before the beat existed | A wind-up **in plain sight for all 12 ticks**, reading as shorter and snappier than a heavy's, and the stop's own look: a heavy that was winding loses it (windup end k 2) | The sim's own wind-up drawn whole (cue `windup` dur); the `medium` row | The stopped heavy's look (section 3.6: a small broken-wind-up flinch, not built) |
| **Y mashed** (the grind) | 24 blows in 200 ticks on the `heavy` row | A **drum roll of full blows**: each wound in plain sight, the carry blending one into the next, the weight rolling | The `medium` row plays; wind-ups whole; overlapping windows compress to the gap | Nothing |
| **Y held** (the patient close) | A medium that lands late; no charge exists (pass 2) | A **coil of its own**: forward and patient, one shoulder wound back, loading from 10 to 28 ticks (charged from 16, full at 24), a flash at full | The `hold` row on the `medium` style and four hold poses (`ch.y_p`, `ch.y_r`, `ch.b_p`, `ch.b_r`); the held layer. Viewable now in the study (`yhold`) | The charged medium (Encounter, pass 2); its `charge_full` cue (the same cue name) and the VFX flash |
| **B tapped** (the hammer) | 28-tick wind-up, `heavy` row; the launcher's 14 ticks | The **heavy's wind-up whole and slow**: a tell plain from the first tick (28), and the launcher's 14 as its own shorter read | `super` row; the cue's dur (28, or 14 for the launcher) drawn whole | Nothing |
| **B mashed** (the advance) | 8 heavies in 220 ticks; lights stagger him as they would anyone | Heavy after heavy **wound in plain sight**, and the armour: lights do not shift him | Armour read; `super` row | Nothing |
| **B held** (the big read) | The old failure above: thrown at 28, idle through the charge, a 4-tick pop on release | A **charge you can watch**: the chamber held, the body sinking and winding round for 18 ticks to full at 44, a shudder at the flash, then the release from that pose | The held layer (chamber, `hold` row to 46, a shudder from `charge_full`), the release carried out of the held pose. 62-tick holds checked for all 16 tier pieces | The release's own blow is the sim's 4-tick beat: fine; the `charge_full` cue is sent already |

## 2. What the body teaches by hold length (the phone's Simple layout)

Attack is read by how long it is held, so the milestones the UI marks at 12 and 28 ticks have to be in the body. The scratch build puts them there:

| Held for | Tapped (button up) | Held on |
| ---: | :--- | :--- |
| 0 to 4 | the light, at once | the wait, the set pose coming up from 5 (a held X) |
| 12 | a Y's wind-up is complete: the medium goes | a Y's chamber reached (6 ticks in) and held: it is a medium waiting |
| 16 | the Y goes by itself at a tap's strength | a held X's burst begins (the set pose is gone by 16); a Y's coil starts (charged medium, pass 2) |
| 28 | a B's wind-up is complete: the heavy goes | a B's chamber reached (14 ticks in) and held: a heavy waiting |
| 32 to 44 | | **a B charges**: the body sinks and winds round (`ch.b_*`); full at 44 shudders |
| 70 | | by itself |

So a player who watches his own body reads, without a ring: "I am a medium waiting", "I am a heavy waiting", "I am charging". The held X is the only one that *moves* while it is held, which is its identity.

## 3. What is built (scratch, parked, all inert until named)

1. **The strength map, and when it plays (revised 2026-10-12 at the EP's ruling: the default picture is unchanged until Encounter's hook lands).** A beat that carries a `strength` and names **no style row** of its own gets its strength's row (light `speed`, medium `medium`, heavy `super`, a beat with a burst number `burst`), flurry or not. A beat that names a style row (today every brawl beat does: `speed` or `heavy` at brawl.gd 351, 504 and 801) keeps it, so **today's picture is exactly the committed one** (proved: section 6). `RenderAnim.strength_styles` (default **false**) forces the map over a beat's explicit `speed`/`heavy`: how the nine cells are seen on a sim that still stamps the style. The first brawl beat that carries a strength and no style row sets `RenderAnim.hook_seen`, and from then on the nine cells' other looks (the wind-ups drawn whole, the held charge, the armour read, the held X's set) play with no switch: `RenderAnim.second_pass()` is `strength_styles or hook_seen`.
2. **The sim's wind-up drawn whole** (`_cue_windup`). The cue `windup` start (`dur`, the landing tick) fixes the wind-up's length for that blow, so a Y's 12 ticks and a B's 28 (14 for the launcher) show from the first tick. Matched by landing tick within 4 ticks (a hit-stop in between shifts it).
3. **A held wound blow** (`_held_layer`). While `DirBrawl.winding(S, f).left` is -1 (the sim holds the blow past its landing) the body keeps the chamber of the blow it was winding and the style's `hold` row loads it; the release is the sim's next beat, which the carry blends out of that pose. `charge_full` makes it shudder (a third of a unit, no light).
4. **The hold row** on `medium` (10 to 28) and `super` (28 to 46), each with its own legs-pelvis-spine poses (wave `charge1`, 4 poses, prefix `ch`): the held Y and the held B are bodies of their own.
5. **The armour read** (`AnimFighter.armoured`, set by the dispatch from `DirBrawl.winding`): while a heavy winds or charges in him, a light's reaction is 0.3 of its force and half its amplitude.
6. **The held X's set** keyed on the brawl's own slots (`X_LIVE`, `BURST_N`: pure reads), 5 to 16 ticks after the press, then the burst's row takes over. The next-beat path (`_burst_set`) stays for the floor pace.
7. **Not built:** the stopped heavy's flinch (a wind-up ended by a blow: windup end k 2), the double hit's own poses, and the beat.

## 4. The tapped column's skill strike on the beat (a sketch; Orb has not confirmed the direction)

What it must show, if it comes: "the pinned pose and its return, which is the beat". A light placed on the beat is worth 4 and clears the rival's run, so it has to be **different at a glance from a flurry's light** or the player cannot learn the timing.
- **Parts:** no new key sets. The same light, drawn on a `tech` row that exists (a wire echo, a held contact `hold_ticks` 6 to 10 by grade: perfect 10, good 6, off 4: already data) and a return that eases out over 8 ticks instead of snapping.
- **What is new and small:** a *grade-keyed pin*: the contact key held for the grade's ticks while the rest of the body keeps moving (the follow-through arriving late): two sizes of one new pose-mix, no new poses.
- **Needs:** the sim's grade on the beat (`grade` exists on B0's beats: `perfect`, `good`, `off`, `none`), the skill strike's cue, and VFX's tick. Nothing more of mine until Orb confirms.

## 5. New parts and their sizes

| Part | Size | Where |
| :--- | :--- | :--- |
| Hold poses for the held Y and the held B | 4 poses (`ch.y_p`, `ch.y_r`, `ch.b_p`, `ch.b_r`), legs, pelvis and spine only | built |
| The held layer, the armour read, the strength map, the wind-up cue | about 180 lines in `anim_fighter.gd` and `render_anim.gd`, 3 data rows in `press_styles.json` | built |
| The stopped heavy's flinch | 3 shared poses (a broken wind-up: shoulder dropping, the loaded arm falling, a half step back) | proposed |
| A distinct full-charge look for Y vs B | none beyond the shudder; the flash is VFX's | none |
| The skill strike | 0 poses, 1 mix, a grade pin | sketch |

## 6. How it was checked

- `anim_check` `_test_cells`: the live brawl, scripted pad, medium AI: a held X plays the `burst` row and its set (0.90); a mashed X plays `speed` only; a mashed Y plays `medium` only with the sim's wind-ups drawn whole; a held B shows 23 hold ticks and loads to 1.0.
- All 16 tier pieces on 62 ticks (`_test_windups`): nothing above 80 before the last 6 ticks, every contact solved, loaded to 0.6 or more.
- Gates on a clean export of HEAD plus these files: see the report.

## 7. What I need from Encounter

1. **Drop the explicit `style` at brawl.gd 351, 504 and 801** (a beat then carries `strength` and, for a burst, `burst`); the map is mine and plays by itself the moment a beat has none. Keep `style` only where a row is meant (`tech`, a riposte's, a double hit's). If Encounter would rather name the row, a beat field `look` (`burst`, `medium`, `super`) is the cleaner way and I read it first.
2. **A public read for "a held X, no burst yet"** (`DirBrawl.heldX(S, f)`: live ticks since the press, else -1). I use `X_LIVE` and `BURST_N` today; that couples me to two private slots.
3. **The floor pace's blows carry `burst` 9 and on** (any nonzero number is enough) so they stay in the one move.
4. **The release of a held blow keeps its beat's `strength`** (it does: `heavy`), and `charge_full` for Y when the charged medium lands.
