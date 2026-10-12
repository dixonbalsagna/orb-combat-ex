#!/bin/bash
# apply.sh <checkout root>: copy the slice's files onto a checkout. Each file there must still be the base the slice
# was built on (base.txt: the hash of its text without carriage returns, and the path); if one has moved, nothing is
# copied.
D="$(cd "$(dirname "$0")" && pwd)"
R="${1:-.}"
bad=0
while read -r h f; do
  now=$(tr -d '\015' < "$R/$f" | git hash-object --stdin 2>/dev/null)
  if [ "$now" != "$h" ]; then echo "moved since the slice was built: $f"; bad=1; fi
done < "$D/base.txt"
if [ "$bad" != "0" ]; then echo "nothing copied"; exit 1; fi
while read -r h f; do
  cp "$D/files/$f" "$R/$f" || exit 1
  echo "copied $f"
done < "$D/base.txt"
