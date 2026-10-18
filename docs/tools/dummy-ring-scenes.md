# The dummy, ring and launch scenes of the flash set (2026-10-16)

Owner: Tools. Legal's RL-139: each new pairing at least 3 captures, and a mash-on-the-dummy scene for each fighter in both modes. The EP's brief added a ring of three to five bodies (Camera's 3v1) and a clip where player one launches the AI (Camera's keep rule).

## The scenes

All three are in `tools/flash/sources.json` (a scenario may now carry `slotsList`: one run for each list of fighters, one seed, named `<scene>-<ids joined by ->-<mode>` the way an AI pairing is), `tools/flash/flash_worst.gd` and, as a patch for Rendering's file, `docs/tools/pending/flash-capture-dummy-ring-launch.patch`. The hook patch also lets the page's `slots` be three to five ids.

| Scene | Fighters | What player one does (a pad, as a person would) | Clips |
|---|---|---|---|
| `mashdummy` | PROTAGONIST v REFERENCE, RIVAL v REFERENCE (the dummy stands idle) | A cycle of 600 ticks: X mashed at the fastest tap (every 4 ticks), Y mashed, X held (the burst), RB held and X mashed in reach (the energy mash), RB and B (the blast), then B to launch and X after it (the launcher chain). Ki kept full | 4 |
| `ring` | PROTAGONIST v RIVAL with 1 guard (3 bodies), PROTAGONIST v RIVAL with 3 guards (5 bodies); the guards fight | X mashed, Y now and then, the signature once in 300 ticks. Ki kept full | 4 |
| `launchai` | the default pair, the real AI | B tapped every 45 ticks, walking into reach. In the seed's 1,800 ticks he launches the AI twice and is launched once | 2 |

Read headless on HEAD ee822c5e (1,800 ticks each): `mashdummy` 84 and 153 damage events, the register's worst 1 in 60 ticks; `ring` 140 and 138, worst 3; `launchai` 106, worst 1 (P1 launches the AI once). Player one sprints (dodge held) when a launch has sent them 900 units or more apart, or the scenes spend their ticks flying back (launchai read 42 damage events without it, after Encounter's changes). The check wants 60. The required set is now 66 clips (56 before).

The pairings of the dummy (Simulation's roster) were already in the set in 06b0200e: 7 seeds for the Protagonist and the dummy, 6 for the Anti-hero and the dummy, so each new pairing has at least 3 captures.

Not done: the ring runs with the game's defaults, so Camera's `many_framing` (off by default) is not on in these clips. When Camera wants the clips with it on, it is a page switch like `hold=1`; say so. The sun pan (`w04`) waits for the sun.

## The schema keys of the parked changes

Checked on a scratch export of main with every park applied (Animation's four-patch stack: many-bodies, runs-look, tenth-round, combat-pieces; VFX's energy-and-choreo vfx.patch; Combat's `recipes.split.json`, Encounter's scripts (with the beam struggle's two grants)). Before the keys: 18 unknown-property errors from Animation's stack alone; after: 0 (203 files).

| Key | Where | Status |
|---|---|---|
| `mediumMash`, `heavyMash` | `combat-recipes` `brawl` and `fallback.lower` | added now (the pool must exist for every fighter: `xref:recipes-brawl` already reads it) |
| `breath_ticks`, `press_run`, `march`, a style's `squash_pose` | `anim-press-styles`, on every style | added now; a style's `squash_pose` names fighters and real poses (new rule `xref:pressstyles-squash`). (the file's own top-level `squash_pose` was already there) |
| `ease` per fighter | `anim-fighters` | added now: a map of a press style to `{prof, carry_ticks, twist, ...}`; every key is a style of `press_styles.json` (new rule `xref:fighters-ease`) |
| `chargeGuess`, `heavy.charge.guessTicks` | `director-ai`, `director-interrupts` | added now, byte for byte what Encounter's `pg.cjs` writes (their script finds the keys there and writes the same) |
| `beamStruggle` | `director-interrupts` | added now, byte for byte what `bs.cjs` writes |
| a `cash_in` style | `anim-press-styles` `styles` | added (a full style definition, as `tech`); optional |
| `roles.<fighter>.beam` `{charge, fire, bone}` | `anim-pairlive` | added: charge and fire are wave sequence ids, bone optional |
| manifest strike field `named` | `anim-wave-manifest` | added (boolean) |
| the `common` row | `fighters.json`, `pair_live.json` roles | nothing to add: a fighter and a role are open keys; validated with the stack |
| a wave called `guard1` | the four wave schemas (manifest, keysets, entries, entrymap) | the wave-name pattern is now `^(wave|protag|rival|guard)[0-9]+$` |
| wave `round10`, prefix `rt`; `pair_live` shared `round10` | `anim-pairlive`, the wave schemas | already accepted: the name pattern is `^[a-z]+[0-9]+$` and the pose ids are generic. Nothing to add |
| `energy.json` keyed by roster id | `vfx-energy` | nothing to add: VFX's re-key (9bde4409: default, protagonist, rival, rival_short, reference) fits the schema their `energy-and-choreo/vfx.patch` carries; validated with it applied. My earlier `apply-vfx-energy-ids.cjs` is dropped |

Eleven fixture cases cover the new keys (`tools/fixtures/cases.json`: `recipes-brawl-mash-*`, `anim-pressstyles-run-*`, `anim-pressstyles-march-*`, `anim-pressstyles-style-squash-*`, `anim-fighters-ease-*`).

A warning that is not Tools': with Combat's split recipes in place, `data/director/alchemy.json` says roster id REFERENCE "has no entry here and no pool reference in data/combat/recipes.json".

## Legal's RL-141 to RL-143 (2026-10-16): three more scenes, the rate lists, red flashes 0

Legal asked for a beam clash, a signature in the city and a mashed blast on the dummy in the set, for the beam look, the explosions, the marks and the casts. `clash` and `signaturecity` already exist (and are in the record), so the three added are the ones that make those harder: they are all new ids in `tools/flash/sources.json`, `flash_worst.gd` and `docs/tools/pending/flash-capture-legal-scenes.patch` (the hook).

| Scene | What | Clips |
|---|---|---|
| `clashcity` | the clash scene (both on RT + B together every 30 ticks) started beside the tallest tower: the beams meet over the towers and the struggle's marks are in the frame | 2 |
| `signaturedummy` | PROTAGONIST v REFERENCE and RIVAL v REFERENCE, started beside the tallest tower; player one fires the signature on a cycle at a dummy that cannot dodge, so every beam lands (explosions, collapses, flames; the dummy answers with his own signature too) | 4 |
| `blastdummy` | the same two pairings; energy held and B tapped every 10 ticks point-blank on the dummy (the mashed blast: the energy heavy fires the signature, flames and burn at close range, again and again) | 4 |

The required set is 76 clips (was 66). Read headless on HEAD e88efd24: `clashcity` one CLASH, 7 damage events and a building down; `signaturedummy` 76 and 77 damage, a building down; `blastdummy` 72 and 88 damage; register worst 1 in 60 ticks in all.

The rate lists: the flash set's list is `outside` in `tools/flash/sources.json`; it now names UI's recharging ring (1 Hz) and the tug ring (3 Hz, strokes only, steady under Reduce flashing and Reduced motion). They are in every frame of the pixel clips, so the analyser reads them. VFX's own list is `rates` in `data/vfx/energy.json`, and UI's is in `hud_check`; both are theirs.

Red flashes 0: `release-pass.mjs` now refuses a record with a clip whose red count is anything but 0 (or missing), interim or not. The analyser stays the authority (`wcag.js`, linear values).

Schema keys of Animation's fifth patch (homework4.patch, e117bd9a): joints.json `wing` {fix, suffixes, skip, flex_deg, up, drop, margin, back} and press_styles `press_run.bob`, with a new rule `xref:joints-wing-skip` (each skipped pose is real). Proved with the five-patch stack applied: validate 0 errors (203 files), --self-test 7456 of 7456. Two old cases (`anim-press-styles-flurry-burst-optional` and `-medium-optional`) now also empty the fighters' `ease`, since an `ease` row names a style and deleting that style would otherwise rightly fail `xref:fighters-ease`. Also: 12 cases for VFX's `vfx-energy.schema.json` (it had none, and the validator's coverage check wants three invalid cases per schema).


## Art's city looks, and the red gate (batch 2 addendum)

`docs/tools/pending/apply-art-city-looks.cjs` (run once in the commit that lands `data/art/city-looks.json`, after batch 2 and VFX's apply, since it adds a rule to `tools/schemas/map.json` and cases to `tools/fixtures/cases.json`): writes `tools/schemas/art-city-looks.schema.json` (closed except underscore keys, `note` declared; version field `version`), the map rule after `art/sky.json`, six cross-references in `tools/lib/xref-art.js` (`city-looks-id`, `-district-look`, `-facade-weight`, `-tint-weight`, `-weights-sum`, `-budget`) and 29 cases. Proved on a clean export of HEAD plus the tree's tools plus the file: validate 0 errors and 0 warnings, `--self-test` 7480 of 7480, a second run changes nothing.

The red gate reads the analyser for every clip: `rowOf` takes each row's red count from the analyser's own result (`r.red.flashes` of `wcag.js`, which takes a saturated red on the stored or the linear values, whichever is red), and `redProblems` refuses a record, at `--record` and at `--verify`, whose clip (or its second capture or re-capture) reads anything but 0 red flashes, or no red count. It applies to all 76 required clips, interim or not.

## The red gate and the live record; depth.json; the foot's new limits (2026-10-16)

The red gate was held back because `tools/site-pin-selftest.mjs` failed "the recorded pass HOLDS against the pinned commit". The cause was that test's own synthetic record, whose row had no red count; the live record is fine: all 56 rows (and no second capture or re-capture) read red 0, and `verify` of tools/flash/release-pass.json at its own commit d3f1ca0e returns no problems. The fixture row now carries `red: 0`; site-pin 14 of 14, release-pass 77, site-interim 54, nightly 12. Nothing in the live demo's build changes.

`docs/tools/pending/apply-combat-depth.cjs` (Simulation's depth window; run once in the commit that lands `data/combat/depth.json`) is extended with the director's block that Encounter's d1a.cjs adds (`director`: lineSinMin, lineSinMax, arriveSin, homeAfterTicks, homeBhPerSec; optional) and the rule `depth-line-order`; proved on HEAD plus all six of Animation's patches plus Simulation's parked file with Encounter's block: validate 0 errors and 0 warnings, --self-test 7536 of 7536, a second run changes nothing.

Animation's sixth patch (fc8a336d): `limbs.<ik limb>.min_fwd` and `retreat_max` are optional numbers (0 or more) in `anim-sockets.schema.json`, with three cases; proved with the six-patch stack: validate 204 files 0 errors, --self-test 7496 of 7496.

## Animation's sixth and seventh patches (8895f688, 1ab30e26)

Schema keys: joints.json `slew.free_arm_deg` and `wing.runtime`; press_styles `hold.tremor` and `hold.twist_back` on every style, and `hold.squash` now up to 2 (the held medium and heavy coil to 1.1 and 1.25; the old case that wanted a squash above 1 refused is now above 2); sockets `limbs.hand.min_fwd` and `retreat_max` were already allowed by the foot's keys (every ik limb). Ten cases, put before the sockets cases so the tail of cases.json is as World's fixtures diff expects it (it and the map diff apply clean on top). Proved with all seven patches (many-bodies, runs-look, tenth-round, combat-pieces, homework4, pulled-frames, live-scan-and-tier): validate 204 files 0 errors, --self-test 7506 of 7506.

## The pending schemas (2026-10-17)

- **In the tree** (their data files are in the tree, uncommitted, so commit them together): `art-polar`, `art-outposts`, `art-vehicles` (data/art), `audio-tug-cues`, `audio-babble-ab` (audio/data). Written by `docs/tools/pending/infer-schema.cjs`, which reads the file and writes a closed shape schema (every key present is required, a key outside is refused unless it starts with an underscore, a colour is a hex string, a number is bounded below by zero only where all its values are), its `map.json` rule and cases (a valid one, each key missing, an unknown key at each level, the version wrong, a wrong type at each leaf, up to a cap). A shape check, not a ruling on values: the owner tightens it. Re-run it on a file after the file changes.
- **For the parks** (a schema with no document fails the coverage check, so these are scripts, not files): `node docs/tools/pending/apply-parked-schemas.cjs` in the commit that lands the files. It does `anim-brake`, `anim-chain`, `anim-guard-pass`, `anim-throws` (Animation's guard-pass, air-brake, chain-poses and grapple patches) and `fight-forms` and `fighters-forms` (Simulation's forms park; it makes the virtual fixture copies the self-test reads, since the self-test takes data/fight and data/fighters from tools/fixtures/virtual). Proved on HEAD + all 18 of Animation's patches + the forms files: validate 225 files 0 errors, --self-test 8118 of 8118, a second run changes nothing.
- **Ragdoll fields** (in the tree now): `dofs[].arch`, `lag`, `oop`, axis `y`, top-level `variety` in anim-ragdoll; `weight` in anim-ragdoll-motion; and the rule `ragdoll-motion-dofs` now counts only the in-plane dofs for a shape's numbers (an `oop` dof has none). Proved with the stack (the 64 errors it gave are gone).
- **City looks:** the neighbour rule is a rule now, `xref:city-looks-neighbours`: the wall's mid tone, the glass pair, the trim, the spandrel and the fin differ by no more than the budget in relative luminance, and the figure a tint states in `_neighbours` is the one its colours give. Art's data passes (worst 0.083 of 0.085).
- **restS retired:** no longer required by director-interrupts (docs/design/launch-anywhere.md); still allowed, unread; the case that wanted it required is now `...-rests-retired-optional`.
- **Sockets regions:** nothing to add, the stack validates. **The line `source`/`mode`:** I could not tell which file is meant (the taunts draft's `mode: "3v1"`, the provenance records' `source`); the drafts are not in data/ yet, so nothing validates them. Say which and I will write it.
- World's tools-collateral.diff: applies clean (`git apply --check`); five cases of the standard shape for `biomes-collateral.schema.json`, which comes with World's own files, so I could not run them here; the committer runs --self-test.

## Legal's addendum 10 in the record machinery (RL-156, 2026-10-17)

- **The mode read back, per clip.** capture-web.mjs writes into each clip.json the mode the running game reported after its first tick (`mode`: UI's Reduce flashing and the calm look) and md5 probes of the frames at ticks 60, 180, 300, 600, 1200 and 2400 (`probe`). run-pixels.mjs carries both into summary.json, and every row of the pass file prints `reduceFlashing`, `flashCalm` and `probe`.
- **A pair whose modes match is refused.** `modeProblems` (release-pass.mjs, at `--record` and at `--verify`): each row's reported mode must be its clip's mode; a clip's normal and reduced rows must differ in at least one probe; the canary pair (blastdummy PROTAGONIST v REFERENCE) must not read the same in all three readings. A record made with the old hook has no `hookFixed: true` and does not hold (every clip of it is the calm look).
- **Nightly-style seeds on the same commit.** `--record --extra <summary>` takes the run-pixels summary of seeds 1008, 1009 and 20 more (interim-run.sh now captures them, both modes, after the set, picking the 20 with nextSeeds from the nightly history) and stores them in the record (`extraSeeds`). A record needs at least 22 seeds including 1008 and 1009, each in both modes in its own mode, none over 3 on the primary reading. interim-run.sh does not record, and says which clip, if any clip of the set or of the extra seeds reads over 3.
- Tests: release-pass selftest 91 checks, site-pin 14, site-interim 54, nightly 12.

## Offline site, double_hit, brake, catastrophe (2026-10-17)

- **The site offline and the pinned record.** With `tools/site.json` offline, `node tools/site-pin.mjs` prints nothing and exits 0 (an offline site has no pin), the CI "Resolve the pinned commit" step has nothing to verify, and no CI step reads the record; the old record (d3f1ca0e) no longer holds in `release-pass --verify` (no `hookFixed`, no nightly-style seeds), which matters only when the site goes online again, and then it should refuse. Proved: site-pin selftest 14, site-interim selftest 54, an offline build of a stub export (5 files, no .wasm, no .pck) and `check-site-offline` ok.
- **`double_hit`** is registered in `tools/flash/sources.json` as a counted source (the register already weighs it, 0.15: render/vfx/flash_registry.gd), for Encounter's launch anywhere.
- **`data/fight/brake.json`** (Simulation's air brake, parked): `apply-parked-schemas.cjs brake-fight` writes `fight-brake` (proved on HEAD plus the parked file: validate 201 files 0 errors, --self-test 8012 of 8012).
- **`vfx-catastrophe.schema.json`**: `apply-vfx-catastrophe-cases.cjs` adds the valid case and the three invalid ones (alpha_max 0.6, a sprites entry over 160, a z over -5) plus an unknown key, in the commit that lands VFX's park. NOT yet run against the schema: the tremor-dust patch (docs/vfx/pending/tremor-dust/apply.patch) holds the map entry but neither `data/vfx/catastrophe.json` nor the schema file, so VFX must add them.
- **Narrative's line files** (taunts, run lines) stay unvalidated until they move into data/; **babble_ab.json** has its schema already (it was warning) and would only be dropped if Orb adopts a letter.

## The rehearsal, the lock check, the tightened schemas (2026-10-18)

- **check-site-interim.mjs** now fails unless the exported `ui/data/features.json` has `lock_reduce_flashing` true (UI's rf-lock, Legal RL-156): one word, and if it is forgotten the toggle shows. Self-test 55 checks (a root with the lock off fails).
- **A rehearsal** is `NO_RECORD=1 bash tools/flash/interim-run.sh <commit> <from> <expires> <dir>`: the whole set, the second captures, the nightly-style seeds, and `tools/flash/run-table.mjs` writes `table.md` (every clip against addendum 10: 3 or under on the primary, red 0, with the worst second and its sources); nothing is recorded, built or published.
- **Tightened (the EP's shape schemas of b328017b):** anim-brake (poses named and checked to exist, lean_deg 0 to 90 and ordered, weights 0 to 1, ticks at least 1), anim-chain (the same; keeps 0 to 1; counts at least 1; the three "poses" are sequences, so a pose or a sequence), anim-guard-pass (contacts are a MAP of any contact key, not today's 28; each must be a real pose, `now` at most `was` and at most the hand goal), anim-throws (all five sends, each throw a sequence that exists and has a grip, no grip that no send uses). Rules `anim-brake-*`, `anim-chain-pose`, `anim-guard-pass-*`, `anim-throws-*`; 19 cases; the old generated cases whose bound moved were corrected.
- **vfx-catastrophe (fbfdf182):** the policy line said the tremor block is closed, which also refused a `_note` there; now closed except underscore keys in both places, and a rule `vfx-catastrophe-order`: the calm onset and settling are never quicker than the normal ones, the sprite tiers ascend, every pair runs low to high. 10 cases with VFX's three. `apply-vfx-catastrophe-cases.cjs` is dropped.
