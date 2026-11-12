---
name: tech-debt
description: >-
  Use when asked to find, score, or prioritize technical debt in a repository
  or a scoped path, or to produce a debt remediation plan. Ranks files by git
  churn and fix history, checks dependency age and known vulnerabilities, and
  reports a ranked plan. For bugs and security holes in the code, use
  ponytail-audit. It does not change code unless asked.
---

# Technical Debt Analysis

Find where debt costs the most, from git history and the dependency tree, and
rank the fixes. The report is the deliverable. Do not edit code unless the
user asks for a fix after the report.

This skill covers churn, dependencies, and the plan only. It does not hunt
for bugs or security holes in the code. When the user wants those, tell them
to run `/skill:ponytail-audit` on the top hotspots from step 2.

## Rules

- Every item needs evidence: a `file:line`, a command output, or a git
  statistic. No evidence, no item.
- Never invent numbers. No dollar costs, no hourly rates, no projected
  savings. When a metric was not measured, say so in the "Not measured"
  section.
- Run only tools that are installed (`command -v <tool>`). Do not install
  tools without asking. Prefer the repo's own audit and update commands
  (`Justfile`, `Makefile`, `package.json` scripts, `pyproject.toml`).
- Generated, vendored, and lock files are not hotspots. Skip them in the
  churn lists. Lock files are evidence for dependency age.

## Workflow

### 1. Fix the scope

Use the paths or area the user named. If none, use the repository root.
Read `CLAUDE.md`/`AGENTS.md`/`README.md` and the build files to learn the
languages, the package managers, and the existing audit commands.

### 2. Find the hotspots

Rank files by churn:

```bash
git log --since=12.months --name-only --format= -- <scope> \
  | sort | uniq -c | sort -rn | head -30
```

Rank files by fix history:

```bash
git log --since=12.months -i -E --grep='fix|bug|revert' --name-only --format= -- <scope> \
  | sort | uniq -c | sort -rn | head -20
```

Find files that always change together, which points to a hidden coupling:

```bash
git log --since=12.months --name-only --format='format:%n--' -- <scope> \
  | awk 'function flush(){if(n>1&&n<=10)for(i=1;i<=n;i++)for(j=i+1;j<=n;j++)print (f[i]<f[j]?f[i]" "f[j]:f[j]" "f[i]);n=0} /^--$/{flush();next} NF{f[++n]=$0} END{flush()}' \
  | sort | uniq -c | sort -rn | head -15
```

A hotspot is a file high in both the churn list and the fix list. Read each
top hotspot briefly to name what makes it hard to change (size, mixed jobs,
no tests). Do not do a full code review of it.

### 3. Check the dependencies

Run the checks that apply to the repo:

| Ecosystem | Outdated | Vulnerabilities |
| --- | --- | --- |
| Python (uv) | `uv tree --outdated --depth 1` | `pip-audit`, `uv audit` |
| Node | `npm outdated` / `pnpm outdated` | `npm audit` / `pnpm audit` |
| Rust | `cargo outdated --root-deps-only` | `cargo audit` |
| Go | `go list -u -m all` | `govulncheck ./...` |
| Nix flake | `nix flake metadata` (input `lastModified`) | none built in |

Also look for:

- Major versions behind, and libraries with no release in two or more years.
- Deprecated APIs that the build or the tests warn about.
- Pins or overrides without a reason, for example a patched or vendored
  dependency nobody updates.
- Two libraries that do the same job.

### 4. Score each item

Give each item four values:

- Impact (1 to 3): how much it slows changes or causes bugs. 3 means it
  blocks or breaks work now.
- Risk (1 to 3): 3 for a known vulnerability or an unsupported runtime, 2 for
  a deprecated API with a removal date, 1 for friction only.
- Churn (1 to 3): from step 2. 3 for the top tenth of files, 1 for files with
  almost no changes. For a dependency, use the churn of the files that import
  it.
- Effort: S (under 2 hours), M (2 to 8 hours), L (more than 1 day). Base it on
  the size of the change and the test coverage around it.

Score = (Impact + Risk) × Churn. Sort by score, high first. Break ties with
the smaller effort first. A quick win is an item with a score of 9 or more
and effort S.

Merge items that one fix removes together. Drop items with a score under 4
unless the user asked for a full inventory.

### 5. Plan the remediation

For each item in the plan, give:

- The first concrete step (a file and the change, or the exact upgrade).
- How to verify it (the test, build, or audit command that proves it is done).
- What can break, and how to make the change safe (tests first, one upgrade
  per change, a changelog check for breaking changes).

Group the plan as Now (quick wins and known vulnerabilities), Next (M effort),
and Later (L effort). Suggest a prevention gate only where the repo lacks it
and it is cheap to add, for example a scheduled dependency update job.

## Report format

```markdown
## Summary

<2-3 sentences: the top debt, where it is, and the first fix.>

## Hotspots

| File | Commits | Fix commits | Why it is hard to change |
| --- | --- | --- | --- |

## Dependencies

| Package | Current | Latest | Problem |
| --- | --- | --- | --- |

## Plan

| ID | Item | I | R | C | Effort | Score |
| --- | --- | --- | --- | --- | --- | --- |

### Now
1. D1: <first step>. Verify: <command>. Risk: <what can break>.

### Next
...

### Later
...

## Not measured

- <metric>: <why, for example the tool is not installed>.

For bugs and security holes in the hotspots, run `/skill:ponytail-audit <paths>`.
```

Put the report in the chat. Write it to a file only when the user asks.
