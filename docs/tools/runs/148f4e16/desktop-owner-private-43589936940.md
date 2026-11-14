# The first owner-private desktop build on a runner (Tools, 2026-11-14)

GitHub run 43589936940, workflow "Desktop builds", `audience=owner-private`, commit 148f4e1648b0f86afcd0a4d1f4acd799ce2c70d2 (main), 11:25 to 11:28 UTC, **success, about 2 min 45 s**. Legal RL-262: for Orb and Orb 2 only; no approval file; nothing uploaded.

## What the run did (53 steps, each read from the run)

| Step | Result |
| :--- | :--- |
| Audience is one of the two | owner-private: "no approval file is needed and nothing will be uploaded" |
| Refuse a commit that is not on main | ran: the commit against main reads `identical` |
| Refuse without Orb's recorded yes (RL-203) | **skipped**, as designed for this audience |
| Lock Reduce flashing on; version number into the export presets; routes check (lock, bypass words, no net/, feedback target not a public issue); ETC2/ASTC; import; build_info.json | all passed |
| Export Windows, Linux, macOS | all passed (about 9 s, 3 s, 11 s) |
| The project's bench and the exported Linux binary's bench | both print `gameplay hash at tick 2400: 7b8c8aff21d1a5cb`: the exported binary starts headless and plays the project's own match |
| Pack the three folders | passed, with Orb's owner-approved notice (`--notice site-interim-owner.json`, the EP's decision of 2026-11-14) |
| Unpack each archive and check the folder | passed for all three (below) |
| What this run kept | written to the run's summary: "Nothing was uploaded" |
| The three upload steps; the two Windows-runner jobs | **skipped** (gated to outside-testers) |

## The packages as they stood on the runner (they are not kept)

| Package | Size | SHA-256 |
| :--- | ---: | :--- |
| `orb-combat-ex-windows-x86_64.zip` | 44,413,715 bytes | `3ac0b3a27bc459136400cec2a2d7116fbd8d5bf4e3f8265c383148e99e4545bd` |
| `orb-combat-ex-linux-x86_64.tar.gz` | 34,758,997 bytes | `bea5e0b4f366434b418f5570973f34552bb8291f8af4ac7904f54dfc583cf15e` |
| `orb-combat-ex-macos-universal.zip` | 66,809,250 bytes | `f36ed2e611eeb25943636586737468e7c06b28fd7ecab074a5c53f231cd0988a` |

`tools/desktop-package.mjs verify` on each unpacked folder: files, the executable's magic bytes, the embedded pck, build_info.json (148f4e1, 2026-11-14), README.txt and NOTICES.txt hold. **Linux was run** (the bench above); Windows and macOS were **read, not run**.

**Artifacts: 0** (checked through the API: `total_count` 0). No file from this run can be downloaded. The checksums above are of files that were discarded with the runner, so they identify what this commit builds only if a later build of the same commit reproduces them; they are not a promise that it will (a zip carries file dates).

## What this does and does not give

- It proves that commit 148f4e16 can be exported, packed and checked for all three desktops by a workflow on a stock runner, that the lock, the routes check and the notice rules hold, and that the Linux program plays the project's own match to the project's own hash. That is the A1 exit's CI desktop build, for the owner-private audience.
- It does **not** give Orb a file: an owner-private package is not kept by a run (RL-262 section 1). The file for Orb and Orb 2 is made on Orb's own PC with the same packaging tool and moves by drive or private message. There is no one-command local build yet: `tools/desktop-package.mjs` has the steps (lock, version, routes, text, verify) and the workflow has the exports; a local `build` command that does the whole sequence on a PC is the next piece of A-TOOLS-01.
- It does not start the Windows or macOS program (the Windows runner jobs are for the outside-testers audience), take a flash reading of the package (G21, `docs/tools/a2-plan.md`), or say anything about outside testers (their README notice is Legal's final words, which do not exist yet).
