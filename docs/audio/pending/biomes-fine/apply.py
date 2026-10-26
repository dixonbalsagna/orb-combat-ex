# APPLY the fine-biome sound park (docs/audio/pending/biomes-fine/README.md). Audio's own files only.
# Usage: python apply.py <root> [--check]
#   <root> is the tree to change: a scratch export first, the repo root only for the EP's apply (ends with a commit).
#   --check changes nothing and says whether every file is as the park expects.
# Each file in src/ replaces the one at the same path in <root>; its current text (line endings aside) must be the one the park was made
# from (old_hashes.json), so a file someone else has changed since is not overwritten.
import hashlib, json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, 'src')
root = sys.argv[1]
check = '--check' in sys.argv[2:]
old = json.load(open(os.path.join(HERE, 'old_hashes.json'), encoding='utf-8'))
problems = []
done = []
for dirpath, _, files in os.walk(SRC):
    for f in files:
        src = os.path.join(dirpath, f)
        rel = os.path.relpath(src, SRC).replace(os.sep, '/')
        dst = os.path.join(root, rel)
        if not os.path.exists(dst):
            problems.append('%s: not in the tree (apply the biome park first)' % rel)
            continue
        raw = open(dst, encoding='utf-8', newline='').read()
        crlf = '\r\n' in raw
        cur = hashlib.sha256(raw.replace('\r\n', '\n').encode('utf-8')).hexdigest()
        if cur != old.get(rel):
            problems.append('%s: has changed since this park was made' % rel)
            continue
        new = open(src, encoding='utf-8', newline='').read().replace('\r\n', '\n')
        done.append(rel)
        if not check:
            open(dst, 'w', encoding='utf-8', newline='').write(new.replace('\n', '\r\n') if crlf else new)
if problems:
    print('NOT APPLIED. %d problem(s):' % len(problems))
    for p in problems:
        print('  ' + p)
    sys.exit(1)
print(('CHECKED' if check else 'APPLIED') + ': ' + str(len(done)) + ' files: ' + ', '.join(done))
