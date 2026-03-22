---
description: Run the fix-loop skill — iterates build, lint, and tests; fixes failures; re-runs until all checks are clean or max iterations reached. Use during development to clean up lint and failing tests before /pre-pr.
argument-hint: [lint | tests | all — default: all]
---

## Current State

Branch: !`git branch --show-current`

Status: !`git status --short`

---

## Instructions

Invoke the `fix-loop` skill.

The skill will:
1. Use the Glob tool to find `.claude/plans/repo-*.md` and read the repo profile if it exists
2. Auto-detect language and commands if no profile found
3. Run the fix loop for the requested scope

If $ARGUMENTS is `lint`: run only build and lint phases (skip tests).
If $ARGUMENTS is `tests`: run only test phase (skip lint).
If $ARGUMENTS is `all` or empty: run full fix-loop (build + lint + tests).

After fix-loop completes:
- If CLEAN: suggest running `/pre-pr` next
- If PARTIAL: summarise what remains and suggest next steps
