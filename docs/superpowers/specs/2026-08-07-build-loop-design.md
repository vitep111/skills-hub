# build-loop — Design

**Date:** 2026-08-07
**Status:** Approved, ready for implementation planning

## Problem

`WORKFLOW.md` describes an excellent eleven-phase agent-native development
loop, maps every stage to a skill in this hub, and names the stages that have
no skill. It is a *description*. Nothing executes it.

The result is that starting a new project means remembering the loop,
remembering which skill drives each stage, and manually filling the gaps —
every time. The phases most often skipped are the ones with no skill behind
them, which are also the two the whole downstream plan inherits from
(architecture, and API contracts).

## Goal

One entry point — `build-loop` — that takes a greenfield project idea and
drives it through Phases 0–10 to a shipped, deployed result: invoking the
existing hub skills where they exist, executing inlined instructions where
they do not, spawning agents for the build, and stopping at exactly three
human gates.

## Scope

**In scope**

- Greenfield projects only. New project from an empty or near-empty directory.
- Phases 0 through 10, terminating in a deployed project, docs, and a retro.
- Three human gates; everything between them runs unattended.
- Inlined instructions for the gap stages, rather than new skills.
- Automatic scale right-sizing, proposed by the loop, confirmed by the user.

**Out of scope for v1**

- Brownfield work (features inside an existing codebase).
- Extracting the inlined gap content into standalone reusable hub skills.
- A `Workflow`-tool layer for deterministic parallel fan-out. Deferred to
  v1.1 behind a stated trigger; see *Phase 6–7 as a swappable executor* and
  *Verification*.
- A full threat-modelling methodology. A lightweight security posture is
  folded into the NFR subsection of Phase 3 instead.

## Approach

A single orchestrator **skill**, in this hub's native format.

`SKILL.md` is the phase machine. At each stage it either invokes an existing
skill or reads one of four gap files. It does not reimplement agent dispatch,
model tiering, or the fix loop — `obra/subagent-driven-development` already
does that, and delegating to it is the point.

### Rejected alternatives

**A `Workflow` script.** Deterministic JS, real `pipeline()` fan-out,
resumable, budget-aware. Rejected as the primary format because workflows run
as a background batch and cannot stop to ask a question, so the three gates
would degrade into three manually chained invocations. It is also
session-local rather than a portable skill folder, which fights the premise of
this repo.

**A hybrid** — orchestrator skill that hands Phases 6–7 to a `Workflow`
script for true parallel fan-out across tickets. This is the right end state.
It is not v1 because the script cannot be written well until the ticket and
task-brief formats have settled, and those only settle in a real run.

It is not, however, deferred indefinitely. Two concrete commitments make the
upgrade cheap and give it a trigger rather than a hope; see *Phase 6–7 as a
swappable executor* and *Verification*.

## Architecture

### Location

`skills/vitep/build-loop/` in the hub, following the existing
`skills/<source-owner>/<skill-name>/` convention. Authored here rather than
vendored, hence the `vitep` owner directory.

Unlike every other skill in this hub, `build-loop` is installed to
`~/.claude/skills/build-loop/` rather than copied per-project. Greenfield
means the target directory is empty at invocation time, so the skill must
already be globally available.

### Files

```
skills/vitep/build-loop/
  SKILL.md                  phase machine 0-10, the three gates,
                            the delegation table, the run-state contract
  phases/
    01-discover.md          prior art, success metrics, feasibility spike
    03-specify.md           architecture + ADRs, API/data contracts, NFRs
    08-09-ship.md           CI gate, versioning, deploy, migrations,
                            rollback, docs
    10-learn.md             retro, encode learnings as new hub skills
  reference/
    skill-map.md            every stage -> skill, extracted from
                            WORKFLOW.md Part B
  scripts/
    gate-check              deterministic ledger + artifact validation,
                            run before each gate
```

Only gap phases get their own file under `phases/`. Phases 0, 2, 4, 5, 6 and 7 are fully
covered by existing skills and appear as one line each in the SKILL.md
delegation table. A run therefore loads `SKILL.md` plus only the two or three
gap files it actually reaches.

### Relationship to WORKFLOW.md

`WORKFLOW.md` remains, as the reference document explaining *why* the loop has
this shape. `reference/skill-map.md` is the extract of its Part B that the
skill consults during a run. A pointer is added to the top of `WORKFLOW.md`
naming `build-loop` as its executable form, so the two do not drift into rival
sources of truth.

## Run state

Every run creates one directory in the target project. Everything lands there,
and all of it is committed — ADRs and the spec are genuine documentation for a
new repo, and briefs and review reports make the run auditable.

```
docs/build-loop/<YYYY-MM-DD>-<slug>/
  00-run.md            the ledger - the resume anchor
  01-discovery.md      prior art, success metrics
  02-design.md         chosen approach, rejected options, scope cut
  03-spec.md
  03-architecture.md   ADRs, including the deploy-target decision
  03-contracts.md      data model and API contracts
  04-plan.md
  04-tickets.md
  06-tasks/            per-task briefs and reports
  07-reviews/          per-task review reports
  09-release.md        version, changelog, migrations, rollback
  10-retro.md
```

### `00-run.md`

The ledger is what makes three gates survivable. A full greenfield run will
exhaust context and compact at least once; the ledger is what survives when
the conversation does not. It holds:

- **Run header** — idea, slug, date, scale tier.
- **Phase table** — phase, status, artifact path.
- **Gate log** — which gates were approved, when, and what was approved.
- **Decision log** — key decisions, including the deploy target.
- **Deferred-minors ledger** — required by `WORKFLOW.md` §A.4 rule 3, and read
  by the final whole-branch review.
- **Escalations** — any hard stop and its resolution.

Re-invoking `build-loop` in a directory containing an incomplete run reads the
ledger and resumes from the first unfinished phase.

### The ledger is a precondition, not a record

The phase row is written **on entering** a phase, before any work is done —
not appended afterwards as a summary of what happened. The artifact path is
filled in on exit.

This inversion is what gives `gate-check` something to verify. A phase that
was skipped leaves a row with no artifact, or no row at all where the
following phase has one. Written the other way round — as an after-the-fact
record — a skipped phase leaves no trace, and the ledger degrades into a
narration of whatever the run happened to do.

## Enforcement

The loop's phase sequence is expressed in instructions, and instructions are
followed by judgement rather than by machinery. The mitigation is not to
pretend otherwise but to make the one thing that matters — *did each phase
actually produce its artifact* — a fact on disk rather than a claim in prose.

### `scripts/gate-check`

A small deterministic script, run immediately before each gate fires. It reads
`00-run.md` and asserts:

- every phase row from 0 to the current phase is present;
- every completed row names an artifact that **exists on disk** and is
  non-empty;
- the gate's own prerequisites are met — for Gate 2, that
  `03-architecture.md` and `03-contracts.md` both exist; for Gate 3, that CI is
  green and the deferred-minors ledger has been read by the final review.

It exits non-zero on failure, and its output is shown to the user as part of
the gate. Skipping Phase 3 therefore surfaces as a missing file and a failed
check, not as a confident summary.

This is the same discipline `obra/verification-before-completion` already
demands of implementation work — evidence before assertions — applied to the
orchestrator itself.

### What enforcement cannot do

`gate-check` verifies that artifacts exist, not that they are any good. A
shallow, useless `03-architecture.md` passes it. Quality is not mechanically
enforceable, and claiming otherwise would be the more dangerous design.

That is what the gates are for, and it is why Gate 2 presents the actual ADRs
and contracts for reading rather than a summary of them. The script guards
against *omission*; the human guards against *emptiness*.

## The three gates

| | Fires after | User is shown | Approval means |
|---|---|---|---|
| **1 · Design** | Phase 2 Shape | discovery, chosen approach, scope cut, proposed scale tier | proceed to spec and architecture |
| **2 · Buildable package** | Phase 4 Plan | spec, ADRs including deploy target, contracts, plan, tickets | authorize the entire unattended build |
| **3 · Ready to ship** | Phase 8 Integrate, CI green | branch summary, review ledger, release plan | merge, deploy, docs, retro |

Between gates the loop runs unattended and spawns agents freely.

### Handoff conflict with `brainstorming`

`obra/brainstorming` declares a HARD-GATE: its terminal state is
`writing-plans`, and it must invoke no other skill. In this loop, Phase 3
(Specify — spec, architecture, contracts) sits between design approval and
planning.

`SKILL.md` therefore states the handoff explicitly: `build-loop` invokes
`brainstorming` for Phases 1–2, takes control back at design approval, runs
Phase 3, and reaches `writing-plans` at Phase 4 as `brainstorming` intended —
with Specify inserted. Left unwritten, a mid-run agent would follow
`brainstorming`'s gate straight past architecture, which is the exact P0 gap
this design exists to close.

## Hard stops

Three conditions halt the loop and ask the user. These are failures, not
gates.

1. **Fix loop exhausted.** Round 5 reached after model escalation and the task
   still fails. `WORKFLOW.md` §A.4 holds that the plan may be wrong; grinding
   further is waste.
2. **Deploy blocked.** The release step needs credentials or access the
   session does not have.
3. **A Phase 3 decision proves wrong during build.** The chosen architecture
   cannot carry a ticket. With only three gates, the real risk is that the
   loop quietly redesigns mid-build rather than stopping; this makes stopping
   mandatory.

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
  a lightweight security posture, so that review has a stated bar to check
  against.

### `08-09-ship.md`

- **CI gate** — CI must exist; for greenfield, create it. It must be green
  before Gate 3 fires.
- **Versioning and changelog** — semver, changelog generated from the ticket
  list.
- **Deploy** — execute the target chosen in the Phase 3 ADR.
- **Migrations** — only when the project has a datastore.
- **Rollback and flags** — a stated plan; implementation only where the deploy
  target supports it.
- **Documentation** — README, API docs, usage. A new project starts with none.

### `10-learn.md`

- Check the shipped result against the Phase 1 success metrics.
- Retro on **what the loop got wrong**, not what the code got wrong.
- Encode procedural learnings as a new hub skill via `obra/writing-skills`.
  This arrow is what makes the system compound rather than repeat.

## Scale adaptation

"Create something" spans a fifty-line CLI to a product. Eleven phases and
three gates on a small utility is overhead for its own sake. Phase 0 assesses
the idea, proposes a tier, and states it at Gate 1 for the user to confirm or
override.

| Tier | Trigger | Adaptation |
|---|---|---|
| **Small** | one component, no persistence, no deploy target | Phases 1–2 compress to a single pass; no `wayfinder`; single ticket; direct execution; no migrations; Gates 1 and 2 merge |
| **Standard** | anything else | the full loop, subagent-driven execution |
| **Large** | multiple independent subsystems | `wayfinder` first, then decompose into sub-projects and run `build-loop` once per sub-project, following the decomposition guidance in `obra/brainstorming` |

## Execution modes and agent dispatch

`SKILL.md` states the mode-selection rule and the artifact rule, then
delegates. It does not reimplement dispatch.

- **Direct execution** — plan is small, under roughly five tasks.
- **Subagent-driven** — plan has independent tasks; use
  `obra/subagent-driven-development`.
- **Parallel dispatch** — two or more tasks with no shared state and no
  ordering; use `obra/dispatching-parallel-agents`.

The governing rule, carried over from `WORKFLOW.md` §A.3: **artifacts move as
files, never as pasted text.** Briefs, diffs and reports are file paths.

### Phase 6–7 as a swappable executor

Gate 2 to Gate 3 is the longest unattended span in the loop and covers the
entire build. It is where drift is most likely and where a deterministic
mechanism would pay for itself most.

`SKILL.md` therefore writes Phases 6–7 against a **named executor** with a
fixed contract, rather than inlining the orchestration:

- **In:** the ticket list from `04-tickets.md`, and the run directory path.
- **Out:** a per-ticket brief and report under `06-tasks/`, a review report
  under `07-reviews/`, and updated rows in `00-run.md`.
- **Guarantee:** no ticket is marked accepted without a clean review, and the
  fix loop escalates model tier at round 4 and stops at round 5.

v1's executor is `obra/subagent-driven-development`. A v1.1 executor is a
`Workflow` script implementing the same contract with real `pipeline()`
fan-out. Because the contract is stated rather than assumed, swapping them is
a substitution, not a rewrite of `SKILL.md`.

## Verification

**Structural check.** Every stage listed in `reference/skill-map.md` resolves
to either a skill that exists on disk or a gap file that exists in
`phases/`. No stage may point at nothing.

**Real check.** A dry run on a genuine small greenfield project, end to end,
before the skill is considered done. The run must produce a complete
`00-run.md` ledger, pass `gate-check` at all three gates, and reach a deployed
result.

**The v1.1 trigger.** The dry run is also the decision point for the
`Workflow` executor. If it shows phase drift anywhere in the Gate 2 → Gate 3
span — a skipped review, a ticket accepted without one, a fix loop that ran
past round 5, or a `gate-check` failure at Gate 3 — then building the
`Workflow` executor is the next piece of work, not a future maybe. If the span
holds, v1's executor stays.

## Open risks

- **Model-driven discipline.** Nothing mechanically forces the phase
  *sequence*; the instructions do. `gate-check` and the ledger-as-precondition
  rule reduce this to a narrower risk — omission is now caught, but shallow
  work that satisfies the check is not. The residual exposure is concentrated
  in the Gate 2 → Gate 3 span, which is exactly what the swappable executor
  and its v1.1 trigger exist to address.
- **`gate-check` becoming theatre.** A check that only ever passes teaches the
  run to stop reading it. If the dry run never fails a gate, that is evidence
  the assertions are too weak, not that the loop is disciplined.
- **Deploy reliability.** Deploy targets vary widely. Anchoring the choice in a
  Phase 3 ADR helps, but Phase 9 remains the least predictable part of the
  loop and the most likely to hit hard stop 2.
- **Unattended stretch length.** Gate 2 to Gate 3 is the longest unattended
  span in the loop and covers the entire build. The deferred-minors ledger and
  the final whole-branch review are the safety net.
