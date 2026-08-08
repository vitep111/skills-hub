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

## Files in this skill

```
phases/00-bootstrap.md   phases/01-discover.md   phases/03-specify.md
phases/08-integrate.md   phases/09-release.md    phases/10-learn.md
reference/skill-map.md
scripts/gate-check       scripts/structure-check
```

Phases 2, 4, 5, 6, 7 have no `phases/` file — they are driven by existing
skills directly, per the delegation table in Section 3.

---

## 1. Checkpoints

Four human stops, exactly. Between them the loop runs unattended and spawns
agents freely.

| Gate | Fires after | User is shown | Approval means |
|---|---|---|---|
| **0 · Scale** | Phase 0 | proposed tier and what it changes | run at this tier |
| **1 · Design** | Phase 2 (Shape) | discovery, chosen approach, scope cut | proceed to spec and architecture |
| **2 · Buildable package** | Phase 4 (Plan) | spec, ADRs incl. deploy target, contracts, plan, tickets | authorize the entire unattended build |
| **3 · Ready to ship** | Phase 8, **before the merge** | branch summary, whole-branch review verdict, CI conclusion, deferred-minors ledger, release plan | merge, deploy, docs, retro |

Gate 0 is a confirmation, not a review — it is still a real human stop, named
explicitly rather than pretending the loop has exactly three.

**Gate 3 fires before the merge, not after.** `subagent-driven-development`'s
own terminal step, once its Final Review is clean, invokes
`finishing-a-development-branch` — which merges. Left alone, Gate 3 would ask
the user to approve a merge that had already happened. Gate 3 therefore fires
after the whole-branch review and CI (Phase 8, `phases/08-integrate.md`) and
**before** `finishing-a-development-branch` runs. `phases/08-integrate.md`
stops short of that call deliberately; Section 7 below (the executor
contract) is what makes that stop enforceable rather than a hope.

Each gate runs `scripts/gate-check <run-dir> <gate-number>` first. Non-zero
exit blocks the gate — fix what it names, re-run, and only then present the
package above. The check verifies artifacts exist; it cannot verify they are
any good. That is what the human half of the gate is for.

---

## 2. Reading skills, not invoking them

Nine skills in the install set carry `disable-model-invocation: true`:

```
pick-ui-library   prototype   review-animations   grill-me   handoff
implement   to-spec   to-tickets   wayfinder
```

No skill, including `build-loop`, may invoke any of these nine through the
Skill tool — that flag means only a human typing the name can. Wherever a
phase below calls for one of them: **read `~/.claude/skills/<name>/SKILL.md`
with the Read tool, follow its procedure directly, and resolve its
supporting files and scripts relative to that skill's own directory.** Never
route it through the Skill tool, and never substitute a summary of the skill
for actually reading it — a skill that changes upstream changes this
behaviour with no other signal.

Every other skill named anywhere in this file — `brainstorming`,
`writing-plans`, `to-tickets`'s siblings that aren't on the list above,
`subagent-driven-development`, `finishing-a-development-branch`,
`writing-skills`, and the rest — is invoked normally, with the Skill tool.

`reference/skill-map.md` records, for every stage in `WORKFLOW.md` Part B,
which of these two paths applies and the resolved path to use.
`scripts/structure-check` verifies that map stays consistent with Part B and
that every gap file it names actually exists on disk — run it after editing
either.

---

## 3. Delegation table

One row per phase: what drives it, and the artifact it leaves in the run
directory (`docs/build-loop/<date>-<slug>/`).

| Phase | Drives it | Run-directory artifact |
|---|---|---|
| 0 · Bootstrap | `phases/00-bootstrap.md` | `00-bootstrap.md` |
| 1 · Discover | `phases/01-discover.md` | `01-discovery.md` |
| 2 · Shape | `brainstorming`, `grill-me`, `to-spec` (scope-cut section only) | `02-design.md` |
| 3 · Specify | `to-spec` (functional spec) + `phases/03-specify.md` (architecture, ADRs, contracts, NFRs) + `emil-design-eng` / `apple-design` / `ui-ux-pro-max` (UX/UI/motion) + `pick-ui-library` (dependency selection) | `03-spec.md`, `03-architecture.md`, `03-contracts.md` |
| 4 · Plan | `wayfinder` (Large tier only) + `writing-plans` + `to-tickets` | `04-plan.md`, `04-tickets/` |
| 5 · Orchestrate | `using-git-worktrees` + `subagent-driven-development` (workspace setup, model tiering) — see the executor contract, Section 7 | `05-orchestrate.md` |
| 6 · Build | `subagent-driven-development`, `test-driven-development`, `verification-before-completion`, `systematic-debugging`, `implement` — **the only phase fully covered by existing skills; `WORKFLOW.md` says so of no other phase** | `06-tasks/` (bridged from SDD's workspace, Section 6) |
| 7 · Review & Fix | `requesting-code-review`, `code-review`, `review-animations`, `security-review`, `receiving-code-review`, `subagent-driven-development` (fix loop) | `07-reviews/` (bridged from SDD's workspace, Section 6) |
| 8 · Integrate | `phases/08-integrate.md` | `08-integrate.md` |
| 9 · Release | `phases/09-release.md` (invokes `finishing-a-development-branch` for the merge, first action after Gate 3) | `09-release.md` |
| 10 · Learn | `phases/10-learn.md` + `writing-skills` (for procedural findings) | `10-retro.md` |

Phase 5 has no `phases/` file. `SKILL.md` opens its ledger row directly,
records the chosen execution mode, model tiers, and worktree path in
`05-orchestrate.md`, then hands the span to the named executor described in
Section 7. Phases 2, 4, 6, 7 are covered only for the stages this hub's
skills actually reach — their remaining ❌ stages (risk register, estimation,
domain review beyond UI/security) are dropped per the design's Scope
section, not silently absorbed.

---

## 4. Human stops inside delegated skills

The claim that the loop runs unattended between gates is false unless each
delegated skill's own checkpoints are handled. There are six, and they fold
into the four gates above rather than firing on their own:

| Skill | Its checkpoint | `build-loop` does |
|---|---|---|
| `brainstorming` | approval after each design section | folds into Gate 1 — sections are presented as one package |
| `brainstorming` | User Review Gate on the written spec | folds into Gate 1 |
| `to-spec` | "check with the user that these seams match" | folds into Gate 2 |
| `to-tickets` | "iterate until the user approves the breakdown" | folds into Gate 2 |
| SDD (`subagent-driven-development`) | consent required before implementing on `main` | pre-satisfied: Phase 5 creates a worktree branch, so implementation never runs on `main` |
| `wayfinder` (Large tier only) | scope confirmation | folds into Gate 1 |

Folding means the skill is told, at the point it would otherwise stop, that
approval is deferred to the named gate, and its material is carried there
instead of asked for on the spot. Where read-not-invoke applies (Section 2),
this is an instruction inside a file being followed, not a mechanism being
disabled.

**The `brainstorming` handoff needs one explicit override.** Two distinct
rules live inside `brainstorming`, and only one of them is a problem:

- The tagged `<HARD-GATE>` forbids implementation before design approval.
  `build-loop` already satisfies this — Gate 1 *is* that approval. Nothing
  to override.
- A separate, **untagged** rule states that the only skill invoked after
  `brainstorming` is `writing-plans`. Followed literally, this carries a run
  straight from design to planning, past Phase 3 (architecture, ADRs,
  contracts) — exactly the P0 gap this whole skill exists to close.

State the override explicitly wherever `brainstorming` is followed for
Phase 2: `build-loop` takes control at Gate 1, runs Phase 3
(`phases/03-specify.md`) next, and reaches `writing-plans` at Phase 4 — the
same destination `brainstorming` intended, with Specify inserted ahead of it.

---

## 5. Run state

Every run creates one directory in the target project, on the default
branch, committed in full — ADRs and the spec are real documentation for a
new repo; briefs and review reports make the run auditable.

```
docs/build-loop/<YYYY-MM-DD>-<slug>/
  00-run.md            the ledger - the resume anchor
  00-bootstrap.md      install-set + repo + tracker state, scale tier
  01-discovery.md      prior art, success metrics
  02-design.md         chosen approach, rejected options, scope cut
  03-spec.md
  03-architecture.md   ADRs, including the deploy-target decision
  03-contracts.md      data model and API contracts
  04-plan.md
  04-tickets/          one file per ticket - to-tickets forbids a
                       combined file
  05-orchestrate.md    execution mode, model tiers, worktree path
  06-tasks/            per-task briefs and reports (bridged)
  07-reviews/          per-task review reports (bridged)
  08-integrate.md      whole-branch review verdict, CI run id + conclusion
  09-release.md        version, changelog, migrations, rollback
  10-retro.md
```

### `00-run.md` — the ledger `gate-check` parses

Fixed format, not prose — four columns, this order:

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

`status` is one of `open`, `done`, `skipped`, `blocked`. `scripts/gate-check`
treats only `done` as complete and requires a named, non-empty artifact for
it; `skipped` requires a reason and must correspond to a stage marked "out of
scope for v1" in `reference/skill-map.md`; the currently open phase is exempt
from the artifact requirement. Beyond the phase table, the ledger carries a
gate log, a decision log (including the deploy target), the deferred-minors
list, and any escalations — every phase file appends to these in the same
one-line-per-entry format so the ledger stays scannable after a compaction.

### The ledger is a precondition, not a record

The phase row is written **on entering** a phase, with `status: open`,
before any of that phase's work starts. The artifact path and `status: done`
are written only on exit. This inversion is what gives `scripts/gate-check`
something to verify: a skipped phase leaves a row with no artifact, or no row
at all where the next phase has one. Written the other way round — appended
afterward as a summary — a skipped phase would leave no trace, and the
ledger would degrade into a narration of whatever happened to run rather
than a check on it.

### Phase idempotency — both variants

Every phase file opens its own ledger row before doing any work, guarding
against a crash or context compaction mid-phase (both expected, not
exceptional). The guard is a grep against the exact phase number:

```bash
grep -Eq '^\|[[:space:]]*N[[:space:]]*\|' "docs/build-loop/<date>-<slug>/00-run.md"
```

The bracketed whitespace on both sides of `N` is what correctly distinguishes
phase `1` from phase `10` — a naive substring match would treat `1` as a
prefix of `10` and misfire.

Three outcomes:

- **No row for phase N.** First pass. Append `| N | open | | |`.
- **Row exists, status `open`.** A resumed pass — the prior attempt opened
  the row but never reached Exit. Do not append a second row.
- **Row exists, status `done`.** Phase already complete in a prior pass. Skip
  forward to the next phase; do not redo it.

What "resumed pass" means for the middle case splits in two, and getting
this wrong is the difference between a safe retry and a duplicate deploy:

- **Phases that only write local documents** — 0, 1, 2, 3, 4, 8, and 10 —
  redo the section's work from scratch on a resumed `open` row. A document
  write is a no-op past the first correct pass, so blind redo is safe and is
  what `phases/00-bootstrap.md`, `phases/01-discover.md`,
  `phases/03-specify.md`, `phases/08-integrate.md`, and `phases/10-learn.md`
  all do.
- **Phase 9 has irreversible external effects** — merge, tag, deploy — and
  is the one exception. The row guard above is unchanged, but blind redo is
  replaced with a **per-step idempotency check** inside each side-effecting
  section (has this already been merged / already been tagged / already been
  deployed?), and where a step's prior state can't be determined from the
  environment, that step is a **hard stop**: report what's unknown and ask,
  rather than guess. A wrong guess here is a duplicate tag or a second
  deploy, not a rewritten paragraph. `phases/09-release.md` implements this
  exact split.
- **Phases 5–7 have no `phases/` file at all**, so neither variant applies to
  them directly — their idempotency is the named executor's own guarantee
  (Section 7): no ticket is accepted twice, and the fix loop's round-tracking
  is internal to the executor, not a ledger-row redo.

### Where delegated skills actually write, and how it is reconciled

None of the delegated skills default to the run directory. Each row below is
a required reconciliation step, not an assumption:

| Run-state artifact | Skill's own default | Reconciliation |
|---|---|---|
| `02-design.md` | `brainstorming` → `docs/superpowers/specs/…-design.md` | override — the skill states user preferences for spec location take precedence |
| `03-spec.md` | `to-spec` → the issue tracker | tracker is local-markdown per Phase 0, so redirect its output path |
| `04-plan.md` | `writing-plans` → `docs/superpowers/plans/…md` | override — same precedence clause |
| `04-tickets/` | `to-tickets` → `.scratch/<slug>/issues/<NN>-<slug>.md` | redirect the issue directory into the run directory |
| `06-tasks/`, `07-reviews/` | SDD → `.superpowers/sdd/<plan>/`, **git-ignored** | bridge — Section 6 |

---

## 6. The SDD bridge

`subagent-driven-development` keeps briefs, reports, and review packages in
a **git-ignored** workspace, runs its own ledger at
`<workspace>/progress.md`, and **`rm -rf`s that workspace** once its final
review is clean. Left alone, this erases the exact audit trail Section 5
promises — written somewhere that is never committed, then deleted before
Gate 3 can show any of it.

`build-loop` closes this gap by copying the SDD workspace into `06-tasks/`
and `07-reviews/` in the run directory, and **committing that copy before
SDD's Finish step runs** — i.e., before the point where SDD would delete its
own workspace. The copy has to land and be committed strictly earlier than
that deletion, not merely before Gate 3; SDD's Finish step is internal to
Phases 5–7, upstream of Phase 8 and Gate 3 both.

**`00-run.md` is authoritative for deferred minors, not SDD's `progress.md`.**
`progress.md` holds them while the build is in flight; the bridge copies
each entry into `00-run.md`'s `## Deferred minors` list, which is what
`phases/08-integrate.md`'s whole-branch review actually reads. Two ledgers
exist side by side during Phases 5–7 — this is what states which one wins
when they'd otherwise disagree.

---

## 7. The executor contract — Phases 5–7

The span from Gate 2 to Gate 3 is the longest unattended stretch in the loop
and covers the entire build. Rather than reimplementing agent dispatch,
model tiering, and the fix loop, this span is written against a **named
executor** with a fixed contract — v1's executor is
`subagent-driven-development`, wrapped by `build-loop` to enforce the bridge
and the merge exclusion below.

The span is **Phases 5–7, not 6–7** — SDD's own scope begins at workspace
setup and model tiering (Phase 5), not at dispatch (Phase 6).

- **In:** the ticket files from `04-tickets/`, and the run directory path.
- **Out:** per-ticket briefs and reports bridged into `06-tasks/`, review
  reports into `07-reviews/`, deferred minors merged into `00-run.md`, and
  updated phase rows — all committed before the executor's own cleanup runs
  (Section 6).
- **Guarantee:** no ticket is accepted without a clean review; the fix loop
  escalates model tier at round 4 and stops at round 5.
- **Explicitly excluded: the merge.** The executor stops at a clean
  whole-branch review. `finishing-a-development-branch` runs in Phase 9
  (`phases/09-release.md`), **after** Gate 3 — never as part of this span.

**This exclusion is what makes Gate 3 meaningful.** SDD's own terminal node,
left unmodified, invokes `finishing-a-development-branch` as its own last
step — normal, correct behaviour for SDD running alone. Wrapped inside
`build-loop`, whatever runs Phases 5–7 must be told, explicitly, to stop at
"Final Review clean" instead of continuing to that call. Without this
instruction, SDD merges before Phase 8 even starts, Gate 3 fires over a
branch that no longer exists as a branch, and "approval" becomes a rubber
stamp on something already shipped. `phases/08-integrate.md` is written
assuming this stop already happened — its own Section 5 checks for a merge
having already occurred and flags it as an error if so, rather than trying
to prevent it itself.

A v1.1 executor may replace SDD with a deterministic `Workflow` script
implementing this same contract. Because the contract is stated rather than
assumed, that swap is a substitution, not a rewrite of this file.

---

## 8. Hard stops

Conditions that halt the loop and ask the user. These are failures, not
gates.

1. **Missing install-set skill**, found at Phase 0
   (`phases/00-bootstrap.md`, Section 1).
2. **Fix loop exhausted.** Round 5 reached after model escalation and the
   task still fails. The plan may be wrong; grinding further is waste.
3. **Deploy blocked.** The release step (`phases/09-release.md`, Section 4)
   needs credentials or access this session does not have.
4. **A Phase 3 decision proves wrong during build.** The chosen architecture
   cannot carry a ticket. With only four human stops in the whole loop, the
   real risk is the loop quietly redesigning mid-build instead of stopping —
   this is what makes stopping mandatory rather than a judgement call.

---

## 9. Resume

On invocation, check the target directory for
`docs/build-loop/*/00-run.md`. If one exists and its `## Phases` table has
any row not marked `done`, **resume from the first such phase** instead of
starting a fresh run — read that row's status (`open`, `skipped`, or
`blocked`) and the phase file's own Section 1 (or the equivalent delegated
skill) to pick up correctly rather than re-running completed work.

Only start fresh — Phase 0, a new run directory — when no such ledger exists,
or the one that does exists has every row `done` (a completed prior run;
treat a new idea in the same directory as a new run, not a continuation).

---

## 10. Scale tiers

Confirmed at **Gate 0**, at the end of Phase 0, before any tier effect can
take hold — not at Gate 1, which fires after the tier-dependent compression
of Phases 1–2 would already have happened.

| Tier | Trigger | Adaptation |
|---|---|---|
| **Small** | one component, no persistence, no external deploy target | Phases 1–2 compress to a single pass; no `wayfinder`; single ticket; direct execution; no migrations. **All three review gates still fire**, with reduced content |
| **Standard** | anything else | the full loop, subagent-driven execution |
| **Large** | multiple independent subsystems | `wayfinder` first, then decompose; sub-projects run **one at a time**, each with its own run directory and its own Gates 1 and 2; Gate 0 fires once for the whole; Gate 3 fires once, at the end, on the integrated result — sub-projects merge to a shared integration branch without individually deploying |

Small tier still ships: "no deploy target" means no external host, not no
release. Large tier's per-sub-project Gates 1/2 still fold their delegated
skills' own checkpoints (Section 4) the same way a Standard run does.
