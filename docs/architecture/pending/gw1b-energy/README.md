# Parked: Game Design's addendum for GW1b (flight 3,500, the close times, travel 1.5, every meter feed at 0)

Simulation, 2026-11-14, sprint A1. Game Design's addendum to Orb's decisions 5 and 6 (`docs/design/energy-stamina-body.md` section 6, `docs/design/flight-3500.md`), folded into the A-ENERGY-04 and 05 parks as the EP asked, with Game Design's later ruling that the last three feeds go to 0 too. **It moves the golden** (flat out and the feeds), so **it rides golden window GW1b**, after `../energy-on/` and `../meters-zero/`.

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

## Apply

After `../a1-owed/close-rows.patch`, `../energy-on/` (both patches), `../gates-shipped/gates.patch` and `../meters-zero/` (both patches):
`git -c core.autocrlf=false apply grant-data-gw1b.patch gw1b-energy.patch grant-narrative-feeds.patch`

| Patch | Files | Owner | sha1 | sha256 starts |
| :--- | :--- | :--- | :--- | :--- |
| `grant-data-gw1b.patch` | `data/fight/power.json` | mine, as a grant | 9292df190d85bb90563092a7dcaf4a090784a762 | c6e4128d0c9c |
| `gw1b-energy.patch` | `sim/core/tools/{power_check,parity,cross_check}.gd` | mine | 95a4e5c4525b1813eb9611e50272c480d2756cd7 | e9724bd6b217 |
| `grant-narrative-feeds.patch` | `data/fighters/{PROTAGONIST,RIVAL}/meters.json` | Narrative | 854254638ee5b561d328f9252b2c14716fbf5876 | 8fa277d82afa |

**The golden moves** (9 matches, 166,605 ticks on main's data with the stack). It's re-recorded once after GW1b's riders (A-CODE-02).

## Proof

Records in `docs/sim/runs/33f30f2f/gw1b-energy/`. Cut on 33f30f2f with the stack above:
- Import, validator and its self-test, determinism lint.
- The golden regenerated; **parity against it through `gate.mjs`: exit 0**, no SCRIPT ERROR lines.
- **`power_check` 0 failed**, and its negative control 0 failed.
- `cross_check`, `cross_end_check`, `memo_check`, `kick_check` 0 failed; `two_states` (default, power, dash, slip, fights) passes.
- Rendering's 15: 14 pass. `after_check` is the energy model's row ("the match has a rush in it"), which Rendering is re-scripting in their own park. It failed the same way in A-ENERGY-04's gate.

**The close times at flat out 3,500**, with the dash and the kick, tier 1, arrival off (on):

| From | Measured | Target |
| ---: | :--- | :--- |
| 1,000 | 0.25 s (0.32) | 0.45 s |
| 3,000 | 0.83 s (0.88) | 1.00 s |
| 6,000 | 1.68 s (1.75) | 1.90 s |
| 6,000, tier 4 | 0.75 s (0.82) | 0.90 s |

All inside Game Design's targets. `power_check`'s flight rows read flat out 3,500, 4,637, 6,091 and 8,067 at tiers 1 to 4, at the level each row's fighter has (its `SimPower.level`).

## Other owners' checks that read the meters or flat out

- **World, `bystanders_check`, 2 rows:** "the villain fed on the wreck, capped" and "at least one of the matches brought a building down, so the identity is not vacuous". Both read the villain's menace from a wreck, which is 0 now. World's to re-pin (the EP is routing them).
- **Encounter, `arc_check`, "the meteor's own bowl":** fails the same way with the energy model on alone (A-ENERGY-04's gate), so it isn't the addendum's.
- **Rendering, `after_check`:** the energy model's row, re-scripted in Rendering's own park.
- Pass: World's `far_people_check`; Encounter's `relief_check`, `swing_legal_check`, `arrive_check`, `launch_cost_check`; **UI's `hud_check` (8,288 checks, 0 failed)**.
