# Desktop test builds: Windows, Linux and macOS (Tools, 2026-10-28)

Owner: Tools. Brief: the EP, 2026-10-28 (ADR 0011, PC first). Re-cut on 2026-10-28 for Legal's RL-203, RL-204 and RL-205. One manual workflow builds the game for the three PC platforms from a commit, packs each as a folder a tester can unpack and run, checks what a Linux runner can check, and uploads three artifacts. Nothing is signed or notarized (zero budget).

**These are test builds, not releases.** Under Legal's RL-203 a run exists only after Orb says yes in one sentence naming desktop test builds (the 1 November renewal can carry it); the files are kept one day and the EP deletes the run once the testers have them; no link, post or mention anywhere; nothing from a run is a release, a Legal pass or a store build.

## Starting it

GitHub, **Actions**, **Desktop builds**, **Run workflow**. Two audiences (Legal RL-262, `docs/legal/desktop-build-rulings.md`; added 2026-11-14):

- **`owner-private`** (the default): `gh workflow run desktop-builds.yml -f audience=owner-private`. For Orb and Orb 2 only. **No approval file is needed and nothing is uploaded**: the run exports, packs and checks the build (route scan, notices, lock, the Linux bench's gameplay hash) to prove it can be made, and its summary says nothing was kept. The Windows-runner jobs are skipped (they need the Windows zip, which this audience never uploads). The file for Orb and Orb 2 is made on Orb's own PC with `tools/desktop-package.mjs` and moves by drive or private message.
- **`outside-testers`**: `gh workflow run desktop-builds.yml -f audience=outside-testers -f orbs_yes=<date>`. Needs Orb's recorded yes (below), keeps three packages one day, runs the Windows jobs.

Both audiences refuse: a commit that is not on main, a package check that fails, and a feedback target that is a public issue (`ui/data/send.json`). `node tools/check-desktop-audience.mjs` (in CI) fails when an upload or download step is not gated to `outside-testers`. Inputs:

| Input | Default | What it does |
|---|---|---|
| `audience` | `owner-private` | `owner-private` or `outside-testers` (above). |
| `orbs_yes` | empty | `outside-testers` only: the date (YYYY-MM-DD) of Orb's yes naming desktop test builds. The approval step refuses a run without a date that matches the recorded file. |
| `ref` | the commit the workflow was started on | Any commit, branch or tag to build. |
| `frames` | `2400` | Ticks the Linux bench plays before it prints the gameplay hash. |

There is no input to unlock Reduce flashing: the builds are always locked. A run takes about 15 to 20 minutes on a runner (the templates download is 1.28 GB; the three exports are about 30 seconds in all; the Linux bench about a minute).

## Where the artifacts land, and for how long

The run's page, under **Artifacts**, three of them, named for the commit, **kept 1 day** (RL-203 condition 1):

| Artifact | Holds | Size (a 2026-10-28 build) |
|---|---|---|
| `orb-combat-ex-windows-x86_64-<sha>` | `orb-combat-ex-windows-x86_64.zip`, `SHA256SUMS.txt` | the exe is about 118 MB |
| `orb-combat-ex-linux-x86_64-<sha>` | `orb-combat-ex-linux-x86_64.tar.gz`, `SHA256SUMS.txt` | the binary is about 82 MB |
| `orb-combat-ex-macos-universal-<sha>` | `orb-combat-ex-macos-universal.zip`, `SHA256SUMS.txt` | about 65 MB zipped (an Intel slice and an Apple silicon slice) |

GitHub wraps an artifact in a zip of its own: download it, unzip it once, and the game's archive is inside. The Linux one is a `.tar.gz` on purpose: an artifact zip drops the executable bit, a tar keeps it. The repository is public, so anyone signed in to GitHub can download a run's artifacts while they exist: that is why the run waits for Orb's yes and keeps them a day.

## What each holds

One folder per archive, and in it:

- **The game.** Windows: `orb-combat-ex.exe` (release, Compatibility renderer, x86_64, the game's data embedded). Linux: `orb-combat-ex.x86_64` (the same, ELF). macOS: `Orb Combat EX.app` (release, universal, the data in `Contents/Resources/Orb Combat EX.pck`, Godot's ad-hoc signature in `_CodeSignature`; the bundle id is a placeholder, RL-205).
- **`README.txt`**: the commit and date; the flashing notice and the AI line **word for word from the site's active notice file** (`tools/site.json` `interim.notice`; a draft is refused); Legal's PRIVACY section (RL-204); how to run it on that platform; the heading LICENSES. Legal's other words (the Windows warning sentences, the `xattr` lead-in) are constants in `tools/desktop-package.mjs`, and the self-test holds each against Legal's addendum in `docs/legal/page-fixed-lines.md`.
- **`NOTICES.txt`**: the Godot Engine license and copyright, the Open Sans license and the engine's other components, from `tools/site-licences.json`.
- **`build_info.json`**: `{"commit": "<sha7>", "date": "<date>"}`.

**No assurance words.** The package check refuses "safe", "tested", "verified", "virus-free" and "compliant" in README.txt and in the text we wrote around the licenses. The license texts themselves are other people's and stay as published (the Mozilla license says "compliant" once, in NOTICES.txt).

## What the run refuses (RL-203 condition 3, RL-204 condition 1)

Before the import, on the checkout (`node tools/desktop-package.mjs routes`), and the run stops if any of these fails:

- `ui/data/features.json` has `lock_reduce_flashing` true (the step before sets it) and `capture_hook` false (RL-196's build-time fix);
- the standing route scan (`tools/site-routes.mjs`, the six routes of RL-195 and RL-196) is clean: no override of the flag, no unguarded write of the option or the register, no unguarded debug key (F8 is refused under the lock), the capture hook attached only under `capture_hook` or an unlocked build;
- **the six words** that start a run with no flashing notice (`bench`, `frames`, `shot`, `nonotice`, `flashcap`, `study`, `BYPASS_WORDS` in `ui/hud/ui_hud.gd`) are exactly those six, and the capture hook cannot attach off the web;
- **no command-line flag reaches normal mode**: in every packed script (the three desktop presets' own exclude list applied), no statement that reads a command-line or page argument (`args.has`, `OS.get_cmdline_user_args`, the notice's argument reader) has a block that writes the lock flag, the Reduce flashing option, the register (`reduced_flashing`, `force_reduced`, `flash_calm`) or the debug key; and no packed script (a demo or test scene a tester could name on the command line) switches the lock off. This is a **static** check of the sources of the commit being built. It is not a run of the exported game with flags.
- **online play is off and unreachable**: no packed script names a network class (`HTTPRequest`, `ENet*`, `PacketPeer*`, `UDPServer`, `TCPServer`, `StreamPeer*`, `WebSocket*`, `WebRTC*`, `Multiplayer*`) or any `Net*` class of `net/` or `res://net`, `project.godot` names no `res://net`, and **`net/*` is in the exclude filter of all three desktop presets**. The RL-204 privacy line depends on this.

After the exports, on each unpacked archive (`desktop-package.mjs verify --locked`): every file is there; magic bytes (`MZ`, ELF, a universal Mach-O with two slices); the embedded pck's `GDPC` footer; sizes; the macOS bundle; `build_info.json` names the commit; Legal's README words; the lock compiled in; the capture hook off; **no `res://net/` path anywhere in the packed file list**.

The Linux binary is also **played** headless (`--seed=4 --frames=2400 --bench`) and must print the project's own gameplay hash (`d4f6342a1009bdbc` at tick 2400 on 2026-10-28). **The Windows and macOS builds are read, not run** (a Linux runner cannot start them); the Windows exe was played headless on Orb's PC and printed the same hash.

**Not checked by the workflow, kept by people** (RL-203 conditions 2 and 4 to 6): that the commit passes what a pin move passes (a nightly on it, the signature clip and the collapse clip in both modes, reduced, within 2.5 / 3 / 2); that nothing links to or mentions the run; that nothing from it is called a release. The EP deletes the run after the testers have the files.

## The macOS app is unsigned

There is no Apple developer account, so the app is not signed with a certificate and not notarized. Godot's own **ad-hoc signature** is on it, the minimum that lets an Apple silicon Mac run it at all once the tester allows it. README.txt tells them (Legal-cleared words): unzip and drag the app to Applications; try to open it and click Done; System Settings, Privacy & Security, **Open Anyway** (on macOS 14 and earlier Control-click, Open); or from Terminal, "remove the download flag from this app only": `xattr -dr com.apple.quarantine "/Applications/Orb Combat EX.app"`. On Windows the equivalent is SmartScreen's "More info", "Run anyway".

## What changed in the repo, and what lives outside Tools' paths

In Tools' paths: `.github/workflows/desktop-builds.yml` (new), `.github/actions/setup-godot/action.yml` (a new `desktop-templates` input: the same pinned `.tpz` and SHA-512, unpacking only the Windows, Linux and macOS release templates), `tools/desktop-package.mjs` and `tools/desktop-package-selftest.mjs` (new, in CI's data job), this page. `linux-export.yml`, the cheap Linux-only run for the Deck work, was folded into this workflow later (CD-12, 2026-11-07): the Linux export, the bench and the hash check are here, behind the same lock and route scan, and the file is gone.

Outside them, parked as `docs/tools/pending/desktop-builds/export-presets-macos.patch` for the EP to apply: `export_presets.cfg` gets (a) a fourth preset, **macOS** (universal, bundle id `io.github.dixonbalsagna.orbcombatex` and app name "Orb Combat EX", RL-205; ad-hoc signing, no notarization), and (b) `net/*` at the front of the **exclude filter of the Windows, Linux and macOS presets** (not the Web preset, so the demo's export and the flash-set rule are unchanged: RL-197). The workflow's routes check fails without (b).

**project.godot is not touched.** Godot refuses a universal or arm64 macOS export unless `textures/vram_compression/import_etc2_astc` is on, and `project.godot` is a FULL flash-set trigger (RL-128). The workflow sets that one line in its own checkout (`desktop-package.mjs astc`, before the import). The game imports no textures. To export the macOS preset by hand, switch the same setting on in a scratch copy, not in the tree.

The Windows exe has Godot's default icon and no file-version fields (`modify_resources=false`: `rcedit` is a Windows tool).

## To do next (needs people)

- Orb's yes, in one sentence naming desktop test builds (RL-203); then the EP dispatches with `orbs_yes`.
- A Windows PC and a Mac that did not build it: open each, get past the warning with the README's steps, reach the first screen. Until then those two builds are structure-checked only.
- Legal: the bundle id and app name stay placeholders until the formal title search (RL-205).

## Running the tree-editing commands by hand

`desktop-package.mjs lock`, `astc` and the text commands edit the tree they are given, so `lock` and `astc` refuse a **working checkout** (a `.git` in the root, a folder or a linked worktree's file) outside CI. An export without `.git` (`git archive HEAD | tar -x -C <dir>`) is a scratch tree wherever the script is run from, even with its own copy of the script inside it: `node <dir>/tools/desktop-package.mjs lock --root <dir>`. Before 2026-10-28 evening the guard compared the root with the folder the script lives in, which refused exactly that case.

## The Windows jobs and the Linux still (A-TOOLS-13 and spike S5, 2026-11-14)

- **`windows-bench`** (in `desktop-builds.yml`, after the `desktop` job, so behind the same lock): a Windows runner downloads the Windows zip the first job packed, unpacks it, runs the exe headless through the same bench match (`--seed=4 --frames=<frames> --bench`) and compares its gameplay hash with the Linux build's, which the first job hands over as an output. A different hash, or none, fails the run. It uploads nothing.
- **`windows-still`** (same file, same lock): the exe is started with a window on the runner's own desktop, through ANGLE (`--rendering-driver opengl3_angle`, Direct3D with software WARP when there is no GPU, which a hosted runner has not), and one still of the screen is taken and kept for a day. NEVER run on a runner before the first dispatch: whether the window opens there is exactly what this job finds out. If it does not stay up for 30 seconds or the still is nearly one colour it fails, and its summary shows what the game printed.
- **`linux-still.yml`** (spike S5, dispatch only, its own file; not one of the desktop workflows, so it never uploads the binary): exports the Linux preset of a commit, starts it under Xvfb with the Compatibility renderer on software GL, and keeps one still. The one page of what was tried, what it cost and what it shows (`docs/tools/s5-linux-still.md`) is written from its first run.
- **`windows-local`** (same file, `owner-private` only; the EP, 2026-11-21): the first two jobs need the Windows zip, which only an outside-testers run uploads, so on the owner-private route they never run. This job makes the Windows exe **on a Windows runner** (Godot 4.7.2's Windows editor and the Windows release template, each SHA-512 checked), so no artifact crosses and nothing is uploaded (Legal RL-262), starts it, plays the same bench match through the console wrapper of the same export and compares its gameplay hash with the Linux job's (a job output, text), then starts the windowed exe on the runner's desktop and measures one still of the screen. **The still is not kept** (a kept file is an upload): the summary says whether the game stayed up for 30 s, how many distinct colours the screen had, and shows the game's first lines. Never run on a runner before: the first dispatch is its test, and the still step is the likeliest to need a fix (a hosted runner has no GPU and WARP is untested here). `tools/check-desktop-audience.mjs` holds: the job has no upload or download step.
- The hash comparison across Windows, Linux and the project's own bench is what A-TOOLS-13 asks for beside the still; the seed-only planet comparison across the two platforms stays with World's digest tool (the brief's amendment), read beside S5.

## The owner-private build on Orb's own PC: one command (A-TOOLS-01, 2026-11-14)

Legal's RL-262 says the file for Orb and Orb 2 is made on Orb's own PC with the same packaging tool, never kept by a CI run. `node tools/desktop-local-build.mjs [--commit <rev>] [--out <folder>] [--godot <exe>]` does the whole sequence for Windows (and, since 2026-11-23, Linux: see the last section), about 3 minutes, headless and at below-normal priority:

1. `git archive` of the commit into a scratch folder: **the committed files only, never your working tree**, which it does not read or change (so `write-build-info.mjs` runs on the scratch copy, never in the shared folder);
2. lock Reduce flashing on, put the version number into the export preset, the routes check (lock, bypass words, no net/, feedback target not a public issue), write build_info.json;
3. import, export "Windows Desktop" (release), then the project's bench and the **exported program's** bench: both must print the same gameplay hash;
4. pack: the program, README.txt (Orb's owner-approved notice and the line "ORB-PRIVATE: a private build for Orb and Orb 2 only ..."), NOTICES.txt, build_info.json; zip as `orb-combat-ex-ORB-PRIVATE-windows-x86_64-<commit8>.zip`;
5. unzip it somewhere new and verify the folder the way a player's PC finds it.

It stops at the first failing step and names it. It writes the zip, `<zip>.sha256.txt` and `build-record.txt` to `homework/Files/desktop/<commit8>-ORB-PRIVATE/` (git-ignored; `--out` changes it). The file moves to Orb 2 by a drive, the home network or a private message, never a public link. `--with-working-tools` is a TEST-ONLY switch (it copies the working copy of the packaging tool into the scratch folder, says so in the record and the last line, and the package is then not a build of the commit alone).

**Tried on 2026-11-14** on commit 5963d224 (main), this PC, with the working-tree packaging tool because the ORB-PRIVATE change was not committed yet: every step ok, bench hash `7b8c8aff21d1a5cb` from both programs (the same as the CI run's, 43589936940), zip 44,397,278 bytes. Not tried: a run without `--with-working-tools` (it refuses until the ORB-PRIVATE change is in the commit being built, and says so); a run of the resulting program with a window (no session opens a Godot window; the program was started headless for the bench only); Linux (the tool is Windows only today); Orb 2's PC.

## Linux in the same command, saved runs and clean records (path to Alpha 1, job 7, 2026-11-23)

- **`node tools/desktop-local-build.mjs --platform windows|linux|both`** (default `both`; the paragraph above is the Windows half). The Linux package is `orb-combat-ex-ORB-PRIVATE-linux-x86_64-<commit8>.tar.gz`: the "Linux" preset exported, README.txt, NOTICES.txt and build_info.json from the same packaging tool (`text --platform linux`, the owner notice and the ORB-PRIVATE line), packed by `tools/lib/targz.mjs` (the program 0755, the rest 0644: Windows' own tar cannot give a file an executable bit, so the archive is written by our own writer, the same bytes for the same inputs), unpacked somewhere new with the system tar, and checked by `desktop-package.mjs verify --platform linux` (files, ELF magic, pck footer, notices, lock, the private line). The record also says the program has its executable bit inside the archive.
- **What it does not do on a Windows PC: play the Linux program.** It is an ELF. The record says "NOT played on this PC" and gives the project's own bench hash for comparison; the `desktop-builds.yml` run plays the Linux binary on a Linux runner and compares its hash with the project's. On a Linux machine the same command plays it. No WSL is installed here, so no Linux program has been started from this tool.
- **`build-record.txt` is written clean:** the scratch folder is `<scratch>`, a user's folder `<user>`, the repository `<repo>` (`tools/record-paths.mjs`; CI's data job checks that no user folder path is in anything under `docs/tools`). The records of the first two Windows builds (cb8d7934 and b624340a) were cleaned with it and filed as `docs/tools/runs/<commit8>/owner-private-build-record.txt`.
- **`node tools/desktop-run-record.mjs <run id>`** saves a `desktop-builds.yml` run as a page: the jobs with results and times, the failed steps with the last lines of their log, the gameplay hash each job printed and whether they agree, the packages' sizes and SHA-256 sums as they stood on the runner, and the artifact count (0 for an owner-private run). Default file: `docs/tools/runs/<commit8>/desktop-run-<id>.md`.
- **The build number** is `tools/version.json` plus the top entry of `docs/tools/changelog.md`, added together by `node tools/version.mjs --next` in the commit that is built (the build counter is 0 until then, so a build says 0.1.0). `node tools/version.mjs --check --ready` fails until the entry has its line for players.

## The testers' menu hides the modes testers cannot use (path to Alpha 1, job 14, 2026-11-23)

`ui/data/features.json` `testers_package` (false) hides the mode rows whose `testers` is false in `ui/data/modes.json` (today the campaign and the network row; `ui/core/ui_modes.gd`; `docs/ui/menus-a1.md` section 4 said "Tools' package build sets it", and nothing did). Now: **`node tools/desktop-package.mjs testers --root <scratch tree>`** sets it (same scratch-tree guard as `lock`); `desktop-builds.yml` runs it for the `outside-testers` audience only; **`routes` and `verify` take `--testers` or `--no-testers`** and the workflow passes the one that matches the audience, so a testers' package whose flag is off (or has no row to hide), or Orb's own owner-private build with the flag on, fails the run. `verify` reads the packed `features.json` and `modes.json` from the package itself. Proven on a real Windows export of main with the edit (the packed flag read true; `--no-testers` on it fails; `routes --testers` before the edit fails); UI's `hud_check` already holds that the menu's rows follow the flag. Not changed: the rows marked "coming" (couch 2v2, horde, practice, custom planet) still show as "Coming" in the testers' menu, since their `testers` flag is true; whether testers should see an unbuilt row is UI's and Orb's call.
