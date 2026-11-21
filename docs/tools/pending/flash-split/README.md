# flash-split (park, Tools, 2026-11-21)

The EP's first priority: CI run 44881357568 on b0e20f9a (GW1a) cancelled the job "Flash count (worst cases, flash register)" at its 45-minute limit, in the step "Play the worst cases" (07:40:54 to 08:26:10Z). Every other job passed. Until this lands, every push hits the same limit.

## What it changes

`flash-split.patch` (apply with `git apply`; it touches only `.github/workflows/ci.yml` and `tools/ci-budgets.json`) turns the one job into three:

| job | what it does | limit / budget (min) |
|---|---|---|
| `flash-selftests` | the node self-tests that were the first half of the old job (no Godot) | 30 / 20 |
| `flash-cases` | a matrix of five sets, one runner each, each plays its share of the worst cases and keeps the run files one day | 30 / 20 |
| `flash` | same id and name as before; `needs: flash-cases`, downloads the five sets into one folder and recounts them as ONE with `check-log.js` | 15 / 10 |

`deploy` now needs `flash-selftests` as well. The recount is unchanged and still needs every required scenario, so a scenario missing from any set still fails it.

The five sets:

- scenes-1: `--only=mash,mashcity,clash,signature,signaturecity,rushcity,transform,collapse,plumedesert,plumeice,plumevolc` (the negative control runs here only)
- scenes-2: `--only=mashdummy,ring,launchai,clashcity,signaturedummy,blastdummy`
- ai-1: `--only=ai --slots=PROTAGONIST,RIVAL --seeds=4,39,104,106,7,9,43`
- ai-2: `--only=ai --slots=PROTAGONIST,REFERENCE --seeds=98,100,74,4,49,8,13`
- ai-3: `--only=ai --slots=RIVAL,REFERENCE --seeds=15,29,107,88,100,36`

## Why (measured on the cancelled run's log)

- 82 runs in the step: 42 non-ai (20 of 1,500 ticks, mean 27.7 s; 22 of 1,800 ticks, mean 30.7 s) and 40 `ai` runs (3 pairings, 7+7+6 seeds, two modes each, 3,600 ticks, 55.2 s each).
- That is about 57 minutes of cases one after another, after about 9 minutes of node self-tests in the same job (private preview 99 s, pixel pipeline 138 s, site hook 184 s), so about 67 minutes against a limit of 45. The step was cancelled at 36 minutes, with 58 lines logged.
- Split five ways each set is about 11 to 13 minutes plus about 2 minutes of set-up, which fits a 20-minute budget under the two-thirds rule (limit 30).
- The guess that each case boots the globe ground and is slower than before is consistent with the per-run times (about 28 to 31 s for 1,500 to 1,800 ticks), but it is a log reading, not an experiment.

## Checked here

- `check-workflows` ok (13 files), `check-workflow-shell` ok (262 steps), `ci-budgets-check` ok, `ci-budgets` self-test ok (7), on a scratch export of HEAD with the patch applied.
- `git apply --check` against HEAD passes.
- File-name parity, on a scratch export of HEAD (headless, below-normal, 90 ticks): `--only=ai --seeds=98,4` writes 12 files (three pairings x two seeds x two modes; the PROTAGONIST/RIVAL pairing is named `flash-ai-<mode>-<seed>.json`, the others `flash-ai-<mode>-<A>-<B>-<seed>.json`); `--only=ai --slots=PROTAGONIST,REFERENCE --seeds=98,4` writes 4 files, all among those 12. So the five sets write distinct names and the merged folder is the one the one-job run wrote.
- Local timing of the step on main, full length (same scratch export, below-normal, one Godot at a time): `--only=clash` 50 s for its two runs (normal, reduced; about 25 s each with start-up); one `ai` pairing and seed 91 s for its two runs (about 45 s each). Both are a little under the CI figures (27.7 to 30.7 s and 55.2 s per run), which is the machine, not a different job: the run counts, not the per-run time, are what overran the 45 minutes.

## Not proven

- The split has not run on a runner. The first CI run of it must be read, and the three budgets' `measuredMin` filled in from it (they carry the expected figures and "to be recorded").
- `upload-artifact` / `download-artifact` use the pins already in the file's other jobs; `merge-multiple` with the five artifact names has not been run here.
- Five runners at once is five times the Godot minutes for the cases; the one-job total was already about 57 minutes of runner time, so the cost is only the extra set-up (about 2 minutes times five).
