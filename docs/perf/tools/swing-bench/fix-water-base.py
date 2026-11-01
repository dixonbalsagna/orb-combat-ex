# PROPOSAL, applied to a scratch tree only (World owns sim/world/water.gd): WorldWater.step's flow window reads WorldTerrain.baseAt (a field world: SimField.col) three times per column per water tick;
# read each column once into a local array and use it in both loops. Results are the same reads in the same order of use, so the flow is bit-identical (baseAt does not change inside the step).
#   python fix-water-base.py <tree>
import sys
p = sys.argv[1] + '/sim/world/water.gd'
s = open(p, encoding='utf8').read()


def sw(a, b):
    global s
    assert s.count(a) == 1, (a[:70], s.count(a))
    s = s.replace(a, b)


sw("\t\tvar flux := PackedFloat32Array()\n\t\tflux.resize(hi - lo + 1)   # flux[j - lo]: depth moving from column j to column j + 1 (negative: the other way)\n\t\tvar b: int = posmod(lo, NC)\n\t\tvar gb: float = WorldTerrain.baseAt(S, b) + dfm[b]\n\t\tvar rb: bool = WorldTerrain.baseAt(S, b) < RESERVOIR_BASE\n",
   "\t\tvar flux := PackedFloat32Array()\n\t\tflux.resize(hi - lo + 1)   # flux[j - lo]: depth moving from column j to column j + 1 (negative: the other way)\n\t\tvar bs := PackedFloat64Array()   # the base of each column of the window, read once (a field world reads it through SimField.col)\n\t\tbs.resize(hi - lo + 1)\n\t\tfor j in range(lo, hi + 1):\n\t\t\tbs[j - lo] = WorldTerrain.baseAt(S, posmod(j, NC))\n\t\tvar b: int = posmod(lo, NC)\n\t\tvar gb: float = bs[0] + dfm[b]\n\t\tvar rb: bool = bs[0] < RESERVOIR_BASE\n")
sw("\t\t\tgb = WorldTerrain.baseAt(S, b) + dfm[b]\n\t\t\trb = WorldTerrain.baseAt(S, b) < RESERVOIR_BASE\n",
   "\t\t\tgb = bs[j + 1 - lo] + dfm[b]\n\t\t\trb = bs[j + 1 - lo] < RESERVOIR_BASE\n")
sw("\t\t\tif WorldTerrain.baseAt(S, i) < RESERVOIR_BASE:\n\t\t\t\tcontinue\n", "\t\t\tif bs[j - lo] < RESERVOIR_BASE:\n\t\t\t\tcontinue\n")
open(p, 'w', encoding='utf8').write(s)
print('fix-water-base applied')
