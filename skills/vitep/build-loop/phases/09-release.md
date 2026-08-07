# Phase 9 — Release

**Everything in this file runs after Gate 3 approval.** Do not open this
file, let alone act on it, until the user has approved the Gate 3 package —
branch summary, review verdict, CI conclusion, triaged minors, release
plan — presented from the run directory's `08-integrate.md` **artifact**
(written by `phases/08-integrate.md`, a different file from both this one
and from that artifact). That approval is what authorizes the merge below.

Same naming pattern applies to this file: *this file* is
`phases/09-release.md`, the instructions you are reading; the artifact it
writes is *also* named `09-release.md`, in the run directory. Below, "this
file" means the instructions; "the artifact" means the thing you write.

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
- **Row `open`.** Resumed pass. **Do not blindly redo Sections 2–4** —
  unlike this pattern's use elsewhere, they're not document writes: merge,
  tag, and deploy are irreversible operations with external side effects.
  Section 2 (Merge), Section 3 (Tag), and Section 4 (Deploy) each open with
  their own check for whether their effect already happened, and skip if
  so. Sections 5–7 (migrations, rollback/flags, docs) have no such hazard —
  redo them as written. Where a side-effecting step's prior state can't be
  determined from the environment, that step is a hard stop: report what's
  unknown and ask, rather than guess — a wrong guess here is a duplicate
  tag or a second deploy, not a rewritten paragraph.
- **Row `done`.** Phase 9 already ran. Stop, proceed to Phase 10.

`gate-check` never asserts phase 9's row — there is no Gate 4 — but keep
writing it anyway: it's what lets a compaction mid-release resume correctly
instead of re-merging or re-deploying.

**Why this phase diverges from the row-resume pattern.** `01-discover.md`,
`03-specify.md`, and `08-integrate.md` all say "redo the sections from
scratch" on a resumed `open` row, and that's safe there because every one
of their sections only writes a local document — redoing a document write
is a no-op past the first correct pass. Phase 9 is the first phase whose
sections have external, irreversible effects; "redo from scratch" applied
here would double-tag or re-deploy. The three-branch **row** guard above is
unchanged and still correct — only what "redo" means for Sections 2–4
differs, and each of those sections states its own check rather than this
one restating three different mechanisms up front.

---

## 2. Merge

**Idempotency check, first — always, not just on a resumed pass:**

```bash
git merge-base --is-ancestor <worktree-branch> <default-branch> && echo "already merged"
```

Already merged → skip invoking `finishing-a-development-branch` again;
record the merge commit instead of creating a new one (the merge on
`<default-branch>` that first contains the worktree branch tip:
`git log <default-branch> --merges --ancestry-path <worktree-branch>..<default-branch> -1 --format=%H`)
and continue to Section 3. Not merged → proceed below.

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
   `v0.1.0` unless the project idea already commits to a public 1.0. This
   step has no side effects — safe to recompute every pass, resumed or not.
2. **Idempotency check, before writing anything:**

   ```bash
   git rev-parse -q --verify "refs/tags/vX.Y.Z" >/dev/null && echo "already tagged"
   ```

   Already tagged → this version already shipped in a prior pass; skip
   Steps 3 and 4 below entirely and continue to Section 4 with the
   existing `vX.Y.Z`. Not tagged → continue.
3. **Generate the changelog** from the same ticket files — one bullet per
   ticket, its title plus a one-line summary of what shipped. Prepend a new
   section to `CHANGELOG.md` (create it if absent):

   ```markdown
   ## [X.Y.Z] - <date>
   - <ticket title>: <one-line summary>
   ```

4. **Tag** the merge commit and push the tag if a remote exists:

   ```bash
   git tag vX.Y.Z
   git push origin vX.Y.Z   # only if a remote exists
   ```

---

## 4. Deploy

Execute the target named in `03-architecture.md`'s deploy-target ADR — this
step **reads** that decision, it does not choose one. `03-architecture.md`
is small enough to read in one call — do that, and locate the ADR whose
**Decision** names the deploy target. Don't try to grep it out with a fixed
line count: the heading isn't required to contain the words "deploy
target" verbatim, and the Decision line can sit well below the heading (the
worked example in `03-specify.md` puts it over 20 lines down) — a
`grep -A` with a small context window can miss it, or match nothing. Quote
the Decision verbatim into the release-plan record (Section 9's exit
write).

**No such ADR found → hard stop.** Phase 3 was required to write exactly
one ADR deciding the deploy target, never skipped, at any tier. Its absence
is a defect carried forward from an earlier phase, not something to paper
over here — stop and report it to the user rather than choosing a target.

Once the Decision is found:

- **"No external host"** (Small tier's documented case). No deploy step
  runs — the tag and changelog (Section 3) and docs (Section 7) are the
  shipped artifact; see Section 8.
- **A real target** (PaaS, registry, container host, …). Before executing,
  check whether `vX.Y.Z` is already live there — a package registry's
  "view this version" command, a container registry's tag listing, the
  target's own deployed-version API or dashboard. Confirmed already
  deployed → skip, record that fact, move to Section 5. No reliable way to
  check, or the check is inconclusive → **hard stop**, distinct from Hard
  stop 3 below: report the version and target, state plainly that whether
  it's already deployed is unknown, and ask before proceeding. Otherwise,
  execute by the target's standard mechanism, using whatever credential the
  ADR's Consequences said this step would need.

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

Not a separate mechanical path — Section 4's "no external host" branch is
this. The one thing not to skip: write the exit artifact's `## Deploy`
field as "no external host — tagged release only" rather than leaving it
blank, so a reader doesn't mistake "no deploy ran" for "deploy was skipped
by mistake."

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
