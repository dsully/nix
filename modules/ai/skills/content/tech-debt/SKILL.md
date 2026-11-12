---
name: tech-debt
description: >-
  Use when asked to find, inventory, score, or prioritize technical debt in a
  repository or a scoped path, or to produce a debt remediation plan. Gathers
  evidence with real tools, scores each item by impact, risk, churn and effort,
  and reports a ranked plan. It does not change code unless asked.
---

# Technical Debt Analysis

Find the debt that slows changes or causes bugs, prove each item with
evidence, and rank the fixes. The report is the deliverable. Do not edit code
unless the user asks for a fix after the report.

## Rules

- Every item needs evidence: a `file:line`, a command output, or a git
  statistic. No evidence, no item.
- Never invent numbers. No dollar costs, no hourly rates, no projected
  savings, no coverage figures that were not measured. When a metric was not
  measured, say so in the "Not measured" section.
- Run only tools that are installed (`command -v <tool>`). Do not install
  tools without asking. Prefer the repo's own lint, test, and audit commands
  (`Justfile`, `Makefile`, `package.json` scripts, `pyproject.toml`).
- Judge code against the repo's own conventions (`CLAUDE.md`, `AGENTS.md`,
  lint config), not against generic thresholds.
- Generated, vendored, and lock files are not debt. Skip them.

## Workflow

### 1. Fix the scope

Use the paths or area the user named. If none, use the repository root.
Read `CLAUDE.md`/`AGENTS.md`/`README.md` and the build files to learn the
languages, entry points, and the existing quality commands.

### 2. Find the hotspots

Debt matters most where the code changes often. Rank files by churn first:

```bash
git log --since=12.months --name-only --format= -- <scope> \
  | sort | uniq -c | sort -rn | head -30
```

Also collect files that recent fix commits touch:

```bash
git log --since=12.months -i -E --grep='fix|bug|revert' --name-only --format= -- <scope> \
  | sort | uniq -c | sort -rn | head -20
```

Use these lists to decide where to read closely. A messy file that nobody
touches is low priority.

### 3. Collect evidence by category

Run the checks that apply to the repo's languages. Read the hotspot files
yourself for what tools cannot see.

| Category | What to look for | Tools (if installed) |
| --- | --- | --- |
| Complexity | Long functions, deep nesting, god modules | `ruff check --select C901,PLR0912,PLR0915`, `radon cc -s -n C`, `lizard`, `gocyclo` |
| Duplication | Copied logic, repeated business rules | `jscpd`, then read the matches |
| Structure | Circular imports, layer violations, one change that needs edits in many files | `git log` co-change of file pairs, import graph tools |
| Dependencies | Outdated majors, deprecated APIs, known vulnerabilities | `uv tree --outdated`, `pip-audit`, `npm outdated`, `npm audit`, `cargo outdated`, `cargo audit`, `nix flake metadata` (input ages) |
| Tests | Untested hotspots, flaky or skipped tests, slow suites | the repo's coverage command, `rg -n -e skip -e xfail -e '\.only\('` |
| Markers | Deferred work the authors already admitted | `rg -n -e TODO -e FIXME -e HACK -e XXX` |
| Documentation | Public APIs or complex logic with no explanation, stale docs that contradict code | read the code and the docs |
| Build and deploy | Manual steps, no rollback, missing CI checks | CI config, `Justfile`, scripts |

Record each finding with its location and the exact evidence.

### 4. Score each item

Give each item four values:

- Impact (1 to 3): how much it slows changes or causes bugs. 3 means it
  blocks or breaks work now.
- Risk (1 to 3): 3 for security or data loss, 2 for outages or wrong results,
  1 for friction only.
- Churn (1 to 3): from the hotspot rank in step 2. 3 for the top tenth of
  files, 1 for files with almost no changes.
- Effort: S (under 2 hours), M (2 to 8 hours), L (more than 1 day). Base it on
  the size of the code and the test coverage around it.

Score = (Impact + Risk) × Churn. Sort by score, high first. Break ties with
the smaller effort first. A quick win is an item with a score of 9 or more
and effort S.

Merge items that one fix removes together. Drop items with a score under 4
unless the user asked for a full inventory.

### 5. Plan the remediation

For each item in the plan, give:

- The first concrete step (a file and the change, not "refactor X").
- How to verify it (the test, lint, or command that proves it is done).
- What can break, and how to make the change safe (tests first, a facade, a
  feature flag, or small steps).

Group the plan as Now (quick wins and score-15+ risks), Next (M effort), and
Later (L effort). Suggest a prevention gate only where the repo lacks it and
it is cheap to add, for example a lint rule in the existing config.

## Report format

```markdown
## Summary

<2-3 sentences: the top debt, where it is, and the first fix.>

## Inventory

| ID | Category | Location | Evidence | I | R | C | Effort | Score |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| D1 | Complexity | src/orders.py:120 | `process()` is 210 lines, C901=34, 41 commits in 12 months | 3 | 2 | 3 | M | 15 |

## Plan

### Now
1. D1: <first step>. Verify: <command>. Risk: <what can break>.

### Next
...

### Later
...

## Prevention

- <gate>: <where to add it>.

## Not measured

- <metric>: <why, for example the tool is not installed>.
```

Put the report in the chat. Write it to a file only when the user asks.
