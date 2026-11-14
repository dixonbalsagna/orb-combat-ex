# Netcode, sprint A1 wave 2 (2026-11-14)

This covers the brief `docs/ep/alpha/audit-2026-11-13/05-directives/A1/netcode-online.md`. Item 1 (A-NET-05) is the park `docs/net/pending/lan-stamp/`. This page holds items 2 to 5. Orb answered decisions 2 and 5 on 2026-11-13: "Go with recommendation on all" (`docs/ep/vision.md`).

## 2. Flight speed on LAN (A-CONTROLS-04)

**Where LAN takes the speed from:** `data/fight/power.json`, `flight.flatOut`. NetLan's setups carry no `"flatOut"`, so `SimPower` sets `S.powerFlat` from the data on both PCs (`sim/core/power.gd:119`). Both PCs run the same folder, so they read the same file.
- Orb's 3,500 came from the page's slider, which is a setup word (`"flatOut"`) that LAN never had. That's why LAN played 5,000.
- Decision 5 makes 3,500 the data's default in every mode and drops the slider. Once that data change lands (Game Design, GW1), LAN plays 3,500 on both PCs with nothing typed, and nothing changes in `net/`.
- The LAN setup doesn't need to carry the speed, so no setup or message changes. NetLan's setups are constants in the game on both PCs, not a message; the hello carries only their key.
- A later LAN folder built from that data plays it. `lan_check`'s setup row reads the model, the dash, the slip and the travel; it will read the speed too when the data lands.

## 3. The planet on LAN (A-WORLD-14)

Decision 2 is a random planet each quick match, with a fixed one for a newcomer's first match and for tests.
- **Through A1:** LAN keeps planet 7 (`NetLan.SETUP`). It's a test match between Orb's two PCs, and decision 2 keeps a fixed planet for tests. Nothing is built.
- **In A3, with LAN inside the game (A-NET-02):** the host draws the planet's seed and sends it in the hello. The joiner adopts it, so both PCs build the same planet, and the seed is shown and saved in the report as it is in the solo quick match.
- **What it takes:** one field in the hello and the joiner adopting it (PROTO 5 to 6); the match key built from the agreed setup; `lan_check` rows for both PCs on the host's seed, with a control where the joiner keeps its own. The saved file already carries the setup in its replay, so the report and its replay follow with no change.
- **Cost:** about 0.1M tokens, no sim change and no change to the state fingerprint. A planet generated at match start also adds its build time to the join, which World's planet work measures.

## 4. Orb's first real LAN save through the report tool (A-SAVES-01), steps for QA

There is no real LAN save yet: `saved\` in `orb-lan-6a30b4c9` and `orb-lan-6eec6a75` holds only its note. When Orb and Orb 2 play the LAN round:
1. With the game closed on both PCs, Orb 2's `saved\` files and `lan-log-old.txt` are copied onto the main PC (a USB stick), into the LAN folder or Downloads.
2. On the main PC, Orb double-clicks `Make my report folder.cmd` in the LAN folder. It gathers the newest 12 hours of files and films a clip of each report (Tools' `lan-report.mjs`; `docs/tools/lan-report.md`). The folder lands in `homework/Files/reports/orb-lan-report-*`.
3. QA checks every saved file against **the LAN folder's own tree/**, never main or a newer build:
   `node tools/preview/blackbox-verify.mjs <lan-....json> --tree "homework/Files/builds/orb-lan-6a30b4c9/tree"`.
   Files from `orb-lan-6a30b4c9` carry no build id, because they were made before A-NET-05. They play on that tree, but a stamped build refuses them as another build's, which is how it should be.
4. QA reads the saves themselves: the two PCs' files should hold the same inputs; `marks` gives the ticks Orb reported; `frames.slow` against `frames.rollbacks`, and `net` (delay, rollbacks, deepest, checks matched), show any stutter.
5. QA sends the EP the report folder's path and the verify lines. I read them together with both PCs' `lan-log` files and report.

**Where the raw files stay (Legal RL-267).** Orb and Orb 2's saves, logs and clips stay where they land, in git-ignored `homework/`, and are read in place. An outside tester's raw files would live only in git-ignored `.private/testers/`; LAN is Orb and Orb 2 only for Alpha. None of them is copied into a tracked `docs/*/runs/` folder, a session's scratchpad, a brief or a report. What gets committed is a summary with no names and no paths: verdicts, tick counts, rollback and frame figures.

## 5. The Windows desktop build and net/ (A-TOOLS-01), a paragraph for Tools

The solo game needs nothing from `net/`. No packed script outside `net/` loads anything from `res://net` or uses a network class; the only mentions are comments in `sim/core/cross.gd`, `sim.gd` and `stage.gd`. Saved matches, replays and "report this" are the sim's and UI's (`sim/core/replay.gd`, the black box in `sim_host.gd`). So the Windows Desktop preset keeps `net/*` in its `exclude_filter` (as Linux and macOS do today), and the packager's check stays as it is: a preset that packs `net/` is refused, which is right (RL-204, condition 1: the privacy line holds only while the game makes no network connection).
- **What the package leaves out:** all of `net/`: the session, the ENet and loopback transports, the handshake, NetLan and its checks.
- **The one thing that packs `net/`:** the private LAN kit (`net/tools/lan_kit.mjs`). It edits only its own scratch copy's `export_presets.cfg`, never main's, and its folder isn't a public build.
- **When LAN comes into the game in A3 (A-NET-02):** that needs Legal's new privacy line before any preset packs `net/`. Until then, a refusal from the packager is an answer to keep, not to work around.
- **Not a desktop matter, for Tools to know:** the Web preset doesn't exclude `net/*`, so the private page packs `net/`, its checks included (26 files under `net/tools`).
