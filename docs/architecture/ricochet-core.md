# The ricochet's glance in the core

Owner: Simulation and Engine. 2026-10-22. The core's build of Game Design's glance (`docs/design/fight-feel.md` section 3; `rulings-2026-10-22.md` 2b), on the EP's brief of 2026-10-22. **Built and proved in scratch, parked at `pending/ricochet/`; nothing is in the tree.** Behind one data switch that is off: with it off, every match, replay and checkpoint is the same to the bit.

## 1. The rule as built

| Rule (Game Design's) | As built |
| :--- | :--- |
| **The line:** 1,500 units a second into the surface, the speed along its normal | `line`, on the normalised velocity (the traversal factor divided out, as World's contact reads speeds) |
| **At or above the line, under 40° to the surface: the glance.** 0.7 of his speed, angle in equal to angle out, and he doesn't stop | `SimRicochet.rule(vn, vt, inRow)`: the normal part reflected and both parts × `keep`. He leaves the surface and flies on |
| **At or above the line, steeper:** the wall slam, the lodge or the chain, as ruled | Unchanged. The rule says "not a ricochet", and World's contact goes on as before |
| **Below the line: Combat's plant** | The rule classifies it (`BELOW`). The plant itself is Encounter's, and it tells it through `told` (kind plant), so it counts in the same row and sends the same event |
| **At most two ricochets in a row,** plants and glances together; then the next surface is a plain stop | `maxInRow` 2, counted per send (`Fighter.rics`, with the launch number it belongs to). At the cap the rule says "not a ricochet", and World's contact takes it as it would today |

**Where it acts**, by World's granted lines (`pending/ricochet/grant_world.py`):
- **The ground, a slope, a ridge or a cliff:** World's landing (`WorldContact._land`) already measures the contact in the slope's frame. A glance there is a new branch before the slam, paid and told as a bounce that keeps 0.7: the wear and the area by the speed it removes, World's `bounce` event with its `keep`, and his leaving the ground. Not on the sea, and not past the journey's own caps.
- **A building's face:** World's hit test (`WorldBrunt.checkHit`, and its swept form with depth on) asks `SimRicochet.offFace` first. A fast send steep to the face (moving along it) glances off. He stands just outside the face, no longer aimed at it, and the building takes nothing.

**The curve:** a glance ends the launch curve's paced leg (`flight` end, kind glance). His velocity first takes the speed he showed, so the glance keeps 0.7 of what the camera saw.

**The event:** `ricochet` (`fx-events.md`): kind glance (or Encounter's plant), the surface, where, his direction and speed after it, and the count in the row. Encounter's choreographer and Camera read it; it is also VFX's scrape and Audio's.

**For the choreographer:** `SimRicochet.predict(vx, vy, nx, ny, inRow)` gives the kind and the velocity after, for any surface normal. With the launch curve's `Track` (`pending/shared/`), a planner can step a send to its first contact and ask what that contact will do. World's own journey predictor runs the same branch, so it already predicts glances off the ground.

## 2. My readings, for Game Design to confirm

- **"In a row" is one send.** The count starts again at every send. A bounce or a skid between two ricochets doesn't reset it.
- **"A plain stop"** after two is the contact as it is today (a slam, a bounce, a skid), not a new kind of stop.
- **A glance pays like a bounce that keeps 0.7:** wear and area damage by the 30% of the speed it removes, and World's contact hit-stop (0.06 s). Game Design's "doesn't stop" is read as the body flying on, not the clock.
- **A face glance strikes nothing:** no damage, no mark. World may add a scrape.
- **The surfaces are the ground (any slope) and a building's face.** A parked car, a post and a tree don't stop a flight today, so there is nothing to glance off. The interior chain's slabs are World's chain, and are left to it.
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
- **Off:** a replay carries no ricochet data, and the same send skids as before.
- **The rule by its cases:** a glance; under the line; steeper; a full row; moving away. `predict` agrees on level ground and on a face.
- **On flat ground** (the check finds 640 units of level dry ground), a send 30° down at 5,000:
  - it glances once, told with `n` 1, and flies on upward with 0.7 of its speed;
  - World's bounce event keeps 0.7.
- **The same send with a full row, at 2,000 (under the line), and 72° down** (World's slam) doesn't glance.
- **With the curve on:** the glance ends the paced leg.
- **A building's face:**
  - a send steep to it at 2,000 into it glances, reflected and no longer aimed;
  - at 400 into it, or near level, it doesn't.
- **A match with the ricochet on** replays, and carries the data.

**Results:** in `pending/ricochet/README.md`.

**In play** (scratch probes, 6 AI matches of 7,200 ticks, every match played twice and the same both times):
- **With the switch on, no glance at all,** with the curve off or on: 3 to 6 sends a match.
- **Why, from every ground contact World reported with the switch off** (58 in all, 28 of them a send's first):
  - none would glance;
  - 42 are under the line, the plant's;
  - 16 are steeper than 40°.
- **First contacts meet the ground at a median 1,219 into it** (90th percentile 1,710, at most 2,557), at a median 44°. The fast contacts are steep (a send down is a slam). The shallow ones are slow into the ground, since a level send only gains its downward speed from gravity.
- **On the whole speed, the 16 contacts under 40° run** at a median 2,058 (90th percentile 3,461). 12 of them are at 1,500 or more.
- **So as ruled, a ground glance is rare by construction,** and the plants (Encounter's) would make QA's row. **If Game Design means the line on the whole speed,** about 12 in those 6 matches would glance: some 2 a two-minute match. That is one comparison in `SimRicochet.rule`, Game Design's to rule.

## 5. Not in this window

| What | Whose |
| :--- | :--- |
| The plant below the line, its counter and the dodge-aimed spring; the wall kick's push (2b) | Encounter, with Combat |
| The AI's shares, the choreographer's taste for ricochets | Encounter |
| The scrape's look and sound; the camera's framing of a glance | VFX, Audio, Camera |
| A face's scrape mark, and any surface beyond the ground and the faces | World |
| QA's rows: plants and glances 2 to 8 a match | QA |
