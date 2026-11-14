# One against many: does the parked work still apply? (A-AI-13, and Encounter's part of spike S3)

Encounter, 2026-11-14, sprint A1 wave 1. A dry run of the parked stages 2 and 3 (`docs/director/pending/one-v-many-s2/`, `one-v-many-s3/`, last rebuilt 2026-10-16) on a scratch copy of HEAD def3445a. **Nothing was written to the repository.**

## How

- The two apply scripts (`s2.cjs`, then `s3.cjs`) were run against the scratch copy through a wrapper. Each anchor is exact text, and the scripts stop at the first missing one. The wrapper records every anchor instead, so the dead ones are all listed.
- Stage 1 (Simulation's bodies, 2 to 5 a match) is on main: `SimRoster.MAX_BODIES` is 5.
- Then the half-applied copy was imported and the parked `ring.gd` checked on its own (`--check-only`).

## What still applies

| Stage | Exact anchors | Apply | Dead |
| :--- | ---: | ---: | ---: |
| 2 (the partner and the ring) | 4 | 2 | 2 |
| 3 (the interjection, the guards' rules) | 19 | 17 | 2 |

**The dead four, and why:**

| Anchor | Why it died | The re-cut |
| :--- | :--- | :--- |
| `ai.gd`: the hook after `if f.act.formReady: i.transform = true` | the computer's transform moved out of `aiInput` | find the ring's hook point in `aiInput` again (before the brawl's branch) |
| `exchange.gd`: `if DirBeam.inClash(S, A): return` then `var big` | the Driver's and the outside blow's `takes` now sit between the two lines | put the ring's guard-request test after `inClash`, before them |
| `brawl.gd`: the charged heavy's stagger (`if bool(a.get("charged", false)):` in its old context) | the line is still there; the lines around it changed | re-anchor on today's context |
| `brawl.gd`: `static func _send(S, ex, f, o, aim, why, mul)` | `_send` gained `extra: Dictionary = {}` (the full send) | re-anchor on the new signature |

**The broad rename.** Stage 2 also renames every `SimRoster.opp(` in the director to `DirRing.partner(`: 49 places today. It's mechanical and it compiles. But the 2v2 work since (`DirBrawl.rivalOf`, `DirBrawl.exOf`, `SimCross`) added its own idea of "my opponent". Each of the 49 needs reading against 2v2 before it's trusted.

**It compiles.** The half-applied copy imports with 0 script errors, and the parked `ring.gd` passes `--check-only`. So nothing in today's code it calls has gone.

## The verdict

- **Most of it still applies:** 19 of 23 exact anchors, and the code compiles.
- **The re-cut is small:** four anchors and a read of the 49 renamed sites against 2v2. My guess is half a day, then the old gate list and probes (35 checks, the ring probes at 3, 4 and 5 bodies) run again.
- **What it doesn't answer yet:** the frame cost of up to five weak bodies (S3 asks for it in a quiet window; I'll ask the EP for one), and respawn.

## Respawn inside the five-body limit (S3)

- **Not built.** Stage 1 says a guard's fall "is the director's: he leaves the field, and his place reopens after its cooldown" (`sim/core/damage.gd:136-139`). `docs/director/one-v-many.md` puts "break the escort: a guard sent off for 20 s" in stage 5, unbuilt.
- **It fits the limit by reusing slots:** a weak body that falls leaves the field (inactive, off the ring) and comes back at the ring's edge after its cooldown, fresh. The match never holds more than five bodies at once, and a horde of any total size passes through them. Nothing in the replay or the hash needs a sixth slot.

## Lifting the five-body limit (an estimate only)

- `MAX_BODIES` is only a check, in `roster.gd:54` and `sim.gd:204-206`. The fighter arrays are sized from the setup's slots.
- What lifting it costs is elsewhere:
  - the frame (each body is stepped, and the director's ring and partner logic look at pairs);
  - the director's one exchange at a time (`S.dirS.ex`);
  - the replay's input records and the net session's slots, which are written for the few slots a match has;
  - the camera's framing.
- The frame cost measured on five bodies (in the quiet window) will say how far past five it can go. Until then, my guess is that six to eight is mostly frame cost, and anything bigger needs the director's pair logic reworked.
