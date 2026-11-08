# Gate outputs, Encounter's parks on main (CD-22)

Run 2026-11-07, in a scratch tree from `git archive` of main 85e838b6. Main has since moved to 665f58d6, but the only change under `sim/`, `data/`, `tools/schemas/` and `tools/feel/` is one line in `sim/core/tools/run-all.js`, a runner these gates don't call. The parks were applied in order:
- main-rows;
- refusal-reasons (with Orb's scheme folded in);
- flight-strikes;
- launch-cuts with its grant;
- stick-lunge;
- team-ending.

Godot 4.7.2, headless, below normal priority.

- `stack/sim_g5/`, switches off: the golden check, validate, self-test, two-fighter ratchet, every director check (38) and the 4 core 2v2 checks.
- `stack/render_g5/`: Rendering's 15 gates.
- `stack/on_g5/`, the next batch's page (the morning page's 69 rows, plus flightStrikes, aimCuts and stickLungeLight) with `flickKeep` on: determinism, rollback, two_states and every director check. `knock_wall_check` fails one row, World's building index (see `docs/director/pending/main-rows/`).
- `stack/ledger-1229-*`: Tools' ledger of Orb's 1229 play (`node tools/feel/ledger.mjs homework/Files/orb-first-play-20261107-1229.json --tree <tree>`), on Tools' 57 sim switches of Orb's build, with the refusal knocks on, and with `flickKeep` too. `ledger-1229-summary.txt` counts rows and physical presses (one-tick runs of one kind).
- `stack/gt_g5.txt`: Tools' gauntlet, `--arms orbs --levels easy --n 40`, on the same switches with the knocks on: shipped, `flickRun` 1.5, and `flickRun` + `flickKeep`. The arm's guard is not yet fixed by Tools (`docs/design/gauntlet-plan.md` section 5).
- `stack/*-unit.txt`: the new and changed checks, run alone on the tree.
- `stick-slam/full_send_check.txt`: the full send's check, on the stack plus `docs/director/pending/stick-slam/`.
