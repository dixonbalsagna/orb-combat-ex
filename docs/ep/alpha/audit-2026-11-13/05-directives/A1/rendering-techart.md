# A1: Rendering & Technical Art Director

Leads: A-RENDER-01, A-RENDER-04, A-PERF-08
Supports: A-MODES-01, A-MODES-06, A-MODES-11, A-UI-01, A-CAMERA-01, A-WORLD-01, A-CODE-03, A-UI-02, A-RENDER-07

Draft for the Executive Producer (EP) to send once Orb approves the path to Alpha. Nothing here is decided until then.

Goal: A build made plainly from main, started with no special words, shows the game Orb plays (the globe ground, the craters without the black fill, the meteor trail) and opens in a proper window on Windows and Linux.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A1, decisions 3 and 4); `docs/ep/alpha/audit-2026-11-13/02-areas/RENDER.md` and `PERF.md`; `docs/decisions/0010-look-gate.md`; `docs/ep/taste.md`; `docs/rendering/pending/crater-look-default/README.md`; `docs/tools/steam-deck.md`.
- A-RENDER-01: the look Orb plays is switched on only by launch words; on main the default is the older ground, so a plain export shows a different game. Evidence: `render/core/main.gd:243-251` and `:259` (the crater look; line 256 is the tile share); `render/core/tile_ground.gd:14`; `render/vfx/vfx_look.gd:177`; also `docs/tools/runs/6a30b4c9/switch-list.txt:32-36`, `:83` and `net/tools/lan_kit.mjs:127` (the LAN kit passes `--tiles=1` alone).
- A-RENDER-04: the black, flat-brown crater has a still and a proven cause (a beam's scorch filled per vertex on coarse tiles); the fix is on only by a launch word, is parked (finished work waiting outside main), and raises the collapse flash reading from 3 to 4. Evidence: `docs/rendering/runs/1931a0f8/terrain-step0-a.txt:26`; `docs/tools/runs/1931a0f8/terrain-step0-stills.md:12`; `docs/rendering/pending/crater-look-default/README.md:3`, `:41`; also `docs/ep/vision.md:1695` (Orb: "workshop this, and improve the system").
- A-PERF-08: the game sets no window: no display section in the project file and no fullscreen, resolution, vertical-sync or frame-cap setting in code or in the options. Evidence: `project.godot:6-19`; `ui/data/settings.json:54`; `docs/tools/steam-deck.md:15`. A change to the project file triggers the full flashing check set (`.github/workflows/desktop-builds.yml:83-84`).
- Supports: UI's rows need lines in `render/core/main.gd` (routing at 1337-1348, the Escape quit at 1596-1598, the clock while paused at 811 and 1326). Camera's defaults switch on in the same block (243-252). World's planet reaches the match at 441-449 and 1644. A-RENDER-07 (EP leads): no record ties a visible landing to its side-by-side.

You own: `render/core/`, `render/shaders/`, `docs/rendering/`.
- ask under NEEDS FROM EP for a grant: `project.godot` (the display section)
- ask under NEEDS FROM EP for a grant: `render/vfx/vfx_look.gd` (VFX's path: the crater look's default at line 177)
- ask under NEEDS FROM EP for a grant: `ui/data/settings.json` (UI's path; or the EP routes the options row to UI)
- The launch words used by Tools' build and LAN kits (`tools/`, `net/tools/`) are Tools' and Netcode's to remove once the defaults are in: list them under NEEDS FROM EP.

Acceptance criteria:
1. (A-RENDER-01, X-13, X-29) Before anything lands, the whole render gate set runs on a scratch tree with the globe ground as the default; every check that fails because it only ever saw the old ground is listed with its owner. Result saved under `docs/rendering/runs/<sha>/`.
2. (A-RENDER-01) If Orb says yes to decision 3: a plain start with no launch word shows the globe ground and the meteor trail; the old ground is kept only behind a test word; the launch words are gone from the build tool's table and the LAN kit. Checked by starting the first desktop build with no arguments and comparing stills, at the same ticks of the same replay, with the browser build Orb played.
3. (A-RENDER-04, X-13) The crater look with the black fill removed is the default, as the parked work has it and no wider: the terrain and impact workshop Orb asked for on 2026-11-09 is scoped apart and is not started here. A still of the same crater before and after is saved.
4. (A-RENDER-04, safety) The flashing checks run in both modes (normal and reduced) on the new default and the readings are saved under `docs/rendering/runs/<sha>/`. The parked work's own record shows the collapse reading rising from 3 to 4: a reading over the limit is reported under RISKS for the EP to route, and the default look is not degraded to move a number (ADR 0010, point 3).
5. (Look gate, ADR 0010) Items 2 and 3 each ship with a side-by-side against the reference build (`node tools/flash/side-by-side.mjs`; stills plus a short GIF) and against the 9 November build, before the EP commits. The reference today is the one in `docs/ep/taste.md`; the path asks Orb (decision 4) to name the 9 November globe build, with its known picture faults listed as not part of it. Your report names which build each picture was compared with.
6. (A-PERF-08, X-19, X-22, X-24) The project file has a display section: the game starts in a stated window mode and size on Windows and on Linux, and fills a 1280 by 800 screen. Vertical sync and a frame cap are each either a setting with a default or a stated fixed choice. One options row exposes what a player may change (UI builds the row). The project-file change is planned with the EP so the full flashing check set it triggers runs once; its result is saved.
7. (Supports) UI's and World's lines in `render/core/main.gd` are granted or made by you within a day of the ask, one owner at a time. A-CAMERA-01: the camera block switches on by default with the ground. A-CODE-03 and A-UI-02: the planet entry and the report and replay hook Tools moves onto main sit in the main scene with no preview patch. A-RENDER-07: every visible landing of yours names its side-by-side file in the report.
8. Nothing in this brief adds a full-screen pass, a frame copy or a read-back from the GPU. If one is needed, Performance's timing comes first (ADR 0010, point 5).

Constraints:
- Tokens: about 2.65M as an estimate (two rows of size M at 1.2M, one of size S at 0.25M).
- State hash: none of this changes the sim's state fingerprint. Rendering reads sim state and never writes it.
- Machine: headless Godot only (pictures come from the web build in headless Chrome, only through Tools' launcher, one software-rendered capture at a time, each with a time limit); at most 3 Godot processes for a short gate; long runs at below-normal priority; a measurement taken while the machine was saturated is marked invalid; check nothing you started is still running before you end a turn.
- Engine: the Compatibility renderer is the baseline; GDScript only.
- Determinism and data: numbers live in data; a data shape change updates its schema in the same commit.
- Originality: nothing from an existing franchise.
- Orb's rules: nothing drawn on, over or between the fighters; no dissolves, fades, slow wipes or full-screen blur; no presentation effect that drops the frame rate; plain words. Nothing about flashing readings goes to Orb from you: it goes to the EP.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Before this starts: Orb's yes to decisions 1, 3 and 4; the working tree committed or deliberately ignored (A-PROCESS-03); the played build's patches on main (A-CODE-03). Item 1 (the scratch gate run) starts on day one. In step 4 of A1's order the look lands after the round planet (A-WORLD-01) and the camera (A-CAMERA-01). Waiting on this: A-CODE-01; the first desktop build and its still comparison (A-TOOLS-01); Performance's first frame record and loading times; the flashing measurements on the globe ground, briefed on day one for A2 (A-LEGAL-01, Camera's row, with you).
