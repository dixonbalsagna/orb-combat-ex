# A1: Art Director

Leads: none
Supports: A-PROCESS-03, A-RENDER-04

Draft for the Executive Producer (EP) to send once Orb approves the path to Alpha. Nothing here is decided until then.

Goal: The repository holds Art's real state (every changed art file is either committed or deliberately left out), and the crater a player sees after a beam is checked by an artist's eye before it becomes the default.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A1, step 2 of "The order inside A1"; decision 3); `docs/ep/alpha/audit-2026-11-13/00-baseline.md`; `docs/ep/alpha/audit-2026-11-13/02-areas/PROCESS.md` and `RENDER.md`; `docs/ep/taste.md`.
- A-PROCESS-03 (EP leads): the working tree carries 14,805 uncommitted paths, so the repository does not hold the project's state. Evidence: `docs/ep/alpha/audit-2026-11-13/00-baseline.md:13`; `docs/ep/alpha/audit-2026-11-13/baseline-status.txt`; `docs/ep/alpha/audit-2026-11-13/reads/RR-09.md:8`. The baseline's list shows changed files under `art/concepts/biomes/` and `art/concepts/energy/` and in `docs/art/`.
- A-RENDER-04 (Rendering leads): the black, flat-brown crater has a still and a proven cause (a beam's scorch filled per vertex on coarse tiles); the fix is parked (finished work waiting outside main). Evidence: `docs/rendering/runs/1931a0f8/terrain-step0-a.txt:26`; `docs/tools/runs/1931a0f8/terrain-step0-stills.md:12`; `docs/rendering/pending/crater-look-default/README.md:3`. Orb's wider ask ("workshop this, and improve the system", `docs/ep/vision.md:1695`) is scoped apart and is after Alpha on the path's recommendation.

You own: `art/`, `docs/art/`.
- `data/art/` has no owner line: ask under NEEDS FROM EP for a grant: `data/art/` (only to say keep or ignore for the changed files there; the EP commits).

Acceptance criteria:
1. (A-PROCESS-03) One list for the EP covering every uncommitted path under `art/`, `docs/art/` and `data/art/` in the baseline's list: keep (finished or wanted, with one line on what it is), ignore (generated or scratch, with the pattern to ignore), or not mine. You change no git state; the EP commits or ignores from the list. Checked by the EP's count of paths still unsorted: none under your folders.
2. (A-PROCESS-03) Any in-progress character art in the list is marked so the EP keeps it out of anything public.
3. (A-RENDER-04) When Rendering's before-and-after stills of the crater are saved, one paragraph from you, through the EP: does the crater with the black fill removed fit the art direction for scorched ground on each biome it was shot on, and what, if anything, is wrong that is cheap to fix now. Wider ideas go in the ideas log, not into this landing.
4. (Look gate, ADR 0010) You change nothing a player sees in this brief. If the crater note leads to an art change, it ships with a side-by-side against the reference build before the EP commits.

Constraints:
- Tokens: no rows of your own in A1; allow about 0.25M as an estimate for the supporting work.
- State hash: nothing here changes the sim's state fingerprint.
- Machine: no Godot runs are needed; pictures of concept files come only through Tools' launcher (no browser of your own), one capture at a time.
- Determinism and data: art numbers that the game reads live in data; a data shape change updates its schema in the same commit.
- Originality: every design is our own; nothing from an existing franchise.
- Orb's rules: in-progress character art is never public; no masks (faces and silhouettes are refined instead); destruction is big and lasting; plain words; the AI disclosure goes wherever the game's art is shown.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Item 1 is step 2 of A1's order and is wanted in the first two days: the switch groups cannot start landing until the working tree is committed or deliberately ignored. Item 3 waits on Rendering's stills (A-RENDER-04). Waiting on this: A-PROCESS-03 closing, and with it every landing in A1.
