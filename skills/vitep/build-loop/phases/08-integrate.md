# Phase 8 — Integrate

Run this once Phases 5–7 (the build) are complete — every ticket in
`04-tickets/` implemented and reviewed clean, with `06-tasks/` and
`07-reviews/` bridged into the run directory. This phase closes the branch
out for shipping: a whole-branch review, real CI evidence, and a triage
verdict on every deferred minor. It does **not** merge — that is Phase 9's
first act, after Gate 3.

**Naming collision, read this once:** *this file* is
`phases/08-integrate.md`, the instructions you are reading. The artifact it
writes is *also* named `08-integrate.md`, but it lives in the run directory
(`docs/build-loop/<date>-<slug>/08-integrate.md`) and is a different file.
Below, "this file" means the instructions; "the artifact" means the thing
you write.

All work here happens **inside the worktree branch** Phase 5 created, not
the default branch — confirm with `git branch --show-current`. `gate-check`
for Gate 3 also runs from the worktree.

---

## 1. Enter phase

First action, before any review or CI work starts. Phase 8 owns opening its
own ledger row, and this file can be re-entered after a crash or a context
compaction — both expected, not exceptional — so the open must be
idempotent. Never append blindly.

1. **Check for an existing phase 8 row:**

   ```bash
   grep -Eq '^\|[[:space:]]*8[[:space:]]*\|' "docs/build-loop/<date>-<slug>/00-run.md"
   ```

2. **No row found.** First pass. Append `| 8 | open | | |`.
3. **Row found, status `open`.** Resumed pass — Exit (Section 5) never ran.
   Re-do Sections 2–4 from scratch. The artifact is rewritten whole at Exit,
   not appended to, so a resumed pass can't leave duplicate `ci-run:` or
   `triage` lines behind.
4. **Row found, status `done`.** Already complete, Gate 3 already fired.
   Stop, proceed to Phase 9.

Before starting, read `00-run.md`'s `## Deferred minors` (every entry needs
a triage line, Section 3) and `03-architecture.md`'s deploy-target ADR (the
Gate 3 release-plan preview, Section 6, summarizes it).

---

## 2. Whole-branch review

Most capable model available, reading the **full branch diff** — default
branch's merge-base to the worktree tip — and `00-run.md`'s `## Deferred
minors`. It emits one verdict per minor: fix now, accept as-is, or
won't-fix with a reason.

If Phases 5–7 ran under `subagent-driven-development`, its own Final Review
already did this — most capable model, `requesting-code-review`'s
`code-reviewer.md`, pointed at the same deferred-minor lines — and the
report is bridged into `07-reviews/`. Check there first:

```bash
ls "docs/build-loop/<date>-<slug>/07-reviews/" | grep -i final
```

Found → use its verdicts for Section 3, don't re-run the review. Not found
(a different execution mode ran Phases 5–7, or the bridge was skipped) →
run it now the same way: `git merge-base <default-branch> HEAD` for the
range, dispatch the review, save output to `07-reviews/08-final-review.md`.

Either way, Section 3's verdicts come from this review — never invented.

---

## 3. Record the triage

For **every** entry under `00-run.md`'s `## Deferred minors` (each shaped
`- <id>: <description>`), the artifact needs one line, at the start of a
line:

```
triage <id>: <verdict>
```

**Reproduce the id verbatim.** `gate-check` takes each ledger line's text
before its first colon as the id (`- M1: naming nit` → `M1`) and greps for
`^triage[[:space:]]+<id>:` — one-or-more spaces after `triage`, the id
exactly as in the ledger, colon immediately after with no space before it.
A paraphrased id does not match:

```
triage M1: accepted as-is — cosmetic, not worth a fix-round detour
triage M2: fixed in commit a1b2c3d
```

"Accepted as-is" is a valid verdict; a missing line is not — Gate 3 will
not fire without one per minor, however trivial.

---

## 4. CI gate

CI must exist before Gate 3 can point at a real run. Greenfield starts with
none, so this phase scaffolds it.

1. **Remote.** Phase 0 deferred remote creation to here
   (`00-bootstrap.md`'s `Remote:` line records whether one exists). If
   none, create one — hosted CI needs somewhere to run:

   ```bash
   gh repo create <name> --private --source=. --remote=origin
   git push -u origin <worktree-branch>
   ```

   Genuinely local-only project (no forge account, none named by the user)
   → skip to the local-only fallback below.

2. **Scaffold the pipeline** — part of the deliverable, not a throwaway.
   For GitHub, `.github/workflows/ci.yml` running install + test on push,
   using the command `00-bootstrap.md`/`03-architecture.md` established for
   the stack:

   ```yaml
   name: CI
   on: [push, pull_request]
   jobs:
     test:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - run: <install command>
         - run: <test command>
   ```

   Commit it — the push is what triggers the first real run.

3. **Observe the run to completion:**

   ```bash
   gh run list --branch <worktree-branch> --limit 1
   gh run watch <run-id>
   gh run view <run-id> --json databaseId,conclusion
   ```

4. **If it fails,** diagnose and fix (`systematic-debugging`), push, watch
   the new run. Never record a non-`success` conclusion and proceed —
   `gate-check` requires the literal word `success`.

5. **Record**, at the start of a line:

   ```
   ci-run: <run id>
   ci-conclusion: success
   ```

   Id charset: letters, digits, `.`, `_`, `-` only — no slashes, no spaces.

**Local-only fallback.** Run the test suite in the worktree directly; if
green, record a locally-derived id, e.g. `ci-run: local-$(date +%s)`, and
`ci-conclusion: success`. These lines are **observable proxies chosen
deliberately** — "CI is green" is not a fact on disk, a recorded run id and
conclusion is, whether hosted or local.

---

## 5. Stop — do not merge

Phase 8 ends here. **It does not merge, and this is deliberate.**
`obra/subagent-driven-development`'s own terminal step, once its Final
Review is clean, invokes `finishing-a-development-branch` — normal, correct
behavior for SDD running alone. Inside `build-loop`, whatever ran Phases
5–7 must have been told to stop at "Final Review clean" instead of
continuing to that call, precisely so this phase and Gate 3 sit between a
clean branch and the merge that ships it. If a merge already happened
before this phase started, stop and flag it — Gate 3 would otherwise be
approving something already done, not authorizing it.

The merge is Phase 9's Section 2, and Phase 9 does not start until Gate 3
approves.

---

## 6. Exit

1. Write `docs/build-loop/<date>-<slug>/08-integrate.md` — the full file in
   one write, never an accumulation of appends across a resumed pass:

   ```markdown
   # Phase 8 — Integrate

   ## Whole-branch review
   <verdict summary and the path to the full report>

   ## Deferred minors triage
   triage <id>: <verdict>
   <one line per 00-run.md ## Deferred minors entry, or "None deferred
   this run." if that section is genuinely empty>

   ## CI
   ci-run: <run id>
   ci-conclusion: success

   ## Release plan preview
   <one paragraph: the deploy-target ADR's Decision, and what Phase 9 will
   do — deploy to <target>, or "no external host — tag and generate docs"
   for Small tier>
   ```

2. In `00-run.md`, flip phase 8's row: `| 8 | done | 08-integrate.md | |`.

3. Commit. Stage the CI workflow file only if Section 4 actually created
   one — the local-only fallback never does, since there's no hosted
   pipeline to scaffold, and staging a path that doesn't exist fails the
   commit outright:

   ```bash
   git add "docs/build-loop/<date>-<slug>/00-run.md" \
           "docs/build-loop/<date>-<slug>/08-integrate.md"
   [ -f ".github/workflows/ci.yml" ] && git add ".github/workflows/ci.yml"
   git commit -m "chore(build-loop): phase 8 complete, branch ready to ship"
   ```

---

## 7. Gate 3

```bash
~/.claude/skills/build-loop/scripts/gate-check "docs/build-loop/<date>-<slug>" 3
```

- **Exit 1:** reason on stderr — a missing `ci-run:`/`ci-conclusion:
  success` line, or an untriaged minor. Fix (Sections 3–4), rewrite the
  artifact, re-run. Don't present Gate 3 until this exits 0.
- **Exit 0:** present the package and wait for explicit approval — the
  script passing is the mechanical check, not the human one:

  1. **Branch summary** — the ticket list from `04-tickets/`, one line each.
  2. **Review verdict** — Section 2's outcome.
  3. **CI conclusion** — the recorded `ci-run:`/`ci-conclusion:` lines.
  4. **Triaged minors** — every `triage <id>: <verdict>` line.
  5. **Release plan** — the artifact's Release plan preview.

Approval means what the gate table says: **merge, deploy, docs, retro** —
it authorizes all of Phase 9, not just the merge. Phase 9 does not stop
again to re-ask before deploying or documenting. Proceed to
`09-release.md` only after this approval is given.
