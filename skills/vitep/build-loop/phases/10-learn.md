# Phase 10 — Learn

Run this after Phase 9. It produces `10-retro.md`: whether the run's own
success metrics actually passed, a retro on what the **loop** — not the
product's code — got wrong, and, where a finding is procedural rather than
project-specific, a new skill written into the hub. No gate follows this
phase; Gate 3 was the last human approval point in the loop, and it already
fired at the end of Phase 8 (`08-integrate.md`, Section 7), before Phase 9
ran. Phase 10 is the last thing `build-loop` does.

**This phase writes to a second repository.** The run executes inside the
target project; the hub (`skills-hub`) is a separate git repo, reached only
through the `SKILLS_HUB` path Phase 0 recorded. Section 4 is the only place
here that crosses that boundary — everything else is a document write local
to the run directory, same as every phase before Phase 9.

---

## 1. Enter phase

First action, before any metric check or retro work starts. Phase 10 owns
opening its own ledger row, and this file can be re-entered after a crash or
a context compaction — both expected, not exceptional — so the open must be
idempotent. Never append blindly.

1. **Check for an existing phase 10 row** in
   `docs/build-loop/<date>-<slug>/00-run.md`'s `## Phases` table — the
   two-digit guard, mirroring `01-discover.md`'s phase-1 guard
   (`^\|[[:space:]]*1[[:space:]]*\|`) without colliding with it, since a
   space/pipe boundary must immediately follow the digits:

   ```bash
   grep -Eq '^\|[[:space:]]*10[[:space:]]*\|' "docs/build-loop/<date>-<slug>/00-run.md"
   ```

   Verify rather than trust this by construction:

   ```bash
   printf '| 10 | open | | |\n' | grep -Eq '^\|[[:space:]]*10[[:space:]]*\|' && echo "matches phase 10"
   printf '| 1 | open | | |\n'  | grep -Eq '^\|[[:space:]]*10[[:space:]]*\|' || echo "correctly does not match phase 1"
   ```

2. **No row found.** First pass. Append `| 10 | open | | |`.
3. **Row found, status `open`.** A resumed pass. Metric check (Section 2),
   Retro (Section 3), and Scope note (Section 5) are plain document writes —
   redo them from scratch, the simple-redo rule the rest of the loop uses.
   **Encode learnings (Section 4) is the exception:** it can commit into the
   hub, so it states its own idempotency check rather than being redone
   blindly.
4. **Row found, status `done`.** Phase 10, and the whole loop, already
   completed. Stop — there is no Phase 11 to proceed to.

Before starting, read what this phase depends on and does not re-derive:
`01-discovery.md`'s `## Success metrics` (Section 2 checks these) and
`00-bootstrap.md`'s `SKILLS_HUB:` line (Section 4 needs it).

---

## 2. Metric check

Read `01-discovery.md`'s `## Success metrics` section verbatim — the exact
numbered list Phase 1 wrote, each line shaped `<claim> — check: <exact
procedure>`. For each metric, actually run the stated procedure against the
shipped result and record pass/fail plus the evidence it produced — not a
restatement of the claim, not a guess.

Rules:

- **An unevaluable metric is a retro finding, not a shrug.** Phase 1 exists
  specifically to guarantee every metric is mechanically checkable. If the
  stated procedure no longer runs (moved tool, renamed file, changed
  precondition), or turns out not to have been mechanically checkable
  despite that requirement, mark it `UNEVALUABLE` and carry it into
  Section 3 — that guarantee failing to hold is exactly what Section 3
  exists to catch.
- **Three outcomes only, no partial credit.** `PASS`, `FAIL`, or
  `UNEVALUABLE` — never a judgement call.

Record one line per metric, same order as `01-discovery.md`:

```
1. <claim> — check: <procedure> → PASS/FAIL/UNEVALUABLE — <evidence, one line>
```

---

## 3. Retro

On what the **loop** got wrong — this phase's process, not the product's
code. "The auth module has a bug" belongs in the project's issue tracker
(`docs/agents/issue-tracker.md`), not here. "Phase 3's ADR is what Phase 8
had to work around" belongs here.

Work through these four prompts, in order, against this run's actual ledger
(`00-run.md`) and artifacts — not in the abstract:

1. **Redone work.** Which phase produced an artifact a later phase had to
   redo or materially revise (e.g. an architecture decision Phase 8 worked
   around)?
2. **A gate that approved something that later proved wrong.** Did Gate 1,
   2, or 3 pass on an artifact whose flaw only surfaced afterward? Name the
   gate and what it missed.
3. **Where the loop stopped that it shouldn't have.** Any hard stop,
   escalation, or human wait (`00-run.md`'s `## Escalations`) the loop had
   enough information to resolve without escalating.
4. **Where the loop didn't stop that it should have.** Any point a phase
   proceeded past a real ambiguity or risk instead of escalating.

An empty answer to a prompt is valid — "no redone work this run" — but must
be stated, not omitted. Do not force a finding where none exists.

For each actual finding, write one line:
`<prompt category>: <what happened> — <the procedural fix, if one is obvious>`.

---

## 4. Encode learnings

Findings from Section 3 that are **procedural** — a reusable technique, not
a fact specific to this one project — become a new skill in the hub. A
project-specific finding (e.g., "this project's auth library has a quirk")
stays in `10-retro.md`; it does not get a skill.

No procedural finding this run → write `## Encode learnings` as `No
procedural findings this run — nothing to encode.` and skip the rest of this
section.

1. **Locate the hub.** Read the `SKILLS_HUB:` line from `00-bootstrap.md`
   (default `C:\Claude\skills-hub`; use whatever that line actually says —
   do not hardcode past it).

2. **Hub path doesn't exist.** Do not lose the learning: write it into
   `10-retro.md` under a `## For manual transfer` heading, phrased as a
   ready-to-use skill description (problem it addresses, the technique), say
   so plainly in the final report — a documented fallback, not a silent
   skip — and skip the rest of this section.

3. **Hub path exists — idempotency check, before authoring anything.**
   Search every owner directory, not just `vitep/` — a matching skill may
   already live under a different owner:

   ```bash
   find "<SKILLS_HUB>/skills" -mindepth 2 -maxdepth 2 -iname "<skill-name>" -type d
   ```

   - **Already exists.** Do not author a duplicate. Update the existing
     `SKILL.md` if this run's learning adds something it doesn't already
     cover, or skip entirely if it's already covered. Either way, state
     explicitly which happened, in `10-retro.md` and the final report:
     `updated <hub path>` or `skipped — already covers this`.
   - **Does not exist.** Author it fresh, below.

4. **Author via `writing-skills`.** Invoke it normally with the Skill tool —
   it is not on the read-not-invoke list. Follow its RED-GREEN-REFACTOR
   process rather than shortcutting to a skill written from this one example
   untested. Name it per that skill's naming conventions (verb-first/gerund,
   e.g. `checking-deploy-credentials-early`). Place it under
   `skills/vitep/<skill-name>/` — `build-loop`'s own owner directory —
   unless the finding is clearly a variant of an existing third-party skill,
   in which case update that skill instead of forking a new owner.

5. **Merge immediately — the hub's own policy, non-negotiable here.** Its
   `CLAUDE.md` states it directly: *"merge the changes to `main` immediately
   after installing — do not leave the work sitting only on a feature
   branch."* No PR, no feature branch left for later review:

   ```bash
   cd "<SKILLS_HUB>"
   git add "skills/vitep/<skill-name>/"
   git commit -m "feat(skills): add <skill-name>, learned from build-loop run <slug>"
   ```

6. **Record the result** in `10-retro.md`'s `## Encode learnings` section:
   skill name, hub path, and whether it was authored fresh, updated, or
   skipped as a duplicate.

---

## 5. Scope note

This section authors **new** skills distilled from what this run learned —
a build-loop run teaching the hub something it didn't already know. That is
distinct from, and does not conflict with, the design's out-of-scope item
excluding refactoring `build-loop`'s own gap files (its phase instructions,
`reference/skill-map.md`) into skills. This phase never touches
`build-loop`'s own files; it only writes new, unrelated skills elsewhere in
the hub.

---

## 6. Exit

1. Write `docs/build-loop/<date>-<slug>/10-retro.md`:

   ```markdown
   # Phase 10 — Retro

   ## Metric check
   <one line per success metric, PASS/FAIL/UNEVALUABLE with evidence>

   ## Retro
   <one line per actual finding from the four prompts, or "no finding" per prompt>

   ## Encode learnings
   <skill name + hub path + authored/updated/skipped, per finding | "No procedural findings this run — nothing to encode.">

   ## For manual transfer
   <present only when SKILLS_HUB did not exist — one entry per learning, as a ready-to-use skill description>
   ```

2. In `00-run.md`, change phase 10's row from `open` to `done` and name the
   artifact:

   ```
   | 10 | done | 10-retro.md | |
   ```

3. Commit — in the **target project's** repo, not the hub. Section 4's hub
   commit, if any, already happened separately, inside `<SKILLS_HUB>`:

   ```bash
   git add "docs/build-loop/<date>-<slug>/00-run.md" \
           "docs/build-loop/<date>-<slug>/10-retro.md"
   git commit -m "chore(build-loop): phase 10 complete, retro recorded"
   ```

4. **Remove the worktree.** Phase 5 created one and Phase 9's merge does not
   always remove it — a real run finished with the worktree and its branch
   still on disk, holding a stale copy of every run artifact. From the main
   repository root, once the merge is confirmed landed:

   ```bash
   git worktree list                       # confirm which one this run made
   git worktree remove <worktree-path>     # add --force only if it refuses
   git worktree prune
   git branch -d <worktree-branch>         # -d, never -D: it must be merged
   ```

   If `git branch -d` refuses, the branch is **not** merged — stop and report
   that, rather than reaching for `-D`. A refusal here means Phase 9 did not
   finish what it claimed to.

   Skip this step, and say so, if Phase 9's merge step already removed the
   worktree — `git worktree list` showing only the main repository is the
   evidence.

No `gate-check` call closes this phase — there is no Gate 4, and Gate 3
already fired before Phase 9 ran. This is the last commit `build-loop`
makes. Report to the user: the metric check results, the retro findings,
what Section 4 did with each procedural finding — including, explicitly,
anything written under `## For manual transfer` because the hub path wasn't
found — and whether the worktree was removed here or already gone.
