# docs/production: Production Operations

The plan's paperwork, so the Executive Producer can steer and Orb can see where the project is. Owner: Production Operations (the Executive Producer is the only source of status and the only one who commits).

| Page | What it is | Who changes it |
| --- | --- | --- |
| [milestones.md](milestones.md) | **The page Orb opens.** Which milestone (A1 to A6) the project is in, what is left, what could move the date, Orb's decisions. Generated | Rebuilt from status.json |
| [milestone-rows.md](milestone-rows.md) | The full table: every row of every milestone, with what it needs. Generated | Rebuilt from status.json |
| [status.json](status.json) | The one input the status comes from: row statuses with their commit or report, the switch-row count, the decisions, the added items | Production Operations, from the EP's status messages |
| [change-control.md](change-control.md) | How a new idea waits (the six steps, after A4, after the freeze) | Production Operations; Orb's yes recorded by the EP |
| [ideas-log.md](ideas-log.md) | Where ideas wait, with their price and Orb's answer | Production Operations logs; the EP prices |
| [risk-register.md](risk-register.md) | The Alpha push's risks: owner, early sign, guard; what happened; the old rows' fates | Production Operations |
| [backlog-draft.md](backlog-draft.md) | Draft of the single backlog keyed by register id (the EP owns it). Generated | Rebuilt from status.json |
| [token-record.md](token-record.md) | Draft of the weekly token record (the EP owns it) | Production Operations, from the EP's figures |
| [done-tests.md](done-tests.md) | Draft of the "done test" for each Alpha feature (the EP owns it) | Production Operations |
| tools/ | build-tracker.mjs (builds the three generated pages and checks them), check-pages.mjs (checks the hand-written pages), milestone-data.mjs (the path's goals and exit lines) | Production Operations |
| runs/ | Saved check output, one folder per commit, as the playbook's CD-22 asks | Production Operations |

## Every two days (the EP sends status)

1. Edit status.json: each row that moved gets its status and its commit (landed) or report (reported); add the new switch-row count; note the date in `asOf`.
2. Try the change first if unsure: `STATUS_FILE=<a copy> node docs/production/tools/build-tracker.mjs --check`.
3. Run `node docs/production/tools/build-tracker.mjs`. It rewrites the three generated pages and prints its checks; every one must pass (a landed row without a commit id fails, for example).
4. Save the output under docs/production/runs/<sha>/ when the EP commits.

No Godot, no browser, no dependencies: Node only.
