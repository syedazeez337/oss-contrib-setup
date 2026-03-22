---
description: Run the PR preflight quality gate — scope, lint, tests, diff size, description, competing PRs. All 6 gates must pass before opening a PR.
---

## Current Branch

Branch: !`git branch --show-current`
Base: main (or master — auto-detected)

## Changed Files

!`git diff main...HEAD --name-only 2>/dev/null || git diff master...HEAD --name-only`

## Diff Summary

!`git diff main...HEAD --stat 2>/dev/null || git diff master...HEAD --stat`

## Recent Commits on This Branch

!`git log main...HEAD --oneline 2>/dev/null || git log master...HEAD --oneline`

---

Invoke the `pr-preflight` skill against the above diff and branch state.

After all 6 gates are evaluated, if all pass:
1. Output the PASSED summary block
2. Generate a suggested PR title in conventional commits format based on the changes
3. Generate a complete draft PR body using the description template from the skill's references

If any gate fails:
1. Output the FAILED summary block listing which gates failed and exactly what to fix
2. Do NOT generate PR title/body until gates pass
3. Output a numbered remediation checklist: "Fix gate N first, then re-run /pre-pr"
