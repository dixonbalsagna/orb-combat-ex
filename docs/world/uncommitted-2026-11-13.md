# World's uncommitted paths, for the EP's clean-up (A-PROCESS-03; World, 2026-11-13)

`git status` on `sim/world/`, `data/biomes/`, `docs/world/` and `tools/world-checks.json`: **33 paths, none of them code or data** (every `sim/world` and `data/biomes` change is committed). All are docs, parks and run records. I have not committed or deleted anything. "Landed" means the park's diff reverse-applies to HEAD def3445a; "unlanded" means it applies forward.

## Keep (commit)

| Path | What | Note |
| :--- | :--- | :--- |
| `docs/world/gen3-field.md`, `front-limit.md`, `opening-slope.md`, `lot-gap.md`, `street-axis.md`, `surface-memo.md`, `water-window-warm.md`, `crater-collapse.md`, `meteor-crater.md`, `wall-hold.md`, `beam-grid.md`, `struggle-meet.md`, `bystanders-build.md`, `globe-step2.md` | design pages for work that is on main or parked | the record of why the code is as it is |
| `docs/world/lot-reach.md`, `power-world.md`, `struggle-meeting-point.md` (modified) | small edits since the last commit | keep |
| `docs/world/runs/66b66796/`, `c7b0414b/`, `globe-step2/` | gate records (CD-22): the cd05 re-cut, the bystanders window, terrain step 2 | keep; `globe-step2/` is 67 KB |
| `docs/world/img/struggle-meet/` | the meeting-point stills (28 KB) | keep |
| `docs/world/pending/globe-step2/` | **unlanded**, out of the 9 Nov batch for Camera's `chase_rush_check` (4 of 130 rows); World re-cuts it in A1 | keep until re-cut |
| `docs/world/pending/crater-collapse/`, `meteor-power/`, `civilians-removed/`, `cancel-keep/`, `places-reached/`, `forest-fire-linger/` | **unlanded** parks, each applies to HEAD | keep, they are the queue |
| `docs/world/pending/power-world/` (modified) | the park's diff applies neither way on HEAD (part of it landed, main moved); its grant patch is landed | keep; World re-checks it before the next power window |

## Ignore or delete (landed or empty of value)

| Path | Why |
| :--- | :--- |
| `docs/world/pending/beam-grid/` | **landed**: its diff reverse-applies. The folder is stale (`beam-grid.md` stays) |
| `docs/world/pending/gen3-field/` | README only, the gen 3 field is on main |
| `docs/world/pending/field-static-memo/` | a request note; the static memo landed in 3c9005ac |
| `docs/world/pending/power-world/grant-encounter-energy.patch` (the modified file) | landed; its edit can go with the folder when the park is re-checked |

If you commit the keep list, the three `pending/` folders that are stale can be deleted in the same commit (World will not delete them first: they are untracked, so the EP's commit is the record).
