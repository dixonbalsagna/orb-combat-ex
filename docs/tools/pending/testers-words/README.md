# Park: the testers' words and the report-channel refusal (Tools, 2026-11-25; A2 job 4, first piece)

`testers-words.patch`, cut against HEAD 935056c0. All Tools' paths. `git apply docs/tools/pending/testers-words/testers-words.patch`.

- New `tools/site-tester.json`: Legal's RL-264 words, held word for word by the self-test. `draft: true`. The report channel is only the placeholder.
- `tools/desktop-package.mjs`: `text --testers` and `verify --testers` use those words. Refused while the words are a draft; refused while the report-channel line is missing, a placeholder, two lines, a link, an invite, an address or a handle. The real line is read from the git-ignored `.private/testers/report-channel.txt` (or `--channel-file`).
- `desktop-builds.yml`: the outside-testers text step passes `--testers`.
- `docs/tools/desktop-builds.md`: a section on it.

**Run in a full scratch copy:** packaging self-test 162 checks (146 before); desktop audience, workflows, workflow shell, workflow paths, script table, local-build and interim-site self-tests pass; content screen 0 failing. **Not run:** the workflow itself; no package was made with the testers' words (the file is a draft, so the command refuses).

**Effect of applying:** an `audience=outside-testers` run now stops at its text step. Before, it would have shipped the site's notice, which Legal did not write for testers.
