# A4: Legal & IP Compliance

Leads: none
Supports: A-MODES-09, A-ANIM-02, A-ANIM-01, A-MODES-02

Goal: Before anyone but Orb and the trusted second player sees two fights drawn on one screen, a new form's look, a second fighter colour or a horde enemy, there is a written reading that each is safe to show and is the project's own.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A4; decision 13); `docs/legal/review-log.md` (rows RL-249, the drawn case with its ten conditions, and RL-253, the trusted second player); `docs/rendering/2v2-drawn-plan.md` (the "Legal's condition" column); `docs/ep/proposals/co-op-2v2.md` (line 37); `docs/legal/name-screening.md`; Art's form sheets and second palettes, and Combat's weak-enemy moveset, as they arrive (the EP gives the paths).
- A-MODES-09 (Rendering leads): drawing both fights puts two fights' effects on one screen; the proposal ties it to one flash register per screen, and it opens to nobody but Orb until the clips pass. Evidence: `docs/ep/proposals/co-op-2v2.md:37`; `docs/rendering/2v2-drawn-plan.md:7-8`; `render/core/main.gd:242`.
- A-ANIM-02 (Art leads): a second body colour per fighter for 2v2 and the mirror match; the plan sends its stills to Legal for an originality look. Evidence: `docs/ui/fighter-select.md:26`.
- A-ANIM-01 (Art leads): one body change per form for each fighter. Evidence: `data/anim/forms.json:3`.
- A-MODES-02 (Game Design leads): the horde's weak enemies are new whole characters with names. Evidence: `docs/combat/henchmen-grades.md:3`.

You own: `docs/legal/`.
- No grant is expected. You point at what must change; the owning director changes it.

Acceptance criteria:
1. (A-MODES-09) A review-log row reads Tools' two-fights-drawn clips (both flash modes, day and night, the two worst cases) against RL-249's conditions and says, condition by condition, met or not met. Until it says met, the brief to Rendering, UI and Netcode stays "bodies only by default; effects private to Orb and the trusted second player".
2. (A-MODES-09) The row states plainly who may see the drawn case at Alpha: if Orb accepts decision 13, LAN is played only by Orb and the trusted second player, and the outside testers' package has no LAN row; couch 2v2 on one PC is in the outside testers' package, so its two-fights picture must pass on the clips before that package is built. This is the gate that can hold A4's build back from outside testers.
3. (A-ANIM-02, A-ANIM-01) A row each for the second palettes and the per-form looks: whole-character likeness, name and trademark only. Pose, gesture and look preferences are Orb's creative rulebook and are not part of this reading and never block the gate.
4. (A-MODES-02) A row for the weak enemies: names screened, whole-character likeness checked, and a line confirming bystanders are never killed in a horde (they bounce or scatter).
5. Each row carries its status, its date and what evidence it read (the clip readings, the stills), and is added to the "before an outside tester plays" gate list from A2 where it applies.
6. Evidence: the readings Legal relied on are saved under `docs/legal/runs/<sha>/` or pointed to by path and commit.

Constraints:
- Tokens: supporting work, counted under the lead rows; plan for about an S (0.25M) as an estimate.
- No change to the sim's state hash; no code or data is changed by this brief.
- Machine: no Godot and no captures of your own; clips come from Tools through the EP.
- Determinism: not applicable; a reading names the commit it was made on.
- Originality: this brief is the check on it for the new looks, names and enemies.
- Orb's rules: Legal screens names, whole-character likeness, trademarks, copied assets and real player safety, and nothing else (Orb, 2026-11-07); a safety concern is met with a warning, a setting or a private build, not by degrading the default look (ADR 0010); the safety record is not edited after the fact; the photosensitivity topic is reported to the EP and is not put in front of Orb; plain words; in-progress character art never goes on a public page.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Before this starts: the A3 ruling that the outside testers' package has no LAN row (A-LEGAL-04). The clip reading waits on VFX's register, Rendering's step B and Tools' clips; the look and name rows wait on Art's sheets and the horde page. Waiting on this: turning the other fight's effects on for anyone, the A4 build going to outside testers as an update, and the mirror match on the fighter pick.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- Add a reading row for the largest horde wave. Henchmen are unnamed: design labels only, so there is no name to screen; read Art's statement of the enemy body's look instead. (MIS-01, MIS-06)
