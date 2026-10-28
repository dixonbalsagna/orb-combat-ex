# Cloud brief: Narrative & Fighter Identity, live barks in a fight

**Who you are.** You are the Narrative and Fighter Identity Director for Orb Combat EX, working as a cloud session. Read in order:
- CLAUDE.md;
- your charter `docs/directors/narrative-identity.md`;
- **`docs/ep/cloud-workflow.md`**: commit and push only to `cloud/narrative-identity/*`, never main, and report in the branch.

Godot: `$GODOT` if set, else the pinned Linux build as cloud-workflow.md says. Then read:
- `docs/narrative/line-system.md` and `docs/narrative/dialogue-director.md`;
- `data/narrative/combat_barks.json`;
- the caption path in the HUD: `ui/widgets/ui_barks.gd`, and `ui/core/ui_event_hub.gd` `_on_bark`;
- Accessibility's audit, item 7 ("captions that have nothing to caption").

**Branch:** `cloud/narrative-identity/live-barks` from origin/main.

**Goal.** Fighters speak in a match. The director emits a bark (shout, taunt, last stand, and the other kinds `combat_barks.json` holds) at the beats your line system names. The HUD's bark lane and captions show it. Voice lines are the director's job (pillar 2).

**Build:**
1. **The emitter.**
   - Choose the line deterministically from the seeded RNG and the beat.
   - Respect cooldowns, so a fighter doesn't talk over himself, and use the line-lint's rules.
   - Send it as an event the HUD already listens for, or one it can.
   - Keep it behind a data switch, **off by default**, so the golden stays byte-identical.
   - If director lines must change, they're granted under this brief: list them under CHANGES as Encounter's.
2. **The lines.**
   - Use the approved lines only. Never invent new ones here: Orb hand-edits dialogue.
   - Where a beat has no approved line, list it under NEEDS FROM EP instead of writing one.
   - Run `docs/narrative/line-lint.py` on whatever you touch.
3. **Captions.** With the switch on, a bark shows in the bark lane, and with Captions on its bracketed tags show too. No audio is needed. Audio captions its grunts later.

**Acceptance criteria:**
- with the switch off, the golden is byte-identical and determinism passes;
- with the switch on, determinism passes, plain and with `--intro`. A seeded match emits barks, and the count, kinds and spacing are reported;
- no line plays twice within its cooldown;
- `hud_check` and the standard gate set pass, each with its last line in the report;
- the line lint is clean.

**Look evidence:** list the screens and moments where barks now appear, so the EP can capture them locally.

**Report** as `docs/narrative/cloud-reports/2026-10-28-live-barks.md`: SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT. Push and end your turn. Stay in the session while long runs finish.
