# APPLY the audio warm-up across frames (docs/audio/pending/warm-async/README.md). Audio's own files only.
# Usage: python apply.py <root> [--check]      (a scratch export first; the repo root only for the EP's apply, ending with a commit)
# Each file in src/ replaces the one at the same path in <root>, where that file is what the park was made from (old_hashes.json); files with no
# entry there are new and must not exist yet. Line endings of the target are kept.
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
        if rel in old:
            if not os.path.exists(dst):
                problems.append('%s: not in the tree' % rel)
                continue
            raw = open(dst, encoding='utf-8', newline='').read()
            crlf = '\r\n' in raw
            if hashlib.sha256(raw.replace('\r\n', '\n').encode('utf-8')).hexdigest() != old[rel]:
                problems.append('%s: has changed since this park was made' % rel)
                continue
            new = open(src, encoding='utf-8', newline='').read().replace('\r\n', '\n')
            if not check:
                open(dst, 'w', encoding='utf-8', newline='').write(new.replace('\n', '\r\n') if crlf else new)
        else:
            if os.path.exists(dst):
                problems.append('%s: already there' % rel)
                continue
            if not check:
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                with open(src, 'rb') as a, open(dst, 'wb') as b:
                    b.write(a.read())
        done.append(rel)
if problems:
    print('NOT APPLIED. %d problem(s):' % len(problems))
    for p in problems:
        print('  ' + p)
    sys.exit(1)
print(('CHECKED' if check else 'APPLIED') + ': ' + str(len(done)) + ' files: ' + ', '.join(sorted(done)))
