---
name: reviewing-embedded-plan-code
description: Use when an implementation plan embeds complete, non-trivial algorithmic code (parsers, state machines, tokenizers, concurrency logic) that you are about to transcribe verbatim during execution, before marking that task complete.
---

# Reviewing Embedded Plan Code

## Overview

A plan document that writes out full implementation code (not pseudocode) is, in effect, an unreviewed commit. Executing it as literal TDD steps — write test, transcribe the plan's code, watch it pass — only proves the code satisfies the tests the plan itself chose to write. It doesn't catch bugs the plan's author didn't think to test for, especially in algorithmically tricky code like parsers or state machines, where a wrong boundary condition can pass every test the same blind spot would have missed — because the same author (often the same agent) wrote both the code and its tests.

## When to use

- The plan (or ticket, or spec) contains complete, runnable code for logic more complex than simple CRUD/wiring — a parser, a state machine, a tokenizer, a concurrency primitive, a non-trivial algorithm.
- You are about to transcribe that code into the actual files, or have just done so and are about to mark the task complete.
- Not needed for boilerplate, scaffolding, or straightforward wiring code where a bug is unlikely to hide behind passing tests.

## Technique

Before treating a task that transcribes plan-embedded algorithmic code as done, run one adversarial pass on it independent of the plan's own tests:

1. Ask "what input would break this code that the plan's own tests don't cover?" — specifically inputs the plan's author might not have imagined when writing the tests alongside the code.
2. For parsers/state machines/tokenizers specifically: check boundary conditions the plan's tests don't exercise — characters/tokens at unusual positions (start of input, mid-token, end of input with no terminator), and interactions between two features that were each tested independently but never together (e.g. a `-` sign both as a binary operator and as the start of a negative number).
3. If you find a break, treat it as a bug found during build, not deferred to a later review phase — fix it immediately with a new failing test, same as any other TDD cycle.
4. If nothing breaks under adversarial pressure, say so explicitly, so a later reviewer doesn't have to wonder whether this pass happened.

Doing this immediately during the build phase, not later at code review, matters because it costs far less to fix a defect before the task is marked done than after — every phase between "marked done" and "caught" carries the bug forward, compounding the cost of fixing it.

## Common mistakes

- Treating "the plan's own tests pass" as proof of correctness — the plan's author and the code's transcriber often share the same blind spots.
- Deferring all correctness scrutiny to a later code-review phase — a dedicated reviewer will eventually catch it, but every phase between "done" and "caught" carries the bug forward.
- Applying this to trivial wiring code where the overhead isn't worth it — reserve the adversarial pass for logic where bugs plausibly hide behind passing tests.

## Evidence

Tested against a tokenizer scenario (not the CSV parser that motivated this skill, to check generalization): a subagent without this skill, given plan-embedded code plus its passing plan-specified tests, explicitly declined to test uncovered inputs ("out of scope for redesign... only worth raising if it blocks Task 3"). The same scenario with this skill loaded produced a proactive adversarial pass — probing exactly the boundary interaction the skill names by example (`-` as binary operator vs. start of a negative number) — and correctly judged the result not to be a bug (a lexer emitting a uniform token for `-` regardless of position is correct; disambiguating unary/binary is a parser-stage concern). Confirms both a behavior change and correct, non-overzealous application of the technique.
