# Keeping a second copy of Orb's builds and play files (A-TOOLS-09, Tools, 2026-11-14)

`homework/Files` is git-ignored: every build Orb played, their saved matches and the report folders exist only there (2.9 GB on 2026-11-13). `tools/backup-kept.mjs` copies them to a second place, checks the copy and puts them back. **Where the copy lives is Orb's answer** (an external drive, a stick, another PC's folder): the tool takes any folder with `--to`. Nothing is sent anywhere by it; nothing is ever deleted, from the source or from the copy.

## Make or refresh the copy

```
node tools/backup-kept.mjs --to "D:\Orb Combat EX backup"
```

Copies the kept builds (`builds/`, every folder), the saved matches and results (the `orb-first-play-*.json` and `*-result-*.json` files of the top folder) and the report folders and zips (`reports/`). A second run copies only what is new. `--include builds,play,reports` and `--only <part of a name>` narrow it; `--dry` shows what it would do. A file already in the copy that is not the source's is named and left alone (a kept build is never changed).

## Check the copy

```
node tools/backup-kept.mjs --verify --to "D:\Orb Combat EX backup"
```

Reads every file of the copy against `BACKUP-MANIFEST.json` (size and SHA-256) and says `THE COPY IS WHOLE` or names each file that is missing or changed. Run it after a copy and whenever the drive has been away.

## Put it back (the written restore)

1. Plug in the drive or stick. Close the game and every server window.
2. Into a NEW folder first, to look before touching anything: `node tools/backup-kept.mjs --restore --from "D:\Orb Combat EX backup" --to "C:\Restore test"`.
3. Check what came back: `node tools/backup-kept.mjs --verify --to "C:\Restore test"` after copying `BACKUP-MANIFEST.json` into it (the restore does not copy the manifest).
4. To fill the real folder: `node tools/backup-kept.mjs --restore --from "D:\Orb Combat EX backup" --to "<the project>\homework\Files"`. It copies the files the folder lacks and checks each; a file that is there and the same is left; **a different file is never overwritten**: it is listed as REFUSED and the command exits 1.
5. Start a kept build from its own folder as before (its `serve.cmd`).

## Rehearsed

2026-11-14, on the real folder: the kept build of commit 1931a0f8 (2,499 files, 185 MB) and the 8 saved match and result files, copied, copied again (nothing new), verified (2,507 files, 0 problems), restored into a new folder, verified there (0 problems) and restored again over it (nothing to do): `docs/tools/runs/9431211a/backup-rehearsal.txt`. The whole 2.9 GB was not copied: the check is the same for every file, and copying it needs the place Orb chooses.

Self-test (CI): `node tools/backup-kept-selftest.mjs`, 21 checks: the sets, the second run, a changed copy named and never overwritten, verify, the restore and its refusal, the guards on where it may write.
