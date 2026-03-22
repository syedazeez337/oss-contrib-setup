---
description: Run the go-reviewer agent on the current branch diff. Use before opening any PR or when asked to review code changes.
---

## Branch Under Review

Branch: !`git branch --show-current`
Against: !`git log --oneline -1 main 2>/dev/null || git log --oneline -1 master`

## Diff Statistics

!`git diff main...HEAD --stat 2>/dev/null || git diff master...HEAD --stat`

## Full Diff

!`git diff main...HEAD 2>/dev/null || git diff master...HEAD`

---

Invoke the `go-reviewer` agent on the above diff.

The agent must:
1. Read the full diff including all changed files
2. For each changed file, read 15 lines of surrounding context using the Read tool
3. Identify critical, important, and minor issues
4. Produce the full structured review output including verdict and merge confidence

After the review, append:
```
---
Next steps based on verdict:
- APPROVE: run /pre-pr then /commit push to open the PR
- REQUEST_CHANGES: fix critical issues, then re-run /review
- NEEDS_DISCUSSION: open a draft PR or comment on the issue to align with maintainers first
```
