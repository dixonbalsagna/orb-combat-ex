# The LT zip, its looks, Animation's 23 poses and 4 sketches: originality screen

Owner: Legal and IP Compliance. 2026-10-05. Screens `docs/vfx/zip.md` and its stills (`docs/vfx/img/zip-*.jpg`), `docs/design/melee-press-feel.md` section 2c, Orb's 2026-10-05 notes, `docs/animation/moveset-parts.md` sections 5 and 5a, and the contact sheets `art/animation/review/{rival4,protag7}` and `moves1-signature-sketches.png`. From stills and sheets only (the GIFs and the prototype were not played). A screen, not legal advice. The motion rules are data in `movegen-banned.json` under `motion` (m01 to m08).

| # | Item | Verdict |
| :-- | :-- | :-- |
| 1 | Tech zip with 2 ticks of travel | **Avoid as built; clear at 4 or more drawn ticks** (RL-076) |
| 2 | Filled, stacked speed and heavy ghosts | **Conditional** (RL-077) |
| 3 | The heavy's shrinking wind-up ring | **Clear**, with conditions (RL-078) |
| 4 | Counter and caught marks (and guard broken) | **Clear**, with conditions (RL-078) |
| 5 | Animation's 23 parked poses | **Clear by eye, conditional** on lint and a full-size look at four (RL-079) |
| 6 | The 4 signature sketches | **Conditional**: the held tells (RL-080) |
| 7 | Hip-zone width, flag 8 against lint 14 | **Both, by state** (RL-080) |

## 1. Is the tech zip a vanish step?

**As built, yes, near enough.** The body is at the start, then at the arrival 2 ticks later (about 33 ms), with echoes marking where it went. The nearest well-known staging is a fighter who disappears and reappears at the opponent, leaving afterimages. The legal point is not the echoes, which are fine, it is that the body is not seen travelling. Two ticks is a jump.

**What makes it clear (m01 to m04):**
- the body is drawn and opaque on every tick of the way in and out, never faded, hidden or replaced by a copy;
- **at least 4 ticks each way**, and never more than **3 body heights between consecutive drawn positions**, so the minimum is `max(4, ceil(distance_bh / 3))` (5 ticks at the top of the 12.5 bh band). Four ticks is still snappier than the speed reading's 6 to 8, so the tech reading keeps its character;
- the path is continuous and the echoes **trail behind** the body; none stands at the arrival point before the body gets there. Popping off back to front, ending at the body, is fine;
- the wire echoes and the thin line are fine as they are.

**The far-side exit** does not change the minimum, but adds one rule: the exit is its own drawn travel after the strike hold, over or round the rival with the rival in view, never an appearance behind him in the same tick as the strike. The zip "through" is clear when it is drawn travel past the body; it is a vanish step if he is simply there.

## 2. Filled ghosts (amends RL-052 for zips)

RL-052 asked for a thin outline for the dash afterimage because filled, body-coloured copies in a line are the stock afterimage image. A soft, faint, flat smear along the real path is a motion blur, which is ordinary. **Conditional** on m05 and m06:
- flat single tint in the **lane colour**, never the body's colours or face;
- 0.35 opacity or less, fainter with age; at most 5;
- on the body's **real recent path**, each overlapping the next by about a third, so it reads as a smear and not a row of standing figures; never in a ring, fan or spread round the target;
- gone within **8 ticks** of the zip's end (this replaces the 0.1 s for zips; Orb's 6 to 8 ticks fits);
- the real body on top, full opacity; no ghost stays as a stationary copy.
The stills (`zip-speed-in`, `zip-heavy-in`) meet these as drawn: faint, flat, blue lane colour, overlapping. The press styles' filled heavy ghosts take the same conditions, and the dash afterimage outside zips keeps RL-052.

## 3. Wind-up ring, counter and caught marks

- **Heavy wind-up ring (40 to 12 units onto the fist): clear.** It is not one of the seven marks, and there is no pose with it. Conditions (m07): hollow, thin, lane colour, shrinks only (never grows or holds), the wind-up only (10 ticks or fewer), never fills or becomes a ball at the hand. With the stance tell's aura and a shout it would count towards the two-mark limit, so no scream on a heavy zip.
- **Counter bar, counter diamond and double ring, caught ring and brackets, guard-broken fragments: clear** (the stills are small, hard-edged, lane-coloured). Conditions (m08): no text or numbers on the brackets (a lock-on is fine, a readout is not), nothing on the eyes or face, and no full-screen or body-wide gold, white or red flash from the guard-broken ring or the double ring.

## 4. The 23 poses (8 Protagonist, 15 rival)

By eye at sheet size, none is a recognisable signature, and `pose_lint` passes the Legal tags. Not seen: full-size poses, the reels. Conditions:
- **Look at full size before they go live:** `rm.fist_drop` and `rm.plate_hammer` (the arm is straight up at the contact frame) and `pm.palm_heave` (the rear arm is up while the front arm pushes). Each must lower at once and never be held, never a tell, victory or taunt pose.
- the palm rises (`pm.palm_rise`, `pm.palm_lift`, `pm.palm_heave`) stay open hands, feet down, no glow, as already tagged;
- the rival keeps no palm anywhere (Animation's own rule).

## 5. The 4 signature sketches

Held 30 ticks or more, so the held-pose rules decide them. **Conditional:**
- **Rival tell** (sunk stance, lead blade hand out at eye height, head low): clear if the hand is a flat open blade, edge on. Never a pointing finger or two fingers, never palm up and curling (a beckon), and the head-low sunk stance never has fists clenched at the sides (mark 1). Its end (arm lowered, head turned up) is clear.
- **Protagonist tell** (hands open, low and wide, palms down, circling step): this is the pose to watch. In the sheet the hands look close together near the waist. If the hands are within 10 units of each other or inside the hip zone for the 30 ticks, it is the cupped-at-the-hip and two-hand charge pose, held. Needs the hands **apart by at least shoulder width**. The end (hands loose, slight bow) is clear.
- Animation runs the wider hip zone and the `two_hand_chamber` and `wrists_together` numbers on both tell poses and reports the figures.

## 6. The hip zone (flag 8, lint 14)

Both, by state. **Closed fists in a transient wind-up** (the uppercut and short uppercut dipping at x 12) use the narrow zone of 8, as now: a fist dipping is ordinary boxing and Legal has cleared it. **Open hands or palms, and any held pose** (tells, signature sketches, held heavies' hold frame) use the wider 14. Today this refuses nothing: the rising palms chamber at x 18 or more. For held heavies the hold frame must also keep the hand at or below 80 high (the held-raise limit applied to the hold, not only the follow-through).
