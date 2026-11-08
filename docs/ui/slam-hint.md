# "Hold to slam": a one-time hint for the stick's slam (UI & UX, 2026-11-07; the EP's brief for Sunday's build, from Game Design's docs/design/slam-and-pace.md section 1; re-pointed to Encounter's cue)

**What Orb did.** Orb held the right stick down for a slam and got a stun and a short drop, because a full stick hold did not send. Game Design's ruling makes a hold to the top stage send (DOWN at the top stage on a foe in the air is the slam). A person who does not know to hold needs one plain line, a few times.

**The line.** `prompt.teach_slam`: "Hold to slam" (ui/data/terms.json; Narrative may reword it). It is the legend's teaching row at the screen's edge, with the right stick's glyph beside it, for 1.5 s, and it goes in one cut. Nothing is drawn on a fighter and nothing fades. It rides the teaching line that already carries "Hold for a beam" and the refusal words, so it shows in the compact legend and in a beam struggle only with the `refusal-compact` park in.

**When.** On Encounter's **`slam_hint`** cue (docs/director/pending/stick-slam): a person's quick down flick that lands on a foe in the air, which does not send. The cue's text is the direction (`down`) and its source is empty; UI reads nothing else from it. For a person only (the cue's actor is a person; a computer is never told), the first three times ever, counted in the profile (`taught_slam_n`, as the flick and chase lines are). An earlier version of this park inferred the moment from `stick_release` and `stick_stage`; the cue is simpler and is the only trigger now.

**The switch.** `slam_hint` in ui/data/features.json, **off as shipped**, because `fullSend` (data/director/stick.json) is not enabled yet and the line would promise a slam that does not happen. **Flip it in the same commit that turns `fullSend.enabled` on.** It also needs `beam_teach` (on): it rides the teaching lines.

**Tests (`_slam_hint_rules`, 2 checks in hud_check):** off as shipped (no word, no count); on, the cue says "Hold to slam" with the stick's glyph for 1.5 s; not for the computer; only the first three times; and quiet with the teaching lines off. Each fails with the cue's branch removed (tried).
