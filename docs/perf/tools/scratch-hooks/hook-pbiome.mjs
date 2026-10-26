// SCRATCH HOOK (scratch export only): a scene `pb`, a planet match rendered in one view with both fighters idle (no input) in the middle of the longest stretch of a wanted ground of the match's ring,
// on a gen 1 or gen 2 planet. Page flags: pplanet=<planet seed> (default 7), pgen=1|2 (default 1), pbiome=desert|forest|city|coast (default desert; coast = the longest stretch where the ring's
// ocean share in a 41-column window is between 30 and 70 percent). The ring is a Whole ring of planet pplanet, touch 3. window.__pbinfo = {biome: [longest run in columns, its centre column], ...,
// cols, gen} says what the ring holds (a probe run reads it; a ring without the wanted ground puts the pair at the ring's middle and says found false). Apply after hook-perf.mjs.
import { readFileSync, writeFileSync } from 'node:fs';
const p = process.argv[2] + '/render/tools/flash_capture.gd';
let s = readFileSync(p, 'utf8');
s = s.replace('"mashdummy", "ring"', '"pb", "mashdummy", "ring"');
s = s.replace('"mashdummy": [false, true]', '"pb": [false, false], "mashdummy": [false, true]');
const a1 = '\t\t"ai":           # the real AI match, forms readied at 300 and 1500, a tier raised at 900';
if (!s.includes(a1)) throw new Error('anchor ai scenario');
s = s.replace(a1, '\t\t"pb":\n\t\t\tif t == 0:\n\t\t\t\t_pb_place(S)\n' + a1);
const a2 = '\tmain.start_match(seed if seed != 0 else SEED, ai_set, {} if slots.size() < 2 else {"slots": slots})';
if (!s.includes(a2)) throw new Error('anchor start_match');
s = s.replace(a2, '\tvar su_p: Dictionary = {} if slots.size() < 2 else {"slots": slots}\n\tif sc == "pb":\n\t\tsu_p = {"planet": int(_page_kv("pplanet")) if _page_kv("pplanet") != "" else 7, "touch": 3, "intro": false}\n\t\tif _page_kv("pgen") == "2":\n\t\t\tsu_p["planetGen"] = 2\n\tmain.start_match(seed if seed != 0 else SEED, ai_set, su_p)');
s += `

func _pb_place(S: SimState) -> void:
	var pc: PackedByteArray = WorldBiomes.planetCols
	var nc: int = SimConst.NC
	var info := {"cols": nc, "gen": 2 if _page_kv("pgen") == "2" else 1}
	if pc.size() < nc:
		info["error"] = "no planet columns"
		JavaScriptBridge.eval("window.__pbinfo = %s;" % JSON.stringify(info), true)
		return
	var names: Array = WorldPlanetWorld.BIOME_NAME
	var want: String = _page_kv("pbiome") if _page_kv("pbiome") != "" else "desert"
	var centre_want: int = nc / 2
	var found: bool = false
	for tgt in ["desert", "forest", "city", "coast"]:
		var best_len: int = 0
		var best_c: int = 0
		var run: int = 0
		for i in range(nc):
			var ok: bool = false
			if tgt == "coast":
				var oc: int = 0
				for k in range(-20, 21):
					if str(names[pc[posmod(i + k, nc)]]) == "ocean":
						oc += 1
				ok = oc >= 13 and oc <= 29
			else:
				ok = str(names[pc[i]]) == tgt
			if ok:
				run += 1
				if run > best_len:
					best_len = run
					best_c = i - run / 2
			else:
				run = 0
		info[tgt] = [best_len, best_c]
		if tgt == want and best_len >= (10 if tgt == "coast" else 30):
			centre_want = best_c
			found = true
	info["want"] = want
	info["found"] = found
	JavaScriptBridge.eval("window.__pbinfo = %s;" % JSON.stringify(info), true)
	for i in range(2):
		var f = S.fighters[i]
		f.x = SimWrap.wrap((float(centre_want) + 0.5) * SimConst.COL + 60.0 * float(i))
		f.y = WorldTerrain.groundY(S, f.x) + 10.0
		f.vx = 0.0
		f.vy = 0.0
`;
writeFileSync(p, s); console.log('pbiome hook applied');
