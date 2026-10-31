// SCRATCH HOOK (a scratch tree only): own-time counters on the re-cut field-frame's swing.gd (the one with S.bList, poseReach/poseBody/poseShot in data), for swing_bench2.gd.
//   node hook-7-recut.mjs <tree>
// SimSwing.tus: the swing tick's own microseconds; tlist/nlay: _poseList and how many times it laid the list again; tpose/nposes: _poses; trb/nrb: _rebucket (a building crossing a bucket). Static, never a sim input.
import { readFileSync, writeFileSync } from 'node:fs';
const root = process.argv[2];
if (!root) throw new Error('usage: node hook-7-recut.mjs <tree>');
const f = `${root}/sim/core/swing.gd`;
let s = readFileSync(f, 'utf8');
const swap = (from, to) => { const n = s.split(from).length - 1; if (n !== 1) throw new Error(`"${from.slice(0, 70)}" found ${n} times`); s = s.replace(from, to); };
swap('static func tick(S: SimState) -> void:\n', `static var tus: int = 0
static var tlist: int = 0
static var nlay: int = 0
static var tpose: int = 0
static var nposes: int = 0
static var trb: int = 0
static var nrb: int = 0


static func tick(S: SimState) -> void:
	var _t0: int = Time.get_ticks_usec()
	_tick0(S)
	tus += Time.get_ticks_usec() - _t0


static func _tick0(S: SimState) -> void:
`);
swap('static func _poses(S: SimState, all: bool) -> void:\n', `static func _poses(S: SimState, all: bool) -> void:
	var _t0: int = Time.get_ticks_usec()
	_poses0(S, all)
	tpose += Time.get_ticks_usec() - _t0
	nposes += 1


static func _poses0(S: SimState, all: bool) -> void:
`);
swap('static func _poseList(S: SimState) -> PackedInt32Array:\n', `static func _poseList(S: SimState) -> PackedInt32Array:
	var _t0: int = Time.get_ticks_usec()
	var r: PackedInt32Array = _poseList0(S)
	tlist += Time.get_ticks_usec() - _t0
	return r


static func _poseList0(S: SimState) -> PackedInt32Array:
`);
swap('\tS.bListKey = key\n\tS.bListN = sw.n\n', '\tS.bListKey = key\n\tS.bListN = sw.n\n\tnlay += 1\n');
swap('static func _rebucket(S: SimState, i: int, k0: int, k1: int) -> void:\n', `static func _rebucket(S: SimState, i: int, k0: int, k1: int) -> void:
	var _t0: int = Time.get_ticks_usec()
	_rebucket0(S, i, k0, k1)
	trb += Time.get_ticks_usec() - _t0
	nrb += 1


static func _rebucket0(S: SimState, i: int, k0: int, k1: int) -> void:
`);
writeFileSync(f, s);
console.log('hook-7 applied to', root);
