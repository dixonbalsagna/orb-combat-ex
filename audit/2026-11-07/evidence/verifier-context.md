# Context for verifiers (written by the Independent Auditor, 2026-11-07)

The auditor is outside the project's chain of command and reports to Orb (the owner) only. The EP and every director, Legal and QA included, are being audited. This file holds what the auditor has already established from primary evidence, the verdict rules, and the files you may use as pointers.

## Established facts (primary evidence in this folder)
- Baseline: commit 8d9b98a2 (2026-11-07 22:03Z). HEAD is 53b6df82, which only adds docs/rendering/2v2-drawn-plan.md. Safety records were not edited after the baseline (post-notice-changes.md).
- The GitHub repo dixonbalsagna/orb-combat-ex is PUBLIC, so every committed file can be read by anyone. Orb's ruling: docs/ep/vision.md:80 ("Stays public so Orb can share the prototype with friends"), 2026-09-29.
- GitHub Pages is live. The / page is a holding page (live-site-index.html). /play/ serves a PLAYABLE web build of pinned commit 257a766c (tools/site.json "pin"), behind a click-through flash warning (live-play-index.html; words in tools/site-interim-owner.json). The interim is "owner-approved" by Orb on 2026-10-18 and expires 2026-11-15. Reduce flashing is locked on in that build. /bench/ and /band/ serve the holding page. The site was last deployed 2026-11-05 from commit 72a4d1e4.
- CI is dead: .github/workflows/ci.yml has run no job on 37 pushes since 3c9005ac (2026-11-06) because of unquoted ': ' in step names at ci.yml:226, 240, 263 and 277 (ci-dead-root-cause.txt). The deploy job needs every job, so nothing has deployed since, and a take-down (tools/site-offline.mjs) cannot deploy either. The only CI still running is web-parity.yml.
- Private builds: LAN folders built from main a8bc66e2 were given to Orb and a second player, "Orb 2", on an old PC on the home network. Orb ruled on 2026-11-07 that Orb 2 has Orb's standing on safety for private builds (docs/ep/vision.md, last block; RL-253).
- The EP's disclosure pack is in audit/disclosure/ (pointers only; it is the audited party's account, not evidence).
- Earlier helper output you may use as POINTERS (re-check anything you rely on): evidence/sweep-a1.json to sweep-a78.json (an independent blind sweep of the code), evidence/gates-flash.json and gates-other.json (what each automated check really tests), evidence/claims-inventory.json (the claims, with every source).

## Rules
- READ-ONLY on the project. You may write only the output files your prompt names under audit/2026-11-07/evidence/, plus optional proof files named evidence/AC-###.txt (or evidence/G-##.txt) holding command output you ran. Never change git state. Never use SendMessage or contact other sessions.
- The shipped code is the COMMITTED tree. For the live public build, read the pinned commit with `git show 257a766c:<path>`. For private LAN builds, read a8bc66e2 or HEAD.
- Machine: do NOT run Godot, Chrome or any browser, npm install, or any long job. Short read-only shell commands (git, grep, node one-liners, gh read-only API, curl GET of the public site) under 2 minutes each are fine. Never scan outside the repo.
- Evidence: every path:line you cite must be one you opened in this run. A document saying something is true is a CLAIM, not evidence, even if Legal or QA wrote it. Never invent a path, function, number, law, clause or platform rule.
- External rules (WCAG, Steam, itch.io, Suno, GitHub, FTC, COPPA, GDPR, USPTO, IARC, EU AI Act, licences): check the primary source with WebSearch/WebFetch; give the URL, the access date 2026-11-07, and one quote under 15 words. If the primary source is unreachable, say so.
- Do not write franchise character names. Say "a well-known franchise term" and quote the project's own term. Name a franchise or company only where a legal point depends on it.

## Verdicts (exactly one per claim)
- CONFIRMED: real, traced or reproduced in primary evidence, and it would matter at public release (or matters now, because the repo and /play/ are public).
- CONFIRMED-MINOR: real, but the release harm is negligible or already mitigated by something that demonstrably works.
- OVERSTATED: a real kernel with inflated severity or scope: a private-build issue dressed as a release blocker, a standard applied stricter than written while called "the standard", a one-in-a-million path treated as certain.
- UNSUPPORTED: no evidence either way; the claim rests on assertion and needs a test, not a belief.
- HALLUCINATED: contradicted by primary evidence: the cited file, function, rule, law, standard clause, platform policy, date or number does not exist or says otherwise. Only when you can show what is actually true; if you cannot check, it is UNSUPPORTED.
- MISFILED: real, but not a release-safety matter (taste, Orb's creative direction, team process, dev-machine hygiene, balance) carried in the safety records. Say where it belongs.

Many claims are rules or conditions rather than statements of fact. For a rule, ask: is the danger it guards against real at release, is the rule's stated basis (a law, a standard, a platform policy) real and correctly stated, and is it in force in the code where it says it is? A rule whose basis is an outside standard but which is stricter than that standard is fine as a design margin, and OVERSTATED only if the record presents the stricter number as the standard itself or treats a breach of the margin as a breach of the standard. A rule that is Orb's own creative direction (originality, look) is MISFILED as safety, not wrong: never judge Orb's taste.

## Severity (for CONFIRMED and CONFIRMED-MINOR, and for gaps)
- S1 release-blocking: credible harm to players (seizure risk, code execution, data leak) or serious legal exposure at the first public release, or already, given the public repo and /play/.
- S2 before store: must be fixed before a store release; tolerable in a free public web build with a warning.
- S3 should fix: real, low harm or low likelihood.
- S4 note.
State likelihood (high/medium/low) and evidence strength (reproduced / traced in code / documented only) separately.

## Horizons
private (Orb, Orb 2 and friends) / web (free public web build) / store (Steam and the like) / already-public (harm exists now because the repo or /play/ is public) / none.
