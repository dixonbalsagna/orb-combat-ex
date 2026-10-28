# Cloud brief: Netcode & Online, the AI takes over a dropped player, and the calm turn under rollback

**Who you are.** You are the Netcode and Online Director for Orb Combat EX, working as a cloud session. Read these in order:
- CLAUDE.md;
- your charter `docs/directors/netcode-online.md`;
- **`docs/ep/cloud-workflow.md`**: commit and push only to `cloud/netcode-online/*`, never to main, and report in the branch.

Godot: `$GODOT` if set, else the pinned Linux build as cloud-workflow.md says. Then read:
- `docs/net/rollback.md`, sections 6, 10 and 12;
- your ai-depth report `docs/net/cloud-reports/2026-10-28-ai-depth.md`.

**Encounter's ruling (2026-10-28).** The sim's own in-tick AI (`--ai=sim`) is the online model for an AI opponent. The director decides about 100 `f.ai` branches mid-tick on that tick's plan, so as fixed inputs they'd land a tick late or never. For a dropped player, switch the slot to the in-sim AI at an agreed tick, rather than having one peer drive its inputs. Encounter also audited the mutable director statics in your RISKS, and each is written before it's read in every tick.

**Branch:** `cloud/netcode-online/ai-takeover` from origin/main.

**Build:**
1. **Takeover.** When a peer drops (or a test says so), both sides agree a tick T at least the input delay ahead and carry it in the protocol. From T the slot is the in-sim AI (the same switch newMatch's `ai` flags set), on every peer and every re-simulation. Reverting to the human at an agreed tick is optional; say if you build it. If setting `f.ai` mid-match needs a sim line, it's outside your paths: park that line as a patch under `docs/net/pending/` and say so.
2. **The calm turn under rollback.** `WorldEpoch._plans` and `_jobs` (`sim/world/epoch.gd:21-22`) are derived caches outside the state, made by the warm ticks. Play the `calm` setup with `--ai` and `--ai=sim` across a calm turn, with rollbacks reaching back across the swap. Prove that a re-simulated warm tick or swap gives the same state, or show the divergence and which cache causes it. Read World's code, but don't change it; propose any World fix in NEEDS.
3. **Tests.** Add `--takeover=T` (or similar) to `rollback_check`, with a `--negative-control` where one peer switches a tick late.

**Acceptance criteria:**
- the sim is untouched (or the one parked line), and the golden is byte-identical;
- the takeover's every confirmed tick equals a straight run that switches at T, on lan, p120 and far, for at least 3 seeds, and its negative control is caught;
- the calm setup with both AI modes passes or has a diagnosis;
- the existing rollback, desync, spectator, delay and transport checks pass, as do CI's new `--ai`, `--ai=sim`, depth and planet2 steps;
- the standard gate set passes, each with its last line in the report.

**Machine:** keep long runs to four processes at a time, and stop at 6 CPU-hours.

**Report** as `docs/net/cloud-reports/2026-10-28-ai-takeover.md`: SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT. Push and end your turn. Stay in the session while long runs finish.
