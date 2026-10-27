// SCRATCH HOOK (scratch export only; needs hook-bootprof2.mjs, and Audio's first park, which HEAD has from 1b3f5a29): a mark when the async audio warm-up ends (the bank's `warmed` signal), and every 20
// frames the bank's counters: window.__bpskip = [[frame, performance.now() ms, skipped, warming, deferred_played], ...] (at most 700 samples), and window.__bpreport = the bank's skipped_report() text when
// the re-cut has one (named skipped cues, played-late count). Properties the tree lacks read as -1 or an empty string.
import { readFileSync, writeFileSync } from 'node:fs';
const p = process.argv[2] + '/render/core/main.gd';
let s = readFileSync(p, 'utf8');
const a = '\thost.audio_cues.bank.warm()';
const i = s.indexOf(a);
if (i < 0) throw new Error('anchor: bank.warm()');
const eol = s.indexOf('\n', i);
s = s.slice(0, eol + 1) + '\tif "warmed" in host.audio_cues.bank:\n\t\thost.audio_cues.bank.warmed.connect(func(): _bp("warm_async_done"))\n' + s.slice(eol + 1);
const pr = 'func _process(delta: float) -> void:\n';
if (!s.includes(pr)) throw new Error('anchor: _process');
s = s.replace(pr, pr + '\tif frames % 20 == 0:\n\t\t_bps()\n');
s += `

var _bps_n: int = 0


func _bps() -> void:
	if not OS.has_feature("web") or _bps_n >= 700 or host == null:
		return
	var b = host.audio_cues.bank
	if not ("skipped" in b):
		return
	_bps_n += 1
	var dp: int = int(b.deferred_played) if "deferred_played" in b else -1
	JavaScriptBridge.eval("(window.__bpskip = window.__bpskip || []).push([%d, performance.now(), %d, %s, %d]);" % [frames, int(b.skipped), "true" if bool(b.warming) else "false", dp], true)
	if b.has_method("skipped_report"):
		JavaScriptBridge.eval("window.__bpreport = %s;" % JSON.stringify(str(b.skipped_report())), true)
`;
writeFileSync(p, s); console.log('audio warm marks v2 applied');
