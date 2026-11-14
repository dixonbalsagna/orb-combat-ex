# MARKET: marketing capture and distribution

Alpha audit 2026-11-13, baseline 8901d351 (game code of build 6a30b4c9). Read-only. Owners: Community & Marketing, Tools & Pipeline, Camera & Cinematography. Paths under `homework/` are local and git-ignored (`.gitignore:28-29`); they are cited as "(local)". No web was read in this session: platform rules are quoted from the project's notes and from the judgment session's `02-areas/web-checks.md` (read 2026-11-13), and each is marked **needs web check** where the notes are the only source.

## Summary

- **Works:** the capture side has real parts. One command makes seeded, repeatable clips from a kept build through the guarded browser launcher, one tick a picture, with the HUD hidden (`tools/clips/make.mjs:3-11`, `render/tools/flash_capture.gd:180`); six clips made on 2026-11-10 are on record with a flash verdict each (`docs/tools/runs/mms-2026-11-10/screen-results.txt`).
- **Does not exist:** the archive and the distribution. No fixed shot list, no per-milestone render job, no archive folder, no backup; nothing for itch.io at all (no page, keys, channels, upload script, rehearsal or tester guide); no Steam timeline in the project's own pages.
- **Biggest gap:** F-MARKET-01. X-31 cannot be met: the repository holds nothing for itch.io, and Legal's own page says the title search comes before any itch.io page (F-MARKET-08).
- X-31 is a gap; X-34 is a gap (three of the six named shots have a recipe, none is rendered per milestone, and the kit films only a browser build at 960 by 540).
- One blocker, seven majors, seven minors, ten things that work.

## Questions and answers

**Q1. Is there a fixed shot list in one data file, rendered at every milestone (10.1)?**
Half. The one data file exists: `tools/clips/clips.json` holds recipes (scene, seed, page words, tick or event window, crop, encoding; `clips.json:2`), and a recipe "moves to a newer build with nobody looking" (`clips.json:2`; `--build` at `make.mjs:3`). It is not a fixed shot list and nothing renders it per milestone. Against the six shots the specification names:

| Shot | Recipe today | Evidence |
| --- | --- | --- |
| Beam struggle | yes | `clips.json:57` (`beam-struggle`), `:78`, `:82`, `:86` (three camera framings; these need the film camera words `bdshot`, present on main: `flash_capture.gd:609`, `main.gd:61`) |
| Launch into a city | yes | `clips.json:61` (`top-power-towers`, scene `towers`, `flash_capture.gd:391`) |
| Building fall | yes | `clips.json:66` (`building-gives-way`, scene `collapse`, `flash_capture.gd:365`) |
| Transformation | no recipe; a hook scene exists | `flash_capture.gd:363` (`transform`); event name ready at `clips.json:29` |
| Lap of the globe at speed | none, and no hook scene | `flash_capture.gd:33-36` (scene lists: no lap or flight scene) |
| LAN 2v2 moment | none | see Q3 and F-MARKET-04 |

Ten further recipes are empty slots marked `"pending": true` (`clips.json:98-107`). F-MARKET-02.

**Q2. What is kept per milestone (build, replay files, clean footage, a line on what changed)?**
- *The build:* yes in practice. Every build the owner played is kept by commit: 18 folders under `homework/Files/builds/` (local), written by `tools/preview/handover.mjs` (TOOLS F-TOOLS-20). They are not milestones, and they are on one disk with no backup (TOOLS F-TOOLS-09).
- *Replay files:* the owner's saved matches sit loose in `homework/Files/` (local; six `orb-first-play-*.json`), not filed with a milestone.
- *Clean footage:* one folder, `homework/Files/clips/mms-2026-11-10/` (local), named by date, not by build; the kit's designed layout is `homework/Files/clips/<build folder>/` with `index.txt` (`make.mjs:10`).
- *A line saying what changed:* none. No changelog is tracked (`git ls-files` for "changelog": no file).
So any two milestones cannot be shown side by side today. F-MARKET-03.

**Q3. What already exists, checked from its code?**
- *Clip kit* (`tools/clips/`): real. `make.mjs <name|all>`, `--from-match`, `--list`, `--dry` (`make.mjs:3-5`); serves a kept build, starts the browser through the launcher, steps one tick at a time, finds moments from the sim's own events with no picture looked at (`make.mjs:7-11`); GIF, PNG sequence or WebM (`make.mjs:9-10`). Its self-test is in no workflow (grep of `.github/workflows/*.yml` for `clips-selftest`: no line). F-MARKET-16, F-MARKET-13.
- *Replay* (`sim/core/replay.gd`): a seed, AI flags and intents reproduce a match bit for bit (`replay.gd:3`); a replay carries a data hash and plays back only on the same data (`replay.gd:7`, `:135`), with a hash checkpoint every 60 ticks (`replay.gd:29`). `tools/preview/blackbox-clip.mjs` films a saved match and compares the checkpoints as it goes (`blackbox-clip.mjs:1-2`). The page word it needs, `replay=1`, is not in main's game code: it is patched into a scratch copy by the private-build tool (`tools/preview/switches.mjs:538-545`; `git grep '"replay"' -- render ui` returns nothing). F-MARKET-10, F-MARKET-18.
- *Side-by-side* (`tools/flash/side-by-side.mjs`): two captured clips as stills and a half-size GIF, labelled, and it refuses two clips of different matches unless told the difference is the point (`side-by-side.mjs:1-4`, `:18-19`). It takes frames from `capture-web.mjs`, not the clip kit's output folder. No CI job runs it (I-07, flash pixels row). F-MARKET-19.
- *Guarded launcher* (`tools/machine/`): real (Q5). F-MARKET-17.
- *LAN:* `tools/preview/lan-clip.mjs` plays a LAN report's replay on a kept browser build of the same commit and writes a player page (`lan-clip.mjs:1-6`, `:11`). Its self-test is in no workflow, and the first real LAN save through the report tool is still owed (`questions.md`, AQ-01, Tools' list). Whether it handles four fighters: not evidenced.

**Q4. What is missing?**
The shot list itself (F-MARKET-02); a job that renders it per milestone, the archive's layout, the change line and a backup (F-MARKET-03); a way to film the desktop and LAN game (F-MARKET-04); footage at a size and format a video site or a store accepts (F-MARKET-05); a written rule for a replay that no longer plays (F-MARKET-10).

**Q5. Do captures follow the PC rules (launcher only, one at a time, time limit, below-normal priority)?**
Yes in the code. Every clip tool imports `launchBrowser` from `tools/machine/browser.mjs` (`make.mjs:17`, `blackbox-clip.mjs:10`, `reel.mjs:12`, `clip-script.mjs:9`). The launcher sets a hard time limit (default 5,400 s, `browser.mjs:197`), a Windows Job Object that cannot outlive its launcher (`browser.mjs:6-7`), below-normal priority and a 25% CPU cap (`browser.mjs:8`, `:201-202`), and a profile folder carrying the session's name (`browser.mjs:9-10`). "One at a time" is a written instruction (`docs/tools/clips.md:21`, `lan-clip.mjs:9`), not something the launcher enforces: not evidenced as enforced. The launcher's own self-test is manual (I-07, Notable 3).

**Q6. A way to record with no debug text and no overlays (10.2)?**
In the capture hook, yes: the hook starts no first-run card, notice or intro (`flash_capture.gd:9-10`), and the kit's default words carry `nohud=1&blackbox=off` (`clips.json:6`). In the game itself the debug layers are off unless a key is pressed: the performance readout (`render/core/hud.gd:20` default false; F3 at `main.gd:1543-1544`), the director feed (F4, `main.gd:1549-1550`), the key help (`main.gd:277`). The tools that film a saved match add their own bar over the page (`blackbox-clip.mjs:31`), which the kit's `--from-match` path replaces with a strip under the picture (`docs/tools/clips.md:47`).

**Q7. An optional no-HUD mode?**
For capture only, and only in a browser build: `nohud` hides the HUD layer and the take-over prompt (`flash_capture.gd:180-181`), and the hook exists only on the web (`main.gd:299`). There is no no-HUD option a player can choose, and none in a desktop build. F-MARKET-15, F-MARKET-20.

**Q8. Steady frame pacing during capture?**
Yes, by design: "A tick is a frame here whatever the machine does" (`flash_capture.gd:21-22`); `step()` runs exactly one tick and resolves when the frame has been shown (`flash_capture.gd:16-18`). Two limits the hook states itself: it is not the game's own pacing (real play interpolates between ticks), and the crowd's run cycles follow the shader's clock, so bystanders differ between two captures of the same shot (`flash_capture.gd:23-24`). F-MARKET-14. The recipes take every third tick at 12 pictures a second (`clips.json:8`, `:11`), so today's clips are not 60 frames a second (F-MARKET-05).

**Q9. Photo mode: after Alpha?**
Confirmed after Alpha. None exists (`git grep -i 'photo mode'`: only the audit's own pages and a drafted idea at `docs/tools/clip-capture-audit.md:39`). It is not in Orb's Alpha definition, and the shot list does not need it: shots are scripted, not framed by hand. F-MARKET-15.

**Q10. Orb's standing rules for anything public (10.3): are they written and enforced?**
- *No in-progress character art in public:* written (`docs/marketing/steam-readiness.md:21`; `docs/tools/clips.md:56`). Footage stays private by location (`.gitignore:28-29`). Enforced by a person, not a tool.
- *AI disclosure everywhere:* wording and placement written for video descriptions and pinned comments (`docs/marketing/go-to-market-plan.md:96`, `:110`); Steam's survey answer drafted (`docs/legal/steam-readiness.md:28-31`). Nothing has been published, so use is not evidenced.
- *Player-safety screening of video:* partly. Every GIF the kit makes gets a flash verdict (`make.mjs:251`, `:277`, `:345`; record `docs/tools/runs/mms-2026-11-10/screen-results.txt`). WebM and PNG output get none (`make.mjs:282`, `:349`), and video is the format a video site takes. F-MARKET-06 (off the owner's page).
- *Forward-facing words seen by Orb:* written as a rule (`docs/marketing/store-copy-draft.md:121`, `:178`); the public page is offline (`tools/site.json:3`, I-07).
- One thing against the "real captures only" rule the project wrote for itself (`store-copy-draft.md:103-106`): the clips shared so far are staged. F-MARKET-09.

**Q11. itch.io for Alpha (10.4): what exists, and do the notes match itch.io's documentation?**
Nothing exists in the repository: `git grep -i -E 'itch\.io|\bbutler\b' -- tools .github net render ui sim` returns one line, a test string (`ui/tools/hud_check.gd:9416`). No page set-up note, key list procedure, channel names, upload script, rehearsal record or tester guide (`git ls-files | grep -i tester`: only `docs/legal/alpha-tester-note.md`, which does not mention itch.io). F-MARKET-01, F-MARKET-07.
What the project's notes claim about itch.io, each **needs web check**:
- an account is free and payout details are needed only when charging (`docs/legal/pre-store-checklist.md:28`);
- itch.io has a generative-AI field with per-part ticks, and untagged AI projects are left off browse pages (`docs/legal/go-to-market.md:28`, a secondary source by its own label; `docs/marketing/go-to-market-plan.md:32`, `:106`);
- itch.io needs no rating and uses content tags (`docs/legal/guide-selling-your-first-game.md:37`; "Not checked in detail", `docs/legal/go-to-market.md:151`).
None of the project's notes covers restricted pages, download keys, the upload tool, channels or versions. The judgment session's read (`02-areas/web-checks.md`, itch.io table) covers them: restricted pages and named, revocable keys; `butler push <folder> user/game:channel`; channel names tag the platform; our own version string with `--userversion`. Two points there are from forum threads and are to be settled in the rehearsal: whether claiming a key needs an itch.io account, and how a tester goes back a version.
The marketing plan describes a different itch.io: a public page with the browser game embedded (`go-to-market-plan.md:146-158`). F-MARKET-11. Legal's own page puts the title search before any itch.io page (`docs/legal/name-screening.md:186`). F-MARKET-08.

**Q12. Steam at Beta (10.5): each item.**

| Item | What the project's notes say | State |
| --- | --- | --- |
| Fee | $100 per app, not refundable, recouped only after $1,000; "A free game never recoups it" (`docs/legal/steam-readiness.md:10`) | Matches web-checks. Orb's spend; not for Alpha. |
| Account | Identity, tax and bank, 15 to 30 days, Orb alone (`docs/legal/steam-readiness.md:11`; `docs/marketing/steam-readiness.md:29`) | Matches web-checks ("weeks"). Nothing of it is in the repository. |
| Waiting period | Plan on 30 days. The three records disagree on which of Valve's pages says 21: Marketing says the Steam Direct page gives 30 and Onboarding 21 (`docs/marketing/steam-readiness.md:32`); Legal says both give 21 (`docs/legal/steam-readiness.md:12`); web-checks says Onboarding gives 30 and the older page 21 | **Needs web check.** Planning on 30 is safe under every reading. F-MARKET-12. |
| Store page review before the build | 3 to 5 business days, submit 7 or more ahead (`docs/marketing/steam-readiness.md:30`); "1 to 5 days" (`docs/legal/steam-readiness.md:12`) | Web-checks: 3 to 5, ask at least 7 business days ahead, page before build. Legal's "1 to 5" is the looser figure. |
| Coming soon, two weeks | `docs/marketing/steam-readiness.md:31`; `docs/legal/steam-readiness.md:12` | Matches web-checks. Whether it can overlap the 30 days: not checked (web-checks, "Not checked"). |
| Demo is its own app | `docs/marketing/steam-readiness.md:37`; one wishlist notice within 14 days of the demo's first release (`:39`) | Matches web-checks (own app id, linked; own page needs a trailer and five screenshots). The 14-day notice: **needs web check.** |
| Title cleared | "No store page or fee until this is done" (`docs/legal/steam-readiness.md:36`); row open (`docs/legal/review-log.md:53`) | Open. F-MARKET-08. |
| Store assets | Four capsule sizes, five or more screenshots of at least 1920 by 1080, a trailer in .mp4/.mov/.wmv up to 1080p at 30 or 60 frames a second (`docs/marketing/steam-readiness.md:12-16`) | Sizes **need web check**. All "need". Today's kit cannot make them (F-MARKET-05). |
| Content survey and AI | Pre-generated yes, live-generated no; disclose code too by Orb's rule (`docs/legal/steam-readiness.md:28-31`) | Matches web-checks. Marketing notes the survey wording may have changed (`docs/marketing/steam-readiness.md:48`). |
| Steam Deck review | Valve awards the badge after its own review; "Reviews need a build review first"; 9 px smallest text, 30 frames a second at 800p (`docs/marketing/steam-readiness.md:47`) | How Valve schedules it: not evidenced here or in web-checks. **Needs web check.** It belongs to a Steam release, not to an itch.io Alpha. |
| Next Fest | Entry rules "unconfirmed today"; earlier read: public page and a live demo (`docs/marketing/steam-readiness.md:40`); one Next Fest only (`go-to-market-plan.md:22`) | Web-checks: February 2027 closes 10 January 2027; June 2027 is the next. February does not fit (no Alpha yet, title not cleared). Not a target. |

**Q13. The draft timeline, and what "Beta in sight" should mean.**
No timeline that counts back from the demo exists in the project's own pages: Marketing has an order of ten steps with no intervals (`docs/marketing/steam-readiness.md:50-61`). The specification's draft holds against the intervals above (web-checks, "For the plan"): 30 days fee-to-release sits inside "week 10 fee paid"; a page submitted at week 6 and live at week 4 leaves the 7 business days and the two weeks of "coming soon"; the demo at week 3 leaves its 7 business days. The project's plan gates the Steam page on "at least 4 fighters, Steam build working" and a public-itch number (`go-to-market-plan.md:21`), which agrees with the stand-in's "four fighters playable" but adds a public stage Orb's Alpha definition does not have. Recommendation: "Beta in sight" means four fighters playable on the Windows and Linux builds and the Alpha testers' reports folded in; the clock starts at Orb's "go" on the fee and the title search. F-MARKET-11.

**Q14. Are the existing notes current?**
- `docs/marketing/steam-readiness.md` (2026-10-27): mostly current; one attribution in dispute (F-MARKET-12).
- `docs/legal/steam-readiness.md` (touched 2026-11-07): current on fee, survey and blockers; it still says "Our code is MIT (shape A)" (`:21`) against Legal's later rundown, which the EP reports as "never MIT or CC BY" (`questions.md`, AQ-04).
- `docs/legal/pre-store-checklist.md` (2026-09-30): stale on the licence: "Keep MIT and CC BY (the recommended pairing)" (`:34`).
- `docs/legal/guide-selling-your-first-game.md` (touched 2026-11-07): a selling guide for a paid game; nothing on restricted pages or keys.
- `docs/marketing/go-to-market-plan.md` (2026-10-05, touched 2026-10-27): predates the Alpha definition; its capture checklist still holds clips for the old placeholder names (`:229`) though the game shows Grist and Loupe (`ui/data/fighter_names.json:5-6`), and it advises against a Discord server (`:129`) where Orb has since chosen one for reports (`docs/ep/vision.md:1741`). F-MARKET-11, F-MARKET-12.

## Exit criteria

| Id | Status | Proof or gap | Measuring tool, and whether it exists |
| --- | --- | --- | --- |
| X-31 itch.io: restricted page, tester keys, Windows and Linux channels, one update through the upload tool | **Gap** | Nothing in the repository (Q11; F-MARKET-01); no Windows or Linux build of the game as played to upload (TOOLS F-TOOLS-01); Legal's page forbids the page before the title search (F-MARKET-08); no tester guide (F-MARKET-07) | A rehearsal with a dummy build: does not exist. The account, page, keys and the upload tool's install are the owner's actions. No number in this criterion is marked proposed. |
| X-34 marketing archive: the fixed shot list renders from the candidate and sits beside the same shots from earlier milestones | **Gap** (partly not measurable today) | Three of six shots have a recipe (Q1); no render job, archive folder or earlier milestone's shots (Q2); the kit films a browser build only (F-MARKET-04) | The archive folder: does not exist. The parts that do: `tools/clips/make.mjs` (renderer), `tools/clips/clips.json` (list file), `tools/flash/side-by-side.mjs` (pairing), `tools/machine/browser.mjs` (launcher). Missing: the shot list rows, a per-milestone job, a desktop or LAN capture route. |

## Findings

Costs: S under 0.5M tokens, M 0.5 to 2M. The one comparable on record is the clip kit itself, estimated before it was built at "about 0.5 to 0.8 million tokens" for one Tools session (`docs/tools/clip-capture-audit.md:34`); its real cost is not recorded. No finding here changes the sim's state hash.

| id | kind | statement | evidence | criterion | severity | alpha | owner | cost | hash |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F-MARKET-01 | gap | Nothing for itch.io exists: no page set-up note, key procedure, channel names, upload script or rehearsal record (the same hole as TOOLS F-TOOLS-02, seen from the distribution side). | `git grep -i -E 'itch\.io\|\bbutler\b' -- tools .github net render ui sim`: one test string, `ui/tools/hud_check.gd:9416`; `02-areas/TOOLS.md:60`; `02-areas/web-checks.md` (itch.io table) | X-31, X-30 | blocker | required | tools-pipeline | M: estimate, no comparable | no |
| F-MARKET-02 | gap | There is no fixed shot list: the recipe file covers three of the six named shots and has no recipe for a transformation, a lap of the globe or a LAN 2v2 moment. | `tools/clips/clips.json:57`, `:61`, `:66`, `:78-86`, `:98-107`; `render/tools/flash_capture.gd:33-36`, `:363` | X-34 | major | required | tools-pipeline | S: adds rows and one or two hook scenes to a kit estimated at 0.5 to 0.8M whole (`docs/tools/clip-capture-audit.md:34`) | no |
| F-MARKET-03 | gap | No job renders the shots at a milestone and no archive exists: clips land in a git-ignored folder with no milestone name, no line on what changed and no backup. | `tools/clips/make.mjs:10`; `.gitignore:28-29`; `homework/Files/clips/` holds one folder, `mms-2026-11-10` (local); `git ls-files` for "changelog": none; `02-areas/TOOLS.md:67` | X-34 | major | required | tools-pipeline | S: estimate, no comparable | no |
| F-MARKET-04 | gap | The capture hook exists only in a browser build, so the Alpha candidate's own Windows and Linux programs cannot be filmed, and a LAN 2v2 shot depends on a replay route whose self-test is in no workflow and which has not yet read a real LAN save. | `render/core/main.gd:299`; `tools/preview/lan-clip.mjs:1-6`; grep of `.github/workflows/*.yml` for `lan-clip-selftest`: none; `questions.md` AQ-01 (Tools: "the first real LAN save through lan-report") | X-34 | major | required | tools-pipeline | M: estimate, no comparable | no |
| F-MARKET-05 | gap | Footage is made at 960 by 540, shrunk to 480 wide at 12 pictures a second, as GIF or browser-recorded WebM with no MP4, below what the project's own Steam note asks of screenshots and a trailer. | `tools/clips/clips.json:7-14`; `tools/clips/make.mjs:9-10`; `docs/tools/clip-capture-audit.md:16`, `:32`; `docs/marketing/steam-readiness.md:15-16` (needs web check) | X-34 | major | required | tools-pipeline | S: estimate, no comparable (the size is a recipe key; PNG sequences already exist) | no |
| F-MARKET-06 | gap | Only GIFs get the flash check; WebM video and PNG sequences leave the kit with no verdict, and no page says how a public video is screened (off the owner's page). | `tools/clips/make.mjs:251`, `:277`, `:345` against `:282`, `:349`; `docs/tools/clips.md:43` | X-34, X-02 | major | required | tools-pipeline | S: estimate, no comparable | no |
| F-MARKET-07 | gap | No tester guide says how a tester gets a key, installs on a Steam Deck, updates, or posts a report; the only tester page is Legal's note, which does not mention itch.io. | `git ls-files \| grep -i tester`: `docs/legal/alpha-tester-note.md` only; `grep -n itch docs/legal/alpha-tester-note.md`: none | X-31, X-18, X-01 | major | required | community-marketing | S: estimate, no comparable | no |
| F-MARKET-08 | gap | Legal's own page puts the formal title search before any itch.io page, the title row is still open, and nothing excuses a key-only page (the same point as LEGAL F-LEGAL-09). | `docs/legal/name-screening.md:186`; `docs/legal/review-log.md:53`; `docs/legal/steam-readiness.md:36` | X-31 | major | required | legal-ip | S: estimate, no comparable | no |
| F-MARKET-09 | gap | The clips shared so far were staged on a private test copy with behaviour the game does not have (both at top power, a beam on a button, changed speeds, a scratch-only camera), so they cannot be remade from main and are not the game as played. | `homework/Files/clips/mms-2026-11-10/index.txt` (local; "What is not stock gameplay"); `docs/tools/runs/mms-2026-11-10/takes-towers-and-clash.json`; `git grep -l mmcam`: only `docs/tools/pending/mms-tweaks/` and that record; `docs/marketing/store-copy-draft.md:103-106` | X-34 | minor | required | tools-pipeline | S: estimate, no comparable (a rule in the shot list: stock build, stock inputs, real speed) | no |
| F-MARKET-10 | gap | No rule says what happens to a shot when an old replay stops playing: a replay is refused on different data, and the page word that plays a saved match is a scratch patch, not game code on main. | `sim/core/replay.gd:7`, `:135`; `tools/preview/switches.mjs:538-545`; `tools/preview/blackbox-clip.mjs:7` | X-34, X-27 | minor | required | tools-pipeline | S: estimate, no comparable | no |
| F-MARKET-11 | gap | The marketing plan predates Orb's Alpha definition: it stages a public browser build and public itch.io page, advises against Discord, still holds clips for the old placeholder names, and has no timeline counting back from the Steam demo. | `docs/marketing/go-to-market-plan.md:20-22`, `:129`, `:146-158`, `:229`; `ui/data/fighter_names.json:5-6`; `docs/ep/vision.md:1741`; `docs/marketing/steam-readiness.md:50-61` | none | minor | required | community-marketing | S: estimate, no comparable | no |
| F-MARKET-12 | gap | The project's notes disagree with each other on Valve's waiting period and are stale on the licence: three records name different pages for the 21 and 30 days, and two Legal pages still call the code MIT. | `docs/marketing/steam-readiness.md:32`; `docs/legal/steam-readiness.md:12`, `:21`; `02-areas/web-checks.md` (Steam table); `docs/legal/pre-store-checklist.md:34`; `questions.md` AQ-04 | none | minor | nice | legal-ip | S: estimate, no comparable | no |
| F-MARKET-13 | gap | The self-tests of the clip kit, the browser launcher and the LAN clip tool run in no workflow, so the chain the archive depends on can break unseen. | grep of `.github/workflows/*.yml` for `clips-selftest`, `machine/selftest`, `lan-clip-selftest`: no line; `01-inventory/I-07-tools-ci.md` Notable 3 | X-34 | minor | nice | tools-pipeline | S: estimate, no comparable (the non-browser halves only; CI must not start a browser capture it cannot bound) | no |
| F-MARKET-14 | gap | Bystanders' run cycles follow the shader's clock, not the tick, so two renders of the same shot differ in the crowd and a side-by-side shows a difference that is not a change in the game. | `render/tools/flash_capture.gd:23-24` | X-34 | minor | nice | rendering-techart | S: estimate, no comparable | no |
| F-MARKET-15 | gap | A player cannot hide the HUD and there is no photo mode; both are absent from the game and neither is in Orb's Alpha definition. | `render/tools/flash_capture.gd:180-181` (capture hook only); `render/core/main.gd:299`; `docs/tools/clip-capture-audit.md:39` (drafted idea) | none | minor | after | ui-ux | M: estimate, no comparable | no |
| F-MARKET-16 | works | One command makes seeded, repeatable clips from a kept build out of one recipe file, finding moments from the sim's own events, and six clips made on 2026-11-10 are on record. | `tools/clips/make.mjs:3-11`; `tools/clips/clips.json:2`, `:19-30`; `docs/tools/runs/mms-2026-11-10/screen-results.txt` | X-34 | none | n/a | tools-pipeline | n/a | no |
| F-MARKET-17 | works | Every clip tool starts its browser through the one guarded launcher, which sets a hard time limit, below-normal priority, a CPU cap and a profile named for its session. | `tools/machine/browser.mjs:5-10`, `:197-202`; `tools/clips/make.mjs:17`; `tools/preview/blackbox-clip.mjs:10` | X-34 | none | n/a | tools-pipeline | n/a | no |
| F-MARKET-18 | works | A replay reproduces a match from its seed and intents, is refused on different data, and the clip made from a saved match says whether its checkpoints matched the match that was played. | `sim/core/replay.gd:3`, `:7`, `:135`; `tools/preview/blackbox-clip.mjs:1-2`, `:34` | X-34, X-27 | none | n/a | simulation-engine | n/a | no |
| F-MARKET-19 | works | The side-by-side tool pairs two captured clips as labelled stills and a GIF and refuses a pair that is not the same scenario and seed. | `tools/flash/side-by-side.mjs:1-4`, `:18-19` | X-34 | none | n/a | tools-pipeline | n/a | no |
| F-MARKET-20 | works | Capture is clean in a browser build: the hook shows no card, notice or intro, a page word hides the HUD without touching the sim, and the kit uses it by default. | `render/tools/flash_capture.gd:9-10`, `:180-181`; `tools/clips/clips.json:6` | X-34 | none | n/a | tools-pipeline | n/a | no |
| F-MARKET-21 | works | Capture pacing is even whatever the PC is doing: the hook runs exactly one tick per picture. | `render/tools/flash_capture.gd:16-18`, `:21-22` | X-34 | none | n/a | tools-pipeline | n/a | no |
| F-MARKET-22 | works | A clip button (F9, or View and RB) and automatic bookmarks mark moments in a saved match, and the kit cuts a clip for each from the replay. | `tools/preview/blackbox.mjs:258-265`; `tools/clips/clips.json:31-39`; `tools/clips/make.mjs:4`, `:326` | X-34 | none | n/a | tools-pipeline | n/a | no |
| F-MARKET-23 | works | Each build the owner played is kept by commit (18 folders), which is the "build" half of a milestone archive. | `homework/Files/builds/` (local; 18 folders, newest `orb-first-play-6a30b4c9-6627cb9d`, `orb-lan-6a30b4c9`); `02-areas/TOOLS.md:78` | X-34, X-30 | none | n/a | tools-pipeline | n/a | no |
| F-MARKET-24 | works | The owner's rules for public material are written where the work will be done: real captures only, no in-progress character art, the AI wording for video descriptions, and publishing held for the owner's approval. | `docs/marketing/steam-readiness.md:21`; `docs/marketing/store-copy-draft.md:103-106`, `:121`; `docs/marketing/go-to-market-plan.md:96`, `:110` | none | none | n/a | community-marketing | n/a | no |
| F-MARKET-25 | works | The project's Steam planning figures are on the safe side of the platform pages read on 2026-11-13: 30 days from the fee, two weeks of "coming soon", seven business days per review, and a free game never recoups the fee. | `docs/legal/steam-readiness.md:10-12`; `docs/marketing/steam-readiness.md:30-32`; `02-areas/web-checks.md` (Steam table) | none | none | n/a | legal-ip | n/a | no |

Owner notes: F-MARKET-01 also needs the owner's own actions (account, page, keys, installing the upload tool), plus community-marketing for the page's words and legal-ip for F-MARKET-08. F-MARKET-02 needs camera (the camera path of each shot) and community-marketing (which moments). F-MARKET-04 needs netcode-online and performance-platform. F-MARKET-06 needs legal-ip and accessibility-localization, who own the screening rule. F-MARKET-07 needs qa-balance, performance-platform and legal-ip. F-MARKET-15 needs tools-pipeline and camera.

## Gaps the questions missed

- **The capture route films a different program from the one testers get.** Alpha ships Windows and Linux programs; the kit films a browser build of the same commit. The sim is the same by the parity checks, but the picture is the browser's. Nothing compares the two pictures (F-MARKET-04).
- **Staged clips.** Section 10 asks for "the same moments"; the clips made so far get their moments by changing the game (F-MARKET-09). A shot list for comparisons has to be stock, or two milestones differ for reasons that are not progress.
- **Crowd timing** makes identical shots differ (F-MARKET-14).
- **Video has no flash verdict** (F-MARKET-06).
- **The tester guide** is asked for in 10.4 but no criterion names it as a marketing deliverable; it sits between X-01, X-18 and X-31 (F-MARKET-07).
- **Two plans for itch.io.** The specification's key-only page and the marketing plan's public page with the embedded browser game are different things under one name (F-MARKET-11). The public test page is down and its delegated decision ends 15 November (`questions.md`, AQ-02).

## Not evidenced

| What could not be checked | What one measurement would settle it |
| --- | --- |
| Whether the clip kit runs end to end on the newest kept build with the tracked recipes (the record on file used a scratch copy's words) | `node tools/clips/make.mjs all --build orb-first-play-6a30b4c9` and its `index.txt`, saved under `docs/tools/runs/` |
| Whether the kit can film at 1920 by 1080 and 60 pictures a second in workable time through the launcher's CPU cap | One recipe with `size` 1920 by 1080 and `step` 1, as a PNG sequence, timed |
| Whether `lan-clip.mjs` handles a four-fighter LAN report | The first real LAN 2v2 report folder run through it |
| Whether "one capture at a time" is enforced by the launcher or only asked | A read of `tools/machine/captures.mjs` and a second launch while one is listed |
| Whether claiming an itch.io key needs an account, and how a tester returns to an earlier version | The X-31 rehearsal with a dummy build (owner's account) |
| How Valve schedules a Steam Deck compatibility review, and whether "coming soon" can overlap the 30 days | A read of Valve's Deck and release pages (web check) |
| itch.io's generative-AI field and whether it applies to a restricted page | A read of itch.io's creator pages (web check); Legal to cite it in a row |
| Steam's asset sizes and trailer formats as listed in `docs/marketing/steam-readiness.md:12-16` | A read of Valve's graphical assets and trailer pages (web check) |
| Whether any clip has been posted publicly | Not knowable from the repository; the page is offline (`tools/site.json:3`) |

## Decisions for Orb

1. **Will you create the itch.io account and the key-only page, and install its upload tool, yourself once Tools has a one-page checklist?** Recommendation: yes, in one sitting; X-30 and X-31 cannot be rehearsed before it. (Same question as TOOLS.)
2. **May the key-only page go up under the working title before the paid title search?** Recommendation: yes, only if Legal first writes one row saying an unlisted, unpromoted, key-only page is acceptable; the search still comes before any public or Steam page. (Same question as LEGAL.)
3. **What should "Beta in sight" mean, the point where the Steam clock starts?** Recommendation: four fighters playable on the Windows and Linux builds and the Alpha testers' reports folded in. Nothing for Steam is spent before then, and the February 2027 Next Fest is not a target.
4. **Where is the progress archive kept safe?** It holds builds and private footage, so it cannot go in the public repository. Recommendation: a second disk or a private folder you already have, copied at each milestone; choosing or paying for storage is your call.
5. **May Tools ask you to install a free video encoder when the first teaser is cut?** It is a download, so it is yours to do. Recommendation: not now; the archive keeps full-size picture sequences, which lose nothing, and the encoder is added when Beta is in sight.
6. **Photo mode after Alpha?** Recommendation: yes, after Alpha; the scripted shot list does not need it.
