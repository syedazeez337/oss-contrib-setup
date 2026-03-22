---
description: Run the PR preflight quality gate — scope, lint, tests, diff size, description, competing PRs. All 6 gates must pass before opening a PR.
---

## Current Branch

Branch: !`git branch --show-current`

Remote info: !`git remote show origin 2>/dev/null`

Recent commits: !`git log --oneline -10`

Status: !`git status --short`

---

## Instructions

Invoke the `pr-preflight` skill.

The skill will:
1. Read `git remote show origin` output above to determine the base branch (HEAD branch line)
2. Use the Read and Glob tools to load `.claude/plans/repo-*.md` if it exists
3. Run all 6 gates using Bash tool with the resolved commands

After all 6 gates are evaluated, if all pass:
1. Output the PASSED summary block
2. Generate a suggested PR title using the commit format from the repo profile or git log
3. Generate a complete draft PR body using the repo's required sections

If any gate fails:
1. Output the FAILED summary block listing which gates failed and exactly what to fix
2. Do NOT generate PR title/body until gates pass
3. Output a numbered remediation checklist: "Fix gate N first, then re-run /pre-pr"
