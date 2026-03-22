---
description: Run the fix-loop skill — iterates build, lint, and tests; fixes failures; re-runs until all checks are clean or max iterations reached. Use during development to clean up lint and failing tests before /pre-pr.
argument-hint: [lint | tests | all — default: all]
---

## Context

Current branch: !`git branch --show-current`

Changed files: !`git diff main...HEAD --name-only 2>/dev/null | head -20`

Repo profile: !`cat .claude/plans/repo-*.md 2>/dev/null | head -40 || echo "No repo profile — run repo-ingest first for best results"`

## Instructions

Invoke the `fix-loop` skill.

If $ARGUMENTS is `lint`: run only build and lint phases of fix-loop (skip test phase).
If $ARGUMENTS is `tests`: run only test phase of fix-loop (skip lint phase).
If $ARGUMENTS is `all` or empty: run full fix-loop (build + lint + tests).

After fix-loop completes:
- If CLEAN: suggest running `/pre-pr` next
- If PARTIAL: summarise what remains and suggest next steps
