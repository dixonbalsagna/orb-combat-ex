# Plan: GW1b's one golden re-record (A-CODE-02), with the planet flip last

Simulation, 2026-11-20, sprint A1. The GW1b review (`docs/ep/reviews/GW1b-review.md`, B-02, and its 20-step order) and the GW1a review's S-07 ask for one re-record of the golden at the end of GW1b. They also ask that the golden finally play the world the game starts on: planet 7, touch 3, generation 3, which Orb played. This page is the plan; the recipe change it names lands with the re-record.

## The order

- **Steps 1 to 19** land one by one on the GW1a tree, as the review lists them. **The golden is not re-recorded between them.** Each step is gated against its own expectation:
  - steps 1 to 4 (A-WORLD-01's code, its one line in `beginMatch`, `replay-world`, World's pins) change nothing while the mode is `arena`: **the golden byte for byte**, parity green;
  - steps 5 onward move the golden on purpose (meters-zero, gw1b-energy, the director's riders, the floor rise, and more). For each, parity runs against a golden regenerated on that step's tree, and the step's own lane says what moved and why. That's what my parks already record (meters-zero, gw1b-energy, floor-rise-unpin).
- **Step 20, World's flip (mode only, the draw off):** every match that names no planet moves to planet 7, touch 3, generation 3. Before it:
  - one full gate on a scratch stack with the mode on `planet`;
  - each owner parks pins or re-reads for its red rows. A row that's about the hand-made arena takes `"world": "arena"`.
- **Then the one re-record**, on the finished GW1b tree, by me: `sim/core/test/golden.json` regenerated once, parity green against it, Rendering's 15, and a two-run check (the golden made twice gives one file).

## What the recipes change (lands with the re-record; built and gated before step 20)

- **After the flip, the default recipes play the round planet by themselves.** Each recipe that names no planet starts on planet 7, touch 3, generation 3, through `WorldDefault`. That covers S-07's gap: today no recipe plays generation 3.
- **The hand-made arena stays covered on purpose.** Two of the 9 computer matches and both scripted replays take `"world": "arena"`, so the arena (still a mode, and the strip-ground tools' world) keeps a reference.
- **`PLANET_MATCH` names its generation** (`"planetGen": 3`), so it no longer follows `climate.json`.
- **A new recipe, as `path-round-2.md` asked: planet 7 at generation 3, with a crater and a slide.** It's a seeded computer match whose record shows both. The recipe prints the tick of its first crater and its first slide, so a later change that loses either is seen. I pick the seed with a probe on the GW1b stack.
- **Cold and warm alike.** Since World's fix (b1d9444e, with its `cache_warm_check`), a planet reads the same from a cold field cache as a warm one. The re-record is taken with a cold cache and made again warm, and the two files must be equal (fork_check's finding).

## Who re-reads what

| When | Who | What |
| :--- | :--- | :--- |
| Each of steps 5 to 19 | the step's owner | parity against the step's regenerated golden; the step's lane |
| Before step 20 | every director, through the EP | their checks with the mode on `planet`; pins parked |
| Just before step 20 | World | re-cut `docs/world/pending/checks-gw1a/ground-repin.diff` (the six hashes of `render/tools/ground_check.gd`) on the exact GW1b tree: any change to play data moves them. It lands in the same step as the re-record |
| After step 20 | Simulation | the one re-record; parity; two runs, one file; Rendering's 15, with World's ground re-pin in |
| After the re-record | QA | the reference lanes on the new golden |

## The patch: the recipes and my arena pins (built and gated; lands at step 20 with the re-record)

| Patch | Files | sha1 | sha256 starts |
| :--- | :--- | :--- | :--- |
| `gw1b-golden.patch` | `sim/core/tools/{golden_recipes,parity,cross_check,cross_end_check,fights_check,frame_check}.gd` | ee5abe0189fe3670d45f48037d21df1e7cf59888 | 8752f445beea |

Apply on main (b0e20f9a) after GW1b's steps 1 to 4 (checked). It needs A-WORLD-01's `WorldDefault` and its `"world"` key. Tests and recipes only: no sim code.

- **The recipes** (`golden_recipes.gd`):
  - default seed 1, seed 11's KO match and both scripted replays take `"world": "arena"`; the other seven matches name no world;
  - **`PLANET_MATCH` is planet 7, touch 3, generation 3, seed 29.** It keeps its first crater and first slide (ticks 818 and 583), and parity asks for both. Seed 1 had a crater but no slide under the golden's own conditions (`probe_gen3`, `gen3_probe2`);
  - parity re-runs each match and replay with its recorded set-up.
- **My rows about the hand-made arena** (the review's B-02), found with the flip on a scratch stack:
  - **parity:** nine rows run in arena mode, through a small wrapper that puts the mode back: the arm set-ups, the view's particles at depth, a fighter's depth and the contact rule, the intro phase's flat start, the shots' buildings, the replay header's "no planet", the planet's load (its running match), the match's start in pieces (its two starts with no planet), and forms' Witness. Each row's planets are named, so they're unchanged;
  - **cross_check, cross_end_check, fights_check:** the whole check in arena mode (their 2v2 stages are written on the arena). A 2v2 on the planet is World's and Encounter's to cover;
  - **frame_check:** its two "off a field world" matches take `"world": "arena"`.
- **Not pinned: parity's "composed intros".** It's a real fault on the planet, fixed in `../intro-store/`, which lands before step 20.

## Proof (records: `docs/sim/runs/b0e20f9a-gw1b/golden-plan/`)

- **Steps 1 to 4 on main, arena mode:** the golden is byte for byte main's. Parity passes, with replay-world's row ("a replay of the default world names its planet"). World's `world_default_check` passes.
- **Steps 1 to 4 + this patch, arena:** golden regenerated (it moves: the planet match and the recorded set-ups); **parity exit 0** (the planet match "3,600 ticks: identical", its crater and slide kept); `frame_check`, `cross_check`, `cross_end_check` pass.
- **Steps 1 to 4 + the flip + this patch + `../intro-store/`:**
  - the golden made from a cold field cache and then a warm one: **one file**;
  - **parity exit 0 through `gate.mjs`**, every row;
  - `frame_check`, `cross_check`, `cross_end_check` pass.
- **Before the pins, with the flip:** parity failed 10 rows, cross_check 7, cross_end_check 3, frame_check 4 (`parity_planet_before_pins.txt`, `1_steps1-4_and_flip_red_rows.txt`).
- **Not the flip's:** `fights_check`'s "swings rest while apart" fails the same way on a plain export of main as it stands, b0e20f9a (`fights_check_on_main.txt`). It isn't in CI. It's my check, and I look at it after GW1b.
- **My other checks with the flip:** `power_check`, `kick_check`, `two_states`, `fork_check`, `field_static_check`, `memo_check`, `places_check`, `rec_check`, `replay_xproc_check`, `ceil_check`, `coop_check`, `loop_check`, `load_split`: all pass unpinned.
