// SCRATCH HOOK (scratch export only; needs Audio's park docs/audio/pending/warm-async applied first and hook-bootprof2.mjs): a mark when the async audio warm-up ends (the bank's `warmed` signal), and every
// 20 frames the bank's skipped-cue count, window.__bpskip = [[frame, performance.now() ms, skipped, warming], ...] (at most 700 samples).
import { readFileSync, writeFileSync } from 'node:fs';
const p = process.argv[2] + '/render/core/main.gd';
let s = readFileSync(p, 'utf8');
const a = '\thost.audio_cues.bank.warm()';
const i = s.indexOf(a);
if (i < 0) throw new Error('anchor: bank.warm()');
const eol = s.indexOf('\n', i);
s = s.slice(0, eol + 1) + '\tif "warmed" in host.audio_cues.bank:\n\t\thost.audio_cues.bank.warmed.connect(func(): _bp("warm_async_done"))\n' + s.slice(eol + 1);
s = s.replace('func _process(delta: float) -> void:\n', 'func _process(delta: float) -> void:\n\tif frames % 20 == 0:\n\t\t_bps()\n');
s += `

var _bps_n: int = 0


func _bps() -> void:
	if not OS.has_feature("web") or _bps_n >= 700 or host == null:
		return
	var b = host.audio_cues.bank
	if not ("skipped" in b):
		return
	_bps_n += 1
	JavaScriptBridge.eval("(window.__bpskip = window.__bpskip || []).push([%d, performance.now(), %d, %s]);" % [frames, int(b.skipped), "true" if bool(b.warming) else "false"], true)
`;
writeFileSync(p, s); console.log('audio warm marks applied');
