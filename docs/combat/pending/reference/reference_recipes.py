# PARKED BUILD (Combat): the training dummy's moveset, for the window with Simulation's dummy_roster.py (docs/architecture/pending/n-bodies/).
# Adds REFERENCE's entries, keyed `reference`, to data/combat/recipes.json from reference.recipes.json beside this script: his pools, the burst's close and
# samples, the launcher by send, the fallback report and his counts. He has no energy in reach (no energy piece is common). Nothing else in the file changes, and no piece row is
# added: every piece he names is already in the pieces table. data/director/alchemy.json needs no entry (a fighter it does not list uses his id in lower case).
# Usage: python reference_recipes.py <repo root> [--check]
#   --check   say whether it applies cleanly (or is already in, and the same), and write nothing
import io, json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
root = sys.argv[1]
check = "--check" in sys.argv
p = os.path.join(root, "data", "combat", "recipes.json")
text = io.open(p, encoding="utf-8", newline="").read()
rec = json.loads(text)
frag = json.load(io.open(os.path.join(HERE, "reference.recipes.json"), encoding="utf-8"))
W = frag["fighter"]
assert json.dumps(rec, indent=2, ensure_ascii=True) + "\n" == text, "data/combat/recipes.json is not in its usual form (indent 2, ASCII): stop and ask Combat"

# where each entry goes
PLACES = {"pools": ("pools",), "burst.close": ("burst", "close"), "burst.samples": ("burst", "samples"), "launcher.bySend": ("launcher", "bySend"),
          "launcher.bySendLower": ("launcher", "bySendLower"), "reach.pieces": ("reach", "pieces"), "reach.runs": ("reach", "runs"),
          "reach.after": ("reach", "after"), "fallback.onTheTier": ("fallback", "onTheTier"), "_counts": ("_counts",)}
PLACES = {k: v for k, v in PLACES.items() if k in frag}   # an entry the fragment does not hold (his energy in reach) is left out
def at(path):
    d = rec
    for k in path:
        d = d[k]
    return d

# the pools the brawl's cells name today: he must have each, or his blows in that cell go without a piece
named = sorted(set(v for k, v in rec["brawl"].items() if not k.startswith("_")) | set(rec["fallback"]["lower"].values()))
energy = ("reach.bolt", "reach.blast")   # no energy piece is common: these he goes without, as intended
lacking = [n for n in named if n not in frag["pools"] and n not in energy]
pieces = set(e["id"] for v in frag["pools"].values() for e in v) | set(i for k in ("launcher.bySend", "launcher.bySendLower") for v in frag[k].values() for i in v)
unknown = sorted(i for i in pieces if i not in rec["pieces"])
present = [k for k, path in PLACES.items() if W in at(path)]

problems = []
if lacking:
    problems.append("the brawl names pools his fragment does not have (a later window changed the cells; Combat regenerates the fragment): " + ", ".join(lacking))
if unknown:
    problems.append("pieces that are not rows of the pieces table: " + ", ".join(unknown))
if present and len(present) < len(PLACES):
    problems.append("partly applied already: " + ", ".join(present))
same = present and len(present) == len(PLACES) and all(at(path)[W] == frag[k] for k, path in PLACES.items())
if present and len(present) == len(PLACES) and not same:
    problems.append("already in, and different from the fragment")
if problems:
    print("reference_recipes.py: NOT APPLIED")
    for x in problems:
        print("  " + x)
    sys.exit(1)
if same:
    print("reference_recipes.py: already in, and the same. Nothing to do")
    sys.exit(0)
if check:
    print("reference_recipes.py --check: applies cleanly (%d pools, %d pieces, all rows of the pieces table). Nothing written" % (len(frag["pools"]), len(pieces)))
    sys.exit(0)
for k, path in PLACES.items():
    at(path)[W] = frag[k]
io.open(p, "w", encoding="utf-8", newline="\n").write(json.dumps(rec, indent=2, ensure_ascii=True) + "\n")
print("reference_recipes.py: REFERENCE's moveset written into data/combat/recipes.json (%d pools, %d pieces)" % (len(frag["pools"]), len(pieces)))
