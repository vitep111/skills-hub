# Phase 3 — Specify

Run this after Gate 1 passes. It closes the two P0 gaps `build-loop` exists
for: **architecture/ADRs** (plans otherwise inherit unexamined structural
decisions with no record of why) and **API/data contracts** (without them,
each build subagent invents its own contract per task and they drift apart).

This phase writes three artifacts to the run directory:

- `03-spec.md` — the functional spec, produced by following `to-spec`.
- `03-architecture.md` — components, ADRs (including the mandatory
  deploy-target decision), and non-functional requirements. **Required and
  asserted non-empty by Gate 2.**
- `03-contracts.md` — API and data contracts. **Required and asserted
  non-empty by Gate 2.**

Phase 3's other two stages — UX/UI/motion design and dependency selection —
are ✅ covered by existing skills (`emil-design-eng`, `apple-design`,
`ui-ux-pro-max`, `pick-ui-library`) and are routed there directly by
`SKILL.md`'s delegation table, not by this file. This file scopes to the
three ❌ stages plus the functional spec.

---

## 1. Enter phase

First action, before any of the work below starts. Phase 3 owns opening its
own ledger row, and this file can be re-entered after a crash or a context
compaction — both expected, not exceptional — so the open must be
idempotent. Never append blindly.

1. **Check for an existing phase 3 row** in
   `docs/build-loop/<date>-<slug>/00-run.md`'s `## Phases` table:

   ```bash
   grep -Eq '^\|[[:space:]]*3[[:space:]]*\|' "docs/build-loop/<date>-<slug>/00-run.md"
   ```

2. **No row found.** First pass. Append it:

   ```
   | 3 | open | | |
   ```

3. **Row found, status `open`.** A resumed pass — the prior attempt was
   interrupted after the row was opened but before Exit (Section 7). Do not
   append a second row. Re-do Sections 2–6's work from scratch and let Exit
   flip this same row to `done`.

4. **Row found, status `done`.** Phase 3 already completed in a prior pass.
   Do not redo it. Stop here and proceed to Phase 4.

Once past this check, read two things before starting work:

- The confirmed tier from `00-bootstrap.md`'s `tier:` line — it governs the
  deploy-target ADR's default answer (Section 4).
- `02-design.md`, Phase 2's artifact (chosen approach, rejected options,
  scope cut) — Architecture and contracts describe what Gate 1 already
  approved, not a re-litigation of it.

---

## 2. Functional spec

Produced by following `to-spec` (`disable-model-invocation: true` — read
`~/.claude/skills/to-spec/SKILL.md` with the Read tool and follow its
procedure directly; never invoke it via the Skill tool).

1. Follow its process as written: explore the repo, sketch test seams
   (preferring existing seams, one seam if possible), then write the spec
   using its template (Problem Statement, Solution, User Stories,
   Implementation Decisions, Testing Decisions, Out of Scope, Further
   Notes).
2. **Redirect the publish step.** `to-spec` defaults to publishing to the
   issue tracker (`.scratch/<feature-slug>/spec.md` under the
   local-markdown tracker Phase 0 configured). Do not publish there — write
   the finished spec to `docs/build-loop/<date>-<slug>/03-spec.md` instead.
   This is a required reconciliation, not an optional shortcut: the run
   directory is the single audit trail, and a spec left in `.scratch/` is
   invisible to `gate-check` and to Phase 10's retro.
3. **Fold its checkpoint into Gate 2.** `to-spec` says to check with the
   user that the test seams match expectations before finalizing. Do not
   stop for that here — note the seams chosen in the spec, and let the user
   review them as part of Gate 2's package, alongside the plan and tickets
   Phase 4 produces. Stopping twice for the same approval is the failure
   mode this folding avoids.

---

## 3. Architecture

Components, boundaries, data flow, derived from `02-design.md`'s chosen
approach — this section makes that approach concrete enough to build from,
it does not choose a new one.

**Component inventory.** One row per component:

| Component | What it does | How it's used | Depends on |
|---|---|---|---|
| \<name\> | \<one or two sentences\> | \<who/what calls it, and when\> | \<other components, external services, libraries\> |

**Rule: reject a component whose internals must be read to know what it
does.** If the "what it does" cell needs "see the code" to be true, the
component isn't understood yet — go back and decide its responsibility
before writing it down. A component with an unclear boundary here becomes an
unclear ticket at Phase 4 and an unclear seam at Phase 6.

**Data flow.** Below the table, a short prose or ordered-list walkthrough of
how data moves through the components for the system's one or two primary
operations — request in, response out; or event in, side effect out. Name
the components from the table above by name; do not introduce new ones here.

For dependency choices (which library fills a "Depends on" cell), check
`pick-ui-library`'s curated list before defaulting to something outside it
(`disable-model-invocation: true` — read
`~/.claude/skills/pick-ui-library/SKILL.md` directly, never invoke via the
Skill tool). Its list is deliberate and taste-driven; don't substitute an
alternative unless the task genuinely isn't covered.

**Record the stack's install and test commands.** This is where the stack
is actually locked, so this is where the commands that operate it get
written down — one line each, exact and runnable, e.g. `npm ci` / `npm
test`, `pip install -e .` / `pytest`, `cargo build` / `cargo test`.
`phases/08-integrate.md`'s CI scaffold and `phases/09-release.md`'s release
steps both read these two lines verbatim from `03-architecture.md` rather
than re-deriving them; the exit template below (Section 7) is where they're
written.

---

## 4. ADRs

Each significant decision — one that later work would otherwise silently
inherit unexamined — recorded with this exact template:

```markdown
### ADR-<NN>: <decision in one line>

**Context.** What forces this decision. What is true that makes it necessary.

**Options.** Each considered option, one line each, with its main cost.

**Decision.** The option chosen, stated as a commitment not a preference.

**Consequences.** What this makes easy. What this makes hard. What it forecloses.
```

Number ADRs `ADR-01`, `ADR-02`, … in the order they're decided. A decision
belongs here when a later phase would otherwise have to guess or re-derive
it — data storage choice, framework/runtime choice, sync vs. async
processing, how state is shared across components, and the deploy target
below. A decision that's obviously implied by `02-design.md` and has no real
alternative does not need its own ADR; don't manufacture one for the sake of
a count.

### The deploy-target ADR is mandatory

Every run writes exactly one ADR deciding the deploy target — never
skipped, regardless of tier. **Phase 9 (`09-release.md`) executes whatever
this ADR names**, and deciding the target at release time is too late: by
then Phase 0's remote-creation decision and Phase 8's CI setup have already
had to guess at it. Deciding it here, before any ticket exists, is the
entire reason this ADR is required rather than optional.

Under the Small tier, "no external deploy target" is one of the tier's own
trigger conditions — for that case the correct decision is legitimately "no
external host, ship as a tagged release with generated docs." That answer
is still written as a full ADR, not shortened to a line or skipped as
self-evident. The worked example below is exactly that case — copy it
directly when it applies, adjusting only the specifics.

**The ADR also carries one machine-checkable line.** `gate-check` cannot
parse ADR prose — it can only assert a file is non-empty — so alongside the
four-part narrative above, add one literal line under **Decision**, at the
start of a line:

```
deploy-target: <one-line target>
```

e.g. `deploy-target: none — tagged release only` or `deploy-target: Fly.io`.
Gate 2 asserts this exact line exists in `03-architecture.md`; the ADR
narrative is for the human reading Gate 2's package, this line is for the
script running before it. Both describe the same decision — write the line
once the Decision sentence above it is settled, don't let them drift.

<deploy-target-adr-worked-example>

```markdown
### ADR-01: Deploy target

**Context.** Phase 9 executes deployment mechanically from whatever this
ADR names; deciding it at release time is too late, because Phase 0's
remote-creation step and Phase 8's CI setup already need to know whether an
external host exists. The confirmed tier is Small, whose own trigger names
"no external deploy target," and the approved design (`02-design.md`) is a
single-component tool with no persistence and no network-facing surface.

**Options.**
- Deploy to a PaaS (e.g. a hosted runtime) — real, but there is no server
  surface in this design to host; adds an account, a config file, and an
  ongoing bill for nothing the design uses.
- Publish to a package registry (npm/PyPI/etc.) — legitimate distribution,
  but premature: no external consumer has been confirmed, and registry
  publication is its own commitment (name squatting, semver discipline)
  this run hasn't earned yet.
- No external host — ship as a tagged git release with generated docs —
  costs nothing to operate; the tradeoff is there is no live, browsable
  artifact for a user to visit.

**Decision.** No external host. Phase 9 generates docs (README, usage
instructions) and the changelog into the repository itself, commits them,
and tags that commit (`git tag vX.Y.Z`) — not the bare merge commit, so the
tag always carries the docs it ships alongside. No deploy step runs, no
hosting credential is required, no uptime is owed.

deploy-target: none — tagged release only

**Consequences.** This makes shipping trivial and removes an entire class of
Phase 9 failure — missing deploy credentials, host outages, deploy-target
drift. It forecloses Phase 8 testing against a live deployment, and it means
"shipped" means "tagged and documented," not "reachable at a URL." If this
project later needs distribution, that is a new ADR written when the need is
real, not a retroactive edit of this one.
```

</deploy-target-adr-worked-example>

When a real external target does apply (a web app, an API service), write
the same four-part ADR with that target as the Decision — a hosting
provider, a registry, a container target — and state in Consequences what
credential or account Phase 8/9 will need, so a missing credential at
release time is a known risk, not a surprise. Add the `deploy-target:` line
here too, naming the same target in one line, e.g. `deploy-target: Fly.io`
or `deploy-target: npm registry` — Gate 2 requires it regardless of which
branch of this decision applies.

---

## 5. API and data contracts

Schemas, endpoint signatures, and error shapes, written now — before any
ticket exists — precisely because without them, each build subagent
invents its own contract per task and they drift apart from each other.
This section is the single source subagents check instead.

One block per contract, named and shaped like this:

```markdown
### Contract: <name>

**Consumers.** <which components or upcoming tickets call or rely on this — required>

**Shape.** <METHOD /path for an endpoint, or the type/schema name for a data contract>

**Request.** <request body/params shape, or "n/a" for a pure data schema>

**Response.** <response body shape, field names and types>

**Errors.** <each error shape/status the contract can return, and the condition that triggers it>
```

**Rule: a contract with no named consumer is rejected.** "Consumers"
unnamed means nothing downstream is known to depend on this shape yet — if
that's true, it's not a contract, it's a guess; wait until a real consumer
exists (Phase 4's tickets will surface it) rather than speculatively
contracting an unused interface.

**If this project has no external interface** — a Small-tier CLI with no
API and no persisted/shared data shape — do not leave `03-contracts.md`
empty. `gate-check` treats an empty file as a failed prerequisite,
indistinguishable from one nobody wrote. Write one explicit line instead:

```markdown
No external contracts. <one-line reason, e.g. "single-process CLI, no
network interface, no persisted data shared across components.">
```

---

## 6. Non-functional requirements

A performance budget with numbers, an accessibility bar, and a lightweight
security posture. **Phase 7's review checks the shipped work against this
section** — a vague NFR here is an unenforceable one there, so every line
must be a number or a concrete, checkable statement, not an adjective.

Write under this shape:

```markdown
## Non-functional requirements

### Performance budget
- <operation> — <numeric budget, e.g. "under 200ms p95"> — measured by <exact procedure>

### Accessibility bar
- <standard or stated bar, e.g. "WCAG 2.1 AA" or, for a CLI, "every error exits non-zero with a human-readable message on stderr">
- <what gets checked to confirm it: keyboard nav / contrast ratios / screen-reader labels / etc., as applicable>

### Security posture
- Sensitive data: <what data is sensitive, or "none">
- Trust boundary: <where untrusted input enters the system>
- Authentication story: <mechanism used, or "none — no auth surface in this design">
```

A component with no meaningful performance concern still gets a line stating
that plainly (e.g. "startup — under 1s cold — measured by `time` on the
built binary") rather than an omitted section; "n/a" is acceptable only for
Security posture's Sensitive data / Authentication fields when the design
genuinely has neither.

---

## 7. Exit

1. Write `docs/build-loop/<date>-<slug>/03-architecture.md`:

   ```markdown
   # Phase 3 — Architecture

   install: <command that installs the stack's dependencies>
   test: <command that runs the stack's test suite>

   ## Components
   <component table from Section 3>

   ## Data flow
   <data flow walkthrough from Section 3>

   ## ADRs
   <every ADR from Section 4, in ADR-NN order, including ADR for the deploy target>

   ## Non-functional requirements
   <content from Section 6, exact subheadings>
   ```

2. Write `docs/build-loop/<date>-<slug>/03-contracts.md`:

   ```markdown
   # Phase 3 — Contracts

   <one "### Contract: <name>" block per Section 5, or the explicit
   "No external contracts" line if none apply>
   ```

3. Confirm `03-spec.md` was already written in Section 2 — if the redirect
   step was skipped, write it now before continuing; Gate 2 needs all three
   files, not just the two it names explicitly.

4. In `00-run.md`, change phase 3's row from `open` to `done`, naming
   `03-architecture.md` as the artifact — the ledger holds one artifact per
   row, and `03-architecture.md` is the Gate 2 prerequisite most likely to
   be skipped under time pressure, so it's the one worth having the ledger
   assert:

   ```
   | 3 | done | 03-architecture.md | |
   ```

5. Commit:

   ```bash
   git add "docs/build-loop/<date>-<slug>/00-run.md" \
           "docs/build-loop/<date>-<slug>/03-spec.md" \
           "docs/build-loop/<date>-<slug>/03-architecture.md" \
           "docs/build-loop/<date>-<slug>/03-contracts.md"
   git commit -m "chore(build-loop): phase 3 complete, spec/architecture/contracts recorded"
   ```

Gate 2 does not fire here — `scripts/gate-check <run-dir> 2` requires phase 4
done as well, and phase 4 (Plan) is out of this file's scope. Proceed to
whatever drives phase 4 next; do not run `gate-check` from this file.
