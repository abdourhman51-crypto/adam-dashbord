#!/usr/bin/env bash
# The shared law block must be byte-identical in every agent prompt.
#
# It is duplicated on purpose: each n8n node receives one standalone string and
# cannot import a file. Duplication without a check is how it drifted before —
# the promise was rewritten across four parent-facing screens in August 2026
# while four prompts kept teaching the old product for a month.
#
# Run from anywhere:  bash docs/prompts/check-law.sh
# Exit 0 = identical everywhere. Exit 1 = drift, with the offenders named.

set -uo pipefail
cd "$(dirname "$0")"

START='=== ما الذي نغيّره'
END='• أي شيء يشبه محاضرة تربوية، أو مديحاً عامّاً: «أحسنت»، «رائع»، «ممتاز».'

extract() {
  python3 -c '
import sys
path, start, end = sys.argv[1], sys.argv[2], sys.argv[3]
t = open(path, encoding="utf-8").read()
try:
    s = t.index(start)
    e = t.index(end) + len(end)
except ValueError:
    sys.stderr.write("MISSING LAW BLOCK: " + path + "\n")
    sys.exit(2)
sys.stdout.write(t[s:e])
' "$1" "$START" "$END"
}

FILES=(README.md adam-conversation-agent.md adam-seed-composer.md
        adam-journey-step.md adam-tantrum-reading.md)

canon=$(extract README.md) || { echo "cannot read canonical law from README.md"; exit 1; }
canon_sum=$(printf '%s' "$canon" | md5sum | cut -d' ' -f1)

fail=0
for f in "${FILES[@]}"; do
  body=$(extract "$f") || { fail=1; continue; }
  sum=$(printf '%s' "$body" | md5sum | cut -d' ' -f1)
  if [ "$sum" = "$canon_sum" ]; then
    printf '  ok    %s\n' "$f"
  else
    printf '  DRIFT %s\n' "$f"
    diff <(printf '%s\n' "$canon") <(printf '%s\n' "$body") | sed 's/^/        /'
    fail=1
  fi
done

if [ "$fail" -ne 0 ]; then
  echo
  echo "The law in README.md is the correct one. Copy it over the drifted file(s)."
  echo "Agent-specific rules belong AFTER the block, under:"
  echo "  === زيادات خاصة بهذا الوكيل — تُضاف ولا تناقض ==="
  exit 1
fi

echo
echo "law identical in ${#FILES[@]} files (${canon_sum:0:12})"
