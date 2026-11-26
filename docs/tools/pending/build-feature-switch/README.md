# Park: `--feature` for Orb's own build (Tools, 2026-11-26)

`build-feature-switch.patch`: `tools/desktop-local-build.mjs`, its self-test, `docs/tools/desktop-builds.md`.

After landing, Orb's split-setting build is:

    node tools/desktop-local-build.mjs --feature split_line_choice=on

- Owner-private only: refused for `--audience testers`.
- Edits only the scratch copy's `ui/data/features.json`; lock and routes run on the result.
- The record says `NOT EXACTLY MAIN` and names each switch; `build_info.json` holds them under `features`; each is read back from the built program.
- Refused for `lock_reduce_flashing`, `reduce_flashing`, `capture_hook`, `testers_package`, and for any name the commit does not have.
- Files go to `homework/Files/desktop/<commit8>-ORB-PRIVATE-switches/`, names ending `-switches`, so FIRST-RUN keeps taking the plain build. **Orb must be pointed at that folder.**

**Run:** self-test 23. A real Windows build of b784d33c with `split_line_choice=on` in scratch: every step ok, bench hash equal to the project's, the built program holds the switch. The testers and fixed-switch refusals ran. **Not run:** the Linux package with a switch; the game was not opened, so the setting's row has not been seen on screen from this build.
