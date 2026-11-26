# Desktop builds: who may get one, how each is made, and the approval line (A-TOOLS-01 and A-LEGAL-02 support; RL-262, RL-263)

Legal, 2026-11-13, written against def3445a; sections 2 to 4 brought up to date 2026-11-25 (RL-277, RL-278). A screen, not legal advice.

## 1. A build for Orb and the trusted second player, before any outside yes (RL-262)

**Ruling: yes, may be made.** A private desktop build (Windows and Linux) for Orb and Orb 2 needs no recorded yes for outside testers. They are covered by Orb's own ruling of 2026-11-07 (RL-253) and by RL-226 and RL-224 (private builds Orb sees, Orb 2 may see). It stays inside those terms:

1. **Who:** exactly Orb and Orb 2. Nobody else gets the file.
2. **How it is made:** on Orb's own PC with the same packaging script the outside package uses (one command, Tools), with the same route scan, the same notices and the same warning. It is **not** made as a file kept by a CI run on the public repository (section 2).
3. **How it moves:** to Orb 2 by a drive, the home network, or a direct private message to Orb 2. Never a public link, never a public upload, never a CI run.
4. **What it carries:** the flashing-effects warning shown before play on each PC and not skippable (RL-253 condition 2); README.txt and NOTICES.txt as for outside testers; the file name and README line say it is a private build for Orb and Orb 2 ("ORB-PRIVATE"), not a test build for others.
5. **Lock state:** Reduce flashing may be unlocked in this package (Orb's standing, RL-253), but the build is never sent on to anyone else in that state. An unlocked build must never be made by, or kept by, a workflow on the public repository.
6. **Not a release or a Legal pass.** A private build for the two is not evidence for any gate, and no flash number from their play counts toward one (RL-224, RL-253).

## 2. May a CI run on the public repository keep a game program as a run file? (RL-262, PC-03)

**Ruling: not an unlocked one, ever, and a locked one only for an outside test after Orb's yes, for one day.**

Why: GitHub lets anyone signed in with read access to a repository download its run files ([GitHub: download workflow artifacts](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/download-workflow-artifacts)), and every signed-in account can read a public repository; third-party sites even offer the files without logging in ([nightly.link](https://nightly.link/)). So a game program kept as a run file on a public repository is **a public download** for as long as it is kept (90 days by default). Reading GitHub's page, I am inferring that "anyone signed in" covers a public repo; the page does not say it in so many words.

So the rules are (as they stand from 2026-11-25, RL-277):
- **No workflow uploads a game program, locked or not.** A workflow may build and check, but keeps nothing: no run file, no release asset.
- **Testers' packages are made on Orb's PC only.** The allowance this page first gave (a locked package kept as a run file for one day, after Orb's yes) is withdrawn by the EP's decision and is no longer in the workflow. Bringing it back needs a new ruling.
- **No GitHub Pages copy or itch.io push from a workflow;** the itch.io upload is Orb's, by hand, in one sitting.

## 3. The two routes and what each must refuse (RL-262 as narrowed by RL-277)

| For | How it is made | Needs `docs/ep/approvals/desktop-test-builds.txt` | What leaves Orb's PC |
|---|---|---|---|
| Outside testers | On Orb's PC: `node tools/desktop-local-build.mjs --audience testers --builds-yes <date>` | **Yes,** in the commit being built (date equal to the one typed, 0 to 30 days old, a scope line, a recorded-by line) | Only Orb's own upload to the restricted page (RL-261, RL-272) |
| Orb and Orb 2 | On Orb's PC: the same script with no audience (files named ORB-PRIVATE) | No | A drive, the home network or a direct private message (section 1) |
| Proof that a commit builds | The desktop workflow, owner-private only | No | Nothing: no upload |

The testers' route must refuse:
- a commit that is not on main, and anything from the working tree (it builds the committed files only);
- a missing, old or mismatched approval file;
- testers' words still marked draft (`tools/site-tester.json`), or a report-channel line that is missing, a placeholder, or holds a link, address or handle (the line stays in `.private/testers/`, never in git or a build record);
- a build whose checks fail (Reduce flashing locked on, the route scan, README and NOTICES words, no `net/*`, no public-issue feedback target).

The package's record (commit, checks, file names and checksums, no folder paths) is committed under `docs/tools/runs/<commit8>/`. The program files themselves are never committed.

**Not proven by any of this:** the Linux program in the testers' package cannot be started on Orb's Windows PC, and no runner ever sees it. A person starts it on a Deck or another Linux machine before any key goes out (gate G23).

## 4. The approval line Orb is asked to record (RL-263)

When the gates in `outside-tester-gates.md` are green, the EP asks Orb one question: "Yes to desktop test builds for named outside testers?" On Orb's word the EP pastes this into `docs/ep/approvals/desktop-test-builds.txt` unchanged, replacing the three dates and the quote:

```
date: YYYY-MM-DD
scope: desktop test builds (Windows and Linux) for named outside testers, through a private download page only
recorded-by: Executive Producer, on Orb's word of YYYY-MM-DD ("Orb's own words here")
ends: 30 days after the date above, then ask again
conditions: every gate in docs/legal/outside-tester-gates.md is green for the commit being built; the package is locked, noticed and checked; one named adult per key; nothing public
```

What the testers' build script reads (and the upload script, with the page's own approval file, RL-272): `date:` (YYYY-MM-DD, must equal the typed date, 0 to 30 days old), a `scope:` line containing "desktop test builds", and a `recorded-by:` line with text. The `ends:` and `conditions:` lines are for people. The file must be committed in the commit being built.
