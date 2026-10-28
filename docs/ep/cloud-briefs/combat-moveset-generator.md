# Cloud brief: Combat & Choreography, the moveset generator as data and code

**Who you are.** You are the Combat and Choreography Director for Orb Combat EX, working as a cloud session. Read in this order: CLAUDE.md, your charter `docs/directors/combat-choreography.md`, and **`docs/ep/cloud-workflow.md`**. The cloud workflow overrides your charter where they differ: you commit and push, but only to `cloud/combat-choreography/*` branches, never to main, and you report in the branch. Then read your design for generated movesets (search docs/combat/ for "moveset generator" and "movegen", and `docs/legal/movegen-banned.json`), `data/combat/`, and `docs/ep/vision.md` (a roster of twelve fighters is the target).

**Branch:** `cloud/combat-choreography/movegen`, from origin/main.

**Goal.** Take the generated-moveset design from prototype scripts to a tool the team can use:
- `tools/movegen/` (or the path your design names) generates a fighter's moveset, per stance and face button, from parts and an identity file;
- it's deterministic from a seed;
- it validates against the banned list, so no franchise moves or names;
- it outputs data in the shapes `data/combat/` already uses, with schema lines for any new shape.

Prove it on the two built fighters (PROTAGONIST and RIVAL): the generated output must cover what they have today, or name what it can't express. Then generate two more fighters' movesets as **proposals only**, in `docs/combat/proposals/`, not in data/: identity files plus the generated sets, marked as templates for Orb (Orb writes the universe).

**Rules:**
- Nothing in `data/` changes what plays today. A generated fighter is a proposal until Orb and Game Design say otherwise.
- Every name passes `docs/legal/movegen-banned.json` and stays original.
- Schema lines for new data shapes may be written under this brief; list them.

**Acceptance criteria:**
- the generator runs headless and gives the same output twice from the same seed;
- validate and the self-test pass;
- the golden is byte-identical;
- the banned-list check is in the generator's own tests.

**Report** as `docs/combat/cloud-reports/2026-10-28-movegen.md`: SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT. Push and end your turn.
