---
name: writing-plans
description: Write a concrete implementation plan before executing any multi-step task. Use before fixing bugs spanning multiple files, implementing features, or refactoring. Plan is saved to .claude/plans/ in the working repo.
version: 1.0.0
author: oss-contrib-setup (adapted from NousResearch/hermes-agent)
license: MIT
metadata:
  tags: [planning, workflow, methodology, pre-implementation]
  related_skills: [tdd-go, systematic-debugging]
---

# Writing Plans

## When to Use

Before any task that involves:
- Touching more than 2 files
- Writing new logic (not just renaming/formatting)
- A fix whose root cause required investigation
- Any work that will become a PR

Skip planning only for trivial single-file changes with a root cause already understood.

## Core Principle

A plan is a contract, not a todo list. It specifies:
- **What exactly changes** — file paths, function names, line numbers
- **Why each change is needed** — traced back to the root cause
- **How to verify each step** — exact commands that confirm the step succeeded

If a step in your plan cannot be verified, the plan is incomplete.

---

## Task Granularity

Each task must take **2–5 minutes** to execute. Larger = split it.

**Good task (2 min):**
```
- [ ] Add bounds check to ConvertPort() in pkg/forward/forward.go:47
```

**Bad task (too vague, unbounded):**
```
- [ ] Fix the overflow bug
```

**Bad task (too large, multiple concerns):**
```
- [ ] Refactor the metrics package and fix the registration conflict
```

---

## Plan Format

```markdown
# Plan: <imperative short title>

**Repo:** <org>/<repo>
**Issue:** #<number> — <issue title>
**Root cause:** <one precise sentence — from systematic-debugging>
**Approach:** <one sentence — the fix strategy>
**Estimated diff:** ~<N> lines across <N> files

---

## Tasks

- [ ] 1. Read `path/to/file.go:L40-L60` — understand the current conversion logic
- [ ] 2. Write failing test `TestConvertPort_Overflow` in `path/to/file_test.go`
         Verify: `go test -run TestConvertPort_Overflow ./path/to -v -count=1` → FAIL
- [ ] 3. Add bounds check in `ConvertPort()` at `path/to/file.go:47`
         Verify: `go test -run TestConvertPort_Overflow ./path/to -v -count=1` → PASS
- [ ] 4. Run full package tests
         Verify: `go test ./path/to/... -count=1` → all pass
- [ ] 5. Run lint
         Verify: `golangci-lint run ./path/to/...` → clean
- [ ] 6. Check diff size
         Verify: `git diff --stat` → < 100 lines, all in related files
- [ ] 7. Run /pre-pr

---

## Risks and Open Questions
- <any risk, dependency, or thing you're unsure about>
```

---

## Writing Process

### Step 1 — Verify root cause is known
If root cause is not stated in one sentence, run `systematic-debugging` skill first.
A plan written without a clear root cause will be wrong.

### Step 2 — Explore the affected code
```bash
grep -rn "ConvertPort\|int32(" ./pkg/forward --include="*.go"
```
Read the function, read its callers, read its tests.

### Step 3 — Identify all files that need to change
List them explicitly. No "and related files" — be exact.

### Step 4 — Write tasks bottom-up
Start from the smallest code change, then the test, then the verification.
Each task has one responsibility.

### Step 5 — Add verification to every task
If a task has no verification command, add one.
Verification commands must be runnable — no pseudocode.

### Step 6 — Estimate the diff
```bash
# After reading the code but before writing anything:
# Estimate lines: typically count the function body + test cases
```
If estimate > 100 lines: look for a smaller scope.
If estimate > 300 lines: the plan is wrong — narrow the fix.

---

## Save Location

```bash
mkdir -p .claude/plans
```

Save as: `.claude/plans/YYYY-MM-DD_<slug>.md`
Example: `.claude/plans/2026-03-22_coredns-g115-forward.md`

---

## Execution Rules

1. Mark each task `[x]` as you complete it — do not batch-complete
2. If a task reveals the plan is incorrect: update the plan before continuing
3. Never skip a verification step — if CI would catch it, you should catch it first
4. If 3 consecutive tasks fail: stop, re-read the root cause, rewrite the plan
