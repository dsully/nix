---
name: comment-analyzer
description: >-
  Use when asked to check code comments or docstrings for accuracy, value, or
  rot: after writing documentation, before a PR that adds or changes comments,
  or when auditing a scoped set of files. Checks each comment against the code
  and reports wrong, missing, and removable comments. It does not edit code.
---

# Comment Analyzer

Check that every comment in scope is true now and earns its place. Report
findings with fixes. Do not edit files unless the user asks after the report.

## Scope

Use the files, symbols, or diff the user named. If none, use the comments
that the current branch adds or changes: `git diff main...HEAD` plus the
uncommitted diff. Check only comments and docstrings in that scope.

## What a comment must be

A comment stays only if all three hold:

1. Names, types, and structure do not already make it clear.
2. Without it, a reader could make a wrong change.
3. It describes the code as it is now, not how it got there.

Good reasons for a comment: why a non-obvious approach beat the obvious one;
a constraint from outside the file (API quirk, spec clause, upstream bug),
with a link; an invariant or edge case a reader would break; a
`TODO(owner): <action>` that points at a tracked issue.

Repo rules in `CLAUDE.md` or `AGENTS.md` override this list.

## Checks

For each comment, read the code it describes, then check:

- Accuracy: parameters, return values, raised errors, and types match the
  signature and body. Named functions, types, flags, and files exist.
  Described edge cases are handled. Complexity or performance claims hold.
- Staleness: the comment refers to code that moved, was renamed, or was
  removed. A `TODO`/`FIXME` describes work that is already done. An example
  no longer runs.
- Value: the comment fails the three conditions above. Use the list in the
  remove-ai-slop skill, section "Code comments and docstrings", for the
  patterns (narration, change history, banners, signature restating
  docstrings). Commented-out code is always a removal.
- Gaps: a non-obvious side effect, precondition, error case, or external
  constraint has no comment, and a reader would get it wrong. Report a gap
  only when a better name or type cannot remove the need.
- Clarity: the wording has two readings, or it needs a paragraph where one
  line would do.

Prefer a code fix over a comment fix: when a rename, an extracted function,
or a type makes the comment unnecessary, suggest that.

## Report format

```markdown
## Summary

<scope checked, number of comments, top problem.>

## Wrong

- file:line: <what the comment says> vs <what the code does>. Fix: <new text or delete>.

## Remove

- file:line: <why it adds nothing>. Fix: delete, or <rename/extract>.

## Improve

- file:line: <what is missing or unclear>. Fix: <new text>.

## Missing

- file:line: <the hazard a reader would miss>. Fix: <one-line comment>.
```

Leave out an empty section. Put "Wrong" first, because a false comment is
worse than no comment.
