# Desktop builds: who may get one, what the workflow must refuse, and the approval line (A-TOOLS-01 and A-LEGAL-02 support; RL-262, RL-263)

Legal, 2026-11-13, written against def3445a. A screen, not legal advice. Tools may quote the conditions in the workflow's comments.

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

So the rules for the workflow are:
- **No upload at all for an owner-private build.** The workflow may build and check, but must not keep the program as a run file or a release asset.
- **A locked outside-tester package may be kept as a run file** only when all of: Orb's recorded yes is in the commit being built (section 3); the lock flag is true (Reduce flashing locked on); the route scan and notices pass; `retention-days: 1` (RL-203's rule stands: the EP deletes the run once the testers have the files); and nothing links to it. It is a public download for that one day, which is why it must be the locked, noticed package and why it waits for the yes.
- **No release asset, GitHub Pages copy or itch.io push from a workflow** unless Orb or the EP does it by hand (the itch.io upload is Orb's, one sitting).

## 3. The workflow's exact conditions (for Tools to code, RL-262)

Add one input, `audience`, with two values:

| `audience` | Needs `docs/ep/approvals/desktop-test-builds.txt` | Lock flag | Upload |
|---|---|---|---|
| `owner-private` | No | Any, but see below | **Refuse any upload step** (the job fails if one would run) |
| `outside-testers` | **Yes**, as it checks today (a date, a scope line, a recorded-by line, 0 to 30 days old, in the commit being built) | Must be **true** | One artifact, `retention-days: 1` |

And for **both** audiences the workflow must still refuse:
- a build whose package check does not pass (route scan, notice, README and NOTICES words, no `net/*`);
- a build with a feedback target that is a public issue link (`ui/data/send.json`);
- a build made from a ref that is not a commit on main;
- any publishing step (release, Pages, itch.io).

Quote for the workflow comment: "owner-private builds are made locally and never uploaded; only a locked outside-tester package, after Orb's recorded yes, may be kept as a run file, for one day (Legal RL-262)."

## 4. The approval line Orb is asked to record (RL-263)

When the gates in `outside-tester-gates.md` are green, the EP asks Orb one question: "Yes to desktop test builds for named outside testers?" On Orb's word the EP pastes this into `docs/ep/approvals/desktop-test-builds.txt` unchanged, replacing the three dates and the quote:

```
date: YYYY-MM-DD
scope: desktop test builds (Windows and Linux) for named outside testers, through a private download page only
recorded-by: Executive Producer, on Orb's word of YYYY-MM-DD ("Orb's own words here")
ends: 30 days after the date above, then ask again
conditions: every gate in docs/legal/outside-tester-gates.md is green for the commit being built; the package is locked, noticed and checked; one named adult per key; nothing public
```

What the workflow reads: `date:` (YYYY-MM-DD, must equal the typed date, 0 to 30 days old), a `scope:` line containing "desktop test builds", and a `recorded-by:` line with text. The `ends:` and `conditions:` lines are for people; the workflow ignores them. The file is committed in the commit being built.
