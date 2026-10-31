# The private preview: the new planet, playable in Orb's own browser (Tools, 2026-10-30)

Owner: Tools and Pipeline. Asked by the EP for Orb's push of 2026-10-30 ("get the new planet ready for Orb to play"). **Private and local: nothing is published, uploaded or dispatched, the live pin and `tools/site.json` are not touched, and no work in progress goes on a public page.**

```
node tools/preview/preview.mjs                     build main with every new-planet switch on, check it, serve it on 127.0.0.1:8765, print the URL
node tools/preview/preview.mjs --off water,floor   the same with those switches off (to compare); "--off all" is the plain build
node tools/preview/preview.mjs --list              the switches and what each does
node tools/preview/preview.mjs --check             do the switch table and the scratch patch still fit this tree? (no Godot, no browser, writes nothing)
node tools/preview/preview.mjs --overlay sim/input,data/input,docs/controls/pending/right-hand --open
                                                   the same with the right-hand work of the WORKING tree (not committed yet) laid over main, and the page opened in your default browser
```

Other flags: `--planet 7` (the planet's seed in the printed URL), `--port 8765` (a busy default falls on to the next; a port you name must be free), `--rev main`, `--no-smoke`, `--no-serve` (build and check, then exit), `--rebuild`, `--bisect`, `--godot <exe>` (else `$GODOT`, else the usual 4.7.2 install), `--out <folder>`.

Open the printed URL in Opera. To compare, run the command a second time in another terminal with `--off <switch>` and `--port 8766`, and open both.

## What it does

1. Unpacks the **committed** tree of `--rev` (default `main`) into a scratch folder under the temp folder (`meridian-preview/<commit>-<switches>-<patch>/`). Uncommitted work in the checkout is not in it.
2. Turns the switches on **there only**, by editing the data files' text (the one value, the rest of the file as it was):

| id | file and key | what it is | needs |
| :--- | :--- | :--- | :--- |
| `gen2` | `data/biomes/climate.json` `gen` 1 → 2 | planet generation 2 for every planet match | |
| `biome` | `data/combat/launch_biome.json` `biome.enabled` | the launch planner reads the ground | |
| `water` | `data/biomes/water.json` `enabled` | water v2 | |
| `surface` | `data/biomes/water.json` `surface.enabled` | surfacing, world half | |
| `interrupts` | `data/director/interrupts.json` `water.enabled` | surfacing, director half | |
| `floor` | `data/biomes/water.json` `floor.enabled` | the lake floor | `surface` and `interrupts` |
| `turn` | `data/biomes/rings.json` `turn.on` 0 → 1 | the arena's calm turn: the ring swaps for a new one, turned a few degrees | |

   `turn` (the EP, 2026-10-30; `--off turn` for the plain ring) is on by default so the ring turn can be seen in play. A turn needs a **planet match** (the preview's `?planet=` start), **60 s of match time since the last turn** (`turn.gapSeconds`), and **a calm moment after a launch has landed** (both fighters down or set, nothing moving); a match turns at most 4 times, each by at most about 10 degrees. So the smoke check (20 s of keys) does not wait for one: it checks that the running game reads the switch as asked and prints the match's turn count (`turns` in the probe, -1 when the match cannot turn). To see a turn, play a planet match for a minute or two and land a launch.

   `floor` needs both halves of the surfacing rule or the game's own load check (`WorldFill.floorProblem`) refuses it, so `--off surface` or `--off interrupts` turns the floor off with it, and the report says so. Rivers and B plates (`rivers.json`, `land.json` `b.enabled`) are **not** in the set: the EP's list did not name them, and World's readiness note holds them for Orb's look. They are two more rows in `tools/preview/switches.mjs` if wanted.
3. **Scratch code, two small patches to `render/core/main.gd` of the scratch copy** (`tools/preview/switches.mjs`, `patchMain`): a **`?planet=N` entry**, because the shipped game builds a generated planet only when a match's setup names one and neither the start menu nor the URL does yet (so `gen` alone changes nothing a player sees: a normal start plays the hand-made world); and a **`?preview=1` probe** that publishes `window.__preview` (tick, planet generation, what each switch reads as in the running game, hit points, the water loader's errors) twice a second for the smoke check. The printed URL carries `?planet=N`; without it Orb plays the hand-made world, where only the biome and water switches act. Each patch anchor must be found exactly once, or the build stops and says which line changed.
4. Imports and exports the Web build with the **standard** export template, single Godot process, at below-normal priority, 25-minute limit each. The custom template and its pin are not involved.
5. Runs the **boot-and-play smoke check** (`tools/preview/smoke.mjs`) through the guarded browser launcher of `tools/machine/browser.mjs` (time limit, below-normal priority, CPU cap, profile folder `cap-tools-preview-…`): the build boots; the check clicks through the first-run How to play card and the start menu ("I understand, start") as a new player would, then sends keys for 20 s; it raises no script exception or console error, the match's tick runs on, a canvas is drawn, and **every switch reads in the running game as it was asked** (a switch that reads off when it was turned on is a failure). A failure names the switch the evidence points at; `--bisect` then builds and checks each switch alone.
6. Serves the folder on **127.0.0.1 only**, no cache, until Ctrl-C.

A build is cached by commit, switches and patch: the same command again serves at once and prints the smoke result recorded with the build. `--rebuild` builds again.

Time on this PC (below-normal priority, other sessions running): about 45 s to import and export, about a minute and a half for the smoke check, a cached build serves at once. The first start in the browser shows the game's own flashing-effects notice and the How to play card, as any fresh visitor sees them.

## What it does not do

- It does not start a browser for Orb; it prints the URL.
- It does not prove the look. The smoke check proves the game boots, plays and has the switches on; Orb's eyes judge the planet.
- A planet match on gen 2 builds its planet in one synchronous call at match start (World's readiness note: about 1.1 s native, more in a browser), so the start may pause longer than the hand-made world's.
- The preview is not the public build: nothing here goes through the site job, the release pass or the flash check, and the build must never be copied to a public page.

## Tests

`node tools/preview/preview-selftest.mjs [--require-browser]` (CI, the qa job): the edit of each switch on fixture files shaped like the real ones, the cascade, the patch (LF and CRLF, a missing or doubled anchor), the whole build against a throwaway repository with a stand-in for Godot (**the repository comes out untouched**, `tools/site.json` byte for byte, the scratch tree flipped and patched, `--off` building elsewhere, a failed export showing its log), the local server (127.0.0.1 only, no path out of the folder), and the smoke check on tiny pages (passes a page that reads as asked, fails one whose water reads off and names `water`, fails a page that never publishes). `--check` is the real-tree twin: run it after any change to those data files or to `render/core/main.gd`.

## The right hand, and switches that are not in the tree yet (the EP, 2026-10-31: Orb's night order, "a working version with the 3d world and our new controller mapping folded in")

- **`rightStick`** is the eighth switch: `data/input/timing.json` `switches.rightStick` false to true (Controls' pitch 4a: the right stick throws directional-charge strikes, the left hand braces and slips). It needs two things in the tree you build: Controls' code and data (`sim/input/`, `data/input/`), and **the pad's right stick read by `render/core/main.gd`**, which is Controls' `right-hand-host.patch` until Rendering lands it. The preview applies that patch to the SCRATCH copy of main.gd when the tree has not got the change (`docs/controls/pending/right-hand/right-hand-host.patch` in the tree you build or overlay); with neither the change nor the patch the switch WAITS and says why, and the build is made without it. The probe (`?preview=1`) reads `SimInputData.right_stick_on()` and the smoke check expects it as asked.
- **A switch that waits is never a pass.** A switch whose key is not in the tree you build (the file is missing, or the key) is listed as `WAITING, not in this build` in the report, `--list` and `--check`, is not on, and is not counted as checked. A key that is there with a value the table does not know is an error, as before. `tools/preview/switches-pending.json` holds names that wait for a key: **gen3, tiles and swing** (named by the EP, 2026-10-31; owners World and Rendering). A row with no `file` is a name only. When the owner lands the key, give the row `file`, `path`, `from` and `to` (and `needs`, `probe`): it becomes a switch, on by default, `--off`-able and checked.
- **`--overlay <paths>`** (comma-separated, relative to the repository root, existing) copies those paths of the WORKING tree over the scratch copy: for work that is not committed yet (Controls' right hand before it lands). The report says `OVERLAY: ... uncommitted`, `build_info.json` lists the paths, and the cache key holds a hash of their contents (a change to a file builds again). It reads files as they are on disk, so mid-edit work builds mid-edit.
- **`--open`** opens the printed address in the default browser once it is served (Windows `start`); without it nothing opens.
- **What the right hand does in the game today** (Controls' README, `docs/controls/pending/right-hand/README.md`): the input layer is built (the stick, the strike reader, the left hand's brace and vanish, the swapped layouts, the D-pad mirror), but the **simulation and the director do not read the intent's second word yet** (`SimIntent.pack2`, `rsStart`, `rsRelease`, `rsLevel`, `rsDir`), nothing outside `sim/input/` uses them, and the settings screen has no rows for it. With the switch on the right stick is read and shapes the intent, and **the fight does not change** until Simulation and Encounter consume it. The preview turns the switch on honestly; it cannot make the fight use it.
- `--check` now says what it did NOT check: what waits, and that an overlay is uncommitted work.
- Self-test: `node tools/preview/preview-selftest.mjs` (96 checks).
