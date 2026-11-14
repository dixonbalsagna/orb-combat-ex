# A2: Tools & Pipeline

Leads: A-LEGAL-06, A-LEGAL-08, A-MARKET-01, A-MARKET-02, A-MARKET-03, A-MARKET-04, A-MARKET-07, A-TOOLS-02, A-TOOLS-03, A-TOOLS-04, A-TOOLS-05
Supports: A-LEGAL-01, A-LEGAL-03, A-LEGAL-12, A-TOOLS-06, A-QA-02, A-PERF-01, A-PERF-03, A-UI-10

Goal: A friend with a Steam Deck can get the build from a private itch.io page with a key, save a small report with one press, find a file that says why if the game died, and be put back on the previous build in one step; and every milestone's build leaves the same fixed set of shots behind in an archive.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A2), `02-areas/TOOLS.md`, `02-areas/MARKET.md`, `02-areas/LEGAL.md` (the gate list G1 to G20 under Q1), `02-areas/web-checks.md` (itch.io table; Discord's upload limit), `docs/tools/lan-report.md`, `docs/tools/clips.md`, `docs/legal/alpha-discord-flags.md`, `docs/decisions/0010-look-gate.md`.
- A-TOOLS-02: nothing for itch.io exists (no page set-up note, key procedure, channel names, upload script or rehearsal record). Evidence: a search of tools, .github, net and docs/tools for the site's name or its upload tool finds nothing; `.github/workflows/desktop-builds.yml:163, :171, :179` (a game binary is only ever uploaded as a one-day CI file).
- A-TOOLS-03: no rollback procedure or release checklist. Evidence: every "rollback" hit in tools, .github, docs/tools and the playbook is about netcode or flash data; `docs/ep/playbook.md:19-21`.
- A-TOOLS-04: nothing captures a crash or a hang. Evidence: `project.godot:1-26` (no logging section); `net/lan.gd:287, :389, :485` (saves on pause, match end and a pressed report only); `tools/preview/lan-report.mjs:7, :28`.
- A-TOOLS-05: the one-press report folder works only on Orb's PC, has no size cap and has never been made from a real LAN save. Evidence: `tools/preview/lan-report.mjs:4`, `:83`; `.gitignore:36-37`; `net/tools/lan_kit.mjs:28`.
- A-LEGAL-06: no check that report files hold no account names or file paths. Evidence: `docs/legal/alpha-discord-flags.md:6`; `tools/preview/lan-report.mjs:1`; `net/lan.gd:520`. A path scrub already exists for clip records (`tools/preview/lan-clip.mjs:24`, `blackbox-clip.mjs:33`): reuse it.
- A-LEGAL-08: the repairs to the flash measuring chain (corrective item CD-09) have no commit. Evidence: `docs/ep/corrective-plan-2026-11-07.md:17`; `tools/flash/release-pass.json:4`; `.github/workflows/player-watch.yml:9`; `audit/2026-11-07/corrective-directive.md:23`.
- A-MARKET-01: no fixed shot list; the recipe file covers three of six named shots. Evidence: `tools/clips/clips.json:57`, `:61`, `:66`.
- A-MARKET-02: no job renders the shots at a milestone and no archive exists. Evidence: `tools/clips/make.mjs:10`; `.gitignore:28-29`; no changelog file is tracked.
- A-MARKET-03: the capture hook exists only in a browser build, and the LAN replay route's self-test is in no workflow. Evidence: `render/core/main.gd:299`; `tools/preview/lan-clip.mjs:1-6`; no workflow line names lan-clip-selftest.
- A-MARKET-04: only GIFs get the flash check; WebM and PNG sequences leave with no verdict. Evidence: `tools/clips/make.mjs:251`, `:277`, `:345`; `docs/tools/clips.md:43`.
- A-MARKET-07: no rule for a shot whose old replay stops playing. Evidence: `sim/core/replay.gd:7`, `:135`; `tools/preview/switches.mjs:538-545`.

You own: `tools/`, `build/`, `.github/`.
- ask under NEEDS FROM EP for a grant: `docs/tools/` (the checklists, the itch.io note and every saved record under `docs/tools/runs/<sha>/`)
- ask under NEEDS FROM EP for a grant: `project.godot` (a log file per run, for A-TOOLS-04)
- ask under NEEDS FROM EP for a grant: `net/lan.gd` (a last-moments file and a report save that needs no outside program) or have Netcode make that change through the EP
- ask under NEEDS FROM EP for a grant: `render/core/main.gd` (the crash and hang hooks; a capture hook for desktop programs) and `render/tools/` (the shot recipes' staged scenes)
- ask under NEEDS FROM EP for a grant: `ui/` (the Save report row) or have UI make it through the EP

Acceptance criteria:
1. (A-LEGAL-08) The analyser's counting flaw named in CD-09 is fixed, its self-test fails on the old code and passes on the new, the self-test runs in CI, and a flash reading runs on a schedule against main. Record: commits, the CI run id and the first scheduled reading under `docs/tools/runs/<sha>/`. This lands first: Camera's readings (A-LEGAL-01) rest on it.
2. (A-LEGAL-08, supports A-LEGAL-01) The standard clips can be run with the globe ground switched on, in normal and reduced modes, by one command; `tools/flash/release-pass.json` is written for the commit read.
3. (A-TOOLS-04) A forced crash and a forced hang, on Windows and on Linux, each leave a file saying why; the report picks it up. Check: a forced-crash test per platform in CI, output saved. The cost of the per-run file is measured in the bench before it lands.
4. (A-TOOLS-05) One press in any build, on Windows and Linux, saves one report file under 10 MB with no outside program and no path to this repository; nothing is sent automatically; clips are separate. Check: a test that makes the report on both platforms and reads its size; a made-from-a-real-LAN-save run saved under `docs/tools/runs/<sha>/`.
5. (A-LEGAL-06) A scan refuses a report or a packaged file that holds an account name or a personal file path; it runs on every package and on the report in criterion 4. Record: the scan's output under `docs/tools/runs/<sha>/`, and Legal's row.
6. (A-TOOLS-02) A page set-up checklist Orb can follow in one sitting, a key procedure (one key per named friend), a Windows and a Linux channel name, and an upload script. Rehearsal record: a dummy build pushed to both channels, a key claimed, an update applied. The account, the page and the upload tool's install are Orb's actions; no key or token is written into any file.
7. (A-TOOLS-03) A release checklist and a one-step rollback, rehearsed on the dummy build, including a settings file written by the newer build being read by the older. Record under `docs/tools/runs/<sha>/`.
8. (A-MARKET-01) The shot list is one data file naming all six shots, each marked "played" or "staged"; recipes exist for a transformation and a lap of the globe; the LAN 2v2 shot is listed with what it waits on (LAN inside the game, a later milestone).
9. (A-MARKET-02, A-MARKET-07) One job renders the list from a named build into an archive folder named by milestone, with a one-line "what changed" and a tracked changelog entry; the first entry is made from the A1 and A2 builds. A written rule: shots are built from recipes, not saved replays; a replay-based shot is re-recorded or retired when the data changes.
10. (A-MARKET-03) The shots can be filmed from the Windows and Linux desktop programs, not only the browser build; the LAN clip self-test runs in a workflow. Any capture hook is absent from, or locked off in, a tester's package (the package check proves it).
11. (A-MARKET-04) WebM and PNG-sequence outputs get the same flash verdict as GIFs or are refused; `docs/tools/clips.md` says how a clip is screened before anyone outside sees it.
12. Nothing here changes what a player sees in a match. The Save report row and any crash notice do: each ships with a side-by-side against the reference build (the look gate, ADR 0010; `node tools/flash/side-by-side.mjs`) before it is committed.

Constraints:
- Tokens: about 8.4M as an estimate (six M rows and five S rows at the size classes).
- State hash: no change. A2 has no golden window (a landing that re-records the reference matches); if any fix turns out to move the hash, stop and report.
- Machine: headless Godot only; at most 3 Godot processes for a short gate; anything over about ten minutes at below-normal priority; browser captures only through your own guarded launcher, one at a time, checked before the turn ends.
- Determinism: the crash and report code reads sim state and never writes it; no rendering state in the sim; numbers in data, and a data shape change updates its schema in `tools/schemas/` in the same commit.
- Originality: nothing copied from any existing game or tool's assets.
- Orb's rules: nothing drawn on, over or between the fighters; no dissolves or fades; plain words in every tester-facing line, and Orb sees those lines before use; the AI disclosure is on the itch.io page and in the package; in-progress character art is never public (the archive stays private); no personal path, account name or address in any packaged file.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: A-TOOLS-01 (the one-command desktop build), A-LEGAL-09 (Legal's ruling on a page under the working title) and A-UI-02 must have landed in A1. Inside this brief: criterion 1 first (Camera, Rendering and VFX wait on it); then 3, 4 and 5 (QA's soak, Performance's bench and the Deck session wait on them); the rehearsal (6, 7) waits on Orb's account actions and on Legal's re-cut package rules (A-TOOLS-06); the shot list (8 to 11) runs beside all of it with Community & Marketing's wording through the EP.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- Criteria 1 and 2 (the repair of the flash measuring chain, A-LEGAL-08) are sent on day one of A1 and do not wait on A1's landings. (ORD-06)
- Once a desktop capture exists, run the clip analyser on the Linux desktop build's own frames for the standard clips, at 1280 by 800 and at the Deck's default picture level; until then gate G4's record says which build it was read on. (PC-05)
- The package step may build and check a tester package with no approval file; the approval is checked at the upload step. (PC-04)
- The forced-crash test lives in CI and in Orb's own unlocked copy, never as a hidden row in a tester's package. The update-and-roll-back rehearsal uses a dummy channel no tester's key can see. Every upload to itch.io is Orb's own action, listed on Orb's page for this milestone; no session uses Orb's sign-in, so "or the EP" does not apply. (PC-08) (PC-12, PC-01)
