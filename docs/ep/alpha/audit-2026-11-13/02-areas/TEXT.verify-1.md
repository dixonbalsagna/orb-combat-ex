# TEXT: verifier 1

Read-only check of the TEXT area's findings at 8901d351. Each finding was read against the files it cites and against anything that could make it false.

| Id | Verdict | New severity | What I checked | Note |
| :-- | :-- | :-- | :-- | :-- |
| F-TEXT-01 | corrected | unchanged (major) | `docs/ui/strings.md:3`, `:5`, `:9-14`; a count of its table rows (1115) and of rows with keep, rewrite or cut in the Mark column (0); `ui/tools/strings_inventory.py:169`, `:179`; `docs/ep/vision.md:951`; `docs/ep/vision.md:1191-1198`; `docs/design/brawl-second-pass.md:1352`; `docs/ui/plain-words.md:17`; `git log -- docs/ui/strings.md` (last regenerated in 6a30b4c9, same commit as the last `ui/data` change) | The list holds 1115 rows and none carries a mark, and the rule at `vision.md:951` is as cited, so the substance holds. One fact is too absolute: Orb's marks on three on-screen hints are recorded at `docs/ep/vision.md:1191-1198` (hint 8 kept; hints 9 and 10 sent for rewrite per `docs/design/brawl-second-pass.md:1352`), so the gap is "no record for the notice, menu, how-to, settings and all but three hints". |
