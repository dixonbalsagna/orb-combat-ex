# Silent passes in the tools behind the outside-tester gates (A-TOOLS-15, CD-21; Tools, 2026-11-14)

The brief: search every tool behind a gate on the outside-tester list for `grandfathered`, `report only` and `CHECK` lines, and either make each one fail the run or list it here with its reason. Searched: `tools/`, `.github/` (`*.mjs`, `*.js`, `*.yml`, `*.json`), 2026-11-14. Also searched, for the same kind of quiet exit: `continue-on-error`, `|| true`, "advisory", "warn only".

## Made to fail (changed in this park)

| Where | What it did | Now |
| :--- | :--- | :--- |
| `tools/clips/make.mjs` (the clip kit; the GIF check) | A GIF whose flash check threw an error got the verdict `CHECK` and was written to index.txt like any other line; `OVER GATE` and `FAIL` were lines too, and the run still exited 0. | Any verdict but `PASS` makes the run exit 1 and names the clip ("NOT PASS ... do not hand it over"). An error in the check is no longer a quiet pass. |
| `tools/flash/signature-gate.mjs --check` (CD-09 item 2, in the earlier park) | A grandfathered record printed `signature gate ok`. | It prints `signature gate EXCEPTION (grandfathered, NOT a pass of the limits ...)` and says so in its test. See the list below for why it still exits 0. |

## Listed, with the reason each stays

All of these concern ONE thing, the old public playable page (`/play/`, now offline) and the one commit it was pinned to. None of them is reached by a desktop build or by an outside tester's package: `desktop-builds.yml` does not call them, and an outside-tester package is refused until the approval file exists (criterion 4 of the brief).

| Where | The exception | Why it stays | Ends when |
| :--- | :--- | :--- | :--- |
| `tools/flash/signature-gate.json` (`grandfathered: true`, read by `signature-gate.mjs`, `check-site-interim.mjs`) | The pin 257a766c's signature clip reads 3 / 3 / 3 on the record, over the 2.5 / 3 / 2 limits. | Legal ruled the live pin (RL-195, RL-209) before the condition existed; the record is kept as it was measured. The check says EXCEPTION, never ok. A new pin has to pass the limits (the words-only child inherits the exception only if no reading is worse: `signature-gate-selftest.mjs`). | The playable page is retired, or its pin moves to a commit that passes the limits. |
| `tools/site-routes-grandfather.json` (read by `check-site-interim.mjs`, `flash/nightly-seeds.mjs`) | The routes scan (Legal RL-195 (b)) does not fail for that one pin's open routes that can lift the Reduce flashing lock. | RL-196: the live demo stays up while the lock-route fix lands; the entry names the commit and the ruling, and every other pin passes the scan in full. `check-site-interim.mjs` prints a note when it applies. | Same as above. |
| `tools/site-ui-excuse.json` (read by `check-site-interim.mjs`) | The pin whose game strings predate RL-192's swap is excused from the in-game-notice wording check. | Named ruling, for that commit only. | Same as above. |
| `tools/flash/signature-gate.json` `engineFlip` (read by `site-template.mjs`) | A custom web engine build is allowed one reading over the limit under RL-202. | Named ruling with an end date: `site-template.mjs` fails it after `until`. | The entry's own end date, or the pin's move. |

## Not silent (checked, nothing to change)

- `|| true` and `exit 0` in the workflows: `desktop-builds.yml:115-116` read a hash that the next step compares (an empty one fails the run); `flash-pixels-dryrun.yml` is a speed measurement with no verdict, by its own header; `flash-nightly.yml` continues past a failed capture only so that the next step, the verdict, reads the missing clip and fails the job (a clip not read is exit 2); `linux-still.yml` ends its background processes, then tests the still.
- `continue-on-error`: none in any workflow.
- `tools/flash/check-log.js:167` prints an "advisory" line about a small body; the verdict above it is the register's count, which fails the run.
- No "report only" mode exists in the tools.

## How to keep it so

`node tools/check-workflows.mjs` already refuses a workflow that does not parse. A new exception file (`*-grandfather.json`, an excuse file, an `engineFlip`-like entry) needs a row in the table above in the same commit; the EP's landing review reads this page.
