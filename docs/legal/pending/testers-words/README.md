# Parked: the testers' words, corrected (Legal, 2026-11-25, RL-276)

`testers-words.patch` changes two files that **must land together**, because Tools' self-test holds every string in the first against the second:

- `tools/site-tester.json` (Tools' file: needs Tools' yes);
- `docs/legal/tester-folder-notices.md` (Legal's page).

**What changes:** two sections' words only. "Who this build is for" now names itch.io and the account name. "What leaves your computer" now says what the report folder holds, that reports are read with the help of AI services run by another company, and the deletion promise. No code, no new section, the placeholder unchanged, `draft` stays true.

**Checked:** `git apply --check` passes on main at f1069d82; the package's own shape check passes on the patched words; every string is on the patched page; the assurance words are absent. Tools' full self-test was not run on the patched tree.

**Depends on Orb:** the sentence beginning "If you ask, Orb will delete" assumes Orb says yes to the deletion promise. If Orb says no, it is replaced by nothing before `draft` goes false (Legal re-cuts).
