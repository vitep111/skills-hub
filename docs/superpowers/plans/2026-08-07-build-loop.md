# build-loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `build-loop`, an orchestrator skill that drives a greenfield project idea through WORKFLOW.md's eleven phases to a shipped result, stopping at four human checkpoints.

**Architecture:** A skill folder at `skills/vitep/build-loop/`. `SKILL.md` is the phase machine; six `phases/*.md` files carry inlined instructions for stages with no skill; `reference/skill-map.md` maps every stage to a resolved skill path or an out-of-scope marker; two bash scripts enforce what is mechanically checkable. Everything else delegates to existing hub skills — by reading their `SKILL.md` and following it, never by invoking them.

**Tech Stack:** Markdown (skill documents), Bash (validation scripts, run under Git Bash on Windows), Git.

**Spec:** `docs/superpowers/specs/2026-08-07-build-loop-design.md` (commit `8b6efea`, `main`).

## Global Constraints

- **Greenfield only.** Every document assumes an empty or near-empty target directory. No brownfield paths.
- **Read, do not invoke.** Nine skills carry `disable-model-invocation: true` — `pick-ui-library`, `prototype`, `review-animations`, `grill-me`, `handoff`, `implement`, `to-spec`, `to-tickets`, `wayfinder`. `build-loop` reads `<skill>/SKILL.md` with the Read tool and follows its procedure. Never route these through the Skill tool.
- **Flat install set.** Skills install to `~/.claude/skills/<name>/` with owner directories dropped, because SDD resolves its reviewer via the relative sibling path `../requesting-code-review/code-reviewer.md`.
- **Artifacts move as files, never as pasted text.** Briefs, diffs and reports are file paths.
- **`00-run.md` is authoritative for deferred minors.** SDD's `progress.md` is a transient copy.
- **Gate 3 fires before the merge.** `finishing-a-development-branch` runs in Phase 9, after approval.
- **`build-loop` itself must stay model-invocable.** Its frontmatter carries `name` and `description` only — never `disable-model-invocation`.
- **Scripts are Bash with `#!/usr/bin/env bash`**, matching `skills/obra/subagent-driven-development/scripts/`. No external dependencies beyond coreutils, `awk`, `sed`, `grep`.
- **Commit to `main`.** Per this repo's `CLAUDE.md`, skill work merges to `main` immediately — do not leave it on a feature branch.

## File Structure

| File | Responsibility |
|---|---|
| `skills/vitep/build-loop/SKILL.md` | The phase machine: phase sequence, the four checkpoints, the delegation table, the run-state contract, the executor contract |
| `phases/00-bootstrap.md` | Repo init, install-set check, tracker config, scale assessment, Gate 0 |
| `phases/01-discover.md` | Prior art, success metrics, feasibility spike |
| `phases/03-specify.md` | Architecture + ADRs, API/data contracts, NFRs |
| `phases/08-integrate.md` | Whole-branch review, CI gate — everything before Gate 3 |
| `phases/09-release.md` | Merge, versioning, deploy, migrations, rollback, docs — everything after Gate 3 |
| `phases/10-learn.md` | Retro, metric check, encode learnings back into the hub |
| `reference/skill-map.md` | Every WORKFLOW.md Part B stage → resolved install path, gap file, or out-of-scope marker |
| `scripts/gate-check` | Parses `00-run.md`, asserts a gate may fire |
| `scripts/structure-check` | Asserts `skill-map.md` matches Part B and every stage resolves |
| `tests/test-gate-check.sh` | Fixture-driven tests for `gate-check` |
| `tests/test-structure-check.sh` | Fixture-driven tests for `structure-check` |

Two files carry real logic (`gate-check`, `structure-check`) and are built test-first. The rest are instruction documents, gated by `structure-check` and by the end-to-end dry run.

---

### Task 1: Ledger format and `gate-check`

The only phase-sequencing enforcement in the design. Built first because every later document references the ledger format it parses.

**Files:**
- Create: `skills/vitep/build-loop/scripts/gate-check`
- Create: `skills/vitep/build-loop/tests/test-gate-check.sh`
- Modify: `docs/superpowers/specs/2026-08-07-build-loop-design.md` — the `00-run.md format` section

**Interfaces:**
- Consumes: nothing.
- Produces: the ledger contract every later task writes against —
  - `00-run.md` phase table columns, in order: `phase | status | artifact | reason`
  - `status` ∈ `open` | `done` | `skipped` | `blocked`
  - Deferred minors listed under a `## Deferred minors` heading as `- <id>: <description>`
  - Triage verdicts in `08-integrate.md` as `triage <id>: <verdict>`
  - CI evidence in `08-integrate.md` as `ci-run: <id>` and `ci-conclusion: success`
  - Invocation: `gate-check <run-dir> <gate>` where gate ∈ `0|1|2|3`; exit 0 to proceed, 1 with a reason on stderr
  - Gate → highest required phase: 0→0, 1→2, 2→4, 3→8

- [ ] **Step 1: Fix the ledger example in the spec**

The spec's `00-run.md format` block shows three columns but its `gate-check` section requires a reason for `skipped` rows. Four columns is the reconciliation. Replace the example block in `docs/superpowers/specs/2026-08-07-build-loop-design.md`:

```markdown
# Run: <slug>
idea: <one line>   date: <YYYY-MM-DD>   tier: small|standard|large

## Phases
| phase | status | artifact | reason |
|-------|--------|----------|--------|
| 0 | done | 00-bootstrap.md | |
| 1 | open | | |

## Deferred minors
- <id>: <description>

## Gate log
## Decision log
## Escalations
```

- [ ] **Step 2: Write the failing test**

Create `skills/vitep/build-loop/tests/test-gate-check.sh`:

```bash
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

echo ""
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `bash skills/vitep/build-loop/tests/test-gate-check.sh`
Expected: every case FAILs — `gate-check` does not exist yet.

- [ ] **Step 4: Write `scripts/gate-check`**

```bash
#!/usr/bin/env bash
# Validate a build-loop run ledger before a gate fires. Exits non-zero on the
# first failure with a specific reason, so a gate cannot pass on a skipped
# phase, a missing artifact, or unverified CI.
#
# Usage: gate-check <run-dir> <gate 0|1|2|3>
set -uo pipefail

RUN_DIR="${1:-}"
GATE="${2:-}"

fail() { echo "gate-check FAIL: $*" >&2; exit 1; }

[ -n "$RUN_DIR" ] && [ -n "$GATE" ] || fail "usage: gate-check <run-dir> <gate 0|1|2|3>"
[ -d "$RUN_DIR" ] || fail "run directory not found: $RUN_DIR"

LEDGER="$RUN_DIR/00-run.md"
[ -f "$LEDGER" ] || fail "ledger not found: $LEDGER"

case "$GATE" in
  0) MAX_PHASE=0 ;;
  1) MAX_PHASE=2 ;;
  2) MAX_PHASE=4 ;;
  3) MAX_PHASE=8 ;;
  *) fail "unknown gate: $GATE (expected 0, 1, 2, or 3)" ;;
esac

SKILL_MAP="$(cd "$(dirname "$0")" && pwd)/../reference/skill-map.md"

# Phase table -> "phase|status|artifact|reason" records.
ROWS=$(awk -F'|' '
  /^[[:space:]]*\|[[:space:]]*[0-9]+[[:space:]]*\|/ {
    for (i = 2; i <= 5; i++) gsub(/^[ \t]+|[ \t]+$/, "", $i)
    print $2 "|" $3 "|" $4 "|" $5
  }' "$LEDGER")
[ -n "$ROWS" ] || fail "no phase rows found in $LEDGER"

for phase in $(seq 0 "$MAX_PHASE"); do
  row=$(printf '%s\n' "$ROWS" | awk -F'|' -v p="$phase" '$1 == p { print; exit }')
  [ -n "$row" ] || fail "phase $phase has no row in the ledger"

  status=$(printf '%s' "$row" | cut -d'|' -f2)
  artifact=$(printf '%s' "$row" | cut -d'|' -f3)
  reason=$(printf '%s' "$row" | cut -d'|' -f4)

  case "$status" in
    done)
      [ -n "$artifact" ] || fail "phase $phase is done but names no artifact"
      path="$RUN_DIR/$artifact"
      if [ -d "$path" ]; then
        [ -n "$(ls -A "$path" 2>/dev/null)" ] \
          || fail "phase $phase artifact directory is empty: $artifact"
      elif [ -f "$path" ]; then
        [ -s "$path" ] || fail "phase $phase artifact is empty: $artifact"
      else
        fail "phase $phase artifact does not exist: $artifact"
      fi
      ;;
    skipped)
      [ -n "$reason" ] || fail "phase $phase is skipped with no reason"
      [ -f "$SKILL_MAP" ] || fail "skill-map not found: $SKILL_MAP"
      grep -Eq "^\|[[:space:]]*$phase\.[0-9]+[[:space:]]*\|.*out of scope for v1" "$SKILL_MAP" \
        || fail "phase $phase is skipped but no stage under it is marked out of scope in skill-map.md"
      ;;
    open)
      [ "$phase" -eq "$MAX_PHASE" ] \
        || fail "phase $phase is still open but gate $GATE requires it complete"
      ;;
    blocked)
      fail "phase $phase is blocked: ${reason:-no reason recorded}"
      ;;
    *)
      fail "phase $phase has unknown status: '$status'"
      ;;
  esac
done

case "$GATE" in
  2)
    for f in 03-architecture.md 03-contracts.md; do
      [ -s "$RUN_DIR/$f" ] || fail "gate 2 requires a non-empty $f"
    done
    ;;
  3)
    INT="$RUN_DIR/08-integrate.md"
    [ -s "$INT" ] || fail "gate 3 requires a non-empty 08-integrate.md"
    grep -Eq '^ci-run:[[:space:]]*[A-Za-z0-9_.-]+[[:space:]]*$' "$INT" \
      || fail "gate 3 requires a 'ci-run: <id>' line in 08-integrate.md"
    grep -Eq '^ci-conclusion:[[:space:]]*success[[:space:]]*$' "$INT" \
      || fail "gate 3 requires 'ci-conclusion: success' in 08-integrate.md"
    minors=$(awk '/^##[[:space:]]+Deferred minors/ { f = 1; next }
                  /^##[[:space:]]/ { f = 0 }
                  f && /^-[[:space:]]/ { print }' "$LEDGER")
    while IFS= read -r m; do
      [ -n "$m" ] || continue
      id=$(printf '%s' "$m" | sed 's/^-[[:space:]]*//' | cut -d':' -f1 | sed 's/[[:space:]]*$//')
      [ -n "$id" ] || continue
      grep -Eq "^triage[[:space:]]+$id:" "$INT" \
        || fail "deferred minor '$id' has no triage verdict in 08-integrate.md"
    done <<< "$minors"
    ;;
esac

echo "gate-check OK: gate $GATE"
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `chmod +x skills/vitep/build-loop/scripts/gate-check && bash skills/vitep/build-loop/tests/test-gate-check.sh`
Expected: `passed: 18  failed: 0`, exit 0.

**Runtime note.** Each case calls `mktemp -d` and several subshells. Under Git
Bash on Windows the full suite takes well over a minute; a slow run is not a
hang. If you need to isolate one case, run `gate-check` directly against a
hand-built fixture directory rather than shortening the suite.

- [ ] **Step 6: Commit**

```bash
git add skills/vitep/build-loop/scripts/gate-check \
        skills/vitep/build-loop/tests/test-gate-check.sh \
        docs/superpowers/specs/2026-08-07-build-loop-design.md
git commit -m "feat(build-loop): add gate-check and fix the ledger column count"
```

---

### Task 2: `phases/00-bootstrap.md`

Phase 0 does the work everything downstream assumes: a git repo with a commit, the tracker config the `mattpocock` skills need, and a confirmed scale tier.

**Files:**
- Create: `skills/vitep/build-loop/phases/00-bootstrap.md`

**Interfaces:**
- Consumes: the ledger contract from Task 1.
- Produces: `00-bootstrap.md` in the run directory, containing the `SKILLS_HUB` path that Task 7 (`10-learn.md`) reads, and the confirmed tier that `SKILL.md` branches on.

- [ ] **Step 1: Write the file**

Required sections, in order:

1. **Install-set check.** List all 21 skills from the spec's *Location and install set*. Instruct: verify each exists at `~/.claude/skills/<name>/SKILL.md`. A missing skill is hard stop 1 — report which one and its hub path (`skills/<owner>/<name>/`), do not degrade silently. State the flat-install rationale: SDD resolves its reviewer via `../requesting-code-review/code-reviewer.md`.

2. **Repository bootstrap.** `git init` if absent; write a `.gitignore` appropriate to the stack; make an initial commit so `using-git-worktrees` has something to branch from; create the remote only if the Phase 3 deploy-target ADR or CI will need one — and note that ADR does not exist yet, so defer remote creation to Phase 8 unless the user has already named a host.

3. **Tracker config.** Write `docs/agents/issue-tracker.md` configured for the local-markdown tracker. The `mattpocock` skills (`to-spec`, `to-tickets`, `code-review`, `wayfinder`) expect this file and point users at a `/setup-matt-pocock-skills` command absent from this hub; `wayfinder` names local-markdown as the documented fallback. Include the literal file content to write.

4. **Run directory.** Create `docs/build-loop/<YYYY-MM-DD>-<slug>/`, write `00-run.md` with the phase table from Task 1 (phase 0 row `open`), commit.

5. **Record `SKILLS_HUB`.** Write the hub path into `00-bootstrap.md`, defaulting to `C:\Claude\skills-hub`. Phase 10 reads this.

6. **Scale assessment and Gate 0.** State the three tiers and their triggers verbatim from the spec's scale table. Propose one, present it with what it changes, and get confirmation **before any tier effect takes hold**. Explain why here and not later: the Small tier compresses Phases 1–2, so confirming at Gate 1 would be circular.

7. **Exit.** Set phase 0 to `done` with artifact `00-bootstrap.md`, run `scripts/gate-check <run-dir> 0`, commit.

- [ ] **Step 2: Verify the install list matches the spec**

Run: `grep -c "^  [a-z]" skills/vitep/build-loop/phases/00-bootstrap.md`
Cross-check each name against the spec's install-set block. Every name must appear in exactly one place in both.

- [ ] **Step 3: Commit**

```bash
git add skills/vitep/build-loop/phases/00-bootstrap.md
git commit -m "feat(build-loop): add phase 0 bootstrap instructions"
```

---

### Task 3: `phases/01-discover.md`

**Files:**
- Create: `skills/vitep/build-loop/phases/01-discover.md`

**Interfaces:**
- Consumes: the confirmed tier from Task 2.
- Produces: `01-discovery.md` in the run directory. Its **success metrics** section is read verbatim by Task 7 (`10-learn.md`), which checks the shipped result against it.

- [ ] **Step 1: Write the file**

Required sections:

1. **Prior art.** Search for existing solutions. Record 3–5, each as: name, what it does, one takeaway phrased as *steal this* or *avoid that*. Require a source link per entry. Reject "no prior art exists" without a recorded search.

2. **Success metrics.** 2–4 criteria, each measurable and each checkable without human judgement. Give two worked examples of good versus bad:
   - Bad: "the CLI should be fast" — Good: "converts a 10MB CSV in under 2 seconds on the dev machine"
   - Bad: "good error messages" — Good: "every non-zero exit prints the offending input line number"
   State that Phase 10 checks these, so a metric nobody can evaluate is a metric that will be skipped.

3. **Feasibility spike.** Only when a technical unknown could invalidate the whole approach. Timeboxed, throwaway, and its result recorded in `01-discovery.md` rather than kept as code.

4. **Small-tier compression.** Under the Small tier, prior art shrinks to 1–2 entries and the spike is skipped; success metrics are **never** skipped, since Phase 10 needs them at every tier.

5. **Exit.** Write `01-discovery.md`, set the phase row to `done`, commit.

- [ ] **Step 2: Commit**

```bash
git add skills/vitep/build-loop/phases/01-discover.md
git commit -m "feat(build-loop): add phase 1 discovery instructions"
```

---

### Task 4: `phases/03-specify.md`

The heaviest gap file. Closes the two P0 gaps the whole design exists for.

**Files:**
- Create: `skills/vitep/build-loop/phases/03-specify.md`

**Interfaces:**
- Consumes: `02-design.md` (from `brainstorming`, Phase 2).
- Produces: `03-architecture.md` and `03-contracts.md` — both are Gate 2 prerequisites asserted by `gate-check`. `03-architecture.md` **must** contain a deploy-target ADR; Task 6 (`09-release.md`) executes whatever it names.

- [ ] **Step 1: Write the file**

Required sections:

1. **Architecture.** Components, boundaries, data flow. Require an explicit answer per component to: what does it do, how is it used, what does it depend on. Reject a component whose internals must be read to know what it does.

2. **ADRs.** Each significant decision recorded with this exact template:

```markdown
### ADR-<NN>: <decision in one line>

**Context.** What forces this decision. What is true that makes it necessary.

**Options.** Each considered option, one line each, with its main cost.

**Decision.** The option chosen, stated as a commitment not a preference.

**Consequences.** What this makes easy. What this makes hard. What it forecloses.
```

3. **The deploy-target ADR is mandatory.** State plainly: Phase 9 executes what this ADR names, and deciding at release time is too late. Under the Small tier the answer may be "no external host — ship as a tagged release with generated docs", but that answer is recorded as an ADR, never skipped. Include that as a worked example ADR so the Small path has a template.

4. **API and data contracts.** Schemas, endpoint signatures, error shapes — written before any ticket exists. State the reason: without them, each subagent invents its own contract per-task and they drift. Require every contract to name its consumers.

5. **Non-functional requirements.** A performance budget with numbers, an accessibility bar, and a lightweight security posture: what data is sensitive, what the trust boundary is, what the authentication story is. State that Phase 7 review checks against this section, so a vague NFR is an unenforceable one.

6. **Exit.** Write all three artifacts, set the phase row to `done`, commit.

- [ ] **Step 2: Verify the Gate 2 artifacts are named exactly as `gate-check` expects**

Run: `grep -o '03-architecture\.md\|03-contracts\.md' skills/vitep/build-loop/phases/03-specify.md | sort -u`
Expected: both filenames present, spelled exactly as in `scripts/gate-check`.

- [ ] **Step 3: Commit**

```bash
git add skills/vitep/build-loop/phases/03-specify.md
git commit -m "feat(build-loop): add phase 3 architecture and contract instructions"
```

---

### Task 5: `phases/08-integrate.md` and `phases/09-release.md`

Two files, one task — the only thing that makes them separate files is the gate boundary between them, and a reviewer has to see both to judge that the boundary is drawn correctly.

**Files:**
- Create: `skills/vitep/build-loop/phases/08-integrate.md`
- Create: `skills/vitep/build-loop/phases/09-release.md`

**Interfaces:**
- Consumes: the deploy-target ADR from Task 4; the deferred-minors ledger in `00-run.md`.
- Produces: `08-integrate.md` in the run directory carrying `ci-run: <id>`, `ci-conclusion: success`, and one `triage <id>: <verdict>` line per deferred minor — the exact strings `gate-check` greps for at Gate 3.

- [ ] **Step 1: Write `phases/08-integrate.md`**

Required sections:

1. **Whole-branch review.** Most capable model, reading the full diff plus the deferred-minors ledger from `00-run.md`. It emits one verdict per minor.

2. **Record the triage.** Write into the run directory's `08-integrate.md`, one line per minor, exactly:
   ```
   triage <id>: <verdict>
   ```
   State that `gate-check` greps for `^triage <id>:` per minor and Gate 3 will not fire without one for each.

3. **CI gate.** CI must exist. For greenfield, scaffold the pipeline here so there is something to run — the workflow file itself is part of the deliverable. Record:
   ```
   ci-run: <run id>
   ci-conclusion: success
   ```
   `gate-check` requires the conclusion to be literally `success`. State that these lines are observable proxies chosen deliberately: "CI is green" is not a fact on disk, a recorded run id and conclusion is.

4. **Stop.** Phase 8 ends here. It does **not** merge. Say so explicitly and name the reason: SDD's own terminal node invokes `finishing-a-development-branch`, so without this instruction the merge happens before the human approves it.

5. **Gate 3.** Run `scripts/gate-check <run-dir> 3`, present the branch summary, review verdict, CI conclusion, triaged minors and release plan.

- [ ] **Step 2: Write `phases/09-release.md`**

Open the file with a one-line banner: *everything in this file runs after Gate 3 approval.*

Required sections:

1. **Merge** via `finishing-a-development-branch`.
2. **Versioning and changelog** — semver; changelog generated from `04-tickets/`.
3. **Deploy** — execute the target named in the Phase 3 ADR. If it needs credentials the session lacks, that is hard stop 3: stop and ask, do not improvise a different target.
4. **Migrations** — only when the project has a datastore.
5. **Rollback and flags** — a stated plan always; implementation only where the deploy target supports it.
6. **Documentation** — README, API docs, usage. A new project starts with none.
7. **Small tier** — shipping means a tagged release with generated docs; the deploy step reads the ADR's "no external host" decision and tags instead.

- [ ] **Step 3: Verify the literal strings match `gate-check`**

Run:
```bash
grep -o 'ci-run:\|ci-conclusion: success\|triage <id>:' skills/vitep/build-loop/phases/08-integrate.md | sort -u
grep -o "ci-run\|ci-conclusion\|\^triage" skills/vitep/build-loop/scripts/gate-check | sort -u
```
Expected: the tokens in the instruction file are exactly those the script greps for. A mismatch here means Gate 3 can never pass.

- [ ] **Step 4: Commit**

```bash
git add skills/vitep/build-loop/phases/08-integrate.md skills/vitep/build-loop/phases/09-release.md
git commit -m "feat(build-loop): add phase 8 and 9 instructions, split at gate 3"
```

---

### Task 6: `phases/10-learn.md`

**Files:**
- Create: `skills/vitep/build-loop/phases/10-learn.md`

**Interfaces:**
- Consumes: the success metrics from `01-discovery.md` (Task 3); the `SKILLS_HUB` path from `00-bootstrap.md` (Task 2).
- Produces: `10-retro.md` in the run directory, and possibly a new skill in the hub repository.

- [ ] **Step 1: Write the file**

Required sections:

1. **Metric check.** Read the success metrics from `01-discovery.md` and record a pass/fail plus evidence for each. A metric that cannot be evaluated is itself a retro finding.

2. **Retro.** On **what the loop got wrong**, not what the code got wrong. Prompt for: which phase produced an artifact a later phase had to redo; which gate approved something that later proved wrong; where the loop stopped that it should not have, and where it did not stop that it should have.

3. **Encode learnings.** Procedural learnings become a new hub skill via `writing-skills`. The run executes in the target project and the hub is a separate repository, so: read `SKILLS_HUB` from `00-bootstrap.md`; if the path exists, author the skill there and — per the hub's own `CLAUDE.md` — **merge it to `main` immediately, not on a feature branch**. If the path does not exist, write the learning into `10-retro.md` under a `## For manual transfer` heading and say so in the final report, rather than losing it.

4. **Scope note.** State that this authors *new* skills from run learnings, which is distinct from the out-of-scope item excluding refactoring `build-loop`'s own gap files into skills.

- [ ] **Step 2: Commit**

```bash
git add skills/vitep/build-loop/phases/10-learn.md
git commit -m "feat(build-loop): add phase 10 retro and learning-capture instructions"
```

---

### Task 7: `reference/skill-map.md` and `scripts/structure-check`

Built after the gap files so the check can pass against real paths.

**Files:**
- Create: `skills/vitep/build-loop/reference/skill-map.md`
- Create: `skills/vitep/build-loop/scripts/structure-check`
- Create: `skills/vitep/build-loop/tests/test-structure-check.sh`

**Interfaces:**
- Consumes: every `phases/*.md` from Tasks 2–6; `WORKFLOW.md` Part B.
- Produces: the stage table `gate-check` greps for out-of-scope markers, in the format `| <phase>.<n> | <stage> | <resolution> |` where resolution is a skill name, a `phases/` filename, or the literal `out of scope for v1`.

- [ ] **Step 1: Write `reference/skill-map.md`**

One row per WORKFLOW.md Part B stage, numbered `<phase>.<n>` matching Part B's ordering within each phase section. Columns: stage id, stage name, resolution.

Resolutions are exactly one of:
- a skill name resolving to `~/.claude/skills/<name>/` — note in a header line that these are **read, not invoked**, for the nine `disable-model-invocation` skills, and list which nine
- a `phases/<file>.md` gap file
- the literal string `out of scope for v1`

The out-of-scope stages, from the spec: `2.4` risk register, `4.4` estimation and critical path, `7.3` performance and accessibility review, `8.3` merge-conflict resolution, `10.1` observability, `10.2` incident response, `10.3` analytics, `10.4` tech-debt backlog.

Header line: *derived from `WORKFLOW.md` Part B, which is the authority. Do not edit this file without editing Part B.*

- [ ] **Step 2: Write the failing test**

Create `skills/vitep/build-loop/tests/test-structure-check.sh`:

```bash
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
```

- [ ] **Step 3: Run it to verify it fails**

Run: `bash skills/vitep/build-loop/tests/test-structure-check.sh`
Expected: FAIL — `structure-check` does not exist.

- [ ] **Step 4: Write `scripts/structure-check`**

```bash
#!/usr/bin/env bash
# Assert every stage in reference/skill-map.md resolves to exactly one of:
# a gap file that exists, a skill name, or the out-of-scope marker; and that
# the stage list still matches WORKFLOW.md Part B, its authority.
set -uo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MAP="$SKILL_DIR/reference/skill-map.md"
ERRORS=0

err() { echo "structure-check FAIL: $*" >&2; ERRORS=$((ERRORS+1)); }

[ -f "$MAP" ] || { echo "structure-check FAIL: no skill-map at $MAP" >&2; exit 1; }

while IFS='|' read -r _ id stage resolution _; do
  id=$(echo "$id" | tr -d '[:space:]')
  resolution=$(echo "$resolution" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
  case "$id" in ''|*[!0-9.]*) continue ;; esac
  [ -n "$resolution" ] || { err "stage $id has no resolution"; continue; }

  case "$resolution" in
    "out of scope for v1") ;;
    phases/*)
      [ -f "$SKILL_DIR/$resolution" ] \
        || err "stage $id names a gap file that does not exist: $resolution" ;;
    *)
      # A skill name. Verified against the install set at Phase 0, not here —
      # the hub checkout has no ~/.claude/skills. Assert it is a bare name.
      case "$resolution" in
        */*) err "stage $id resolution '$resolution' is neither a phases/ file nor a bare skill name" ;;
      esac ;;
  esac
done < "$MAP"

# The map is derived from Part B; every phase Part B defines must appear.
for phase in 0 1 2 3 4 5 6 7 8 9 10; do
  grep -Eq "^\|[[:space:]]*$phase\.[0-9]+" "$MAP" \
    || err "no stages recorded for phase $phase (WORKFLOW.md Part B defines it)"
done

[ "$ERRORS" -eq 0 ] || exit 1
echo "structure-check OK"
```

- [ ] **Step 5: Run both test suites**

Run:
```bash
chmod +x skills/vitep/build-loop/scripts/structure-check
bash skills/vitep/build-loop/tests/test-structure-check.sh
bash skills/vitep/build-loop/tests/test-gate-check.sh
```
Expected: both report `failed: 0`.

- [ ] **Step 6: Commit**

```bash
git add skills/vitep/build-loop/reference/skill-map.md \
        skills/vitep/build-loop/scripts/structure-check \
        skills/vitep/build-loop/tests/test-structure-check.sh
git commit -m "feat(build-loop): add skill-map and structure-check"
```

---

### Task 8: `SKILL.md` and the WORKFLOW.md pointer

The spine. Written last so every cross-reference points at a file that exists.

**Files:**
- Create: `skills/vitep/build-loop/SKILL.md`
- Modify: `WORKFLOW.md` — add a pointer near the top
- Modify: `INSTALLED.md` — add the catalog entry

**Interfaces:**
- Consumes: every file from Tasks 1–7.
- Produces: the entry point. Nothing depends on it.

- [ ] **Step 1: Write the frontmatter and opening**

```markdown
---
name: build-loop
description: Use when starting a new project from scratch — drives a greenfield idea through the full eleven-phase development loop to a shipped result, invoking the hub's skills at each stage, spawning agents for the build, and stopping at four human checkpoints.
---

# Build Loop

Take a greenfield project idea from nothing to shipped, following
`WORKFLOW.md`'s eleven phases. Existing skills drive the stages that have
them; `phases/*.md` carries the stages that do not.

**Greenfield only.** For a feature inside an existing codebase, use the
individual skills directly.
```

No `disable-model-invocation` — `build-loop` must remain model-invocable.

- [ ] **Step 2: Write the required sections**

1. **The checkpoints** — the four-row table from the spec (Gate 0 Scale, 1 Design, 2 Buildable package, 3 Ready to ship), with what is shown and what approval means. State that Gate 3 fires before the merge.

2. **Reading skills, not invoking them.** List the nine `disable-model-invocation` skills. Instruct: Read `~/.claude/skills/<name>/SKILL.md` and follow it; resolve its supporting files relative to that directory; never route it through the Skill tool.

3. **The delegation table** — one row per phase: phase, what drives it (skill name or `phases/` file), and the run-directory artifact it produces. Mark Phase 6 as the only phase fully covered by existing skills.

4. **Human stops inside delegated skills** — the six-row table from the spec, naming for each which gate absorbs it. Include the `brainstorming` handoff: the tagged `<HARD-GATE>` is satisfied by Gate 1; the separate **untagged** terminal-state rule is the one to override, because it would otherwise carry the run from design straight to `writing-plans`, past Phase 3.

5. **Run state** — the run directory layout, the ledger format from Task 1, the ledger-as-precondition rule (row written on entry with `status: open`; artifact and `done` on exit), and the reconciliation table for where each delegated skill actually writes.

6. **The SDD bridge** — copy SDD's git-ignored workspace into `06-tasks/` and `07-reviews/` and commit it *before* SDD's Finish step `rm -rf`s it; merge its `progress.md` minors into `00-run.md`, which is authoritative.

7. **The executor contract** — Phases 5–7, with In / Out / Guarantee / Explicitly excluded (the merge) copied from the spec.

8. **Hard stops** — the four from the spec.

9. **Resume** — on invocation, if the target directory has a `docs/build-loop/*/00-run.md` with any phase not `done`, resume from the first such phase instead of starting fresh.

10. **Scale tiers** — the three-row table, with tier confirmed at Gate 0.

- [ ] **Step 3: Add the WORKFLOW.md pointer**

Insert after line 13 (the "Read this in three parts" list) in `WORKFLOW.md`:

```markdown
> **Executable form:** `skills/vitep/build-loop/` drives this loop end to end
> for greenfield projects. This document is its reference — Part B is the
> authority for the stage → skill mapping, and `build-loop`'s
> `reference/skill-map.md` is derived from it.
```

- [ ] **Step 4: Add the INSTALLED.md entry**

Follow the existing catalog format, under a new `vitep` source section.

- [ ] **Step 5: Verify every referenced file exists**

Run:
```bash
cd skills/vitep/build-loop
grep -oE '(phases|reference|scripts)/[a-z0-9-]+\.?[a-z]*' SKILL.md | sort -u | while read -r f; do
  [ -e "$f" ] || echo "DANGLING: $f"
done
bash tests/test-gate-check.sh && bash tests/test-structure-check.sh
```
Expected: no `DANGLING` lines; both suites report `failed: 0`.

- [ ] **Step 6: Commit**

```bash
git add skills/vitep/build-loop/SKILL.md WORKFLOW.md INSTALLED.md
git commit -m "feat(build-loop): add SKILL.md phase machine and hub pointers"
```

---

### Task 9: End-to-end dry run

The spec's *Real check*. Not a unit test — the acceptance test for the whole skill.

**Files:**
- Create: `C:\Claude\_dryrun-csv2json\` (throwaway target project, outside the hub)
- Modify: `skills/vitep/build-loop/**` — whatever the run proves wrong

**Interfaces:**
- Consumes: the complete skill from Tasks 1–8.
- Produces: a verdict on the v1.1 trigger.

- [ ] **Step 1: Install the skill set**

Copy `build-loop` and the 20 delegated skills into `~/.claude/skills/`, **flattened** — owner directories dropped, so `requesting-code-review` is a sibling of `subagent-driven-development`.

Run: `ls ~/.claude/skills/ | wc -l` — expect at least 21.

- [ ] **Step 2: Run the loop on a Small-tier project**

Target: a CLI that converts a CSV file to JSON. One component, no persistence, no external host — Small tier by the spec's trigger.

From an empty `C:\Claude\_dryrun-csv2json\`, invoke `build-loop` with that idea. Drive it to a shipped result. Record at each checkpoint: which gate fired, whether `gate-check` passed, and whether any human stop occurred that the spec did not predict.

- [ ] **Step 3: Assert the run's evidence**

```bash
RUN=$(ls -d C:/Claude/_dryrun-csv2json/docs/build-loop/*/ | head -1)
bash ~/.claude/skills/build-loop/scripts/gate-check "$RUN" 3
test -s "$RUN/00-run.md" && test -s "$RUN/03-architecture.md" && test -s "$RUN/10-retro.md"
grep -c '^| [0-9]' "$RUN/00-run.md"
```
Expected: `gate-check OK: gate 3`; all three files non-empty; 11 phase rows.

- [ ] **Step 4: Record the v1.1 verdict**

Write findings into `docs/superpowers/specs/2026-08-07-build-loop-design.md` under a new `## Dry run result` section. Per the spec's stated trigger, drift in the Gate 2 → Gate 3 span — a skipped review, a ticket accepted without one, a fix loop past round 5, or a `gate-check` failure at Gate 3 — means the `Workflow` executor is the next work. No drift means v1's executor stays. Record which, with the evidence.

- [ ] **Step 5: Fix what the run proved wrong, then delete the target**

Apply fixes to the skill files. Re-run both test suites. Then `rm -rf C:/Claude/_dryrun-csv2json`.

- [ ] **Step 6: Commit**

```bash
git add skills/vitep/build-loop docs/superpowers/specs/2026-08-07-build-loop-design.md
git commit -m "fix(build-loop): apply dry-run findings and record the v1.1 verdict"
```

---

## Self-Review

**Spec coverage.** Every spec section maps to a task: *Location and install set* → Tasks 2 and 9; *Files* → Tasks 2–8; *Phase 0 bootstrap* → Task 2; *Run state*, *ledger format*, *ledger-as-precondition*, *SDD bridge*, *which working tree* → Tasks 1 and 8; *The gates*, *Gate 3 before merge*, *human stops*, *brainstorming handoff* → Tasks 5 and 8; *Hard stops* → Task 8; *Enforcement* → Tasks 1 and 7; *Inlined gap content* → Tasks 3–6; *Scale adaptation* → Tasks 2, 3, 5; *Execution modes and executor contract* → Task 8; *Verification* → Tasks 7 and 9.

Two spec items are deliberately not their own task: *Relationship to WORKFLOW.md* is folded into Task 8's pointer step, and *Open risks* is prose requiring no implementation.

**Type consistency.** The literal strings crossing task boundaries are `ci-run:`, `ci-conclusion: success`, `triage <id>:`, `## Deferred minors`, the four ledger statuses (`open`/`done`/`skipped`/`blocked`), and `out of scope for v1`. Each is defined in Task 1 or 7 and grepped for in Task 5's and Task 7's verification steps precisely because a mismatch would make a gate unpassable. Artifact filenames (`03-architecture.md`, `03-contracts.md`, `08-integrate.md`) are identical in `gate-check`, the spec, and Tasks 4–5.

**Gap found and closed during review.** `structure-check` cannot verify skill names against `~/.claude/skills/` — the hub checkout has no install directory. Task 7 now asserts only that a resolution is a bare name, and the real install-set verification lives in Phase 0 (Task 2), where it belongs and where a missing skill is a hard stop.
