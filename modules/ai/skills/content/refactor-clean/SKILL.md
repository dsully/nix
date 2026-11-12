---
name: refactor-clean
description: >-
  Use when asked to refactor, clean up, or restructure a named file, function,
  or module without changing what it does. Pins current behavior with tests,
  then applies small verified steps (rename, extract, inline, split, remove
  dead code) and reports each change. Not for new features or bug fixes.
---

# Refactor and Clean

Make the named code easier to read and change. Keep its observable behavior
the same: outputs, side effects, errors, public API, and performance class.
For language idioms, use `python-simplifier` or `typescript-simplifier`
together with this skill.

## Rules

- Behavior stays the same. If a change alters behavior, stop and ask. A
  bug you find is a separate change: report it, do not fix it in the refactor.
- Follow the repo's conventions (`CLAUDE.md`, `AGENTS.md`, lint config, the
  code around it). Do not import a style from elsewhere.
- No speculative abstraction. Add an interface, a base class, a factory, or a
  dependency injection layer only when two or more real callers need it now.
  Three similar lines are better than a premature helper.
- Keep the public API. If a rename or move breaks callers, update every caller
  in the same change, or ask first when callers are outside the repo.
- Stay in scope. List other problems you find in the report. Do not fix them.
- Delete code that becomes dead. Do not leave commented-out code, adapters, or
  "old" names behind unless the user asks for a migration period.

## Workflow

### 1. Fix the scope and the baseline

1. Identify the target from the request. If none is named, ask.
2. Find every caller of the target (`rg`, the language server, or the code
   graph tool).
3. Run the tests that cover the target, plus the lint and type checks. Record
   the result. When the baseline already fails, stop and report the failures.

### 2. Pin the behavior

When the tests do not cover the paths you will change, write
characterization tests first. Assert on what the code does now, including
odd cases, not on what it should do. Run them against the old code; they
must pass. Test behavior and invariants, not line positions or exact copy.

### 3. Find the smells

Read the target. Look for these, in this order:

1. Dead code: unused functions, parameters, branches, imports, flags.
2. Unclear names: a name that hides what the value is or does.
3. Long or deeply nested functions: use guard clauses and extract functions
   with names that state intent.
4. Duplication: the same rule in more than one place. Merge only when the
   copies must change together.
5. Mixed responsibilities: a function or module that does I/O and logic
   together, or serves unrelated callers. Split along the seam the callers
   already use.
6. Magic values: a literal whose meaning is not clear from context. Give it a
   name.
7. Comments that restate code or narrate history: delete them, or replace
   them with a better name.

Use measured signals where the tools exist (`ruff check --select C901`,
`radon cc`, `lizard`, `jscpd`). Do not apply generic size limits that the
repo does not use.

### 4. Change in small steps

For each step:

1. Make one refactoring (one rename, one extract, one move).
2. Run the tests from step 1 and step 2, plus the formatter and lint.
3. When they fail, undo the step or fix it before the next step.

Prefer mechanical tools (language-server rename, `ast-grep`, `ruff --fix`)
over hand edits for wide renames.

### 5. Verify

1. Run the full set of covering tests, lint, and type checks again.
2. Compare to the baseline from step 1. The result must be the same or better.
3. Read the full diff once. Check that no behavior change slipped in.

## Report format

```markdown
## Changes

1. <file:line> <what changed>: <why it is easier to read or change>.

## Verification

- <command>: <result before> → <result after>.

## Not changed

- <file:line> <problem found outside scope or a possible bug>.
```

Keep the report short. The diff shows the code; the report gives the reasons.
