# Change control: how a new idea waits

**Status: proposed, waiting for Orb's yes.** The rule below is copied from the path to Alpha ("Change control", docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md) and put in plain words. The Executive Producer records Orb's yes here once it is given; the freeze half is decision 23 in the path's table. Written 2026-11-13 by Production Operations. Row: A-PROCESS-01 (exit line X-33).

**The point.** Orb has a new idea most weeks, and every one of them is good enough to want. Each idea, though, costs tokens, weeks and sometimes a golden window (a landing that changes how the game plays, so that saved replays stop working). This page gives every idea a written place to wait, with a price tag, until Orb says yes. No idea quietly becomes build work, however small it looks.

Where ideas wait: [ideas-log.md](ideas-log.md). Orb's earlier note on special moves stays where it is: docs/ep/ideas/special-moves.md.

## Words on this page

- **The push:** the six milestones A1 to A6, from now to the Alpha candidate.
- **Golden window:** a landing that changes the simulation's fingerprint. There are four (GW1 to GW4). GW3, in A4, is the last that takes rule changes.
- **Fingerprint:** a short number the simulation makes from a match; if a change moves it, the game plays differently.
- **Size class:** S is about 0.25M tokens, M about 1.2M, L about 4M, XL about 8M. These are the register's classes: sizes, not quotes.
- **"Workshop this":** a page or a throwaway toy that explores the idea. It is never a change to the game.
- **Row:** one line of the audit's gap register; a milestone's row list is what it has promised to close.

## During the push (A1 to A6): the six steps

1. **Write it down the day it is said.** Every new idea, Orb's or anyone's (a director, a tester, a report), goes into the ideas log that day, in the speaker's own words, with the date.
2. **The Executive Producer prices it within one working day.** One line is added to the log: **now**, **at the next milestone** (named) or **after Alpha**; plus a size class, and whether it changes the fingerprint.
3. **Nothing from the log is built until Orb has seen that line and said yes.** Nothing is built silently, including by a director who thinks it is small.
4. **"Now" is allowed only if all three of these hold:**
   - it fits inside a row that is already open in the current milestone;
   - it does not change the fingerprint, or the milestone has an open golden window that takes rule changes (GW2 in A3, GW3 in A4);
   - its cost comes out of that milestone's budget, with the row it displaces named.

   After GW3 closes, an idea that changes a rule waits for after Alpha.
5. **A milestone's row list changes only at its start.** If something comes in mid-milestone, something of the same size goes out, and the PLAY THIS page (the note that tells Orb what to try in each build) says which.
6. **Testers' findings follow the same rule, with one exception:** a finding that stops a newcomer step (cannot install, cannot start, cannot finish a match, cannot report) is fixed in the current milestone without waiting.

**Each spike's page counts as a change request.** A spike is a small trial on a scratch copy that shows how big a row really is. If its page says a row is a class bigger than the register thought, the Executive Producer brings Orb the choice before the row starts: the smaller version, a later date, or something else moves out.

## Which door is open, milestone by milestone

Rule 4 applied to the path (the A1 and A2 readings are Production Operations' reading of rule 4; the Executive Producer confirms):

| Milestone | Can a "now" idea change how the game plays? | Why |
| --- | --- | --- |
| A1 | No, apart from the riders already listed for GW1b | GW1 makes main the game Orb plays; it takes only the listed small fixes |
| A2 | No | No golden window |
| A3 | Yes, if it fits an open row and GW2 is still open | GW2 takes rule changes |
| A4 | Yes, until GW3 closes, on the same conditions | GW3 is the last window that takes rule changes |
| A5 | No | A5 is words, pictures and a last numbers window (GW4, data values only) |
| A6 | No | The candidate is frozen |

An idea that changes no rule (words, a still, a tool, a check) can be "now" in any milestone if it fits an open row and pays from that milestone's budget.

## After A4

No rule changes are taken at all. A5 is words, pictures and one last numbers window. A6 is frozen.

## After the freeze (the day A6 passes)

A new idea is either logged for after launch, or brought to Orb as a scope change with its cost in tokens, weeks and golden windows, and what it would re-open. Only Orb lifts an idea in. These are not scope changes and carry on: fixes to things that are broken, tuning inside the data's existing shape, and polish that passes the look gate.

## The standing exception

Anything that touches a player-safety check, a Legal flag, spending or something public stops and goes to Orb as one plain question, exactly as it does today. This page never delays that.

## How it runs day to day (proposed practice, beyond the path's text)

The Executive Producer:

- Keeps the log current and prices each new line within one working day (step 2).
- Asks Orb about priced lines in the same sitting as the milestone's other questions, so Orb sees them together.
- Records Orb's answer in the log's last column; an answer of yes changes the milestone's row list only through step 5.
- Sends Production Operations each new line and each answer, so the tracker's counts stay true.

## Proposed pointer for the playbook (the Executive Producer's file)

Production Operations does not edit the playbook. The line proposed for docs/ep/playbook.md, under "Rules of engagement":

> 9. **Change control.** Every new idea goes into docs/production/ideas-log.md the day it is said; price it within one working day (now, a named milestone, or after Alpha; size class; moves the fingerprint or not); build nothing from the log until Orb has said yes. Rules are in docs/production/change-control.md.
