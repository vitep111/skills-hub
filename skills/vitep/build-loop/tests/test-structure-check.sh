#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
CHECK="$HERE/../scripts/structure-check"
PASS=0; FAIL=0

expect() {
  local want="$1" name="$2"; shift 2
  local out; out="$("$@" 2>&1)"; local got=$?
  if [ "$got" -eq "$want" ]; then PASS=$((PASS+1)); echo "ok   - $name"
  else FAIL=$((FAIL+1)); echo "FAIL - $name (exit $got, wanted $want): $out"; fi
}

# The real skill directory must validate.
expect 0 "the shipped skill-map validates" "$CHECK"

# A stage pointing at a nonexistent gap file must fail.
tmp="$(mktemp -d)"; cp -r "$HERE/.." "$tmp/build-loop"
echo '| 9.9 | invented stage | phases/99-nope.md |' >> "$tmp/build-loop/reference/skill-map.md"
expect 1 "a stage naming a missing gap file fails" "$tmp/build-loop/scripts/structure-check"

echo ""; echo "passed: $PASS  failed: $FAIL"; [ "$FAIL" -eq 0 ]
