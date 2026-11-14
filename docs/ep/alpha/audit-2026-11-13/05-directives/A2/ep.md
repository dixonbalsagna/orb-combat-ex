# A2: Executive Producer

Leads: A-ACCESS-04
Supports: A-LEGAL-03, A-LEGAL-07, A-PERF-01, A-TOOLS-02

Goal: Nobody outside the trusted two plays a build until every safety gate has a saved record on its commit, and the open corrective row on access settings says truthfully which parts are done.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A2, "If a milestone misses its exit", "Change control"), `02-areas/LEGAL.md` (the gate list G1 to G20), `02-areas/ACCESS.md` (F-ACCESS-06), `docs/ep/corrective-plan-2026-11-07.md`, `docs/ep/playbook.md`, `docs/decisions/0010-look-gate.md`, `docs/ep/taste.md`.
- A-ACCESS-04: corrective item CD-14 has an empty progress cell and no commit or record names it since 2026-11-07, although one of its four parts (a brace button on pads) is done on the Arena layout. Evidence: `docs/ep/corrective-plan-2026-11-07.md:22`; `reads/RR-09.md:32`; `data/input/layouts.json:136-140`; commit 8db493cb.

You own: `docs/decisions/`, `docs/ep/`, and the shared files.

Acceptance criteria:
1. (A-ACCESS-04) CD-14's row in `docs/ep/corrective-plan-2026-11-07.md` states each of its four parts as done (with the commit and file line), open (with its owner and milestone) or dropped (with the reason), from Accessibility's read. The Hit pause slider's part follows Orb's answer (hide, recommended, or wire). Check: the row; Accessibility's report it was filled from.
2. (routing, exit line X-02) A build goes to a friend only when Legal's gate page shows every safety gate and blocker green on that commit with records under `docs/*/runs/<sha>/` (corrective item CD-22), and Orb's one-line approval of desktop test builds for named testers is recorded in `docs/ep/approvals/desktop-test-builds.txt` after the gates are green, not before. If a gate is still red at the end of A2, the Deck session waits; that goes to Orb as one question with three choices (wait, ship short with the line carried forward by name, or cut something).
3. (routing) Each grant asked for in this milestone's briefs is ruled on in writing: the paths with no owner (`docs/tools/`, `docs/qa/`, `project.godot`, `render/tools/`, `data/input/`) and the cross-director files (`render/core/main.gd`, `ui/`, `net/lan.gd`, `.github/`).
4. (routing) Every visible change in this milestone is looked at as a side-by-side against the reference build before it is committed (the look gate, ADR 0010); a change that looks worse goes back whatever its gate says.
5. (routing) The friends' two sheets, bench files and report files are collected by you from Orb, stripped of anything that names a person, and handed to Performance, Controls, Audio and UI. Findings that stop a newcomer step are fixed in this milestone from the 6M fix reserve; the rest follow change control.
6. (routing) The PLAY THIS page for the A2 build says what is new (nothing in the fight; the report, the crash file, the pause on an unplugged pad) and what to try, and the Alpha date is re-estimated from the spikes and the first real Deck readings.

Constraints:
- Tokens: about 0.25M as an estimate for the lead row (one S); reviews, gate runs and routing are on top, about a third of each week by the path's own assumption.
- State hash: no row in A2 changes it and A2 has no golden window: refuse any landing that moves the hash and place it in GW2 (A3's window, "The fight's rules").
- Machine: headless Godot only; at most 3 Godot processes for a short gate while long runs are going; long runs at below-normal priority; verify a build from its own packed data, not from the switch list.
- Determinism: every landing keeps seeded RNG, fixed step and no rendering state in the sim; data shape changes carry their schema in the same commit; read CI after every push.
- Originality: nothing from an existing franchise in any landing.
- Orb's rules: one clear question at a time, in plain words; nothing is built from the ideas log until Orb has said yes; forward-facing text is seen by Orb before use; the AI disclosure up front; in-progress character art never public; the topic kept off Orb's page stays off it.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT), as the milestone's closing note to Orb.

Order: A1 must have closed (GW1, "Main is the game", and the one-command desktop build). Criterion 1 waits on Accessibility's read and Orb's answer on the slider. Criterion 2 is the last thing in the milestone before the friends' session; A3's landings wait on nothing here, and its directors are already working ahead behind switches.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- No build is uploaded to a channel an outside tester holds a key to, or sent to one, unless every gate on the "before an outside tester plays" list (X-02) is green with saved records on that commit. This is an exit line of this milestone. (MIS-01, ORD-02, COS-01, ORB-01, PC-01)
- A tester's raw report and speed-test files are never committed: they live in a git-ignored folder, and only the team's own reading of them (numbers, no quoted notes) is saved under `docs/*/runs/<sha>/`. A tester's request to delete is carried out on that folder and on the report server. (PC-02)
- Legal's ruling splits two acts: "build and check a tester package, hand to nobody" needs no approval; "hand out commit <sha>" needs Orb's recorded yes, checked at the upload step. Do not record the yes early to break the loop. (PC-04)
- A change to the ordinary look of the beam clash or of a cut goes to Orb as two clips and one question (which looks better, or the same?), with no numbers; you are not the last judge of it. Whether a locked package may go out with the ordinary look's reading still red is Legal's ruling. (ORB-02)
- A2's rows may close before the friends' files arrive; the Deck's first readings (X-18, X-19, X-24) are then carried by name into A3. Your page lists the machine's long runs and quiet windows. (ORD-10, COS-09)
