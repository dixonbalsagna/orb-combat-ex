#!/bin/bash
# apply.sh <checkout root> [--check]: copy the slice's files onto a checkout. Each file there must still be the base
# the slice was built on (base.txt: the hash of its text without carriage returns, and the path); if one has moved,
# nothing is copied. With --check it only says whether every base still matches, and copies nothing.
D="$(cd "$(dirname "$0")" && pwd)"
R="${1:-.}"
case "$2" in ""|--check) ;; *) echo "unknown option: $2 (nothing copied)"; exit 2;; esac
bad=0
while read -r h f; do
  now=$(tr -d '\015' < "$R/$f" | git hash-object --stdin 2>/dev/null)
  if [ "$now" != "$h" ]; then echo "moved since the slice was built: $f"; bad=1; fi
done < "$D/base.txt"
if [ "$bad" != "0" ]; then echo "nothing copied"; exit 1; fi
if [ "$2" = "--check" ]; then echo "every base matches; nothing copied (--check)"; exit 0; fi
while read -r h f; do
  cp "$D/files/$f" "$R/$f" || exit 1
  echo "copied $f"
done < "$D/base.txt"
