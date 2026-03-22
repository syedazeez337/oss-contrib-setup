---
description: Generate a conventional commit message, stage specific files, commit, and optionally push the branch.
argument-hint: [push — add to also push after committing]
---

## Current State

Status: !`git status --short`

Unstaged diff: !`git diff`

Staged diff: !`git diff --cached`

Recent commits (for message style): !`git log --oneline -10`

Remote: !`git remote get-url origin 2>/dev/null || echo "no remote"`

Current branch: !`git branch --show-current`

Contribution guidelines: !`cat CONTRIBUTING.md 2>/dev/null || echo "no CONTRIBUTING.md"`

Repo profile (sign-off + commit format): !`cat $(ls .claude/plans/repo-*.md 2>/dev/null | head -1) 2>/dev/null | grep -A5 "Sign-off\|Commit Format\|SIGN_OFF\|COMMIT" || echo "no repo profile"`

---

## Instructions

### Step 1 — Determine commit conventions

Priority order (highest wins):
1. **Repo profile** (`.claude/plans/repo-*.md`) — read `Sign-off` and `Commit Format` fields
2. **git log** — read the last 10 commits and extract the actual format used in practice
3. **CONTRIBUTING.md** — read for explicit commit format instructions
4. **Default** — conventional commits format if nothing else found

From these sources extract:
- Exact commit message format (with a real example from git log)
- DCO / CLA / none requirement
- Any other per-repo commit rules

**The repo's own practice (git log) takes precedence over what CONTRIBUTING.md says.**

### Step 2 — Analyse the changes
Read all staged and unstaged diffs.
Identify the component (scope) and the type of change (fix/chore/feat/test/docs/refactor).

### Step 3 — Propose a commit message
Generate a commit message that matches the repo's convention from Step 1.
Default format (conventional commits) if no other convention found:
```
<type>(<scope>): <present-tense description under 72 chars>
```

Examples:
- `fix(forward): prevent G115 integer overflow in port conversion`
- `chore(lint): fix gosec G115 in pkg/metrics workqueue registration`
- `test(forward): add regression test for int32 overflow boundary`
- `fix(crd): remove duplicate replicas field from Kafka schema`

Show the proposed message and ask: "Commit with this message? (yes/edit/abort)"

### Step 4 — Stage specific files
Do NOT use `git add -A` or `git add .`
Stage only the files directly related to the fix:
```bash
git add path/to/file1.go path/to/file1_test.go
```

Do not stage:
- `.env` files
- `*_test` binaries or coverage output files
- Any file not related to the fix

### Step 5 — Commit
If CONTRIBUTING.md or git log shows DCO sign-off is required (look for `Signed-off-by` in recent commits):
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

After pushing, output the branch URL and suggest:
```
Branch pushed. To open the PR:
  gh pr create --fill --web
Or directly:
  gh pr create --title "<commit message>" --body "<draft body>"
```

### Step 7 — Confirm
Output the commit hash, message, and file list:
```
✓ Committed: <hash>
  Message: <message>
  Files: <list>
  DCO sign-off: yes/no
  <If pushed: Branch URL>
```
