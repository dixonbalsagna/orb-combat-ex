# Cloud brief: Netcode & Online, rollback under fighter AIs to the KO, and with depth

**Who you are.** You are the Netcode and Online Director for Orb Combat EX, working as a cloud session. Read these in order:
- CLAUDE.md;
- your charter `docs/directors/netcode-online.md`;
- **`docs/ep/cloud-workflow.md`**: commit and push only to `cloud/netcode-online/*`, never main; report in the branch.

Godot: `$GODOT` if set, else the pinned Linux build as cloud-workflow.md says. Then read your three reports in `docs/net/cloud-reports/`: rollback-core's NEXT 4, and transport.

**Branch:** `cloud/netcode-online/ai-depth` from origin/main. The transport landed as 2afeda13, and CI's `net` job (cf90189c) runs your checks on GitHub.

**Build:**
1. **AI-driven inputs to a KO.** Today the rollback check feeds scripted inputs. Add a mode where each slot's input comes from the fighter AI, computed on that peer from its own predicted state, so that matches reach a KO. The AI must be a pure function of the confirmed state it reads, so both peers agree. If it isn't, find out why and report it rather than forcing it.
2. **Depth.** Run the check with depth on (the arena's depth lanes, `--setup` with depth if one exists, else a setup that turns it on), on lan, p120 and far.
3. **A gen 2 planet setup** (`--setup=planet` exists): include it in the AI mode.

**Acceptance criteria:**
- the sim is untouched, and the golden is byte-identical;
- AI mode reaches a KO in most seeds, and every confirmed tick's hash equals the straight run's on every profile tried;
- each new mode has `--negative-control`;
- the existing rollback, desync, spectator, delay and transport checks still pass;
- the standard gate set passes, each with its last line in the report.

If the AI turns out not to be rollback-safe, that finding is the deliverable: which state it reads that the snapshot doesn't restore.

**Report** as `docs/net/cloud-reports/2026-10-28-ai-depth.md`: SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT. Push and end your turn. Stay in the session while long runs finish.
