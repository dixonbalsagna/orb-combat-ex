"""Window 9 (World, 2026-10-23): Simulation's two notes on window 8.   python mk_w9.py <root>   (root: windows 2 to 8)
 1. skate.json is hashed as its parsed data without the "_" keys (FighterData._canon), as contact.json is, not as raw text
 2. the reference run is its own function (_refRun) so a check can prove it writes nothing to the state"""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def contact(s):
    s = rep(s, '''static var _skateHash: String = ""''', '''static var _skateParsed: Dictionary = {}''')
    s = rep(s, '''		h.text("skate")
		h.text(_skateHash)   # ruling 12's switch, on: a replay must know''', '''		h.text("biomes.skate")
		FighterData._canon(h, _skateParsed)   # the parsed data without the "_" notes, like contact.json: a changed note keeps old replays''')
    s = rep(s, '''				_skateHash = str(text.hash())''', '''				_skateParsed = j''')
    s = rep(s, '''			var ref: Body = _cloneBody(b)
			_refOn = true
			var rt: int = 0
			while not ref.done and rt < TICK_CAP:
				stepBody(S, ref, SimConst.DT, [])
				rt += 1
			_refOn = false
			f.ctrlT = int(f.jT) + rt''', '''			f.ctrlT = int(f.jT) + _refRun(S, b)''')
    s = rep(s, '''## The skate after control is back''', '''## The reference run of a skid: a copy of the body stepped on reference ground to its end, the ticks it takes. It reads the state and writes nothing to it (the steps' events go to a throwaway list; no
## terrain, crater, fx or random draw): skate_check proves the state hash is the same with it and without.
static func _refRun(S: SimState, b: Body) -> int:
	var ref: Body = _cloneBody(b)
	_refOn = true
	var rt: int = 0
	while not ref.done and rt < TICK_CAP:
		stepBody(S, ref, SimConst.DT, [])
		rt += 1
	_refOn = false
	return rt


## The skate after control is back''')
    return s


rw(R, 'sim/world/contact.gd', contact)
print('w9 applied')
