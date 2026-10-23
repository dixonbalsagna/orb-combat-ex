# PARKED TOOL (Simulation): web parity, the native and web (wasm) builds' sim compared bit for bit
# (docs/architecture/web-parity.md). Adds sim/core/tools/web_parity.gd and .tscn (the probe) and web_parity.mjs (the
# one-command check). Nothing in the game reads them; the golden does not move. The CI job is Tools' (README).
# Usage: python apply.py <repo root>
import os, shutil, sys
HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(sys.argv[1])
FILES = ['sim/core/tools/web_parity.gd', 'sim/core/tools/web_parity.tscn', 'sim/core/tools/web_parity.mjs']
for f in FILES:
    assert not os.path.exists(f), f + ' is already there'
for f in FILES:
    shutil.copyfile(os.path.join(HERE, 'files', f + '.txt'), f)
print("web parity: the probe and the check")
