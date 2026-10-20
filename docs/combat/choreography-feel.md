# Back and forth: recoil exits, ricochets, clash meets and turns

Owner: Combat and Choreography. Date: 2026-10-19. Paper, and parked data in `pending/choreo/feel.json`. Nothing is built.

**Orb** (homework 6, `docs/ep/vision.md`, 2026-10-19), on the launcher's rest: "more back and forth, impacts, dynamic clashing. both fighters should be backflipping out of strikes, ricocheting off of environmental elements."

**What is whose.**
- **Game Design** rules the feel: when each piece fires, its windows, its numbers and its limits. Every tick below is a first value for it to rule.
- **This paper is the moveset side:** what each piece looks like, which pieces it draws on, its three beats, and what Encounter, Animation, World and Camera need.
- **Camera now reads the choreography as a storyteller.** So every piece has a named anticipation, impact and follow-through, and one event that says so ahead of time (section 6).

**Three rules for all four.**
1. **One press is one attack, and the sim decides what lands.** These pieces change how a separation, a rebound and a trade play, and who acts next. They never turn a miss into a hit. The two that open a press window (the ricochet's counter and the turns) say so.
2. **Both fighters stay active.** After every exit somebody is moving toward somebody: no idle reel, no standing apart.
3. **No loops without an end.** Each piece has a count after which the exchange must resolve.

## 1. Recoil exits: backflips and handsprings out of a strike

When a blow separates the pair, the struck fighter's reel or knock-back is drawn as an acrobatic exit, by the weight of the blow. He regains control at the landing, which is the reel's own end, so the exit costs him nothing a reel didn't.

| The blow that separates them | Exit, on the ground | Exit, in the air | Ticks | Distance |
| :--- | :--- | :--- | ---: | ---: |
| A light (a string's end, a push-off) | **The skip:** two quick steps back | A short drift back, knees tucked | 10 | 1 bh |
| A medium (a stop, a medium's knock-back) | **The back handspring:** hands to the ground behind him, legs over, back on his feet | **The back tuck:** one tight rotation | 18 | 2 bh |
| A heavy that knocks back but doesn't launch | **The backflip:** a full rotation, landing in stance | The same, with more height | 24 | 3 to 4 bh |
| A launch | The air brake's skid, as built (`ab.skid`) | | | |
| A clash that splits (section 3) | Both, mirrored: handsprings for a medium meet, backflips for a heavy one | | | |

- **The stick shapes it.** The exit runs back along the knock's line; up makes it a high backflip, down a low handspring. It is presentation inside the knock-back's own distance, never a longer or shorter one.
- **A surface behind him within the exit's distance** turns the exit into a ricochet (section 2).
- **Beats:**
  - **anticipation:** the blow's hit-stop, 4 ticks with the contact held;
  - **impact:** the contact;
  - **follow-through:** the rotation and the landing. The landing tick is the moment control returns, so Camera frames the landing point.

| | The Protagonist (fluid) | The Anti-hero (snappy) |
| :--- | :--- | :--- |
| Handspring | Two hands, a twist in the air, lands facing the rival | One hand down, the other kept in guard, lands square |
| Backflip | A layout, arms wide, a long open arc | A compact tuck, no wasted rotation, lands in an exact crouch |
| Skip | A light bounce, weight on the toes | A short slide back on both feet |

**Needs:**
- **Encounter:** pick the exit by the blow's weight and the state (ground or air, a surface behind), match the knock-back's distance and the reel's length to the exit, and send `recoil`.
- **Animation:** the skip, handspring and backflip as shared poses, derived from the ground tech flip (`gc.tech_flip`, already a tucked backflip) and the bounce (`gc.bounce.rebound`), with flavour per fighter. About 8 shared and 4 each (estimate).
- **World:** the ground point at the landing, and whether a surface stands within the exit's distance.

## 2. Ricochets: off a wall, the ground or a prop, and back into a counter

When a fighter sent along a line meets a surface below the wall slam's speed, he plants on it and springs back toward the rival. Above that speed it is the wall slam or the building chain, as ruled (`wall-slam.md`; `buildings.md` §7.3).

| Surface | The plant | The rebound |
| :--- | :--- | :--- |
| **A building's face that holds** | Both feet flat on the wall, knees folding, a crack under the soles (no collapse below the wall slam's speed) | Mirrored off the wall's normal, bent toward the rival |
| **The ground at a slant, a ridge, a cliff** | Hands or feet set on the slope | Up and off it, toward the rival |
| **Flat ground** | A rebound off the hands (the bounce) | A low spring back |
| **A parked car** (a prop, World's option B) | Lands on the roof, which crumples | Off the roof, upward |
| **A post or a tree** | One hand catches it and swings him round | A turned rebound, round the post |

**The counter.**
- **A press of X, Y or B inside 6 ticks of the plant** makes the rebound a blow of that strength:
  - X: a flying knee or a jump kick;
  - Y: a driving medium;
  - B: a rebound heavy. It is drawn from his launch enders for the legs on a line (`pending/launch/enders.json`), so it can launch when the rules allow.
- **With no press,** he springs back unarmed, landing in range: both fighters are active again.
- **The rival sees it coming.** The plant is a tell of at least 6 ticks. The rebound blow can be guarded and perfect-blocked like any blow, and a perfect block of it is a clean answer.
- **Beats:**
  - **anticipation:** the flight toward the surface, then the plant. The plant has a 4-tick hit-stop and the crack. Camera frames the body, the surface and the rival together.
  - **impact:** the rebound blow's contact, or the plant itself with no press;
  - **follow-through:** the landing in range, or the rival's recoil exit.
- **The limit:** two ricochets in a row in one exchange, then the next surface is a plain stop.

| | The Protagonist | The Anti-hero |
| :--- | :--- | :--- |
| On a wall | A running step up the face and a turning push-off, sending him round and in | A flat two-foot plant and a straight piston push, coming back on a line |
| His rebound blow | A turning palm or an edge kick | A knee or the plate ram |

**Needs:**
- **Encounter:**
  - find the first surface on the send's path (World's query) and pick ricochet or wall slam by speed;
  - open the 6-tick window and pick the rebound piece by button and family;
  - count the ricochets;
  - send `ricochet`.
- **World:**
  - a surface query along a path: the point, the normal, the kind (face, ground, ridge, prop, post) and whether it holds;
  - cracks and dents below collapse;
  - parked cars as hashed props (`crowd-cars-buildings.md`, option B).
- **Animation:**
  - plant poses for the wall, the ground and the post, with the feet or hands solved onto the surface point by the contact IK (as the clinch's grip layer puts a hand on a body);
  - the post swing as two poses.
  - About 4 shared and 2 each (estimate). The coil-spring entries (`pe.plant_coil`, `w2.coil_spring`) are the push-off's nearest ancestors.

## 3. Clash meets: both trading at once

When both fighters' blows would land inside the same few ticks, they meet between the two bodies instead of both landing. Today's double hit (a level trade, both thrown apart) becomes the heaviest case of a family:

| Meet | What meets | What follows |
| :--- | :--- | :--- |
| **X against X** | Wrists and forearms knock | Both bounce back half a step. Pressing again meets again: up to 3 quick meets in a row |
| **Y against Y** | Elbows or knees | Both slide back 1 bh |
| **B against B** | The heavy clash: a ring of force between them | Both thrown into backflips (section 1), as the double hit is today |
| **Unequal** (X against B, and so on) | The heavier goes through | The lighter is knocked into his handspring or skip. It is the brawl's triangle, made visible |

- **It ends** in one of three ways:
  1. **a split:** both take mirrored recoil exits;
  2. **a break:** one wins a meet by timing (Game Design's rule), and his blow goes through;
  3. **escalation:** after the third meet it becomes the fist clash's pulse contest (`pending/wave5-clashes.md`).
- **Beats:**
  - **anticipation:** both wind-ups seen together. Camera frames both in profile, at equal weight.
  - **impact:** the meet at the midpoint, with a 4 to 6-tick hit-stop and the spark or the ring;
  - **follow-through:** the split's two exits, or the winner's blow landing.

| | The Protagonist | The Anti-hero |
| :--- | :--- | :--- |
| How he meets a blow | An open palm that turns the other strike aside as it meets | The forearm plate square on: a dead stop |

So the same meet looks different by who meets whom: a palm turning a plate, or two plates.

**Needs:**
- **Encounter:**
  - find two strike beats landing inside the meet window;
  - put the meet at the midpoint and resolve it by strength and timing;
  - count the meets;
  - send `clash_meet` and `clash_split`.
- **Animation:**
  - both strikers' ends solved onto one shared point (a paired contact, like the clinch's grip layer);
  - a meet pose per strength for each fighter, from the pair clash (`pp.clash`, `pp.clash.recoil`), plus section 1's exits.
  - About 3 shared and 3 each (estimate).
- **World:** none, unless the B meet's ring cracks the ground and breaks glass near it, as the duel of perfects does from level 3 (Game Design's to rule).

## 4. Turns: quick back and forth in place

The everyday back and forth, below the duel of perfects:
1. A's blow is deflected.
2. D's return comes at once.
3. A can deflect that in turn.
4. The initiative swaps back.

It is a ping-pong in place, not the flying rally of wave 3.

| Beat | What happens | Ticks |
| :--- | :--- | ---: |
| The deflect | A guard press in the turn's window (wider than a perfect block's) turns the blow aside | |
| The return | The deflector's return blow, quick, from his stop pool (lines and rises) and his reversal pool | |
| A turn, in all | The deflect and the return | 12 to 16 |

- **It runs 2 to 6 turns.** It ends when one fighter misses the deflect: he takes the blow and his recoil exit. Or when one escalates: a heavy is a meet (section 3); a launch is a link (launch anywhere).
- **It relates to the duel of perfects:** the duel is the perfect-only, escalating version; turns are its plain-timing cousin. Game Design rules the windows.
- **Beats, for each turn:**
  - **anticipation:** the incoming wind-up, read on the defender's side (his head turns to it);
  - **impact:** the deflect's small spark, and at once the return's contact;
  - **follow-through:** the returner's step in, which is the swap of initiative.
  - **Camera:** a 1% lean toward the new attacker at each swap, so the frame breathes with the turns.

| | The Protagonist | The Anti-hero |
| :--- | :--- | :--- |
| His deflect | A catch-and-turn: the palm meets the forearm and leads it past | A forearm check: the plate meets it and stops it dead |
| His return | A rising palm or a palm push | A straight fist or a knee |

**Needs:**
- **Encounter:** the turn windows, the swap of attacker and defender inside one exchange, the count, and `turn`.
- **Animation:** three deflects each (high, mid and low). The returns are existing pieces, with the join smoothing between them.
- **World:** none.

## 5. Pieces, in one count (estimates; Animation's figures to come through the EP)

| Piece | Shared poses | A fighter's flavour | Draws on |
| :--- | ---: | ---: | :--- |
| Recoil exits | 8 | 4 | `gc.tech_flip`, `gc.bounce.rebound`, `ab.skid` |
| Ricochets | 4 | 2 | `pe.plant_coil`, `w2.coil_spring`, the contact IK |
| Clash meets | 3 | 3 | `pp.clash`, the clinch's grip layer, as a paired contact |
| Turns | 0 | 3 | The stop and reversal pools |
| **All four** | **15** | **12** | About 39 for the two fighters |

No new strike piece is needed. Every rebound blow, return and meet is a piece the fighters already have.

## 6. For Camera: one event a piece, sent before it plays

| Event | Fields | Sent at | Anticipation | Impact | Follow-through |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `recoil` | who, kind (skip, handspring, tuck, backflip), weight, from, to, land tick, ground or air | The contact | The hit-stop, 4 ticks | The contact | The rotation, to the landing tick |
| `ricochet` | who, surface kind, point, normal, plant tick, strike (button or none), contact tick | When the send meets the surface on its path | The flight, and the plant | The rebound's contact (or the plant) | The landing in range |
| `clash_meet` | a, b, n, kind (x, y, b), point, winner (none for a split) | When the two blows are found to meet | Both wind-ups | The meet at the point | `clash_split` (both exits) or the winner's blow |
| `turn` | from, to, n, window, deflect kind | At each deflect | The incoming wind-up | The deflect, then the return | The returner's step in |

Every event carries `big` (one set piece in 20 s, Camera's rule 2), set false except on a B meet and on a ricochet whose counter launches.

## 7. For Game Design: what to rule

1. **The exits' ticks and distances** (10, 18, 24; 1, 2, 3 to 4 bh). Does the reel's length change to match, or does the exit fit inside today's?
2. **The ricochet:**
   - the speed below which a surface is a ricochet rather than a wall slam;
   - the counter's 6-tick window;
   - two in a row at most;
   - whether a rebound heavy can launch.
3. **The meets:**
   - the window in which two blows meet;
   - who wins a meet;
   - three quick X meets, then the pulse contest;
   - whether a B meet breaks glass.
4. **The turns:** the deflect's window against a perfect block's, and 2 to 6 turns.
5. **The AI's shares** of each, by level.
