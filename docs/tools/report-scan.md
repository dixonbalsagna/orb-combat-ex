# The report scan: a size limit, and names and folder paths (Tools, 2026-11-23; path to Alpha 1, job 14, second piece; X-21, Legal G13)

`node tools/report-scan.mjs <report folder or files>... [--names <file>] [--no-machine-names] [--json]`

It reads what the game made for a tester to send: the folder under `user://reports` (the match files) and, once UI's report folder copies them, the newest logs (`docs/tools/pending/crash-file/README.md`). It fails (exit 1) on:

| Rule | What | Limit or pattern |
| :--- | :--- | :--- |
| size | one file | 4 MB (`perFileBytes`) |
| size | the whole folder | 9 MB (`totalBytes`) |
| paths | a user's folder (`C:\Users\<name>`, `/c/Users/<name>`, `/home/<name>`, `/Users/<name>`), a drive path, a network share | `tools/report-scan.json` `patterns` |
| names | the account name and the PC name of the machine that runs the scan; every line of `--names`; every line of `.private/testers/names.txt` when it exists (Orb's PC) | whole words, any case, 3 letters or more |
| addresses | an email, an IPv4 address (not 127.0.0.1), a network card's address | `patterns` |

A file with a non-text extension is checked for size only (the scan says how many). **A finding names the file, the line and the rule, never the matched text** (a name found in a report is not repeated in a log).

## The size limit, and where it comes from

X-21 asks that the report fit Discord's free upload limit, "check the current limit and cite it". As of the search of 2026-11-23: **20 MB per file for accounts without Nitro since 13 August 2026 (it was 10 MB before)**, from Discord's announcement as reported by [Neowin](https://www.neowin.net/news/discord-raises-file-size-upload-limit-for-its-non-subscribers/), with other guides agreeing. **Tools did not read Discord's own help page: re-check it before the guide is final.** The limits above (4 MB a file, 9 MB in all) sit under both the new and the old figure, so a report still goes if the new one is wrong. A half-hour match's replay is the largest file the game writes; a copied log is cut to its last 200 KB.

## What UI ports (so the copied logs are clean before they are written)

A log the game writes can hold the player's folder paths. The report folder's copy of a log must be cleaned in the game, not left to this scan. The patterns are data, in `tools/report-scan.json` (`patterns`, as JavaScript regular expressions; the Godot RegEx class takes the same forms): replace each match of `windowsUserFolder` and `posixHome` with `<user>`, each `driveRoot` with `<path>`, `uncShare`, `email`, `ipv4` and `mac` with `<removed>`, and drop the OS user name and PC name wherever they appear as whole words. This tool then proves it from outside: `node tools/report-scan.mjs <the report folder>`. Not built (it is game code): the port.

## What was read, 2026-11-23

- The real logs and reports in this PC's own game data folder (five files, 21 KB, written by headless tool runs): 0 findings. **That is not evidence about a played game's log**: the file of a windowed run holds the graphics driver's lines and more, and none has been scanned yet.
- The forced-crash check's logs (`tools/crash/crash-check.mjs`, row 7, run on Windows with the machine's own names): 7 files, 0 findings.
- The self-test (12 checks) covers each rule, the allowed engine lines, the size limits and a folder scan.
