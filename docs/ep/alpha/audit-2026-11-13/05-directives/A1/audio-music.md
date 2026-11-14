# A1: Audio & Music Director

Leads: A-AUDIO-01
Supports: none

Draft for the Executive Producer (EP) to send once Orb approves the path to Alpha. Nothing here is decided until then.

Goal: A build made plainly from main sounds the same as the build Orb played on 9 November: the sound sets that were on for Orb are on in main's own data.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A1; the A-AUDIO-02 line in "Rows proposed smaller for Alpha"; decision 21); `docs/ep/alpha/audit-2026-11-13/02-areas/AUDIO.md`; `docs/tools/runs/6a30b4c9/pck-verify.txt` lines 93-95 (what the played build's packed audio data says).
- A-AUDIO-01: on main five sound sets are off, so a build made plainly from main has no beam, knock-out, launch, struggle or transformation sound; Orb's build has three of them on only through build switches. Evidence: `audio/data/tug_cues.json:4`; `audio/data/moment_cues.json:4`; `audio/data/carry_cues.json:4`; also `audio/data/coop_cues.json:4`, `audio/data/world_cues.json:4`, `tools/preview/switches.mjs:236-244`.

You own: `audio/`, `docs/audio/`.
- ask under NEEDS FROM EP for a grant: `tools/preview/switches.mjs` (Tools removes each sound row from the build tool's switch table once main's data carries it; you name the rows)
- ask under NEEDS FROM EP for a grant: `tools/schemas/` (only if a data shape changes)

Acceptance criteria:
1. (A-AUDIO-01, X-13) The three sound sets that are on in the played build are on in main's data, with the same values the played build's packed files hold. Checked by the EP's row count and by reading the first desktop build's packed audio data against `docs/tools/runs/6a30b4c9/pck-verify.txt`.
2. (A-AUDIO-01) For each of the two sets that are off in both main and the played build, one written line in `docs/audio/`: it stays off for Alpha, with the reason, or you propose turning it on. Turning one on is a change from the build Orb judged, so it goes to the EP as a proposal with a short clip to listen to, and is not switched on in this brief.
3. (A-AUDIO-01) The audio checks under `audio/tools/` pass on main's new defaults; any check pinned to the old defaults is updated with a reason. Results saved under a `runs/<sha>/` folder in `docs/audio/` (corrective item CD-22; no such folder exists there yet).
4. (A-AUDIO-01) A short listening note for the EP: one match on main's data and the same replay on the 9 November build, saying whether a beam, a knock-out, a launch, a struggle and a transformation can each be heard in both. Nothing is meant to sound different.
5. Sound does not change the picture, so the look gate (ADR 0010) does not apply here. If any change of yours does alter what is seen (a HUD cue, a caption), it needs a side-by-side against the reference build before the EP commits.

Constraints:
- Tokens: about 0.25M as an estimate (one row of size S).
- State hash: none of this changes the sim's state fingerprint. Sound reads sim events and never writes sim state.
- Machine: headless Godot only; at most 3 Godot processes for a short gate; long runs at below-normal priority; no browser of your own (captures only through Tools' launcher, asked for through the EP).
- Determinism and data: cue numbers live in data; a data shape change updates its schema in the same commit.
- Originality: every sound is our own; no samples, melodies or cues from an existing franchise or library we have no right to.
- Orb's rules: brawl sounds are chunky and low, not tinny or metallic; plain words; the AI disclosure covers generated sound wherever the game is shown. No new sounds in A1: the missing ones (a background bed, building damage and collapse, menu moves) are row A-AUDIO-02 in A5, and the sound toolset is after Alpha.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Before this starts: Orb's yes to decision 1 and the working tree committed or deliberately ignored (A-PROCESS-03). In step 4 of A1's order the sound sets land after the look and before the left-panel menus. Waiting on this: A-CODE-01 (no switch row differs between main and the played build); the first desktop build (A-TOOLS-01); in A2 Orb's ten-minute listening pass (A-AUDIO-03); in A5 the missing sounds (A-AUDIO-02).
