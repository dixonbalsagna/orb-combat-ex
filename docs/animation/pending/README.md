# Animation's parked patch for the nine cells' chain (2026-10-13)

`nine-cells-asserts.patch` goes in **after** Encounter's chain (`docs/director/pending/nine-cells-chain/README.md`, steps 1 to 4 and 5 to 6) and not before: its two rewritten asserts describe the picture the recipes make, and would fail on main as it is. It applies with `git apply` (paths `a/` and `b/` from the repo root; checked with `git apply --check` on main at 996bf933: it applies there too, so the order is for the asserts and not for the text).

**What is in it (6 files, all Animation's).**
| File | Change |
| :--- | :--- |
| `render/anim/tools/anim_check.gd` | The pair-live test's "his blows were all his own key sets" reads his own prefixes off his pick list (`pair_lists.by_name`), not the four old ones (the recipes' pieces add the tier, the energy pieces and the mediums). The cells test's default: a mashed Y plays the **medium** row with the sim's wind-ups drawn whole and `hook_seen` set (the hook landed), where before it asserted today's heavy row |
| `render/anim/tools/lead_scan.gd` | A tumble is the sim's spin over 3 rad/s in any state (a locked fighter thrown on a bounce had been scored as "not a tumble") |
| `render/anim/anim_fighter.gd` | The flight lead turns a body along the motion he has, not only along `f.vx`: a knockback carries him by position and leaves the velocity small, so a skid at 900 units a second was not seen as fast (seed 8, tick 2140 of the chain's matches) |
| `render/anim/tools/waves/protag10.mjs`, `data/anim/waves/protag10.manifest.json`, `data/anim/waves/protag10.keysets.json` | Legal RL-133: `pu.su_drive` is drawn and worded as one arm and said `uses.arms` 2 with a second limb (`hand_l`, the double hammer's, from its base row). Now one arm, no second limb; the contact solve no longer drives the left hand to the chest. `reach.json` is unchanged (82 measured again) |

**What it read** on a scratch export of main 996bf933 with the chain applied (steps 1 to 5; the golden's regeneration not run, it is not mine): `anim_check` passed (seed 4, 2400 ticks), `joint_scan --strict` 0 of 896 poses and 0 on screen, `lead_scan --strict` 0 feet first and not a tumble (**with the chain and without this patch's lead_scan and anim_fighter parts it was 4**: 3 locked-bounce frames and one skid), `held_scan --strict` 0 fail, determinism plain and `-- --intro --seeds=2 --ticks=900` passed.
