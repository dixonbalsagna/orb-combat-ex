class_name RenderCameraRoll
extends RefCounted
## A dutch tilt on the fight's top climaxes (the EP's briefs of 2026-10-22; docs/rendering/camera-roll.md). The main
## panes' cameras roll about their view axis by RenderLook.ROLL_DEG.x to .y degrees: in over ROLL_TIMES.x of match time,
## held ROLL_TIMES.y, back over ROLL_TIMES.z, eased. Motivated and rare:
## - the sim's climax event decides when: a finisher's start or a KO (RenderLook.ROLL_EVENTS), or a decisive exchange
##   won by a beam clash, a guard break or a launch (ROLL_DECISIVE); a plain knock-back does not roll;
## - at least ROLL_GAP_S of match time between two rolls' starts, except for a finisher's start and a KO;
## - how much and which way: with Encounter's camera-intent feed on and a story live in Camera's split rig, the story
##   (its weight, never under the event's; toward story_d's side of story_a); otherwise the event's own weight, toward
##   the loser's side of the winner.
## Off unless RenderLook.CAMERA_ROLL_ON or main's --roll. The HUD (UI's canvas) is never rotated, and Camera's inset
## strip stays level.
## Reads the sim's events, its fighters' places and the rig's story only; writes nothing; draws no random number.

var angle_deg: float = 0.0     # this frame's roll, signed
var _from: float = 0.0
var _to: float = 0.0
var _t0: float = -1.0          # the match time the current roll began; -1: none
var _last: float = -INF        # the match time the last roll began, for ROLL_GAP_S


## A new match: no roll, and no gap to wait out.
func reset() -> void:
	_end()
	_last = -INF


func _end() -> void:
	angle_deg = 0.0
	_from = 0.0
	_to = 0.0
	_t0 = -1.0


## A tick's events: a top climax starts a roll from where the camera stands now (a new climax mid-roll turns it, never
## snaps it). rig: Camera's split rig when main steps it (the split view attached; it has read this tick's cam_intent
## cues already), else null.
func consume(S: SimState, events: Array, rig = null) -> void:
	if S.T < _last:
		_last = -INF   # the match went back (a seek)
	for e in events:
		var ty: String = String(e.type)
		var w: float = -1.0
		var win: int = -1
		var lose: int = -1
		if ty == "decisive" and RenderLook.ROLL_DECISIVE.has(String(e.kind)):
			w = float(RenderLook.ROLL_DECISIVE[String(e.kind)])
			win = int(e.winner)
			lose = int(e.loser)
		elif ty == "finisher_start" and RenderLook.ROLL_EVENTS.has(ty):
			w = float(RenderLook.ROLL_EVENTS[ty])
			win = int(e.actor)
			lose = int(e.target)
		elif ty == "ko" and RenderLook.ROLL_EVENTS.has(ty):
			w = float(RenderLook.ROLL_EVENTS[ty])
			win = int(e.winner)
			lose = int(e.loser)
		if w < 0.0:
			continue
		if not RenderLook.ROLL_EVENTS.has(ty) and S.T - _last < RenderLook.ROLL_GAP_S:
			continue   # too soon after the last roll
		if rig != null and rig.intent_feed and DirCamIntent.on() and _story_live(S, rig):
			var tags: Array = rig.story_tags
			w = maxf(w, 1.0 if tags.has("finisher") else clampf((float(rig.story_w) - 1.0) / 4.0, 0.25, 1.0))
			win = int(rig.story_a)
			lose = int(rig.story_d)
		_roll_to(S, win, lose, w)


## The rig holds a told plan's story now (Camera's story slots), with both its fighters.
func _story_live(S: SimState, rig) -> bool:
	var a: int = int(rig.story_a)
	var d: int = int(rig.story_d)
	if a < 0 or d < 0 or a >= S.fighters.size() or d >= S.fighters.size() or a == d:
		return false
	return int(rig.story_w) > 0 or not rig.story_tags.is_empty()


func _roll_to(S: SimState, win: int, lose: int, w: float) -> void:
	if win < 0 or lose < 0 or win >= S.fighters.size() or lose >= S.fighters.size() or win == lose:
		return
	var dx: float = SimWrap.sdx(S.fighters[win].x, S.fighters[lose].x)
	_from = angle_deg
	_to = (1.0 if dx >= 0.0 else -1.0) * lerpf(RenderLook.ROLL_DEG.x, RenderLook.ROLL_DEG.y, w)
	_t0 = S.T
	_last = S.T


## The roll at match time t (the tick's time plus the frame's share of the next): eased in, held, eased out.
func update(t: float) -> float:
	if _t0 < 0.0:
		return 0.0
	if t < _t0:
		reset()   # the match went back (a new match or a seek)
		return 0.0
	var ti: Vector3 = RenderLook.ROLL_TIMES
	var e: float = t - _t0
	if e < ti.x:
		angle_deg = lerpf(_from, _to, smoothstep(0.0, 1.0, e / ti.x))
	elif e < ti.x + ti.y:
		angle_deg = _to
	elif e < ti.x + ti.y + ti.z:
		angle_deg = lerpf(_to, 0.0, smoothstep(0.0, 1.0, (e - ti.x - ti.y) / ti.z))
	else:
		_end()
	return angle_deg
