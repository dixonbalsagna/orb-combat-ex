# Park: the testers' package on Orb's PC; the workflow's outside-testers path gone (Tools, 2026-11-25; RL-277)

`testers-local.patch`, cut on HEAD 43de88fe. All Tools' paths. `git apply docs/tools/pending/testers-local/testers-local.patch`.

- `node tools/desktop-local-build.mjs --audience testers --builds-yes <date>`: refused off main or without Orb's committed, dated yes; refused before the import while the words are a draft or `.private/testers/report-channel.txt` is missing or unsafe. Windows zip and Linux tar.gz in `homework/Files/desktop/<commit8>-testers/`. The record holds no channel line.
- `desktop-builds.yml`: `owner-private` only; no upload, no download, the `windows-bench` and `windows-still` jobs gone (they needed the uploaded zip); `windows-local` stays.
- `check-desktop-audience.mjs` and its self-test now hold that. Docs updated.

**Run:** self-tests (audience 13, local build 14, packaging 162, upload check 25), the workflow guards.

**Rehearsed** in a scratch clone with a made-up approval, made-up report channel and the words marked final there only: the testers' build passed every step (Windows bench hash equal to the project's: 9d323c7f64c75955), and `itch-push.mjs` on its files with the record committed gave a clean dry run; `--push`, a missing yes date and an empty channel were refused. One line was added after the rehearsal (the check's throwaway README is deleted at once) and was not rebuilt.

**Not proven:** the Linux program has been started by nobody, and no runner sees these bytes; a person starts it on a Deck or other Linux machine before a key is sent. The trimmed workflow has not run. No macOS testers' package.
