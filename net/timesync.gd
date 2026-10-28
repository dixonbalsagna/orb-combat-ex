class_name NetTimeSync
extends RefCounted
## Time sync by frame advantage (docs/net/rollback.md section 11): the peer that runs ahead waits a frame now and then,
## so neither drifts away and the other does not have to predict ever further. Pure: the host feeds it frame numbers and
## its round-trip estimate, and asks it each frame whether to wait.
## Each packet carries the sender's frame and its own advantage. On arrival the receiver estimates the sender's frame
## now as the packet's frame plus the one-way time in frames, and its advantage is its own frame minus that. If this
## peer's mean advantage over a window exceeds the other's, it is ahead by half the difference: every `every` frames it
## waits that many frames (at least `minLead` to act, at most `maxWait`), and the other peer, seeing the same numbers
## the other way round, does not. A wait reaches the other peer's reports a round trip later, so after one the means
## start afresh and take no samples until then (`quietUntil`): deciding on samples from before the wait overcorrects,
## and on a long link the two peers then take turns waiting.

const FRAME_MS: float = 1000.0 / 60.0

var window: int = 32      # samples in each mean
var every: int = 30       # frames between decisions
var minLead: int = 1      # a lead below this is left alone (it is noise)
var maxWait: int = 8      # the most frames one decision waits
var on: bool = true       # tests only: false never waits (the transport check's negative control)

var mine := PackedFloat32Array()     # this peer's advantage, recent samples
var theirs := PackedFloat32Array()   # the other's, as it reported
var current: float = 0.0             # the newest advantage, frames (sent in each packet)
var waitLeft: int = 0
var quietUntil: int = 0              # the frame from which samples count again after a wait
var rttFrames: int = 0               # the newest round trip, in frames
var nextDecision: int = 0
var waited: int = 0                  # frames waited in total
var decisions: int = 0


## A packet from the other peer: its frame when sent, the advantage it reported, and this peer's frame and round-trip
## estimate (ms) now.
func observe(localFrame: int, remoteFrame: int, remoteAdv: float, rttMs: float) -> void:
	var est: float = float(remoteFrame) + maxf(0.0, rttMs) * 0.5 / FRAME_MS
	current = float(localFrame) - est
	rttFrames = int(ceil(maxf(0.0, rttMs) / FRAME_MS))
	if localFrame < quietUntil:
		return
	mine.append(current)
	theirs.append(remoteAdv)
	if mine.size() > window:
		mine.remove_at(0)
	if theirs.size() > window:
		theirs.remove_at(0)


## The frames this peer should wait now, by the means.
func lead() -> int:
	if mine.is_empty() or theirs.is_empty():
		return 0
	return int(floor((_mean(mine) - _mean(theirs)) * 0.5))


## Each frame: true when this peer should wait this frame instead of running a tick.
func shouldWait(frameNo: int) -> bool:
	if waitLeft > 0:
		waitLeft -= 1
		waited += 1
		return true
	if not on or frameNo < nextDecision:
		return false
	nextDecision = frameNo + every
	if mine.size() < window / 2 or theirs.size() < window / 2:
		return false
	var l: int = lead()
	if l < minLead:
		return false
	decisions += 1
	waitLeft = mini(l, maxWait) - 1
	waited += 1
	mine.clear()
	theirs.clear()
	quietUntil = frameNo + rttFrames + 2
	nextDecision = maxi(nextDecision, quietUntil + window / 2)
	return true


static func _mean(a: PackedFloat32Array) -> float:
	var s: float = 0.0
	for v in a:
		s += v
	return s / float(a.size())
