# Parked: the old meters change nothing; the comeback for both (A-ENERGY-05)

Simulation, 2026-11-14, sprint A1 (`05-directives/A1/simulation-engine.md`, criteria 3 and 4). Orb's decision 6 (2026-11-13), as recommended: **keep the comeback as a rule for every fighter, set every other effect to zero in data, remove the code after Alpha.** It changes the state hash (the rival gains the comeback), so it **rides golden window GW1b**, after the switch flip.

## What changes

- **Narrative's grant, both fighters' `meters.json`:**
  - the Protagonist's anguish: `regen_penalty` 0 (was 0.01); composure was already 0; the comeback (0.5) kept, its note saying it's a rule for every fighter;
  - the rival's menace: `regen_bonus` 0 (was 0.01), `damage_mul` 0 (was 0.05), `beam_power` 0 (was 0.08), and **the comeback, 0.5**, the same as the Protagonist's.
  - Each zeroed number's note says what it was and why.
- **Mine:**
  - `damage.gd`: the comeback applies to every fighter whose data names one, not only the one with the anguish meter. A fighter with none (the training dummy) is untouched. For the Protagonist the expression is unchanged.
  - `fighter_data.gd`: the comeback may stand on either meter.
  - **Parity's new row** ("the old meters change nothing; the comeback for both"):
    - for each fighter, his meter at 0 and at 100 against the meter at rest gives the same damage, the same energy regain over a live tick, the same beam power in a contest (`DirBeam._power`) and the same roam read, which is where the computer leads the fight (`DirLocation._roamRead`);
    - for both fighters, the same blow struck half way to the brink deals ×(1 + 0.5 × 0.25) more than struck fresh.

## What still acts, with the file and line, and why (criterion 4; nothing is deleted in A1)

- **Who has which meter** still sets two of the director's choices: they key on the meter's presence, not its value, so zeroing can't reach them.
  - Where a deflected beam goes: `sim/director/beamplay.gd:508-513` (the hero sends it at the sky, the villain toward the nearest building).
  - The computer's roam: `sim/director/location.gd:116-117` (the hero's and the villain's sides of the roam read).
  - Encounter's.
- **The swing reads the meters' values:** `sim/director/swing.gd:462` (the swing's intensity takes the higher of each meter) and `:496` (a personality term weighted by the anguish meter). Swing is on in the 9 November build. Encounter's: zero `swing.json`'s anguish weight, and drop or zero the meters from `:462`'s intensity.
- **The world still feeds the meters** on every building fall, crater and emptied building: `sim/world/collateral.gd:406-466`. With every effect zero the numbers move and change nothing. World's, for after Alpha.
- **The HUD may still show the meters** (`meters.json` `"visible": true`). That's UI's and Narrative's.
- **Hiding and ambush are off in data:** `canHide` false for both fighters (`data/fighters/*/fighter.json`), so nobody hides and the ambush multiplier (`damage.gd`, ×1.5) never fires.
- **Signature variants by biome have no switch** (`data/combat/sigvariants.json` has only `byPersonality`, off), so they act in every match. The biome launch layer (`data/combat/launch_biome.json` `biome.enabled`) is off on main and on in the 9 November build: a switch-group row. Combat's and Encounter's.

## Apply

`git -c core.autocrlf=false apply meters-zero.patch grant-narrative-meters.patch`, on HEAD 8007de44 (checked again on 148f4e16: it applies and reproduces the tested tree).

| Patch | Owner | sha1 | sha256 starts |
| :--- | :--- | :--- | :--- |
| `meters-zero.patch` (`damage.gd`, `fighter_data.gd`, `parity.gd`) | mine | 5ad4d852cdd7de21d1df2a896fb3ef8cbd72ab1a | 25ae18f3ecb6 |
| `grant-narrative-meters.patch` (both fighters' `meters.json`) | Narrative | 3ca8eea1c7a76ee1d9bc9c442edaae84feeb445f | 045b45f1a5df |

**The golden moves** (9 matches, 173,718 ticks on main's data): the rival's comeback. It's re-recorded once after GW1b's riders (A-CODE-02).

Parity's wired-numbers table loses two rows: regen_penalty's and regen_bonus's caps only matter while their `perPoint` isn't 0, and both are 0 now. That's the same rule the table already used for composure's `below`.

## Proof

Records in `docs/sim/runs/8007de44/meters-zero/`:
- On 8007de44 (the final patches): the golden regenerated; **parity against it through `gate.mjs`: exit 0**, no SCRIPT ERROR lines, the new row ok.
- **Negative control:** with HEAD's `meters.json` put back, the new row fails. The Protagonist at full anguish regains 0.0667 a tick against 0.0833 at rest.
- On bf6c4538 (the first gate): `power_check` 0 failed; `two_states`, rollback, desync, `replay_xproc`, determinism all pass; Rendering's 15 all pass.
- Validator and self-test (the comeback on the menace meter needs no schema change), lint, ratchet 365.

## For QA (through the EP)

The win-rate batch before and after: the Protagonist's only comeback hung on his meter, and now the rival has one too.
