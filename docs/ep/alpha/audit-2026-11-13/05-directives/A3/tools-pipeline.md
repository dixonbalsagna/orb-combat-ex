# A3: Tools & Pipeline

Leads: none
Supports: A-CONTROLS-05, A-AI-07, A-MODES-04, A-LEGAL-04, A-PERF-02, A-WORLD-03

Milestone A3 is "The fight's new rules, and LAN inside the game" (docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md). This brief is ready to send once Orb approves the plan; nothing in it is decided until then.

Goal: One command still makes the build Orb plays, now with LAN inside it for the trusted two and without it for outside testers, and the new rules are checked in CI on Windows and Linux.

Context:
- Read first: tools/desktop-package.mjs lines 211, 219 and 348; export_presets.cfg lines 55 and 101; .github/workflows/ci.yml lines 221 and 353-356; tools/feel/ledger.mjs; record docs/tools/runs/1931a0f8/b1-ledger-1229.txt; net/tools/lan_kit.mjs lines 28, 92-101 and 120; tools/world-checks.json.
- A-CONTROLS-05 (led by Encounter Systems): the latest count of unanswered presses is from an older build (225 of 760), and the ledger's counting rule changed on 7 and 8 November, so counts across builds are not like for like. Evidence: tools/feel/ledger.mjs; the record above; data/director/interrupts.json:611.
- A-AI-07 (led by Encounter Systems): the hold-and-release check on the computer's beams is local only. Evidence: sim/director/tools/beam_ai_check.gd:2-6.
- A-MODES-04 (led by Netcode & Online): LAN reaches the game only through text patches the LAN kit makes to a scratch copy. Evidence: net/tools/lan_kit.mjs:1-3, :11-14; export_presets.cfg:55, :101.
- A-LEGAL-04 (led by Legal): no ruling or package covers who gets LAN; the locked package refuses any network code. Evidence: tools/desktop-package.mjs:211, :348.
- A-PERF-02 (led by Netcode & Online): LAN has no Linux build path. Evidence: net/tools/lan_kit.mjs:120; export_presets.cfg:101.
- A-WORLD-03 (led by World & Environment): terrain step 2's park carries a patch to your lint (tools/lint-determinism.mjs) and lines for tools/world-checks.json (docs/world/pending/globe-step2/README.md).

You own: tools/, build/, .github/
- ask under NEEDS FROM EP for a grant: export_presets.cfg (no director owns it), agreed with Netcode through the EP so only one of you edits it
- ask under NEEDS FROM EP for a grant: docs/tools/ (no director owns it) for run records

Acceptance criteria:
1. Supports A-MODES-04 and A-LEGAL-04. The one-command desktop build makes two packages from one commit: the trusted-two package with LAN inside it, and the outside-tester package with no network code and no LAN row. The package step refuses an outside-tester package that contains either, and refuses to make the trusted-two package without Legal's written exception on file. The refusals are shown by a self-test and saved under docs/tools/runs/<sha>/.
2. Supports A-PERF-02 (smaller version): the Linux desktop build includes the network code and the two-program check passes on Linux in CI. Full version if Orb declines the proposal: a Linux LAN package for a real Deck session.
3. Supports A-AI-07. sim/director/tools/beam_ai_check.gd runs in CI on every push, with a verdict line, and fails the job when it fails (no "report only").
4. Supports A-CONTROLS-05. The ledger uses the one counting rule Controls & Game Feel writes in docs/controls/refusals.md, prints the rule's version in its output, and is run on the A3 build over the same script as the older record; the output is saved.
5. Supports A-WORLD-03. The lint patch from World's park is reviewed and applied by you first (the park's order), with its self-test passing, and the world-check lines are added with --run verdicts.
6. The mode smoke suite (built in A1) gains LAN 1v1 on Windows and passes there, and still passes for solo and two players on one PC on Windows and Linux (exit X-05, partial, must pass).
7. The gates on A2's "before an outside tester plays" list are re-run on the A3 commit, each with a saved record under docs/*/runs/<sha>/, because the new beam changes what is on screen. The A3 build goes to the two friends as an update through the itch.io channel, as the outside-tester package.

Constraints:
- Tokens: no lead rows in A3; supporting work is not sized in the register. Say in your report what each piece cost.
- State fingerprint: your work does not change it. CI must be read after every push in golden window GW2, "The fight's rules" (a golden window is one landing that changes the sim's state fingerprint, after which the saved reference matches are re-recorded once): it checks the head commit's data only.
- Headless Chrome starts only through your own launcher, with a time limit, at below-normal priority, with the session's name in its profile folder. A flag with a space in it breaks the capture job and pops a prompt: never pass one.
- Nothing in a package or a record may carry a player's address, account name or file path. Uploading to itch.io is Orb's action or done on Orb's word for that upload.
- Machine rules: Godot runs headless only; at most 3 Godot processes for a short gate (never more than 6 in one session); a run longer than about ten minutes starts at below-normal priority, and a reading taken while the machine was saturated is marked invalid, not reported; pictures and clips come only through Tools' launcher (tools/machine/capture.mjs), one capture at a time; stop only your own processes, by PID; check nothing you started is still running before you end a turn.
- Originality: every name, move, look and line is our own; nothing from an existing franchise.
- A director never briefs or messages another director: anything you need from one goes under NEEDS FROM EP and the EP routes it.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT). Keep it short. Report, then freeze the files you reported until the EP confirms the commit.

Order: Before this starts: the one-command desktop build (A-TOOLS-01), the corrected ratchet (A-ENERGY-06), the mode smoke suite (A-MODES-08) and the itch.io rehearsal (A-TOOLS-02) from A1 and A2. The lint patch goes first of all, because World's step 2 waits on it. The two-package step waits on Legal's exception and Orb's decision 13. Waiting on this: Netcode's A-MODES-04 and A-PERF-02, Legal's A-LEGAL-04 check, and the A3 build reaching Orb and the two friends.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- Every upload to itch.io is Orb's own action, listed on Orb's page for this milestone; no session uses Orb's sign-in, so "or the EP" does not apply. (PC-08)
