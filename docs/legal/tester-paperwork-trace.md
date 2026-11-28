# Tester paperwork: sources, and what closes G9 and G14

Legal, 2026-11-28 (A2 job 8; RL-297). For the team. A screen, not legal advice. **Bold** in the last column means Orb must answer.

## The note (`alpha-tester-note.md`)

| Lines | From | Orb |
|---|---|---|
| Flashing, do not play, the lock | RL-264, RL-275 | G14 read |
| How to stop | RL-297 | **New** |
| Private early test; the AI line (word for word); adults | RL-261, RL-264 | G14 read |
| The one-reply acknowledgement | RL-266 (G16), RL-273 | **New** |
| What you may do; rights; ideas; end of test | RL-260, RL-264, RL-265 | G14 read |
| Nothing leaves unless you send it | RL-264, RL-276 | G14 read |
| itch.io (word for word from `page-fixed-lines.md`) | RL-271 | **Changed** |
| Report folder; AI services | RL-273, RL-276 | **Yes** |
| Discord; no personal details | RL-273 | G14 read |
| Deletion within 14 days | RL-273, RL-276 | **Yes or no** |
| Credits | RL-264 | G14 read |

Taken out: the two-PC sentence (the testers' build has no network code; G10, G19) and the music sentence (no music ships without its own row; RL-264). The "words in the new menus" page still shows an older itch.io line and a shortened AI line.

## The sheet (`tester-sheet-legal-rows.md`)

| Row | From | Serves |
|---|---|---|
| No name or signature | RL-267 | G22 |
| Stop line | RL-264, RL-297 | safety |
| L1 adult, read | RL-261, RL-273 | G16 |
| L2 warning and lock | RL-264, RL-275 | G6, G7, X-19 |
| L3 close from first screen | RL-297 | X-19 |
| L4 pause, then close | RL-297 | X-19 |
| L5 files checked | RL-273, RL-276 | G13 |
| L6 nothing public | RL-264, RL-265 | privacy of the test |

**L4 on a Deck** passes only when a person does it on a real Steam Deck, with the testers' package and the built-in controls. No other machine stands in. Record "a Steam Deck", the archive's checksum and pass or fail under `docs/legal/runs/<sha>/`; the filled sheet stays in `.private/testers/`. A fail stops further Deck matches until fixed. L4 needs a match, so it waits on G21's Linux reading (RL-280); L2 and L3 need none. The code has these routes; none has been seen on a Deck.

## What closes G9 (README and NOTICES)

1. Orb's yes to the friends' text, and yes or no to deletion. On no, the sentence comes out of the note, `tester-folder-notices.md` and `tools/site-tester.json` together.
2. Tools sets `tools/site-tester.json` to `draft: false`.
3. Orb's line in `.private\testers\report-channel.txt`.
4. The shader notices or replacements (RL-289, RL-292, RL-294, RL-295).
5. Tools' `verify` output saved for the candidate.

## What closes G14 (paperwork)

1. Orb's read of the note, README text and permission page, recorded in `vision.md`.
2. The deletion answer, recorded.
3. Legal's read of the finished itch.io page (RL-272).
4. One row per item in `docs/legal/runs/<sha>/`.

Orb's answers can all be given now, before any candidate exists.
