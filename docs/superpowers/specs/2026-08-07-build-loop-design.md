# build-loop — Design

**Date:** 2026-08-07
**Status:** Approved. Ready for implementation planning.

## Problem

`WORKFLOW.md` describes an eleven-phase agent-native development loop, maps
each stage to a skill (in this hub or, for some stages, to a Claude Code
built-in), and names the stages that have no skill at all. It is a
*description*. Nothing executes it.

Starting a new project therefore means remembering the loop, remembering which
skill drives each stage, and manually filling the gaps — every time. The
stages most often skipped are the ones with no skill behind them, and two of
those are structural: architecture/ADR, which every downstream plan inherits
its decisions from, and API contracts, which subagents otherwise invent
per-task and drift apart on.

## Goal

One entry point — `build-loop` — that takes a greenfield project idea and
drives it through Phases 0–10 to a shipped result: invoking or following the
existing hub skills where they exist, executing inlined instructions where
they do not, spawning agents for the build, and stopping at exactly three
human gates plus a scale confirmation.

## Scope

**In scope**

- Greenfield projects only. New project from an empty or near-empty directory.
- Phases 0 through 10, terminating in a shipped project, docs, and a retro.
- Three human gates plus one scale confirmation at the end of Phase 0.
  Everything else runs unattended.
- Inlined instructions for the gap stages, rather than new skills.
- Scale right-sizing across Small / Standard / Large tiers.

**Out of scope for v1**

- Brownfield work (features inside an existing codebase).
- Extracting the inlined gap content into standalone reusable hub skills.
- A `Workflow`-tool layer for deterministic parallel fan-out. Deferred to
  v1.1 behind a stated trigger; see *Phases 5–7 as a swappable executor* and
  *Verification*.
- A full threat-modelling methodology. A lightweight security posture is
  folded into the NFR subsection of Phase 3 instead.
- **These `WORKFLOW.md` stages are explicitly dropped from v1** and must be
  marked as such in `reference/skill-map.md`: risk register (2.4), estimation
  and critical path (4.4), merge-conflict resolution (8.3), performance and
  accessibility domain review (7.3), observability (10.1), incident response
  and postmortem (10.2), analytics against metrics (10.3), and tech-debt
  backlog (10.4). Dropping them is a decision, not an oversight; a later
  version may add them.

## Approach

A single orchestrator **skill**, in this hub's native format.

`SKILL.md` is the phase machine. At each stage it either drives an existing
skill or reads one of five gap files. It does not reimplement agent dispatch,
model tiering, or the fix loop — `obra/subagent-driven-development` (SDD)
already does that, and delegating to it is the point.

### Driving user-invoke-only skills

Nine skills in this hub carry `disable-model-invocation: true`, which
`mattpocock/writing-great-skills` defines as *"only you, typing its name, can
invoke it — and no other skill can."*

`emilkowalski/pick-ui-library`, `emilkowalski/prototype`,
`emilkowalski/review-animations`, `mattpocock/grill-me`, `mattpocock/handoff`,
`mattpocock/implement`, `mattpocock/to-spec`, `mattpocock/to-tickets`,
`mattpocock/wayfinder`.

These drive Phases 0, 2, 3, 4 and 7 — including the entire Gate 1 → Gate 2
span, which is meant to run unattended. An orchestrator skill cannot invoke
any of them via the Skill tool.

**Resolution: read, do not invoke.** `disable-model-invocation`
governs Skill-tool invocation and description-based auto-triggering. It does
not prevent `build-loop` from *reading* `<skill>/SKILL.md` with the Read tool
and following its procedure directly. This keeps every upstream skill
byte-identical, requires no frontmatter divergence, and leaves the skills
still user-invocable exactly as their authors intended.

Its cost: `build-loop` must resolve each skill's supporting files and scripts
by path itself, and a skill's procedure is followed rather than encapsulated,
so a skill that changes upstream changes `build-loop`'s behaviour silently.
`reference/skill-map.md` records the resolved path for each, which is what the
structural check verifies.

Alternatives considered and rejected: inlining their content as further gap
files (duplicates skills this hub already owns, and rots); instructing the
user to type them at each point (adds roughly six human stops, contradicting
the three-gate decision); amending the frontmatter in this hub (diverges from
upstream, and makes those skills auto-invocable by *anything*, not just
`build-loop` — a side effect well beyond this design's remit).

### Rejected alternatives

**A `Workflow` script.** Deterministic JS, real `pipeline()` fan-out,
resumable, budget-aware. Rejected as the primary format because workflows run
as a background batch and cannot stop to ask a question, so the gates would
degrade into manually chained invocations. It is also session-local rather
than a portable skill folder, which fights the premise of this repo.

**A hybrid** — orchestrator skill that hands the build to a `Workflow` script.
This is the right end state. It is not v1 because the script cannot be written
well until the ticket and task-brief formats have settled, and those only
settle in a real run. It is deferred behind a stated trigger, not indefinitely;
see *Verification*.

## Architecture

### Location and install set

`skills/vitep/build-loop/` in the hub, following the existing
`skills/<source-owner>/<skill-name>/` convention. Authored here rather than
vendored, hence the `vitep` owner directory.

Greenfield means the target directory is empty at invocation, so `build-loop`
**and every skill it drives** must already be available globally. The install
set is:

```
~/.claude/skills/
  build-loop/
  brainstorming/            grill-me/          to-spec/
  writing-plans/            to-tickets/        wayfinder/
  subagent-driven-development/                 implement/
  dispatching-parallel-agents/                 test-driven-development/
  systematic-debugging/     verification-before-completion/
  requesting-code-review/   receiving-code-review/
  finishing-a-development-branch/              using-git-worktrees/
  writing-skills/           handoff/           code-review/
  pick-ui-library/
```

**Flat, not nested.** SDD dispatches its final reviewer via a relative sibling
path, `../requesting-code-review/code-reviewer.md`, which resolves only if the
two are siblings. The hub's `skills/<owner>/<name>/` nesting does not survive
into the install; owner directories are dropped.

Phase 0 verifies the install set is present. A missing skill is a **hard
stop**, not a silent degradation — `build-loop` reports which skill is absent
and where to copy it from.

### Files

```
skills/vitep/build-loop/
  SKILL.md                  phase machine 0-10, the gates, the delegation
                            table, the run-state contract
  phases/
    00-bootstrap.md         repo init, install-set check, tracker config,
                            scale assessment
    01-discover.md          prior art, success metrics, feasibility spike
    03-specify.md           architecture + ADRs, API/data contracts, NFRs
    08-integrate.md         whole-branch review, CI gate  (pre-Gate 3)
    09-release.md           versioning, deploy, migrations, rollback, docs
    10-learn.md             retro, encode learnings as new hub skills
  reference/
    skill-map.md            every stage -> resolved skill path, or the
                            marker "out of scope for v1"
  scripts/
    gate-check              deterministic ledger + artifact validation,
                            run before each gate
```

Phases 08 and 09 are separate files because **Gate 3 fires between them**. A
single file straddling the loop's last human gate would put the release work
one scroll away from the approval that authorizes it.

Of the phases without a gap file, **only Phase 6 is fully covered by existing
skills** — `WORKFLOW.md` says so explicitly and says it of no other phase.
Phases 2, 4, 5 and 7 are covered for the stages `build-loop` drives, with
their remaining ❌ stages dropped per *Scope*. Every complete run loads all six
gap files.

### Relationship to WORKFLOW.md

`WORKFLOW.md` Part B is the **authority** for the stage → skill mapping.
`reference/skill-map.md` is a derived extract, adding the resolved install
path and the v1 scope marker for each stage. The structural check verifies the
extract against Part B, so the two cannot drift silently. A pointer at the top
of `WORKFLOW.md` names `build-loop` as its executable form.

## Phase 0 — bootstrap

Phase 0 does more than the original design acknowledged, because everything
downstream assumes conditions that a greenfield directory does not satisfy.

1. **Install-set check.** Every skill in the install set is present. Missing
   skill → hard stop.
2. **Repository bootstrap.** `git init` if needed; write `.gitignore`; make an
   initial commit so `using-git-worktrees` has a commit to branch from; create
   the remote if the deploy target or CI will need one. Without an initial
   commit, Phase 5 cannot start.
3. **Tracker config.** The `mattpocock` skills (`to-spec`, `to-tickets`,
   `code-review`, `wayfinder`) expect `docs/agents/issue-tracker.md` and refer
   users to a `/setup-matt-pocock-skills` command that is not in this hub.
   Phase 0 writes that file itself, configured for the **local-markdown
   tracker**, which `wayfinder` names as the documented fallback.
4. **Run directory.** Created on the default branch and committed.
5. **Scale assessment.** Assess the idea, propose a tier, and **confirm it
   with the user now** — see *Scale adaptation*.

## Run state

Every run creates one directory in the target project. All of it is committed
— ADRs and the spec are genuine documentation for a new repo, and briefs and
review reports make the run auditable.

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
  06-tasks/            per-task briefs and reports (bridged, see below)
  07-reviews/          per-task review reports (bridged, see below)
  08-integrate.md      whole-branch review verdict, CI run id + conclusion
  09-release.md        version, changelog, migrations, rollback
  10-retro.md
```

### Where delegated skills actually write, and how it is reconciled

Every delegated skill has its own output convention. None of them default to
the run directory. Each row below is a required reconciliation step, not an
assumption:

| Run-state artifact | Skill's own default | Reconciliation |
|---|---|---|
| `02-design.md` | `brainstorming` → `docs/superpowers/specs/…-design.md` | override — the skill states user preferences for spec location take precedence |
| `03-spec.md` | `to-spec` → the issue tracker | tracker is local-markdown per Phase 0, so redirect its output path |
| `04-plan.md` | `writing-plans` → `docs/superpowers/plans/…md` | override — same precedence clause |
| `04-tickets/` | `to-tickets` → `.scratch/<slug>/issues/<NN>-<slug>.md` | redirect the issue directory into the run directory |
| `06-tasks/`, `07-reviews/` | SDD → `.superpowers/sdd/<plan>/`, **git-ignored** | **bridge, see below** |

### The SDD bridge

SDD keeps briefs, reports and review packages in a git-ignored workspace, runs
its own ledger at `<workspace>/progress.md`, and **deletes the workspace**
(`rm -rf`) when the final review is clean. Left alone, the audit trail this
design promises is written where it will never be committed and then erased
before Gate 3 can show it.

`build-loop` therefore copies the SDD workspace into `06-tasks/` and
`07-reviews/` and commits it **before** SDD's Finish step runs.

**`00-run.md` is authoritative for deferred minors.** SDD's `progress.md`
holds them while the build is in flight; the bridge copies them into
`00-run.md`'s deferred-minors ledger, which is what the Phase 8 whole-branch
review reads. Two ledgers exist during Phases 5–7 and this states which wins.

### `00-run.md` format

The ledger is what makes long unattended spans survivable. A full greenfield
run will exhaust context and compact at least once; the ledger is what
survives when the conversation does not. `gate-check` parses it, so its format
is fixed, not prose:

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

`status` is one of `open`, `done`, `skipped`, `blocked`. `gate-check` treats
only `done` as completed and requires an artifact for it; `skipped` requires a
reason column entry and is legal only for stages marked out of scope. The
**currently open phase is exempt** from the artifact requirement — without
that exemption the check fails on every gate, since the check runs while the
gate's own phase is still open.

The ledger also holds: a gate log, a decision log including the deploy target,
the deferred-minors ledger, and any escalations.

Re-invoking `build-loop` in a directory containing an incomplete run reads the
ledger and resumes from the first phase not marked `done`.

### The ledger is a precondition, not a record

The phase row is written **on entering** a phase, with `status: open`, before
any work is done. The artifact path and `status: done` are written on exit.

This inversion is what gives `gate-check` something to verify. A skipped phase
leaves a row with no artifact, or no row at all where the following phase has
one. Written the other way round — appended afterwards as a summary — a
skipped phase leaves no trace, and the ledger degrades into a narration of
whatever the run happened to do.

### Which working tree

The run directory is created on the default branch at Phase 0. Phases 5–8
execute inside the worktree branch, so their artifacts land there and reach
the default branch only at the Phase 8 merge. **`gate-check` runs from the
worktree** for Gates 2 and 3, and from the default branch for Gate 1.

## The gates

| | Fires after | User is shown | Approval means |
|---|---|---|---|
| **0 · Scale** | Phase 0 | proposed tier and what it changes | run at this tier |
| **1 · Design** | Phase 2 Shape | discovery, chosen approach, scope cut | proceed to spec and architecture |
| **2 · Buildable package** | Phase 4 Plan | spec, ADRs incl. deploy target, contracts, plan, tickets | authorize the entire unattended build |
| **3 · Ready to ship** | Phase 8, **before merge** | branch summary, whole-branch review verdict, CI conclusion, deferred-minors ledger, release plan | merge, deploy, docs, retro |

Between gates the loop runs unattended and spawns agents freely.

Gate 0 is a confirmation, not a review gate — but it is a human stop and the
spec names it rather than pretending the loop has exactly three.

### Gate 3 fires before the merge, not after

SDD's own terminal node invokes `finishing-a-development-branch`, and its
scope runs through the whole-branch review. Left as-is, Gate 3 would ask the
user to approve a merge that had already happened.

Gate 3 therefore fires after the whole-branch review and CI, and **before**
`finishing-a-development-branch`. The executor contract below names the merge
as explicitly excluded, because SDD will otherwise perform it.

### Human stops inside delegated skills

The claim that the loop runs unattended between gates is false unless each
delegated skill's own checkpoints are handled. They are not incidental —
there are roughly six, and one of them is in a skill this design already
examined:

| Skill | Its checkpoint | `build-loop` does |
|---|---|---|
| `brainstorming` | approval after each design section | folds into Gate 1 — sections are presented as one package |
| `brainstorming` | User Review Gate on the written spec | folds into Gate 1 |
| `to-spec` | "check with the user that these seams match" | folds into Gate 2 |
| `to-tickets` | "iterate until the user approves the breakdown" | folds into Gate 2 |
| SDD | consent required before implementing on `main` | pre-satisfied: Phase 5 creates a worktree branch, so implementation never runs on `main` |
| `wayfinder` (Large tier only) | scope confirmation | folds into Gate 1 |

Folding means `build-loop` instructs the skill that approval is deferred to
the named gate and carries the material there. Where read-not-invoke applies,
this is straightforward: the checkpoint is an instruction in a file being
followed, not a mechanism being triggered.

### Handoff conflict with `brainstorming`

Two distinct rules, often conflated, and only one of them is the problem:

- The tagged `<HARD-GATE>` forbids implementation action before design
  approval. `build-loop` already satisfies this — Gate 1 *is* that approval.
- A separate, **untagged** rule states that the only skill invoked after
  brainstorming is `writing-plans`. This is the one that would carry a run
  straight from design to planning, past Phase 3 — the exact P0 gap this
  design exists to close.

`SKILL.md` states the handoff against the second rule: `build-loop` follows
`brainstorming` for Phases 1–2, takes control at Gate 1, runs Phase 3, and
reaches `writing-plans` at Phase 4 as `brainstorming` intended — with Specify
inserted.

## Hard stops

Conditions that halt the loop and ask the user. These are failures, not gates.

1. **Missing install-set skill** at Phase 0.
2. **Fix loop exhausted.** Round 5 reached after model escalation and the task
   still fails. `WORKFLOW.md` §A.4 holds that the plan may be wrong; grinding
   further is waste.
3. **Deploy blocked.** The release step needs credentials or access the
   session does not have.
4. **A Phase 3 decision proves wrong during build.** The chosen architecture
   cannot carry a ticket. With few gates, the real risk is that the loop
   quietly redesigns mid-build rather than stopping; this makes stopping
   mandatory.

## Enforcement

The phase sequence is expressed in instructions, and instructions are followed
by judgement rather than machinery. The mitigation is not to pretend otherwise
but to make the one thing that matters — *did each phase actually produce its
artifact* — a fact on disk rather than a claim in prose.

### `scripts/gate-check`

Run immediately before each gate. It reads `00-run.md` and asserts:

- every phase row from 0 to the current phase is present;
- every `done` row names an artifact that exists and is non-empty — for a
  directory artifact, **non-empty means it contains at least one file**;
- every `skipped` row carries a reason and corresponds to a stage marked out
  of scope in `reference/skill-map.md`;
- the currently open phase's row is exempt from the artifact requirement;
- gate-specific prerequisites: for Gate 2, `03-architecture.md` and
  `03-contracts.md` both exist; for Gate 3, `08-integrate.md` names a CI run
  identifier and a conclusion of `success`, and the whole-branch review report
  contains a triage verdict line for every entry in the deferred-minors
  ledger.

Non-zero exit on failure; output shown to the user as part of the gate.
Skipping Phase 3 surfaces as a missing file and a failed check, not as a
confident summary.

Both Gate 3 prerequisites are deliberately **observable proxies**. "CI is
green" and "the reviewer read the ledger" are not facts on disk; a recorded
run id with a conclusion, and a per-minor triage line in a report, are. A
check that asserts unobservable things is prose with an exit code.

This is the discipline `obra/verification-before-completion` already demands
of implementation work — evidence before assertions — applied to the
orchestrator itself.

### What enforcement cannot do

`gate-check` verifies that artifacts exist, not that they are any good. A
shallow, useless `03-architecture.md` passes it. Quality is not mechanically
enforceable, and claiming otherwise would be the more dangerous design.

That is what the gates are for, and it is why Gate 2 presents the actual ADRs
and contracts for reading rather than a summary of them. The script guards
against *omission*; the human guards against *emptiness*.

## Inlined gap content

### `01-discover.md`

- **Prior art** — search for existing solutions. Record 3–5, each with one
  takeaway: steal this, or avoid that.
- **Success metrics** — 2–4 measurable criteria defining "working", written
  before building. Phase 10 checks the shipped result against them.
- **Feasibility spike** — only when a technical unknown could invalidate the
  approach. Timeboxed, throwaway code.

### `03-specify.md`

The heaviest gap file; it closes P0 gaps 1 and 2.

- **Architecture and ADRs** — components, boundaries, data flow. Each
  significant decision recorded as context / options / decision /
  consequences. **The deploy target is an ADR here**, because Phase 9 executes
  what was chosen and deciding it at release time is too late.
- **API and data contracts** — schemas, endpoint signatures, error shapes,
  written before any ticket exists. This is what prevents subagents inventing
  contracts per-task and drifting apart.
- **Non-functional requirements** — performance budget, accessibility bar, and
  a lightweight security posture, so review has a stated bar to check against.

### `08-integrate.md`

- **Whole-branch review** — the most capable model, reading the full diff and
  the deferred-minors ledger, emitting a triage verdict per minor.
- **CI gate** — CI must exist; for greenfield, Phase 9's pipeline setup is
  scaffolded here so there is something to run. Record the run identifier and
  conclusion in `08-integrate.md`. Gate 3 will not pass without `success`.

### `09-release.md`

Everything here runs **after** Gate 3.

- **Merge** — via `finishing-a-development-branch`.
- **Versioning and changelog** — semver, changelog generated from the tickets.
- **Deploy** — execute the target chosen in the Phase 3 ADR.
- **Migrations** — only when the project has a datastore.
- **Rollback and flags** — a stated plan; implementation only where the deploy
  target supports it.
- **Documentation** — README, API docs, usage. A new project starts with none.

### `10-learn.md`

- Check the shipped result against the Phase 1 success metrics.
- Retro on **what the loop got wrong**, not what the code got wrong.
- Encode procedural learnings as a new hub skill via `writing-skills`.

The run executes in the target project; the hub is a separate repository.
`build-loop` locates it via a `SKILLS_HUB` path recorded in `00-bootstrap.md`
at Phase 0, defaulting to `C:\Claude\skills-hub`. If the hub is not present,
the learning is written to `10-retro.md` and flagged for manual transfer
rather than lost. When the hub is present, the hub's own `CLAUDE.md` policy
applies: the new skill is merged to `main` immediately, not left on a branch.

This does not contradict the out-of-scope line excluding *"extracting the
inlined gap content into standalone hub skills"* — that excludes refactoring
`build-loop`'s own gap files; this authors new skills from run learnings.

## Scale adaptation

"Create something" spans a fifty-line CLI to a product. Eleven phases on a
small utility is overhead for its own sake.

**The tier is confirmed at Gate 0, at the end of Phase 0** — before any tier
effect takes hold. The earlier design confirmed it at Gate 1, which was
circular: the Small tier compresses Phases 1–2, so by the time Gate 1 arrived
the compression had already happened.

| Tier | Trigger | Adaptation |
|---|---|---|
| **Small** | one component, no persistence, no external deploy target | Phases 1–2 compress to a single pass; no `wayfinder`; single ticket; direct execution; no migrations. **All three gates still fire**, with reduced content |
| **Standard** | anything else | the full loop, subagent-driven execution |
| **Large** | multiple independent subsystems | `wayfinder` first, then decompose; see below |

**Small tier still ships.** "No deploy target" means no external host, not no
release: for the Small tier, shipping means a tagged release with generated
docs, and the deploy-target ADR records that choice explicitly rather than
being skipped.

**Large tier recursion.** `wayfinder` maps the whole, then sub-projects are
run **one at a time**, per `brainstorming`'s decomposition guidance. Each
sub-project gets its own `docs/build-loop/<date>-<slug>/` directory and its
own Gates 1 and 2. Gate 0 fires once for the whole. **Gate 3 fires once, at
the end**, on the integrated result — sub-projects merge to a shared
integration branch without individually deploying. Ship and retro run once.

## Execution modes and agent dispatch

`SKILL.md` states the mode-selection rule and the artifact rule, then
delegates. It does not reimplement dispatch.

- **Direct execution** — plan is small, under roughly five tasks.
- **Subagent-driven** — plan has independent tasks; use SDD.
- **Parallel dispatch** — two or more tasks with no shared state and no
  ordering; use `dispatching-parallel-agents`.

The governing rule, carried over from `WORKFLOW.md` §A.3: **artifacts move as
files, never as pasted text.** Briefs, diffs and reports are file paths.

### Phases 5–7 as a swappable executor

Gate 2 to Gate 3 is the longest unattended span in the loop and covers the
entire build. It is where drift is most likely and where a deterministic
mechanism would pay for itself most.

`SKILL.md` writes this span against a **named executor** with a fixed
contract, rather than inlining the orchestration. The span is Phases 5–7, not
6–7 — SDD's own scope begins at workspace setup and model tiering:

- **In:** the ticket files from `04-tickets/`, and the run directory path.
- **Out:** per-ticket briefs and reports bridged into `06-tasks/`, review
  reports into `07-reviews/`, deferred minors merged into `00-run.md`, and
  updated phase rows — all committed before the executor's own cleanup runs.
- **Guarantee:** no ticket is accepted without a clean review; the fix loop
  escalates model tier at round 4 and stops at round 5.
- **Explicitly excluded:** the merge. The executor stops at a clean
  whole-branch review. `finishing-a-development-branch` runs in Phase 9,
  after Gate 3.

v1's executor is SDD, wrapped by `build-loop` to enforce the bridge and the
merge exclusion. A v1.1 executor is a `Workflow` script implementing the same
contract with real `pipeline()` fan-out. Because the contract is stated rather
than assumed, swapping them is a substitution, not a rewrite of `SKILL.md`.

## Verification

**Structural check.** Every stage in `reference/skill-map.md` resolves to one
of exactly three things: a skill present in the install set at its recorded
path, a gap file present in `phases/`, or the explicit marker *out of scope
for v1*. No stage may point at nothing. The check also verifies
`skill-map.md`'s stage list matches `WORKFLOW.md` Part B, so the derived
extract cannot drift from its authority.

**Real check.** A dry run on a genuine small greenfield project, end to end,
before the skill is considered done. The run must produce a complete
`00-run.md` ledger, pass `gate-check` at all three gates, and reach a shipped
result.

**The v1.1 trigger.** The dry run is also the decision point for the
`Workflow` executor. If it shows phase drift anywhere in the Gate 2 → Gate 3
span — a skipped review, a ticket accepted without one, a fix loop past round
5, or a `gate-check` failure at Gate 3 — then building the `Workflow` executor
is the next piece of work, not a future maybe. If the span holds, v1's
executor stays.

## Open risks

- **Model-driven discipline.** Nothing mechanically forces the phase
  *sequence*; the instructions do. `gate-check` and the ledger-as-precondition
  rule narrow this — omission is caught, shallow work that satisfies the check
  is not. The residual exposure concentrates in the Gate 2 → Gate 3 span,
  which is what the swappable executor and its v1.1 trigger address.
- **`gate-check` becoming theatre.** A check that only ever passes teaches the
  run to stop reading it. If the dry run never fails a gate, that is evidence
  the assertions are too weak, not that the loop is disciplined.
- **Read-not-invoke coupling.** Following a skill's procedure rather than
  invoking it means an upstream edit to that skill changes `build-loop`'s
  behaviour with no signal. The structural check catches a moved or deleted
  file; it cannot catch a changed instruction.
- **Delegated-skill drift generally.** Five of the reconciliations in *Run
  state* depend on overriding a skill's default output path. Two of those
  skills document that user preferences take precedence; three do not, and
  those redirections rest on instruction-following alone.
