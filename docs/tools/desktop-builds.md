# Desktop test builds: Windows, Linux and macOS (Tools, 2026-10-28)

Owner: Tools. Brief: the EP, 2026-10-28 (ADR 0011, PC first). Re-cut on 2026-10-28 for Legal's RL-203, RL-204 and RL-205. One manual workflow builds the game for the three PC platforms from a commit, packs each as a folder a tester can unpack and run, checks what a Linux runner can check, and uploads three artifacts. Nothing is signed or notarized (zero budget).

**These are test builds, not releases.** Under Legal's RL-203 a run exists only after Orb says yes in one sentence naming desktop test builds (the 1 November renewal can carry it); the files are kept one day and the EP deletes the run once the testers have them; no link, post or mention anywhere; nothing from a run is a release, a Legal pass or a store build.

## Starting it

GitHub, **Actions**, **Desktop builds**, **Run workflow** (or `gh workflow run desktop-builds.yml -f orbs_yes=<date>`). Inputs:

| Input | Default | What it does |
|---|---|---|
| `orbs_yes` | none, required | The date (YYYY-MM-DD) of Orb's yes naming desktop test builds. The first step refuses a run without a date. |
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

In Tools' paths: `.github/workflows/desktop-builds.yml` (new), `.github/actions/setup-godot/action.yml` (a new `desktop-templates` input: the same pinned `.tpz` and SHA-512, unpacking only the Windows, Linux and macOS release templates), `tools/desktop-package.mjs` and `tools/desktop-package-selftest.mjs` (new, in CI's data job), this page. `linux-export.yml` stays as it is: the cheap Linux-only run for the Deck work.

Outside them, parked as `docs/tools/pending/desktop-builds/export-presets-macos.patch` for the EP to apply: `export_presets.cfg` gets (a) a fourth preset, **macOS** (universal, bundle id `io.github.dixonbalsagna.orbcombatex` and app name "Orb Combat EX", RL-205; ad-hoc signing, no notarization), and (b) `net/*` at the front of the **exclude filter of the Windows, Linux and macOS presets** (not the Web preset, so the demo's export and the flash-set rule are unchanged: RL-197). The workflow's routes check fails without (b).

**project.godot is not touched.** Godot refuses a universal or arm64 macOS export unless `textures/vram_compression/import_etc2_astc` is on, and `project.godot` is a FULL flash-set trigger (RL-128). The workflow sets that one line in its own checkout (`desktop-package.mjs astc`, before the import). The game imports no textures. To export the macOS preset by hand, switch the same setting on in a scratch copy, not in the tree.

The Windows exe has Godot's default icon and no file-version fields (`modify_resources=false`: `rcedit` is a Windows tool).

## To do next (needs people)

- Orb's yes, in one sentence naming desktop test builds (RL-203); then the EP dispatches with `orbs_yes`.
- A Windows PC and a Mac that did not build it: open each, get past the warning with the README's steps, reach the first screen. Until then those two builds are structure-checked only.
- Legal: the bundle id and app name stay placeholders until the formal title search (RL-205).

## Running the tree-editing commands by hand

`desktop-package.mjs lock`, `astc` and the text commands edit the tree they are given, so `lock` and `astc` refuse a **working checkout** (a `.git` in the root, a folder or a linked worktree's file) outside CI. An export without `.git` (`git archive HEAD | tar -x -C <dir>`) is a scratch tree wherever the script is run from, even with its own copy of the script inside it: `node <dir>/tools/desktop-package.mjs lock --root <dir>`. Before 2026-10-28 evening the guard compared the root with the folder the script lives in, which refused exactly that case.
