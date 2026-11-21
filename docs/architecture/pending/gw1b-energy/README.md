# Parked: Game Design's addendum for GW1b (flight 3,500, the close times, travel 1.5, every meter feed at 0)

Simulation, 2026-11-14, sprint A1. Game Design's addendum to Orb's decisions 5 and 6 (`docs/design/energy-stamina-body.md` section 6, `docs/design/flight-3500.md`), folded into the A-ENERGY-04 and 05 parks as the EP asked, with Game Design's later ruling that the last three feeds go to 0 too. **It moves the golden** (flat out and the feeds), so **it rides golden window GW1b** (step 6 of the GW1b review's order), after `../meters-zero/`. Re-cut on the GW1a tree on 2026-11-20.

## What changes

- **The grant into `data/fight/power.json`** (mine by charter; it lands as a grant in A1):
  - `flight.flatOut` **3,500** (was 5,000: Orb's decision 5, Game Design's `flight-3500.md`);
  - `dash.closeSec` **{1,000: 0.45, 3,000: 1.0, 6,000: 1.9}** (was 0.4, 0.8, 1.4): QA's close-time targets, moved for 3,500;
  - `launchTravel` **1.5** (was 2.0): Orb's 9 November match ran `?travel=1.5`.
  - Each changed note says what it was and why.
- **Narrative's grant, both fighters' `meters.json`:** **every feed to the meters is 0**, so every fighter's ladder fills alike from time, charging and damage. Each zeroed source carries a `_zeroed` note saying what it was.
  - The Protagonist: destroyed (the rival's, 0.3; his own, 0.6), emptied (0.5), failed to protect (1).
  - The rival: destroyed (0.8), destroyed_power (0.07), crater (1), emptied (1), region_broken (8), brink (10). The last three are Game Design's ruling of 2026-11-14.
- **The comeback for every fighter** (×(1 + 0.5 × (1 − vitality)²), cap 0.5, exponent 2) is already `../meters-zero/`. Vitality reads the nearer road to the brink, which is the core alone until the body exists in A3 (Game Design's section 4), so **no code changes for it**.
- **Mine: rows written for the old numbers** (`sim/core/tools/`, tests only):
  - `power_check`:
    - flat out, the send's reach, the fastest top and the flight's cap now read the data's base (`SimPower.flatOut`) and its `launchTravel`, not 5,000 and ×2;
    - the close times' targets come from `dash.closeSec`, and the top from 6,000 is 0.9 s (`flight-3500.md`);
    - the slip's "off" row asked for twice the slip's speed, which was written for 5,000. It now asks that, off, a tap is still a third of the way from the slip's speed to his last held speed.
  - `parity`: the wired-numbers table loses three rows: anguish source 0's `within`, menace source 2's `minBh` and source 3's `sizes`. Each only matters while its source's amount isn't 0. The amount rows stay: they prove each feed is still wired. That's the same rule that took out composure's `below` and the two regen caps.
  - `cross_check`: the shots from outside read the shooter's menace and anguish from a building he brings down. With every feed at 0 the menace rows passed as 0 against 0 and the anguish rows failed. For their own runs the shooter now has the feeds main had before the addendum, put back after, so the rows still show that a shot from outside is charged to its shooter.

## Apply (re-cut on the GW1a tree, 2026-11-20: the GW1b review's B-04 and B-22)

**On the GW1a tree, after `../meters-zero/` (both patches; GW1b's step 5). This is GW1b's step 6.**
`git -c core.autocrlf=false apply grant-data-gw1b.patch gw1b-energy.patch grant-narrative-feeds.patch`

- **The slip stays on.** `power.json` keeps its whole `dash` object on one line, so the first cut (made on main's data, where the slip was off) carried `"slip": {"enabled": false` on both sides of that line. GW1a turned the slip on in the same line. The re-cut is made on the GW1a tree, so the line now carries the slip **on** on both sides. Only `flight.flatOut`, `launchTravel`, `dash.closeSec` and their notes change. **Don't hand-apply the `dash` line from the old cut.**
- The base: the EP's final GW1a stack (s422 `gw1a-final` 3917885), with `../meters-zero/` re-cut on it (its README says so).

| Patch | Files | Owner | sha1 | sha256 starts |
| :--- | :--- | :--- | :--- | :--- |
| `grant-data-gw1b.patch` | `data/fight/power.json` | mine, as a grant | be0e018e6f35276baed71f482691f11e5483d383 | 468109e9fda6 |
| `gw1b-energy.patch` | `sim/core/tools/{power_check,parity,cross_check}.gd` | mine | 09796c4d03a6e4cc75cf1824359bd48e273f54f7 | 9ab2a2044513 |
| `grant-narrative-feeds.patch` | `data/fighters/{PROTAGONIST,RIVAL}/meters.json` | Narrative | 854254638ee5b561d328f9252b2c14716fbf5876 | 8fa277d82afa |

(The first cut, on 33f30f2f: `grant-data-gw1b.patch` 9292df19, `gw1b-energy.patch` 95a4e5c4. Narrative's feeds grant is unchanged.)

**The golden moves** (9 matches, 187,200 ticks on the GW1a tree with this). It's re-recorded once, at the end of GW1b (`../gw1b-golden/`).

## Proof

Records in `docs/sim/runs/3917885-s422/gw1b-energy-recut/`. On the GW1a tree with `../meters-zero/` and these three, **the slip on**:
- Import, validator and its self-test, determinism lint.
- The golden regenerated; **parity against it through `gate.mjs`: exit 0**, no SCRIPT ERROR lines.
- **`power_check` 0 failed**, and its negative control 0 failed. `kick_check`, `cross_check`, `cross_end_check`, `memo_check` 0 failed; `two_states` (default, power, dash, slip, fights) passes.
- Rendering's 15: 14 pass. **`after_check` fails one row**: "on every tick the number drawn round each fighter is the number VFX's tally reads for him", with 3 frames where 1 after-image is drawn and the tally reads 2 (seed 8, tick 119). It passes with `../meters-zero/` alone and with the feeds alone. It fails only with this `power.json` grant: slower flight changes the play, and that exposes a frame where Rendering's drawn after-images and VFX's tally disagree. Rendering's and VFX's to look at; no sim change.

**The close times at flat out 3,500**, with the dash and the kick, tier 1, arrival off (on), the slip on:

| From | Measured | Target |
| ---: | :--- | :--- |
| 1,000 | 0.25 s (0.32) | 0.45 s |
| 3,000 | 0.83 s (0.88) | 1.00 s |
| 6,000 | 1.68 s (1.75) | 1.90 s |
| 6,000, tier 4 | 0.75 s (0.82) | 0.90 s |

All inside Game Design's targets, and the same as the first cut's.

## The look gate (the GW1b review's B-20)

- **It changes what the player sees:** flat-out flight drops from 5,000 to 3,500, and a sent body travels 1.5 times its send instead of 2.0. `docs/design/flight-3500.md` asks for a side-by-side, by Rendering and VFX before the EP commits: the trail and the dash at 3,500 against the 9 November build, plus a launch at 1.5, in the default look (Reduce flashing on). **Not taken yet;** the EP routes it.
- **The travel value:** QA's readings of the 9 November build record "travel 1.5" (`docs/qa/runs/6a30b4c9/x06-first-reading.md`, whose data hash equals the one in Orb's saved play file). Orb's two play files of that afternoon (`orb-first-play-20261109-1625.json`, `-1646.json`, `docs/qa/runs/6a30b4c9/README.md`) aren't in the repo or under `homework/Files`, so I haven't read the value from the file itself. QA, who replayed them, can.

## Other owners' checks that read the meters or flat out (from the first cut, on main's data)

- **World, `bystanders_check`, 2 rows:** both read the villain's menace from a wreck, which is 0 now. World's `bystanders-gw1b` (GW1b step 7) re-reads them.
- **Encounter, `arc_check`, "the meteor's own bowl":** the energy model's, fixed in Encounter's `gw1b-riders` (step 8).
- Pass: World's `far_people_check`; Encounter's `relief_check`, `swing_legal_check`, `arrive_check`, `launch_cost_check`; UI's `hud_check` (8,288 checks, 0 failed).
