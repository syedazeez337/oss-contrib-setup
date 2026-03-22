---
description: Generate a commit message matching the repo's conventions, stage specific files, commit, and optionally push the branch.
argument-hint: [push — add to also push after committing]
---

## Current State

Status: !`git status --short`

Unstaged diff: !`git diff`

Staged diff: !`git diff --cached`

Recent commits (for message style): !`git log --oneline -10`

Remote: !`git remote get-url origin 2>/dev/null`

Current branch: !`git branch --show-current`

---

## Instructions

### Step 1 — Determine commit conventions

Use the Read tool to check these in priority order:
1. `.claude/plans/repo-*.md` (repo profile from repo-ingest) — read `Sign-off` and `Commit Format` fields
2. `CONTRIBUTING.md` — look for explicit commit format rules
3. `git log --oneline -10` (already injected above) — extract the actual format used in practice

**The repo's practice in git log is ground truth.** CONTRIBUTING.md is secondary.

Extract:
- Exact commit format (paste a real example from git log)
- DCO / CLA / none sign-off requirement
- Any other per-repo rules

### Step 2 — Analyse the changes
Read all staged and unstaged diffs above.
Identify the component (scope) and type of change (fix/chore/feat/test/docs/refactor).

### Step 3 — Propose a commit message
Match the format from Step 1 exactly.
Default if nothing found: `<type>(<scope>): <present-tense description under 72 chars>`

Show the proposed message and ask: "Commit with this message? (yes/edit/abort)"

### Step 4 — Stage specific files
Do NOT use `git add -A` or `git add .`
Stage only files directly related to the fix:
```bash
git add path/to/file1 path/to/file2
```

Do not stage `.env` files, build artifacts, or unrelated files.

### Step 5 — Commit
If sign-off required (DCO — look for `Signed-off-by` in git log or CONTRIBUTING.md):
```bash
git commit -s -m "<approved message>"
```

Otherwise:
```bash
git commit -m "<approved message>"
```

### Step 6 — Push (only if $ARGUMENTS contains "push")
```bash
git push -u origin HEAD
```

Suggest next step:
```
Branch pushed. To open the PR:
  gh pr create --title "<commit message>" --body "<draft body>"
```

### Step 7 — Confirm
```
✓ Committed: <hash>
  Message:   <message>
  Files:     <list>
  Sign-off:  <yes (DCO) | no>
```
