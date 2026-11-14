# A2: Audio & Music

Leads: A-AUDIO-03, A-AUDIO-04
Supports: none

Goal: Orb has listened to the desktop build for ten minutes and marked what sounds wrong before any friend hears it, and the team knows that sound plays on Windows, on Linux and on a real Steam Deck.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A2; decision 21), `02-areas/AUDIO.md` (F-AUDIO-03, F-AUDIO-04), `docs/audio/crackle.md`, `docs/audio/first-play-sound.md`.
- A-AUDIO-03: no sound has Orb's approval by ear: Audio's pages say nobody on the team can listen, and Orb's latest word (2026-11-09) is that the crackles sounded bad, with no record of which build that was. Evidence: `docs/audio/crackle.md:3`, `:55`; `docs/audio/first-play-sound.md:3`; `docs/ep/vision.md:1703`. Verified detail: Orb has reported that sound plays (`docs/ep/vision.md:1646`, `:1705`) and gave tone notes on 2026-10-16 (`docs/ep/vision.md:1333-1334`); what is missing is approval by ear and the build the crackle remark was about.
- A-AUDIO-04: sound on the Alpha's platforms is not evidenced: every proof is the browser build, the only audio project setting is web-only, and no CI job runs an audio check. Evidence: `project.godot:12-14`; `docs/audio/crackle.md:57`; `01-inventory/I-05-ui-audio-loc.md:9`.

You own: `audio/`, `docs/audio/`.
- ask under NEEDS FROM EP for a grant: `project.godot` (only if a desktop audio setting is needed beside the web-only one)
- ask under NEEDS FROM EP for a grant: `.github/` (a desktop audio check in CI) or have Tools add it through the EP

Acceptance criteria:
1. (A-AUDIO-03) A one-page listening sheet for Orb in `docs/audio/`, in plain words: ten minutes on the A2 desktop build, a short list of moments to cause (a light blow, a heavy blow, a beam, a clash, a launch into the ground, a building coming down, moving through the menu) and beside each a box: fine, too loud, too quiet, crackles, sounds wrong. It names the build id so the answer is tied to a build. The EP hands it to Orb; Orb's marks, in their words, are saved under `docs/audio/runs/<sha>/`.
2. (A-AUDIO-03) Each mark other than "fine" becomes one dated line in `docs/audio/` with a proposed fix and size; the crackle question is answered for this build (heard or not heard). Fixes that fit an S are made in this milestone; the rest go to the EP for A5's sound row (A-AUDIO-02).
3. (A-AUDIO-04) A check that runs the exported Windows and Linux programs headless, plays a fixed list of cues and proves each produced a non-silent, non-clipped buffer of the expected length. It runs in CI on both platforms; outputs saved under `docs/audio/runs/<sha>/`. If the engine cannot capture its own output headless on a platform, say so with the evidence and propose the nearest check that can run.
4. (A-AUDIO-04) The desktop audio settings are stated on a page: what the web-only setting at `project.godot:12-14` does, what a desktop build uses instead, and whether anything needs setting for Linux.
5. (A-AUDIO-04, first reading from real hardware) The friends' sheet asks: did you hear sound through the Deck's speakers; any crackle, drop-out or delay; was anything painfully loud. Both answers saved under `docs/audio/runs/<sha>/deck/`. Silence or crackle on a Deck is reported to the EP the same day.
6. Nothing here changes the picture; if a fix adds a caption or a visible cue, it names the look gate (ADR 0010) and ships with a side-by-side against the reference build.

Constraints:
- Tokens: about 0.5M as an estimate (two S rows at the size classes).
- State hash: no change. Sound reads sim events and never writes sim state; A2 has no golden window.
- Machine: headless Godot only; at most 3 Godot processes for a short gate; long runs at below-normal priority; browser captures only through Tools' launcher.
- Determinism: cues fire from sim events on a fixed step; no audio timing feeds back into the sim; levels and cue numbers live in data, with the schema updated in the same commit as any shape change.
- Originality: every sound is the project's own synthesis; nothing sampled or imitated from an existing game, show or track.
- Orb's rules: Orb wants brawl sounds chunky and low, not tinny or metallic (2026-10-16); a quiet fight with no music is the plan for Alpha unless Orb says otherwise; plain words on the sheet, seen by Orb before use; no sudden loud sound in the first seconds of a tester's first start.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: criteria 1 to 4 need the A1 desktop build (A-TOOLS-01) and A-AUDIO-01 on main. Criterion 5 needs the two friends' Steam Deck session (A-PERF-01). Waiting on this brief: Orb's listening pass in the A2 play; the smaller sound row A-AUDIO-02 in A5 takes its list from criterion 2.
