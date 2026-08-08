# Skill Map

Derived from `WORKFLOW.md` Part B, which is the authority. Do not edit this
file without editing Part B — update Part B first, then re-derive this file
to match.

One row per Part B stage, numbered `<phase>.<n>` in Part B's own order
within each phase section. Columns: stage id, stage name, resolution.

`<resolution>` is exactly one of:

- a **bare skill name** — no owner directory, no slashes — resolving to
  `~/.claude/skills/<name>/`
- a **`phases/<file>.md`** gap file belonging to this skill, which must
  exist on disk
- the literal string **`out of scope for v1`**

**Read, not invoked.** These nine skill names carry
`disable-model-invocation: true`, whether or not they happen to appear as a
resolution below (some are reduced out of a multi-skill Part B cell by the
first-listed-skill rule and so don't appear in the table themselves — that
does not lift the restriction). No phase of `build-loop`, and no skill it
drives, may invoke any of the nine via the Skill tool. Wherever one of them
is the right skill for a stage, the correct action is: read that skill's
`SKILL.md` with the Read tool and follow its procedure directly.

```
pick-ui-library   prototype   review-animations   grill-me   handoff
implement   to-spec   to-tickets   wayfinder
```

Every other bare skill name in this map is invoked normally, via the Skill
tool.

---

## Phase 0 — Bootstrap

| Stage | Skill | |
|---|---|---|
| 0.1 | Skill discipline (find & invoke skills before acting) | using-superpowers |
| 0.2 | Environment readiness (deps installed, tests runnable) — greenfield reading: no project dependencies exist yet to install (those are chosen at Phase 3, installed at Phase 6); at Phase 0 "ready" means the skill install set, a git repo with a commit, and tracker config | phases/00-bootstrap.md |
| 0.3 | Session continuity / context compaction | handoff |

## Phase 1 — Discover

| Stage | Skill | |
|---|---|---|
| 1.1 | Idea capture → design intent | brainstorming |
| 1.2 | User & stakeholder intent | brainstorming |
| 1.3 | Prior art / competitive research | phases/01-discover.md |
| 1.4 | Success metrics definition | phases/01-discover.md |
| 1.5 | Feasibility spike / tech scouting | phases/01-discover.md |

## Phase 2 — Shape

| Stage | Skill | |
|---|---|---|
| 2.1 | Option exploration | brainstorming |
| 2.2 | Adversarial pressure-test | grill-me |
| 2.3 | Scope cut / prioritization | to-spec |
| 2.4 | Risk register | out of scope for v1 |

## Phase 3 — Specify

| Stage | Skill | |
|---|---|---|
| 3.1 | Functional spec (problem, stories, acceptance criteria) | to-spec |
| 3.2 | Non-functional requirements (perf, security, a11y, compliance) | phases/03-specify.md |
| 3.3 | Architecture & ADRs | phases/03-specify.md |
| 3.4 | Data model & API contracts | phases/03-specify.md |
| 3.5 | UX / UI / motion design | emil-design-eng |
| 3.6 | Dependency & library selection | pick-ui-library |

## Phase 4 — Plan

| Stage | Skill | |
|---|---|---|
| 4.1 | Large-scope mapping (bigger than one session) | wayfinder |
| 4.2 | Implementation plan w/ global constraints | writing-plans |
| 4.3 | Ticket decomposition + dependency edges | to-tickets |
| 4.4 | Estimation, sequencing, critical path | out of scope for v1 |
| 4.5 | Plan self-review before execution | writing-plans |

## Phase 5 — Orchestrate

| Stage | Skill | |
|---|---|---|
| 5.1 | Isolated workspace | using-git-worktrees |
| 5.2 | Clean baseline verification | using-git-worktrees |
| 5.3 | Execution mode selection | executing-plans |
| 5.4 | Model / cost tiering per role | subagent-driven-development |
| 5.5 | Task brief generation | subagent-driven-development |

## Phase 6 — Build

| Stage | Skill | |
|---|---|---|
| 6.1 | Dispatch implementer | subagent-driven-development |
| 6.2 | TDD inner loop | test-driven-development |
| 6.3 | Status handling (DONE / CONCERNS / NEEDS_CONTEXT / BLOCKED) | subagent-driven-development |
| 6.4 | Self-verification with evidence | verification-before-completion |
| 6.5 | Debugging | systematic-debugging |
| 6.6 | Spec/ticket-driven implementation | implement |

## Phase 7 — Review & Fix

| Stage | Skill | |
|---|---|---|
| 7.1 | Requesting review / review package | requesting-code-review |
| 7.2 | Multi-axis review (Standards × Spec) | code-review |
| 7.3 | Domain review — UI & motion | review-animations |
| 7.4 | Domain review — security | security-review |
| 7.5 | Domain review — performance / accessibility | out of scope for v1 |
| 7.6 | Receiving feedback with rigor | receiving-code-review |
| 7.7 | Fix rounds + model escalation | subagent-driven-development |
| 7.8 | Adjudication & minor deferral | subagent-driven-development |

## Phase 8 — Integrate

| Stage | Skill | |
|---|---|---|
| 8.1 | Final whole-branch review | subagent-driven-development |
| 8.2 | Finish branch (merge / PR / cleanup) | finishing-a-development-branch — executed at Phase 9, after Gate 3; never in Phase 8 |
| 8.3 | Merge-conflict resolution | out of scope for v1 |
| 8.4 | CI green gate | phases/08-integrate.md |

## Phase 9 — Release

| Stage | Skill | |
|---|---|---|
| 9.1 | Versioning & changelog | phases/09-release.md |
| 9.2 | CI/CD pipeline & deploy | phases/09-release.md |
| 9.3 | Database / data migrations | phases/09-release.md |
| 9.4 | Rollback plan & feature flags | phases/09-release.md |
| 9.5 | Documentation (README, API, user docs) | phases/09-release.md |

## Phase 10 — Operate & Learn

| Stage | Skill | |
|---|---|---|
| 10.1 | Observability & instrumentation | out of scope for v1 |
| 10.2 | Incident response & postmortem | out of scope for v1 |
| 10.3 | Analytics vs. success metrics | out of scope for v1 |
| 10.4 | Tech-debt & refactor backlog | out of scope for v1 |
| 10.5 | Retrospective / learning capture | phases/10-learn.md |
| 10.6 | Encode learnings as new skills | writing-skills |
