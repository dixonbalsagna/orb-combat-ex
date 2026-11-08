class_name SimHaptics
extends RefCounted
## The pulses a pad or a phone gives (docs/controls/haptics.md): what a cue from the sim asks for and the host plays.
## Pure functions over data: no engine call, no clock, no state, no RNG. The host (render/core/main.gd) calls `plan` and plays the steps
## it returns (`Input.start_joy_vibration`, `Input.vibrate_handheld`), the later ones on host timers; nothing here reads or writes the
## sim, the replay or the hash, and a pulse is never the only cue (UI's chip, Audio's sound and the fighters' own bodies say the same).
##
## The numbers are `haptics` in data/input/timing.json. For each kind (see KINDS) there are two lists of STEPS, `pad` and `handheld`:
##   a pad step {at, weak, strong, ms}: `at` milliseconds after the request, the two motors (`weak` the high-frequency one, `strong` the
##     low, each 0 to 1) and `ms` its length;
##   a phone step {at, ms}.
## Global numbers: `minGapMs` (a second request for the same slot inside it is dropped), `padMinMs` and `handheldMinMs` (the shortest
## pulse the hardware can feel: a motor needs about 20 to 40 ms to spin up, so a shorter request is lengthened to this, never dropped,
## and never passed as 0, which Godot reads as "for as long as it can"), `scaleMin` (see SCALE) and `padMinStrength` (a motor below this
## is not felt, so a scaled step is raised to it). A kind may carry its own `gapMs`: the least time between two of that kind for one
## slot, so a mashed button or a steady beat can never make the pad buzz without a break. Absent, these defaults stand.
## The feel of each shape is Audio's (docs/audio/launch-and-tug.md); the hardware floors and the rate limits are Controls'.
##
## SCALE. `plan` and `steps` take a scale from 0 to 1 (the struggle's share, the clinch's grip): a pad step's motors are multiplied by
## scaleMin + (1 - scaleMin) * scale and raised to padMinStrength; a phone, which has no strength, gets a shorter pulse the same way (never
## under handheldMinMs). A scale of 1 is the data as written.
## MAPPING. `requests` turns a sim cue into who feels what, from the cue's own fields (no state but the firer's slot, which the host keeps
## from the beam struggle's first cue).

const DEFAULTS: Dictionary = {
	# The strike stick's charge ladder (pitch 1): a tick, a knock, a thud as each rung is reached. Each has a low motor in it, so none is the brake's tick.
	"ladder_1": {
		"pad": [{"at": 0, "weak": 0.35, "strong": 0.15, "ms": 20}],
		"handheld": [{"at": 0, "ms": 12}],
		"gapMs": 120,
	},
	"ladder_2": {
		"pad": [{"at": 0, "weak": 0.3, "strong": 0.45, "ms": 25}],
		"handheld": [{"at": 0, "ms": 22}],
		"gapMs": 120,
	},
	"ladder_3": {
		"pad": [{"at": 0, "weak": 0.25, "strong": 0.8, "ms": 45}, {"at": 70, "weak": 0.2, "strong": 0.3, "ms": 25}],
		"handheld": [{"at": 0, "ms": 40}, {"at": 70, "ms": 15}],
		"gapMs": 160,
	},
	# The throw of a charged strike or beam (docs/controls/beam-aim-feel.md section 5): one low push, then a short roll-off, on the low motor with only a trace of the high one.
	# Soft and chunky: nothing brighter than a thud, so the lift of the thumb is answered by weight, not a buzz. The thrower only; scaled by the charge reached.
	"release_thump": {
		"pad": [{"at": 0, "weak": 0.1, "strong": 0.65, "ms": 40}, {"at": 55, "weak": 0.0, "strong": 0.25, "ms": 30}],
		"handheld": [{"at": 0, "ms": 30}, {"at": 55, "ms": 14}],
		"gapMs": 160,
	},
	# The stick's full send (docs/controls/full-send-haptic.md; Encounter's stick_full_send cue): the top-stage payoff, a held stick strike sent at a full B's share. The heaviest thing the pad does:
	# a slam on the low motor with a bite of the high one, a roll-off, then a settle, all inside the 160 ms every kind keeps. The sender only (the one sent has launch_felt). Scaled by the family (the slam 1.0).
	"full_send": {
		"pad": [{"at": 0, "weak": 0.3, "strong": 1.0, "ms": 60}, {"at": 65, "weak": 0.0, "strong": 0.55, "ms": 45}, {"at": 115, "weak": 0.0, "strong": 0.25, "ms": 40}],
		"handheld": [{"at": 0, "ms": 60}, {"at": 65, "ms": 28}],
		"gapMs": 400,
	},
	# Orb's 2026-10-05 picks, the five that were missing (docs/controls/impact-haptics.md; switches.hapticImpact). Soft and low, none brighter than a thud; every one has its own gap so a brawl
	# never buzzes. A landed blow, felt by the one who landed it, scaled by the blow's strength.
	"blow_land": {
		"pad": [{"at": 0, "weak": 0.15, "strong": 0.6, "ms": 30}],
		"handheld": [{"at": 0, "ms": 23}],
		"gapMs": 90,
	},
	# A blow taken: the same weight, lower and a little longer, felt by the one it hit.
	"hit_taken": {
		"pad": [{"at": 0, "weak": 0.1, "strong": 0.7, "ms": 40}],
		"handheld": [{"at": 0, "ms": 29}],
		"gapMs": 90,
	},
	# A close: an attack carries the fighter across the gap. One short surge on both motors.
	"close_surge": {
		"pad": [{"at": 0, "weak": 0.3, "strong": 0.25, "ms": 40}],
		"handheld": [{"at": 0, "ms": 24}],
		"gapMs": 200,
	},
	# Sent flying: the launched fighter's own pad. A heavy push, then a roll-off.
	"launch_felt": {
		"pad": [{"at": 0, "weak": 0.2, "strong": 0.8, "ms": 80}, {"at": 100, "weak": 0.0, "strong": 0.4, "ms": 60}],
		"handheld": [{"at": 0, "ms": 42}, {"at": 100, "ms": 18}],
		"gapMs": 300,
	},
	# Touchdown after a launch: a thud with a short tail, scaled by the speed it came down at.
	"landing_thud": {
		"pad": [{"at": 0, "weak": 0.1, "strong": 0.65, "ms": 50}, {"at": 70, "weak": 0.0, "strong": 0.25, "ms": 30}],
		"handheld": [{"at": 0, "ms": 34}, {"at": 70, "ms": 16}],
		"gapMs": 200,
	},
	# A building breaks (it falls): both pads, two low pushes, scaled by its height. Over inside 160 ms like every kind.
	"building_break": {
		"pad": [{"at": 0, "weak": 0.2, "strong": 0.6, "ms": 70}, {"at": 90, "weak": 0.0, "strong": 0.4, "ms": 70}],
		"handheld": [{"at": 0, "ms": 45}, {"at": 90, "ms": 40}],
		"gapMs": 600,
	},
	# A rival's stick strike has started (pitch 3), on the defender's pad: two light taps for a blow from above or toward, one low knock for below or away.
	"incoming_high": {
		"pad": [{"at": 0, "weak": 0.55, "strong": 0.12, "ms": 20}, {"at": 45, "weak": 0.3, "strong": 0.1, "ms": 20}],
		"handheld": [{"at": 0, "ms": 14}, {"at": 45, "ms": 10}],
		"gapMs": 200,
	},
	# A beam is on its way and the receiver may still answer (row 40, Encounter's `beam_window`): one firm pulse, played again and again at a rising scale through the
	# window (a crescendo to arrival, see beam_window). Both motors, no longer than a heavy's snap.
	"incoming_beam": {
		"pad": [{"at": 0, "weak": 0.4, "strong": 0.5, "ms": 40}],
		"handheld": [{"at": 0, "ms": 26}],
		"gapMs": 100,
	},
	# A stick press the game did not answer (the audit's gap 2): two short dull knocks on the low motor, the sound of a press that went nowhere. The presser only.
	"stick_refused": {
		"pad": [{"at": 0, "weak": 0.05, "strong": 0.35, "ms": 30}, {"at": 70, "weak": 0.0, "strong": 0.3, "ms": 30}],
		"handheld": [{"at": 0, "ms": 20}, {"at": 70, "ms": 12}],
		"gapMs": 200,
	},
	"incoming_low": {
		"pad": [{"at": 0, "weak": 0.1, "strong": 0.55, "ms": 30}],
		"handheld": [{"at": 0, "ms": 18}],
		"gapMs": 200,
	},
	# A thump with a ring after it: the pluck and the head snap, then the ring (Audio's shape, 150 ms in all). The launcher only.
	"launch_open": {
		"pad": [{"at": 0, "weak": 0.3, "strong": 0.7, "ms": 80}, {"at": 90, "weak": 0.2, "strong": 0.0, "ms": 60}],
		"handheld": [{"at": 0, "ms": 25}, {"at": 85, "ms": 10}],
		"gapMs": 300,
	},
	# The form is ready: two light taps, the second firmer. Rising, so it says "now" rather than "hit".
	"form_prompt": {
		"pad": [{"at": 0, "weak": 0.25, "strong": 0.25, "ms": 20}, {"at": 70, "weak": 0.4, "strong": 0.4, "ms": 30}],
		"handheld": [{"at": 0, "ms": 10}, {"at": 70, "ms": 20}],
		"gapMs": 200,
	},
	# The air brake can be set: one sharp tick on the high motor alone. Nothing low in it, which is what tells it from every other kind.
	"brake_ready": {
		"pad": [{"at": 0, "weak": 0.6, "strong": 0.0, "ms": 20}],
		"handheld": [{"at": 0, "ms": 10}],
		"gapMs": 200,
	},
	# The heavy's charge is full: one firm snap on both motors.
	"charge_full": {
		"pad": [{"at": 0, "weak": 0.5, "strong": 0.6, "ms": 40}],
		"handheld": [{"at": 0, "ms": 35}],
		"gapMs": 200,
	},
	# The clinch's pulse (every 20 ticks): a low creak, then a faint scrape after it. Scaled by the grip.
	"clinch_pulse": {
		"pad": [{"at": 0, "weak": 0.0, "strong": 0.3, "ms": 30}, {"at": 50, "weak": 0.15, "strong": 0.0, "ms": 20}],
		"handheld": [{"at": 0, "ms": 15}, {"at": 50, "ms": 10}],
		"gapMs": 250,
	},
	# The beam struggle, off the beat: a player's own surge (a bright tick, the high motor) and a surge made against him (a heavy low
	# push), both scaled by the share of the point the pusher holds. The loser's end is once.
	"struggle_push": {
		"pad": [{"at": 0, "weak": 0.5, "strong": 0.1, "ms": 25}],
		"handheld": [{"at": 0, "ms": 20}],
		"gapMs": 100,
	},
	"struggle_pushed": {
		"pad": [{"at": 0, "weak": 0.0, "strong": 0.6, "ms": 40}],
		"handheld": [{"at": 0, "ms": 30}],
		"gapMs": 160,
	},
	"struggle_lose": {
		"pad": [{"at": 0, "weak": 0.4, "strong": 0.8, "ms": 60}],
		"handheld": [{"at": 0, "ms": 40}],
		"gapMs": 300,
	},
}
const MIN_GAP_MS: int = 80
const PAD_MIN_MS: int = 20
const HANDHELD_MIN_MS: int = 10
const SCALE_MIN: float = 0.35
const PAD_MIN_STRENGTH: float = 0.15
const GRIP_STEPS: int = 5
const SHARP_BOOST: float = 0.25
const MAX_STEPS: int = 4
const MAX_AT_MS: int = 1000


## The beam-answer window (row 40). Encounter's cue `beam_window` (UI's contract): text "start" or "end", actor = the shooter, target = the receiver, `n` = the ticks from
## the hand to the front's arrival, `k` = the beam's level, and an optional `dodge_from`; the host passes `text` and `n` (as `ticks`). "start" opens it, "end" closes it. Returns {} when the switch is off or the cue is
## not a window; else {slot: the receiver, open: bool, pulses: [{at: ms after the cue, scale: 0 to 1}]}: a crescendo of `incoming_beam` pulses, one per 200 ms of the window
## (1 to 5), spaced evenly inside it and rising from 0.3 to 1.0, the last well before arrival. Pure; the host plays them on its timers and drops the rest when the window closes.
static func beam_window(actor: int, target: int, text: String, ticks: float) -> Dictionary:
	if not SimInputData.haptic_beam_on():
		return {}
	var slot: int = target if (target >= 0 and target <= 1 and target != actor) else (1 - actor if (actor >= 0 and actor <= 1) else -1)
	if slot < 0:
		return {}
	if text != "start" or ticks < 1.0:
		return {"slot": slot, "open": false, "pulses": []}
	var length_ms: int = int(ticks * 1000.0 / 60.0)
	var n: int = clampi(int(float(length_ms) / 200.0), 1, 5)
	var pulses: Array = []
	for k in range(1, n + 1):
		pulses.append({"at": int(float(length_ms * k) / float(n + 1)), "scale": 0.3 + 0.7 * float(k) / float(n)})
	return {"slot": slot, "open": true, "pulses": pulses}


## The ladder's pulses (pitch 1): the rungs a held strike's charge has newly reached, from `from_level` to `to_level` (0 to 3). The hub keeps the levels
## it saw and calls this when one rises; nothing here reads the sim.
static func ladder_requests(slot: int, from_level: int, to_level: int) -> Array:
	var out: Array = []
	for rung in range(maxi(from_level, 0) + 1, mini(to_level, 3) + 1):
		out.append({"slot": slot, "kind": "ladder_%d" % rung, "scale": 1.0})
	return out


## The pulse for a charge that has reached stage `n` of `of` (UI's `charge_stage` cue, docs/ui/charge-stages.md; docs/controls/beam-aim-feel.md section 5): the first stage is the
## tick (ladder_1), the last the thud with its ring (ladder_3), those between the knock (ladder_2) rising from 0.7 to 1.0 of its strength, so a six-stage charge climbs without any
## pulse louder than the top. [] for stage 0 or a stage outside 1..of. A two-stage charge is the tick, then the thud. Needs switches.hapticLadder.
static func stage_requests(slot: int, n: int, of: int) -> Array:
	if not SimInputData.haptic_ladder_on() or slot < 0 or slot > 1 or of < 1 or n < 1 or n > of:
		return []
	if n == of:
		return [{"slot": slot, "kind": "ladder_3", "scale": 1.0}]
	if n == 1:
		return [{"slot": slot, "kind": "ladder_1", "scale": 1.0}]
	var rise: float = float(n - 2) / float(maxi(1, of - 3))
	return [{"slot": slot, "kind": "ladder_2", "scale": 0.7 + 0.3 * clampf(rise, 0.0, 1.0)}]


## The thump that answers a throw: the thrower's pad, scaled by the charge reached (level 1 to `of`; 0.4 at the first rung up to 1.0 at the last). A flick (level 0) throws no thump,
## so a mashed quick strike never buzzes. Needs switches.hapticLadder.
static func release_requests(slot: int, level: int, of: int = 3) -> Array:
	if not SimInputData.haptic_ladder_on() or slot < 0 or slot > 1 or level < 1 or of < 1:
		return []
	return [{"slot": slot, "kind": "release_thump", "scale": 0.4 + 0.6 * clampf(float(level) / float(of), 0.0, 1.0)}]


## Every press answered (docs/controls/refusals.md): the reason codes of the presses the game lets go of, which UI can show ("a word at the edge, the first few times") and which ride on the `reason` key of a
## stick_refused request. `word` is a suggested English word for the edge (UI owns the final string), `owner` says whose drop it is, `what` what happened. The pad's knock is the same for all: a press that went nowhere.
const REFUSALS: Dictionary = {
	"face_late": {"word": "Too late", "owner": "controls", "what": "a face press waited behind the stick for longer than strike.queueTicks and went"},
	"face_overflow": {"word": "Too many", "owner": "controls", "what": "a fourth face press behind the stick: the oldest went (strike.queueDepth)"},
	"no_answer": {"word": "No answer", "owner": "controls", "what": "a stick request the director never started inside strike.refuseTicks"},
	"no_energy": {"word": "No energy", "owner": "encounter", "what": "the press would cost more energy than he has (the director's stick_refused text ki)"},
	"hit": {"word": "Hit", "owner": "encounter", "what": "the charge was lost to a hit (text taken)"},
	"too_late": {"word": "Too late", "owner": "encounter", "what": "the request waited too long for the fighter to act (text late)"},
	"replaced": {"word": "Replaced", "owner": "encounter", "what": "a newer press took the buffered one's place (text replaced)"},
	"no_reach": {"word": "Out of reach", "owner": "encounter", "what": "it cannot reach him in the air (text chase)"},
	"answered": {"word": "Answered", "owner": "encounter", "what": "a planned exchange took the request: his rival's answer (text answered)"},
	"dodged": {"word": "Dodged", "owner": "encounter", "what": "the request was dodged out of (text dodged)"},
	"cancelled": {"word": "Cancelled", "owner": "encounter", "what": "the guard or the dodge ended the charge (text cancel)"},
	"not_yours": {"word": "Not yours", "owner": "encounter", "what": "the first move belongs to his rival (text refused)"},
	"busy": {"word": "Busy", "owner": "encounter", "what": "the fighter could not act: a state number as the text (the old shape; the director now says which of the four below)"},
	"launched": {"word": "In the air", "owner": "encounter", "what": "he could not act because he was launched (refusal-reasons: DirExchange.cantWhy)"},
	"down": {"word": "Down", "owner": "encounter", "what": "he could not act because he was down (refusal-reasons)"},
	"stunned": {"word": "Stunned", "owner": "encounter", "what": "he could not act because he was stunned (refusal-reasons)"},
	"locked": {"word": "Locked", "owner": "encounter", "what": "he could not act because an exchange held him (refusal-reasons)"},
	"recovering": {"word": "Recovering", "owner": "encounter", "what": "a flick made early in his flight was too old to be his first blow out (flickKeep.recoverTicks; refusal-reasons)"},
	"set_piece": {"word": "In a move", "owner": "encounter", "what": "a finisher, the KO, a set piece in a brawl or a beam struggle: the flick would be stale (refusal-reasons)"},
	"chord": {"word": "One at a time", "owner": "controls", "what": "two attack buttons on one tick: the bigger went, the smaller was let go of (switches.chordPick)"},
	"queue_full": {"word": "Queue full", "owner": "encounter", "what": "three blows already waiting and the cooldown holds them: one knock a burst (refusal-reasons)"},
	"stun_limit": {"word": "One a string", "owner": "encounter", "what": "a stick stun held back by the one-a-string rule"},
	"queue_expired": {"word": "Too slow", "owner": "encounter", "what": "the director's attack queue ran out before it could start the blow"},
	"block_lockout": {"word": "Block cooling", "owner": "encounter", "what": "the perfect block's anti-mash lockout held the press"},
	"too_close": {"word": "Too close", "owner": "encounter", "what": "a quick RB flick in a brawl: the heavy blast can't go in an exchange he is in (stick_refused source close)"},
	"cooling": {"word": "Cooling", "owner": "encounter", "what": "the stick's beam met the signature's wait (stick_refused source cooling)"},
	"soon": {"word": "Soon", "owner": "encounter", "what": "the beam is waiting for its target to be free to act, up to maxWaitTicks (stick_refused source soon)"},
	"other": {"word": "Not now", "owner": "controls", "what": "a refusal whose text this table does not know"},
}
## The director's stick_refused cue reasons (the cue's `source`; its `text` is the stick's direction), as codes.
const REFUSAL_TEXT: Dictionary = {"ki": "no_energy", "taken": "hit", "late": "too_late", "replaced": "replaced", "chase": "no_reach", "answered": "answered", "dodged": "dodged", "cancel": "cancelled", "refused": "not_yours", "close": "too_close", "cooling": "cooling", "soon": "soon"}


## The reason code for a refusal cue's reason (its `source`, hud-spec sections 84 and 85): a known code passes through, the director's words map (REFUSAL_TEXT), a number (a state mask) is "busy", anything else "other".
static func refusal_code(text: String) -> String:
	if REFUSALS.has(text):
		return text
	if REFUSAL_TEXT.has(text):
		return String(REFUSAL_TEXT[text])
	if text != "" and text.is_valid_int():
		return "busy"
	return "other"


## The suggested edge word for a code (UI owns the final string); "Not now" for an unknown code.
static func refusal_word(code: String) -> String:
	return String(REFUSALS.get(code, REFUSALS["other"])["word"])


## What the five impact kinds are scaled by.
const BLOW_STRENGTH: Dictionary = {"light": 0.3, "medium": 0.6, "heavy": 1.0, "bolt": 0.3, "blast": 0.7, "guard": 0.2}
const LAND_SPEED_REF: float = 1400.0
const LAUNCH_SPEED_REF: float = 1500.0
const BUILDING_H_REF: float = 300.0


## The rumble for one sim event, read from the event itself (an SimState.FxEvent; docs/controls/impact-haptics.md). Orb's 2026-10-05 picks that were missing:
##   damage (light, medium, heavy, bolt, blast, guard)  the attacker feels blow_land and the one hit feels hit_taken, scaled by the strength (a guarded blow is dull: 0.2); beams, impacts and
##                                                     hazards (kind beam, impact, anything else) rumble nothing here: the struggle has its own kinds and a landing its own event
##   rush        actor = the fighter closing the gap     -> close_surge
##   launch      actor = the one sent, target = the launcher (the launcher's own cue is UI's launcher_open)  -> launch_felt on the sent one, scaled by speed
##   land        actor = the one touching down, spd      -> landing_thud, scaled by the speed
##   building_fall  (no fighter)                         -> building_break on both pads, scaled by the height
## [] for any other event, and for all of them with switches.hapticImpact off (the one exception is the cue stick_stage, below, behind its own switch). Reads only the event (stage_event_requests keeps the last stage each pad was told).
static func event_requests(e) -> Array:
	if String(e.type) == "cue" and String(e.kind) == "stick_stage":
		return stage_event_requests(e)
	if String(e.type) == "cue" and String(e.kind) == "stick_full_send":
		return full_send_requests(e)
	if not SimInputData.haptic_impact_on():
		return []
	match String(e.type):
		"damage":
			var strength: float = float(BLOW_STRENGTH.get(String(e.kind), -1.0))
			if strength < 0.0:
				return []
			var out: Array = []
			var a: int = int(e.attacker)
			var v: int = int(e.victim)
			if a >= 0 and a <= 1 and a != v:
				out.append({"slot": a, "kind": "blow_land", "scale": strength})
			if v >= 0 and v <= 1 and a != v:
				out.append({"slot": v, "kind": "hit_taken", "scale": strength})
			return out
		"rush":
			var r: int = int(e.actor)
			return [{"slot": r, "kind": "close_surge", "scale": 1.0}] if r >= 0 and r <= 1 else []
		"launch":
			var s: int = int(e.actor)
			if s < 0 or s > 1:
				return []
			return [{"slot": s, "kind": "launch_felt", "scale": clampf(float(e.amount) / LAUNCH_SPEED_REF, 0.3, 1.0)}]
		"land":
			var l: int = int(e.actor)
			if l < 0 or l > 1:
				return []
			return [{"slot": l, "kind": "landing_thud", "scale": clampf(float(e.spd) / LAND_SPEED_REF, 0.25, 1.0)}]
		"building_fall":
			var sc: float = clampf(float(e.depth) / BUILDING_H_REF, 0.3, 1.0)
			return [{"slot": 0, "kind": "building_break", "scale": sc}, {"slot": 1, "kind": "building_break", "scale": sc}]
	return []


## The stick's full send on the sender's pad (docs/controls/full-send-haptic.md; switches.hapticLadder, with the right stick): Encounter's cue `stick_full_send` (actor the sender, source the family) is one `full_send`,
## the slam at full strength, the grounded bury a little under, a send up or across lighter. Presentation only, read from the cue and nothing else.
const FULL_SEND_SCALE: Dictionary = {"slamDown": 1.0, "bury": 0.9, "skyward": 0.8, "across": 0.8, "acrossBehind": 0.8}


static func full_send_requests(e) -> Array:
	if not SimInputData.haptic_ladder_on():
		return []
	var slot: int = int(e.actor)
	if slot < 0 or slot > 1:
		return []
	return [{"slot": slot, "kind": "full_send", "scale": float(FULL_SEND_SCALE.get(String(e.source), 0.8))}]


## The charge's stages on the pad (docs/controls/stage-pulses.md; switches.hapticStages, off): Encounter's cue `stick_stage` (actor the charger, `k` the stage, `n` the count, source "capped" when
## what he can pay stopped the climb) is one pulse by `stage_requests`: the first stage the tick, the last the thud, those between the knock climbing, so a base fighter's two stages are the tick
## and the thud and a six-stage charge climbs. A step down (k under the last) says nothing; "capped" is the knock of a press that went nowhere (stick_refused, 0.6). A first stage is always a
## new charge. The only state is the last stage each pad was told, so a step down is told from a climb: presentation only, never read by the sim.
static var _stage_last: Array = [0, 0]


static func reset_stage_state() -> void:
	_stage_last = [0, 0]


static func stage_event_requests(e) -> Array:
	if not SimInputData.haptic_stages_on():
		return []
	var slot: int = int(e.actor)
	if slot < 0 or slot > 1:
		return []
	var k: int = int(e.k)
	var of: int = int(e.n)
	var last: int = int(_stage_last[slot])
	_stage_last[slot] = k
	if String(e.source) == "capped":
		return [{"slot": slot, "kind": "stick_refused", "scale": 0.6}]
	if k < 1 or of < 1 or k > of or (k <= last and k != 1):
		return []
	return stage_requests(slot, k, of)


## The kinds this knows.
static func kinds() -> Array:
	return DEFAULTS.keys()


## The minimum gap between two requests for one slot, in milliseconds.
static func min_gap_ms() -> int:
	return SimInputData.ti(["haptics", "minGapMs"], MIN_GAP_MS)


## The least time between two requests of one kind for one slot: the kind's own `gapMs`, never under the slot-wide gap. 0 for an unknown kind.
static func kind_gap_ms(kind: String) -> int:
	if not DEFAULTS.has(kind):
		return 0
	return maxi(min_gap_ms(), SimInputData.ti(["haptics", kind, "gapMs"], int(DEFAULTS[kind].get("gapMs", 0))))


## One kind's steps for a device ("pad" or "handheld"), cleaned: each `at` 0 to 1000 ms, motors clamped to 0 to 1, each length raised to the
## hardware floor, a step with no strength (a pad) or no length left out, at most 4 steps, in order of `at`; then scaled (see SCALE).
## [] for an unknown kind.
static func steps(kind: String, device: String, scale: float = 1.0) -> Array:
	if not DEFAULTS.has(kind) or (device != "pad" and device != "handheld"):
		return []
	var raw = SimInputData.t(["haptics", kind, device], DEFAULTS[kind][device])
	if not (raw is Array):
		raw = DEFAULTS[kind][device]
	var floor_ms: int = SimInputData.ti(["haptics", "padMinMs"], PAD_MIN_MS) if device == "pad" else SimInputData.ti(["haptics", "handheldMinMs"], HANDHELD_MIN_MS)
	var f: float = scale_factor(scale)
	var min_strength: float = clampf(SimInputData.tf(["haptics", "padMinStrength"], PAD_MIN_STRENGTH), 0.0, 1.0)
	var out: Array = []
	for s in raw:
		if not (s is Dictionary):
			continue
		var ms: int = int(s.get("ms", 0))
		if ms <= 0:
			continue
		ms = maxi(ms, floor_ms)
		var st: Dictionary = {"at": clampi(int(s.get("at", 0)), 0, MAX_AT_MS), "ms": ms}
		if device == "pad":
			var weak: float = clampf(float(s.get("weak", 0.0)), 0.0, 1.0)
			var strong: float = clampf(float(s.get("strong", 0.0)), 0.0, 1.0)
			if weak <= 0.0 and strong <= 0.0:
				continue
			st["weak"] = _scaled(weak, f, min_strength)
			st["strong"] = _scaled(strong, f, min_strength)
		elif f < 1.0:
			st["ms"] = maxi(floor_ms, int(round(float(ms) * f)))
		out.append(st)
	out.sort_custom(func(a, b): return int(a["at"]) < int(b["at"]))
	if out.size() > MAX_STEPS:
		out.resize(MAX_STEPS)
	return out


## A motor value scaled by `f`, raised to the least strength a motor can be felt at, but a motor that was off stays off.
static func _scaled(v: float, f: float, min_strength: float) -> float:
	if v <= 0.0 or f >= 1.0:
		return v
	return clampf(maxf(v * f, min_strength), 0.0, 1.0)


## The factor a scale of 0 to 1 gives: scaleMin at 0, 1 at 1, linear between; anything outside is clamped.
static func scale_factor(scale: float) -> float:
	var lo: float = clampf(SimInputData.tf(["haptics", "scaleMin"], SCALE_MIN), 0.0, 1.0)
	return lo + (1.0 - lo) * clampf(scale, 0.0, 1.0)


## Whether a request at `now_ms` may play, `last_ms` being when this slot's last one did (host milliseconds; the host owns the clock).
## `gap_ms` overrides the slot-wide gap (the kind's own: `kind_gap_ms`).
static func allow(last_ms: int, now_ms: int, gap_ms: int = -1) -> bool:
	var gap: int = min_gap_ms() if gap_ms < 0 else gap_ms
	return now_ms - last_ms >= gap or now_ms < last_ms


## What to play for a request, or {} for nothing. `target` is `hub.rumble_target(slot)` ({kind, id}); `enabled` is the player's haptics
## option; `last_ms` and `now_ms` are the host's clock for this slot (its last pulse of any kind), `last_kind_ms` is when this slot last
## felt this kind (a kind's own gap; default none yet), and `scale` is 0 to 1 (see SCALE). Each step is played `at` milliseconds after the
## request (the first now, the rest on host timers):
##   a pad:   {via: "pad", id, steps: [{at, weak, strong, seconds}]}   -> Input.start_joy_vibration(id, weak, strong, seconds)
##   a phone: {via: "handheld", steps: [{at, ms}]}                      -> Input.vibrate_handheld(ms)
## A keyboard, a slot nobody holds, an unknown kind, the option off, nothing left in the steps, a request too soon after the last or too
## soon after the last of its own kind: {}.
static func plan(kind: String, target: Dictionary, enabled: bool, last_ms: int, now_ms: int, scale: float = 1.0, last_kind_ms: int = -1000000) -> Dictionary:
	if not enabled or not DEFAULTS.has(kind) or not allow(last_ms, now_ms) or not allow(last_kind_ms, now_ms, kind_gap_ms(kind)):
		return {}
	match str(target.get("kind", "none")):
		"pad":
			var ps: Array = steps(kind, "pad", scale)
			if ps.is_empty():
				return {}
			var out: Array = []
			for s in ps:
				out.append({"at": int(s["at"]), "weak": float(s["weak"]), "strong": float(s["strong"]), "seconds": float(s["ms"]) / 1000.0})
			return {"via": "pad", "id": int(target.get("id", -1)), "steps": out}
		"touch":
			var hs: Array = steps(kind, "handheld", scale)
			if hs.is_empty():
				return {}
			return {"via": "handheld", "steps": hs}
	return {}


## The pusher's share of the beam struggle's point. `point` is the cue's `amount`: 0 at the firer's hands, 1 at the other's, so the
## firer pushes it up and the other down. 0 to 1, 0.5 at an even tug.
static func push_share(point: float, pusher_is_firer: bool) -> float:
	var p: float = clampf(point, 0.0, 1.0)
	return p if pusher_is_firer else 1.0 - p


## Who feels what for one sim cue: an array of {slot, kind, scale}, [] for a cue that rumbles nothing. The cue's own fields, as the sim
## sends them (`name` the cue's kind, or the event's type for transform_ready):
##   launcher_open        actor = the fighter who may launch           -> that slot, launch_open
##   transform_ready      actor                                        -> that slot, form_prompt
##   charge_full          actor = the charger                          -> that slot, charge_full
##   air_brake text "ready"  actor = the sent fighter (sim/core/brake.gd, -> that slot, brake_ready
##                        once a send, the first tick he could brake;
##                        start and end rumble nothing)
##   grapple_pulse        actor, target, amount = the catcher's grip   -> both, clinch_pulse, scaled by |grip| / 5
##   beam_surge           actor (the pusher), target, amount = the    -> the pusher struggle_push, the other struggle_pushed, both
##                        point after it, text "sharp" (a surge in the  scaled by the pusher's share of the point (a sharp one
##                        window's first tick)                          adds sharpBoost)
##   beam_end text "overwhelmed"   actor = the winner, target = the  -> the target, struggle_lose
##                        overwhelmed fighter
## `firer` is the slot that fired the struggle's first beam (the `beam_struggle` cue's actor, whose hands are the point's 0), which the
## host keeps; -1 if unknown (the surge's actor is then taken as the firer). A beam_stray and every other cue rumble nothing.
static func requests(name: String, actor: int, target: int, text: String, amount: float, firer: int = -1, source: String = "") -> Array:
	match name:
		"stick_refused":
			# Encounter's cue when it drops a stick request it cannot start (busy, stunned, in a struggle): actor = the presser. The truth, told as soon as the director knows.
			if not SimInputData.haptic_refused_on() or actor < 0 or actor > 1:
				return []
			if source == "hit" and SimInputData.haptic_impact_on():
				return []   # a blow that stopped the charge is felt as the blow itself (hit_taken, switches.hapticImpact): a second knock on the same tick is the same news twice. The screen word "Hit" stays UI's
			if source == "soon":
				return []   # a held release waiting on its target's gate is not a refusal: the screen word is enough (the EP, 2026-11-07)
			return [{"slot": actor, "kind": "stick_refused", "scale": 1.0, "reason": refusal_code(source if source != "" else text)}]   # the reason is the cue's source (text is the direction); an old caller with the reason in text still reads
		"press_refused":
			# The director's (or the block's) cue for a press that is not a stick request and was let go of: actor = the presser, source = a reason code (stun_limit, queue_expired, block_lockout).
			if not SimInputData.refusal_cues_on() or actor < 0 or actor > 1:
				return []
			return [{"slot": actor, "kind": "stick_refused", "scale": 1.0, "reason": refusal_code(source if source != "" else text)}]
		"stick_start":
			# Encounter's cue when a stick strike's request begins: actor = the striker, text = its direction as the defender faces it. The defender feels it (switches.hapticIncoming).
			if not SimInputData.haptic_incoming_on() or actor < 0 or actor > 1:
				return []
			match text:
				"toward", "up":
					return [{"slot": 1 - actor, "kind": "incoming_high", "scale": 1.0}]
				"away", "down":
					return [{"slot": 1 - actor, "kind": "incoming_low", "scale": 1.0}]
			return []
		"launcher_open":
			return [{"slot": actor, "kind": "launch_open", "scale": 1.0}] if actor >= 0 else []
		"transform_ready":
			return [{"slot": actor, "kind": "form_prompt", "scale": 1.0}] if actor >= 0 else []
		"charge_full":
			return [{"slot": actor, "kind": "charge_full", "scale": 1.0}] if actor >= 0 else []
		"air_brake":
			return [{"slot": actor, "kind": "brake_ready", "scale": 1.0}] if actor >= 0 and text == "ready" else []
		"grapple_pulse":
			var steps_n: float = float(maxi(1, SimInputData.ti(["haptics", "gripSteps"], GRIP_STEPS)))
			var sc: float = clampf(absf(amount) / steps_n, 0.0, 1.0)
			var out: Array = []
			if actor >= 0:
				out.append({"slot": actor, "kind": "clinch_pulse", "scale": sc})
			if target >= 0 and target != actor:
				out.append({"slot": target, "kind": "clinch_pulse", "scale": sc})
			return out
		"beam_surge":
			if actor < 0:
				return []
			var other: int = target if target >= 0 and target != actor else 1 - actor
			var share: float = push_share(amount, actor == firer or firer < 0)
			if text == "sharp":
				share = minf(1.0, share + SimInputData.tf(["haptics", "sharpBoost"], SHARP_BOOST))
			var res: Array = [{"slot": actor, "kind": "struggle_push", "scale": share}]
			if other >= 0 and other != actor:
				res.append({"slot": other, "kind": "struggle_pushed", "scale": share})
			return res
		"beam_end":
			# The sim's cue names the winner as the actor and the overwhelmed fighter as the target.
			return [{"slot": target, "kind": "struggle_lose", "scale": 1.0}] if text == "overwhelmed" and target >= 0 else []
	return []
