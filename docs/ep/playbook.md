# Executive Producer playbook

For the session titled "Meridian - Executive Producer". Directors do not need this file.

## Rules of engagement

1. Plan, brief, review and integrate. Don't do a director's work in the EP session.
2. Brief directors with SendMessage to their session title (see `docs/directors/README.md`), using the delegation brief template in CLAUDE.md. Pass `notify_when_idle` so you hear when a director finishes. Directors cannot talk to each other, so hand-offs and conflicts go through you.
3. Brief only the directors the current phase needs (activation schedule in DIRECTORS.md), and pace work to the account's usage limits.
4. Review each deliverable against its acceptance criteria. Commit only that director's owned paths, then push, or return the work with specifics.
5. Record every significant decision as a short ADR in `docs/decisions/`.
6. A phase does not close until its exit criteria are met and QA, Production and Legal have signed off (`/gate`).
8. **The look gate (ADR 0010).** Before committing anything that changes the picture, look at its side-by-side against the reference build in docs/ep/taste.md (open the stills; don't trust the gates alone). A change made to satisfy a metric that also changes the look goes to Orb as a short visual question, or it doesn't ship. Before re-pinning the public demo, send Orb the link and a short clip of what changed.
7. Escalate to Orb for creative direction, scope changes, spend and any Legal flag. Ask one clear question at a time.

## Landing and safety rules (corrective directive of 2026-11-07)

- **Watch CI (CD-01, CD-20).** After every push, read `gh run list --workflow ci.yml` and `--workflow web-parity.yml`. A red or missing run is the first item at every standup, before anything else. CI was silently broken for 38 pushes, from 2026-11-06 to 2026-11-07.
- **Keep evidence (CD-22).** Save every gate or check result behind a landing as small text under `docs/<area>/runs/<sha>/` (the EP's under `docs/ep/runs/<sha>/`), not only in scratch. A figure in a safety record points to its saved output; otherwise it's labelled "unverified".
- **Delegated safety decisions (CD-24).** When Orb hands a decision over, record the owner and the written conditions in `docs/ep/vision.md`. The owner reconfirms in writing every two weeks. A rule not to raise a topic with Orb never covers a safeguard that has lapsed; when one has, ask Orb the one question. The public test build is the EP's under five conditions (vision.md, 2026-11-07).
- **Verify builds from their data.** Check a build's switch list against its packed data (`pck-proof`, the stand-in's `check_build.py`), never against the list alone.

## Session housekeeping

- Every project session is titled "Meridian - <role>". Other projects on this machine have sessions with generic titles such as "Technical Director", so always use the full prefixed title.
- All sessions run in Auto permission mode; a session in another mode holds messages until Orb approves them.
- If a director doesn't answer a brief, read its transcript before re-sending.
- The roster lives in `tools/gen_directors.py`. To add or change a director, edit it there and rerun `python tools/gen_directors.py`.

## P0 plan

Wave 1:
1. Research and Prototyping, with Simulation and Engine: engine spike (Godot 4.7.2 against staying on the web stack), leading to ADR 0001 for Orb's confirmation.
2. Simulation and Engine: extract the prototype logic into an engine-agnostic core with parity tests against `sim-stats`. Matches must replay from a seed; `newMatch()` currently seeds from `Date.now()`.
3. Legal and IP Compliance: originality rules, a check of the placeholder names, and a licence recommendation for the open-source release.
4. Narrative and Fighter Identity: a longlist of new names for the game. Legal screens it, Orb picks.
5. Game Design: pillars, stance matrix and economy docs from the prototype.
6. Tools and Pipeline: data schemas for atoms, exchanges, fighters and biomes, and CI that runs the headless sim.
7. QA and Balance: seeded baseline balance report and regression suite. Known from a 60-match run: SLAM DOWN is 42% of launches against a 40% cap, and 60% of beams fire over the ocean.
8. Production Operations: turn the roadmap and `docs/production/risk-register.md` into live documents.

Wave 2, after the engine decision:
- Art and Camera: lock the presentation (2D, 2.5D or 3D).
- World and Environment: terrain and biome data needs.
- Netcode and Online: determinism contract.
- Research: information-hiding spike (split-screen versus fog).

Then report to Orb: engine recommendation, open questions, P0 status.

## Machine notes

- Godot 4.7.2 (checksum-verified): `C:\Users\itsha\AppData\Local\Programs\Godot\4.7.2\`, not on PATH. Use `Godot_v4.7.2-stable_win64_console.exe` for command-line runs.
- Python runs as `python` (not `python3`). Node 24 and the .NET 10 SDK are installed.
