# The ricochet's glance in the core

Owner: Simulation and Engine. 2026-10-22. The core's build of Game Design's glance (`docs/design/fight-feel.md` section 3; `rulings-2026-10-22.md` 2b, re-ruled in 4), on the EP's briefs of 2026-10-22. **Built and proved in scratch, parked at `pending/ricochet/` (re-cut to the ruling of 4); nothing is in the tree.** Behind one data switch that is off: with it off, every match, replay and checkpoint is the same to the bit.

## 1. The rule as built

| Rule (Game Design's) | As built |
| :--- | :--- |
| **The line: 1,500 units a second of his whole speed** (re-ruled by Game Design, `rulings-2026-10-22.md` 4: it was the speed along the surface's normal, and nothing glanced) | `line`, on the normalised velocity's whole speed (the traversal factor divided out, as World's contact reads speeds) |
| **The surfaces: a building's face, and ground sloped 30° or more** (a hillside, a ridge, a cliff, a crater's wall). On flatter ground the knocked-about rules stand: the skid (Orb's own picture), the bounce, the tumble, the slam | `minSlope` 30. `SimRicochet.steepGround(s)` for World's landing; a face always counts |
| **At or above the line, under 40° to the surface: the glance.** 0.7 of his speed, angle in equal to angle out, and he doesn't stop | `SimRicochet.rule(vn, vt, inRow)`: the normal part reflected and both parts × `keep`. He leaves the surface and flies on |
| **At or above the line, steeper:** the wall slam, the lodge or the chain, as ruled | Unchanged. The rule says "not a ricochet", and World's contact goes on as before |
| **Below the line: Combat's plant** | The rule classifies it (`BELOW`). The plant itself is Encounter's, and it tells it through `told` (kind plant), so it counts in the same row and sends the same event |
| **At most two ricochets in a row,** plants and glances together; then the next surface is a plain stop | `maxInRow` 2, counted per send (`Fighter.rics`, with the launch number it belongs to). At the cap the rule says "not a ricochet", and World's contact takes it as it would today |

**Where it acts**, by World's granted lines (`pending/ricochet/grant_world.py`):
- **Ground sloped 30° or more:** World's landing (`WorldContact._land`) already measures the contact in the slope's frame. A glance there is a new branch before the slam, taken only when `steepGround` says so. It is paid and told as a bounce that keeps 0.7: the wear and the area by the speed it removes, World's `bounce` event with its `keep`, and his leaving the ground. Not on the sea, not past the journey's own caps, and never on flatter ground.
- **A building's face:** World's hit test (`WorldBrunt.checkHit`, and its swept form with depth on) asks `SimRicochet.offFace` first. A fast send steep to the face (moving along it) glances off. He stands just outside the face, no longer aimed at it, and the building takes nothing.

**The curve:** a glance ends the launch curve's paced leg (`flight` end, kind glance). His velocity first takes the speed he showed, so the glance keeps 0.7 of what the camera saw.

**The event:** `ricochet` (`fx-events.md`): kind glance (or Encounter's plant), the surface, where, his direction and speed after it, and the count in the row. Encounter's choreographer and Camera read it; it is also VFX's scrape and Audio's.

**For the choreographer:** `SimRicochet.predict(vx, vy, nx, ny, inRow)` gives the kind and the velocity after, for any surface normal. With the launch curve's `Track` (`SimFlight`, on main), a planner can step a send to its first contact and ask what that contact will do. World's own journey predictor runs the same branch, so it already predicts glances off steep ground.

## 2. My readings, for Game Design to confirm

- **"In a row" is one send.** The count starts again at every send. A bounce or a skid between two ricochets doesn't reset it.
- **"A plain stop"** after two is the contact as it is today (a slam, a bounce, a skid), not a new kind of stop.
- **A glance pays like a bounce that keeps 0.7:** wear and area damage by the 30% of the speed it removes, and World's contact hit-stop (0.06 s). Game Design's "doesn't stop" is read as the body flying on, not the clock.
- **A face glance strikes nothing:** no damage, no mark. World may add a scrape.
- **The surfaces are a building's face and ground sloped 30° or more** (Game Design's ruling). A parked car, a post and a tree don't stop a flight today; they join when they do. The interior chain's slabs are World's chain, and are left to it.
- **With ground contact off** (old profiles only), there is no glance.

## 3. In the core

| Where | What |
| :--- | :--- |
| `ricochet.gd` (new) | `SimRicochet`: the data, `rule`, `predict`, `inRow`, `told`, `offFace` |
| `state.gd` | `S.ricOn`; `Fighter.rics` and `ricN` |
| `sim.gd` | The switch at a new match |
| `hash.gd` | The row, only while on; the event's fields |
| `replay.gd` | `data/fight/ricochet.json` in the data hash, only while on |
| `fx.gd`, `view/fx.gd` | The `ricochet` event |
| `flight.gd` | `SimFlight.endLeg`, public |
| `tools/parity.gd` | One check |
| World's `contact.gd`, `brunt.gd` | The landing's branch, the body's count, the tell, the face's call (`grant_world.py`) |
| Tools' schema | `grant_tools.py` |

## 4. The proof

**The check, "the ricochet's glance":**
- **Off:** a replay carries no ricochet data, and a contact is World's as before.
- **The rule by its cases:** a glance; one only 1,000 into the surface at a whole 3,162, now a glance (the line is the whole speed); under the line; steeper; a full row; moving away. **The slope's scope:** slopes of 0 and 0.5 (27°) are not a ricochet's ground; 0.6 and -0.7 are. `predict` agrees on a level surface and on a face.
- **On the test world's steep uphill** (49°, found by the check), a send 20° into the slope at 3,000:
  - it glances once, told with `n` 1, and flies on upward with 0.7 of its speed;
  - World's bounce event keeps 0.7.
- **Not glancing:** the same send with the switch off, with a full row, or at 1,200 (under the line), and a send 60° into the slope (World's bounce). **A fast shallow send on level ground skids** (Orb's skid stands).
- **With the curve on:** the glance ends the paced leg.
- **A building's face:**
  - a send steep to it at 2,000 into it glances, reflected and no longer aimed;
  - at a whole 1,077, or near level to the face's normal, it doesn't.
- **A match with the ricochet on** replays, and carries the data.

**Results:** in `pending/ricochet/README.md`.

**In play, as re-ruled** (scratch probes, 6 AI matches of 7,200 ticks, the default world, every match with the switch on played twice and the same both times):
- **2 glances in the 6 matches** (seeds 4 and 5), none off a face, with 3 to 6 sends a match.
- **With the switch off, of 58 ground contacts, 51 were on level ground** and 7 on ground sloped 30° or more. Of those 7, by the rule: 3 glances, 1 under the line (a plant), and 3 steeper.
- **So QA's row** (plants and glances 2 to 8 a match) **reads under in AI play:** about 0.5 a two-minute match, so 1 to 2 a seven-minute one, plants included. The fights happen on level ground. Game Design named the lever: the choreographer's taste for sends at walls and slopes (Encounter's), not the line.

**Before the re-ruling** (the line on the speed into the surface, any slope): no glance in the same 6 matches. First contacts met the ground at a median 1,219 into it, and the 16 contacts under 40° ran at a whole median 2,058.

## 5. Not in this window

| What | Whose |
| :--- | :--- |
| The plant below the line, its counter and the dodge-aimed spring; the wall kick's push (2b) | Encounter, with Combat |
| The AI's shares, the choreographer's taste for ricochets | Encounter |
| The scrape's look and sound; the camera's framing of a glance | VFX, Audio, Camera |
| A face's scrape mark, and any surface beyond the ground and the faces | World |
| QA's rows: plants and glances 2 to 8 a match | QA |
