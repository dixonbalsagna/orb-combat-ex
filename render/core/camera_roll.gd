class_name RenderCameraRoll
extends RefCounted
## A dutch tilt on the fight's climaxes (the EP's brief of 2026-10-22; docs/rendering/camera-roll.md). The main panes'
## cameras roll about their view axis by RenderLook.ROLL_DEG.x to .y degrees on a decisive exchange won (a launch, a
## guard break or an interrupt light; a clash or a beam more), a finisher's start or a KO (the most), leaning toward the
## loser's side of the winner: in over ROLL_TIMES.x of match time, held ROLL_TIMES.y, back over ROLL_TIMES.z, eased.
## Off unless RenderLook.CAMERA_ROLL_ON or main's --roll. The HUD (UI's canvas) is never rotated, and Camera's inset
## strip stays level.
## Reads the sim's events and its fighters' places only; writes nothing; draws no random number.

var angle_deg: float = 0.0     # this frame's roll, signed
var _from: float = 0.0
var _to: float = 0.0
var _t0: float = -1.0          # the match time the current roll began; -1: none


func reset() -> void:
	angle_deg = 0.0
	_from = 0.0
	_to = 0.0
	_t0 = -1.0


## A tick's events: a decisive exchange, a finisher's start or a KO starts a roll toward the loser's side, from where the
## camera stands now (a new climax mid-roll turns it, never snaps it).
func consume(S: SimState, events: Array) -> void:
	for e in events:
		var ty: String = String(e.type)
		var w: float = -1.0
		var win: int = -1
		var lose: int = -1
		if ty == "decisive":
			w = 0.5 if ["clash", "beam", "beam_clash"].has(String(e.kind)) else 0.25
			win = int(e.winner)
			lose = int(e.loser)
		elif ty == "finisher_start":
			w = 1.0
			win = int(e.actor)
			lose = int(e.target)
		elif ty == "ko":
			w = 1.0
			win = int(e.winner)
			lose = int(e.loser)
		if w < 0.0 or win < 0 or lose < 0 or win >= S.fighters.size() or lose >= S.fighters.size() or win == lose:
			continue
		var dx: float = SimWrap.sdx(S.fighters[win].x, S.fighters[lose].x)
		_from = angle_deg
		_to = (1.0 if dx >= 0.0 else -1.0) * lerpf(RenderLook.ROLL_DEG.x, RenderLook.ROLL_DEG.y, w)
		_t0 = S.T


## The roll at match time t (the tick's time plus the frame's share of the next): eased in, held, eased out.
func update(t: float) -> float:
	if _t0 < 0.0 or t < _t0:
		reset()   # none, or the match went back (a new match or a seek)
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
		reset()
	return angle_deg
