# The interim playable site (Orb's word 2026-10-14; Legal's ruling RL-136, seven days)

Owner: Tools and Pipeline. For the EP, Legal and UI. Built the night of 2026-10-14; **not applied**: `tools/site.json` still says `"offline": true, "interim": null`.

## What it is

Legal's ruling RL-136 (`docs/legal/photosensitivity-note.md`, addendum 8): the playable build returns for seven days behind a click-through, with the finding stated, Reduce flashing on by default, no promotion, and three conditions waived and recorded. The full-set release path is unchanged and is the only way to a site without a time limit.

| Page | What it is |
|---|---|
| `/play/` | The Godot export, noindex, with the engine's start wrapped in `window.__startGame` and called once, from the gate's button. The gate (Legal's words, verbatim, `tools/site-interim.json`) is the first thing in the body, fits a phone, and nothing but the loader script downloads before the click. **"Not now"** is a link to `../`, the holding page. |
| `/`, `/bench/`, `/band/`, `/404.html` | The holding page, exactly the plain notice of `tools/site-notice.json` (no script, no link, no game, noindex). **This is where "Not now" goes: its URL is the site root; from the game at `/play/` it is `../`** (UI: `JavaScriptBridge.eval("window.location.href = new URL('../', window.location.href).href")`, so it works under the Pages project path). |
| `/about/` | How the game was made (Legal's AI line), privacy (the target-none line), the flashing-effects finding, Godot's MIT line and Open Sans' OFL line, then the engine's own full licence and copyright texts: Godot's MIT text, OFL-1.1 and the roughly 100 components the engine lists, written from the engine itself by `tools/site_licences.gd` into `tools/site-licences.json` (run again when the engine version changes). Reached from the gate's "Licences, notices and privacy". |

Nothing links to `/play/` from the holding page or from any page of ours except the About page's "I understand, start: the game's first screen" link, which leads to the gate, not past it.

## One command to take it down (tested)

```
node tools/site-offline.mjs
```
Sets `"offline": true`, `"approved": null` and `"interim": null` in `tools/site.json`; the next build is the holding page and nothing else (the interim self-test runs this command, builds the result and passes `tools/check-site-offline.mjs`). `--check` only reports the state. Then commit and push `tools/site.json`.

## To switch it on (the EP's word)

1. Frozen commit: `bash tools/flash/interim-run.sh <commit> <from date> <expires date>` (below) records the pass and builds and checks the interim site locally.
2. `tools/site.json`: `"offline": false`, `"approved": "<date of Orb's word>"`, and
   `"interim": {"legal": "RL-136", "approved": "<date>", "expires": "<date>", "notice": "site-interim.json"}`; the dates are the same as the ones the run recorded (the build and CI refuse a mismatch).
3. Prefs: Reduce flashing on by default (UI), below.

## The measured commit and the pass file

`tools/flash/interim-run.sh` exports the commit's web build in a scratch tree, captures all 28 clips (both modes) through the guarded launcher, captures the second captures, reads the margins and **records the pass with the interim** in `tools/flash/release-pass.json`: the commit's four hashes (so the published build is the measured commit: a later commit that changes anything the player runs makes the record stale and the build refuses), every row with its real verdict (the failing ones stay in the file), the capture conditions, the HUD line (2.0 Hz, the largest `UiLook.HZ_*`), the seeds, and an `interim` block: `{legal: RL-136, from, expires, waives: [whole-set-combined-rule, margin-rule-and-second-captures, ci-gate-on-the-full-set], standing: {pass, notPass, marginRuleNotMet, needSecondCapture}}`. The record stops holding the day after `expires` (`release-pass.mjs --verify`, the build, and CI). Starved or unrecorded captures, a missing clip, a changed hash, the dips cap, the HUD line and the seeds are not waived.

## The pinned deploy: main keeps moving, the demo does not

Orb wants the mechanics and the animation refined continuously, so main moves while the demo is up, and a record is stale for any commit that changes what the player runs. So when the site is online (an `interim`, or a full release pass) **its `/play/` is built from the commit the pass file recorded, not from HEAD** (`tools/site-pin.mjs`, the `site` job):

1. `node tools/site-pin.mjs` prints the recorded commit (`commit` in `tools/flash/release-pass.json`), or nothing when the site is offline. `tools/site.json` may also carry `"pin": "<sha>"`; if it does it must equal the record's (a mismatch fails the job), so the site's target is one visible value.
2. CI exports HEAD's Web build as it always did (a broken export still fails CI) and, when pinned, also `git archive`s the pinned commit into a scratch tree, imports and exports it the same way (`node tools/site-pin.mjs --export <dir>`; a shallow checkout fetches just that SHA), writing its own `build_info.json` (its short SHA and date).
3. `tools/build-site.mjs` builds the site from the pinned export with `--commit <pin>`, so the record is verified against the pinned commit's hashes (it holds) and not HEAD's (it would not); `check-site-interim.mjs` reads the shipped prefs and the feedback target from the pinned tree (`--root`), because those are what is published.

**What changes the published game:** recording a new run (`bash tools/flash/interim-run.sh <commit> <from> <expires>`, which writes the record for that commit) and committing the record (and `"pin"`, if used). A later game commit does neither: the site job stays green and `/play/` is byte-identical. `tools/site-pin-selftest.mjs` (14 checks, CI) proves that on a throwaway repository: a later game commit makes the recorded pass stale against the branch tip, holds against the pinned commit, and the pinned export is byte-identical to the first.

**What it does not do:** the rest of the site (the holding page, the About page, the gate and its words, the CI checks) is built from HEAD's tools, so a change to the words or the gate goes live with the next push; the game inside `/play/` does not. A new fix to the game goes up only with a new recorded run.

## The nightly seeds (Legal, RL-137): the take-down trigger, read every night

While the interim is up a few new AI seeds are captured each night against the **pinned** build, in both modes, reading **only the primary reading**; any clip over 3 on it is the take-down trigger (RL-136 item 3). It is run by us, not by CI, so it costs no minutes.

```
node tools/flash/nightly-seeds.mjs            # 8 new seeds, both modes, pinned commit, three at a time, one report line
```

- **The seeds**: the next 8 integers from 1000 that are in neither the recorded set (`tools/flash/sources.json`) nor the history (`tools/flash/nightly-seeds.json`, one row a night), so a seed is never read twice. Deterministic: the history is the only state. `--count`, `--base` change it.
- **The build**: the commit the pass file recorded (`tools/site-pin.mjs`), exported once into `<temp>/nightly-seeds/<sha7>/web` and reused each night (`$GODOT` must be set the first time).
- **The run**: `tools/flash/run-pixels.mjs --seeds ...` through the guarded launcher, below-normal priority, 25% of the cores, a time limit; about 16 captures at three jobs: **roughly 80 minutes**, plus 3 minutes for the first export. Nothing but the primary reading is read; the clips stay in `<temp>/nightly-seeds/<sha7>/<date>/clips` for `tools/flash/margins.mjs` if one is over.
- **The report line** (also in `<date>/report.txt` and the history): `nightly seeds 2026-10-16 on the pinned d3f1ca0e: seeds 1000,...,1007 x 2 modes, 16 of 16 clips read; largest primary 2.5 (ai-1003-normal); none over 3`. Exit 0 when none is over 3. **Exit 1 and the words `TAKE DOWN: <clip> reads <n>`** when one is; exit 2 when a clip was not read or the run failed (a missing clip is not a pass).
- **On exit 1**: `node tools/site-offline.mjs`, commit and push `tools/site.json`, tell the EP and Legal with the clip, its kind and owner (`margins.mjs` and a per-tick probe).

**Schedule (ours, by the machine):** once a night, started at 01:00, below-normal, so it finishes before 03:00 and before the morning's work. On this machine: `schtasks /Create /SC DAILY /ST 01:00 /TN "OrbCombat nightly seeds" /TR "cmd /c cd /d <repo> && set GODOT=<godot console exe> && node toolslash
ightly-seeds.mjs >> %TEMP%
ightly-seeds.log 2>&1"`. It reads the log's last line each morning. The seeds are not stable across sim changes, but the pinned commit does not change, so a seed read once keeps its reading. `tools/flash/nightly-selftest.mjs` (12 checks, CI) covers the pick, the line and the trigger.

## What CI checks (`tools/check-site-interim.mjs`, with `tools/site-interim-selftest.mjs`, 50 checks, and the interim cases of `tools/flash/release-pass-selftest.mjs`)

The check passes at once without an `interim` block. With one it fails on:
- **expiry** (`interim.expires` before today, UTC), a missing Legal id, date or expiry, the words still a draft, or the pass file not recording the same ruling, expiry and the three waivers;
- **autoplay**: the engine started anywhere but inside `window.__startGame`; `__startGame` called from anywhere but the gate's button; the gate missing, not before the canvas, or without a button; audio or video that autoplays;
- **a skip**: any page other than `/play/` with a script, iframe or meta refresh, a reference to the game's files, or a link that is not the gate, About or the holding page (a query, a fragment, a link away fail); `/`, `/bench/`, `/band/`, `/404.html` not exactly the holding page; any other `.html` in the site; "Not now" missing or not `../`;
- **noindex and no social card** on every page, `/play/` included;
- **the shipped defaults**: Reduce flashing not on by default in `ui/data/options.json`, not enabled in `ui/data/features.json`, or off in the literal of `ui/hud/ui_hud.gd`;
- **the words**: the gate lacking any sentence of Legal's, the button, "Not now", the small Reduce-flashing line or the AI line; About lacking the AI line, the privacy line **for the feedback target in use** (`ui/data/send.json` `_target`: today `none`; another target fails until Legal's matching variant is written in), the Godot or Open Sans line, or their licence texts; any of "safe", "seizure-safe", "tested for photosensitivity", "WCAG compliant", "certified", "no flashing";
- **the placeholder-name scan** (`tools/site-name-scan.mjs`): KAI, VORR, Meridian or Calamity on any page, or in a file of the game's pack that is not on the allowlist `tools/site-name-scan.json` (two files today, neither shown: a note string in `data/combat/recipes.json` and the JS parity oracle's frozen golden).

## Open at the time of writing

- **Reduce flashing is off today** in all three places above, so the check fails on the real tree: UI's change (one default and the feature flag).
- **The game has its own first-start notice** (UI's, the addendum 3 wording naming "Reduced motion"). With the gate there are two screens and two texts. Legal's words are in the gate; UI's menu notice should carry the same words (one string), and the gate can be dropped later by deleting the interim's wrapper, not before the game's own gate is shown to fail nothing.
- **The holding page's text** (`tools/site-notice.json`, RL-121) still says the playable build is offline and that scenes flash more often than the limit. With an interim live at `/play/` that sentence is true for visitors who do not know the address, and "Not now" returns a visitor to it. Legal may want it amended; it is one JSON file.
- **Feedback target**: `ui/data/send.json` `"_target": "none"`: COPY REPORT puts a plain-text report on the clipboard, SEND is hidden, nothing leaves the computer. The privacy line is for that target.
