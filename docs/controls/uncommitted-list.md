# Controls' uncommitted paths: keep or ignore (A-PROCESS-03; the EP's wave 2 brief, 2026-11-14)

`git status` under `sim/input/` and `docs/controls/` on HEAD e715c9cc: 6 modified tracked files and about 84 untracked ones (the pad group and its records are already committed, ac0ae1f7). **Everything is KEEP except two regenerable clip files, marked IGNORE.** Nothing here is in progress; nothing is half-done. Controls changes no git state: the EP commits.

| Path | Files | Verdict | Why |
|---|---:|---|---|
| `docs/controls/README.md`, `beam-answers-input.md`, `haptics.md`, `responsiveness.md`, `right-hand-attacks-model.mjs`, `right-hand-interface.md` (modified) | 6 | KEEP (commit) | real edits, 137 lines added and 1 changed; not line-ending noise (the same count with `-w --ignore-cr-at-eol`) |
| `docs/controls/*.md` design pages, untracked: `charge-lost`, `chord-pick`, `controls-audit`, `dodge-held`, `flight-strike-b`, `full-send-haptic`, `impact-haptics`, `lt-take-back-claw`, `orb-first-play-stick`, `push-stick`, `refusal-cues`, `refusals`, `stage-pulses`, plus this wave's `coverage-probe`, `check-scripts-answers`, `uncommitted-list` | 16 | KEEP | the design pages of parks that landed or are parked; `controls-audit.md` is cited by the audit as "uncommitted" |
| `docs/controls/pending/*/` (22 park folders: README + patches, 9 patches in `stick-feel`) | about 50 | KEEP | the record of each park's apply order and proof. The ones whose patches are on main (`b-no-beam`, `inert-knock`, `dash-handover`, `flick-kept`, `charge-lost`, `impact-haptics`, `stage-haptics`, `stall-keep`, `chord-full-send`, `dodge-held`, `flight-strike-b`, `landing` and more) are stale as "pending"; the EP may move them to a `landed/` folder, they still hold the proofs. `pad-group` and `coverage-probe` are this wave's open parks. |
| `docs/controls/runs/<sha>/` (`51b840f5` coverage readings, `592a807b` charge-lost) | 4 untracked | KEEP | CD-22 records |
| `docs/controls/clips/*.cjs`, `*.mjs`, `*.py` (the readers: `read-orb-aim`, `read-orb-lt-face`, `read-orb-release`, `read-stick-log`, `make-overlay`, `export-thumbs`) | 6 | KEEP | small scripts (2 to 8 KB); the `read-orb-*` ones only read Orb's play files and carry none of their contents |
| `docs/controls/clips/hitstop-ab.json`, `hitstop-ab.md`, `thumbs.md` | 3 | KEEP | the clip's input script and its notes |
| `docs/controls/clips/thumbs.json` (692 KB) and `hitstop-ab.overlay.json` (61 KB) | 2 | **IGNORE** | made by `export-thumbs.py` and `make-overlay.mjs`; regenerate on demand; the first is the largest file in `docs/controls/` |
| `sim/input/tools/stall_probe.gd` (+ `.uid`) | 2 | KEEP | the probe of the stall-keep park (`docs/controls/pending/stall-keep/`); read-only, no sim change |

One note for the EP: the six modified docs and the untracked design pages are cited by the audit's findings as "uncommitted", so committing them closes those citations.
