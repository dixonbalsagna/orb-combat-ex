# The three-strength brawl: sizing on paper (2026-10-06)

Owner: VFX Director. A plan only; nothing is built. Read: docs/design/brawl-second-pass.md §2, §3, §7, §11; docs/legal/movegen-banned.json (f01, f04, f05, k01 to k04, h01 to h05). Everything below is presentation, read from the sim and the beats the way the press styles are, so it never touches the gameplay hash. The new cues and beat args it needs are listed at the end; until they exist I build against a staged one, as for the zip.

## What exists and is reused

The press styles (speed, tech, heavy, block; `press.gd`, `shots_view.gd` `_press`) already draw a blow's after-image and contact look from a `damage` event and the beat's `style`, `grade`, `closing`, `charge`, `hand`. The three strengths slot in as follows: X is today's light, Y is today's heavy strike, B is a new tier. The doc says the looks stay "the ones set for speed, on all three" for the flurries, so the first build adds almost no new shapes: it adds a **wind-up**, a **full-charge flash**, a **burst smear** and a **double hit mark**.

## 1. The wind-up (Y 12 ticks, B 28 ticks) and the charge (held Y, held B)

| What | Look | Quads | Legal |
| :-- | :-- | ---: | :-- |
| Y wind-up | The heavy's shrinking hollow ring on the loaded limb, last 10 of its 12 ticks (the existing wind ring, `wr`), lane colour. No body mark | 1 | k01 (one mark), h05 (the pose is Animation's: loaded limb at shoulder height or lower) |
| B wind-up | The same ring over 28 ticks, drawn thinner and slower, plus a thin line along the loaded limb's path to where it will land in the last 6 ticks (the riposte's committed line, reused) so a rival can read the length of it | 2 | k01: ring and line are one mark each, never with an aura; checked every tick of the 28 |
| Held Y (full at 24) and held B (full at 44, goes by 70) | The ring stops shrinking and holds at its small size while charging, with a few short streaks drifting toward the limb (the tech echoes' pop timing, reversed). At the full-charge tick: the flash | 1 to 3 | k03: a thin ring or edge flash on the hand, forearm or plate, lane colour, at most 4 ticks, never body-wide, never gold, white or red, no shouted name; a held B shows at most two of the seven marks at any tick |
| **Full-charge flash** (Y at 24, B at 44) | One thin ring at the hand, 4 ticks, shrinking; the just release (4 ticks after) gets the same ring once more, smaller, so the player can read the window | 1 | **Open:** k03 lists tier marks at 12, 14, 24, 40, 48. B's full flash at 44 is not on that list: Legal to confirm 44 or the design to move it |
| Armoured wind-up | Nothing drawn on the body (an armour glow is a body-wide mark). The armour reads through the hit: a light that meets it throws a small spark at the contact and the rival is not reeled (Animation's) | 0 | k01, k04 |

Reduced motion: the rings stay (they are still and thin); the drifting streaks and the repeat ring on the just release go.

## 2. The three flurries

The doc keeps the looks "those set for speed". So: the X flurry is the speed blur on the one striking limb at 5 to 10 blows a second; the Y flurry is full blows (one whole strike each, the speed look's after-image and ring); the B flurry is one hammer blow every 28 ticks, each wound up in plain sight (section 1's ring) with the heavy's contact look (crescent and double ring).

Two limits shape the X flurry's smear (Legal f01): at any instant at most **2 ghosts of any one limb and at most 4 limb-ghosts on screen in all**. At 10 blows a second the press styles' present "one after-image per blow, alive 8 ticks" would put up to 5 alive at once, so the X flurry needs a different rule: **one limb, one smear, re-seeded each blow**, at most 2 ghosts of it alive (the two latest blows' end points), life 4 ticks, never a fan. Both fighters flurrying: 2 + 2 = 4, which is the cap, so a third source (a burst on one side) must take from the same pool: a small per-instant counter in `VfxPress` (`limb_ghosts_alive`) that every after-image draw asks before it spawns. That counter is the one new mechanism in the whole plan.

Quads: X flurry about 6 a fighter, Y flurry 7 per blow (one at a time), B flurry 38 for the release as the heavy has now.

## 3. The burst (held X, eight blows, gaps 4, 4, 5, 6, 8, 11, 15)

Legal f04 and f05 decide the look:
- **f01:** one limb at a time, at most 2 ghosts of it, 4 in all, the counter above.
- **f04:** the three fastest gaps (4, 4, 5) are the opening; the smear thins from the fourth blow on, so the picture itself slows down in step with the gaps: ghosts per blow 2, 2, 2, 1, 1, 1, 0, 0 (blows 7 and 8 are single clean strikes with a ring).
- **f05:** the hands alternate, never the same limb, tip, path or place twice (Animation chooses the limbs; VFX draws the path it is given), so VFX never repeats a smear on the last blow's path: when `beat_args.hand` equals the previous blow's, it draws the second blow's ghost on the other hand's path or drops it. No slow-motion close-up or camera cut (Camera's, noted).
- One lane-coloured contact tick per blow (the speed look's small ring), so eight contact marks over 55 ticks; the sound is one breath (Audio's).

Quads: at most 9 at the opening, 3 at the tail.

## 4. The double hit (an even mash, 240 ticks, both land)

A mutual throw-back is Legal k04: sparks at the contact point only, **no rubble ring with cracks and wind, no lightning, no body-wide aura, no gold, white or red flash**. So the double hit is two contact looks at the same tick, mirrored: each fist's heavy contact (crescent and double ring) at the other's face line (the mark sits below the face as for the zip's marks, m08, or at the contact point as k04 says; the contact point wins), then two thin dust trails along the ground under each as they are thrown back (the skid's `thin_puffs`), in opposite directions. About 14 quads and 20 puffs, both gone in 20 ticks. The picture-in-picture close-up is Camera's and Animation's; VFX draws nothing new in it except that the same marks are drawn into the close-up's view if the view is a second `VfxLayer` (the split screen's layers already do that).

## 5. Budget

Quads in the shots view's one draw. Worst instant: both fighters mid-flurry, one with a full-charge flash: X smear 6 + Y blow 7 + one flash 1 + the existing contact marks 20 = about 35 on top of the present worst test tick of 84 of 380. No debris except the double hit's puffs (20). One new counter, one new Fx style (`flash_ring`), one new mark (`double`); no draw call and no new pool.

## What I need when it is real

- Encounter: beat args `strength` (x, y, b), `windup_ticks`, `charge` (0 to 1) and `full` (flash tick) on the strike beat, a `charge_full` cue (actor, button, tick), a `double_hit` cue (both slots, point) and `burst` (n of 8) on the burst's beats, all read the way `VfxPress.beat_args` reads `style` today.
- Animation: the limb of each burst blow (`hand`), and `press_path` for the wind-up's committed line.
- Legal: the 44 tick question (section 1) and a reading of the X flurry's one-limb-one-smear rule against f01.
- Camera: the double hit's close-up, and nothing on the burst (f05).

## Tests when built

A flurry never has more than 2 ghosts of a limb or 4 in all (asserted across a 10-blows-a-second run with both fighters); the burst's ghost count falls with its gaps and never repeats a path; a wind-up and a charge never show more than two of the seven marks in any tick of 70; the flash lasts 4 ticks or fewer; the double hit draws no ring, crack or flash over a body; hash_check and both determinism runs unchanged.

## Built (2026-10-06): Encounter's final cue names, ahead of the sim

`render/vfx/reach.gd` (state and cues), `shots_view.gd` `_reach` and `_press` (drawing), `press.gd` (the counter); `effects_check.gd` `_brawl()`; stills `img/br-*.jpg`.

| Piece | Cue it hangs on | What is drawn |
| :-- | :-- | :-- |
| Wind-up rings, Y and B | cue `windup` text `start` (actor, target, `source` the cell, `dur` seconds, `n` the landing tick) and text `end` (`k` 1 thrown, 2 stopped by a blow, 3 lost, 4 a miss) | A ring with a darker edge on the lead hand: a medium's closes over the last 10 of its 12 ticks, a heavy's (28 ticks, told by `dur` of 20 ticks or more) over its whole time with the limb's committed line to the rival in its last 6. Stopped: four fragments; lost: the ring fades; thrown or a miss: gone, and the blow's own looks take over. Not a flash; nothing on the body (the armour is not drawn) |
| The limb-ghost counter (f01) | every blow's `damage` event | `VfxPress._grant_ghosts()`, each tick: a speed blow's smear is one limb-ghost, a tech blow's echoes one each while alive; the newest are granted first, at most 2 of any limb (slot and hand) and 4 in all, so in a flurry the two newest smears of a limb draw and older ones fade without theirs. `ghost_peak`, `ghost_peak_limb` and `ghost_refused` expose it. A 2-second mash from both fighters peaked at 3 in all and 2 of a limb, with 5 smears withheld |
| The burst's thinning smear (f04) and alternating hands (f05) | beat arg `burst` (the blow's number, 1 to 8) with `hand` | The smear keeps 2, 2, 2, 1, 1, 1, 0, 0 of its parts (the contact ring always stays), and if a burst blow's hand equals the last one's it is flipped, so no limb repeats. Assumed: `burst` on the beat args; without it a blow is an ordinary flurry blow under the counter |
| The double hit (k04) | cue `double_hit`, 8 ticks ahead (actor, target, `n` the landing tick) | At the landing, a crossed crack, sparks and a hollow ring on each face line in each fighter's own colour, one small flash for the pair if the register grants `double_hit`, and dust along the ground under each as they are thrown apart (the debris pool's). No rubble ring, cracks in the ground, lightning, aura, gold, white or red |
| The whiff | cue `miss` (actor the one who missed, target, text `gave_ground`, `reach` or `dodge`) | The blow's arc cuts the air and ends in nothing: a dark core on a light edge, drawn out over 3 ticks, gone in 8, and a little dust at the feet of whoever moved |
| B now | cues `launcher_open` (actor the launcher, target the staggered, `n` the tick the stagger ends, text the kind) and `launcher_close` | A chevron on each side of the staggered fighter until the close or the stagger's end. No longer on any stagger of 12 ticks or more |
| The full flash on energy | cue `energy_land` `k` | `k` 1 marks the one blow in 20 ticks that may take the full flash (the register still decides); with no `k` the 1-in-20 pace is ours |

The full-charge flash and `charge_full` wait for C2b.

**A correction to what I told Legal.** I said the tech blow's three echoes never had more than two alive at once. That was wrong for a perfect blow: all three were drawn for its first 2.5 ticks. A perfect timed blow now draws two echoes (the counter and a clamp in `_press`), so the claim is true and RL-106's "as built" holds as of this change. Orb's reference showed three; this is Legal's ceiling, and I have told the Executive Producer.
