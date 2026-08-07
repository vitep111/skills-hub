# Phase 0 — Bootstrap

Run this once, at the very start of a `build-loop` invocation, in the target
project's root directory. It assumes: a greenfield (empty or near-empty)
directory, and a project idea already stated by the user earlier in this
conversation. Everything downstream — `using-git-worktrees`, the
`mattpocock` skills, `gate-check` itself — assumes the conditions this phase
creates. Do the seven sections below in order; each later section depends on
state the earlier ones create.

Work in a POSIX shell (Git Bash on Windows) — `scripts/gate-check` is bash
and every command below is written for it.

---

## 1. Install-set check

Verify the flat, global install set is present before touching anything
else. Greenfield means the target directory starts empty, so `build-loop`
and every skill it drives must already live in the global skills directory,
not this hub.

Verbatim from the design spec's *Location and install set*:

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

**Flat, not nested.** SDD dispatches its final reviewer via a relative
sibling path, `../requesting-code-review/code-reviewer.md`, which resolves
only if the two directories are siblings under `~/.claude/skills/`. The
hub's `skills/<owner>/<name>/` nesting does not survive into the install —
owner directories are dropped.

Run:

```bash
for name in build-loop brainstorming grill-me to-spec writing-plans to-tickets wayfinder \
            subagent-driven-development implement dispatching-parallel-agents \
            test-driven-development systematic-debugging verification-before-completion \
            requesting-code-review receiving-code-review finishing-a-development-branch \
            using-git-worktrees writing-skills handoff code-review pick-ui-library; do
  test -f ~/.claude/skills/"$name"/SKILL.md || echo "MISSING: $name"
done
```

If nothing printed, every skill is present — continue to Section 2.

**Hard stop 1 — missing skill.** The first `MISSING:` line halts the run.
Do not continue, do not substitute another skill, do not degrade silently.
Report to the user, for **every** missing name printed above:

- the missing skill's name
- its hub path, so it can be copied in: `skills/<owner>/<name>/`

| Skill | Hub path |
|---|---|
| build-loop | skills/vitep/build-loop/ |
| brainstorming | skills/obra/brainstorming/ |
| grill-me | skills/mattpocock/grill-me/ |
| to-spec | skills/mattpocock/to-spec/ |
| writing-plans | skills/obra/writing-plans/ |
| to-tickets | skills/mattpocock/to-tickets/ |
| wayfinder | skills/mattpocock/wayfinder/ |
| subagent-driven-development | skills/obra/subagent-driven-development/ |
| implement | skills/mattpocock/implement/ |
| dispatching-parallel-agents | skills/obra/dispatching-parallel-agents/ |
| test-driven-development | skills/obra/test-driven-development/ |
| systematic-debugging | skills/obra/systematic-debugging/ |
| verification-before-completion | skills/obra/verification-before-completion/ |
| requesting-code-review | skills/obra/requesting-code-review/ |
| receiving-code-review | skills/obra/receiving-code-review/ |
| finishing-a-development-branch | skills/obra/finishing-a-development-branch/ |
| using-git-worktrees | skills/obra/using-git-worktrees/ |
| writing-skills | skills/obra/writing-skills/ |
| handoff | skills/mattpocock/handoff/ |
| code-review | skills/mattpocock/code-review/ |
| pick-ui-library | skills/emilkowalski/pick-ui-library/ |

The hub itself lives at `SKILLS_HUB` (default `C:\Claude\skills-hub`; see
Section 5 — at Phase 0 this hard stop can fire before Section 5 runs, so
assume the default unless the user has already told you otherwise). Copy
each missing skill from `<SKILLS_HUB>/<hub path>` to
`~/.claude/skills/<name>/`, **flattening** — do not carry the owner
directory into the global install. Then stop this run entirely and ask the
user to re-invoke `build-loop` once the copy is done. Do not proceed within
this session on an incomplete install set.

**Read, not invoke.** Seven of the 21 skills above
(`grill-me`, `handoff`, `implement`, `to-spec`, `to-tickets`, `wayfinder`,
`pick-ui-library`) carry `disable-model-invocation: true` — no skill,
including `build-loop`, may invoke them via the Skill tool. Wherever a later
phase drives one of them, it reads that skill's `SKILL.md` with the Read
tool and follows its procedure directly. Phase 0 only verifies these are
installed; it does not drive any of them, so this note is forward-looking,
not an instruction for this phase.

---

## 2. Repository bootstrap

1. **Init if absent.**

   ```bash
   git rev-parse --is-inside-work-tree >/dev/null 2>&1 || git init
   ```

2. **Write `.gitignore`.** Start from the baseline below, always. Then scan
   the user's stated project idea for a stack signal and append the matching
   block(s). If no stack is evident yet, write the baseline only — Phase 3
   (architecture) is where the stack actually gets locked, and this file can
   gain stack-specific entries then. Skip this step if `.gitignore` already
   exists (resumed run) and has content.

   <gitignore-baseline>

   ```gitignore
   # OS
   .DS_Store
   Thumbs.db
   Desktop.ini

   # Editors
   .vscode/
   .idea/
   *.swp

   # Secrets
   .env
   .env.*
   !.env.example
   ```

   </gitignore-baseline>

   Stack blocks — append the one(s) matching the idea's stated language/framework:

   <gitignore-node>

   ```gitignore
   # Node
   node_modules/
   dist/
   build/
   .next/
   out/
   coverage/
   *.log
   ```

   </gitignore-node>

   <gitignore-python>

   ```gitignore
   # Python
   __pycache__/
   *.py[cod]
   .venv/
   venv/
   *.egg-info/
   .pytest_cache/
   .mypy_cache/
   ```

   </gitignore-python>

   <gitignore-go>

   ```gitignore
   # Go
   /bin/
   *.exe
   *.test
   ```

   </gitignore-go>

   <gitignore-rust>

   ```gitignore
   # Rust
   /target/
   ```

   </gitignore-rust>

   (Rust: `Cargo.lock` is committed for applications and ignored for
   libraries — decide per the idea, don't blanket-ignore it.)

3. **Initial commit.** Required even if `.gitignore` is the only file — this
   is the commit `using-git-worktrees` branches from at Phase 5. Without it,
   Phase 5 cannot start.

   ```bash
   git add .gitignore
   git commit -m "chore: initial commit"
   ```

   Skip if `git log -1` already succeeds (resumed run with an existing
   commit).

4. **Remote — do not create one by default.** The deploy target is a Phase 3
   ADR decision that does not exist yet at Phase 0. Create a remote now
   **only if the user's original request already named a specific host**
   (e.g. "push this to github.com/me/thing", "make a GitHub repo called
   X"). If so, create it with the appropriate CLI (e.g. `gh repo create
   <name> --private --source=. --remote=origin`) and record the host in
   `00-bootstrap.md` (Section 4 below).

   Otherwise, create no remote here. Remote creation is explicitly
   **deferred to Phase 8** (`08-integrate.md`, which needs a remote to run
   CI) — not Phase 0. Note this explicitly in `00-bootstrap.md`.

---

## 3. Tracker config

The `mattpocock` skills (`to-spec`, `to-tickets`, `code-review`, `wayfinder`)
expect `docs/agents/issue-tracker.md` and, absent it, point the user at
`/setup-matt-pocock-skills` — a command this hub does not have. Phase 0
writes that file itself, configured for the **local-markdown tracker**,
which `wayfinder` already names as its own documented fallback.

Skip this step if the file already exists (resumed run). Otherwise create
`docs/agents/` and write this exact content to `docs/agents/issue-tracker.md`:

<issue-tracker-file>

```markdown
# Issue tracker

**Tracker:** local-markdown (no external tracker configured for this repo)

## Storage

Issues live under `.scratch/<feature-slug>/issues/`, one file per issue,
named `<NN>-<slug>.md`, numbered from `01` within each feature slug
directory, in dependency order (blockers first). An issue's identity is its
file path; cite it in commit messages as `<feature-slug>/<NN>-<slug>` (e.g.
`Closes user-auth/03-login-form`).

## Label vocabulary

- `ready-for-agent` — applied by `to-spec` and `to-tickets` to specs/tickets
  ready to be worked; no further triage needed.
- `wayfinder:map` — the map issue for a wayfinder effort.
- `wayfinder:research`, `wayfinder:prototype`, `wayfinder:grilling`,
  `wayfinder:task` — wayfinder ticket types.

Local-markdown has no native label field. Record labels as a `**Labels:**`
line near the top of the issue file's body.

## Fetch (reading an existing issue)

Given a reference like `#12`, a bare issue number, or a
`<feature-slug>/<NN>-<slug>` path:

1. If given a bare number or `#N`, search `.scratch/*/issues/` for a file
   whose `<NN>` prefix matches. If more than one feature slug has that
   number, ask which.
2. Read the file directly. Its full body, including any inline
   `## Resolution` section, is the whole record — local-markdown has no
   separate comment stream to also check.

`code-review` resolves commit-message issue references (`#123`,
`Closes #45`) the same way, when identifying its spec source.

## Publish (writing a new issue/spec)

- **Spec** (`to-spec`) → `.scratch/<feature-slug>/spec.md`. Add a
  `**Labels:** ready-for-agent` line under the title.
- **Tickets** (`to-tickets`) → one file per ticket under
  `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, using that skill's own
  per-ticket template — this doc does not restate it.

## Blocking and dependencies

No native blocking relationship. Each issue file states its own dependency
in a `**Blocked by:**` line (ticket numbers/titles, or "None — can start
immediately"). An issue is unblocked when every issue it names as a blocker
has `**Status:** done` or `**Status:** closed`.

## Wayfinding operations

(`wayfinder` already falls back to local-markdown on its own when no
tracker doc names one — this section exists for completeness, not
necessity.)

- **Map** → `.scratch/<slug>/wayfinder-map.md`, holding the map body
  `wayfinder` defines (Destination / Notes / Decisions so far / Not yet
  specified / Out of scope).
- **Child tickets** → `.scratch/<slug>/wayfinder-tickets/<NN>-<slug>.md`,
  one file per ticket, each carrying its `wayfinder:<type>` label from the
  vocabulary above.
- **Claim** → a `**Claimed by:**` line in the ticket file, in place of
  tracker-native assignment.
- **Blocking / frontier** → a `**Blocked by:**` line, as above; the
  frontier is computed by scanning child ticket files for open + unblocked
  + unclaimed.
- **Resolution** → append a `## Resolution` section to the ticket file, set
  `**Status:** closed`, and append the context pointer to the map's
  Decisions-so-far section by hand — local-markdown has no query to do this
  automatically.
```

</issue-tracker-file>

---

## 4. Run directory

Every `build-loop` run gets one directory in the target project, created on
the default branch.

1. **Date and slug.**
   - `<date>` = today's date, `YYYY-MM-DD` (`date +%F` in bash).
   - `<slug>` = kebab-case, derived from the user's project idea: lowercase,
     3–6 significant words, punctuation and stopwords stripped, hyphen-joined
     (e.g. "a CLI that converts markdown to slides" → `markdown-to-slides-cli`).

2. **Create the directory.**

   ```bash
   mkdir -p "docs/build-loop/<date>-<slug>"
   ```

   Skip if it already exists for today's date and this slug (resumed run) —
   read the existing `00-run.md` instead of overwriting it, and resume from
   Section 5 of this file using its recorded state.

3. **Write `00-run.md`.** This is the ledger `gate-check` parses; its format
   is fixed, not prose. `tier` cannot be filled yet — Gate 0 (Section 6)
   hasn't run — so write the literal placeholder `pending`, to be overwritten
   in Section 6. This is the one phase where the row is written at the same
   moment the ledger file itself is created, rather than strictly "on
   entering the phase" — Phase 0 IS what creates the ledger, so the two
   collapse into one step here. Every phase after this one writes its `open`
   row into an already-existing ledger, ahead of doing any of that phase's
   work.

   Write exactly this shape to `docs/build-loop/<date>-<slug>/00-run.md`,
   filling `<slug>`, `<one line>`, and `<date>`:

   ```markdown
   # Run: <slug>
   idea: <one line>   date: <YYYY-MM-DD>   tier: pending

   ## Phases
   | phase | status | artifact | reason |
   |-------|--------|----------|--------|
   | 0 | open | | |

   ## Deferred minors

   ## Gate log

   ## Decision log

   ## Escalations
   ```

4. **Write `00-bootstrap.md`** — the artifact for this phase, and the file
   Phase 10 reads for `SKILLS_HUB`. Create it now with what Sections 1–3
   already determined; Sections 5 and 6 below append to it. Write this
   template to `docs/build-loop/<date>-<slug>/00-bootstrap.md`, filling in
   the bracketed parts:

   ```markdown
   # Phase 0 — Bootstrap

   SKILLS_HUB: [pending — Section 5]
   tier: [pending — Section 6]

   ## Install-set check
   All 21 skills present in ~/.claude/skills/.

   ## Repository
   - git: [initialized fresh | already present]
   - .gitignore: [baseline only | baseline + <stack> block(s)] written
   - Initial commit: [<sha>]
   - Remote: [none created — no host named in the original request;
     deferred to Phase 8 | created at <url>, host named in the original request]

   ## Tracker
   docs/agents/issue-tracker.md written, configured for the local-markdown
   tracker.

   ## Scale assessment
   [pending — Section 6]
   ```

5. **Commit.**

   ```bash
   git add docs/agents/issue-tracker.md "docs/build-loop/<date>-<slug>/"
   git commit -m "chore(build-loop): open run <slug>, phase 0"
   ```

---

## 5. Record `SKILLS_HUB`

`build-loop` runs inside the target project; the hub is a separate
repository, so it has to be located by path. Default:

```
C:\Claude\skills-hub
```

Use a different path only if the user has already told you the hub lives
elsewhere, or a `SKILLS_HUB` environment variable is set in this session —
otherwise use the default. Do not guess or search for it.

Update `00-bootstrap.md`'s `SKILLS_HUB:` line (written as `[pending —
Section 5]` in Section 4) with the resolved path, e.g.:

```
SKILLS_HUB: C:\Claude\skills-hub
```

Phase 10 (`10-learn.md`) reads this line to know where to merge new
procedural learnings as hub skills. If the path doesn't exist at Phase 10,
that phase writes the learning to `10-retro.md` and flags it for manual
transfer instead — nothing is lost, but that fallback is Phase 10's problem,
not this one's. Do not verify the path exists here; just record it.

---

## 6. Scale assessment and Gate 0

**Confirm the tier now, before any tier effect takes hold — not at Gate 1.**
The Small tier compresses Phases 1–2 into a single pass; if confirmation
waited until Gate 1 (which fires *after* Phase 2), the compression would
already have happened by the time the user saw the question. Confirming
here is what makes the choice real rather than retroactive.

Verbatim from the design spec's *Scale adaptation*:

| Tier | Trigger | Adaptation |
|---|---|---|
| **Small** | one component, no persistence, no external deploy target | Phases 1–2 compress to a single pass; no `wayfinder`; single ticket; direct execution; no migrations. **All three gates still fire**, with reduced content |
| **Standard** | anything else | the full loop, subagent-driven execution |
| **Large** | multiple independent subsystems | `wayfinder` first, then decompose; see below |

Two clarifications that matter for correct behavior, also from the spec:

- **Small tier still ships.** "No deploy target" means no external host, not
  no release — for Small, shipping means a tagged release with generated
  docs, and the deploy-target ADR records that choice explicitly rather than
  being skipped.
- **Large tier recursion.** `wayfinder` maps the whole project first, then
  sub-projects run one at a time. Each sub-project gets its own
  `docs/build-loop/<date>-<slug>/` directory and its own Gates 1 and 2.
  Gate 0 fires once, for the whole. Gate 3 fires once, at the end, on the
  integrated result. (`wayfinder` carries `disable-model-invocation: true` —
  a later phase reads its `SKILL.md` and follows it; it is never invoked via
  the Skill tool.)

**Assess and propose:**

1. Match the user's stated project idea against the three triggers above.
2. Propose one tier. Present to the user:
   - the proposed tier and which trigger it matched
   - the exact Adaptation cell for that tier, so they see what changes
     concretely, not just the tier's name
3. Ask for confirmation before proceeding to Section 7. Do not proceed on
   an assumed or default answer — this is Gate 0, a real human stop, even
   though it's a confirmation rather than a review.

**Once confirmed:**

- Update `00-run.md`'s top line, replacing `tier: pending` with the
  confirmed value (`tier: small`, `tier: standard`, or `tier: large`).
- Append one line to `00-run.md`'s `## Gate log`:
  `- Gate 0 (Scale): approved — tier=<value>`
- Append one line to `00-run.md`'s `## Decision log`:
  `- Phase 0: tier=<value> — matched trigger "<trigger text>"`
- Replace `00-bootstrap.md`'s `tier: [pending — Section 6]` line with
  `tier: <value>`, and its `## Scale assessment` section with:

  ```markdown
  ## Scale assessment
  Trigger matched: <trigger text>
  Adaptations in effect: <adaptation text for the confirmed tier>
  Confirmed by user at Gate 0: yes
  ```

These two logs (Gate log, Decision log) are being used here for the first
time in the run — keep using this same one-line-per-entry format in later
phases so the ledger stays scannable after a compaction.

---

## 7. Exit

1. In `00-run.md`, change phase 0's row from `open` to `done` and name the
   artifact:

   ```
   | 0 | done | 00-bootstrap.md | |
   ```

2. Run the gate check:

   ```bash
   ~/.claude/skills/build-loop/scripts/gate-check "docs/build-loop/<date>-<slug>" 0
   ```

   If it reports "Permission denied" (the execute bit can be lost on copy
   into the global install), run it explicitly instead:

   ```bash
   bash ~/.claude/skills/build-loop/scripts/gate-check "docs/build-loop/<date>-<slug>" 0
   ```

   - **Exit 0:** gate passes. Proceed to Phase 1 (`01-discover.md`) — opening
     phase 1's row with `status: open` is that phase's first action, not
     this file's.
   - **Exit 1:** the reason is on stderr. Fix the specific gap it names
     (e.g. `00-bootstrap.md` missing or empty — re-check Section 4 ran to
     completion), then re-run `gate-check`. Do not proceed to Phase 1 until
     it exits 0.

3. Commit the exit state:

   ```bash
   git add "docs/build-loop/<date>-<slug>/00-run.md" "docs/build-loop/<date>-<slug>/00-bootstrap.md"
   git commit -m "chore(build-loop): phase 0 complete, gate 0 passed"
   ```
