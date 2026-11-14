# The version number and the changelog (A-TOOLS-07, Tools, 2026-11-14)

## What the number is

`<major>.<minor>.<build>`, for example `0.1.7`. Major and minor are the project's own (`tools/version.json`, today 0.1). The **build** is a counter: it goes up by one for every build handed to a person (a kept build, a desktop build, a test build), and only through `node tools/version.mjs --next`, which is run in the commit that is built, so the number a build carries is in its own commit and a rebuild of the same commit has the same number. It is not the same thing as a build's id (a page build's commit and cache key, `orb-first-play-<commit8>-<key8>`, which names the files and which a saved match carries): the id says which exact files, the number says which release.

## Where it goes

| Where | How | By |
| :--- | :--- | :--- |
| `build_info.json` of every build (`version` beside `commit` and `date`) | `tools/write-build-info.mjs` reads `tools/version.json` | Tools, done |
| The Windows exe's file and product version (`0.1.7.0`) and the macOS app's version (`0.1.7`) | `node tools/desktop-package.mjs version --root <checkout>`, a step of `desktop-builds.yml` that edits its own checkout only | Tools, done |
| The changelog | `docs/tools/changelog.md`: `--next` writes the new entry above the old ones: the commit subjects since the last entry ("For the team") and a line for players that stays a placeholder until it is written | Tools, done |
| **On the screen** | a line in a menu and in the report (below) | **UI**, waiting for the words and the place |

## The check

`node tools/version.mjs --check` (in CI): the counter and the changelog's top entry are the same number. `--check --ready` is run when a build is handed to a person: it also refuses an entry whose line for players is still the placeholder (Orb reads that line first). `node tools/preview/build-check.mjs --build <a build>` prints the build's own stamp from its packed data, version included: that is the number its menu must show (the check of the brief: "the number read from a build's packed data equals the one on its menu still"; the menu part waits for UI's line and a still through the launcher, which is a visible change and goes with a side-by-side).

## For UI: the line on the screen (draft words, Orb sees them before use)

- **Where:** one small line at the foot of the pause menu and of the start menu, in the quiet colour of the hint strip: **"Version 0.1.7"**. Nothing over the fighters. On the match-over card and in the saved report the same number sits with the commit: **"Version 0.1.7 (build 59c6b195, 14 November 2026)"**, so a report says which build it came from in words a person can read out.
- **Where it comes from:** `UiFeedback.build_info()` already reads `res://build_info.json`; `version` is one more key in it (a build made before this has none: the line is left out, never "unknown").
- **For Orb, in plain words, the question:** "Do you want the number to show on the menus as a small 'Version 0.1.7' line at the bottom, and the report to say the same number? It tells you and your tester which build you are both looking at."

## The first changelog entry

Written when the first build is numbered (A1's desktop build, A-TOOLS-01): `node tools/version.mjs --next`, then the line for players, then `--check --ready`. Draft of that line for Orb (plain words, no team names): "This is the first numbered build: the game you played on 9 November, made as a program that starts on its own on Windows and Linux, with a number so we both know which build it is, and a button that saves your match so you can send it to us." Orb changes it as they wish.
