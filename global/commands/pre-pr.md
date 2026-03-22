---
description: Run the PR preflight quality gate — scope, lint, tests, diff size, description, competing PRs. All 6 gates must pass before opening a PR.
---

## Current Branch

Branch: !`git branch --show-current`

Remote default branch: !`git remote show origin 2>/dev/null | grep 'HEAD branch'`

## Changed Files

!`git diff main...HEAD --name-only 2>/dev/null || git diff master...HEAD --name-only 2>/dev/null || git diff trunk...HEAD --name-only 2>/dev/null`

## Diff Summary

!`git diff main...HEAD --stat 2>/dev/null || git diff master...HEAD --stat 2>/dev/null || git diff trunk...HEAD --stat 2>/dev/null`

## Recent Commits on This Branch

!`git log main...HEAD --oneline 2>/dev/null || git log master...HEAD --oneline 2>/dev/null || git log trunk...HEAD --oneline 2>/dev/null`

## Repo Profile

!`cat .claude/plans/repo-*.md 2>/dev/null | head -60 || echo "No repo profile — run repo-ingest for best results"`

---

Invoke the `pr-preflight` skill against the above diff and branch state.

The `Remote default branch` line above tells you the actual base branch — use it for all
`git diff <base>...HEAD` commands in the skill. Do not assume `main`.

After all 6 gates are evaluated, if all pass:
1. Output the PASSED summary block
2. Generate a suggested PR title using the commit format from the repo profile (or git log if no profile)
3. Generate a complete draft PR body using the repo's required sections (from profile or description-template.md)

If any gate fails:
1. Output the FAILED summary block listing which gates failed and exactly what to fix
2. Do NOT generate PR title/body until gates pass
3. Output a numbered remediation checklist: "Fix gate N first, then re-run /pre-pr"
