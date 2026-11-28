# Ballistic shots: brief 4 of the combat overhaul, steps 1 to 3, ruled

Game Design, 2026-11-28, for the EP and Simulation. It rules the per-kind numbers for the directive's section 2 (`docs/ep/proposals/combat-overhaul-directive.md`, "The ballistic hybrid"), steps 1 to 3: seeking shots, lobs and the charged shot. Steps 4 and 5 (the beam as a stream; mines and deflections) aren't here.

**Orb:** "homing shots... need to be aimed and travel in a ballistic simulation like everything else".

**Everything sits behind one switch, `shots.json` `ballistic.enabled`, off on main.** Off, nothing changes and the golden doesn't move.

**What the code says today** (read for this page):
- Every shot the director fires at a rival is a seeker (`shots.gd` `fire`, `o.target`), which arrives on a set tick whatever he does. That covers the bolt (X) and the charged shot (the heavy blast, and the Driver's levels). Ground and water don't stop it.
- The lob is a fixed-time arc to a point.
- A launched fighter falls at 1,000 units a second squared (`fighter.gd` `DROP_GRAV`). A body height (bh) is 75 units.
- LT's dash works at any range: about 1,000 units a second on its first tick, flat out (3,500) by tick 12 (`power.json` `dash`). The slip moves at most 1.5 bh.

## 1. The numbers, per kind

| Kind | What fires it | Gravity share | Drag | Turn rate | Touch radius |
| :--- | :--- | ---: | ---: | ---: | ---: |
| `bolt` | X (E20), the stream | 0 | 0 | **3° a tick** | 14 (today's) |
| `arc` | any other seeking kind | 0 | 0 | 3° a tick | 20 (today's) |
| `charged` | B tapped (E41), the Driver (E124 to E127) | **0.15** | 0 | **2° a tick** | 30 (today's) |
| `lob` | Y (E30) | **1.0** | 0 | 0 | 24 (today's), then the 1.5 bh burst |
| `shard` | the spray | 0 | 0 | 0 | 10 (today's) |
| `mine` | laid (E70) | 0 | 0 | 0 | 30 (today's; step 5 moves mines) |

**Gravity share** is a share of a launched fighter's 1,000. **Touch** is a body within the touch radius plus `bodyR` 40 of the shot's swept path.

**Why 3° for the bolt, not the directive's 4.** I worked through a seeker against a defender who dashes across its path with LT, using LT's real ramp (about 1,000 units a second on its first tick, flat out by tick 12):
- **At 3° a tick,** an LT dash held 15 ticks dodges a bolt if it begins 4 to 18 ticks before the bolt arrives. That's a window of about a quarter of a second. At 4° the window is 5 to 15 ticks, about a sixth of a second.
- **The window is the same at any range,** because what decides it is the last few ticks. The range only decides whether he has time to see it coming. From closer than about 1,000 units the bolt arrives inside a reaction time, so up close the guard is the answer.
- **Too early and the seeker corrects.** A dash begun 25 or more ticks out is followed and hit. So the dodge is a timed sidestep, not a guess.
- **Flying flat out across its path and staying gone** also beats it at any time, because a bolt (60 units a tick) is barely faster than LT flat out (58). That costs wind (`energy-stamina-body.md` §2) and gives up the spot.
- **A slip or a brawl step never dodges a bolt by itself.** The seeker turns back onto him. Against bolts the answer is the guard (E24) or a real sidestep.
- **3, not 4, because Orb has to win this by feel.** A sixth of a second is a parry window, and Orb hasn't got the hang of the struggle's timing yet. A quarter of a second still asks for timing, and it still leaves a bolt that hits anyone who doesn't move.

**Why 2° for the charged shot.** It's the heavy: 10 ki, worth a heavy, trade power 4. A wider turn makes it easier to sidestep: an LT dash held 15 ticks dodges it if begun 5 to 20 ticks before it arrives. In exchange, its miss craters the ground (§3). A big shot should be the readable one, and missing with it should still cost the world something.

**Why no drag on any kind.** Drag slows a shot below flight speed, so it stops closing the gap (pillar 3). It also makes the solved lead and the lob's arc inexact. The column is there for later kinds (thrown rocks, debris).

## 2. The rules every shot keeps

- **Aimed, always** (the directive's model): a shot leaves along the right stick's line. With the stick at rest it leaves on the solved lead for his current velocity, with the beam's 15° of help.
- **A seeker turns toward him by at most its turn rate each tick,** after gravity and drag, and then moves.
- **One pass.** Once he falls behind the seeker (more than 90° off its heading), it stops seeking. It flies on along its line under its gravity and hits whatever it meets. **A dodged shot never comes back.**
- **Ground, water and standing buildings stop every shot,** seekers included. Cover is real: a ridge or the sea between them takes the shot. World's rule still says what a building takes.
- **In reach, the brawl's energy blows are blows** (E16's point-blank bolt, E35's blast). The switch doesn't touch them.

**Pillar 3: a shot that can miss still closes the gap.**
- **It always gets to him:** a seeker is faster than a fighter's free flight and keeps turning onto him until it passes, and a lob lands where he'd be from any range.
- **A miss is a near miss:** the seeker stays on him to the last ticks, so the shot visibly closes the gap, and the miss reads as the defender's move, not the game refusing.
- **A miss still lands somewhere:** it carries on to the ground, a building or a ridge behind him. A charged shot craters there, and a lob bursts where it falls.
- **Distance never blocks the drama, but it's no longer a guarantee.** That's the directive's "real gamble". The attacks that close the gap for certain are the snap, the long strike and LT, as S1 ruling 3 already said for beams.

## 3. The lob and the charged shot

**The lob: a real arc under a fighter's gravity.**
- **It's thrown on a solved arc that peaks 3 bh (225 units) above the higher of the two ends** and lands on the point he'd reach if he kept his velocity at the release. Gravity share 1.0, the same as a launched fighter: one gravity in the world.
- **Its flight is about 1.3 s on level ground,** longer when he's below the thrower. At a fighter's gravity, a 36-tick arc rises only 0.6 bh above the straight line, which isn't a lob. A lob that clears cover takes the time a real one takes.
- **E33's aim stands:** neutral lands on his course, and a lean toward or away moves the landing up to 4 bh.
- **E36's fighter variants become the apex,** within 1 bh either way (high and slow, low and quick), not 6 ticks either way.
- **E34's answers become movement:** a body that leaves the burst isn't hit. The burst's edge is worth half, so a late slip takes at most the edge. The guard and the shot that sets it off in flight are unchanged.
- **The cost:** a lob is slower to arrive than E30's 36 ticks. That's what makes it a skill shot over cover rather than a second seeker.

**The charged shot: a little gravity and a crater.**
- **Gravity share 0.15.** While it seeks, its turn rate absorbs it. After its pass it droops on its line. Fired down at a grounded target, a miss craters just behind him; fired level, it flies on and comes down on whatever stands in its way.
- **It craters where it meets the ground, hit or miss,** and where it hits a fighter within 1 bh of the ground (at his feet). Hitting a fighter in the air makes a burst, not a crater.
- **The crater's size is its energy's,** through the crater code that exists:
  - a full heavy blast makes E41's 2 bh;
  - a tapped one (0.4 of the damage) makes a smaller one, by the crater code's own law from energy to radius;
  - a Driver shot makes one by its level's `dmgMul`.
- No other kind craters. Bolts keep their scorch.

## 4. The E-rules under the switch (`energy-overhaul.md`)

- **E7, never out of range:** replaced by §2's pillar 3. The 45-tick arrival goes. Every shot still reaches him from any range in view and still closes the gap, but a timed move can beat it.
- **E20, the bolt:** 60 units a tick, seeking at 3° a tick, aimed along the stick or the solved lead.
- **E24, a bolt on a guard:** unchanged.
- **E30, E33, E34, E36, the lob:** as §3.
- **E41, the heavy blast:** one big seeker at 2° a tick, with gravity share 0.15, cratering where it meets the ground. Its worth, knock-back and trade power are unchanged.
- **E60, the energy grab's throw:** there's no thrown energy grab in the sim yet. When it's built, it follows §2 with its own turn rate.
- **E124 to E127, the Driver:** its shots are `charged`, with the same numbers, and the crater goes by its level.

## 5. The data (Simulation's file, so it's listed under NEEDS FROM EP)

`data/fight/shots.json`:
```json
"ballistic": {
  "enabled": false,
  "_note": "Game Design, docs/design/ballistic-shots.md (2026-11-28): brief 4 of the combat overhaul, steps 1 to 3. While enabled, every shot is a body: each tick gravity (a share of the launched fighter's 1,000), then drag (share of speed lost a second), then a seeker turns toward its target by at most turnDeg, then it moves; touch is a body within touchR + bodyR of the swept path. Off, shots travel as before",
  "seekEndsAtPass": true,
  "stoppedByGround": true,
  "stoppedByWater": true,
  "lob": { "apexBh": 3, "apexAbove": "higherEnd" },
  "crater": { "kinds": ["charged"], "fullBh": 2, "byEnergy": true, "atFeetWithinBh": 1 },
  "kinds": {
    "bolt":    { "gravity": 0,    "drag": 0, "turnDeg": 3, "touchR": 14 },
    "arc":     { "gravity": 0,    "drag": 0, "turnDeg": 3, "touchR": 20 },
    "charged": { "gravity": 0.15, "drag": 0, "turnDeg": 2, "touchR": 30 },
    "lob":     { "gravity": 1.0,  "drag": 0, "turnDeg": 0, "touchR": 24 },
    "shard":   { "gravity": 0,    "drag": 0, "turnDeg": 0, "touchR": 10 },
    "mine":    { "gravity": 0,    "drag": 0, "turnDeg": 0, "touchR": 30 }
  }
}
```
- `seekEndsAtPass`: a seeker stops turning once he is more than 90° off its heading.
- `lob.apexBh`: the solved arc's peak above the higher end. The lob's burst stays E30's 1.5 bh.
- `crater.fullBh`: a full heavy blast's crater. `byEnergy` scales the others through the existing crater code.
- `touchR` repeats each kind's `r` so that the switch owns its numbers. Simulation may read `r` instead if they must stay equal.

## 6. Acceptance (Simulation's check, switch on unless it says off)

1. **Off:** the golden is unchanged.
2. **Seekers hit what doesn't dodge:** a bolt, an arc shot and a charged shot each hit a target that stands still or flies a straight line at any speed below the shot's, from 600 to 6,000 units: 10 of 10 each.
3. **The timed sidestep, from 2,400 units, with LT held 15 ticks:**
   - **A bolt is dodged** when the dash begins 4 to 18 ticks before arrival: 10 of 10 at each tick. The window is at least 10 ticks wide and inside the last 25.
   - **A charged shot is dodged** when the dash begins 5 to 20 ticks before arrival: 10 of 10. The window is at least 14 ticks wide.
   - **Begun 25 or more ticks before arrival,** the dash is followed and the bolt hits.
   - **A slip or a brawl step alone** doesn't dodge a bolt.
4. **One pass:** in 200 dodged seekers, no hit after the pass.
5. **Cover:** no shot passes through ground or water (0 in a batch). A target behind a ridge or under the surface isn't hit through it.
6. **The lob:**
   - lands within its burst of a target that stands still or flies straight, from 600 to 6,000 units: 10 of 10;
   - peaks 3 bh above the higher end;
   - misses a target that turns or stops after the release and ends more than 2 bh off the solved point;
   - clears a 2 bh wall standing midway between them.
7. **The crater:**
   - every charged shot that meets the ground leaves a crater, hit or miss;
   - a full heavy blast's is 2 bh, and a tapped one's is smaller;
   - there's none from a hit on a fighter in the air, and none from any other kind.
8. **Determinism:** replays reproduce, with no new random draws.

**For QA's batch afterwards, against off on the same seeds:**
- match length stays in QA's band;
- the computer's energy hit rate by kind is reported;
- craters per minute at tiers 1 and 2 are reported (no fight levels the planet at low tiers).

## 7. Risks

- **The computer doesn't dodge by moving yet** (the stand-in's M3 on the beam trial says the same). Against it, every seeker in reach of its window lands unless it happens to be moving. It needs a timed LT sidestep at its level's rate. That's Encounter's, and it's asked of the EP; until then Orb's play page says so.
- **Bolts against a fighter fleeing flat out:** 60 against 58 units a tick, so a runner outpaces them, and at higher power levels by far. Brief 5's flee rules (F1 to F4) are what make running costly. Shots aren't meant to catch a runner.
- **The lob is slower than E30's 36 ticks.** If Orb finds it too slow in play, the lever is `lob.apexBh` (2 bh is about 1.1 s), never a gravity other than a fighter's.
