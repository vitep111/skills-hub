# Phase 1 — Discover

Run this after Gate 0 passes. It produces `01-discovery.md`: prior art,
success metrics, and (when warranted) a feasibility spike. The idea itself
and user intent were already captured earlier in the conversation and in
`00-bootstrap.md` — this phase does not re-elicit them. It fills the three
gaps Phase 1 owns and nothing else does: research, measurable success
criteria, and de-risking a make-or-break unknown.

---

## 1. Enter phase

First action, before any research starts. Phase 1 owns opening its own
ledger row, and this file can be re-entered after a crash or a context
compaction — both expected, not exceptional — so the open must be
idempotent. Never append blindly.

1. **Check for an existing phase 1 row** in
   `docs/build-loop/<date>-<slug>/00-run.md`'s `## Phases` table:

   ```bash
   grep -Eq '^\|[[:space:]]*1[[:space:]]*\|' "docs/build-loop/<date>-<slug>/00-run.md"
   ```

2. **No row found.** First pass. Append it:

   ```
   | 1 | open | | |
   ```

3. **Row found, status `open`.** A resumed pass — the prior attempt was
   interrupted after the row was opened but before Exit (Section 6). Do not
   append a second row. Re-do Sections 2–4's work from scratch and let Exit
   flip this same row to `done`.

4. **Row found, status `done`.** Phase 1 already completed in a prior pass.
   Do not redo it. Stop here and proceed to Phase 2.

Once past this check, read the confirmed tier from
`docs/build-loop/<date>-<slug>/00-bootstrap.md`'s `tier:` line. It governs
Section 5 below — read it now so the rest of this phase runs at the right
size the first time, not as a rewrite.

---

## 2. Prior art

Search for existing solutions to the same problem the idea solves —
products, libraries, OSS projects, blog writeups of prior attempts. Use
whatever search tool is available in this session.

Record 3–5 entries (Standard/Large tier; Small tier is 1–2, see Section 5),
each as one row:

| Name | What it does | Takeaway | Source |
|---|---|---|---|
| \<name\> | \<one sentence\> | Steal: \<what to copy\> *or* Avoid: \<what to not repeat\> | \<url\> |

Rules:

- **One takeaway per entry, and it must commit to a side.** Not "interesting
  approach" — either `Steal: <specific mechanism>` or `Avoid: <specific
  failure mode>`.
- **A source link is required per entry.** No link, no entry.
- **"No prior art exists" is not a valid entry on its own.** If a genuine
  search turns up nothing directly comparable, record the search instead of
  the table: the queries run, the sources checked, and one line on why the
  space is plausibly empty (e.g. a narrow internal tool). An unrecorded
  absence is indistinguishable from a search that was never done — treat it
  as not done.

---

## 3. Success metrics

2–4 criteria. Every one must be answerable **pass or fail, by running
something or reading something — no human judgement call.** This is a hard
requirement, not a style preference: **Phase 10 (`10-learn.md`) reads this
section verbatim** and checks the shipped result against each line. A metric
it cannot evaluate mechanically is a metric it will record as unevaluable,
not one it will guess at generously.

A metric is well-formed when it names, in one line: what gets measured, the
exact procedure or command that measures it, and the pass/fail threshold.

- Bad: "the CLI should be fast"
  Good: "converts a 10MB CSV in under 2 seconds on the dev machine"
- Bad: "good error messages"
  Good: "every non-zero exit prints the offending input line number"

Write the section under the exact heading `## Success metrics`, one metric
per numbered line, in this shape:

```
1. <claim> — check: <exact procedure that yields pass/fail>
2. <claim> — check: <exact procedure that yields pass/fail>
```

Small tier does not shrink this section — see Section 5.

---

## 4. Feasibility spike

Default is **no spike.** Run one only when a specific technical unknown, if
it turns out wrong, invalidates the *whole chosen approach* — not merely
makes it slower or uglier. Examples of the right size of unknown: "does this
library actually parse the target format at all," "can this API's rate
limit sustain the required throughput," "does the target platform permit
the background execution the design needs." Examples of the wrong size:
picking between two similar libraries, or tuning a config value — those are
Phase 3 decisions, not spikes.

If no such unknown exists, skip and record why in one line — do not run a
spike for the sake of having one.

If one exists:

1. **State the question** the spike answers, in one sentence.
2. **Set a timebox before starting** (e.g. 30 minutes) and stop at it
   regardless of outcome — an inconclusive result at the timebox is still a
   result.
3. **Throwaway code only.** Write it in the scratchpad or a temp location
   outside the project tree — not this repo's `.scratch/` directory, which
   `00-bootstrap.md` reserves for issue-tracker files — never committed,
   never left in the working directory. Delete it once the result is
   recorded.
4. **Record the result in `01-discovery.md`**, not as surviving code: the
   question, the timebox used, what was tried, the result, and the decision
   it drives (proceed as planned / change approach to X / escalate to the
   user).

---

## 5. Small-tier compression

Applies only when Section 1 read `tier: small` from `00-bootstrap.md`.
Standard and Large tiers run Sections 2–4 as written above.

Under Small:

- **Prior art** shrinks to 1–2 entries instead of 3–5. Same per-entry rules
  (source link, committed Steal/Avoid takeaway) still apply.
- **The spike is skipped outright**, regardless of whether an invalidating
  unknown exists. Record `## Feasibility spike` as `Skipped — Small tier.`
- **Success metrics are never skipped, at any tier.** Phase 10 needs them to
  check the shipped result whether this run was Small, Standard, or Large.
  Do not compress this section.

---

## 6. Exit

1. Write `docs/build-loop/<date>-<slug>/01-discovery.md`:

   ```markdown
   # Phase 1 — Discovery

   tier: <value>

   ## Prior art
   <table from Section 2, or the recorded-search fallback>

   ## Success metrics
   <numbered list from Section 3, exact heading, unchanged at every tier>

   ## Feasibility spike
   <spike record from Section 4, or the one-line "not needed" / "Skipped — Small tier" note>
   ```

2. In `00-run.md`, change phase 1's row from `open` to `done` and name the
   artifact:

   ```
   | 1 | done | 01-discovery.md | |
   ```

3. Commit:

   ```bash
   git add "docs/build-loop/<date>-<slug>/00-run.md" "docs/build-loop/<date>-<slug>/01-discovery.md"
   git commit -m "chore(build-loop): phase 1 complete, discovery recorded"
   ```

Gate 1 does not fire here — `scripts/gate-check <run-dir> 1` requires phase 2
done as well, and phase 2 is out of this file's scope. Proceed to whatever
drives phase 2 next; do not run `gate-check` from this file.
