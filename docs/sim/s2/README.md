# Spike S2, the gravity well trial: the core's half (scratch; never to land)

Simulation, 2026-11-14, sprint A1 (A-COMBAT-03; I lead, Encounter on DirBands). The design is the stand-in's `docs/ep/proposals/gravity-well-trial-design.html`, with Game Design's five rulings at the end of `docs/design/gravity-well-reading.md`. **This is a throwaway build on a scratch copy. Nothing here lands.** The patch is kept here so Encounter can build their half on the same tree.

## The trial's base tree

HEAD 4c284b84, plus `../../architecture/pending/a1-owed/close-rows.patch`, `energy-on/energy-on.patch` and `gates-shipped/gates.patch`, with **GW1a's target data** (the kept 9 November data, `homework/Files/builds/orb-first-play-6a30b4c9-6627cb9d/tree/data/`, copied over main's data, with `power.json` `enabled` and `dash.enabled` true). That's the build Orb played, on today's code. The trial's matches pass `"flatOut": 3500` (Orb's decision 5) and `"travel": 1.5` in their setup; the kick, the slip and the dash are on in that data.

Then `s2-core.patch` (below).

## What the core gives (`s2-core.patch`)

- **`data/fight/well.json`** (new; schema `tools/schemas/fight-well.schema.json` and its row in `map.json`): the switch (off), size, zones, the draw, the snap's numbers and the close fight's numbers, as the design's section 10 with Game Design's rulings: the snap at the faster of 4,000 and flat out with a 3 bh a tick ceiling (ruling 1); the draw `"rest"` by default with `"capped"` as the comparison arm (ruling 2); `leaveAfterBlows` 3 (ruling 3); `chargeGrow` 0.25 (ruling 5). The capped arm's "holding away" is two numbers of its own (`awayDead` 0.3, `awayShare` 0.5).
- **Setup words:** `"well"` (true or false) overrides the switch for a match; `"wellClose"` (`"pair"` or `"own"`) overrides `close.mode`, with or without the well. As `"kick"` does.
- **`sim/core/well.gd` (`SimWell`):** names no director class (the load split).
  - `radius(f)`: by tier and charge (the charge rises over 30 ticks while he powers up or gathers a beam, and falls over 15).
  - `tick(S)`: once a live tick, after the control loop and before the bodies step, while `S.wellOn`. It writes each fighter's `wel.zone` against the rival's well (`SimWell.IN`, `EDGE`, `OUT`, with the bands' hysteresis; `zones.either` the second reading) and the draw.
  - `zoneNow(S, A, D)`: the zone straight from the distance, for a press before the first write.
  - The draw, in silence only (`"rest"`): the stick as held at rest (`heldMx`, `heldMy`: a stun can't fake it), no control held or pressed, free, no rush, no stun, no K.O., no approach in hand (`SimDir.approaching` → `DirBands.pending`), and **both** fighters' latch set. At most a quarter of plain flight, nothing at the edge and full by half the radius, faded in over 12 ticks, eased out over the last body height before 2.5 bh. It's applied as its own movement at the free flight's position step, so it leaves nothing behind on the tick the stick moves.
  - The latch: launched, down, dropped, a stun, or a rush with no target clears it; his own input once free sets it. **`SimWell.sent(f)`** clears it from the director (for a knock-back with no rush and no state of its own).
  - `"capped"` (Game Design's): always on in free flight, halved on a fighter holding away (`heldAway`).
- **State:** `SimState.WellState` on `f.wel` (null unless `S.wellOn` or `S.wellOwn`): `zone`, `r`, `chg`, `quiet`, `own`, `dx`, `dy`, and three for the director: `ovx`, `ovy` (the own-body mode's speed), `lv` (blows that reached him while he held away), `late` (the outrun option). All whole numbers, all hashed while either switch is on.
- **`SimPower.flatFor(S, f)`:** flat out for his level and build, whatever his stance, range or the dash's switches: the snap's speed (`maxf(snap.floorSpeed, flatFor)`).
- **The replay's key** folds `well.json` for a match with the well or the own-body mode on.
- **`sim/core/tools/well_check.gd`.**

| Patch | Files | sha1 | sha256 starts |
| :--- | :--- | :--- | :--- |
| `s2-core.patch` | `data/fight/well.json`, `sim/core/{well,state,sim,hash,fighter,power,replay,dir}.gd`, `sim/core/tools/well_check.gd`, `tools/schemas/fight-well.schema.json`, `tools/schemas/map.json` | bdc711cc6c63a56d40e1add2282fa80ac1c3f1c7 | 7e14a3d42b3e |

Apply on the base tree above: `git -c core.autocrlf=false apply s2-core.patch`.

**Proof** (`runs/core-1/`): import, validator, determinism lint, the two-fighter ratchet (365 of 365) and the load split pass. **With the well off, the golden reproduces GW1a's target byte for byte.** `well_check`: every row but one passed on the first run. The capped draw compared the two fighters' raw speeds, which differ (their `spd`). The row now compares each against his own flight and is re-run in the next window.

What the check printed:
- **The snap by tier at flat out 3,500, with an empty power meter: 4,000, 4,373, 5,464, 6,827.** The design's 4,640, 6,090 and 8,070 need a full power meter: tier is 0.8 of the level and the power meter the other 0.2 (`power.json` `level`). Both tables go in the page.
- Two fighters who let go at 10 bh drift to 2.50 bh and stop there. The fastest draw was 69 a second (cap 107).

## The joined trial (final)

- **The tree:** the base above, then `s2-core-v2.patch`, then Encounter's `../../director/s2/s2-dir.patch` v2 (53570393). It's frozen as a scratch copy, `s2t`, committed as 9f867c5; Tools' gauntlet ran on it.
- **`s2-core-v2.patch`** replaces `s2-core.patch`: sha1 bc6810b37e089ff6cfd353f4fe41b6a7fad8481c, sha256 ed7bfc91d9de. It adds:
  - the join's call: in silence the draw also waits while the rival's approach or zip is in hand; the capped arm meets a snap, not while holding away or guarding, and never draws during his own crouch;
  - the review's fixes: every latch is updated before any silence is read, so slot order changes nothing; the replay key folds `power.json` when the well is on and the energy model off;
  - three trial tools: `well_read.gd` (the design's readings), `well_clips.gd` (the clip matches), `well_clips_check.gd` (each clip file replays exactly).
- **The review** (one workflow, approved by the EP: 6 agents, 1,263,550 tokens, no Godot): 22 findings, 14 confirmed, 5 narrowed, 3 refuted. Encounter's v2 fixes their five, the core and the readings take the rest. One is noted and left: the latch also trips on a fighter's own target-less rushes, which only ever holds the draw back (`runs/joined/review_findings.txt`).
- **Proof on the joined tree** (`runs/joined/`): well_check 0 failed; Encounter's well_dir_check 28 of 28; load split, ratchet 365, lint, validator; **with both switches off, the golden reproduces GW1a's target byte for byte.**
- **The readings:** the quick parts (`read_quick`, `read_brawl`, `read_draw`) and 40 computer matches a close-fight version (`read_matches`). The page is `trial-page.md`.
- **The clip matches:** `clips/match-files/`, ten match files (five scenes, today and proposed), each a real match from its start with both pads scripted, a mark on the moment. All ten replay exactly on the trial's code. Tools' clip kit cuts them: `node tools/clips/make.mjs --from-match <file> --build <a web build of s2t>`.

## Encounter's half (through the EP)

On the same base plus `s2-core.patch`, in Encounter's own scratch copy:
1. **`DirBands.pressBand(S, A, D)`**: CLOSE stays the band's own; otherwise MID if `A.wel.zone` (or `SimWell.zoneNow` before the first write) is `IN` or `EDGE`, else FAR. Read at the four places on a press's path: `exchange.gd:310` (the gate), `bands.gd:287` (`farPressNow`), `bands.gd:197` (`begin`'s own read), `stick.gd:520` (`_lungeLight`). The computer's choices (`ai.gd:282-299`), DirZip, the chase tap and the grab keep today's edges.
2. **The snap in `begin`**, with the well on, `snap.enabled`, not a charge, not a counter-rush and pressBand MID: speed `maxf(snap.floorSpeed, SimPower.flatFor(S, A))`, ticks as line 205's own form without its 20-tick ceiling, then at least `(d - eng) / (maxStepBh × 75)`; the crouch unchanged. Feed "SNAP" and, on a press that reads `OUT`, "FAR KIT, outside the well"; a cue "snap".
3. **`SimWell.sent(f)`** where the director shoves a fighter without a rush: `DirRecoil.knocked` (recoil.gd:74) and `DirLaunch.knockBack` (launch.gd:1381).
4. **`close.mode` "own"** (`S.wellOwn`) in the brawl: the design's section 8 list, with Game Design's rulings 3 and 4: the walk-out on the 3rd blow that reaches a fighter holding away (landed or guarded; a stun or stagger pauses the count without resetting it; letting go of away resets it; the brawl ends with a new reason, "broke"), and solid bodies (melee.gd:129-134). The own speeds live in `f.wel.ovx`, `ovy` and the count in `f.wel.lv`. The computer's brawl stick holds still where it pushed away.

Then I put both halves together, build the readings (the design's section 12) and the clips, and write the page.
