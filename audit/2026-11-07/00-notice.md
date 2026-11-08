# Notice of independent audit

- Opened: 2026-11-07 22:41 UTC (14:41 PST), by Orb typing `/audit full workflow` in a new session, renamed "Independent Audit".
- Scope: full (A1 to A9). Orb approved a multi-agent Workflow for this audit (the word `workflow` in the command).
- HEAD at opening: 53b6df820b23934617b2f1b2aed01ddba015b69c (Rendering: plan for drawing the partner's fight in a 2v2 (RL-249's drawn case))
- Evidence baseline: ~/.claude/skills/audit/baseline-2026-11-07.txt, taken 2026-11-07T22:03:01.071Z, head 8d9b98a242f925458da9063529ca7a8be96597b1 ("Legal: RL-255 clears the air-brake looks with conditions"), 13,835 uncommitted paths fingerprinted by blob hash.
- All verdicts are measured against the baseline commit 8d9b98a2 plus the fingerprinted working tree, unless a finding says otherwise.

## The directive as served to the EP

```
NOTICE OF INDEPENDENT AUDIT: DIRECTIVE TO THE EXECUTIVE PRODUCER

To: Meridian - Executive Producer
From: the Independent Auditor, commissioned by Orb
Served: by Orb in person, on receipt. Effective immediately.
Evidence baseline: commit 8d9b98a2 plus a content fingerprint of all 13,835 uncommitted paths, taken 2026-11-07 22:03 UTC, before this notice was served, and held outside the repository.

1. WHAT THIS IS
Orb has commissioned an unannounced, independent audit of the project's release safety. The question is simple: which of the safety concerns recorded in this project are real and would hurt players, Orb or the project at public release, and which are overstated, misfiled or unfounded? The audit also covers risks nobody has recorded, and whether the internal checks actually test what they claim.

The auditor works in a session titled "Independent Audit". It is outside the chain of command in CLAUDE.md: it reports to Orb only, and you and every director are being audited, Legal and QA included. This is not a judgement on anyone's effort. It is a check on the evidence.

2. WHAT YOU DO NOW
a) Acknowledge. Reply to the "Independent Audit" session with one line naming yourself as the single point of contact. The auditor does not talk to directors; all questions come to you.
b) Freeze the safety record. From this moment, do not edit, rewrite, delete, move or re-commit any existing safety record: docs/legal/, docs/accessibility/, qa/known-bugs*, docs/qa/, tools/flash/, .github/workflows/, net/ and docs/net/, docs/decisions/, the director charters' standing rules, and any pending or scratch folder that holds safety evidence. No "tidying up", no closing old rows, no re-running a gate to replace a failing result with a passing one. Normal development may continue; the audit wants to see the project as it really runs.
c) If something must change in a frozen path for a genuine, already-planned reason, it may, but log it in the disclosure pack (item 8) with the reason and commit id. Undisclosed changes to the safety record after the baseline are themselves a finding.
d) Tell any active director who might touch those paths, in one line: "An independent audit is open. Point, don't fix: leave safety records as they are." Nothing more.

3. THE DISCLOSURE PACK (within one working session)
Write it to audit/disclosure/ at the repo root. That folder is the only part of audit/ you may write to; never edit anything else under audit/. Pointers, not essays: give paths and one line each. Do not summarise what a record says; the auditor reads the record itself.
 1. Safety claims index: every place the project records a safety concern, warning, gate, waiver or sign-off.
 2. Open blockers: everything you currently believe blocks a public release, with source path and owner.
 3. Gate inventory: every automated check that claims to protect players or the project (CI jobs, lints, self-tests, release passes), what each claims, and whether it runs on the real build or on stand-ins.
 4. Waivers and overrides: every safety flag that was deferred, waived or overruled, by whom (Orb, Orb 2, the stand-in, you), and where that is recorded.
 5. Rule origins: for each standing safety rule, whether it comes from an outside source (a law, a platform policy, a published standard; give the source) or was written inside the team.
 6. What is live now: every build, page, download or LAN folder that anyone outside this PC can reach today, with its commit.
 7. Data flows: anything the shipped game or its page sends off the machine, writes to disk, or reads from outside its own files.
 8. Post-notice changes: anything in a frozen path changed after this notice, with reason and commit.

4. ANSWERING THE AUDITOR
Questions arrive as numbered information requests (IR-01 and on). Answer each within the same working session with pointers to primary evidence: files, lines, commits, command output. "I don't know" is a good answer. A guessed or invented answer is not: the audit records any answer that does not hold up. Do not prepare, stage or polish evidence; hand over what exists.

5. WHAT YOU DO NOT DO
- Do not fix findings during the audit, even small ones. Fixes come afterwards through a corrective directive that Orb will hand you.
- Do not edit anything the auditor writes, or the auditor's kit outside the repo.
- Do not rewrite git history, force-push, or delete branches, pending folders or scratch evidence.
- Do not ask the auditor to look at a newer version instead of the baseline.
- Do not route audit work to directors beyond asking them for pointers.

6. MACHINE AND COST
The auditor follows every machine rule in CLAUDE.md and reads before it runs anything. You need not start any test runs for it. Expect a handful of information requests, not a stream.

7. WHAT HAPPENS NEXT
The auditor reports to Orb. Orb hands you a corrective directive: real problems ranked by severity, false alarms to clear, and changes to how safety is checked. You reply to Orb with a plan (owner and order for each item) within one working session of receiving it.

Acknowledge receipt now.
```
