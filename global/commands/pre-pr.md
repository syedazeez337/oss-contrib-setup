---
description: Run the PR preflight quality gate — scope, lint, tests, diff size, description, competing PRs. All 6 gates must pass before opening a PR.
---

## Current Branch

Branch: !`git branch --show-current`

Base branch: !`BASE=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | awk '{print $NF}'); [ -z "$BASE" ] && BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'); [ -z "$BASE" ] && BASE="main"; echo "$BASE"`

## Changed Files

!`BASE=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | awk '{print $NF}'); [ -z "$BASE" ] && BASE="main"; git diff ${BASE}...HEAD --name-only 2>/dev/null`

## Diff Summary

!`BASE=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | awk '{print $NF}'); [ -z "$BASE" ] && BASE="main"; git diff ${BASE}...HEAD --stat 2>/dev/null`

## Recent Commits on This Branch

!`BASE=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | awk '{print $NF}'); [ -z "$BASE" ] && BASE="main"; git log ${BASE}...HEAD --oneline 2>/dev/null`

## Repo Profile

!`cat $(ls .claude/plans/repo-*.md 2>/dev/null | head -1) 2>/dev/null || echo "No repo profile — run repo-ingest for best results"`

---

Invoke the `pr-preflight` skill against the above diff and branch state.

After all 6 gates are evaluated, if all pass:
1. Output the PASSED summary block
2. Generate a suggested PR title using the commit format from the repo profile (or git log if no profile)
3. Generate a complete draft PR body using the repo's required sections (from profile or description-template.md)

If any gate fails:
1. Output the FAILED summary block listing which gates failed and exactly what to fix
2. Do NOT generate PR title/body until gates pass
3. Output a numbered remediation checklist: "Fix gate N first, then re-run /pre-pr"
