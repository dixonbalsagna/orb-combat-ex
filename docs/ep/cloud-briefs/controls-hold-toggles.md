# Cloud brief: Controls & Game Feel, toggles for every required hold

**Who you are.** You are the Controls and Game Feel Director for Orb Combat EX, working as a cloud session. Read these in order:
- CLAUDE.md;
- your charter `docs/directors/controls-feel.md`;
- **`docs/ep/cloud-workflow.md`**: commit and push only to `cloud/controls-feel/*`, never main; report in the branch.

Godot: `$GODOT` if set, else the pinned Linux build as cloud-workflow.md says. Then read:
- Accessibility's audit `docs/accessibility/audit-2026-10-28.md` (the holds item, NEEDS 5 of its report);
- ADR 0008 (the control scheme);
- ADR 0011 (PC first: keyboard and gamepad);
- how `energy_style` (hold or toggle) is built today, in `ui/data/options.json` and the input code that reads it.

**Branch:** `cloud/controls-feel/hold-toggles` from origin/main.

**Build.** A hold-or-toggle option, built the way energy_style is, for each action that must be held today: Guard, the defensive, charging and manoeuvre stances, and Transform's half-second hold.
- The default stays **hold**, so nothing changes for anyone who doesn't switch.
- Toggle means: press once to start, press again to stop.
- Say what ends a toggled state on its own: a hit taken, a launch, a KO, the stance changing. Match what hold does when the button is let go in those cases.
- Player 2 gets their own setting, as energy_style_p2 does.
- The toggle is input-layer only: it turns presses into the same held state the sim already reads. The sim must not learn a new input.
- If any line outside your paths must change, list it under CHANGES. UI's `ui/data/options.json` rows are granted under this brief.

**Acceptance criteria:**
- the golden is byte-identical; determinism passes plain and with `--intro`;
- a scripted check per action: a held sequence and the matching toggled sequence produce the same sim inputs, tick by tick, and the same state hash;
- `hud_check` and the standard gate set pass, each one's last line in the report.

**Game Design question.** Does a toggled Guard need a balance change, since holding Guard costs a hand and toggling it doesn't? Put it under NEEDS FROM EP with your view. Don't tune anything.

**Report** as `docs/controls/cloud-reports/2026-10-28-hold-toggles.md`: SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT. Push and end your turn. Stay in the session while long runs finish.
