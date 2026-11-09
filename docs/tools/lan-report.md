# LAN report tools (Tools, 2026-11-08; Orb's overnight order: the next LAN play-test has every tool for reporting issues)

Three pieces of mine; Netcode saves the replay and the "report this" record, UI shows the button.

| Piece | What it does |
|---|---|
| `tools/preview/lan-strip.mjs` | Decodes a replay's recorded intents (`inputs` entries `[tick, slot, low, high, word2?]`, intent version 4: `SimIntent.pack` and `pack2`) into the clip kit's strip rows, so a native LAN match, which has no browser pad log, still gets a button strip. |
| `tools/preview/lan-clip.mjs` | Plays a report's replay through `blackbox-clip.mjs` (the replay path, the guarded launcher) from about 30 s before the report to 2 s after, and writes a player page with the strip drawn **under** the picture, in a canvas of its own (nothing covers a fighter). |
| `tools/preview/lan-report.mjs` | "Make my report folder": gathers the LAN files, films a clip of each report, zips the lot. `--write-cmd <folder>` writes `Make my report folder.cmd` (CRLF) into a LAN folder. |
| `tools/preview/lan-clip-selftest.mjs` | 71 checks, node only, no browser: the decode of every intent bit, hold and null entries, the window, the finder, the shortcut text, the refusals. |

## The file shape (agreed with Netcode through the EP, 2026-11-08; replaces my draft)

Netcode saves to `saved` beside the exe, one file a save: `lan-<commit8>-<main|old>-<yyyymmdd-hhmmss>-<over|pause|quit|report>.json`. Fields: `kind: "orb-lan-match"`, `pc`, `slot`, `mode`, `build {commit, lan}`, `reason`, `savedAt`, `tick`, `marks [{tick, kind:"report", tag, note, at}]` (the black box's shape), `frames {slow, rollbacks}`, `net`, and `replay` (SimReplay v4, a checkpoint every 60, the final hash), which also plays on the folder's `tree/` with `blackbox-verify <file> --tree <folder>	ree`.
What my tools read: `replay` (`ticks`, `inputs`, and what the page needs to start it), `build.commit` (else `commit`), `pc` (else `side`), `slot` (else 0 for main and 1 for old), `marks` of kind `report` (else a plain `reportTicks` list), `tag`, `note`, `reason`, `mode`. A plain black box file (`orb-first-play-*.json`) works as is (no report marks: the last 30 s, or `--tick N`).
- **Which file:** `lan-report.mjs` copies every saved file in, and films the NEWEST file of each PC (a later save holds the whole match to its tick and all its marks).
- **Which windows:** each `report` mark gets 1800 ticks before to 120 after; marks whose windows chain together share one clip (a group reaches back to its first mark); at most six clips a file (the newest); a file with no report mark gets its last 30 s.
- **Refusals:** a web folder that is not a kept build of the file's commit is refused before any browser starts (exit 3, a plain line in `lan-clip.json` and the README); a replay the page refuses (another data hash) is reported the same way.

## Running it

```
node tools/preview/lan-clip.mjs --file <report.json> --dir homework/Files/builds/orb-first-play-<commit8>-<key8>/web --out <folder> [--tick N] [--slot N] [--every 6] [--width 960 --height 540]
node tools/preview/lan-report.mjs [--from <folder> ...] [--no-clips] [--dry]
```
`Make my report folder.cmd`: double-click on the main PC, with the game closed on both PCs and the old PC's files copied over (a USB stick). It looks in its own folder and Downloads, takes the files of the newest 12 hours, copies (never moves or deletes), films each report from the kept web build of its commit, and writes `homework/Files/reports/orb-lan-report-<time>/` (reports, replays, logs, clips, README.txt) and a `.zip` beside. Nothing is sent anywhere; the README says the folder stays on Orb's PC and carries the flashing warning.

## Rules it keeps
Chrome only through `blackbox-clip.mjs`'s launcher (time limit, below-normal, CPU cap, this session's name in the profile), one clip at a time, a 20-minute limit a clip (`--clip-limit`); it refuses to run while `orb-combat-lan.exe` is running (`--force` skips); a commit with no kept web build gives no clip and a line in the README, never a failure; with no clip the folder is still complete.

## Proven, and not yet
- **Proven (2026-11-08):** the intent decode against `SimIntent.pack` and `pack2` (85 selftest checks, node only); the whole chain on a COPY of Orb's real 18,503-tick replay (given a report mark at tick 2,500 and Netcode's file name): the clip tool played it on build 1931a0f8's web folder (321 pictures, window 700 to 2620, about 5 minutes below-normal), the strip drew Y and B as "tap" with the left stick where it was, and the zip (18.8 MB, README, `saved`, `logs`, `clips`) was made with the original untouched. The player page carries its strip inside itself because a page opened from disk cannot fetch a neighbouring file.
- **Not proven:** a real LAN save: none exists yet. The first one decides whether a field name differs from the agreed shape here (`KINDS`/`SAVED` in `lan-report.mjs`, `reportMarks`/`commitOf`/`pcOf` in `lan-clip.mjs`). A match recorded by the native exe plays on the web page only if both read intent version 4 and the same data hash; the clip says so when the page refuses it.
- **Where the shortcut goes:** `Make my report folder.cmd` must sit in the LAN folder (it looks beside itself, where `saved` is, then in Downloads). A sample is in `docs/tools/shortcuts/`; it names this repository's tool by absolute path, so it is for Orb's main PC only. `node tools/preview/lan-report.mjs --write-cmd <LAN folder>` writes it; whoever builds the LAN folder (Netcode's handover) should run that.
