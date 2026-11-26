# Park: the permission page in the testers' folder (Tools, 2026-11-25; RL-265)

`permission-page.patch`, cut on HEAD 643693aa. All Tools' paths. `git apply docs/tools/pending/permission-page/permission-page.patch`.

A testers' package now carries **`WHAT-YOU-MAY-DO.txt`** beside README.txt: Legal's permission page (`docs/legal/permission-page.md`, the section under its title), bold marks removed, nothing else changed. The words sit in `tools/site-tester.json` like the other testers' words, so they stay a draft with them; the self-test holds them against Legal's page line for line, both ways (an added paragraph fails). `verify --testers` refuses a package without the file or with changed words. Owner-private packages are unchanged.

**Run:** packaging self-test 165; upload check 25; local build 14; the text command wrote the four files in a scratch copy with a made-up channel. **Not run:** a full testers' build with it.

**For Legal:** the page's "Credits" paragraph says the notices are "in the build, on the licenses screen, and in NOTICES.txt in your folder": worth one check against what the build's screen shows. **For Orb:** these are words to see before `draft` goes false.
