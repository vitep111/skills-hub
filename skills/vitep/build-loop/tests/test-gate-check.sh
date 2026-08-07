#!/usr/bin/env bash
# Fixture-driven tests for gate-check. No external test framework.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
GATE_CHECK="$HERE/../scripts/gate-check"
PASS=0; FAIL=0

# Build a run directory from a phase table body passed on stdin.
mkrun() {
  local dir; dir="$(mktemp -d)"
  { echo "# Run: test"
    echo "idea: test   date: 2026-08-07   tier: small"
    echo ""
    echo "## Phases"
    echo "| phase | status | artifact | reason |"
    echo "|-------|--------|----------|--------|"
    cat
    echo ""
    echo "## Deferred minors"
  } > "$dir/00-run.md"
  echo "$dir"
}

expect() {
  local want="$1" name="$2"; shift 2
  local out; out="$("$@" 2>&1)"; local got=$?
  if [ "$got" -eq "$want" ]; then
    PASS=$((PASS+1)); echo "ok   - $name"
  else
    FAIL=$((FAIL+1)); echo "FAIL - $name (exit $got, wanted $want): $out"
  fi
}

# 1. A complete gate-0 ledger passes.
d=$(mkrun <<'EOF'
| 0 | done | 00-bootstrap.md | |
EOF
)
echo "bootstrap" > "$d/00-bootstrap.md"
expect 0 "gate 0 passes with a done phase 0" "$GATE_CHECK" "$d" 0

# 2. A done row whose artifact does not exist fails.
d=$(mkrun <<'EOF'
| 0 | done | 00-bootstrap.md | |
EOF
)
expect 1 "done row with missing artifact fails" "$GATE_CHECK" "$d" 0

# 3. A done row whose artifact is empty fails.
d=$(mkrun <<'EOF'
| 0 | done | 00-bootstrap.md | |
EOF
)
: > "$d/00-bootstrap.md"
expect 1 "done row with empty artifact fails" "$GATE_CHECK" "$d" 0

# 4. A missing phase row fails.
d=$(mkrun <<'EOF'
| 0 | done | 00-bootstrap.md | |
| 2 | open | | |
EOF
)
echo x > "$d/00-bootstrap.md"
expect 1 "gate 1 fails when phase 1 has no row" "$GATE_CHECK" "$d" 1

# 5. The currently open phase is exempt from the artifact requirement.
d=$(mkrun <<'EOF'
| 0 | done | 00-bootstrap.md | |
| 1 | done | 01-discovery.md | |
| 2 | open | | |
EOF
)
echo x > "$d/00-bootstrap.md"; echo x > "$d/01-discovery.md"
expect 0 "gate 1 passes with its own phase still open" "$GATE_CHECK" "$d" 1

# 6. An earlier phase left open fails.
d=$(mkrun <<'EOF'
| 0 | done | 00-bootstrap.md | |
| 1 | open | | |
| 2 | open | | |
EOF
)
echo x > "$d/00-bootstrap.md"
expect 1 "gate 1 fails when an earlier phase is still open" "$GATE_CHECK" "$d" 1

# 7. A blocked phase fails.
d=$(mkrun <<'EOF'
| 0 | blocked | | deploy creds missing |
EOF
)
expect 1 "blocked phase fails" "$GATE_CHECK" "$d" 0

# 8. A directory artifact must contain at least one file.
d=$(mkrun <<'EOF'
| 0 | done | 04-tickets | |
EOF
)
mkdir -p "$d/04-tickets"
expect 1 "empty directory artifact fails" "$GATE_CHECK" "$d" 0
echo x > "$d/04-tickets/01-first.md"
expect 0 "directory artifact with a file passes" "$GATE_CHECK" "$d" 0

# 9. Gate 2 requires the architecture and contract artifacts.
d=$(mkrun <<'EOF'
| 0 | done | 00-bootstrap.md | |
| 1 | done | 01-discovery.md | |
| 2 | done | 02-design.md | |
| 3 | done | 03-spec.md | |
| 4 | open | | |
EOF
)
for f in 00-bootstrap 01-discovery 02-design 03-spec; do echo x > "$d/$f.md"; done
expect 1 "gate 2 fails without 03-architecture.md" "$GATE_CHECK" "$d" 2
echo x > "$d/03-architecture.md"
expect 1 "gate 2 fails without 03-contracts.md" "$GATE_CHECK" "$d" 2
echo x > "$d/03-contracts.md"
expect 0 "gate 2 passes with both" "$GATE_CHECK" "$d" 2

# 10. Gate 3 requires CI evidence and a triage line per deferred minor.
mkgate3() {
  local dir; dir="$(mktemp -d)"
  { echo "# Run: test"
    echo ""
    echo "## Phases"
    echo "| phase | status | artifact | reason |"
    echo "|-------|--------|----------|--------|"
    for p in 0 1 2 3 4 5 6 7; do echo "| $p | done | p$p.md | |"; done
    echo "| 8 | open | | |"
    echo ""
    echo "## Deferred minors"
    echo "- M1: naming nit in parser"
  } > "$dir/00-run.md"
  for p in 0 1 2 3 4 5 6 7; do echo x > "$dir/p$p.md"; done
  echo x > "$dir/03-architecture.md"; echo x > "$dir/03-contracts.md"
  echo "$dir"
}
d=$(mkgate3)
expect 1 "gate 3 fails without 08-integrate.md" "$GATE_CHECK" "$d" 3
printf 'ci-run: 12345\nci-conclusion: failure\n' > "$d/08-integrate.md"
expect 1 "gate 3 fails when CI concluded failure" "$GATE_CHECK" "$d" 3
printf 'ci-run: 12345\nci-conclusion: success\n' > "$d/08-integrate.md"
expect 1 "gate 3 fails when a deferred minor has no triage line" "$GATE_CHECK" "$d" 3
printf 'ci-run: 12345\nci-conclusion: success\ntriage M1: accepted as-is\n' > "$d/08-integrate.md"
expect 0 "gate 3 passes with CI success and every minor triaged" "$GATE_CHECK" "$d" 3

# 11. Usage errors.
expect 1 "missing arguments fails" "$GATE_CHECK"
expect 1 "unknown gate fails" "$GATE_CHECK" "$d" 9

# 12. The skipped branch resolves skill-map.md relative to gate-check's own
# location, and reference/skill-map.md does not exist yet (it arrives in
# Task 7). Copy the skill directory to a temp location with a fixture map so
# this branch is exercised without depending on a file no task has created.
sk="$(mktemp -d)/build-loop"
mkdir -p "$sk/scripts" "$sk/reference"
cp "$GATE_CHECK" "$sk/scripts/gate-check"
chmod +x "$sk/scripts/gate-check"
printf '| 2.4 | risk register | out of scope for v1 |\n' > "$sk/reference/skill-map.md"

d=$(mkrun <<'EOF'
| 0 | done | 00-bootstrap.md | |
| 1 | done | 01-discovery.md | |
| 2 | skipped | | risk register not needed |
EOF
)
echo x > "$d/00-bootstrap.md"; echo x > "$d/01-discovery.md"
expect 0 "skipped phase passes when skill-map marks a stage under it out of scope" "$sk/scripts/gate-check" "$d" 1

# 13. A skipped row with an empty reason fails.
d=$(mkrun <<'EOF'
| 0 | done | 00-bootstrap.md | |
| 1 | done | 01-discovery.md | |
| 2 | skipped | | |
EOF
)
echo x > "$d/00-bootstrap.md"; echo x > "$d/01-discovery.md"
expect 1 "skipped phase with empty reason fails" "$sk/scripts/gate-check" "$d" 1

# 14. A skipped row with a reason fails when the skill map has no
# out-of-scope stage for that phase.
sk2="$(mktemp -d)/build-loop"
mkdir -p "$sk2/scripts" "$sk2/reference"
cp "$GATE_CHECK" "$sk2/scripts/gate-check"
chmod +x "$sk2/scripts/gate-check"
printf '| 1.2 | some other stage | out of scope for v1 |\n' > "$sk2/reference/skill-map.md"

d=$(mkrun <<'EOF'
| 0 | done | 00-bootstrap.md | |
| 1 | done | 01-discovery.md | |
| 2 | skipped | | risk register not needed |
EOF
)
echo x > "$d/00-bootstrap.md"; echo x > "$d/01-discovery.md"
expect 1 "skipped phase fails when skill-map has no out-of-scope stage for that phase" "$sk2/scripts/gate-check" "$d" 1

# 15. An unrecognized status string falls through to the default case.
d=$(mkrun <<'EOF'
| 0 | bogus | | |
EOF
)
expect 1 "unknown status fails" "$GATE_CHECK" "$d" 0

echo ""
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ]
