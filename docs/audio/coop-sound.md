# The co-op and controller sounds (Audio and Music, 2026-11-07)

Answers the EP's brief from `docs/ep/proposals/co-op-2v2.md` (A2, and A10 as a proposal) and the controller plan's sound beats. **Built, checked, parked behind a switch that is off** (`audio/data/coop_cues.json`, `enabled: false`). Existing sounds only, no new recipe. **Nobody has listened to it**: the four clips in `docs/audio/img/coop/` are for Orb's ear.

## 1. What plays

| Beat | The sim's cue | What sounds | Where and how loud |
| :--- | :--- | :--- | :--- |
| **The brink's call (A2)** | `brink_call` (`text` the caller's key p1 to p4), once a brink, from either fight | A sting, then the caller's own cry: `form.ready` at pitch 0.84 on the Alert bus, `voice.<family>.pain.head` | The sting is **at the listener** whatever the distance (an alert), -6 dB, captioned "[P4 on the brink]". The cry is at the fighter in the fight on screen; in the other fight it comes **muffled** (the VoiceMuffled bus) and 6 dB quieter, at the listener. At most one call a fighter every 4 s |
| **A good push in a clash** | `beam_surge` | A plain `perfect.tok` (-6 dB) on every surge that is not sharp. The struggle's whump (`tug.surge`) and the sharp surge's tok a step higher were already AudioTug's | At the pusher |
| **A stray in a clash** | `beam_stray` | `grip.refuse`, the dull low knock (135 to 105 Hz), in place of the old falling droop (`perfect.break`, 320 Hz). **A data change in `tug_cues.json`**: `stray.sound` and its gain (-5 dB, so it is no louder than the droop was) | At the presser, one every 20 ticks a fighter |
| **A refusal knock** | `stick_refused` (`source` the reason), `press_refused` (`source` the code) | `grip.refuse`, the same knock whatever the reason, as the pad's own knock is | At the presser, -4 dB; "replaced" and "answered" (a newer press took over, not a failure) 6 dB quieter; one every 12 ticks a fighter, so a mash is one knock |
| **Charge stages rising** | `stick_stage` (`k` the stage, `n` the count, `source` "capped") | `charge.tick.light` climbing a ladder of semitones (0, 2, 4, 7, 9, 12), and `tug.tock` under the top stage. A step down is a 3-semitone lower, 4 dB duller tick and no thud. "capped" adds the knock | At the charger, -8 dB. A new charge (240 ticks since the last stage) starts at the root |

All five are existing sounds at their own pitch and level; every number is in `coop_cues.json`.

## 2. How the call reaches both PCs

A fighter's cues live in the fight he is in, and a PC's audio reads only the fight held in `S`. So **`AudioCues.consume_others(S, lists)`** reads the other fights' events (`lists[j]` is the j-th fight that is not the one in S, in fight order: what `SimHost.other_events()` returns) and takes only `brink_call` from them (their fighters' positions come from `S.stage.fights[k].fighters`). The fight in S is never in the other lists, so a call is read once. The one host line is a patch for Rendering (`docs/audio/pending/coop/sim_host.patch`, applies to HEAD with `git apply --check`):

```
	pending_cues.append_array(audio_cues.consume(S, S.out.fx))
+	if S.stage != null:
+		pending_cues.append_array(audio_cues.consume_others(S, other_events()))
```

Off the 2v2 (`S.stage == null`) it does nothing, and with the switch off it returns an empty list.

**LAN.** I read the list a PC's host keeps. If NetLan's PC holds another fight between ticks (`viewSlot`), S's `cur` is that fight and the mapping above still holds; I have not run a LAN.

## 3. The switch

A page word `soundCoop` in `tools/preview/switches.mjs` (Tools' file), the same shape as the others:

```
{ id: 'soundCoop', file: 'audio/data/coop_cues.json', path: ['enabled'], from: false, to: true, optional: true,
  what: 'the co-op and controller sounds (Audio): the brink call, the clash push, the pad refusal knock, the charge stages' },
```

Read-back probe: `host.audio_cues.coop.enabled()`. `coop_check` asserts "the switch is off in the data", as the others do.

Two of the beats depend on cues that are not on main yet: `stick_stage` is in `docs/director/pending/beam-move` and `strike-stages` (their stages are silent until Encounter's park lands), and `brink_call` is emitted only with `DirOutside` on (2v2 and the `cross` switch). The refusal knock and the clash push work on main today (`stick_refused` and `beam_surge` already come out).

**One change that is not behind `coop`:** the stray's knock replaces the droop in `tug_cues.json`, and `soundTug` is on in page builds. So a build with `soundTug` hears the knock as soon as this lands. If Orb wants the old droop for a first listen, put `perfect.break` and gain -2 back in that one entry.

## 4. Checks (a scratch export of HEAD with these files laid over it)

- `audio/tools/coop_check.gd` (new): 36 checks. The set off makes nothing. The call: sting and cry in the fight in S, the 4 s rate limit per fighter, a missing body is silent; from another fight the cry is muffled, quiet and from that fight's own body, and nothing else in another fight is heard. The knock: the same for every reason, the mash rule, per fighter, "replaced" quieter. The stages: strictly rising pitch from the root to the octave, the thud only at the top, a step down, capped, a restart. The push. Then seeded matches (1v1: every cue a bank sound with finite, in-range numbers, a second run makes the same cues; 2v2 with `DirOutside` forced on and one fighter in each fight worn to his brink: **real calls from both the fight in S and the other (2 and 2), each heard once**).
- `tug_check.gd` (updated for the knock), `moments_check`, `carry_check`, `brawl_check`, `tone_check`, `status_check`, `web_policy_check`, `beat_check`, `babble_check`: all pass.
- `host_check.gd`: the cue logs and every printed hash are identical to a clean HEAD export's (the switch is off); the only difference is the count of objects the engine reports at exit.
- `audio/tools/render_coop_demo.gd` (new) wrote the four clips below. Checked, not heard.

## 5. A10, proposed (not built): the partner's fight, quieter and later, in the muffled distance

What a human on the other side of the planet should hear of the fight they are not in, drawn only from that fight's events (`consume_others` already reads them):

- **What:** a thin, low part of it, not blow by blow. The heavy blows (the effort grunt's own threshold, 26 damage and over), a beam firing, a KO, a meteor's landing (a crater of energy 2.6 and over), a decisive hit, and the brink's call at full level. Nothing else: no light hits, no ticks, no struggle bed, so two fights are never twice the traffic.
- **Where and how loud:** at the listener (no pan; "behind the planet"), through the **muffled buses** that exist (SfxMuffled 900 Hz, VoiceMuffled 1,400 Hz). The level follows the distance along the planet between the listener and that fight's pair: **-14 dB when it is a sixth of a ring away, falling to -24 dB at half a ring**. (The existing `distance_db` law runs out at 2,600 units, -36 dB, and half a ring is 4,800, so it would be silent; the far mix needs its own law.)
- **Later:** a delay of **120 ms up to 380 ms** with the same distance (a feel, not physics: planet-scale sound would be seconds). It needs a `delay_ms` on the cue, played by the deferred queue `AudioVoices` already has (the warm-up uses it) and, on the web, by the page player's start time (`ctx.currentTime + delay`, a one-line change in `audio_web.gd`). My files only.
- **Budget:** class `coop.far`, cap 2, priority 30 below the same sound in the fight on screen, at most four far cues a second, never ducking Music or the voices of the fight on screen.
- **Rumble:** Controls' half (A10 names Controls). The pad's far rumble can follow the same event list and law; sound and rumble are not light events (RL-249 (4)).
- **Cost:** about 1M as the brief says (the mapper and law, `delay_ms` in the voices and the page player, the check, four clips).
- **Questions before building:** whether Orb wants to hear the partner's fight at all in the first together try (some players will take it as noise); and whether "later" should be felt (120 to 380 ms) or left at zero (a pure level and muffle).

## 6. Recordings for Orb's ear (`docs/audio/img/coop/`, mono 22.05 kHz 16-bit, dry: no music; place and distance are not heard in a mono file)

- `brink-call-dry.wav` (10.5 s): the call of a fighter on screen (sting and his cry); the partner's call from the other fight (the cry through the 1.4 kHz muffle, the sting at the listener); both at once.
- `refusal-knock-dry.wav` (7.9 s): a refused press, a second, a mash of five (one knock), a replaced press (quieter), a director-side drop.
- `charge-stages-dry.wav` (9.4 s): a six-stage charge climbing (12 to 120 ticks), a step down, a short four-stage charge stopped at stage 2 by the energy (tick and knock).
- `clash-push-dry.wav` (4.4 s): the struggle's lock and beat, a plain push (whump and tok), a sharp push, two strays (the knock), the end. The bed is left out.

## 7. Risks and limits

- **Not heard.** The sting is `form.ready` lowered a step. It is the ready form's chime in a different key, so it could read as "a transformation is ready" to a player who has heard both; the alternative on the shelf is `ui.launcher` (the launcher's ping, which means "act now" for a different reason). Both are one data line; I have no recording that settles it, only the clip.
- **The call is a cry plus a sting, not a spoken line.** Narrative's bark text would reach the ear through the babble system, which plays the UI's lines; the sim's cue carries no bark (`source` is empty), so there is nothing for it to speak yet.
- **The knock is heard by both fighters' players** (the sound is at the presser, and a PC cannot tell whose pad it is). It is quiet (-4 dB) and one in 12 ticks. If it grates in a two-pad game, the knock can be limited to a fighter the host calls local (a host call, not data).
- **A "good push" on a plain surge is a tok on top of the whump.** At the busiest the struggle's pulse is 3 a second, so at most about 3 toks a second a side.
- **`coop_cues.json` has no schema yet** (a warning, as the moments file had): a draft would be Tools'. The shape is `brink`, `refuse`, `stage`, `clash`.
