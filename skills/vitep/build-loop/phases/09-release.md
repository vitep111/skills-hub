# Phase 9 — Release

**Everything in this file runs after Gate 3 approval.** Do not open this
file, let alone act on it, until the user has approved the package
`08-integrate.md`'s Gate 3 section presented — that approval is what
authorizes the merge below.

This phase writes `docs/build-loop/<date>-<slug>/09-release.md`: what
merged, the version and changelog, the deploy result (or the Small tier's
tag-only equivalent), migrations, the rollback plan, and the documentation
written. No gate follows it — Gate 3 was the last human approval point in
the loop; Phase 10 (retro) runs next, also unattended.

---

## 1. Enter phase

Same idempotent-open contract as every other phase, guard `9`:

```bash
grep -Eq '^\|[[:space:]]*9[[:space:]]*\|' "docs/build-loop/<date>-<slug>/00-run.md"
```

- **No row.** Append `| 9 | open | | |`.
- **Row `open`.** Resumed pass. Re-do the sections below; Exit flips it.
- **Row `done`.** Phase 9 already ran. Stop, proceed to Phase 10.

`gate-check` never asserts phase 9's row — there is no Gate 4 — but keep
writing it anyway: it's what lets a compaction mid-release resume correctly
instead of re-merging or re-deploying.

---

## 2. Merge

Via `finishing-a-development-branch` — invoke normally with the Skill tool;
it is not on the read-not-invoke list. First action in this phase,
deliberately: Phase 8 stopped short of it so it would happen here, after
Gate 3, not before.

The skill runs its own test verification, then presents its own menu (merge
locally / push and open a PR / keep as-is) and waits. This is a mechanism
choice, not a second Gate 3 — approval to proceed through release already
happened. Default to "merge locally" against the default branch Phase 0
initialized, unless the run already shows a PR-based workflow was chosen.

Record the resulting merge commit sha for Section 9's exit write.

---

## 3. Versioning and changelog

1. **Determine the bump.** Read `04-tickets/*.md` — semver: any ticket
   marked breaking → major; any new capability → minor; fixes/polish only →
   patch. First release ever (`git tag --list 'v*'` empty) starts at
   `v0.1.0` unless the project idea already commits to a public 1.0.
2. **Generate the changelog** from the same ticket files — one bullet per
   ticket, its title plus a one-line summary of what shipped. Prepend a new
   section to `CHANGELOG.md` (create it if absent):

   ```markdown
   ## [X.Y.Z] - <date>
   - <ticket title>: <one-line summary>
   ```

3. **Tag** the merge commit and push the tag if a remote exists:

   ```bash
   git tag vX.Y.Z
   git push origin vX.Y.Z   # only if a remote exists
   ```

---

## 4. Deploy

Execute the target named in `03-architecture.md`'s deploy-target ADR — this
step **reads** that decision, it does not choose one. Find it by heading,
not by number (it isn't always `ADR-01`):

```bash
grep -A5 -i "deploy target" "docs/build-loop/<date>-<slug>/03-architecture.md"
```

- **"No external host"** (Small tier's documented case). No deploy step
  runs — the tag and changelog (Section 3) and docs (Section 7) are the
  shipped artifact; see Section 8.
- **A real target** (PaaS, registry, container host, …). Execute by the
  target's standard mechanism, using whatever credential the ADR's
  Consequences said this step would need.

**Hard stop 3.** Deploy needs credentials or access this session doesn't
have → **stop and ask the user.** Do not improvise a different target and
do not fall back to "no external host" just because a credential is
missing — a missing credential is a blocked release, not a license to
redecide the architecture at ship time.

---

## 5. Migrations

Only when the project has a datastore — check `03-architecture.md`'s
component inventory.

- **No datastore.** Record `## Migrations` as `n/a — no datastore in this
  design.` Small tier never reaches the other branch (no migrations, per
  its adaptation table).
- **Datastore present.** Run the migration tool as part of deploy and
  verify it succeeded before treating the deploy as complete — a deploy
  that "succeeded" against an unmigrated schema is not a success.

---

## 6. Rollback and flags

**A rollback plan is written every run, every tier** — even Small, even
"no external host." What differs is whether it's backed by real
infrastructure:

- **Stated plan (always).** How to undo this release if it's bad. Tagged
  release: "point users back at `<previous tag>`, or `git revert` the merge
  commit." Deployed target: that target's own rollback mechanism, named
  specifically.
- **Feature flags (only where the target supports them).** Note which
  flags this release added, if the target has flag infrastructure. If not,
  record `Flags: none — no flag infrastructure in this deploy target`.

---

## 7. Documentation

A new project starts with none — README, API docs, usage instructions are
**written** here, not merely updated.

- **README** — from `03-spec.md` (problem, solution) and
  `03-architecture.md` (what it is), plus install/usage and a link to
  `CHANGELOG.md`.
- **API docs** — from `03-contracts.md`'s `### Contract:` blocks, one
  section each. Skip if `03-contracts.md` is the "No external contracts"
  line — nothing to document.
- **Usage** — a short "how to run it" section for a CLI/library; folded
  into the README unless the project is large enough for its own doc.

Commit the generated docs into the repository.

---

## 8. Small tier — ship as a tagged release

Under the Small tier, "no external host" (Section 4) does not mean "not
shipped" — shipping *is* Sections 2, 3, and 7: merge, tag, generate docs,
no deploy step. State this explicitly in the exit artifact's `## Deploy`
field rather than leaving it blank, so a reader doesn't mistake "no deploy
ran" for "deploy was skipped by mistake."

---

## 9. Exit

1. Write `docs/build-loop/<date>-<slug>/09-release.md`:

   ```markdown
   # Phase 9 — Release

   ## Merge
   <method used, merge commit sha>

   ## Version
   <vX.Y.Z, bump rationale>

   ## Changelog
   <pointer to the CHANGELOG.md section written, or inlined>

   ## Deploy
   <target executed and result, or "no external host — tagged release only">

   ## Migrations
   <ran, with result | n/a — no datastore>

   ## Rollback and flags
   <stated plan; flag infrastructure used or "none">

   ## Documentation
   <files written: README.md, CHANGELOG.md, API docs if applicable>
   ```

2. In `00-run.md`, change phase 9's row from `open` to `done`:

   ```
   | 9 | done | 09-release.md | |
   ```

3. Commit:

   ```bash
   git add "docs/build-loop/<date>-<slug>/00-run.md" \
           "docs/build-loop/<date>-<slug>/09-release.md" \
           CHANGELOG.md README.md
   git commit -m "chore(build-loop): phase 9 complete, released vX.Y.Z"
   ```

No `gate-check` call closes this phase — there is no Gate 4. Proceed to
Phase 10 (`10-learn.md`) directly.
