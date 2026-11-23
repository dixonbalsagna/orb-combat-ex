# The store-page checklist, with the upload and roll-back plan (Tools, 2026-11-23; path to Alpha 1, job 14)

**DRAFT for the EP and Orb. Nothing was uploaded, registered, paid for or contacted, and no page exists.** Every public or store step below waits for Orb's recorded yes. Tools owns the build half; Legal owns the rulings it quotes; Community owns the page's words; Orb owns the account, the keys and every spend.

## 0. Which page this is

For Alpha 1 the only page is **the restricted, key-only itch.io page** that Legal's RL-261 allows (`docs/legal/itch-page-ruling.md`), for the friends who test (Steam Decks first). It is not a store listing: it is a private page that only named friends can open, sells nothing and is found by nobody. A Steam page, a public or listed itch.io page, any promotion, any domain or handle, and any price wait for the paid title search (Orb's spend, CD-06) and for `docs/legal/steam-readiness.md`; this page does not cover them.

## 1. The rules that bind (read before every step)

| Rule | Source | What it means here |
| :--- | :--- | :--- |
| Restricted, unlisted, unpromoted; working title; AI line up front; free; one key per named adult friend; no other use of the name; no claim the name is cleared | RL-261 (`itch-page-ruling.md`), 8 conditions | The page settings and words below are those conditions, one by one |
| **No workflow pushes to itch.io.** The upload is Orb's, by hand, one sitting | `docs/legal/desktop-build-rulings.md` (RL-262) | The upload script runs on Orb's PC, never in CI; CI proves the package, not the page |
| Orb's recorded yes naming the step | RL-263 and gate G8; `docs/ep/approvals/` | The script refuses without it (section 5) |
| The words on the page are Legal's fixed lines, word for word | `docs/legal/page-fixed-lines.md`; Tools' word-for-word check | Copy the strings; never paraphrase |
| No in-progress character art, no story spoilers on the cover or screenshots | Orb's standing rule; RL-261 condition 2 | Plain text cover, or a still with no characters |
| Nothing from a tester is in the repository | RL-267, gate G22 | The key list and every reply stay on Orb's PC, never in a file here |

## 2. Before any page exists: Orb's calls and the gates (status as of 2026-11-23, from `docs/legal/outside-tester-gates.md`; re-read it on the day)

| # | Item | Who | Status |
| :--- | :--- | :--- | :--- |
| 1 | The itch.io account exists and its name has no personal detail; the page's address uses the working title only | Orb | Open |
| 2 | Orb's recorded yes to the page: **`docs/ep/approvals/restricted-itch-page.txt`**, in RL-263's five-line form (date, scope, recorded-by, ends, conditions). Scope line: "the restricted, key-only itch.io page under the working title, for named adult outside testers, free, no promotion". Conditions line: "RL-261's eight conditions are met on the page; the finished page was read by Legal; one named adult per key; nothing public". Orb's question: "Yes to the private, key-only itch.io page, for named friends only?" Asked on the day, once the gates are green (Legal RL-272) | Orb, EP | Open |
| 3 | G8: Orb's recorded yes to desktop test builds | Orb, EP | Red |
| 4 | G4 and G21: a flash reading of the candidate and of the actual desktop programs, both modes, within 2.5 / 3 / 2 | Tools, Camera, VFX | Red |
| 5 | G15, G16: the private report channel exists; each friend told, an adult, acknowledged | Orb | Red |
| 6 | G9: README.txt and NOTICES.txt carry the notice, the AI line, the privacy line and the licences, final wording placed in `tools/site-tester.json` | Tools, Orb | Red |
| 7 | G13 and G22: a report holds no account name or path; no tester file in the repository | Tools | G13 the scan exists (`tools/report-scan.mjs`), the log copy waits for UI; G22 Red until the content screen covers it |
| 8 | The tester note and the permission page, read and signed off by Orb | Legal, Orb | Written (RL-265) |
| 9 | **Testers' itch.io accounts (Legal RL-271, answered yes with three conditions).** A key is claimed with an itch.io account, so itch.io (another company, with its own records) sees the download and Orb sees the account name. (1) Each friend is told in plain words **before the key is sent**, and the page says it: the fixed account line in `page-fixed-lines.md` (itch.io is another company with its own rules; it sees the download; Orb sees the account name; use a name with no personal details if you prefer; the game itself collects nothing); the tester note's privacy section carries the same line. (2) Account names and the key list stay on Orb's PC only, never in a tracked file, run folder, row or report (G22); a report that quotes one is scanned (G13). (3) A friend without an account is not pressed: no key is sent and no other route is made without a new ruling (RL-262). Adults only. The key test with a spare account uses an account that belongs to no friend; one creator reported a free-claim error, so the test comes first ([itch.io access control](https://itch.io/docs/creators/access-control)) | Orb, Legal | Answered (RL-271) |
| 10 | **The fixed account line** is on the page and in the tester note (RL-271 and RL-272 (a)) | Community, Legal | Open |
| 11 | **Page settings kept off** (RL-272 (b)): comments, ratings, the community tab, the devlog, any public download or "who downloaded" display, any link to the report channel (`page-fixed-lines.md`). Checked on the dashboard, logged out and logged in | Orb | Open |
| 12 | **Legal's read of the finished page, before the first key goes out, is a gate row** saved under `docs/legal/runs/<commit8>/` (RL-272 (c); sits under G14 and G18, no new gate number) | Legal | Open |

## 3. The build, per candidate commit (Tools; each line saves a file under `docs/tools/runs/<commit8>/`)

1. **Numbered:** `node tools/version.mjs --next` in the commit being built, the entry's "For players" line read and approved by Orb (`node tools/version.mjs --check --ready`).
2. **Green CI** on the commit, and the run id saved (G1).
3. **The package, made for the outside-testers audience:** `desktop-builds.yml` with `audience=outside-testers` (Orb's yes recorded; the run keeps three archives for one day; nothing is uploaded by the run). The testers' package hides the modes testers cannot use (`desktop-package.mjs testers`). `routes --testers` and `verify --testers` pass (G6, G7, G10). Or, for Orb's own copy only, `node tools/desktop-local-build.mjs` (owner-private, never for friends).
4. **Both programs of the same commit** exist (Windows zip, Linux tar.gz). The Linux program has played the bench on a runner with the project's hash (the desktop run's summary); the Windows program has played it on a Windows runner (`windows-local`) and, for the zip Orb uploads, on Orb's PC (`FIRST-RUN.cmd`).
5. **The packed data matches the plan** (G3): `tools/preview/pck-verify.mjs` output saved.
6. **The checks that read the package:** `node tools/crash/crash-check.mjs` (a log is left and says why), `node tools/report-scan.mjs <a made report folder>` (G13), the mode smoke on both platforms (`tools/smoke/mode-smoke.mjs`), `node tools/content-screen.mjs` (G12, G22).
7. **Checksums:** SHA-256 of each archive, saved beside the run record; the upload script checks them again at the moment of upload.
8. **The flash reading of the actual programs (G21)** by a person with the warning shown, saved as a reading and never as a pass for anything else. **This is the gate that decides whether the page may open.**
9. **Keep the build:** the previous candidate's archives stay on Orb's PC (`homework/Files/desktop/<commit8>/`) until the next one is accepted: the roll-back needs them (section 6).

## 4. The page, word by word (Community writes; Tools compares; Legal reads)

- **Visibility: Restricted** (itch.io's setting that hides the page from browse and search; only people with a key or approved access get in). Check the setting on the dashboard with a logged-out browser: the address must not open. The page is not linked from any public page, README, post or video.
- **Title:** `Orb Combat EX (working title)`. First line of the page: the name may change. No "official", no ™, no claim the name is cleared.
- **AI line (up front):** the fixed AI line from `page-fixed-lines.md`, and itch.io's own AI field answered the same way (Legal's pre-store checklist section 1).
- **The flashing notice and its lock line** (the page box and the program's gate carry the same words) before the download buttons; never "safe", "tested" or "compliant".
- **In development, privacy and licence lines:** the fixed lines from `page-fixed-lines.md` (the licence line is the one Orb recorded for Alpha: all rights reserved).
- **Free:** price none; no tip jar, no pay-what-you-want, no ads, no donation link.
- **Downloads:** the Windows zip and the Linux tar.gz only, behind keys; no web build on this page, no macOS. Platform tags set to match. The README inside each archive is the tester's first screen.
- **Cover and screenshots:** a plain text cover, or a still of the list of modes (no characters). No in-progress character art, no clip until Art and Legal clear it.
- **Contact and reports:** the page names the private report channel only by what it is ("your report goes to Orb by the channel you were given"), never a link, an address or a name. No Discord invite, no public email.
- **The account line (RL-271):** the fixed account line from `page-fixed-lines.md`, on the page, and the same line in the tester note's privacy section; the friend has read it before a key is sent.
- **Settings that stay off (RL-272 (b)):** comments, ratings, the community tab, the devlog, any public download or "who downloaded" display, any link to the report channel. Checked with a logged-out browser and on the dashboard.
- **Legal reads the finished page** (store-copy-screen rules: franchise lookalikes, "tested", photosensitivity words, the AI line, the account line) **before the first key is sent**; the read is saved as a gate row under `docs/legal/runs/<commit8>/` (RL-272 (c)). Tools runs `node tools/content-screen.mjs` over the copy kept in the repository.

## 5. The upload script (planned; **not written** until Orb says yes to the page)

`tools/store/itch-push.mjs`, run by Orb on Orb's PC with itch.io's own command-line tool, [butler](https://itch.io/docs/butler/pushing) (installed by Orb; the API key is in Orb's environment and never in a file, a log or the repository).

- **Dry run by default.** It prints what it would push, to which page and channel, and the checksums; `--push` does it.
- **Refuses** unless: **both approval files exist** (`docs/ep/approvals/restricted-itch-page.txt` for the page and `docs/ep/approvals/desktop-test-builds.txt` for the package, G8: the page hands out the package that file approves, and neither approves the other: RL-272), each with a date 0 to 30 days old equal to the typed date, a scope line (the page file's must contain "restricted itch.io page"; the package file's "desktop test builds") and a recorded-by line with text; the archive's SHA-256 equals the saved one; the archive unpacks and `desktop-package.mjs verify --testers` passes; the version in `build_info.json` equals the changelog's top entry; the page and channel names are on its allow-list (one project, two channels: `windows`, `linux`); it is not running in CI (`GITHUB_ACTIONS` set refuses).
- **Pushes with `--userversion <version>`** so the page shows the build number, then writes a record (what, when, the checksums, the butler output with no key) under `docs/tools/runs/<commit8>/`.
- It never creates keys, never changes the page's settings (those are the dashboard's: Orb's hands) and never touches a second page.

## 6. The one-step roll-back (planned)

itch.io has no "un-publish a build" or "go back to a build" command that I could find: the old forum answer is to **push the older version on the same channel** (a patch that reverts is applied), and a build cannot be yanked ([butler thread](https://itch.io/t/238316/build-version-history-can-i-revert-to-a-previous-build); these threads are years old, so **check whether it has changed on the day**). So the roll-back is `node tools/store/itch-push.mjs --rollback <previous commit8> --push`: it takes the **previous accepted candidate's** kept archives (section 3, step 9), runs the same refusals, and pushes them as a new version number ("<version>-rollback", written in the record).

- **The stop step (RL-261's "what ends it", RL-272 (d)):** a leaked key, the page found by search or linked from anywhere public, anyone contacting Orb about the name, the paid search finding a conflict, a tester unable to tell this game from another, or Orb wanting to list, promote or sell. Then, by Orb's hand on the dashboard: set the page to Draft (or remove the keys), and change the title to the neutral name **"Private fighting-game test build"** (a plain description, not a brand). The script does not do this; it is a settings change. A new name is screened (RL-024) before it goes on any page.
- **Test the roll-back before the first friend:** push build A and then build B to a spare, private page, roll back to A, and read the record. Not done: there is no spare page.

## 7. What is unknown today, and who finds out

- Whether itch.io's current terms and the butler version still behave as above (Tools reads the butler release notes on the day).
- Whether a restricted page's download key can be claimed without friction by a Steam Deck user's browser (Orb tries with a spare account).
- The itch.io AI field's current wording (Legal reads the form).
- Steam: out of scope here; `docs/legal/steam-readiness.md` is the list, and Tools' packaging chain (`desktop-builds.yml`, `desktop-package.mjs`, `tools/version.mjs`) is already what a Steam depot would take.
